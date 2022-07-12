//import {default as NetworkDrFlac} from './music_drflac_module.js'
import {default as NetworkDrFlac} from './music_drflac_module.cache.js'
// times in seconds
const AQMaxDecodedTime = 20;    // maximum time decoded, but not queued
const AQStartLookahead = 0.100; // minimum time to buffer before starting playback
const AQLookahead = 5;          // buffer as long as less than AQLookahead is buffered

let MainAudioContext;
let GainNode;
let AQID = -1;
let AudioQueue = [];
let Tracks_HEAD;
let Tracks_TAIL;
let Tracks_QueueCurrent;
let FACAbortController = new AbortController();
let SBAR_UPDATING = 0;
let NWDRFLAC;

function DeclareGlobalFunc(name, value) {
    Object.defineProperty(window, name, {
        value: value,
        configurable: false,
        writable: false
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

function CreateAudioContext(options) {
    let mycontext = (window.hasWebKit) ? new webkitAudioContext(options) : (typeof AudioContext != "undefined") ? new AudioContext(options) : null;
    GainNode = mycontext.createGain();
    GainNode.connect(mycontext.destination);
    return mycontext;
}

let lastMALtime;
function MainAudioLoop() {
    if(lastMALtime) {
        const MALDelta = MainAudioContext.currentTime - lastMALtime;
        if((MALDelta) > 0.100) {
            console.log('MAL called super late ' + MALDelta);
        }
    }
    lastMALtime= MainAudioContext.currentTime; 
    AQ_clean();
    if(AudioQueue.length === 0) return 0;
    
    // advanced past already scheduled audio. bufferTime is the last endTime
    let bufferTime;
    let acindex = 0;
    for(; acindex < AudioQueue.length; acindex++) {
        if(!AudioQueue[acindex].startTime) break;
        bufferTime = AudioQueue[acindex].endTime;
    }

    // adjust / assign bufferTime if needed
    let timeadjusted = false;
    if(!bufferTime || (bufferTime < MainAudioContext.currentTime)) {
        bufferTime =  MainAudioContext.currentTime+AQStartLookahead;
        console.log('adjusting time to ' + bufferTime);
        timeadjusted = true;
    }
    
    // queue up to 5 secs ahead
    const lookaheadtime = MainAudioContext.currentTime + AQLookahead;
    while(bufferTime < lookaheadtime) {
        // everything is scheduled break out
        if(acindex === AudioQueue.length) return;  
        let toQueue = AudioQueue[acindex];

        let source = MainAudioContext.createBufferSource();        
        source.buffer = toQueue.buffer;
        source.connect(GainNode);    
        source.start(bufferTime, 0);
        InitPPText();
        toQueue.source = source;

        toQueue.startTime = bufferTime;
        if(source.buffer.duration !== (toQueue.duration / toQueue.track.sampleRate)) {
            console.log('duration wrong');
        }
        toQueue.endTime = toQueue.startTime + source.buffer.duration;
        if(!toQueue.playbackinfo.starttime || timeadjusted) {
            timeadjusted = false;
            toQueue.playbackinfo.starttime = toQueue.startTime - toQueue.skiptime;
        }
        if(toQueue.func) {                       
            toQueue.func(toQueue.startTime, toQueue.endTime);
        }

        bufferTime = toQueue.endTime;         
        acindex++;        
    }
}

function GraphicsLoop() {
    AQ_clean();
    if(SBAR_UPDATING) {
        
        
        
    }
    // show the deets of the current track, if exists, is queued, and is playing  
    else if(AudioQueue[0] && AudioQueue[0].playbackinfo.starttime && ((MainAudioContext.currentTime-AudioQueue[0].playbackinfo.starttime) >= 0)) {
        //don't advance the clock past the end of queued audio
        let curTime = MainAudioContext.currentTime-AudioQueue[0].playbackinfo.starttime;       
        //console.log('current time ' + MainAudioContext.currentTime + 'acurtime ' + curTime + 'starttime ' + AudioQueue[0].playbackinfo.starttime);        
        SetCurtimeText(curTime);
        SetSeekbarValue(curTime);
    }   
    
    window.requestAnimationFrame(GraphicsLoop);
}

function geturl(trackname) {
    let url = '../../music_dl?name=' + encodeURIComponent(trackname);
    url  += '&max_sample_rate=48000';
    //url  += '&max_sample_rate=96000';
    /*if (MAX_SAMPLE_RATE) url += '&max_sample_rate=' + MAX_SAMPLE_RATE;
    if (BITDEPTH) url += '&bitdepth=' + BITDEPTH;
    url += '&gapless=1&gdriveforce=1';*/

    return url;
}

function _QueueTrack(trackname, after, before) {
    let track = {'trackname' : trackname, 'url' : geturl(trackname)};
    
    if(!after) {
        after = Tracks_TAIL;        
    }
    if(!before && (after !== Tracks_TAIL)) {
        before = after.next;        
    }
    
    if(after) {
        after.next = track;
        track.prev = after;
        if(after === Tracks_TAIL) {
            Tracks_TAIL = track;
        }
    }    
    if(before) {
        before.prev = track;
        track.next = before;
        if(before === Tracks_HEAD) {
            Tracks_HEAD = track;       
        }        
    }
    
    // we have no link list without a head and a tail
    if(!Tracks_HEAD || !Tracks_TAIL) {
       Tracks_TAIL = track;        
       Tracks_HEAD = track;        
    }
    
    // if nothing is being queued, start the queue
    if(!Tracks_QueueCurrent) {
        Tracks_QueueCurrent = track;
        fillAudioQueue();
    }
    else {
        // Update text otherwise
        let tocheck = (AQ_ID() !== -1) ? AudioQueue[0].track : Tracks_QueueCurrent;
        if(tocheck) {
            if(tocheck.prev === track) {
                SetPrevText(track.trackname);
            }
            else if(tocheck.next === track) {
                SetNextText(track.trackname);
            }
        }            
    }    
    
    return track;
}

function _PlayTrack(trackname) {
    let queuePos;
    if(AQ_ID() !== -1) {
        queuePos = AudioQueue[0].track;
    }
    else if(Tracks_QueueCurrent) {
        queuePos = Tracks_QueueCurrent;
    }
    
    let queueAfter; //falsey is tail
    if(queuePos) {
        queueAfter = queuePos.next;        
    }    

    AQ_stopAudioWithoutID(-1);
    Tracks_QueueCurrent = null;
    return _QueueTrack(trackname, queuePos, queueAfter);   
}

// BuildPTrack is expensive so _QueueTrack and _PlayTrack don't call it
function QueueTrack(trackname, after, before) {
    let res = _QueueTrack(trackname, after, before);
    BuildPTrack();
    return res;
}

function PlayTrack(trackname) {
    let res = _PlayTrack(trackname);
    BuildPTrack();
    return res;
}

function QueueTracks(tracks, after) {
    tracks.forEach(function(elm) {
        after = _QueueTrack(elm, after);
    });
    BuildPTrack();
    return after;
}

function PlayTracks(tracks) {
    let trackname = tracks.shift();
    if(!trackname) return;
    let after = _PlayTrack(trackname);
    if(!tracks.length) return;  
    QueueTracks(tracks, after);
}

// remove played items from the audio queue
function AQ_clean() {
    let toDelete = 0;
    for(let i = 0; i < AudioQueue.length; i++) {
        if(! AudioQueue[i].endTime) break;        

        // run and remove associated graphics timers
        let timerdel = 0;
        for(let j = 0; j < AudioQueue[i].timers.length; j++) {
            if(AudioQueue[i].timers[j].time <= MainAudioContext.currentTime) {
                console.log('aqid: ' + AudioQueue[i].aqid + ' running timer at ' + MainAudioContext.currentTime);
                AudioQueue[i].timers[j].func(AudioQueue[i].timers[j]);
                timerdel++;
            }
        }
        if(timerdel)AudioQueue[i].timers.splice(0, timerdel);
        
        // remove if it has passed
        if(AudioQueue[i].endTime <= MainAudioContext.currentTime) {
            console.log('aqid: ' + AudioQueue[i].aqid + ' segment elapsed, removing');
            toDelete++;
        }
    }
    if(toDelete) {
        // if the AQ is empty and there's a current track we fell behind
        if((toDelete === AudioQueue.length) && (Tracks_QueueCurrent)) {
            SetPlayText(Tracks_QueueCurrent.trackname + ' {LOADING}');
        }
        AudioQueue.splice(0, toDelete);
    }
}

//imprecise, in seconds
function AQ_unqueuedTime() { 
    let unqueuedtime = 0;
    for(let i = 0; i < AudioQueue.length; i++) {
        if(!AudioQueue[i].startTime) {
            unqueuedtime += (AudioQueue[i].duration / AudioQueue[i].track.sampleRate);
        }        
    }
    return unqueuedtime;
}

// returns the currently or about to be playing aqid
function AQ_ID() {
    AQ_clean();     
    for(let i = 0; i < AudioQueue.length; i++) {        
        return AudioQueue[i].aqid;                    
    }
    return -1;
}

function AQ_stopAudioWithoutID(aqid) {
    if(!AudioQueue.length) return;
    let dCount = 0;
    for(let i = AudioQueue.length-1; i >= 0; i--) {
        if(AudioQueue[i].aqid === aqid) {
            break;
        }
        dCount++;
        if(AudioQueue[i].source) {
            AudioQueue[i].source.disconnect();
            AudioQueue[i].source.stop();
        }
        console.log('aqid: ' + AudioQueue[i].aqid + ' AQ_stopAudioWithoutID delete, curr: ' + aqid);
    }
    if(dCount) {
        AudioQueue.splice(AudioQueue.length - dCount, dCount);
    }    
}

if(typeof abortablesleep === 'undefined') {
    //const sleep = m => new Promise(r => setTimeout(r, m));
    const abortablesleep = (ms, signal) => new Promise(function(resolve) {
        const onTimerDone = function() {
            resolve();
            signal.removeEventListener('abort', stoptimer);
        };
        let timer = setTimeout(function() {
            console.log('sleep done ' + ms);
            onTimerDone();
        }, ms);

        const stoptimer = function() {
            console.log('aborted sleep');            
            onTimerDone();
            clearTimeout(timer);            
        };
        signal.addEventListener('abort', stoptimer);
    });
    DeclareGlobalFunc('abortablesleep', abortablesleep);
}

let FAQ_MUTEX = new Mutex();
async function fillAudioQueue(time) {
    // starting a fresh queue, render the text
    if(Tracks_QueueCurrent) {
        let track = Tracks_QueueCurrent;
        let prevtext = track.prev ? track.prev.trackname : '';
        SetPrevText(prevtext);
        SetPlayText(track.trackname + ' {LOADING}');
        let nexttext =  track.next ? track.next.trackname : '';
        SetNextText(nexttext);
        SetCurtimeText(time || 0);
        if(!time) SetSeekbarValue(time || 0);
        SetEndtimeText(track.duration || 0);        
    }

    // Stop the previous FAQ before starting
    FACAbortController.abort();
    FACAbortController = new AbortController();
    let mysignal = FACAbortController.signal;
    let unlock = await FAQ_MUTEX.lock();    
    if(mysignal.aborted) {
        console.log('abort after mutex acquire');
        unlock();
        return;
    }
    let initializing = 1;
    
TRACKLOOP:while(1) {
        // advance the track
        AQID++;
        if(!initializing) {
            if(!document.getElementById("repeattrack").checked) {
                Tracks_QueueCurrent = Tracks_QueueCurrent.next;
            }
        }
        initializing = 0;        
        let track = Tracks_QueueCurrent;
        if(! track) {
            unlock();
            return;
        }
        
        // cleanup nwdrflac
        if(NWDRFLAC) {
            // we can reuse it if the urls match
            if(NWDRFLAC.url !== track.url)
            {
                await NWDRFLAC.close();
                NWDRFLAC = null;
                if(mysignal.aborted) {
                    console.log('abort after cleanup');
                    unlock();
                    return;
                }
            }
            else{
                console.log('optimization using same nwdrflac: ' + track.url);
                track.duration = NWDRFLAC.totalPCMFrameCount / NWDRFLAC.sampleRate;
                track.sampleRate = NWDRFLAC.sampleRate;
            }
        }       
        
        // open the track
        for(let failedtimes = 0; !NWDRFLAC; ) {             
            try {                
                let nwdrflac = await NetworkDrFlac(track.url, mysignal);
                if(mysignal.aborted) {
                    console.log('open aborted success');
                    await nwdrflac.close();
                    unlock();
                    return;
                }
                NWDRFLAC = nwdrflac;                 
                track.duration =  nwdrflac.totalPCMFrameCount / nwdrflac.sampleRate;
                track.sampleRate = nwdrflac.sampleRate;
            }
            catch(error) {
                console.error(error);
                if(mysignal.aborted) {
                    console.log('open aborted catch');
                    unlock();                    
                    return;
                }
                failedtimes++;
                console.log('Encountered error OPEN');     
                if(failedtimes == 2) {
                    console.log('Encountered error twice, advancing to next track');                    
                    continue TRACKLOOP;
                }
            }
        }

        // queue the track
        let dectime = 0;
        if(time) {                         
            dectime = Math.floor(time * NWDRFLAC.sampleRate);            
            time = 0;
        }
        let isStart = true;      
        while(dectime < NWDRFLAC.totalPCMFrameCount) {
            let todec = Math.min(NWDRFLAC.sampleRate, NWDRFLAC.totalPCMFrameCount - dectime);
            
            // if plenty of audio is queued. Don't download yet
            let todecsecs = todec / NWDRFLAC.sampleRate;
            const  nextendtime = function(){
                return (AQ_unqueuedTime()+todecsecs);
            };
            console.log('nextendtime ' + nextendtime() + ' curdecsecs ' + todecsecs);
            while(nextendtime() > AQMaxDecodedTime) {
                let mssleep = (nextendtime()  - AQMaxDecodedTime) * 1000;
                await abortablesleep(mssleep, mysignal);
                if(mysignal.aborted) {
                    console.log('handling aborted sleep');
                    unlock();                     
                    return;
                }
            }
            
            // decode
            let buffer;
            for(let failedcount = 0;!buffer;) {
                try {
                    buffer = await NWDRFLAC.read_pcm_frames_to_AudioBuffer(dectime, todec, mysignal, MainAudioContext);
                    if(mysignal.aborted) {
                        console.log('aborted decodeaudiodata success');
                        unlock();                        
                        return;
                    }
                    if(buffer.duration !== (todec / NWDRFLAC.sampleRate)) {                       
                        buffer = null;
                        throw('network error? buffer wrong length');
                    }                        
                }
                catch(error) {
                    console.error(error);
                    if(mysignal.aborted) {
                        console.log('aborted read_pcm_frames decodeaudiodata catch');
                        unlock();                        
                        return;
                    }                   
                    failedcount++;
                    if(failedcount == 2) {
                        console.log('Encountered error twice, advancing to next track');
                         // assume it's corrupted. force free it
                        await NWDRFLAC.close();
                        NWDRFLAC = null;                      
                        continue TRACKLOOP;
                    }
                }
            }
         
            // Add to the audio queue
            let aqItem = { 'buffer' : buffer, 'duration' : todec, 'aqid' : AQID, 'skiptime' : (dectime / NWDRFLAC.sampleRate), 'track' : track, 'playbackinfo' : {}, 'timers' : []};
            // At start and end track update the GUI
            let isEnd = ((dectime+todec) === NWDRFLAC.totalPCMFrameCount);
            if(isStart || isEnd) {            
                aqItem.func = function(startTime, endTime) {
                    if(isStart) {
                        console.log('aqid: ' + aqItem.aqid + ' start timer at ' + startTime + ' currentTime ' + MainAudioContext.currentTime);
                        aqItem.timers.push({'time': startTime, 'func': function() {                             
                            seekbar.min = 0;
                            seekbar.max = track.duration;
                            SetEndtimeText(track.duration);
                            SetPlayText(track.trackname);
                            let prevtext = track.prev ? track.prev.trackname : '';
                            SetPrevText(prevtext);       
                            let nexttext =  track.next ? track.next.trackname : '';
                            SetNextText(nexttext);
                        }});
                        isStart = false;
                    }
                    if(isEnd) {
                        console.log('aqid: ' + aqItem.aqid + ' end timer at ' + endTime + ' currentTime ' + MainAudioContext.currentTime); 
                        aqItem.timers.push({'time': endTime, 'func': function(){
                            let curTime = 0;
                            SetEndtimeText(0);                    
                            SetCurtimeText(curTime);
                            SetSeekbarValue(curTime);
                            SetPrevText(track.trackname);
                            SetPlayText('');
                            SetNextText('');
                        }});
                    }
                }
            }
            AudioQueue.push(aqItem);        
            dectime += todec;
        }        
    }
    unlock();
}

var prevbtn    = document.getElementById("prevbtn");
var sktxt      = document.getElementById("seekfield");
var seekbar    = document.getElementById("seekbar");
var ppbtn      = document.getElementById("ppbtn");
var rptrackbtn = document.getElementById("repeattrack");
var curtimetxt = document.getElementById("curtime");
var endtimetxt = document.getElementById("endtime");
var nexttxt    = document.getElementById('next_text');
var prevtxt    = document.getElementById('prev_text');
var playtxt    = document.getElementById('play_text');
var dbarea     = document.getElementById('musicdb');

// BEGIN UI handlers

rptrackbtn.addEventListener('change', function(e) {
    let aqid = AQ_ID();
    if(aqid === -1) return;   // nothing is playing repeattrack should do nothing
    if(aqid === AQID) return; // current playing is still being queued do nothing 
    
    console.log('rptrack abort');
    AQ_stopAudioWithoutID(aqid); // stop the audio queue of next track(s)

    if(e.target.checked) {
        // repeat the currently playing track
        Tracks_QueueCurrent = AudioQueue[0].track;
    }
    else {
        // queue the next track
        Tracks_QueueCurrent = AudioQueue[0].track.next;
    }
    fillAudioQueue();
 });
 
 ppbtn.addEventListener('click', function (e) {
     if ((ppbtn.textContent == 'PAUSE')) {
         MainAudioContext.suspend();           
         ppbtn.textContent = 'PLAY';                        
     }
     else if ((ppbtn.textContent == 'PLAY')) {
         MainAudioContext.resume();
         ppbtn.textContent = 'PAUSE';
     }
 });
 
 seekbar.addEventListener('mousedown', function (e) {
     if(!SBAR_UPDATING) {
         SBAR_UPDATING = 1;         
     }
 });
 
 seekbar.addEventListener('change', function (e) {
     if(!SBAR_UPDATING) {
         return;
     }     
     SBAR_UPDATING = 0;
     if(AudioQueue[0]) {
         Tracks_QueueCurrent = AudioQueue[0].track;    
         AQ_stopAudioWithoutID(-1);
         
         let stime = Number(e.target.value);
         console.log('SEEK ' + stime);  
         fillAudioQueue(stime);
     }         
 });
 
 prevbtn.addEventListener('click', function (e) {
    let prevtrack;
    if(AudioQueue[0]) {
        if(!AudioQueue[0].track.prev) return;
        prevtrack = AudioQueue[0].track.prev;
    }
    else if(Tracks_QueueCurrent) {
        if(!Tracks_QueueCurrent.prev) return;
        prevtrack = Tracks_QueueCurrent.prev;
    }
    else if(Tracks_TAIL) {
        prevtrack = Tracks_TAIL;
    }
    else {
        return;
    }

    Tracks_QueueCurrent = prevtrack;
    AQ_stopAudioWithoutID(-1);
    fillAudioQueue();    
 });
 
 nextbtn.addEventListener('click', function (e) {        
    let nexttrack;
    if(AudioQueue[0]) {
        if(!AudioQueue[0].track.next) return;
        nexttrack = AudioQueue[0].track.next;
    }
    else if(Tracks_QueueCurrent) {
        if(!Tracks_QueueCurrent.next) return;
        nexttrack = Tracks_QueueCurrent.next;
    }
    else {
        return;
    }

    Tracks_QueueCurrent = nexttrack;
    AQ_stopAudioWithoutID(-1);
    fillAudioQueue(); 
 });
 
 document.getElementById("volslider").addEventListener('input', function(e) {
     GainNode.gain.setValueAtTime(e.target.value, MainAudioContext.currentTime); 
 });

 function GetItemPath(elm) {
    var els = [];
    var lastitem;
    do {
        var elmtemp = elm;
        while (elmtemp.firstChild) {
            elmtemp = elmtemp.firstChild;
        }
        if (elmtemp.textContent != lastitem) {
            lastitem = elmtemp.textContent;
            els.unshift(elmtemp.textContent);
        }

        elm = elm.parentNode;
    } while (elm.id != 'musicdb');
    var path = '';
    //console.log(els);
    els.forEach(function (part) {
        path += part + '/';
    });
    path = path.slice(0, -1);
    return path;
}

function GetChildTracks(path, nnodes) {
    path += '/';
    var nodes = [];
    for (var i = nnodes.length; i--; nodes.unshift(nnodes[i]));
    var tracks = [];
    nodes.splice(0, 1);
    nodes.forEach(function (node) {
        if (node.childNodes.length == 1) {
            var newnodes = node.childNodes[0].childNodes[0].childNodes[0].childNodes;
            var nodearr = [];
            for (var i = newnodes.length; i--; nodearr.unshift(newnodes[i]));
            var felm = nodearr[0].childNodes[0].textContent;
            var ttracks = GetChildTracks(path + felm, nodearr);
            tracks = tracks.concat(ttracks);
        }
        else {
            tracks.push(path + node.childNodes[0].childNodes[0].textContent);
        }

    });
    return tracks;
}
 
 dbarea.addEventListener('click', function (e) {
     if (e.target !== e.currentTarget) {
         console.log(e.target + ' clicked with text ' + e.target.textContent);
         if (e.target.textContent == 'Queue') {
             let path = GetItemPath(e.target.parentNode.parentNode);
             console.log("Queuing - " + path);
             if (e.target.parentNode.tagName == 'TD') {
                QueueTrack(path);
             }
             else {
                 var tracks = GetChildTracks(path, e.target.parentNode.parentNode.parentNode.childNodes);
                 QueueTracks(tracks);
             }
             e.preventDefault();
         }
         else if (e.target.textContent == 'Play') {
             let path = GetItemPath(e.target.parentNode.parentNode);
             console.log("Playing - " + path);
             if (e.target.parentNode.tagName == 'TD') {
                PlayTrack(path);
             }
             else {
                 var tracks = GetChildTracks(path, e.target.parentNode.parentNode.parentNode.childNodes);
                 PlayTracks(tracks);
             }
             e.preventDefault();
         }
     }
     e.stopPropagation();
 });
 // End ui handlers
 Number.prototype.toHHMMSS = function () {
    var sec_num = Math.floor(this); //parseInt(this, 10); // don't forget the second param
    var hours = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = sec_num - (hours * 3600) - (minutes * 60);
    var str;
    if (hours > 0) {
        if (hours < 10) { hours = "0" + hours; }
        str = hours + ':'
    }
    else {
        str = '';
    }
    //if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) { seconds = "0" + seconds; }
    return str + minutes + ':' + seconds;
}

function SetCurtimeText(seconds) {   
    curtimetxt.value = seconds.toHHMMSS();
}

function SetEndtimeText(seconds) {   
    endtimetxt.value = seconds.toHHMMSS();
}

function SetNextText(text) {
    nexttxt.innerHTML = '<span>' + text + '</span>';
}

function SetPrevText(text) {
    prevtxt.innerHTML = '<span>' + text + '</span>';
}

function SetPlayText(text) {
    playtxt.innerHTML = '<span>' + text + '</span>';
}

function SetSeekbarValue(seconds) {
    seekbar.value = seconds;           
}

function SetPPText(text) {
    ppbtn.textContent = text;    
}


function InitPPText() {
    if(MainAudioContext.state === "suspended") {
        ppbtn.textContent = "PLAY";
    }
    else {
        ppbtn.textContent = "PAUSE";
    }        
}

let PTrackUrlParams;
function _BuildPTrack() {
    PTrackUrlParams = new URLSearchParams();
    /*if (MAX_SAMPLE_RATE) PTrackUrlParams.append('max_sample_rate', MAX_SAMPLE_RATE);
    if (BITDEPTH) PTrackUrlParams.append('bitdepth', BITDEPTH);
    if (USESEGMENTS) PTrackUrlParams.append('segments', USESEGMENTS);
    if (USEINCREMENTAL) PTrackUrlParams.append('inc', USEINCREMENTAL);*/
    /*Tracks.forEach(function (track) {
        PTrackUrlParams.append('ptrack', track.trackname);
    });
    */
   for(let track = Tracks_HEAD; track; track = track.next) {
       PTrackUrlParams.append('ptrack', track.trackname);
   }
}

function BuildPTrack() {
    // window.history.replaceState is slow :(
    setTimeout(function() {
    _BuildPTrack();
    var urlstring = PTrackUrlParams.toString();
    if (urlstring != '') {
        console.log('replace state begin');
        window.history.replaceState('playlist', 'Title', '?' + urlstring);
        console.log('replace state end');
    }
    }, 1000);
}


// Main
MainAudioContext = CreateAudioContext({'sampleRate' : 44100 });

// queue the tracks in the url
let orig_ptracks = urlParams.getAll('ptrack');
if (orig_ptracks.length > 0) {
    QueueTracks(orig_ptracks);
}

setInterval(function() {
    MainAudioLoop();
}, 25);
window.requestAnimationFrame(GraphicsLoop);
//QueueTrack("Chuck Person - Chuck Person's Eccojams Vol 1 (2016 WEB) [FLAC]/A1.flac");
