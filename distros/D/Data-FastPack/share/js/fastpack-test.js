console.log(msgpack);
console.log(fastpack);


{
  console.log("JSON object/map");
  let obj={hello:"there"};
  let fp_encode=fastpack.encode_meta_payload(obj, 0);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode, 0);

  console.log("Input",obj);
  console.log("Output",fp_decode);
}

{

  console.log("JSON array");
  let obj=[1,2,3];
  let fp_encode=fastpack.encode_meta_payload(obj, 0);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode,0);
  console.log("Input",obj);
  console.log("Output",fp_decode);
}

{
  console.log("Message pack object/map");
  let obj={hello:"there"};
  let fp_encode=fastpack.encode_meta_payload(obj, 1);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode, 0);
  console.log("Input",obj);
  console.log("Output",fp_decode);
}
{
  console.log("Message pack array");
  let obj=[1,2,3];
  let fp_encode=fastpack.encode_meta_payload(obj, 1);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode, 0);
  console.log("Input",obj);
  console.log("Output",fp_decode);
}



//
{
  let input=new Float64Array(1);
  input[0]=123232;
  let args={buffer:undefined, inputs:[{time:0 , id: 1, payload: new Uint8Array(input.buffer)}]};
  let e=fastpack.encode_message(args);
  let d=fastpack.decode_message(args);
  console.log("input:",args);
  console.log("output:", args);
}
