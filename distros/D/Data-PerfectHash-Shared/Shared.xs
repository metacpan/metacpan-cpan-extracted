#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "phash.h"
#include "chd.h"

#define BEXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::PerfectHash::Shared::Builder")) \
        croak("Expected a Data::PerfectHash::Shared::Builder"); \
    PhBuilder *b = INT2PTR(PhBuilder*, SvIV(SvRV(sv))); \
    if (!b) croak("Builder used after build/destroy"); \
    if (b->type_tag != PH_BUILDER_TAG) croak("not a Data::PerfectHash::Shared::Builder handle"); \
    PhBuilder *b0 = b; PERL_UNUSED_VAR(b0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))
#define BREEXTRACT(sv) \
    if (!SvROK(sv)) croak("Builder replaced during the call"); \
    b = INT2PTR(PhBuilder*, SvIV(SvRV(sv))); \
    if (b != b0) croak("Builder replaced or destroyed during the call")

#define SEXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::PerfectHash::Shared")) \
        croak("Expected a Data::PerfectHash::Shared object"); \
    PhSet *s = INT2PTR(PhSet*, SvIV(SvRV(sv))); \
    if (!s) croak("Set used after destroy"); \
    if (s->type_tag != PH_SET_TAG) croak("not a Data::PerfectHash::Shared handle"); \
    PhSet *s0 = s; PERL_UNUSED_VAR(s0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))
#define SREEXTRACT(sv) \
    if (!SvROK(sv)) croak("Set replaced during the call"); \
    s = INT2PTR(PhSet*, SvIV(SvRV(sv))); \
    if (s != s0) croak("Set replaced or destroyed during the call")

static SV *ph_mkobj(pTHX_ void *p, const char *cls) {
    SV *rv = newRV_noinc(newSViv(PTR2IV(p)));
    return sv_bless(rv, gv_stashpv(cls, GV_ADD));
}

/* Save-stack destructor for a transient builder (build_int/build_str): runs on
 * BOTH normal scope exit AND croak-unwind, so a croak mid-collect (wide-char
 * SvPVbyte, dying tied element, OOM) can't longjmp past the free and leak the builder. */
static void ph_builder_free_x(pTHX_ void *p) { ph_builder_free((PhBuilder*)p); }

MODULE = Data::PerfectHash::Shared  PACKAGE = Data::PerfectHash::Shared
PROTOTYPES: DISABLE

SV *
new_builder(class, ...)
    const char *class
  PREINIT:
    uint32_t type = PH_TYPE_INT;
  CODE:
    if ((items - 1) % 2) croak("new_builder: odd number of options");
    for (int i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "type")) {
            const char *t = SvPV_nolen(ST(i+1));
            type = strEQ(t,"str") ? PH_TYPE_STR : strEQ(t,"int") ? PH_TYPE_INT
                 : (croak("type must be 'int' or 'str'"), 0);
        } else croak("unknown option '%s'", key);
    }
    RETVAL = ph_mkobj(aTHX_ ph_builder_new(type), "Data::PerfectHash::Shared::Builder");
  OUTPUT:
    RETVAL

MODULE = Data::PerfectHash::Shared  PACKAGE = Data::PerfectHash::Shared::Builder

void
add(self, key)
    SV *self
    SV *key
  PREINIT:
    BEXTRACT(self);
  CODE:
    if (b->key_type == PH_TYPE_INT) { IV k = SvIV(key); BREEXTRACT(self); ph_builder_add_int(b, (int64_t)k); }
    else { STRLEN len; const char *p = SvPVbyte(key, len); BREEXTRACT(self); ph_builder_add_str(b, p, len); }

void
add_many(self, aref)
    SV *self
    SV *aref
  PREINIT:
    BEXTRACT(self);
    AV *av;
    SSize_t i, n;
  CODE:
    SvGETMAGIC(aref);
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV) croak("add_many: expected an arrayref");
    av = (AV *)SvRV(aref);
    sv_2mortal(SvREFCNT_inc((SV *)av));   /* pin: element magic cannot free it mid-loop */
    n = av_len(av) + 1;
    BREEXTRACT(self);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0); if (!e || !*e) continue;
        if (b->key_type == PH_TYPE_INT) { IV k = SvIV(*e); BREEXTRACT(self); ph_builder_add_int(b, (int64_t)k); }
        else { STRLEN len; const char *p = SvPVbyte(*e, len); BREEXTRACT(self); ph_builder_add_str(b, p, len); }
    }

UV
count(self)
    SV *self
  PREINIT:
    BEXTRACT(self);
  CODE:
    RETVAL = (UV)ph_builder_count(b);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    { PhBuilder *b = INT2PTR(PhBuilder*, SvIV(SvRV(self)));
      /* Cross-bless safety: a reblessed handle points at a real allocation of
       * the OTHER struct. type_tag is the first member of both, so read it
       * first and dispatch to the CORRECT free -- never reinterpret (crash) or
       * skip it (leak). A 0 tag means already-destroyed: no-op. */
      if (b) { uint32_t tag = b->type_tag; sv_setiv(SvRV(self), 0);
        if (tag == PH_BUILDER_TAG) ph_builder_free(b);
        else if (tag == PH_SET_TAG) ph_close((PhSet*)b); } }

void
build(self, path, ...)
    SV *self
    const char *path
  PREINIT:
    BEXTRACT(self);
    mode_t mode = 0600; char err[256];
  CODE:
    /* F2: copy `path` before the option loop's magic (SvPV_nolen/SvUV) can
     * reassign the caller's variable and invalidate the pointer. */
    char *psafe = savepvn(path, strlen(path)); SAVEFREEPV(psafe);
    if ((items - 2) % 2) croak("build: odd number of options");
    for (int i=2;i+1<items;i+=2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key,"mode")) mode=(mode_t)SvUV(ST(i+1));
        else croak("unknown option '%s'", key);
    }
    /* SvPV_nolen/SvUV above can run arbitrary Perl (tie/overload magic) that
     * destroys or replaces self -- re-check before touching b, like add/add_many do. */
    BREEXTRACT(self);
    if (ph_build(b, psafe, mode, err, sizeof err) != 0) croak("Data::PerfectHash::Shared->build: %s", err);

MODULE = Data::PerfectHash::Shared  PACKAGE = Data::PerfectHash::Shared

SV *
build_int(class, path, ids)
    const char *class
    const char *path
    SV *ids
  PREINIT:
    char err[256];
  CODE:
    /* F2: stable copy of path before element magic (SvIV) can invalidate it. */
    char *psafe = savepvn(path, strlen(path)); SAVEFREEPV(psafe);
    if (!SvROK(ids)||SvTYPE(SvRV(ids))!=SVt_PVAV) croak("build_int: expected an arrayref");
    { AV *av=(AV*)SvRV(ids); sv_2mortal(SvREFCNT_inc((SV*)av));   /* pin: element magic cannot free it mid-loop */
      PhBuilder *b=ph_builder_new(PH_TYPE_INT);
      SAVEDESTRUCTOR_X(ph_builder_free_x, b);   /* F7: free on normal return AND croak-unwind (no explicit free below) */
      SSize_t n=av_len(av)+1; for(SSize_t i=0;i<n;i++){SV**e=av_fetch(av,i,0); if(e&&*e) ph_builder_add_int(b,(int64_t)SvIV(*e));}
      int rc=ph_build(b,psafe,0600,err,sizeof err);
      if(rc) croak("build_int: %s",err); }
    RETVAL = &PL_sv_yes;
  OUTPUT:
    RETVAL

SV *
build_str(class, path, strs)
    const char *class
    const char *path
    SV *strs
  PREINIT:
    char err[256];
  CODE:
    /* F2: stable copy of path before element magic (SvPVbyte) can invalidate it. */
    char *psafe = savepvn(path, strlen(path)); SAVEFREEPV(psafe);
    if (!SvROK(strs)||SvTYPE(SvRV(strs))!=SVt_PVAV) croak("build_str: expected an arrayref");
    { AV *av=(AV*)SvRV(strs); sv_2mortal(SvREFCNT_inc((SV*)av));   /* pin: element magic cannot free it mid-loop */
      PhBuilder *b=ph_builder_new(PH_TYPE_STR);
      SAVEDESTRUCTOR_X(ph_builder_free_x, b);   /* F7: free on normal return AND croak-unwind (no explicit free below) */
      SSize_t n=av_len(av)+1; for(SSize_t i=0;i<n;i++){SV**e=av_fetch(av,i,0); if(e&&*e){STRLEN l;const char*q=SvPVbyte(*e,l);ph_builder_add_str(b,q,l);}}
      int rc=ph_build(b,psafe,0600,err,sizeof err);
      if(rc) croak("build_str: %s",err); }
    RETVAL = &PL_sv_yes;
  OUTPUT:
    RETVAL

SV *
load(class, path)
    const char *class
    const char *path
  PREINIT:
    char err[256]; PhSet *s;
  CODE:
    s = ph_open(path, err, sizeof err);
    if (!s) croak("Data::PerfectHash::Shared->load(%s): %s", path, err);
    RETVAL = ph_mkobj(aTHX_ s, "Data::PerfectHash::Shared");
  OUTPUT:
    RETVAL

int
has(self, key)
    SV *self
    SV *key
  PREINIT:
    SEXTRACT(self);
  CODE:
    if (s->hdr->key_type == PH_TYPE_INT) { IV k=SvIV(key); SREEXTRACT(self); RETVAL = ph_has_int(s,(int64_t)k); }
    else { STRLEN len; const char *p=SvPVbyte(key,len); SREEXTRACT(self); RETVAL = ph_has_str(s,p,len); }
  OUTPUT:
    RETVAL

const char *
type(self)
    SV *self
  PREINIT:
    SEXTRACT(self);
  CODE:
    RETVAL = s->hdr->key_type==PH_TYPE_INT ? "int" : "str";
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    SEXTRACT(self);
  CODE:
    RETVAL = (UV)s->hdr->n;
  OUTPUT:
    RETVAL

void
each_key(self, cb)
    SV *self
    SV *cb
  PREINIT:
    SEXTRACT(self);
  CODE:
    if (!SvROK(cb)||SvTYPE(SvRV(cb))!=SVt_PVCV) croak("each_key: expected a coderef");
    for (uint64_t i=0;i<s->hdr->n;i++) {
        const PhStrSlot *ss = NULL;
        if (s->hdr->key_type==PH_TYPE_STR) {
            ss = &((const PhStrSlot*)s->slots)[i];
            /* slot (off,len) is untrusted, same as ph_has_str's lookup path --
             * bounds-check it and skip a corrupt slot instead of reading past the arena. */
            if (!ph_region_ok(ss->off, ss->len, s->hdr->arena_len)) continue;
        }
        { dSP; ENTER; SAVETMPS; PUSHMARK(SP);
          if (s->hdr->key_type==PH_TYPE_INT) XPUSHs(sv_2mortal(newSViv(((const int64_t*)s->slots)[i])));
          else XPUSHs(sv_2mortal(newSVpvn((const char*)s->arena+ss->off, ss->len)));
          PUTBACK; call_sv(cb, G_VOID|G_DISCARD); FREETMPS; LEAVE; }
        SREEXTRACT(self);   /* the callback ran arbitrary Perl */
    }

const char *
path(self)
    SV *self
  PREINIT:
    SEXTRACT(self);
  CODE:
    RETVAL = s->path;
  OUTPUT:
    RETVAL

void
unlink(self)
    SV *self
  PREINIT:
    SEXTRACT(self);
  CODE:
    if (!s->path) croak("unlink: no path");
    if (unlink(s->path) != 0 && errno != ENOENT) croak("unlink(%s): %s", s->path, strerror(errno));

void
DESTROY(self)
    SV *self
  CODE:
    { PhSet *s = INT2PTR(PhSet*, SvIV(SvRV(self)));
      /* Cross-bless safety: see the matching comment on Builder's DESTROY. */
      if (s) { uint32_t tag = s->type_tag; sv_setiv(SvRV(self),0);
        if (tag == PH_SET_TAG) ph_close(s);
        else if (tag == PH_BUILDER_TAG) ph_builder_free((PhBuilder*)s); } }
