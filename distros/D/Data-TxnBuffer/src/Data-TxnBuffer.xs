#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pvbyte
#include "ppport.h"

#define BUFFER_MAX_REUSE_SIZE  (4 * 1024)
#define BUFFER_PIECE_SIZE 64

#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <arpa/inet.h>

#if !defined(__LITTLE_ENDIAN__) && !defined(__BIG_ENDIAN__)
#if __BYTE_ORDER == __LITTLE_ENDIAN
#define __LITTLE_ENDIAN__
#elif __BYTE_ORDER == __BIG_ENDIAN
#define __BIG_ENDIAN__
#endif
#endif

typedef struct {
    char* ptr;
    size_t used;
    size_t size;
} buffer;

static buffer* buffer_init(void);
static buffer* buffer_init_buffer(buffer* b);
static buffer* buffer_init_string(const char* str);
static void buffer_free(buffer* b);
static void buffer_reset(buffer* b);

static int buffer_prepare_copy(buffer* b, size_t size);
static int buffer_prepare_append(buffer* b, size_t size);

static int buffer_copy_string(buffer* b, const char* s);
static int buffer_copy_string_len(buffer* b, const char* s, size_t s_len);
static int buffer_copy_string_buffer(buffer* b, const buffer* src);

static int buffer_append_string(buffer* b, const char* s);
static int buffer_append_string_len(buffer* b, const char* s, size_t s_len);
static int buffer_append_string_buffer(buffer* b, const buffer* src);

static int buffer_spin(buffer* b, size_t len);

static buffer* buffer_init(void) {
    buffer* b;

    b = calloc(1, sizeof(buffer));
    assert(b);

    return b;
}

static buffer* buffer_init_buffer(buffer* src) {
    buffer* b = buffer_init();
    buffer_copy_string_buffer(b, src);
    return b;
}

static void buffer_free(buffer* b) {
    if (!b) return;

    free(b->ptr);
    free(b);
}

static void buffer_reset(buffer* b) {
    if (!b) return;

    if (b->size > BUFFER_MAX_REUSE_SIZE) {
        free(b->ptr);
        b->ptr = NULL;
        b->size = 0;
    }
    else if (b->size) {
        b->ptr[0] = '\0';
    }

    b->used = 0;
}

static int buffer_prepare_copy(buffer* b, size_t size) {
    if (!b) return -1;

    if ((0 == b->size) || (size > b->size)) {
        if (b->size) free(b->ptr);

        b->size = size;
        b->size += BUFFER_PIECE_SIZE - (b->size % BUFFER_PIECE_SIZE);

        b->ptr = malloc(b->size);
        assert(b->ptr);
    }

    b->used = 0;
    return 0;
}

static int buffer_prepare_append(buffer* b, size_t size) {
    if (!b) return -1;

    if (0 == b->size) {
        b->size = size;
        b->size += BUFFER_PIECE_SIZE - (b->size % BUFFER_PIECE_SIZE);

        b->ptr = malloc(b->size);
        assert(b->ptr);
        b->used = 0;
    }
    else if (b->used + size > b->size) {
        b->size += size;
        b->size += BUFFER_PIECE_SIZE - (b->size % BUFFER_PIECE_SIZE);

        b->ptr = realloc(b->ptr, b->size);
        assert(b->ptr);
    }
    return 0;
}

static int buffer_copy_string(buffer* b, const char* s) {
    size_t s_len;
    if (!s || !b) return -1;

    s_len = strlen(s) + 1;
    buffer_prepare_append(b, s_len);

    memcpy(b->ptr, s, s_len);
    b->used = s_len;

    return 0;
}

static int buffer_copy_string_len(buffer* b, const char* s, size_t s_len) {
    if (!b || !s) return -1;

    buffer_prepare_copy(b, s_len+1);

    memcpy(b->ptr, s, s_len);
    b->ptr[s_len] = '\0';
    b->used = s_len + 1;

    return 0;
}

static int buffer_copy_string_buffer(buffer* b, const buffer* src) {
    if (!src) return -1;

    if (src->used == 0) {
        buffer_reset(b);
        return 0;
    }
    return buffer_copy_string_len(b, src->ptr, src->used - 1);
}

static int buffer_append_string(buffer* b, const char* s) {
    size_t s_len;

    if (!s || !b) return -1;

    s_len = strlen(s);
    buffer_prepare_append(b, s_len + 1);
    if (0 == b->used) b->used++;

    memcpy(b->ptr + b->used - 1, s, s_len + 1);
    b->used += s_len;

    return 0;
}

static int buffer_append_string_len(buffer* b, const char* s, size_t s_len) {
    if (!s || !b) return -1;
    if (0 == s_len) return 0;

    buffer_prepare_append(b, s_len + 1);
    if (0 == b->used) b->used++;

    memcpy(b->ptr + b->used - 1, s, s_len);
    b->used += s_len;
    b->ptr[b->used - 1] = '\0';

    return 0;
}

static int buffer_append_string_buffer(buffer* b, const buffer* src) {
    if (!src) return -1;
    if (0 == src->used) return 0;

    return buffer_append_string_len(b, src->ptr, src->used - 1);
}

static int buffer_spin(buffer* b, size_t len) {
    if (!b) return -1;
    if (0 == b->used) return 0;

    size_t rest = b->used - len;
    if (rest > 0) {
        memmove(b->ptr, b->ptr + len, rest);
        b->used -= len;
    }
    else {
        buffer_reset(b);
    }

    return 0;
}

static inline void buffer_append_u24(buffer* b, uint32_t n) {
#ifdef __LITTLE_ENDIAN__
    buffer_append_string_len(b, (const char*)&n, 3);
#else
    buffer_append_string_len(b, (const char*)&n + 1, 3);
#endif
}

static inline void buffer_append_n32(buffer* b, uint32_t n) {
#ifdef __LITTLE_ENDIAN__
    n = htonl(n);
#endif
    buffer_append_string_len(b, (const char*)&n, 4);
}

static inline void buffer_append_n24(buffer* b, uint32_t n) {
#ifdef __LITTLE_ENDIAN__
    n = htonl(n);
#endif
    buffer_append_string_len(b, (const char*)&n + 1, 3);
}

static inline void buffer_append_n16(buffer* b, uint16_t n) {
#ifdef __LITTLE_ENDIAN__
    n = htons(n);
#endif
    buffer_append_string_len(b, (const char*)&n, 2);
}

static inline uint32_t buffer_get_u24(buffer* b, int cursor) {
    uint32_t i = 0;
#ifdef __LITTLE_ENDIAN__
    memcpy(&i, b->ptr + cursor, 3);
#else
    memcpy(&i + 1, b->ptr + cursor, 3);
#endif

    return i;
}

static inline int32_t buffer_get_i24(buffer* b, int cursor) {
    int32_t i = 0;
#ifdef __LITTLE_ENDIAN__
    memcpy(&i, b->ptr + cursor, 3);
#else
    memcpy(&i + 1, b->ptr + cursor, 3);
#endif

    if (i & 0x800000) i |= 0xff000000;

    return i;
}

static inline uint32_t buffer_get_n32(buffer* b, int cursor) {
    uint32_t i = *((uint32_t*)(b->ptr + cursor));
#ifdef __LITTLE_ENDIAN__
    i = ntohl(i);
#endif
    return i;
}

static inline uint32_t buffer_get_n24(buffer* b, int cursor) {
    uint32_t i = 0;
    memcpy((uint8_t*)&i + 1, b->ptr + cursor, 3); /* network order */

#ifdef __LITTLE_ENDIAN__
    i = ntohl(i);
#endif
    return i;
}

static inline uint16_t buffer_get_n16(buffer* b, int cursor) {
    uint16_t i = *((uint16_t*)(b->ptr + cursor));
#ifdef __LITTLE_ENDIAN__
    i = ntohs(i);
#endif
    return i;
}

typedef struct {
    int cursor;
    buffer* buffer;
} txn_buffer_t;

#define BUFARGS \
    MAGIC* m; \
    buffer* b; \
    txn_buffer_t* context = NULL;              \
    m = mg_find(SvRV(sv_obj), PERL_MAGIC_ext); \
    if (NULL != m) context = (txn_buffer_t*)m->mg_obj; \
    if (NULL == context) croak("This is not Data::TxnBuffer object\n"); \
    b = context->buffer;

MODULE = Data::TxnBuffer PACKAGE = Data::TxnBuffer

SV*
new(char* class, SV* sv_data=NULL)
CODE:
{
    HV* hv;
    SV* sv;
    HV* stash;
    txn_buffer_t* context;
    buffer* b;
    char* data = NULL;
    STRLEN len;

    hv = (HV*)sv_2mortal((SV*)newHV());
    sv = sv_2mortal(newRV_inc((SV*)hv));

    stash = gv_stashpv(class, 0);
    assert(NULL != stash);
    sv_bless(sv, stash);

    b = buffer_init();

    context = malloc(sizeof(txn_buffer_t));
    context->cursor = 0;
    context->buffer = b;

    sv_magic((SV*)hv, NULL, PERL_MAGIC_ext, NULL, 0);
    mg_find((SV*)hv, PERL_MAGIC_ext)->mg_obj = (void*)context;

    if (NULL != sv_data) {
        data = SvPVbyte(sv_data, len);
        assert(NULL != data);
        buffer_append_string_len(b, data, len);
    }

    ST(0) = sv;
}

void
DESTROY(SV* sv_obj)
CODE:
{
    BUFARGS;
    buffer_free(b);
    free(context);
}

SV*
data(SV* sv_obj)
CODE:
{
    SV* sv;
    BUFARGS;

    sv = sv_2mortal(newSV(0));
    if (b->used > 0) {
        sv_setpvn(sv, b->ptr, b->used - 1);
    }
    else {
        sv_setpvn(sv, "", 0);
    }

    ST(0) = sv;
}

int
cursor(SV* sv_obj)
CODE:
{
    BUFARGS;
    RETVAL = context->cursor;
}
OUTPUT:
    RETVAL

SV*
spin(SV* sv_obj)
CODE:
{
    SV* sv;
    int r;
    unsigned char* data;
    BUFARGS;

    sv = sv_2mortal(newSV(0));
    if (context->cursor > 0) {
        sv_setpvn(sv, b->ptr, context->cursor);
        buffer_spin(b, context->cursor);
        context->cursor = 0;
    }
    else {
        sv_setpvn(sv, "", 0);
    }

    ST(0) = sv;
}

void
reset(SV* sv_obj)
CODE:
{
    BUFARGS;
    context->cursor = 0;
}

void
clear(SV* sv_obj)
CODE:
{
    BUFARGS;
    context->cursor = 0;
    buffer_reset(b);
}

int
length(SV* sv_obj)
CODE:
{
    BUFARGS;
    RETVAL = b->used > 0 ? b->used - 1 : 0;
}
OUTPUT:
    RETVAL

void
write(SV* sv_obj, SV* sv_buf)
CODE:
{
    char* buf = NULL;
    STRLEN len;
    BUFARGS;

    buf = SvPVbyte(sv_buf, len);
    assert(NULL != buf);

    buffer_append_string_len(b, buf, len);
}

SV*
read(SV* sv_obj, int len)
CODE:
{
    SV* sv;
    BUFARGS;

    if (len <= 0) {
        croak("positive value is required for read. got %d\n", len);
    }
    if (context->cursor + len > b->used) {
        croak("No enough data in buffer for read\n");
    }

    sv = sv_2mortal(newSV(0));
    sv_setpvn(sv, context->buffer->ptr + context->cursor, len);
    context->cursor += len;

    ST(0) = sv;
}

void
write_u32(SV* sv_obj, U32 n)
ALIAS:
    write_u32 = 0
    write_i32 = 1
CODE:
{
    BUFARGS;
    buffer_append_string_len(b, (const char*)&n, 4);
}

U32
read_u32(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 4 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U32 n = *((U32*)(context->buffer->ptr + context->cursor));
    context->cursor += 4;

    RETVAL = n;
}
OUTPUT:
    RETVAL

I32
read_i32(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 4 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    I32 n = *((I32*)(context->buffer->ptr + context->cursor));
    context->cursor += 4;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_u24(SV* sv_obj, U32 n)
ALIAS:
    write_u24 = 0
    write_i24 = 1
CODE:
{
    BUFARGS;
    buffer_append_u24(b, (uint32_t)n);
}

U32
read_u24(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 3 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U32 n = buffer_get_u24(b, context->cursor);
    context->cursor += 3;

    RETVAL = n;
}
OUTPUT:
    RETVAL

I32
read_i24(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 3 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    I32 n = buffer_get_i24(b, context->cursor);
    context->cursor += 3;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_u16(SV* sv_obj, U16 n)
ALIAS:
    write_u16 = 0
    write_i16 = 1
CODE:
{
    BUFARGS;
    buffer_append_string_len(b, (const char*)&n, 2);
}

U16
read_u16(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 2 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U16 n = *((U16*)(context->buffer->ptr + context->cursor));
    context->cursor += 2;

    RETVAL = n;
}
OUTPUT:
    RETVAL

I16
read_i16(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 2 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    I16 n = *((I16*)(context->buffer->ptr + context->cursor));
    context->cursor += 2;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_u8(SV* sv_obj, U8 n)
ALIAS:
    write_u8 = 0
    write_i8 = 1
CODE:
{
    BUFARGS;
    buffer_append_string_len(b, (const char*)&n, 1);
}

U8
read_u8(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 1 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U8 n = *((U8*)(context->buffer->ptr + context->cursor));
    context->cursor += 1;

    RETVAL = n;
}
OUTPUT:
    RETVAL

I8
read_i8(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 1 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    I8 n = *((I8*)(context->buffer->ptr + context->cursor));
    context->cursor += 1;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_n32(SV* sv_obj, U32 n)
CODE:
{
    BUFARGS;
    buffer_append_n32(b, n);
}

U32
read_n32(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 4 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U32 n = buffer_get_n32(b, context->cursor);
    context->cursor += 4;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_n24(SV* sv_obj, U32 n)
CODE:
{
    BUFARGS;
    buffer_append_n24(b, n);
}

U32
read_n24(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 3 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U32 n = buffer_get_n24(b, context->cursor);
    context->cursor += 3;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_n16(SV* sv_obj, U16 n)
CODE:
{
    BUFARGS;
    buffer_append_n16(b, n);
}

U16
read_n16(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 2 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    U16 n = buffer_get_n16(b, context->cursor);
    context->cursor += 2;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_float(SV* sv_obj, float n)
CODE:
{
    BUFARGS;
    buffer_append_string_len(b, (const char*)&n, 4);
}

float
read_float(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 4 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    float n = *((float*)(b->ptr + context->cursor));
    context->cursor += 4;

    RETVAL = n;
}
OUTPUT:
    RETVAL

void
write_double(SV* sv_obj, double n)
CODE:
{
    BUFARGS;
    buffer_append_string_len(b, (const char*)&n, 8);
}

double
read_double(SV* sv_obj)
CODE:
{
    BUFARGS;
    if (context->cursor + 8 >= b->used) {
        croak("No enough data in buffer for read\n");
    }

    double n = *((double*)(b->ptr + context->cursor));
    context->cursor += 8;

    RETVAL = n;
}
OUTPUT:
    RETVAL

