import Module from './drflac.js'

let DrFlac = { 
    'drflac' : true,
    'ready' : false,
    'on' : function(event, cb) {
        if(event === 'ready') {
            this.on_ready = cb;
        }
    }
};

const sleep = m => new Promise(r => setTimeout(r, m));

const waitForEvent = (obj, event) => {
    return new Promise(function(resolve) {
        obj.on(event, function() {
            resolve();
        });
    });
};

class Mutex {
    constructor() {
      this._locking = Promise.resolve();
      this._locked = false;
    }
  
    isLocked() {
      return this._locked;
    }
  
    lock() {
      this._locked = true;
      let unlockNext;
      let willLock = new Promise(resolve => unlockNext = resolve);
      willLock.then(() => this._locked = false);
      let willUnlock = this._locking.then(() => unlockNext);
      this._locking = this._locking.then(() => willLock);
      return willUnlock;
    }
  }

function makeRequest (method, url, start, end, signal) {
return new Promise(function (resolve, reject) {
    var xhr = new XMLHttpRequest();
    
    const handler = function(){
        console.log('ABORT XHR');
        xhr.abort();
    };
    
    signal.addEventListener('abort', handler);            
    xhr.open(method, url);
    xhr.responseType = 'arraybuffer';
    xhr.setRequestHeader('Range', 'bytes='+start+'-'+end);
    xhr.onload = function () {
        signal.removeEventListener('abort', handler);
        if (this.status >= 200 && this.status < 300) {
            //console.log('xhr success');
            resolve(xhr);
        } else {
            console.log('xhr fail');                   
            reject({
                status: this.status,
                statusText: xhr.statusText
            });
        }
    };
    xhr.onerror = function () {
        console.log('xhr onerror');
        signal.removeEventListener('abort', handler);
        reject({
            status: this.status,
            statusText: xhr.statusText
        });
    };
    
    xhr.onabort = function() {
        console.log('xhr onabort');
        signal.removeEventListener('abort', handler);
        reject({
            status: this.status,
            statusText: xhr.statusText
        });
    };
    xhr.send();
    //console.log('sending xhr');
});
}

const GetFileSize = function(xhr) {
    let re = new RegExp('/([0-9]+)');
    let res = re.exec(xhr.getResponseHeader('Content-Range'));
    if(!res) throw("Failed to get filesize");
    return Number(res[1]);
};

const NDRFLAC_SUCCESS = 0;
const NDRFLAC_GENERIC_ERROR = 1;
const NDRFLAC_MEM_NEED_MORE = 2;

const NetworkDrFlac = async function(theURL, gsignal) {    
    // make sure drflac is ready. Inlined to avoid await when it's already ready
    while(typeof DrFlac === 'undefined') {
        console.log('music_drflac, no drflac sleeping 5ms');
        await sleep(5);
    }
    if(!DrFlac.ready) {
        console.log('music_drflac, waiting for drflac to be ready');
        await waitForEvent(DrFlac, 'ready');
    }
    let that = {};
    that.CHUNKSIZE = 262144;

    that.downloadChunk = async function(start, mysignal) {
        if(start % that.CHUNKSIZE)
        {
            throw("start is not a multiple of CHUNKSIZE: " + start);
        }        
        const def_end = start+that.CHUNKSIZE-1;
        const end = that.filesize ? Math.min(def_end, that.filesize-1) : def_end; 
        let xhr = await makeRequest('GET', theURL, start, end, mysignal);
        if(!that.filesize) that.filesize = GetFileSize(xhr);
        if(!that.memptr) that.memptr = DrFlac.network_drflac_mem_create(that.filesize, that.CHUNKSIZE);
        let dataHeap = new Uint8Array(DrFlac.Module.HEAPU8.buffer, DrFlac.network_drflac_mem_bufptr(that.memptr)+start, xhr.response.byteLength);
        dataHeap.set(new Uint8Array(xhr.response));
        DrFlac.network_drflac_mem_add_block(that.memptr, start);  
        return xhr.response.byteLength;
    };

    that.freeError = function(err_ptr) {
        let err = {'code' : DrFlac.network_drflac_error_code(err_ptr), 'extradata' : DrFlac.network_drflac_extra_data(err_ptr)};
        DrFlac.network_drflac_free_error(err_ptr);
        return err;
    };   

    that.close = async function() {
        if(that.ptr){
            DrFlac.network_drflac_close(that.ptr);
            that.ptr = null;
        }        
        if(that.memptr) {
            DrFlac.network_drflac_mem_free(that.memptr);
            that.memptr = null;
        }            
    };

    that.read_pcm_frames_to_AudioBuffer_f32_mem = async function(start, count, mysignal, audiocontext) {
        const f32_size = 4;
        const pcm_float_frame_size = f32_size * that.channels;

        while(1) {       
              
        // attempt to decode the samples
        let destdata = DrFlac.Module._malloc(count*pcm_float_frame_size);
        let err_ptr = DrFlac.network_drflac_create_error();  
        const samples = DrFlac.network_drflac_read_pcm_frames_f32_mem(that.ptr, start, count, destdata, err_ptr);
        const err = that.freeError(err_ptr);   
        
        if(err.code !== NDRFLAC_SUCCESS)
        {
            DrFlac.Module._free(destdata);  
            if(err.code !== NDRFLAC_MEM_NEED_MORE)
            {
                throw("network_drflac_read_pcm_frames_f32_mem failed");
            }
            // download more data
            await that.downloadChunk(err.extradata, mysignal);

            // reopen drflac
            DrFlac.network_drflac_close(that.ptr);
            let err_ptr = DrFlac.network_drflac_create_error();            
            that.ptr = DrFlac.network_drflac_open_mem(that.filesize, that.memptr, err_ptr);
            that.freeError(err_ptr);            
            if(!that.ptr) {
                throw("Failed network_drflac_open");
            }
            continue;
        }      

        let audiobuffer = audiocontext.createBuffer(that.channels, samples, that.sampleRate);
        const chansize = samples * f32_size;
        for( let i = 0; i < that.channels; i++) {
            let buf = new Float32Array(DrFlac.Module.HEAPU8.buffer, destdata+(chansize*i), samples);
            audiobuffer.getChannelData(i).set(buf);        
        }

        DrFlac.Module._free(destdata);
        return audiobuffer;
        };       
    };

    that.read_pcm_frames_to_AudioBuffer = async function(start, count, mysignal, audiocontext) {
        //return that.read_pcm_frames_to_AudioBuffer_wav(start, count, mysignal, audiocontext);
        return that.read_pcm_frames_to_AudioBuffer_f32_mem(start, count, mysignal, audiocontext);
    };

    // open drflac for the first time   
    for(let start = 0; ;) {
        try {
            await that.downloadChunk(start, gsignal);
        } catch(error) {
            that.close();
            throw(error); 
        }

        let err_ptr = DrFlac.network_drflac_create_error();
        that.ptr = DrFlac.network_drflac_open_mem(that.filesize, that.memptr, err_ptr);
        const err = that.freeError(err_ptr);
        start = err.extradata;        
        if(that.ptr) {            
            break;
        }
        else if(err.code !== NDRFLAC_MEM_NEED_MORE){
            that.close();
            throw("Failed network_drflac_open");
        }        
    }
       

    that.totalPCMFrameCount = DrFlac.network_drflac_totalPCMFrameCount(that.ptr);
    that.sampleRate = DrFlac.network_drflac_sampleRate(that.ptr);
    that.bitsPerSample = DrFlac.network_drflac_bitsPerSample(that.ptr);
    that.channels = DrFlac.network_drflac_channels(that.ptr);
    that.url = theURL;
    return that;
};



export default NetworkDrFlac;

Module().then(function(DrFlacMod){
    DrFlac.Module = DrFlacMod;

    DrFlac.network_drflac_totalPCMFrameCount = DrFlacMod.cwrap('network_drflac_totalPCMFrameCount', "number", ["number"]);

    DrFlac.network_drflac_sampleRate = DrFlacMod.cwrap('network_drflac_sampleRate', "number", ["number"]);

    DrFlac.network_drflac_bitsPerSample = DrFlacMod.cwrap('network_drflac_bitsPerSample', "number", ["number"]);

    DrFlac.network_drflac_channels = DrFlacMod.cwrap('network_drflac_channels', "number", ["number"]);   

    DrFlac.network_drflac_close = DrFlacMod.cwrap('network_drflac_close', null, ["number"]);    

    DrFlac.network_drflac_open_mem = DrFlacMod.cwrap('network_drflac_open_mem', "number", ["number", "number", "number"]);

    DrFlac.network_drflac_read_pcm_frames_f32_mem = DrFlacMod.cwrap('network_drflac_read_pcm_frames_f32_mem', "number", ["number", "number", "number", "number", "number"]);

    DrFlac.network_drflac_create_error = DrFlacMod.cwrap('network_drflac_create_error', "number");

    DrFlac.network_drflac_free_error = DrFlacMod.cwrap('network_drflac_free_error', null, ["number"]);

    DrFlac.network_drflac_error_code = DrFlacMod.cwrap('network_drflac_error_code', "number", ["number"]);
    
    DrFlac.network_drflac_extra_data = DrFlacMod.cwrap('network_drflac_extra_data', "number", ["number"]);

    DrFlac.network_drflac_mem_create = DrFlacMod.cwrap('network_drflac_mem_create', "number", ["number", "number"]);

    DrFlac.network_drflac_mem_free = DrFlacMod.cwrap('network_drflac_mem_free', null, ["number"]);

    DrFlac.network_drflac_mem_add_block = DrFlacMod.cwrap('network_drflac_mem_add_block', null, ["number", "number"]);

    DrFlac.network_drflac_mem_bufptr = DrFlacMod.cwrap('network_drflac_mem_bufptr', "number", ["number"]);

    console.log('NetworkDrFlac is ready!');
    DrFlac.ready = true;
    if(DrFlac.on_ready) {
        DrFlac.on_ready();
    }    
});









