class RingBuffer {

    
    constructor(type, count, subbuffercount, sharedvarssab, sab){
        this._capacity = count;
        this._size = count + 1;
        this._sab = [];
        this._buffer = [];
        this._subbuffercount = subbuffercount;        
        this._sharedvarssab = sharedvarssab;
        this._sharedvarsuint32 = new Uint32Array(this._sharedvarssab);       
        this._sab = sab;
        
        for(let i = 0; i < this._subbuffercount; i++) {            
            this._buffer[i] = new type(this._sab[i]); 
        }
    }

    // pass in array type and number of elements to create, and how many arrays
    static create(type, count, subbuffercount) {
        const sharedvarssab = new SharedArrayBuffer(8);
        let sab = [];
        const size = count+1;
        for(let i = 0; i < subbuffercount; i++) {
            sab[i] = new SharedArrayBuffer(type.BYTES_PER_ELEMENT * (size));            
        }
        return new RingBuffer(type, count, subbuffercount, sharedvarssab, sab);
    }
    
    to() {
        return {
            '_capacity' : this._capacity,
            '_subbuffercount' : this._subbuffercount,
            '_sharedvarssab' : this._sharedvarssab,
            '_sab' : this._sab
        };
    }

    _writeindex() {
        return Atomics.load(this._sharedvarsuint32, 0);
    }

    

    _readindex() {
        return Atomics.load(this._sharedvarsuint32, 1);
    }

    

    // returns the count of slots in use
    getcount() {
        const wi = this._writeindex();
        const ri = this._readindex();
        return wi >= ri ? wi-ri : (this._size - (ri - wi));
        // (writeindex - readindex) % size
        //return (this._writeindex() - this._readindex()) % this._size;        
    }
    
    // returns the number of free slots
    getspace() {
        return this._capacity - this.getcount();        
    }   
   
    _AssertSameArrayCount(param) {
        if(param.length === this._subbuffercount) return;
        throw("Different Array Counts! param " + param + " subbuffercount " + this._subbuffercount);
    }         
}

class RingBufferReader {
    constructor(rb) {
        this._rb = rb;
    }

    getcount() {
        return this._rb.getcount();
    }

    getspace() {
        return this._rb.getspace();
    }

    _setreadindex(newval) {
        Atomics.store(this._rb._sharedvarsuint32, 1, newval);
    }

    read(destarrs, max, destoffset) {
        this._rb._AssertSameArrayCount(destarrs);
        destoffset = destoffset || 0;
        const destmax = destarrs[0].length - destoffset;
        max = max || destmax;

        const tocopy = Math.min(destmax, this._rb.getcount(), max);
        if(tocopy === 0) return 0;
        
        let readindex = this._rb._readindex();
        const nextReadIndex = readindex + tocopy;        
        if(nextReadIndex < this._rb._buffer[0].length) {
            for(let i = 0; i < destarrs.length; i++) {                
                destarrs[i].set(this._rb._buffer[i].subarray(readindex, nextReadIndex), destoffset);
            }            
            readindex += tocopy;       
        }
        else {
            const overflow = nextReadIndex - this._rb._buffer[0].length;
            let newreadindex;
            for(let i = 0; i < destarrs.length; i++) { 
                const firstHalf = this._rb._buffer[i].subarray(readindex);
                const secondHalf = this._rb._buffer[i].subarray(0, overflow);       
                destarrs[i].set(firstHalf, destoffset);
                destarrs[i].set(secondHalf, firstHalf.length+destoffset);
                newreadindex = secondHalf.length;
            }            
            readindex = newreadindex;       
        }
        
        // commit that more data is available to write
        this._setreadindex(readindex);
        
        return tocopy;
    }
}

class RingBufferWriter {
    constructor(rb) {
        this._rb = rb;
    }

    getcount() {
        return this._rb.getcount();
    }

    getspace() {
        return this._rb.getspace();
    }

    _setwriteindex(newval) {
        Atomics.store(this._rb._sharedvarsuint32, 0, newval);
    }

    write(arrs, max) {
        this._rb._AssertSameArrayCount(arrs);       
        max = max || arrs[0].length;

        const count = Math.min(max, arrs[0].length);
        const space = this._rb.getspace();
        if(count > space) {
            throw("Tried to write too much data, count " + count + " space " + space);            
        }

        let writeindex = this._rb._writeindex();
        
        if((writeindex+count) < this._rb._size) {
            // copy the data for each array
            for(let i = 0; i < arrs.length; i++) {
                this._rb._buffer[i].set(arrs[i].subarray(0, count), writeindex);
            }            
            writeindex += count;
        }
        else {
            const splitIndex = this._rb._size - writeindex;
            let newwriteindex;
            for(let i = 0; i < arrs.length; i++) {
                const firstHalf = arrs[i].subarray(0, splitIndex);
                const secondHalf = arrs[i].subarray(splitIndex, count);
                this._rb._buffer[i].set(firstHalf, writeindex);
                this._rb._buffer[i].set(secondHalf);
                newwriteindex = secondHalf.length;
            }
            writeindex = newwriteindex;
        }

        
        // commit that more data is available to read
        this._setwriteindex(writeindex);       
    }

    /*
    write_from_rb_reader(srcrb, count) {
        const srccount = srcrb.getcount();
        if(srccount <= count) throw("Not enough data to read");
        const destcount = this._getcount();
        if(destcount <= count) throw("not enough room to write");
        if(this._rb._subbuffercount !== src._rb._subbuffercount) throw("different subbuffer count between dest and src");
        
        // copy the first half
        let destwi = this._rb._writeindex();
        const writeleft = this._rb._size - destwi;
        const canwrite = Math.min(count, writeleft);
        src.read(this._rb._buffer, canwrite, destwi);       
        count -= canwrite;
        destwi = (destwi+canwrite) % this._rb._size;
    
        // copy the second half if needed
        if(count > 0) {            
            destwi = 0;
            src.read(this._rb._buffer, count, destwi);
            destwi += count;
        }              
       
        // commit that more data is available to read
        this._setwriteindex(destwi); 
    }
    */
}

class Float32AudioRingBuffer {       
    
    constructor(rb, samplerate, messagerb){        
        this._rb = rb;
        this._samplerate = samplerate;
        this._messages = messagerb;
        this._MSG = {
            'SKIP' : 1
        };
    }

    getcount() {
        return this._rb.getcount();
    }
    
    gettime() {
        const count = this.getcount();
        return  count / this._samplerate;         
    }

    getspace() {
        return this._rb.getspace();
    }
    
    static createpreq(framecount, numberofchannels) {
        return {
            'rb' : RingBuffer.create(Float32Array, framecount, numberofchannels),
            'messages' : RingBuffer.create(Uint32Array, 4095, 2)
        };
    }
}

class Float32AudioRingBufferReader extends Float32AudioRingBuffer  {
    constructor(rb, samplerate, messages){
        super(rb, samplerate, messages);
        this._msgreader =  new RingBufferReader(messages);               
        this._reader = new RingBufferReader(rb);        
        this._inmessage = [new Uint32Array(1), new Uint32Array(1)];
    }
    
    static create(framecount, numberofchannels, samplerate) {
        const prereq = super.createpreq(framecount, numberofchannels); 
        return new Float32AudioRingBufferReader(prereq.rb, samplerate, prereq.messages);
    }
    
    static from(obj) {
        const rb = new RingBuffer(Float32Array, obj._rb._capacity, obj._rb._subbuffercount, obj._rb._sharedvarssab, obj._rb._sab);
        const messages = new RingBuffer(Uint32Array, obj._messages._capacity, obj._messages._subbuffercount, obj._messages._sharedvarssab, obj._messages._sab);
        return new Float32AudioRingBufferReader(rb, obj._samplerate, messages);
    }

    // (READER ONLY) reduces the amount of data to read. never move it farther than writehead 
    _setreadhead(index) {
        this._reader._setreadindex(index);
    }    
    
    // (READER ONLY)
    read(destarrs, max, destoffset) {
        return this._reader.read(destarrs, max, destoffset);       
    }

    // (READER ONLY) on the reader process messages from the writer
    processmessages() {
       while(this._msgreader.read(this._inmessage, 1) > 0) {
           if(this._inmessage[0][0] === this._MSG.SKIP) {
               this._setreadhead(this._inmessage[1][0]);
           }
       }
    }    
}

class Float32AudioRingBufferWriter extends Float32AudioRingBuffer{
    constructor(rb, samplerate, messages){        
        super(rb, samplerate, messages);
        this._msgwriter = new RingBufferWriter(messages);
        this._writer = new RingBufferWriter(rb);
        this._outmessage = [new Uint32Array(1), new Uint32Array(1)];
    }

    static create(framecount, numberofchannels, samplerate) {
        const prereq = super.createpreq(framecount, numberofchannels); 
        return new Float32AudioRingBufferWriter(prereq.rb, samplerate, prereq.messages);
    }
    
    to() {
        return {
            '_rb' : this._rb.to(),
            '_messages' : this._messages.to(),
            '_samplerate' : this._samplerate        
        };
    }

    // (WRITER ONLY)
    write(arrs, max) {
        return this._writer.write(arrs, max);
    }

    // (WRITER) ONLY)send message from the writer
    sendmessage(msgid, data) {
        this._outmessage[0][0] = msgid;
        this._outmessage[1][0] = data;
        this._msgwriter.write(this._outmessage);
    }   

    // (WRITER ONLY) empty the read buffer
    reset() {        
        this.sendmessage(this._MSG.SKIP, this._rb._writeindex());
    }
}

export {RingBuffer, Float32AudioRingBufferReader, Float32AudioRingBufferWriter};

