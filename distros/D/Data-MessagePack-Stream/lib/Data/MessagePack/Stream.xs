#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pvbyte
#define NEED_newSVpvn_flags
#include "ppport.h"

#include <assert.h>
#include <string.h>

#include <msgpack.h>

typedef struct my_unpacker_s my_unpacker_t;

struct my_unpacker_s {
    msgpack_unpacker* unpacker;
    msgpack_unpacked result;
};

static SV*
load_bool(pTHX_ const char* const name) {
    CV* const cv = get_cv(name, GV_ADD);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    call_sv((SV*)cv, G_SCALAR);
    SPAGAIN;
    SV* const sv = newSVsv(POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
    assert(sv);
    assert(sv_isobject(sv));
    if(!SvOK(sv)) {
        Perl_croak(aTHX_ "Oops: Failed to load %"SVf, name);
    }
    return sv;
}

static SV* decode_msgpack_object(msgpack_object* obj) {
    SV* res = NULL;
    SV* key_sv;
    AV* av;
    HV* hv;
    size_t i;
    msgpack_object* o;
    msgpack_object_kv* kv;
    const char* key;
    STRLEN len;

    switch (obj->type) {
        case MSGPACK_OBJECT_NIL:
            res = newSV(0);
            break;
        case MSGPACK_OBJECT_BOOLEAN: {
          if (obj->via.boolean == 1) {
            res = newSVsv( load_bool(aTHX_ "Data::MessagePack::true") );
          } else {
            res = newSVsv( load_bool(aTHX_ "Data::MessagePack::false") );
          }
                break;
        }
        case MSGPACK_OBJECT_POSITIVE_INTEGER:
            res = newSVuv(obj->via.u64);
            break;
        case MSGPACK_OBJECT_NEGATIVE_INTEGER:
            res = newSViv(obj->via.i64);
            break;
        case MSGPACK_OBJECT_FLOAT:
            res = newSVnv(obj->via.f64);
            break;
        case MSGPACK_OBJECT_BIN:
            res = newSVpvn(obj->via.bin.ptr, obj->via.bin.size);
            break;
        case MSGPACK_OBJECT_STR:
            res = newSVpvn_utf8(obj->via.str.ptr, obj->via.str.size, 1);
            break;
        case MSGPACK_OBJECT_ARRAY: {
            av = (AV*)sv_2mortal((SV*)newAV());
            o = obj->via.array.ptr;

            for (i = 0; i < obj->via.array.size; i++) {
                av_push(av, decode_msgpack_object(o + i));
            }

            res = newRV_inc((SV*)av);
            break;
        }
        case MSGPACK_OBJECT_MAP: {
            hv = (HV*)sv_2mortal((SV*)newHV());
            kv = obj->via.map.ptr;

            for (i = 0; i < obj->via.map.size; i++) {
                key_sv = decode_msgpack_object(&((kv + i)->key));
                key = SvPV(key_sv, len);

                o   = &((kv + i)->val);
                hv_store(hv, key, len, decode_msgpack_object(o), 0);
                SvREFCNT_dec(key_sv);
            }

            res = newRV_inc((SV*)hv);
            break;
        }
        default:
            Perl_croak(aTHX_ "Unsupported msgpack type: %d", obj->type);
            break;
    }

    return res;
}

MODULE=Data::MessagePack::Stream PACKAGE=Data::MessagePack::Stream

PROTOTYPES: DISABLE

void
new(SV* sv_klass)
CODE:
{
    SV* sv_msgpack;
    HV* hv;
    my_unpacker_t* up;
    char* klass = NULL;

    hv = (HV*)sv_2mortal((SV*)newHV());
    sv_msgpack = sv_2mortal(newRV_inc((SV*)hv));

    klass = SvPV_nolen(sv_klass);

    sv_bless(sv_msgpack, gv_stashpv(klass, 1));

    Newx(up, 1, my_unpacker_t);

    up->unpacker = msgpack_unpacker_new(MSGPACK_UNPACKER_INIT_BUFFER_SIZE);
    if (NULL == up->unpacker) {
        croak("cannot allocate msgpack unpacker");
    }
    msgpack_unpacked_init(&up->result);

    sv_magic((SV*)hv, NULL, PERL_MAGIC_ext, NULL, 0);
    mg_find((SV*)hv, PERL_MAGIC_ext)->mg_obj = (SV*)up;

    ST(0) = sv_msgpack;
    XSRETURN(1);
}

void
DESTROY(my_unpacker_t* up)
CODE:
{
    msgpack_unpacker_free(up->unpacker);
    msgpack_unpacked_destroy(&up->result);
    Safefree(up);
}

void
feed(my_unpacker_t* up, SV* sv_buf)
CODE:
{
    char* buf;
    STRLEN len;

    buf = SvPV(sv_buf, len);

    msgpack_unpacker_reserve_buffer(up->unpacker, len);
    memcpy(msgpack_unpacker_buffer(up->unpacker), buf, len);
    msgpack_unpacker_buffer_consumed(up->unpacker, len);
}

int
next(my_unpacker_t* up)
CODE:
{
    RETVAL = msgpack_unpacker_next(up->unpacker, &up->result);
}
OUTPUT:
    RETVAL

void
data(my_unpacker_t* up)
CODE:
{
    SV* sv_res;

    sv_res = sv_2mortal(decode_msgpack_object(&up->result.data));

    ST(0) = sv_res;
    XSRETURN(1);
}
