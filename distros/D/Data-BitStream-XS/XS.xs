
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* We're not using anything for which we need ppport.h */
#include "bitlist.h"
#include "sequences.h"

#define CHECKPOS \
  if (list->pos >= list->len) \
      XSRETURN_UNDEF;

#ifdef INT_MAX
  #define MAX_COUNT INT_MAX
#else
  #define MAX_COUNT 1000000000 /* big enough */
#endif

/*
 * Instead of using XPUSH to extend the stack one value at a time, we'll
 * extend this many when we run out.
 */
#define BLSTGROW 64

static int is_positive_number(const char* str) {
  size_t i;
  size_t len = strlen(str);
  if (len == 0)
    return 0;
  for (i = 0; i < len; i++) {
    if (!isdigit(str[i]))
      return 0;
  }
  return 1;
}
static UV get_uv_from_st(SV* sv) {
  if ( !SvOK(sv) )
    croak("value must be >= 0");  /* undef */
  if ( (SvIV(sv) < 0) && !is_positive_number(SvPV_nolen(sv)) )
    croak("value must be >= 0");  /* negative number */
  return SvUV(sv);
}


static int parse_binary_string(const char* str, UV* val) {
  UV v = 0;
  size_t i;
  size_t len = strlen(str);
  if (len == 0)
    return 0;
  for (i = 0; i < len; i++) {
    if      (str[i] == '0') { v = 2*v + 0; }
    else if (str[i] == '1') { v = 2*v + 1; }
    else                    { return 0; }
  }
  if (val != 0)
    *val = v;
  return len;
}


/* This is C99, and has to be wrapped in HAS_C99_VARIADIC_MACROS.
 * TODO: Find a non-variadic way to do the same thing.
 */
#define GET_CODEVP(codename, nargs, ...) \
   { \
    bool wantarray = (GIMME_V == G_ARRAY); \
    WTYPE v; \
    int c = 0; \
    if ( (list == 0) || (count == 0) || (list->pos >= list->len) ) { \
      if (wantarray) { XSRETURN_EMPTY; } else { XSRETURN_UNDEF; } \
    } \
    if (list->is_writing) { \
      croak("read while writing with %s", #codename); \
      if (wantarray) { XSRETURN_EMPTY; } else { XSRETURN_UNDEF; } \
    } \
    if (count < 0)  count = MAX_COUNT; \
    if (!wantarray) { \
      v = 0; \
      while ( (c++ < count) && (list->pos < list->len) ) \
        v = get_ ## codename(__VA_ARGS__); \
      PUSHs(sv_2mortal(newSVuv(  v  ))); \
    } else { \
      int st_size = 0; \
      int st_pos  = 0; \
      if (count < 10000) { \
        EXTEND(SP, count); \
        st_size = count; \
      } \
      while ( (c++ < count) && (list->pos < list->len) ) { \
        if (++st_pos > st_size) { EXTEND(SP, BLSTGROW); st_size += BLSTGROW; } \
        v = get_ ## codename(__VA_ARGS__); \
        PUSHs(sv_2mortal(newSVuv(  v  ))); \
      } \
    } \
   }

#define PUT_CODEVP(codename, nargs, ...) \
    if (!list->is_writing) { \
      croak("write while reading"); \
    } else { \
      int c = (nargs); \
      while (++c < items) { \
        UV n = get_uv_from_st(ST(c)); \
        put_ ## codename(__VA_ARGS__, n); \
      } \
    }

#define GET_CODE(cn)          GET_CODEVP(cn, 0, list)
#define PUT_CODE(cn)          PUT_CODEVP(cn, 0, list)
#define GET_CODEP(cn,a)       GET_CODEVP(cn, 1, list, a)
#define PUT_CODEP(cn,a)       PUT_CODEVP(cn, 1, list, a)
#define GET_CODEPP(cn,a,b)    GET_CODEVP(cn, 2, list, a, b)
#define PUT_CODEPP(cn,a,b)    PUT_CODEVP(cn, 2, list, a, b)
#define GET_CODESPP(cn,s,a,b) GET_CODEVP(cn, 2, list, s, a, b)
#define PUT_CODESPP(cn,s,a,b) PUT_CODEVP(cn, 2, list, s, a, b)

typedef BitList* Data__BitStream__XS;

MODULE = Data::BitStream::XS	PACKAGE = Data::BitStream::XS

PROTOTYPES: ENABLE

Data::BitStream::XS
new (IN const char* package, ...)
  PREINIT:
    int i;
    FileMode mode = eModeRW;
    const char* file = 0;
    const char* fheaderdata = 0;
    int   fheaderlines = 0;
    int   initial_bits = 0;
  CODE:
    if (items > 1) {
      if ( (items % 2) == 0)
        croak("new takes a hash of options");
      for (i = 1; i < items; i += 2) {
        STRLEN klen, vlen;
        const char* key = SvPV(ST(i+0), klen);
        if (!strcmp(key, "mode")) {
          const char* val = SvPV(ST(i+1), vlen);
          if     ((!strcmp(val,"r" ))||(!strcmp(val,"read")))      mode=eModeR;
          else if((!strcmp(val,"ro"))||(!strcmp(val,"readonly")))  mode=eModeRO;
          else if((!strcmp(val,"w" ))||(!strcmp(val,"write")))     mode=eModeW;
          else if((!strcmp(val,"wo"))||(!strcmp(val,"writeonly"))) mode=eModeWO;
          else if((!strcmp(val,"a" ))||(!strcmp(val,"append")))    mode=eModeA;
          else if((!strcmp(val,"rw"))||(!strcmp(val,"rdwr"))
                                     ||(!strcmp(val,"readwrite"))) mode=eModeRW;
          else
            croak("Unknown mode: %s", val);
        } else if (!strcmp(key, "file")) {
          file = SvPV(ST(i+1), vlen);
        } else if (!strcmp(key, "fheader")) {
          fheaderdata = SvPV(ST(i+1), vlen);
        } else if (!strcmp(key, "fheaderlines")) {
          fheaderlines = SvIV(ST(i+1));
        } else if (!strcmp(key, "size")) {
          initial_bits = SvIV(ST(i+1));
        }
      }
    }
    RETVAL = new(mode, file, fheaderdata, fheaderlines, initial_bits);
  OUTPUT:
    RETVAL

void
DESTROY(IN Data::BitStream::XS list)

int
_maxbits()
  CODE:
    RETVAL = BITS_PER_WORD;
  OUTPUT:
    RETVAL

void
trim(IN Data::BitStream::XS list)
  CODE:
    resize(list, list->len);

UV
len(IN Data::BitStream::XS list)
  ALIAS:
    maxlen = 1
    pos = 2
  CODE:
    RETVAL = (ix == 0) ? list->len :
             (ix == 1) ? list->maxlen
                       : list->pos;
  OUTPUT:
    RETVAL

SV *
fheader(IN Data::BitStream::XS list)
  CODE:
    if (list->file_header == 0) {
      XSRETURN_UNDEF;
    } else {
      RETVAL = newSVpv(list->file_header, 0);
    }
  OUTPUT:
    RETVAL

int
_set_pos(IN Data::BitStream::XS list, IN int n)

int
_set_len(IN Data::BitStream::XS list, IN int n)

bool
writing(IN Data::BitStream::XS list)
  CODE:
    RETVAL = list->is_writing;
  OUTPUT:
    RETVAL

void
rewind(IN Data::BitStream::XS list)
  CODE:
    if (list->is_writing)
      croak("rewind while writing");
    else
      _set_pos(list, 0);

void
skip(IN Data::BitStream::XS list, IN int bits)
  CODE:
    if (list->is_writing)
      croak("skip while writing");
    else if ((list->pos + bits) > list->len)
      croak("skip off stream");
    else
      _set_pos(list, list->pos + bits);

bool
exhausted(IN Data::BitStream::XS list)
  CODE:
    if (list->is_writing)
      croak("exhausted while writing");
    RETVAL = (list->pos >= list->len);
  OUTPUT:
    RETVAL

void
erase(IN Data::BitStream::XS list)
  CODE:
    resize(list, 0);

void
read_open(IN Data::BitStream::XS list)

void
write_open(IN Data::BitStream::XS list)

void
write_close(IN Data::BitStream::XS list)

UV
read(IN Data::BitStream::XS list, IN int bits, IN const char* flags = 0)
  PREINIT:
    int do_readahead;
  CODE:
    if (list->is_writing) {
      croak("read while writing");
      XSRETURN_UNDEF;
    }
    if ( (bits <= 0) || (bits > BITS_PER_WORD) ) {
      croak("invalid parameters: bits %d must be 1-%d",bits,(int)BITS_PER_WORD);
      XSRETURN_UNDEF;
    }
    do_readahead = (flags != 0) && (strcmp(flags, "readahead") == 0);
    if (do_readahead) {
      if (list->pos >= list->len)
        XSRETURN_UNDEF;
      RETVAL = sreadahead(list, bits);
    } else {
      if ( (list->pos + bits-1) >= list->len )
        XSRETURN_UNDEF;
      RETVAL = sread(list, bits);
    }
  OUTPUT:
    RETVAL

UV
readahead(IN Data::BitStream::XS list, IN int bits)
  CODE:
    if (list->is_writing) {
      croak("read while writing");
      XSRETURN_UNDEF;
    }
    if ( (bits <= 0) || (bits > BITS_PER_WORD) ) {
      croak("invalid parameters: bits %d must be 1-%d",bits,(int)BITS_PER_WORD);
      XSRETURN_UNDEF;
    }
    if (list->pos >= list->len)
      XSRETURN_UNDEF;
    RETVAL = sreadahead(list, bits);
  OUTPUT:
    RETVAL

void
write(IN Data::BitStream::XS list, IN int bits, IN UV v)
  CODE:
    if (!list->is_writing) {
      croak("write while reading");
      XSRETURN_UNDEF;
    }
    if ( (bits <= 0) || ( (v > 1) && (bits > BITS_PER_WORD) ) ) {
      croak("invalid parameters: bits %d must be 1-%d",bits,(int)BITS_PER_WORD);
      XSRETURN_UNDEF;
    }
    swrite(list, bits, v);

void
put_string(IN Data::BitStream::XS list, ...)
  CODE:
    if (!list->is_writing) {
      croak("write while reading");
    } else {
      int c = 0;
      while (++c < items)
        put_string(list, SvPV_nolen(ST(c)));
    }

SV *
read_string(IN Data::BitStream::XS list, IN int bits)
  PREINIT:
    char* buf;
  CODE:
    if (list->is_writing)
      { croak("read while writing"); XSRETURN_UNDEF; }
    if (bits < 0)
      { croak("invalid parameters: bits %d must be >= 0",bits); XSRETURN_UNDEF;}
    if (bits > (list->len - list->pos))
      { croak("short read"); XSRETURN_UNDEF; }
    buf = read_string(list, bits);
    RETVAL = newSVpvn(buf, bits);
    Safefree(buf);
  OUTPUT:
    RETVAL

SV*
to_raw(IN Data::BitStream::XS list)
  PREINIT:
    char* buf;
    size_t bytes;
  CODE:
    buf = to_raw(list);
    bytes = NBYTES(list->len);  /* Return just the necessary number of bytes */
    RETVAL = newSVpvn(buf, bytes);
    Safefree(buf);
  OUTPUT:
    RETVAL

void
put_raw(IN Data::BitStream::XS list, IN const char* str, IN int bits)

void
from_raw(IN Data::BitStream::XS list, IN const char* str, IN int bits)

void
_xput_stream(IN Data::BitStream::XS list, IN Data::BitStream::XS source)
  CODE:
    if (!list->is_writing) {
      croak("write while reading");
    } else {
      _xput_stream(list, source);
    }


void
get_unary(IN Data::BitStream::XS list, IN int count = 1)
  ALIAS:
    get_unary1 = 1
    get_gamma = 2
    get_delta = 3
    get_omega = 4
    get_fib = 5
    get_levenstein = 6
    get_evenrodeh = 7
    get_goldbach_g1 = 8
    get_goldbach_g2 = 9
  PPCODE:
    switch (ix) {
      case 0:   GET_CODE(unary);  break;
      case 1:   GET_CODE(unary1);  break;
      case 2:   GET_CODE(gamma);  break;
      case 3:   GET_CODE(delta);  break;
      case 4:   GET_CODE(omega);  break;
      case 5:   GET_CODE(fib);  break;
      case 6:   GET_CODE(levenstein);  break;
      case 7:   GET_CODE(evenrodeh);  break;
      case 8:   GET_CODE(goldbach_g1);  break;
      case 9:
      default:  GET_CODE(goldbach_g2);  break;
    }

void
put_unary(IN Data::BitStream::XS list, ...)
  ALIAS:
    put_unary1 = 1
    put_gamma = 2
    put_delta = 3
    put_omega = 4
    put_fib = 5
    put_levenstein = 6
    put_evenrodeh = 7
    put_goldbach_g1 = 8
    put_goldbach_g2 = 9
  PREINIT:
    int c;
  CODE:
    if (!list->is_writing) croak("write while reading");
    c = 0;
    while (++c < items) {
      UV n = get_uv_from_st(ST(c));
      switch (ix) {
        case 0:   put_unary(list,n);  break;
        case 1:   put_unary1(list,n);  break;
        case 2:   put_gamma(list,n);  break;
        case 3:   put_delta(list,n);  break;
        case 4:   put_omega(list,n);  break;
        case 5:   put_fib(list,n);  break;
        case 6:   put_levenstein(list,n);  break;
        case 7:   put_evenrodeh(list,n);  break;
        case 8:   put_goldbach_g1(list,n);  break;
        case 9:
        default:  put_goldbach_g2(list,n);  break;
      }
    }

void
get_fibgen(IN Data::BitStream::XS list, IN int m, IN int count = 1)
  ALIAS:
    get_binword = 1
    get_baer = 2
    get_boldivigna = 3
    get_comma = 4
    get_gamma_rice = 5
    get_expgolomb = 25
    get_gamma_golomb = 6
    get_gammagolomb = 26
  PPCODE:
    if (ix == 25) ix = 5;
    if (ix == 26) ix = 6;
    if ( (ix == 0 && (m < 2 || m > 16)) ||
         (ix == 1 && (m <= 0 || m > BITS_PER_WORD)) ||
         (ix == 2 && (m < -32 || m > 32)) ||
         (ix == 3 && (m < 1 || m > 15)) ||
         (ix == 4 && (m < 1 || m > 16)) ||
         (ix == 5 && (m < 0 || m > BITS_PER_WORD)) ||
         (ix == 6 && m < 1) )
      croak("invalid parameters: %d\n", m);
    switch (ix) {
      case 0:   GET_CODEP(fibgen, m);  break;
      case 1:   GET_CODEP(binword, m);  break;
      case 2:   GET_CODEP(baer, m);  break;
      case 3:   GET_CODEP(boldivigna, m);  break;
      case 4:   GET_CODEP(comma, m);  break;
      case 5:   GET_CODEP(gamma_rice, m);  break;
      case 6:
      default:  GET_CODEP(gamma_golomb, m);  break;
    }

void
put_fibgen(IN Data::BitStream::XS list, IN int m, ...)
  ALIAS:
    put_binword = 1
    put_baer = 2
    put_boldivigna = 3
    put_comma = 4
    put_gamma_rice = 5
    put_expgolomb = 25
    put_gamma_golomb = 6
    put_gammagolomb = 26
  PREINIT:
    int c;
  CODE:
    if (!list->is_writing) croak("write while reading");
    if (ix == 25) ix = 5;
    if (ix == 26) ix = 6;
    if ( (ix == 0 && (m < 2 || m > 16)) ||
         (ix == 1 && (m <= 0 || m > BITS_PER_WORD)) ||
         (ix == 2 && (m < -32 || m > 32)) ||
         (ix == 3 && (m < 1 || m > 15)) ||
         (ix == 4 && (m < 1 || m > 16)) ||
         (ix == 5 && (m < 0 || m > BITS_PER_WORD)) ||
         (ix == 6 && m < 1) )
      croak("invalid parameters: %d\n", m);
    c = 1;
    while (++c < items) {
      UV n = get_uv_from_st(ST(c));
      switch (ix) {
        case 0:   put_fibgen(list,m,n);  break;
        case 1:   put_binword(list,m,n);  break;
        case 2:   put_baer(list,m,n);  break;
        case 3:   put_boldivigna(list,m,n);  break;
        case 4:   put_comma(list,m,n);  break;
        case 5:   put_gamma_rice(list,m,n);  break;
        case 6:
        default:  put_gamma_golomb(list,m,n);  break;
      }
    }


void
get_blocktaboo(IN Data::BitStream::XS list, IN const char* taboostr, IN int count = 1)
  PREINIT:
    int k;
    UV  taboo;
  PPCODE:
    k = parse_binary_string(taboostr, &taboo);
    if ( (k < 1) || (k > 16) ) {
      croak("invalid parameters: block taboo %s", taboostr);
      XSRETURN_UNDEF;
    }
    GET_CODEPP(block_taboo, k, taboo);

void
put_blocktaboo(IN Data::BitStream::XS list, IN const char* taboostr, ...)
  PREINIT:
    int k;
    UV  taboo;
  CODE:
    k = parse_binary_string(taboostr, &taboo);
    if ( (k < 1) || (k > 16) ) {
      croak("invalid parameters: block taboo %s", taboostr);
      return;
    }
    /* We've turned one argument into two */
    PUT_CODEVP(block_taboo, 1, list, k, taboo);

void
_xget_rice_sub(IN Data::BitStream::XS list, IN SV* coderef, IN int k, IN int count = 1)
  PREINIT:
    SV* self = ST(0);
    SV* cref = 0;
  PPCODE:
    if ( (k < 0) || (k > BITS_PER_WORD) ) {
      croak("invalid parameters: rice %d", k);
      XSRETURN_UNDEF;
    }
    if (!SvROK(coderef)) {
      self = 0;
      cref = 0;
    } else {
      if ((!SvROK(coderef)) || (SvTYPE(SvRV(coderef)) != SVt_PVCV) ) {
        croak("invalid parameters: rice coderef");
        return;
      }
      cref = SvRV(coderef);
    }
    GET_CODESPP(rice_sub, self, cref, k);

void
_xput_rice_sub(IN Data::BitStream::XS list, IN SV* coderef, IN int k, ...)
  PREINIT:
    SV* self = ST(0);
    SV* cref = 0;
  CODE:
    if ( (k < 0) || (k > BITS_PER_WORD) ) {
      croak("invalid parameters: rice %d", k);
      return;
    }
    if (!SvROK(coderef)) {
      self = 0;
      cref = 0;
    } else {
      if ((!SvROK(coderef)) || (SvTYPE(SvRV(coderef)) != SVt_PVCV) ) {
        croak("invalid parameters: rice coderef");
        return;
      }
      cref = SvRV(coderef);
    }
    PUT_CODESPP(rice_sub, self, cref, k);

void
_xget_golomb_sub(IN Data::BitStream::XS list, IN SV* coderef, IN UV m, IN int count = 1)
  PREINIT:
    SV* self = ST(0);
    SV* cref = 0;
  PPCODE:
    if (m < W_ONE) {
      croak("invalid parameters: golomb %lu", m);
      XSRETURN_UNDEF;
    }
    if (!SvROK(coderef)) {
      self = 0;
      cref = 0;
    } else {
      if ((!SvROK(coderef)) || (SvTYPE(SvRV(coderef)) != SVt_PVCV) ) {
        croak("invalid parameters: golomb coderef");
        return;
      }
      cref = SvRV(coderef);
    }
    GET_CODESPP(golomb_sub, self, cref, m);

void
_xput_golomb_sub(IN Data::BitStream::XS list, IN SV* coderef, IN UV m, ...)
  PREINIT:
    SV* self = ST(0);
    SV* cref = 0;
  CODE:
    if (m < W_ONE) {
      croak("invalid parameters: golomb %lu", m);
      return;
    }
    if (!SvROK(coderef)) {
      self = 0;
      cref = 0;
    } else {
      if ((!SvROK(coderef)) || (SvTYPE(SvRV(coderef)) != SVt_PVCV) ) {
        croak("invalid parameters: golomb coderef");
        return;
      }
      cref = SvRV(coderef);
    }
    PUT_CODESPP(golomb_sub, self, cref, m);


void
_xget_arice_sub(list, coderef, k, count=1)
      Data::BitStream::XS list
      SV* coderef
      int &k
      int count
  PREINIT:
    SV* self = ST(0);
    SV* cref = 0;
    SV* stack_k_ptr = ST(2);  /* Remember position of k, it will be modified */
  PPCODE:
    if ( (k < 0) || (k > BITS_PER_WORD) ) {
      croak("invalid parameters: adaptive_rice %d", k);
      XSRETURN_UNDEF;
    }
    if (!SvROK(coderef)) {
      self = 0;
      cref = 0;
    } else {
      if ((!SvROK(coderef)) || (SvTYPE(SvRV(coderef)) != SVt_PVCV) ) {
        croak("invalid parameters: adaptive_rice coderef");
        return;
      }
      cref = SvRV(coderef);
    }
    GET_CODESPP(adaptive_rice_sub, self, cref, &k);
    /* Return the modified k back to Perl */
    sv_setiv(stack_k_ptr, k);
    SvSETMAGIC(stack_k_ptr);

void
_xput_arice_sub(list, coderef, k, ...)
      Data::BitStream::XS list
      SV* coderef
      int &k
  PREINIT:
    SV* self = ST(0);
    SV* cref = 0;
  CODE:
    if ( (k < 0) || (k > BITS_PER_WORD) ) {
      croak("invalid parameters: adaptive_rice %d", k);
      return;
    }
    if (!SvROK(coderef)) {
      self = 0;
      cref = 0;
    } else {
      if ((!SvROK(coderef)) || (SvTYPE(SvRV(coderef)) != SVt_PVCV) ) {
        croak("invalid parameters: adaptive_rice coderef");
        return;
      }
      cref = SvRV(coderef);
    }
    PUT_CODESPP(adaptive_rice_sub, self, cref, &k);
  OUTPUT:
    k


void
get_startstop(IN Data::BitStream::XS list, IN SV* p, IN int count = 1)
  PREINIT:
    char* map;
  PPCODE:
    map = make_startstop_prefix_map(p);
    if (map == 0) {
      XSRETURN_UNDEF;
    }
    /* TODO: we'll skip free in some croak conditions */
    GET_CODEP(startstop, map);
    Safefree(map);

void
put_startstop(IN Data::BitStream::XS list, IN SV* p, ...)
  PREINIT:
    char* map;
  CODE:
    map = make_startstop_prefix_map(p);
    if (map == 0)
       return;
    PUT_CODEVP(startstop, 1, list, map);
    Safefree(map);


void prime_init(IN UV n)

UV prime_count(IN UV n)

UV nth_prime(IN UV n)

int is_prime(IN UV n)
