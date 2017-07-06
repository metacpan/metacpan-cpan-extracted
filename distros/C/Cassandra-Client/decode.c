#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>
#include "define.h"
#include "cc_bignum.h"
#include "proto.h"
#include "decode.h"

#ifdef CAN_64BIT
static void decode_bigint  (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
#endif
static void decode_blob    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_boolean (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_date    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_decimal (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_double  (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_float   (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_inet    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_int     (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_list    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_map     (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_smallint(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_time    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_tinyint (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_tuple   (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_udt     (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_utf8    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_uuid    (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);
static void decode_varint  (pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output);

void decode_cell(pTHX_ char *input, STRLEN len, STRLEN *pos, struct cc_type *type, SV *output)
{
    char *bytes;
    STRLEN bytes_len;

    if (unpack_bytes(aTHX_ input, len, pos, &bytes, &bytes_len) != 0) {
        sv_setsv(output, &PL_sv_undef);
        return;
    }

    switch (type->type_id) {
        case CC_TYPE_ASCII:
        case CC_TYPE_CUSTOM:
        case CC_TYPE_BLOB:
            decode_blob(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_BOOLEAN:
            decode_boolean(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_VARCHAR:
        case CC_TYPE_TEXT:
            decode_utf8(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_INET:
            decode_inet(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_SET:
        case CC_TYPE_LIST:
            decode_list(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_UUID:
        case CC_TYPE_TIMEUUID:
            decode_uuid(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_FLOAT:
            decode_float(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_DOUBLE:
            decode_double(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_DECIMAL:
            decode_decimal(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_VARINT:
        case CC_TYPE_BIGINT:
        case CC_TYPE_COUNTER:
        case CC_TYPE_TIMESTAMP:
        case CC_TYPE_SMALLINT:
        case CC_TYPE_TINYINT:
        case CC_TYPE_INT:
            decode_varint(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_DATE:
            decode_date(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_TIME:
            decode_time(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_MAP:
            decode_map(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_UDT:
            decode_udt(aTHX_ bytes, bytes_len, type, output);
            break;

        case CC_TYPE_TUPLE:
            decode_tuple(aTHX_ bytes, bytes_len, type, output);
            break;

        default:
            sv_setsv(output, &PL_sv_undef);
            warn("Decoder doesn't yet understand type %d, returning undef instead", type->type_id);
            break;
    }
}

inline void bswap8(char *input)
{
    if (IS_BIG_ENDIAN)
        return;

    char tmp;

    tmp = input[0];
    input[0] = input[7];
    input[7] = tmp;

    tmp = input[1];
    input[1] = input[6];
    input[6] = tmp;

    tmp = input[2];
    input[2] = input[5];
    input[5] = tmp;

    tmp = input[3];
    input[3] = input[4];
    input[4] = tmp;
}

inline void bswap4(char *input)
{
    if (IS_BIG_ENDIAN)
        return;

    uint32_t *the_num= (uint32_t*)input;
    *the_num= ntohl(*the_num);
}

inline void bswap2(char *input)
{
    if (IS_BIG_ENDIAN)
        return;

    uint16_t *the_num= (uint16_t*)input;
    *the_num= ntohs(*the_num);
}

#ifdef CAN_64BIT
void decode_bigint(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    union {
        char bytes[8];
        int64_t bigint;
    } bytes_or_bigint;

    if (UNLIKELY(len != 8))
        croak("decode_bigint: len != 8");

    memcpy(bytes_or_bigint.bytes, input, 8);
    bswap8(bytes_or_bigint.bytes);
    sv_setiv(output, bytes_or_bigint.bigint);
}
#endif

void decode_blob(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    sv_setpvn(output, input, len);
}

void decode_double(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    union {
        char bytes[8];
        double doub;
    } bytes_or_double;

    if (UNLIKELY(len != 8))
        croak("decode_double: len != 8");

    memcpy(bytes_or_double.bytes, input, 8);
    bswap8(bytes_or_double.bytes);
    sv_setnv(output, bytes_or_double.doub);
}

void decode_float(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    union {
        char bytes[4];
        float fl;
    } bytes_or_float;

    if (UNLIKELY(len != 4))
        croak("decode_float: len != 4");

    memcpy(bytes_or_float.bytes, input, 4);
    bswap4(bytes_or_float.bytes);
    sv_setnv(output, bytes_or_float.fl);
}

void decode_int(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    union {
        char bytes[4];
        int32_t i;
    } bytes_or_int;

    if (UNLIKELY(len != 4))
        croak("decode_int: len != 4");

    memcpy(bytes_or_int.bytes, input, 4);
    bswap4(bytes_or_int.bytes);
    sv_setiv(output, bytes_or_int.i);
}

void decode_smallint(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    union {
        char bytes[2];
        int16_t i;
    } bytes_or_smallint;

    if (UNLIKELY(len != 2))
        croak("decode_smallint: len != 2");

    memcpy(bytes_or_smallint.bytes, input, 2);
    bswap2(bytes_or_smallint.bytes);
    sv_setiv(output, bytes_or_smallint.i);
}

void decode_tinyint(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    if (UNLIKELY(len != 1))
        croak("decode_tinyint: len != 1");

    int8_t number = *input;
    sv_setiv(output, number);
}

void decode_utf8(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    sv_setpvn(output, input, len);
    SvUTF8_on(output);
}

void decode_boolean(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    if (UNLIKELY(len != 1))
        croak("decode_boolean: len != 1");

    if (*input)
        sv_setsv(output, &PL_sv_yes);
    else
        sv_setsv(output, &PL_sv_no);
}

void decode_inet(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    if (len == 4) {
        char str[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, input, str, INET_ADDRSTRLEN);
        sv_setpv(output, str);

    } else if (len == 16) {
        char str[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, input, str, INET6_ADDRSTRLEN);
        sv_setpv(output, str);

    } else {
        croak("decode_inet: len != (4|16)");
    }
}

void decode_list(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    struct cc_type *inner_type;
    int i;
    AV *the_list;
    SV *the_rv;
    STRLEN pos;

    inner_type = type->inner_type;
    assert(inner_type);

    if (UNLIKELY(len < 4))
        croak("decode_list: len < 4");

    int32_t num_elements = (int32_t)ntohl(*(uint32_t*)(input));
    if (UNLIKELY(num_elements < 0))
        croak("decode_list: num_elements < 0");

    the_list = newAV();
    the_rv = newRV_noinc((SV*)the_list);
    sv_setsv(output, the_rv);
    SvREFCNT_dec(the_rv);

    pos = 4;

    for (i = 0; i < num_elements; i++) {
        SV *decoded = newSV(0);
        av_push(the_list, decoded);

        decode_cell(aTHX_ input, len, &pos, inner_type, decoded);
    }
}

void decode_uuid(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    unsigned char *uinput;

    if (UNLIKELY(len != 16))
        croak("decode_uuid: len != 16");

    uinput = (unsigned char*)input;
    sv_setpvf(output, "%.2x%.2x%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x",
        uinput[0],  uinput[1],  uinput[2],  uinput[3],
        uinput[4],  uinput[5],  uinput[6],  uinput[7],
        uinput[8],  uinput[9],  uinput[10], uinput[11],
        uinput[12], uinput[13], uinput[14], uinput[15]);
}

void decode_decimal(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    union {
        char bytes[4];
        int32_t scale;
    } bytes_or_scale;

    if (UNLIKELY(len < 5))
        croak("decode_decimal: len < 5");

    memcpy(bytes_or_scale.bytes, input, 4);
    bswap4(bytes_or_scale.bytes);
    bytes_or_scale.scale *= -1;

    decode_varint(aTHX_ input+4, len-4, type, output);
    if (bytes_or_scale.scale != 0) {
        char *sign;
        if (bytes_or_scale.scale > 0) {
            sign = "+";
        } else {
            sign = "";
        }
        sv_catpvf(output, "e%s%d", sign, bytes_or_scale.scale);
    }
}

void decode_varint(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    if (UNLIKELY(len <= 0)) {
        croak("decode_varint: len <= 0");
    } else if (len == 1) {
        decode_tinyint(aTHX_ input, len, type, output);
    } else if (len == 2) {
        decode_smallint(aTHX_ input, len, type, output);
    } else if (len == 3) {
        char bytes[4];
        memcpy(bytes+1, input, 3);
        if (input[0] & 0x80) {
            bytes[0] = 0xff;
        } else {
            bytes[0] = 0;
        }
        decode_int(aTHX_ bytes, 4, type, output);
    } else if (len == 4) {
        decode_int(aTHX_ input, len, type, output);
#ifdef CAN_64BIT
    } else if (len < 8) {
        char bytes[8];
        memset(bytes, (input[0] & 0x80) ? 0xff : 0, 8);
        memcpy(bytes+8-len, input, len);
        decode_bigint(aTHX_ bytes, 8, type, output);
    } else if (len == 8) {
        decode_bigint(aTHX_ input, len, type, output);
#endif
    } else {
        char *tmp, *tmpout;
        struct cc_bignum bn;
        int i;

        Newxz(tmpout, (len*4)+2, char);

        if (!IS_BIG_ENDIAN) {
            Newxz(tmp, len, char);
            for (i = 0; i < len; i++) {
                tmp[len-i-1] = input[i];
            }
        } else {
            tmp = input;
        }

        cc_bignum_init_bytes(&bn, tmp, len);

        cc_bignum_stringify(&bn, tmpout, (len*4)+2);
        sv_setpv(output, tmpout);

        cc_bignum_destroy(&bn);
        if (!IS_BIG_ENDIAN) {
            Safefree(tmp);
        }
        Safefree(tmpout);
    }
}

/* fun fact: fmod() doesn't actually implement the modulo operation... */
double fmod_properly(double x, double y)
{
    double mod = fmod(x, y);
    if (mod < 0)
        mod += y;
    return mod;
}

void decode_date(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    uint32_t ind;
    double f, e, J, h, g, Y, M, D;

    if (UNLIKELY(len != 4))
        croak("decode_date: len != 4");

    ind = ntohl(*(uint32_t*)input);

    /* This is why unit tests exist. :-) */
    J = ind;
    J -= 0x80000000 - 2440588;

    f = J + 1401 + floor((floor((4 * J + 274277) / 146097) * 3) / 4) - 38;
    e = (4 * f) + 3;
    g = floor(fmod_properly(e, 1461) / 4);
    h = 5 * g + 2;
    D = floor(fmod_properly(h, 153) / 5) + 1;
    M = fmod_properly((floor(h / 153) + 2), 12) + 1;
    Y = floor(e / 1461) - 4716 + floor((12 + 2 - M) / 12);

    sv_setpvf(output, "%.0lf-%02.0lf-%02.0lf", Y, M, D);
}

#ifdef CAN_64BIT
void decode_time(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    int64_t nano, seconds, hours, minutes;
    STRLEN pvlen;
    char *result;

    union {
        char bytes[8];
        int64_t bigint;
    } bytes_or_bigint;

    if (UNLIKELY(len != 8))
        croak("decode_time: len != 8");

    memcpy(bytes_or_bigint.bytes, input, 8);
    bswap8(bytes_or_bigint.bytes);

    if (UNLIKELY(bytes_or_bigint.bigint < 0 || bytes_or_bigint.bigint > 86399999999999))
        croak("decode_time: invalid value");

    nano =    bytes_or_bigint.bigint % 1000000000;
    seconds = bytes_or_bigint.bigint / 1000000000;
    hours =   seconds / 3600;
    minutes = (seconds % 3600) / 60;
    seconds = seconds % 60;

    sv_setpvf(output, "%lld:%.2lld:%.2lld.%lld", hours, minutes, seconds, nano);
    result = SvPV(output, pvlen);
    while (result[pvlen-1] == '0')
        pvlen--;
    if (result[pvlen-1] == '.')
        pvlen--;
    SvCUR_set(output, pvlen);
}
#else
//32bit compat
void decode_time(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    int32_t nano, seconds, hours, minutes;
    char *txt;
    char workbuf[20];
    STRLEN txt_len;

    decode_varint(aTHX_ input, len, type, output);
    // output now contains a string represending the ns since midnight

    txt = SvPV(output, txt_len);
    if (txt_len > 14) {
        croak("decode_time: invalid value");
    }

    if (txt_len <= 9) {
        memset(workbuf, 0, 20);
        memcpy(workbuf, txt, txt_len);
        seconds = 0;
        nano = atoi(workbuf);
    } else {
        memset(workbuf, 0, 20);
        memcpy(workbuf, txt+txt_len-9, 9);
        nano = atoi(workbuf);
        memset(workbuf, 0, 20);
        memcpy(workbuf, txt, txt_len-9);
        seconds = atoi(workbuf);
    }

    hours   = seconds / 3600;
    minutes = (seconds % 3600) / 60;
    seconds = seconds % 60;

    sv_setpvf(output, "%d:%.2d:%.2d.%d", hours, minutes, seconds, nano);
    txt = SvPV(output, txt_len);
    while (txt[txt_len-1] == '0')
        txt_len--;
    if (txt[txt_len-1] == '.')
        txt_len--;
    SvCUR_set(output, txt_len);
}
#endif

void decode_map(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    struct cc_type *key_type, *value_type;
    int i;
    STRLEN pos;
    HV *the_map;
    SV *the_rv;

    key_type = &type->inner_type[0];
    value_type = &type->inner_type[1];
    assert(key_type && value_type);

    if (UNLIKELY(len < 4))
        croak("decode_map: len < 4");

    int32_t num_elements = (int32_t)ntohl(*(uint32_t*)(input));
    if (UNLIKELY(num_elements < 0))
        croak("decode_map: num_elements < 0");

    the_map = newHV();
    the_rv = newRV_noinc((SV*)the_map);
    sv_setsv(output, the_rv);
    SvREFCNT_dec(the_rv);

    pos = 4;

    for (i = 0; i < num_elements; i++) {
        SV *key, *value;

        key = newSV(0);
        sv_2mortal(key);
        decode_cell(aTHX_ input, len, &pos, key_type, key);

        value = newSV(0);
        hv_store_ent(the_map, key, value, 0);

        decode_cell(aTHX_ input, len, &pos, value_type, value);
    }
}

void decode_udt(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    struct cc_udt *udt;
    int i;
    STRLEN pos;
    HV *the_obj;
    SV *the_rv;

    the_obj = newHV();
    the_rv = newRV_noinc((SV*)the_obj);
    sv_setsv(output, the_rv);
    SvREFCNT_dec(the_rv);

    udt = type->udt;
    assert(udt && udt->fields);

    pos = 0;

    for (i = 0; i < udt->field_count; i++) {
        if (len == pos) {
            break;
        }

        struct cc_udt_field *field;
        SV *value;

        field = &udt->fields[i];
        value = newSV(0);

        hv_store_ent(the_obj, field->name, value, field->name_hash);

        decode_cell(aTHX_ input, len, &pos, &field->type, value);
    }
}

void decode_tuple(pTHX_ char *input, STRLEN len, struct cc_type *type, SV *output)
{
    SV *the_rv;
    AV *the_tuple;
    struct cc_tuple *tuple;
    int i;
    STRLEN pos;

    the_tuple = newAV();
    the_rv = newRV_noinc((SV*)the_tuple);
    sv_setsv(output, the_rv);
    SvREFCNT_dec(the_rv);

    tuple = type->tuple;
    assert(tuple);

    pos = 0;

    for (i = 0; i < tuple->field_count; i++) {
        struct cc_type *type = &tuple->fields[i];
        SV *decoded = newSV(0);
        av_push(the_tuple, decoded);

        decode_cell(aTHX_ input, len, &pos, type, decoded);
    }
}
