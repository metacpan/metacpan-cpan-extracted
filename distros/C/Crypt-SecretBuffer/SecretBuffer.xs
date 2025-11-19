#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#define NEED_newSVpvn_share
#define NEED_SvRX
#define NEED_RX_PRECOMP
#define NEED_RX_PRELEN
#include "ppport.h"
/* these weren't supplied by ppport.h */
#ifndef RX_PRECOMP
   #define RX_PRECOMP(rx)  ((rx)->precomp)
   #define RX_PRELEN(rx)   ((rx)->prelen)
#endif

#include "SecretBuffer_config.h"

#ifndef HAVE_BOOL
   #define bool int
   #define true 1
   #define false 0
#endif

#include "SecretBuffer.h"

typedef struct secret_buffer_span {
   size_t pos, lim;
   int encoding;
} secret_buffer_span;

// For typemap
typedef secret_buffer_span *auto_secret_buffer_span;

/**********************************************************************************************\
* XS Utils
\**********************************************************************************************/

/* Common perl idioms for negative offset or negative count meaning a position
 * measured backward from the end.
 */
static inline IV normalize_offset(IV ofs, IV len) {
   if (ofs < 0) {
      ofs += len;
      if (ofs < 0)
         ofs= 0;
   }
   else if (ofs > len)
      ofs= len;
   return ofs;
}

/* For exported constant dualvars */
#define EXPORT_ENUM(x) newCONSTSUB(stash, #x, new_enum_dualvar(aTHX_ x, newSVpvs_share(#x)))
static SV * new_enum_dualvar(pTHX_ IV ival, SV *name) {
   SvUPGRADE(name, SVt_PVNV);
   SvIV_set(name, ival);
   SvIOK_on(name);
   SvREADONLY_on(name);
   return name;
}

/**********************************************************************************************\
* Platform compatibility stuff
\**********************************************************************************************/

#ifdef WIN32

static size_t get_page_size() {
   SYSTEM_INFO sysInfo;
   GetSystemInfo(&sysInfo);
   return sysInfo.dwPageSize;
}

typedef DWORD syserror_type;
#define GET_SYSERROR(x) ((x)= GetLastError())
#define SET_SYSERROR(x) SetLastError(x)

static void croak_with_syserror(const char *prefix, DWORD error_code) {
   char message_buffer[512];
   DWORD length;

   length = FormatMessageA(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL,
      error_code,
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      message_buffer,
      sizeof(message_buffer),
      NULL
   );

   if (length)
      croak("%s: %s (%lu)", prefix, message_buffer, error_code);
   else
      croak("%s: %lu", prefix, error_code);
}

#else /* not WIN32 */

static size_t get_page_size() {
   long pagesize = sysconf(_SC_PAGESIZE);
   return (pagesize < 0)? 4096 : pagesize;
}

#define GET_SYSERROR(x) ((x)= errno)
#define SET_SYSERROR(x) (errno= (x))
typedef int syserror_type;

#define croak_with_syserror(msg, err) croak("%s: %s", msg, strerror(err))

#endif

/* Shim for systems that lack memmem */
#ifndef HAVE_MEMMEM
static void* memmem(
   const void *haystack, size_t haystacklen,
   const void *needle, size_t needlelen
) {
   if (!needle || !needlelen) {
      return haystack;
   }
   else if (!haystack || !haystacklen) {
      return NULL;
   }
   else {
      const char *p= (const char*) haystack;
      const char *lim= p + haystacklen - (needlelen - 1);
      char first_ch= *(char*)needle;
      while (p < lim) {
         if (*p == first_ch) {
            if (memcmp(p, needle, needlelen) == 0)
               return (void*)p;
         }
         ++p;
      }
   }
   return NULL;
}
#endif /* HAVE_MEMMEM */

/**********************************************************************************************\
* MAGIC vtables
\**********************************************************************************************/

#ifdef USE_ITHREADS
static int secret_buffer_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param);
static int secret_buffer_stringify_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *params);
static int secret_buffer_async_result_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *params);
static int secret_buffer_span_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *params);
#else
#define secret_buffer_magic_dup 0
#define secret_buffer_stringify_magic_dup 0
#define secret_buffer_async_result_magic_dup 0
#define secret_buffer_span_magic_dup 0
#endif

static int secret_buffer_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_magic_vtbl = {
   NULL, NULL, NULL, NULL,
   secret_buffer_magic_free,
   NULL,
   secret_buffer_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

static int secret_buffer_stringify_magic_get(pTHX_ SV *sv, MAGIC *mg);
static int secret_buffer_stringify_magic_set(pTHX_ SV *sv, MAGIC *mg);
static int secret_buffer_stringify_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_stringify_magic_vtbl = {
   secret_buffer_stringify_magic_get,
   secret_buffer_stringify_magic_set,
   NULL, NULL,
   secret_buffer_stringify_magic_free,
   NULL,
   secret_buffer_stringify_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

static int secret_buffer_async_result_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_async_result_magic_vtbl = {
   NULL, NULL, NULL, NULL,
   secret_buffer_async_result_magic_free,
   NULL,
   secret_buffer_async_result_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

static int secret_buffer_span_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_span_magic_vtbl = {
   NULL, NULL, NULL, NULL,
   secret_buffer_span_magic_free,
   NULL,
   secret_buffer_span_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

typedef void* secret_buffer_X_auto_ctor(SV *owner);
void* secret_buffer_X_from_magic(SV *obj, int flags,
   const MGVTBL *mg_vtbl, const char *mg_desc,
   secret_buffer_X_auto_ctor *auto_ctor
) {
   SV *sv;
   MAGIC *magic;

   if ((!obj || !SvOK(obj)) && (flags & SECRET_BUFFER_MAGIC_UNDEF_OK))
      return NULL;

   if (!sv_isobject(obj)) {
      if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
         croak("Not an object");
      return NULL;
   }
   sv = SvRV(obj);
   if (SvMAGICAL(sv) && (magic = mg_findext(sv, PERL_MAGIC_ext, mg_vtbl)))
      return magic->mg_ptr;

   if (flags & SECRET_BUFFER_MAGIC_AUTOCREATE && auto_ctor) {
      void *data= auto_ctor(sv);
      magic = sv_magicext(sv, NULL, PERL_MAGIC_ext, mg_vtbl, (const char*) data, 0);
#ifdef USE_ITHREADS
      magic->mg_flags |= MGf_DUP;
#endif
      return data;
   }
   if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
      croak("Object lacks '%s' magic", mg_desc);
   return NULL;
}

static secret_buffer_span* secret_buffer_span_from_magic(SV *objref, int flags);

#include "secret_buffer_base.c"
#include "secret_buffer_console.c"
#include "secret_buffer_async_write.c"
#include "secret_buffer_charset.c"
#include "secret_buffer_parse.c"
#include "secret_buffer_span.c"

/**********************************************************************************************\
* SecretBuffer magic
\**********************************************************************************************/

/*
 * SecretBuffer Magic
 */

int secret_buffer_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   secret_buffer *buf= (secret_buffer*) mg->mg_ptr;
   if (buf) {
      secret_buffer_realloc(buf, 0);
      if (buf->stringify_sv)
         sv_2mortal(buf->stringify_sv);
      Safefree(mg->mg_ptr);
      mg->mg_ptr = NULL;
   }
   return 0;
}

#ifdef USE_ITHREADS
int secret_buffer_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   secret_buffer *clone, *orig = (secret_buffer *)mg->mg_ptr;
   PERL_UNUSED_VAR(param);
   Newxz(clone, 1, secret_buffer);
   clone->wrapper= mg->mg_obj;
   mg->mg_ptr = (char *)clone;
   secret_buffer_realloc(clone, orig->capacity);
   if (orig->capacity)
      memcpy(clone->data, orig->data, orig->capacity);
   clone->len= orig->len;
   return 0;
}
#endif

/* Aliases for typemap */
typedef secret_buffer  *auto_secret_buffer;
typedef secret_buffer  *maybe_secret_buffer;

/*
 * SecretBuffer stringify SV magic
 */

int secret_buffer_stringify_magic_get(pTHX_ SV *sv, MAGIC *mg) {
   secret_buffer *buf= (secret_buffer *)mg->mg_ptr;
   assert(buf->stringify_sv == sv);
   SvPVX(sv)= buf->data? buf->data : "";
   SvCUR(sv)= buf->data? buf->len  : 0;
   SvPOK_on(sv);
   SvUTF8_off(sv);
   SvREADONLY_on(sv);
   return 0;
}

int secret_buffer_stringify_magic_set(pTHX_ SV *sv, MAGIC *mg) {
   warn("Attempt to assign stringify scalar");
   return 0;
}

int secret_buffer_stringify_magic_free(pTHX_ SV *sv, MAGIC *mg) {
/*   warn("Freeing stringify scalar"); */
   return 0;
}

#ifdef USE_ITHREADS
int secret_buffer_stringify_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   croak("Can't dup stringify_sv");
}
#endif

SV* secret_buffer_get_stringify_sv(secret_buffer *buf) {
   SV *sv= buf->stringify_sv;
   if (!sv) {
      sv= buf->stringify_sv= newSV(0);
      sv_magicext(sv, NULL, PERL_MAGIC_ext, &secret_buffer_stringify_magic_vtbl, (const char *)buf, 0);
#ifdef USE_ITHREADS
      /* magic->mg_flags |= MGf_DUP; it doesn't support duplication, so does the flag need set? */
#endif
      SvPOK_on(sv);
      SvUTF8_off(sv);
      SvREADONLY_on(sv);
   }
   SvPVX(sv)= buf->data? buf->data : "";
   SvCUR(sv)= buf->data? buf->len  : 0;
   return sv;
}

/* flag for capacity */
#define SECRET_BUFFER_AT_LEAST 1

/* Convenience to convert string parameters to the corresponding integer so that Perl-side
 * doesn't always need to import the flag constants.
 */
IV parse_io_flags(SV *sv) {
   if (!sv || !SvOK(sv))
      return 0;
   if (SvIOK(sv))
      return SvIV(sv);
   if (SvPOK(sv)) {
      const char *str= SvPV_nolen(sv);
      if (!str[0]) return 0;
      if (strcmp(str, "NONBLOCK") == 0)  return SECRET_BUFFER_NONBLOCK;
   }
   croak("Unknown flag %s", SvPV_nolen(sv));
}

IV parse_alloc_flags(SV *sv) {
   if (!sv || !SvOK(sv))
      return 0;
   if (SvIOK(sv))
      return SvIV(sv);
   if (SvPOK(sv)) {
      const char *str= SvPV_nolen(sv);
      if (!str[0]) return 0;
      if (strcmp(str, "AT_LEAST") == 0)  return SECRET_BUFFER_AT_LEAST;
   }
   croak("Unknown flag %s", SvPV_nolen(sv));
}

/* for typemap to automatically convert flags */
typedef int secret_buffer_io_flags;
typedef int secret_buffer_alloc_flags;

/**********************************************************************************************\
 * Debug helpers
\**********************************************************************************************/

/* Helper function to check if a memory page is accessible (committed and readable) */
#if defined(WIN32)
   #define CAN_SCAN_MEMORY 1
   static bool is_page_accessible(uintptr_t addr) {
      MEMORY_BASIC_INFORMATION memInfo;
      if (VirtualQuery((LPCVOID)addr, &memInfo, sizeof(memInfo)) == 0)
         return FALSE;
      return (memInfo.State == MEM_COMMIT) && 
            (memInfo.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE));
   }
#elif defined(HAVE_MINCORE)
   #define CAN_SCAN_MEMORY 1
   #include <sys/mman.h>
   static bool is_page_accessible(uintptr_t addr) {
      unsigned char vec;
      return mincore((void*)addr, 1, &vec) == 0;
   }
#else
   #define CAN_SCAN_MEMORY 0
#endif

/* The rest only works if we have is_page_accessible */
#if CAN_SCAN_MEMORY
IV scan_mapped_memory_in_range(uintptr_t p, uintptr_t lim, const char *needle, size_t needle_len) {
   size_t pagesize= get_page_size();
   size_t count= 0;
   void *at;
   uintptr_t run_start = p, run_lim;
   p = (p & ~(pagesize - 1)); /* round to nearest page, from here out */
   while (p < lim) {
      /* Skip pages that aren't mapped */
      while (p < lim && !is_page_accessible(p)) {
         p += pagesize;
         run_start= p;
      }
      /* This page is mapped.  Find the end of this mapped range, if it comes before lim */
      while (p < lim && is_page_accessible(p)) {
         p += pagesize;
      }
      run_lim= p < lim? p : lim;
      /* Scan memory from run_start to run_lim */
      while (run_start < run_lim && (at= memmem((void*)run_start, run_lim - run_start, needle, needle_len))) {
         ++count;
         run_start= ((intptr_t)at) + needle_len;
      }
   }
   return count;
}
#else
IV scan_mapped_memory_in_range(uintptr_t p, uintptr_t lim, const char *needle, size_t needle_len) {
   return -1;
}
#endif

/**********************************************************************************************\
* Crypt::SecretBuffer API
\**********************************************************************************************/
MODULE = Crypt::SecretBuffer           PACKAGE = Crypt::SecretBuffer
PROTOTYPES: DISABLE

void
new(...)
   ALIAS:
      Crypt::SecretBuffer::Exports::secret = 1
      Crypt::SecretBuffer::Exports::secret_buffer = 2
   INIT:
      SV *buf_ref= NULL;
      secret_buffer *buf= secret_buffer_new(0, &buf_ref);
      int i, next_arg= ix == 0? 1 : 0;
   PPCODE:
      if (items - next_arg == 1)
         secret_buffer_assign_sv(buf, ST(next_arg));
      else {
         if ((items - next_arg) & 1)
            croak("Odd number of arguments; expected (key => value) pairs");
         for (i= next_arg; i < items-1; i += 2) {
            SV *key= ST(i), *val= ST(i+1);
            {
               dSP;
               int count;
               ENTER;
               SAVETMPS;
               PUSHMARK(SP);
               EXTEND(SP, 2);
               PUSHs(buf_ref);
               PUSHs(val);
               PUTBACK;
               call_method(SvPV_nolen(key), G_DISCARD);
               FREETMPS;
               LEAVE;
            }
         }
      }
      PUSHs(buf_ref);

void
assign(buf, source= NULL)
   auto_secret_buffer buf
   SV *source;
   INIT:
      const char *str;
      STRLEN len;
   PPCODE:
      secret_buffer_assign_sv(buf, source);
      XSRETURN(1); /* return self for chaining */

void
length(buf, val=NULL)
   auto_secret_buffer buf
   SV *val
   PPCODE:
      if (val) { /* writing */
         IV ival= SvIV(val);
         if (ival < 0) ival= 0;
         secret_buffer_set_len(buf, ival);
         /* return self, for chaining */
      }
      else /* reading */
         ST(0)= sv_2mortal(newSViv(buf->len));
      XSRETURN(1);

void
capacity(buf, val=NULL, flags= 0)
   auto_secret_buffer buf
   SV *val
   secret_buffer_alloc_flags flags
   PPCODE:
      if (val) { /* wiritng */
         IV ival= SvIV(val);
         if (ival < 0) ival= 0;
         if (flags & SECRET_BUFFER_AT_LEAST)
            secret_buffer_alloc_at_least(buf, ival);
         else
            secret_buffer_realloc(buf, ival);
         /* return self, for chaining */
      }
      else /* reading */
         ST(0)= sv_2mortal(newSViv(buf->capacity));
      XSRETURN(1);

void
clear(buf)
   auto_secret_buffer buf
   PPCODE:
      secret_buffer_realloc(buf, 0);
      XSRETURN(1); /* self, for chaining */

IV
index(buf, pattern, ofs_sv= &PL_sv_undef)
   auto_secret_buffer buf
   SV *pattern
   SV *ofs_sv
   ALIAS:
      rindex = 1
   INIT:
      secret_buffer_parse parse;
      size_t pos= 0, lim;
      int flags= 0;
      if (ix == 0) { // index (forward)
         pos= normalize_offset(SvOK(ofs_sv)? SvIV(ofs_sv) : 0, buf->len);
         lim= buf->len;
      } else { // rindex (reverse)
         IV max= normalize_offset(SvOK(ofs_sv)? SvIV(ofs_sv) : -1, buf->len);
         flags= SECRET_BUFFER_MATCH_REVERSE;
         // The ofs specifies the *start* of the match, not the maximum byte pos
         // that could be part of the match.  If pattern is a charset, add one to get 'lim',
         // and if pattern is a string, add string byte length to get 'lim'.
         if (SvRX(pattern))
            lim= max + 1;
         else {
            STRLEN len; // needs to be byte count, so can't SvCUR without converting to bytes first
            const char *str= SvPVbyte(pattern, len);
            lim= max + len;
         }
         // re-clamp lim to end of buffer
         if (lim > buf->len) lim= buf->len;
      }
      if (!secret_buffer_parse_init(&parse, buf, pos, lim, 0))
         croak("%s", parse.error);
   CODE:
      if (secret_buffer_match(&parse, pattern, flags))
         RETVAL= parse.pos - (U8*) buf->data;
      else {
         if (parse.error)
            croak("%s", parse.error);
         RETVAL= -1;
      }
   OUTPUT:
      RETVAL

void
scan(buf, pattern, flags= 0, ofs= 0, len_sv= &PL_sv_undef)
   auto_secret_buffer buf
   SV *pattern
   IV flags
   IV ofs
   SV *len_sv
   INIT:
      secret_buffer_parse parse;
      // lim was captured as an SV so that undef can be used to indicate
      // end of the buffer.
      IV len= !SvOK(len_sv)? buf->len : SvIV(len_sv);
      ofs= normalize_offset(ofs, buf->len);
      if (!secret_buffer_parse_init(&parse, buf,
         ofs, ofs + normalize_offset(len, buf->len - ofs),
         (flags & SECRET_BUFFER_ENCODING_MASK)
      ))
         croak("%s", parse.error);
   PPCODE:
      if (!secret_buffer_match(&parse, pattern, flags))
         if (parse.error)
            croak("%s", parse.error);
      PUSHs(sv_2mortal(newSViv(parse.pos - (U8*) buf->data)));
      PUSHs(sv_2mortal(newSViv(parse.lim - parse.pos)));

void
substr(buf, ofs, count_sv=NULL, replacement=NULL)
   auto_secret_buffer buf
   IV ofs
   SV *count_sv
   SV *replacement
   INIT:
      unsigned char *sub_start;
      secret_buffer *sub_buf= NULL;
      SV *sub_ref= NULL;
      IV count= count_sv? SvIV(count_sv) : buf->len;
   PPCODE:
      /* normalize negative offset, and clamp to valid range */
      ofs= normalize_offset(ofs, buf->len);
      /* normalize negative count, and clamp to valid range */
      count= normalize_offset(count, buf->len - ofs);
      sub_start= (unsigned char*) buf->data + ofs;
      /* If called in non-void context, construct new secret from this range */
      if (GIMME_V != G_VOID) {
         SV **el;
         sub_buf= secret_buffer_new(count, &sub_ref);
         if (count) {
            Copy(sub_start, sub_buf->data, count, unsigned char);
            sub_buf->len= count;
         }
         /* inherit the stringify_mask */
         el= hv_fetchs((HV*) SvRV(ST(0)), "stringify_mask", 0);
         if (el && *el)
            /* we know the hv isn't tied because we just created it, so no need to check success */
            hv_stores((HV*) SvRV(sub_ref), "stringify_mask", newSVsv(*el));
      }
      /* modifying string? */
      if (replacement) {
         IV tail_len= buf->len - (ofs + count);
         IV len_diff;
         const unsigned char *repl_src;
         STRLEN repl_len;

         /* Debatable whether I should allow plain SVs here, or force the user to wrap the data
          * in a secret_buffer first... */
         if (SvPOK(replacement)) {
            repl_src= (const unsigned char*) SvPVbyte(replacement, repl_len);
         } else {
            secret_buffer *peer= secret_buffer_from_magic(replacement, SECRET_BUFFER_MAGIC_OR_DIE);
            repl_src= (const unsigned char*) peer->data;
            repl_len= peer->len;
         }
         len_diff= repl_len - count;
         if (len_diff > 0) /* buffer is growing */
            secret_buffer_alloc_at_least(buf, buf->len + len_diff);
         /* copy anything beyond the insertion point to its new location */
         if (tail_len)
            Move(sub_start + count, sub_start + repl_len, tail_len, unsigned char);
         if (repl_len)
            Copy(repl_src, sub_start, repl_len, unsigned char);
         buf->len += len_diff;
      }
      /* If void context, return nothing.  Else return the substr */
      if (!sub_ref)
         XSRETURN(0);
      else {
         ST(0)= sub_ref; /* already mortal */
         XSRETURN(1);
      }

UV
append_random(buf, count, flags=0)
   auto_secret_buffer buf
   UV count
   secret_buffer_io_flags flags
   CODE:
      RETVAL= secret_buffer_append_random(buf, count, flags);
   OUTPUT:
      RETVAL

void
append_sysread(buf, handle, count)
   auto_secret_buffer buf
   PerlIO *handle
   IV count
   INIT:
      IV got;
   PPCODE:
      got= secret_buffer_append_read(buf, handle, count);
      ST(0)= (got < 0)? &PL_sv_undef : sv_2mortal(newSViv(got));
      XSRETURN(1);

void
append_read(buf, handle, count)
   auto_secret_buffer buf
   PerlIO *handle
   IV count
   INIT:
      int got;
   PPCODE:
      got= secret_buffer_append_read(buf, handle, count);
      ST(0)= (got < 0)? &PL_sv_undef : sv_2mortal(newSViv(got));
      XSRETURN(1);

void
append_console_line(buf, handle)
   auto_secret_buffer buf
   PerlIO *handle
   INIT:
      int got;
   PPCODE:
      got= secret_buffer_append_console_line(buf, handle);
      ST(0)= got == SECRET_BUFFER_GOTLINE? &PL_sv_yes
         : got == SECRET_BUFFER_EOF? &PL_sv_no
         : &PL_sv_undef;
      XSRETURN(1);

void
syswrite(buf, io, count=buf->len, ofs=0)
   auto_secret_buffer buf
   PerlIO *io
   IV ofs
   IV count
   INIT:
      IV wrote;
   PPCODE:
      wrote= secret_buffer_syswrite(buf, io, ofs, count);
      ST(0)= (wrote < 0)? &PL_sv_undef : sv_2mortal(newSViv(wrote));
      XSRETURN(1);

void
write_async(buf, io, count=buf->len, ofs=0)
   auto_secret_buffer buf
   PerlIO *io
   IV ofs
   IV count
   INIT:
      IV wrote;
      SV *ref_out= NULL;
   PPCODE:
      wrote= secret_buffer_write_async(buf, io, ofs, count, GIMME_V == G_VOID? NULL : &ref_out);
      /* wrote == 0 means that it supplied a result promise object, which is already mortal.
       * but avoid creating one when called in void context. */
      ST(0)= wrote? sv_2mortal(newSViv(wrote)) : ref_out? ref_out : &PL_sv_undef;
      XSRETURN(1);

void
stringify(buf, ...)
   auto_secret_buffer buf
   INIT:
      SV **field= hv_fetch((HV*)SvRV(ST(0)), "stringify_mask", 14, 0);
   PPCODE:
      if (!field || !*field) {
         ST(0)= sv_2mortal(newSVpvn("[REDACTED]", 10));
      } else if (SvOK(*field)) {
         ST(0)= *field;
      } else {
         ST(0)= secret_buffer_get_stringify_sv(buf);
      }
      XSRETURN(1);

void
unmask_to(buf, coderef)
   auto_secret_buffer buf
   SV *coderef
   INIT:
      int count= 0;
   PPCODE:
      PUSHMARK(SP);
      EXTEND(SP, 1);
      PUSHs(secret_buffer_get_stringify_sv(buf));
      PUTBACK;
      count= call_sv(coderef, G_EVAL|GIMME_V);
      SPAGAIN;
      if (SvTRUE(ERRSV))
         croak_sv(ERRSV);
      XSRETURN(count);

bool
_can_count_copies_in_process_memory()
   CODE:
      RETVAL= false;
   OUTPUT:
      RETVAL
   
IV
_count_matches_in_mem(buf, addr0, addr1)
   secret_buffer *buf
   UV addr0
   UV addr1
   CODE:
      if (!buf->len)
         croak("Empty buffer");
      RETVAL= scan_mapped_memory_in_range(addr0, addr1, buf->data, buf->len);
   OUTPUT:
      RETVAL

MODULE = Crypt::SecretBuffer           PACKAGE = Crypt::SecretBuffer::Exports

void
unmask_secrets_to(coderef, ...)
   SV *coderef
   INIT:
      int count= 0, i;
      secret_buffer *buf= NULL;
   PPCODE:
      PUSHMARK(SP);
      EXTEND(SP, items);
      for (i= 1; i < items; i++) {
         if (SvOK(ST(i)) && SvROK(ST(i)) && (buf= secret_buffer_from_magic(ST(i), 0)))
            PUSHs(secret_buffer_get_stringify_sv(buf));
         else
            PUSHs(ST(i));
      }
      PUTBACK;
      count= call_sv(coderef, G_EVAL|GIMME_V);
      SPAGAIN;
      if (SvTRUE(ERRSV))
         croak_sv(ERRSV);
      XSRETURN(count);

void
_debug_charset(cset)
   secret_buffer_charset *cset
   INIT:
      HV *hv;
   PPCODE:
      PUSHs(sv_2mortal((SV*)newRV_noinc((SV*)(hv= newHV()))));
      hv_stores(hv, "bitmap", newSVpvn((char*)cset->bitmap, sizeof(cset->bitmap)));
      hv_stores(hv, "unicode_above_7F", newSViv(cset->unicode_above_7F));

MODULE = Crypt::SecretBuffer           PACKAGE = Crypt::SecretBuffer::AsyncResult

void
wait(result, timeout=-1)
   secret_buffer_async_result *result
   NV timeout
   INIT:
      IV os_err, bytes_written;
   PPCODE:
      if (secret_buffer_async_result_recv(result, (IV)(timeout*1000), &bytes_written, &os_err)) {
         EXTEND(sp, 2);
         ST(0)= sv_2mortal(newSViv(bytes_written));
         ST(1)= sv_2mortal(newSViv(os_err));
         XSRETURN(2);
      } else {
         XSRETURN(0);
      }

MODULE = Crypt::SecretBuffer           PACKAGE = Crypt::SecretBuffer::Span

void
new(class_or_obj, ...)
   SV *class_or_obj
   ALIAS:
      clone = 1
      subspan = 2
      Crypt::SecretBuffer::span = 3
   INIT:
      secret_buffer_span *span= secret_buffer_span_from_magic(class_or_obj, SECRET_BUFFER_MAGIC_UNDEF_OK);
      SV **buf_field= span && SvTYPE(SvRV(class_or_obj)) == SVt_PVHV
         ? hv_fetchs((HV*)SvRV(class_or_obj), "buf", 0)
         : NULL;
      secret_buffer *buf= secret_buffer_from_magic(
         buf_field? *buf_field : class_or_obj, SECRET_BUFFER_MAGIC_UNDEF_OK
      );
      bool subspan= span && ix == 2;
      IV base_pos= subspan? span->pos : 0;
      IV pos, lim, len, base_lim;
      int encoding= span? span->encoding : 0, i;
      SV *encoding_sv= NULL;
      bool have_pos= false, have_lim= false, have_len= false;
   PPCODE:
      //warn("items=%d  span=%p  buf=%p  base_pos=%d", (int)items, span, buf, (int)base_pos);
      // 3-argument form, only usable when first arg is a buffer or refs a buffer
      if (buf && items >= 2 && looks_like_number(ST(1))) {
         pos= SvIV(ST(1));
         have_pos= true;
         if (items >= 3 && SvOK(ST(2))) {
            len= SvIV(ST(2));
            have_len= true;
            if (items >= 4) {
               encoding_sv= ST(3);
               if (items > 4)
                  warn("unexpected 4th argument after encoding");
            }
         }
      } else { // key => value form
         if ((items - 1) & 1)
            croak("Odd number of arguments; expected (key => value, ...)");
         for (i= 1; i < items-1; i += 2) {
            if (0 == strcmp("pos", SvPV_nolen(ST(i)))) {
               pos= SvIV(ST(i+1));
               have_pos= true;
            }
            else if (0 == strcmp("lim", SvPV_nolen(ST(i)))) {
               lim= SvIV(ST(i+1));
               have_lim= true;
            }
            else if (0 == strcmp("len", SvPV_nolen(ST(i)))) {
               len= SvIV(ST(i+1));
               have_len= true;
            }
            else if (0 == strcmp("encoding", SvPV_nolen(ST(i)))) {
               encoding_sv= ST(i+1);
            }
            else if (0 == strcmp("buf", SvPV_nolen(ST(i)))) {
               buf= secret_buffer_from_magic(ST(i+1), SECRET_BUFFER_MAGIC_OR_DIE);
            }
         }
      }
      if (have_len && have_lim && (lim != pos + len))
         croak("Can't specify both 'len' and 'lim', make up your mind!");
      // buffer is required
      if (!buf)
         croak("Require 'buf' attribute");
      base_lim= subspan? span->lim : buf->len;
      // pos is relative to base_pos, and needs truncated to (or count backward from) base_lim
      pos= have_pos? normalize_offset(pos, base_lim-base_pos)+base_pos
         : span    ? span->pos
                   : base_pos;
      // likewise for lim, but also might need calculated from 'len'
      lim= have_lim? normalize_offset(lim, base_lim-base_pos)+base_pos
         : have_len? normalize_offset(len, base_lim-pos)+pos
         : span    ? span->lim
                   : base_lim;
      if (pos > lim)
         croak("lim must be greater or equal to pos");
      //warn("  base_lim=%d pos=%d  lim=%d", (int) base_lim, (int)pos, (int)lim);
      // check encoding
      if (encoding_sv) {
         if (!parse_encoding(encoding_sv, &encoding))
            croak("Unknown encoding '%s'", SvPV_nolen(encoding_sv));
      }
      PUSHs(new_mortal_span_obj(aTHX_ buf, pos, lim, encoding));

UV
pos(span, newval_sv= NULL)
   secret_buffer_span *span
   SV *newval_sv
   ALIAS:
      lim = 1
      len = 2
      length = 2
   CODE:
      if (newval_sv) {
         IV newval= SvIV(newval_sv);
         if (newval < 0)
            croak("pos, lim, and len can not be negative");
         switch (ix) {
         case 0: span->pos= newval; break;
         case 1: if (newval < span->pos) croak("lim must be >= pos");
                 span->lim= newval; break;
         case 2: span->pos + newval;
         default: croak("BUG");
         }
      }
      RETVAL= ix == 0? span->pos
            : ix == 1? span->lim
            : ix == 2? span->lim - span->pos
            : -1;
   OUTPUT:
      RETVAL

void
encoding(span, newval_sv= NULL)
   secret_buffer_span *span
   SV *newval_sv
   INIT:
      SV *enc_const;
      AV *encodings= get_av("Crypt::SecretBuffer::_encodings", 0);
      if (!encodings) croak("BUG");
   PPCODE:
      if (newval_sv)
         if (!parse_encoding(newval_sv, &span->encoding))
            croak("Invalid encoding");
      enc_const= *av_fetch(encodings, span->encoding, 1);
      if (!enc_const || !SvOK(enc_const))
         croak("BUG");
      PUSHs(enc_const);

void
scan(self, pattern=NULL, flags= 0)
   SV *self
   SV *pattern
   IV flags
   ALIAS:
      parse       = 0x102
      rparse      = 0x203
      trim        = 0x322
      ltrim       = 0x422
      rtrim       = 0x523
      starts_with = 0x612
      ends_with   = 0x713
   INIT:
      secret_buffer_span *span= secret_buffer_span_from_magic(self, SECRET_BUFFER_MAGIC_OR_DIE);
      SV **sb_sv= hv_fetchs((HV*)SvRV(self), "buf", 1);
      secret_buffer *buf= secret_buffer_from_magic(*sb_sv, SECRET_BUFFER_MAGIC_OR_DIE);
      secret_buffer_parse parse;
      if (!secret_buffer_parse_init(&parse, buf, span->pos, span->lim, span->encoding))
         croak("%s", parse.error);
      // Bit 0 indicates an op from the end of the buffer
      if (ix & 1)
         flags |= SECRET_BUFFER_MATCH_REVERSE;
      // Bit 1 indicates an anchored op
      if (ix & 2)
         flags |= SECRET_BUFFER_MATCH_ANCHORED;
      // Bits 4..7 indicate return type,
      //   0 == return a span
      //   1 == return bool
      //   2 == return self
      int ret_type= (ix >> 4) & 0xF;
      int op= (ix >> 8);
      bool matched;
      if (!pattern) {
         if (op == 3 || op == 4 || op == 5)
            pattern= get_sv("Crypt::SecretBuffer::Span::default_trim_regex", 0);
         if (!pattern)
            croak("pattern is required");
      }
   PPCODE:
      matched= secret_buffer_match(&parse, pattern, flags);
      if (parse.error)
         croak("%s", parse.error);
      switch (op) {
      case 1: // parse
         if (matched) span->pos= parse.lim - (U8*) buf->data;
         break;
      case 2: // rparse
         if (matched) span->lim= parse.pos - (U8*) buf->data;
         break;
      case 3: // trim
      case 4: // ltrim
         if (matched) span->pos= parse.lim - (U8*) buf->data;
         if (op == 4) break;
         // reset the modified parse_state and run in reverse
         parse.pos= buf->data + span->pos;
         parse.lim= buf->data + span->lim;
         flags |= SECRET_BUFFER_MATCH_REVERSE;
         matched= secret_buffer_match(&parse, pattern, flags);
      case 5: // rtrim, and trim
         if (matched) span->lim= parse.pos - (U8*) buf->data;
         break;
      default:
      }
      if (ret_type == 0) {
         if (!matched)
            XSRETURN_UNDEF;
         if (parse.pos > parse.lim || parse.lim > (U8*) buf->data + buf->len)
            croak("BUG: parse pos=%p lim=%p buf.data=%p buf.len=%ld",
               parse.pos, parse.lim, buf->data, (long)buf->len);
         PUSHs(new_mortal_span_obj(aTHX_ buf, parse.pos - (U8*) buf->data, parse.lim - (U8*) buf->data, span->encoding));
      } else if (ret_type == 1) {
         if (matched)
            XSRETURN_YES;
         else
            XSRETURN_NO;
      }
      else {
         XSRETURN(1); // use self pointer in ST(0)
      }

void
copy_to(self, ...)
   SV *self
   ALIAS:
      copy = 1
   INIT:
      secret_buffer_span *span= secret_buffer_span_from_magic(self, SECRET_BUFFER_MAGIC_OR_DIE);
      SV **sb_sv= hv_fetchs((HV*)SvRV(self), "buf", 1);
      secret_buffer *buf= secret_buffer_from_magic(*sb_sv, SECRET_BUFFER_MAGIC_OR_DIE);
      secret_buffer *dst_buf= NULL;
      SV *dst_sv= NULL;
      SSize_t append_ofs, need_bytes;
      int next_arg, dst_encoding_req= -1, dst_encoding= -1;
      secret_buffer_parse src, dst;
      if (!secret_buffer_parse_init(&src, buf, span->pos, span->lim, span->encoding))
         croak("%s", src.error);
   PPCODE:
      if (ix == 0) {
         if (items >= 2) {
            if (sv_isobject(ST(1))) // if object, must be a SecretBuffer
               dst_buf= secret_buffer_from_magic(ST(1), SECRET_BUFFER_MAGIC_OR_DIE);
            else if (SvROK(ST(1)) && !SvROK(SvRV(ST(1)))) // Scalar-ref
               dst_sv= SvRV(ST(1));
            else if (!SvROK(ST(1))) // any plain non-ref scalar
               dst_sv= ST(1);
         }
         if (!dst_sv && !dst_buf)
            croak("copy_to destination buffer must be an empty scalar, scalar-ref, or a SecretBuffer instance");
         next_arg= 2;
      }
      else {
         next_arg= 1;
      }
      
      // parse options
      if ((items - next_arg) & 1)
         croak("expected even-length list of (key => val)");
      for (; next_arg < items; next_arg+= 2) {
         if (0 == strcmp(SvPV_nolen(ST(next_arg)), "encoding")) {
            if (!parse_encoding(ST(next_arg+1), &dst_encoding_req))
               croak("Unknown encoding");
         }
      }
      // Even when copying to a SV, write the buf first and then "sv_setpvn_mg"
      // in order to deal with magic conveniently.
      if (!dst_buf)
         dst_buf= secret_buffer_new(0, NULL);
      // Determine the actual destination encoding
      if (dst_encoding_req >= 0)
         dst_encoding= dst_encoding_req;
      // if dest is an SV and src is a type of unicode, and destination encoding was not
      //  specified, export as utf-8 for perl wide chars.
      else if (dst_sv && SECRET_BUFFER_ENCODING_IS_UNICODE(span->encoding))
         dst_encoding= SECRET_BUFFER_ENCODING_UTF8;
      else
         dst_encoding= span->encoding;

      need_bytes= secret_buffer_sizeof_transcode(&src, dst_encoding);
      if (need_bytes < 0)
         croak("transcode sizeof failed: %s", src.error);
      append_ofs= dst_buf->len;
      secret_buffer_set_len(dst_buf, dst_buf->len + need_bytes);
      if (!secret_buffer_parse_init(&dst, dst_buf, append_ofs, append_ofs+need_bytes, dst_encoding))
         croak("%s", dst.error);
      if (!secret_buffer_transcode(&src, &dst))
         croak("transcode failed: %s", src.error? src.error : dst.error);
      // If the output was actually a SV, assign that now
      if (dst_sv) {
         sv_setpvn_mg(dst_sv, dst_buf->data, dst_buf->len);
         // and if no encoding was requested, upgrade to wide characters
         if (dst_encoding == SECRET_BUFFER_ENCODING_UTF8 && dst_encoding_req < 0)
            SvUTF8_on(dst_sv);
         else // setpvn_mg does not change the utf8 flag, so make sure it is off
            SvUTF8_off(dst_sv);
      }
      // copy returns the SecretBuffer, but copy_to returns empty list.
      if (ix == 1)
         PUSHs(sv_2mortal(newRV_inc(dst_buf->wrapper)));

BOOT:
   HV *stash= gv_stashpvs("Crypt::SecretBuffer", 1);
#define EXPORT_CONST(name, const) \
   newCONSTSUB(stash, name, new_enum_dualvar(aTHX_ const, newSVpvs_share(name)))
   EXPORT_CONST("NONBLOCK",      SECRET_BUFFER_NONBLOCK);
   EXPORT_CONST("AT_LEAST",      SECRET_BUFFER_AT_LEAST);
   EXPORT_CONST("MATCH_MULTI",   SECRET_BUFFER_MATCH_MULTI);
   EXPORT_CONST("MATCH_REVERSE", SECRET_BUFFER_MATCH_REVERSE);
   EXPORT_CONST("MATCH_NEGATE",  SECRET_BUFFER_MATCH_NEGATE);
#undef EXPORT_CONST
   SV *enc[SECRET_BUFFER_ENCODING_MAX+1];
   memset(enc, 0, sizeof(enc));
#define EXPORT_ENCODING(name, str, const) \
   newCONSTSUB(stash, name, (enc[const]= new_enum_dualvar(aTHX_ const, newSVpvs_share(str))))
   EXPORT_ENCODING("ASCII",    "ASCII",      SECRET_BUFFER_ENCODING_ASCII);
   EXPORT_ENCODING("ISO8859_1","ISO-8859-1", SECRET_BUFFER_ENCODING_ISO8859_1);
   EXPORT_ENCODING("UTF8",     "UTF-8",      SECRET_BUFFER_ENCODING_UTF8);
   EXPORT_ENCODING("UTF16LE",  "UTF-16LE",   SECRET_BUFFER_ENCODING_UTF16LE);
   EXPORT_ENCODING("UTF16BE",  "UTF-16BE",   SECRET_BUFFER_ENCODING_UTF16BE);
   EXPORT_ENCODING("HEX",      "HEX",        SECRET_BUFFER_ENCODING_HEX);
#undef EXPORT_ENCODING
   // Set up an array of _encodings so that the accessor can return an existing SV
   AV *encodings= get_av("Crypt::SecretBuffer::_encodings", GV_ADD);
   av_fill(encodings, SECRET_BUFFER_ENCODING_MAX);
   for (int i= 0; i <= SECRET_BUFFER_ENCODING_MAX; i++)
      if (enc[i] && av_store(encodings, i, enc[i]))
         SvREFCNT_inc(enc[i]);
   SECRET_BUFFER_EXPORT_FUNCTION_POINTERS
