(function(){
  "use strict";
  /* FastPack provjdes compact and simple time series data messaging
   * [time, id, len, payload, padding]
   *    time is in seconds (double)
   *    id is channle id (uint32 little endian)
   *    len is length of payload (uint32 little endian)
   *    payload is data
   *    padding is implicit to ensure payload is a muluple of 8 bytes
   *
   *    Channel 0 is reserved for meta data, which is expected to be json or
   *    message pack encoded hash/map objects in the payload
   *    
   *    As javascript doesn't have direct aliasing of variables, the arguemnts to encode/decode
   *    are wrapped ina container object to make buffers etc in/out
   *    
   *    Fastpack payload is 'agnostic' to the type, it is assumed bytes of data.
   *
   *    The exceptiotion it the meta data, being json or msgpack
   *
   */


  /* encode_message
   * arg=>{buffer: Uint8Array, inputs:array of inputs, limit:int}
   * each input is a message object of {time: float, id: int, payload; Uint8}
   */
  function encode_message(args){
    //Javascript doesn't have aliasing or inout params, so via an object....
    let padding;

    let processed=0;

    let limit=args.limit;

    limit||=args.inputs.length;
    let total=0;//Total additional size to allocate to buffer

    let concat;
    let off=0;
    let in_len=0;
    if(args.buffer){
      off=args.buffer.length;
      in_len=off;
    }

    let len=0;
    let offsets=[];
    let _len;
    for(let i=0; i<limit; i++){
      _len=args.inputs[i].payload.length;
      padding=(_len % 8);
      if(padding){padding=8-padding}
      len=padding+16+_len;
      total+=len;
      offsets[i]=off;
      off+=len;
      //Concat input array buffer with new
    }
    concat=new Uint8Array(total+in_len);

    if(in_len){
      // copy old input to new buffer if we had any
      concat.set(args.buffer);
    }
    let view=new DataView(concat.buffer); 
    for(let i=0; i< limit; i++){
      view.setFloat64(offsets[i], args.inputs[i].time,1);
      view.setUint32(offsets[i]+8, args.inputs[i].id, 1);
      view.setUint32(offsets[i]+12, args.inputs[i].payload.length, 1);

      concat.set(args.inputs[i].payload, offsets[i]+16);
    }

    args.buffer=concat;
    return total;
  }


  /* Consumes intput buffer to generate outputs
  */
  function decode_message (args){
    //Args:
    //  { buffer:buf, outputs:[], limit:lim,}
    //buf is uint8 data array 
    let view=new DataView(args.buffer.buffer); 
    let count=0;
    let offset=0
    let _len;
    let padding=0;

    args.outputs||=[];

    if(args.buffer.length< 16){
      // No room for header.. so return no results
      return 0;
    }
    let run=true;

    while((args.buffer.length-offset)>16){
      let scan={};
      scan.time=view.getFloat64(offset,1);
      offset+=8;

      scan.id=view.getUint32(offset, 1);
      offset+=4;

      _len=view.getUint32(offset, 1);
      offset+=4;

      padding=(_len % 8);
      if(padding){padding=8-padding}
      let msgLen=16+padding+_len;
      if((args.buffer.length-offset)>=(padding +_len)){
        //scan.payload=args.buffer.subarray(offset, offset+_len);

        //Slice returns a copy of the data in a new array buffer
        scan.payload=args.buffer.slice(offset, offset+_len);
        offset+=padding+_len;

        args.outputs.push(scan);
      }
      else {
        break;
      }
    }
    //Adjust input buffer
    //args.buffer=args.buffer.subarray(offset);
    args.buffer=args.buffer.slice(offset);

    return args.outputs.length;
  }


  let utf8decoder=new TextDecoder("utf-8");
  let utf8encoder=new TextEncoder("utf-8");

  // Payload is unit8 data array
  function decode_meta_payload(payload, force_mp){
    if(!force_mp && ((payload[0] == 0x5B)||(payload[0] == 0x7B))){   
      console.log("DECODING JSON");
      let data=utf8decoder.decode(payload);
      return JSON.parse(data);
    }
    else { 
      //if(payload[0] & 0x92){
      console.log("DECODING msgpack");
      return msgpack.deserialize(payload); //Message pack
    }
  }

  //Encode a meta structure (object) into  the desired serialized format
  function encode_meta_payload(obj, force_mp){
    return force_mp? msgpack.serialize(obj) : utf8encoder.encode(JSON.stringify(obj));
  }


  let fastpack={
    encode_message:       encode_message,
    decode_message:       decode_message,
    encode_meta_payload:  encode_meta_payload,
    decode_meta_payload:  decode_meta_payload
  };

  if (typeof module === "object" && module && typeof module.exports === "object") {
    // Node.js
    module.exports = fastpack;
  }
  else {
    // Global object
    window.fastpack= fastpack;
  }

})();
