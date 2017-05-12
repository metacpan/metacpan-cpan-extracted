#define PERL_NO_GET_CONTEXT

extern "C" {
#include "EXTERN.h"
#include "perl.h"
}

#include "XSUB.h"
#include "binbuffer.h"

MODULE = Data::BinaryBuffer       PACKAGE = Data::BinaryBuffer

BinaryBuffer*
BinaryBuffer::new();

void
BinaryBuffer::DESTROY();

BinaryBuffer*
read_buffer(BinaryBuffer* THIS, int len)
CODE:
    RETVAL = THIS->read_buffer(len);
    const char* CLASS = "Data::BinaryBuffer";
OUTPUT:
    RETVAL

SV*
read(BinaryBuffer* THIS, int len)
CODE:
    RETVAL = newSV(len);
    SvUPGRADE(RETVAL, SVt_PV);
    int actual_len = THIS->read(SvPVX(RETVAL), len);
    SvCUR_set(RETVAL, actual_len);
    SvPOK_only(RETVAL);
    *SvEND(RETVAL) = (char)0;
OUTPUT:
    RETVAL

void
write(BinaryBuffer* THIS, SV* sv)
CODE:
    STRLEN len;
    const char* src = SvPVbyte(sv, len);
    THIS->write(src, len);

int
size(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->size();
OUTPUT:
    RETVAL


uint8_t
read_uint8(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral<uint8_t>();
OUTPUT:
    RETVAL


uint16_t
read_uint16be(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_be<uint16_t>();
OUTPUT:
    RETVAL


uint16_t
read_uint16le(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_le<uint16_t>();
OUTPUT:
    RETVAL


uint32_t
read_uint32be(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_be<uint32_t>();
OUTPUT:
    RETVAL


uint32_t
read_uint32le(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_le<uint32_t>();
OUTPUT:
    RETVAL


int8_t
read_int8(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral<int8_t>();
OUTPUT:
    RETVAL


int16_t
read_int16be(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_be<int16_t>();
OUTPUT:
    RETVAL


int16_t
read_int16le(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_le<int16_t>();
OUTPUT:
    RETVAL


uint32_t
read_int32be(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_be<int32_t>();
OUTPUT:
    RETVAL


uint32_t
read_int32le(BinaryBuffer* THIS)
CODE:
    RETVAL = THIS->read_integral_le<int32_t>();
OUTPUT:
    RETVAL


void
write_uint8(BinaryBuffer* THIS,uint8_t arg2)
CODE:
    THIS->write_integral(arg2);


void
write_uint16be(BinaryBuffer* THIS,uint16_t arg2)
CODE:
    THIS->write_integral_be(arg2);


void
write_uint16le(BinaryBuffer* THIS,uint16_t arg2)
CODE:
    THIS->write_integral_le(arg2);


void
write_uint32be(BinaryBuffer* THIS,uint32_t arg2)
CODE:
    THIS->write_integral_be(arg2);


void
write_uint32le(BinaryBuffer* THIS,uint32_t arg2)
CODE:
    THIS->write_integral_le(arg2);


void
write_int8(BinaryBuffer* THIS,int8_t arg2)
CODE:
    THIS->write_integral(arg2);


void
write_int16be(BinaryBuffer* THIS,int16_t arg2)
CODE:
    THIS->write_integral_be(arg2);


void
write_int16le(BinaryBuffer* THIS,int16_t arg2)
CODE:
    THIS->write_integral_le(arg2);


void
write_int32be(BinaryBuffer* THIS,int32_t arg2)
CODE:
    THIS->write_integral_be(arg2);


void
write_int32le(BinaryBuffer* THIS,int32_t arg2)
CODE:
    THIS->write_integral_le(arg2);


