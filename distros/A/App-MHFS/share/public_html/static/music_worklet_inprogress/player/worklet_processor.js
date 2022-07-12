import { Float32AudioRingBufferReader } from './AudioWriterReader.js'


class MusicProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this._initialized = false;
    this.port.onmessage = (e) => {
          console.log(e.data);
          if(e.data.message == 'init') {
                this._audioreader = Float32AudioRingBufferReader.from(e.data.audiobuffer);
                this._initialized = true;
          }
    };
  }

    process (inputs, outputs, parameters) {
      if(!this._initialized) {
        //this._lasttime = currentTime;   
        return true;
      }
      
      /*
      const newtime = currentTime;
      const delta = newtime - this._lasttime;
      if(delta > 0.00291) {
          console.error("ACTUAL XRUN " + delta);
      }
      this._lasttime = newtime;
      */

       // possibly adjust the readindex
      this._audioreader.processmessages();
      
      // fill the buffer with audio
      this._audioreader.read(outputs[0]);            
      return true
    }
  }
  
  registerProcessor('MusicProcessor', MusicProcessor);

  