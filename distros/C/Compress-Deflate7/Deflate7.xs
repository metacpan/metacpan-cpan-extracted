#define INITGUID
#include "7zip/CPP/Common/MyInitGuid.h"
#include "7zip/CPP/7zip/IStream.h"
#include "7zip/CPP/7zip/Compress/ZlibEncoder.h"
#include "7zip/CPP/7zip/Common/FileStreams.h"
#include "7zip/CPP/7zip/Common/StreamObjects.h"

extern "C"
{
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

void setCoderProps(NCompress::NDeflate::NEncoder::CCOMCoder* c, unsigned int algo, unsigned int pass, unsigned int fast, unsigned int cycles) {
  HRESULT hr;
  PROPVARIANT v;
  PROPID algoProp = NCoderPropID::kAlgorithm;
  PROPID passProp = NCoderPropID::kNumPasses;
  PROPID fastProp = NCoderPropID::kNumFastBytes;
  PROPID cyclProp = NCoderPropID::kMatchFinderCycles;

  v.vt = VT_UI4;

  // TODO: This probably leaks memory on croaking.

  v.ulVal = algo;
  hr = c->SetCoderProperties(&algoProp, &v, 1);
  if (hr != S_OK)
    croak("Bad algo value");

  v.ulVal = pass;
  hr = c->SetCoderProperties(&passProp, &v, 1);
  if (hr != S_OK)
    croak("Bad pass value");

  v.ulVal = fast;
  hr = c->SetCoderProperties(&fastProp, &v, 1);
  if (hr != S_OK)
    croak("Bad fast value");

  v.ulVal = cycles;
  hr = c->SetCoderProperties(&cyclProp, &v, 1);
  if (hr != S_OK)
    croak("Bad cycles value");
}

SV* internalZlib7(const char* data, size_t len, unsigned int algo, unsigned int pass, unsigned int fast, unsigned int cycles) {

  NCompress::NZlib::CEncoder c;
  CBufInStream* inStream = new CBufInStream;
  CDynBufSeqOutStream* outStream = new CDynBufSeqOutStream;

  inStream->Init((const Byte*)data, len);

  CMyComPtr<ISequentialInStream> in(inStream);
  CMyComPtr<ISequentialOutStream> out(outStream);

  c.Create();

  setCoderProps(c.DeflateEncoderSpec, algo, pass, fast, cycles);

  c.Code(in, out, NULL, NULL, NULL);

  const char* deflated = (const char*)outStream->GetBuffer();
  return newSVpvn(deflated, outStream->GetSize());
}

SV* internalDeflate7(const char* data, size_t len, unsigned int algo, unsigned int pass, unsigned int fast, unsigned int cycles) {

  // TODO: Factor the common code

  NCompress::NDeflate::NEncoder::CCOMCoder c;
  CBufInStream* inStream = new CBufInStream;
  CDynBufSeqOutStream* outStream = new CDynBufSeqOutStream;

  inStream->Init((const Byte*)data, len);

  CMyComPtr<ISequentialInStream> in(inStream);
  CMyComPtr<ISequentialOutStream> out(outStream);

  setCoderProps(&c, algo, pass, fast, cycles);

  c.Code(in, out, NULL, NULL, NULL);

  const char* deflated = (const char*)outStream->GetBuffer();
  return newSVpvn(deflated, outStream->GetSize());
}


MODULE = Compress::Deflate7		PACKAGE = Compress::Deflate7		

void
_zlib7(sv, algo, pass, fb, cycles)
    SV* sv
    unsigned int algo
    unsigned int pass
    unsigned int fb
    unsigned int cycles
  PREINIT:
    STRLEN len;
    char* data;
  PPCODE:
    data = SvPVbyte(sv, len);
    mXPUSHs(internalZlib7(data, len, algo, pass, fb, cycles));

void
_deflate7(sv, algo, pass, fb, cycles)
    SV* sv
    unsigned int algo
    unsigned int pass
    unsigned int fb
    unsigned int cycles
  PREINIT:
    STRLEN len;
    char* data;
  PPCODE:
    data = SvPVbyte(sv, len);
    mXPUSHs(internalDeflate7(data, len, algo, pass, fb, cycles));
