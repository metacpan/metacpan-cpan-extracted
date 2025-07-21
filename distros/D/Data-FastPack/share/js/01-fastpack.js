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


  let utf8decoder=new TextDecoder("utf-8");
  let utf8encoder=new TextEncoder("utf-8");
  /* encode_message
   * arg=>{buffer: Uint8Array, inputs:array of inputs, limit:int}
   * each input is a message object of {time: float, id: int, payload; Uint8}
   */
  let ids=[];
  function encode_message(args){
    //Javascript doesn't have aliasing or inout params, so via an object....
    let padding;

    let processed=0;

    let limit=args.limit;

    let ns=args.ns;

    limit||=args.inputs.length;
    let total=0;//Total additional size to allocate to buffer

    let concat;
    let off=0;
    let in_len=0;


    let buffer=args.buffer;


    let len=0;
    let offsets=[];
    let _len;
    let temp=0;
    //Process messages converting names to ids
    if(ns){
      for(let i=0; i<limit; i++){
        if(args.inputs[i].id){
          //Convert name to id 
          let name=args.inputs[i].id;
          let id=ns.n2e[name];
          if(id == undefined){
            if(args.inputs[i].payload.length){
              //Update id tracking and lookup tables
              id=ns.free_id.pop()||ns.next_id++;
              ns.n2e[name]=id;
              ns.i2e[id]=name;

              let new_arg={buffer: buffer, inputs:[{time: args.inputs[i].time, id: id, payload: utf8encoder.encode(name) }]};
              temp=encode_message(new_arg);
              buffer=new_arg.buffer;
            }
            else {
              //Defined id, but no payload... unreg
              // Message  with no payload is unreg
              delete ns.n2e[name];
              delete ns.i2e[id];
              ns.free_id.push(id);

            }
            //Translate
            ids[i]=id;
          }
          else {
            // No namespace so no translation
            ids[i]=args.inputs[i].id;
          }
        }

      }
    }

    if(buffer){
      off=buffer.length;
      in_len=off;
    }
    
    args.buffer=buffer;
      //Process without name/id conversion
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

    total+=temp;

    if(in_len){
      // copy old input to new buffer if we had any
      concat.set(args.buffer);
    }

    let view=new DataView(concat.buffer); 

    if(ns){
      // use the translated ids
      for(let i=0; i< limit; i++){
        view.setFloat64(offsets[i], args.inputs[i].time,1);
        view.setUint32(offsets[i]+8, ids[i], 1);  /// US THE TRANSLATED ID
        view.setUint32(offsets[i]+12, args.inputs[i].payload.length, 1);
        concat.set(args.inputs[i].payload, offsets[i]+16);
      }
    }
    else {
      //use incoming ids
      for(let i=0; i< limit; i++){
        view.setFloat64(offsets[i], args.inputs[i].time,1);
        view.setUint32(offsets[i]+8, args.inputs[i].id, 1);
        view.setUint32(offsets[i]+12, args.inputs[i].payload.length, 1);
        concat.set(args.inputs[i].payload, offsets[i]+16);
      }
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
    let limit=args.limit;
    let ns=args.ns;

    args.outputs||=[];

    if(args.buffer.length< 16){
      // No room for header.. so return no results
      return 0;
    }
    let run=true;

    while((args.buffer.length-offset)>=16){
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


        if(ns && scan.id){
          let id=scan.id;
          let name=ns.i2e[id];
          if(name == undefined){
            // Id has not been seen before. use payload as name
            name=utf8decoder.decode(scan.payload);
            ns.i2e[id]=name;
            ns.n2e[name]=id;
          }
          else {
            if(scan.payload.length){
              // Id seen previously. Only push if payload is non emply
              args.outputs.push(scan);
              scan.id=name;
            }
            else {
              // No payload remove the id/name from the tables, do not pass on message
              delete ns.n2e[name];
              delete ns.i2e[id];
              ns.free_id.push(id);
            }
          }
        }
        else {
          args.outputs.push(scan);
        }
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



  // Payload is unit8 data array
  function decode_meta_payload(payload, force_mp){
    if(!force_mp && ((payload[0] == 0x5B)||(payload[0] == 0x7B))){   
      let data=utf8decoder.decode(payload);
      return JSON.parse(data);
    }
    else { 
      //if(payload[0] & 0x92){
      return msgpack.deserialize(payload); //Message pack
    }
  }

  //Encode a meta structure (object) into  the desired serialized format
  function encode_meta_payload(obj, force_mp){
    return force_mp? msgpack.serialize(obj) : utf8encoder.encode(JSON.stringify(obj));
  }

  function create_namespace() {
    return {n2e:{}, i2e:{}, next_id:1, free_id:[]};
  }

  function id_for_name(ns, name){
    return ns.n2e[name]; 
  }
  function name_for_id(ns, name){
    return ns.i2e[id]; 
  }


  let fastpack={
    encode_message:       encode_message,
    encode_fastpack:      encode_message,
    decode_message:       decode_message,
    decode_fastpack:      decode_message,
    encode_meta_payload:  encode_meta_payload,
    decode_meta_payload:  decode_meta_payload,
    create_namespace:     create_namespace,
    id_for_name:          id_for_name,
    name_for_id:          name_for_id

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
