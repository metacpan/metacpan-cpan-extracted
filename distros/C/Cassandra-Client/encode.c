#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>
#include "define.h"
#include "proto.h"
#include "swap.h"
#include "encode.h"
#include "cc_bignum.h"

void encode_tinyint(pTHX_ SV *dest, SV *src);
void encode_smallint(pTHX_ SV *dest, SV *src);
void encode_int(pTHX_ SV *dest, SV *src);
void encode_bigint(pTHX_ SV *dest, SV *src);
void encode_blob(pTHX_ SV *dest, SV *src);
void encode_float(pTHX_ SV *dest, SV *src);
void encode_double(pTHX_ SV *dest, SV *src);
void encode_boolean(pTHX_ SV *dest, SV *src);
void encode_uuid(pTHX_ SV *dest, SV *src);
void encode_inet(pTHX_ SV *dest, SV *src);
void encode_time(pTHX_ SV *dest, SV *src);
void encode_date(pTHX_ SV *dest, SV *src);
void encode_varint(pTHX_ SV *dest, SV *src, int* int_out);
void encode_decimal(pTHX_ SV *dest, SV *src);
void encode_undef(pTHX_ SV *dest);

void encode_list(pTHX_ SV *dest, SV *src, struct cc_type *type);
void encode_map(pTHX_ SV *dest, SV *src, struct cc_type *type);
void encode_tuple(pTHX_ SV *dest, SV *src, struct cc_type *type);
void encode_udt(pTHX_ SV *dest, SV *src, struct cc_type *type);

void encode_cell(pTHX_ SV *dest, SV *src, struct cc_type *type)
{
    assert(dest && type);

    if (!src || !SvOK(src)) {
        encode_undef(aTHX_ dest);
        return;
    }

    switch (type->type_id) {
        case CC_TYPE_SMALLINT:
            encode_smallint(aTHX_ dest, src);
            break;

        case CC_TYPE_INT:
            encode_int(aTHX_ dest, src);
            break;

        case CC_TYPE_TINYINT:
            encode_tinyint(aTHX_ dest, src);
            break;

        case CC_TYPE_BIGINT:
        case CC_TYPE_TIMESTAMP:
        case CC_TYPE_COUNTER:
            encode_bigint(aTHX_ dest, src);
            break;

        case CC_TYPE_ASCII:
        case CC_TYPE_CUSTOM:
        case CC_TYPE_BLOB:
        case CC_TYPE_VARCHAR:
        case CC_TYPE_TEXT:
            encode_blob(aTHX_ dest, src);
            break;

        case CC_TYPE_FLOAT:
            encode_float(aTHX_ dest, src);
            break;

        case CC_TYPE_DOUBLE:
            encode_double(aTHX_ dest, src);
            break;

        case CC_TYPE_INET:
            encode_inet(aTHX_ dest, src);
            break;

        case CC_TYPE_BOOLEAN:
            encode_boolean(aTHX_ dest, src);
            break;

        case CC_TYPE_TIME:
            encode_time(aTHX_ dest, src);
            break;

        case CC_TYPE_DATE:
            encode_date(aTHX_ dest, src);
            break;

        case CC_TYPE_DECIMAL:
            encode_decimal(aTHX_ dest, src);
            break;

        case CC_TYPE_VARINT:
            encode_varint(aTHX_ dest, src, NULL);
            break;

        case CC_TYPE_LIST:
        case CC_TYPE_SET:
            encode_list(aTHX_ dest, src, type);
            break;

        case CC_TYPE_MAP:
            encode_map(aTHX_ dest, src, type);
            break;

        case CC_TYPE_TUPLE:
            encode_tuple(aTHX_ dest, src, type);
            break;

        case CC_TYPE_UUID:
        case CC_TYPE_TIMEUUID:
            encode_uuid(aTHX_ dest, src);
            break;

        case CC_TYPE_UDT:
            encode_udt(aTHX_ dest, src, type);
            break;

        default:
            warn("Encoder for type %d not implemented yet. Sending undef instead.", type->type_id);
            encode_undef(aTHX_ dest);
            break;
    }
}

void encode_tinyint(pTHX_ SV *dest, SV *src)
{
    unsigned char bytes[5];
    int number;

    number = SvIV(src);
    if (number > 127 || number < -128) {
        warn("encode_tinyint: number '%s' out of range", SvPV_nolen(src));
    }

    memset(bytes, 0, 3);
    bytes[3] = 1;
    bytes[4] = number;
    sv_catpvn(dest, (char*)bytes, 5);
}

void encode_smallint(pTHX_ SV *dest, SV *src)
{
    union {
        uint16_t s[3];
        unsigned char c[6];
    } stuff;
    memset(stuff.c, 0, 3);
    stuff.c[3] = 2;
    stuff.s[2] = htons((int16_t)SvIV(src));
    sv_catpvn(dest, (char*)stuff.c, 6);
}

void encode_int(pTHX_ SV *dest, SV *src)
{
    union {
        uint32_t s[2];
        unsigned char c[8];
    } stuff;
    memset(stuff.c, 0, 3);
    stuff.c[3] = 4;
    stuff.s[1] = htonl((int32_t)SvIV(src));
    sv_catpvn(dest, (char*)stuff.c, 8);
}

#ifdef CAN_64BIT
void encode_bigint(pTHX_ SV *dest, SV *src)
{
    unsigned char work[12];
    union {
        int64_t iv;
        unsigned char c[8];
    } stuff;
    stuff.iv = SvIV(src);

    work[0] = 0;
    work[1] = 0;
    work[2] = 0;
    work[3] = 8;
    bswap8(stuff.c);
    memcpy(work+4, stuff.c, 8);
    sv_catpvn(dest, (char*)work, 12);
}
#else
void encode_bigint(pTHX_ SV *dest, SV *src)
{
    SV *tmp_sv;
    int sv_len;
    char *ptr;
    unsigned char work[12];

    work[0] = 0;
    work[1] = 0;
    work[2] = 0;
    work[3] = 8;

    tmp_sv = sv_2mortal(newSV(8));
    SvPOK_on(tmp_sv);
    SvCUR_set(tmp_sv, 0);

    encode_varint(aTHX_ tmp_sv, src, &sv_len);
    if (UNLIKELY(sv_len > 8)) {
        /* Unlike our 64bit code, we have the chance to actually detect wrapping.
         * So if you're "lucky" and run a 32bit Perl, enjoy a warning on top of
         * the wrapping you probably didn't want to happen. */
        warn("Truncating scalar value: does not fit bigint");
        sv_chop(tmp_sv, SvPV_nolen(tmp_sv)+(sv_len-8));
        sv_len = 8;
    }
    assert(sv_len > 0);
    ptr = SvPV_nolen(tmp_sv);
    if (ptr[0] & 0x80) {
        /* Negative */
        memset(work+4, 0xff, 8);
    } else {
        /* Positive */
        memset(work+4, 0, 8);
    }
    memcpy(work+4+(8-sv_len), ptr, sv_len);

    sv_catpvn(dest, (char*)work, 12);
}
#endif

void encode_blob(pTHX_ SV *dest, SV *src)
{
    char *ptr;
    STRLEN length;

    ptr = SvPV(src, length);
    if (UNLIKELY(length > INT32_MAX))
        croak("cannot encode blob/string: size exceeds 2GB");

    pack_int(aTHX_ dest, length);
    sv_catpvn(dest, ptr, length);
}

void encode_float(pTHX_ SV *dest, SV *src)
{
    unsigned char work[8];
    union {
        float f;
        unsigned char c[8];
    } stuff;
    stuff.f = SvNV(src);
    work[0] = 0;
    work[1] = 0;
    work[2] = 0;
    work[3] = 4;
    bswap4(stuff.c);
    memcpy(work+4, stuff.c, 4);
    sv_catpvn(dest, (char*)work, 8);
}

void encode_double(pTHX_ SV *dest, SV *src)
{
    unsigned char work[12];
    union {
        double d;
        unsigned char c[8];
    } stuff;
    stuff.d = SvNV(src);
    work[0] = 0;
    work[1] = 0;
    work[2] = 0;
    work[3] = 8;
    bswap8(stuff.c);
    memcpy(work+4, stuff.c, 8);
    sv_catpvn(dest, (char*)work, 12);
}

void encode_boolean(pTHX_ SV *dest, SV *src)
{
    unsigned char bytes[5];
    memset(bytes, 0, 3);
    bytes[3] = 1;
    if (SvTRUE(src)) {
        bytes[4] = 1;
    } else {
        bytes[4] = 0;
    }
    sv_catpvn(dest, (char*)bytes, 5);
}

void encode_uuid(pTHX_ SV *dest, SV *src)
{
    char *ptr;
    STRLEN size;
    int i, j;
    unsigned char work[20];
    memset(work, 0, 20);

    work[3] = 16;

    ptr = SvPV(src, size);
    j = 0;
    i = 0;
    while (j < 32 && i < size) {
        char c = ptr[i++];
        if (c >= '0' && c <= '9') {
            c -= '0';
        } else if (c >= 'a' && c <= 'f') {
            c -= 'a' - 10;
        } else if (c >= 'A' && c <= 'F') {
            c -= 'A' - 10;
        } else {
            continue;
        }

        if (!(j%2))
            c <<= 4;
        work[4 + (j/2)] |= c;
        j++;
    }

    if (j != 32)
        warn("UUID '%s' is invalid", ptr);

    sv_catpvn(dest, (char*)work, 20);
}

void encode_inet(pTHX_ SV *dest, SV *src)
{
    char *ptr;
    STRLEN size;
    int semicolon, i;
    unsigned char out[20];

    ptr = SvPV(src, size);
    semicolon = 0;

    for (i = 0; i < size; i++) {
        if (ptr[i] == ':')
            semicolon++;
    }

    memset(out, 0, 20);

    if (semicolon) { /* IPv6 */
        out[3] = 16;

        if (inet_pton(AF_INET6, ptr, out+4)) {
            sv_catpvn(dest, (char*)out, 20);
        } else {
            warn("Inet address '%s' is invalid", ptr);
            encode_undef(aTHX_ dest);
        }
    } else {
        out[3] = 4;

        if (inet_pton(AF_INET, ptr, out+4)) {
            sv_catpvn(dest, (char*)out, 8);
        } else {
            warn("Inet address '%s' is invalid", ptr);
            encode_undef(aTHX_ dest);
        }
    }
}

void encode_time(pTHX_ SV *dest, SV *src)
{
    unsigned char out[12];
    STRLEN size, i, j, k;
    char *ptr;
    int numbers[4];
    int seconds, nano;

    memset(out, 0, 12);
    out[3] = 8;

    numbers[0] = numbers[1] = numbers[2] = numbers[3] = 0;

    ptr = SvPV(src, size);
    for (i = 0, j = 0; i < size; i++) {
        if (ptr[i] == ':' || ptr[i] == '.') {
            j++;
            k = 0;
            if (j > 3)
                croak("Time '%s' is invalid", ptr);
        } else if (ptr[i] >= '0' && ptr[i] <= '9') {
            numbers[j] *= 10;
            numbers[j] += ptr[i]-'0';
            k++;
        }
    }
    if (j == 3 && numbers[3] > 0) {
        for (; k<9; k++)
            numbers[3] *= 10;
    }

    nano = numbers[3];
    seconds = (((numbers[0]%24) * 3600) + (numbers[1] * 60) + numbers[2]) % 86400;
    *((int64_t*)(out+4)) = (((int64_t)seconds)*1000000000L) + (int64_t)nano;
    bswap8(out+4);
    sv_catpvn(dest, (char*)out, 12);
}

inline int div_properly(int a, int b)
{
    int n = a / b;
    if (a < 0 && a%b != 0)
        n--;
    return n;
}

void encode_date(pTHX_ SV *dest, SV *src)
{
    int negative_year, numbers[3], i, v_a, y, m, jdn;
    char *ptr;
    STRLEN size, pos;

    numbers[0] = numbers[1] = numbers[2] = 0;

    ptr = SvPV(src, size);
    if (UNLIKELY(size < 5))
        croak("Date '%s' is invalid", ptr);

    pos = 0;
    if (ptr[pos] == '-') {
        pos++;
        negative_year = 1;
    } else {
        negative_year = 0;
    }

    i = 0;
    while (pos < size) {
        if (ptr[pos] == '-') {
            i++;
            if (UNLIKELY(i >= 3))
                croak("Date '%s' is invalid", ptr);
        } else if (ptr[pos] >= '0' && ptr[pos] <= '9') {
            numbers[i] *= 10;
            numbers[i] += ptr[pos] - '0';
        } else {
            croak("Date '%s' is invalid", ptr);
        }

        pos++;
    }

    if (negative_year)
        numbers[0] *= -1;

    v_a = (numbers[1] == 1 || numbers[1] == 2) ? 1 : 0;
    y = numbers[0] + 4800 - v_a;
    m = numbers[1] + (12 * v_a) - 3;
    jdn = 1 << 31;
    jdn -= 2472633;
    jdn += numbers[2];
    jdn += div_properly((153 * m) + 2, 5);
    jdn += 365 * y;
    jdn += div_properly(y, 4);
    jdn -= div_properly(y, 100);
    jdn += div_properly(y, 400);
    pack_int(aTHX_ dest, 4);
    pack_int(aTHX_ dest, jdn);
}

void encode_varint(pTHX_ SV *dest, SV *src, int* int_out)
{
    char *ptr;
    STRLEN size;

    ptr = SvPV(src, size);
#ifdef CAN_64BIT
    if (size <= 18) {
        int i;
        union {
            int64_t number;
            unsigned char bytes[8];
        } stuff;
        stuff.number = SvIV(src);
        bswap8(stuff.bytes);
#else
    if (size <= 9) {
        int i;
        union {
            int32_t number;
            unsigned char bytes[4];
        } stuff;
        stuff.number = SvIV(src);
        bswap4(stuff.bytes);
#endif
        if (stuff.bytes[0] & 0x80) { /* negative */
            for (i = 0; i < sizeof(stuff.bytes); i++) {
                if (stuff.bytes[i] != 0xff || (i < (sizeof(stuff.bytes)-1) && !(stuff.bytes[i+1]&0x80)))
                    break;
            }
        } else {
            for (i = 0; i < sizeof(stuff.bytes); i++) {
                if (stuff.bytes[i] || (i < (sizeof(stuff.bytes)-1) && (stuff.bytes[i+1]&0x80)))
                    break;
            }
        }
        if (i == sizeof(stuff.bytes))
            i--;
        if (int_out)
            *int_out= sizeof(stuff.bytes)-i;
        else
            pack_int(aTHX_ dest, sizeof(stuff.bytes)-i);
        sv_catpvn(dest, ((char*)stuff.bytes)+i, sizeof(stuff.bytes)-i);

    } else {
        struct cc_bignum bn;
        unsigned char *tmp, *tmp2;
        size_t encoded_len, i;

        cc_bignum_init_string(&bn, ptr, size);

        Newxz(tmp, bn.length+2, unsigned char);
        Newxz(tmp2, bn.length+2, unsigned char);

        encoded_len = cc_bignum_byteify(&bn, tmp, bn.length+2);
        for (i = 0; i < encoded_len; i++) {
            tmp2[i] = tmp[encoded_len-1-i];
        }

        if (int_out)
            *int_out= encoded_len;
        else
            pack_int(aTHX_ dest, encoded_len);
        sv_catpvn(dest, (char*)tmp2, encoded_len);

        Safefree(tmp);
        Safefree(tmp2);

        cc_bignum_destroy(&bn);
    }
}

void encode_decimal(pTHX_ SV *dest, SV *src)
{
    SV *tmp;
    char *ptr;
    STRLEN size, size_pos, pos;
    int scale, varint_len;

    ptr = SvPV(src, size);

    tmp = sv_2mortal(newSV(size));
    SvPOK_on(tmp);
    SvCUR_set(tmp, 0);

    pos = 0;
    scale = 0;

    if (ptr[pos] == '-') {
        pos++;
        sv_catpvn(tmp, ptr+pos, 1);
    }
    for (; pos < size && ptr[pos] >= '0' && ptr[pos] <= '9'; pos++) {
        /* Main number */
        sv_catpvn(tmp, ptr+pos, 1);
    }
    if (ptr[pos] == '.') {
        /* Decimal point */
        pos++;
        for (; pos < size && ptr[pos] >= '0' && ptr[pos] <= '9'; pos++) {
            sv_catpvn(tmp, ptr+pos, 1);
            scale--;
        }
    }
    if (ptr[pos] == 'e' || ptr[pos] == 'E') {
        /* Explicit scale */
        int explicit_scale = 0, neg = 0;
        pos++;
        if (ptr[pos] == '-') {
            neg = 1;
            pos++;
        } else if (ptr[pos] == '+') {
            pos++;
        }

        for (; pos < size && ptr[pos] >= '0' && ptr[pos] <= '9'; pos++) {
            explicit_scale *= 10;
            explicit_scale += ptr[pos] - '0';
        }
        if (neg)
            explicit_scale *= -1;
        scale += explicit_scale;
    }

    if (pos != size)
        warn("Decimal '%s' is invalid", ptr);

    size_pos = pack_int(aTHX_ dest, 0);
    pack_int(aTHX_ dest, scale*-1);
    encode_varint(aTHX_ dest, tmp, &varint_len);
    set_packed_int(aTHX_ dest, size_pos, 4+varint_len);
}

void encode_list(pTHX_ SV *dest, SV *src, struct cc_type *type)
{
    AV *list;
    int count, i;
    struct cc_type *inner_type;
    STRLEN size_start, size_pos;

    inner_type = type->inner_type;
    assert(inner_type);

    if (UNLIKELY(!SvROK(src) || SvTYPE(SvRV(src)) != SVt_PVAV))
        croak("encode_list: argument must be an ARRAY reference");

    list = (AV*)SvRV(src);
    if (UNLIKELY(av_len(list)+1 > INT32_MAX))
        croak("encode_list: too many entries");

    size_pos = pack_int(aTHX_ dest, 0);
    size_start = SvCUR(dest);

    count = av_len(list)+1;
    pack_int(aTHX_ dest, count);

    for (i = 0; i < count; i++) {
        SV **entry;
        entry = av_fetch(list, i, 0);
        if (!entry)
            encode_undef(aTHX_ dest);
        else
            encode_cell(aTHX_ dest, *entry, inner_type);
    }

    set_packed_int(aTHX_ dest, size_pos, SvCUR(dest)-size_start);
}

void encode_map(pTHX_ SV *dest, SV *src, struct cc_type *type)
{
    HV *map;
    HE *key;
    struct cc_type *key_type, *value_type;
    int i;
    STRLEN size_pos, count_pos, size_start;

    key_type = &type->inner_type[0];
    value_type = &type->inner_type[1];
    assert(key_type && value_type);

    size_pos = pack_int(aTHX_ dest, 0);
    size_start = SvCUR(dest);
    count_pos = pack_int(aTHX_ dest, 0);

    if (UNLIKELY(!SvROK(src) || SvTYPE(SvRV(src)) != SVt_PVHV))
        croak("encode_map: argument must be a HASH reference");
    map = (HV*)SvRV(src);

    i = 0;
    hv_iterinit(map);
    while ((key = hv_iternext(map)) != NULL) {
        SV *key_sv, *value_sv;

        key_sv = HeSVKEY_force(key);
        value_sv = hv_iterval(map, key);

        encode_cell(aTHX_ dest, key_sv, key_type);
        encode_cell(aTHX_ dest, value_sv, value_type);

        i++;
    }
    set_packed_int(aTHX_ dest, size_pos, SvCUR(dest)-size_start);
    set_packed_int(aTHX_ dest, count_pos, i);
}

void encode_tuple(pTHX_ SV *dest, SV *src, struct cc_type *type)
{
    AV *arr;
    struct cc_tuple *tuple;
    int i;
    STRLEN size_pos, size_start;

    tuple = type->tuple;
    assert(tuple);

    if (UNLIKELY(!SvROK(src) || SvTYPE(SvRV(src)) != SVt_PVAV))
        croak("encode_tuple: argument must be an ARRAY reference");
    arr = (AV*)SvRV(src);

    size_pos = pack_int(aTHX_ dest, 0);
    size_start = SvCUR(dest);

    for (i = 0; i < tuple->field_count; i++) {
        struct cc_type *inner_type;
        SV **value;

        inner_type = &tuple->fields[i];
        value = av_fetch(arr, i, 0);
        if (!value)
            encode_undef(aTHX_ dest);
        else
            encode_cell(aTHX_ dest, *value, inner_type);
    }

    set_packed_int(aTHX_ dest, size_pos, SvCUR(dest) - size_start);
}

void encode_udt(pTHX_ SV *dest, SV *src, struct cc_type *type)
{
    HV *hash;
    struct cc_udt *udt;
    STRLEN size_pos, size_start;
    int entry_count, i;

    udt = type->udt;
    assert(udt);

    size_pos = pack_int(aTHX_ dest, 0);
    size_start = SvCUR(dest);

    if (UNLIKELY(!SvROK(src) || SvTYPE(SvRV(src)) != SVt_PVHV))
        croak("encode_udt: argument must be a HASH reference");
    hash = (HV*)SvRV(src);

    entry_count = HvUSEDKEYS(hash);
    if (UNLIKELY(entry_count > udt->field_count))
        croak("encode_udt: too many fields in input");

    for (i = 0; i < entry_count; i++) {
        struct cc_udt_field *field;
        HE *entry;

        field = &udt->fields[i];
        entry = hv_fetch_ent(hash, field->name, 0, field->name_hash);

        if (UNLIKELY(entry == NULL)) {
            if (i == 0) {
                croak("encode_udt: missing required fields in input");
            } else {
                croak("encode_udt: unexpected fields in input");
            }
        }

        encode_cell(aTHX_ dest, HeVAL(entry), &field->type);
    }

    set_packed_int(aTHX_ dest, size_pos, SvCUR(dest) - size_start);
}

void encode_undef(pTHX_ SV *dest)
{
    sv_catpvn(dest, "\xff\xff\xff\xff", 4);
}
