#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* this is a trimmed down version of Perl_sv_cmp which doesn't consider
 * locale and UTF8: i hope this to be  more compliant with Bencode specs  */
static int _raw_cmp(const void *v1, const void *v2) {
    STRLEN cur1, cur2;
    char *pv1, *pv2;
    int cmp, retval;
        
    pv1 = SvPV(*(SV **)v1, cur1);
    pv2 = SvPV(*(SV **)v2, cur2); 
    
    retval = memcmp((void*)pv1, (void*)pv2, cur1 < cur2 ? cur1 : cur2);
    if (retval) {
        cmp = retval < 0 ? -1 : 1;
    } else if (cur1 == cur2) {
        cmp = 0;
    } else {
        cmp = cur1 < cur2 ? -1 : 1;
    }

    return cmp;
}


static bool _is_int(char *pv, STRLEN len, STRLEN *offset) {
    STRLEN i = 0;
    bool is_int = 0;
    bool first_zero = 0;
    bool plus = 0;
    bool minus = 0;
    if (pv[0] == '+') i = plus = 1;
    if (pv[0] == '-') i = minus = 1;
        
    for (;i < len;i++) {
        if (isDIGIT(pv[i])) {
            if (!is_int && pv[i] == '0') {
                if (first_zero) {
                    first_zero = 0;
                    break;
                } else {
                    first_zero = 1;
                    continue;
                }
            }
            is_int = 1;
        } else {
            return 0;
        }
    }
    if (is_int ^ first_zero) {
        *offset = (plus || (minus && first_zero)) ? 1 : 0;
        return 1;
    } else {
        return 0;
    }
}

static void _bencode(SV *line, SV *stuff, bool coerce, bool hkey) {
    char *pv;
    STRLEN len, offset;
    
    if (hkey) {
        pv = SvPV(stuff, len);
        sv_catpvf(line, "%d:", len);
        sv_catpvn(line, pv, len);
        return;
    }
    if (SvIOK(stuff) && !SvNOK(stuff) && !SvPOK(stuff)) {
        sv_catpvf(line, "i%de", SvIVX(stuff));
        return;
    }
    if (SvROK(stuff)) {
        switch (SvTYPE(SvRV(stuff))) {
            AV *av, *keys;
            HV *hv;
            SV *sv; 
            HE *entry; 
            I32 len, i;
            case SVt_PVAV:
                sv_catpv(line, "l");
                av = (AV*)SvRV(stuff);
                len = av_len(av) + 1;
                for (i = 0; i < len; i++) {
                    _bencode(line, *av_fetch(av, i, 0), coerce, 0);
                }
                sv_catpv(line, "e");
                break;
            case SVt_PVHV:
                sv_catpv(line, "d");
                hv = (HV*)SvRV(stuff);
                keys = (AV*)sv_2mortal((SV*)newAV());
                (void)hv_iterinit(hv);
                while ((entry = hv_iternext(hv))) {
                    sv = hv_iterkeysv(entry);
                    (void)SvREFCNT_inc(sv);
                    av_push(keys, sv);
                }
                qsort(AvARRAY(keys), av_len(keys) + 1, sizeof(SV*), _raw_cmp);
                len = av_len(keys) + 1;
                for (i = 0; i < len; i++) {
                    sv = *av_fetch(keys, i, 0);
                    _bencode(line, sv, coerce, 1);
                    _bencode(line, HeVAL(
                        hv_fetch_ent(hv, sv, FALSE, 0)
                     ), coerce, 0); 
                }
                sv_catpv(line, "e");
                break;
            default:
                croak("Cannot serialize this kind of reference: %_", stuff);
        }
        return;
    }
    pv = SvPV(stuff, len);
    if (coerce && _is_int(pv, len, &offset)) {
        sv_catpvf(line, "i%se", pv + offset);
    } else {
        sv_catpvf(line, "%d:", len);
        sv_catpvn(line, pv, len);
    }
}

/* Decode XS implementation by Andrew Danforth <adanforth@gmail.com>, 
 * based entirely upon the Perl implementation by Giulio Motta */

struct decode_stack_entry {
   SV *sv;
   SV *key;
};

struct decode {
   struct decode_stack_entry *stack_entries;
   int stack_size;
   int stack_next;

   char *start;
   char *end;
   STRLEN len;

   char *ptr;
};

static void decode_free(struct decode *decode) {
   for(; decode->stack_next; decode->stack_next--) {
      struct decode_stack_entry *e = &decode->stack_entries[decode->stack_next - 1];
      if (e->sv)  SvREFCNT_dec(e->sv);
      if (e->key) SvREFCNT_dec(e->key);
   }
   Safefree(decode->stack_entries);
}

#define decode_height(s) (s->stack_next)
#define decode_top(s) (&s->stack_entries[s->stack_next - 1])
#define decode_pop(s) (&s->stack_entries[--s->stack_next])

static void decode_push(struct decode *decode, SV *sv) {
   if (decode->stack_next == decode->stack_size) {
      decode->stack_size <<= 1;
      Renew(decode->stack_entries, decode->stack_size, struct decode_stack_entry);
   }

   decode->stack_entries[decode->stack_next].sv = sv;
   decode->stack_entries[decode->stack_next].key = NULL;
   decode->stack_next++;
}

#define DECODE_CROAK(msg) { \
      decode_free(decode); \
      croak("bdecode error: %s: pos %d, %s", msg, decode->ptr - decode->start, decode->start); \
   }
#define OVERFLOW_IF(exp) if (exp) DECODE_CROAK("overflow")

static STRLEN find_num(struct decode *decode, char endchr, int allow_sign) {
   char *s = decode->ptr;
   char sign = 0;

   if (s != decode->end && allow_sign && (*s == '+' || *s == '-'))
      sign = *s++;

   for(; s < decode->end; s++) {
      if (*s == endchr) {
         STRLEN len = s - decode->ptr;
         if (sign && len == 1) 
            DECODE_CROAK("invalid number");
         return(len);
      } else if (!isDIGIT(*s)) 
         DECODE_CROAK("invalid number");
   }

   DECODE_CROAK("overflow");
}

static void push_data(struct decode *decode, SV *data) {
   if (decode_height(decode)) {
      struct decode_stack_entry *e = decode_top(decode);

      if (SvTYPE(SvRV(e->sv)) == SVt_PVAV) { /* array */
         av_push((AV*)SvRV(e->sv), data);
      } else if (SvTYPE(SvRV(e->sv)) == SVt_PVHV) { /* hash */
         if (!e->key) {
            if (SvROK(data)) DECODE_CROAK("dictionary keys must be strings");
            e->key = data;
         } else {
            if (!hv_store_ent((HV*)SvRV(e->sv), e->key, data, 0))
               SvREFCNT_dec(data);
            SvREFCNT_dec(e->key);
            e->key = NULL;
         }
      } else {
         SvREFCNT_dec(data);
         DECODE_CROAK("this should never happen");
      }
   } else {
      decode_push(decode, data);
   }
}

static void pop_data(struct decode *decode) {
   struct decode_stack_entry *e;
   
   if (!decode_height(decode)) DECODE_CROAK("format error");

   e = decode_pop(decode);
   if (e->key) {
      SvREFCNT_dec(e->sv);
      SvREFCNT_dec(e->key);
      DECODE_CROAK("dictionary key with no value");
   }
   push_data(decode, e->sv);
}

static void _cleanse(SV *sv) {
   if (SvIOK(sv) && !SvNOK(sv) && !SvPOK(sv)) return;
   (void)SvIV(sv);
   SvIOK_only(sv);
}

static SV* _bdecode(struct decode *decode) {
   I32 depth = 0;
   I32 coerce = SvTRUE(get_sv("Convert::Bencode_XS::COERCE", TRUE));

   while(decode->ptr < decode->end) {
      if (*decode->ptr == 'l') { /* array */
         decode_push(decode, newRV_noinc((SV*)newAV()));
         depth++;
         decode->ptr++;
      } else if (*decode->ptr == 'd') { /* hash */
         decode_push(decode, newRV_noinc((SV*)newHV()));
         depth++;
         decode->ptr++;
      } else if (*decode->ptr == 'e') { /* end of hash/array */
         pop_data(decode);
         depth--;
         decode->ptr++;
      } else if (*decode->ptr == 'i') { /* integer */
         STRLEN len;
         SV *n;

         decode->ptr++;
         len = find_num(decode, 'e', 1);
         if (!len)
            DECODE_CROAK("number must have nonzero length");

         n = newSVpvn(decode->ptr, len);
         if (!coerce) _cleanse(n);
         push_data(decode, n);

         decode->ptr += len + 1;
      } else if (isDIGIT(*decode->ptr)) { /* string */
         STRLEN strlen, numlen = find_num(decode, ':', 0);

         OVERFLOW_IF(decode->ptr + 1 + numlen > decode->end);

         errno = 0;
         strlen = strtol(decode->ptr, NULL, 10);
         if (errno)
            DECODE_CROAK("invalid number");

         decode->ptr += 1 + numlen;
         OVERFLOW_IF(decode->ptr + strlen > decode->end);
         push_data(decode, newSVpvn(decode->ptr, strlen));

         decode->ptr += strlen;
      } else {
         DECODE_CROAK("bad format");
      }
   }

   OVERFLOW_IF(decode->ptr > decode->end);

   if (decode_height(decode) != 1 || depth)
      DECODE_CROAK("bad format");

   return(decode_pop(decode)->sv);
}

MODULE = Convert::Bencode_XS		PACKAGE = Convert::Bencode_XS		

SV*
bencode(stuff)
    SV * stuff
    PROTOTYPE: $
    PREINIT:
        SV *line = newSV(8100);
    CODE:
        sv_setpv(line, "");
        _bencode(
            line, 
            stuff, 
            SvTRUE(get_sv("Convert::Bencode_XS::COERCE", TRUE)), 
            0
        );
        RETVAL = line;
    OUTPUT:
        RETVAL

SV*
bdecode(string)
   SV *string
   PROTOTYPE: $
   CODE:
      struct decode decode;

      if (!SvPOK(string))
         croak("bdecode only accepts scalar strings");

      decode.start = SvPV(string, decode.len);
      decode.end = decode.start + decode.len;
      decode.ptr = decode.start;
         
      decode.stack_next = 0;
      decode.stack_size = 128;
      New(0, decode.stack_entries, decode.stack_size, struct decode_stack_entry);

      RETVAL = _bdecode(&decode);

      decode_free(&decode);
   OUTPUT:
      RETVAL

void
cleanse(sv)
    SV * sv
    PROTOTYPE: $
    CODE:
        _cleanse(sv);
