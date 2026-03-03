#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define CLONE_KEY(x) ((char *) &x)

/* Maximum safe recursion depth before switching to iterative mode.
 * Each nesting level of [[[...]]] consumes ~3 C stack frames in the
 * recursive clone path (sv_clone for RV + sv_clone for AV + av_clone).
 * The rdepth counter increments once per sv_clone() call, so the
 * nesting level is roughly rdepth/2, using ~450 bytes of stack each.
 *
 * Windows has a 1 MB default thread stack; Cygwin typically 2 MB.
 * Linux/macOS default to 8 MB but some CPAN smokers and containers
 * may have 4 MB or less available after Perl/harness overhead.
 *
 * MAX_DEPTH=2000 on Windows/Cygwin -> ~1000 nesting levels -> ~450 KB.
 * MAX_DEPTH=4000 elsewhere        -> ~2000 nesting levels -> ~900 KB.
 * (GH #77: 32000 was too aggressive — caused SEGV on CPAN smokers.) */
#if defined(_WIN32) || defined(__CYGWIN__)
#define MAX_DEPTH 2000
#else
#define MAX_DEPTH 4000
#endif

#define CLONE_STORE(x,y)						\
do {									\
    if (!hv_store(hseen, CLONE_KEY(x), PTRSIZE, SvREFCNT_inc(y), 0)) {	\
	SvREFCNT_dec(y); /* Restore the refcount */			\
	croak("Can't store clone in seen hash (hseen)");		\
    }									\
    else {	\
  TRACEME(("storing ref = 0x%x clone = 0x%x\n", ref, clone));	\
  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));	\
  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));	\
    }									\
} while (0)

#define CLONE_FETCH(x) (hv_fetch(hseen, CLONE_KEY(x), PTRSIZE, 0))

static SV *hv_clone (SV *, SV *, HV *, int, int, AV *);
static SV *av_clone (SV *, SV *, HV *, int, int, AV *);
static SV *sv_clone (SV *, HV *, int, int, AV *);
static SV *av_clone_iterative(SV *, HV *, int, AV *);

#ifdef DEBUG_CLONE
#define TRACEME(a) printf("%s:%d: ",__FUNCTION__, __LINE__) && printf a;
#else
#define TRACEME(a)
#endif

/* Check whether an mg_obj is a threads::shared::tie instance.
 * The mg_obj is an RV pointing to a blessed PVMG. (GH #18) */
static int
is_threads_shared_tie(SV *obj)
{
  HV *stash;
  if (!obj || !SvROK(obj) || !SvOBJECT(SvRV(obj)))
    return 0;
  stash = SvSTASH(SvRV(obj));
  return stash && HvNAME(stash)
      && strEQ(HvNAME(stash), "threads::shared::tie");
}

static SV *
hv_clone (SV * ref, SV * target, HV* hseen, int depth, int rdepth, AV * weakrefs)
{
  HV *clone = (HV *) target;
  HV *self = (HV *) ref;
  HE *next = NULL;
  int recur = depth ? depth - 1 : 0;

  assert(SvTYPE(ref) == SVt_PVHV);

  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

  /* Pre-size the target hash to avoid incremental resizing */
  if (HvKEYS(self) > 0)
    hv_ksplit(clone, HvKEYS(self));

  hv_iterinit (self);
  while ((next = hv_iternext (self)))
    {
      I32 klen;
      char *kpv = hv_iterkey(next, &klen);
      SV *val = sv_clone(hv_iterval(self, next), hseen, recur, rdepth, weakrefs);
      /* Use hv_iterkey + HeHASH to avoid allocating a mortal SV per key.
       * Negate klen for UTF-8 keys per Perl API convention. */
      if (HeKUTF8(next))
        klen = -klen;
      TRACEME(("clone item %.*s\n", (int)(klen > 0 ? klen : -klen), kpv));
      hv_store(clone, kpv, klen, val, HeHASH(next));
    }

  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
  return (SV *) clone;
}

static SV *
av_clone_iterative(SV * ref, HV* hseen, int rdepth, AV * weakrefs)
{
    AV *self;
    AV *root_clone;
    AV *tail;
    SV *current_ref;
    SV **seen = NULL;
    SV **svp;
    I32 arrlen;
    I32 i;

    if (!ref) return NULL;

    self = (AV *)ref;

    /* Check if we've already cloned this array */
    if ((seen = CLONE_FETCH(ref))) {
        return SvREFCNT_inc(*seen);
    }

    /* Create new array and store it in seen hash immediately */
    root_clone = newAV();
    CLONE_STORE(ref, (SV *)root_clone);

    /* Optimized path for deeply nested single-element arrays:
     * [[[...]]] chains are unrolled iteratively to avoid stack overflow.
     * Each nesting level is an AV with one element (an RV to the next AV). */
    if (av_len(self) == 0) {
        svp = av_fetch(self, 0, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) {
            tail = root_clone;
            current_ref = *svp;

            /* Walk the chain: each step creates one AV and one RV link */
            while (current_ref && SvROK(current_ref) &&
                   SvTYPE(SvRV(current_ref)) == SVt_PVAV &&
                   av_len((AV*)SvRV(current_ref)) == 0) {
                AV *new_av = newAV();
                SV *inner_sv = SvRV(current_ref);

                av_store(tail, 0, newRV_noinc((SV*)new_av));
                CLONE_STORE(inner_sv, (SV*)new_av);

                /* Advance to the next element in the chain */
                svp = av_fetch((AV*)inner_sv, 0, 0);
                if (!svp) break;
                current_ref = *svp;
                tail = new_av;
            }

            /* Handle the final element (leaf or non-matching structure) */
            if (current_ref) {
                if (SvROK(current_ref) &&
                    SvTYPE(SvRV(current_ref)) == SVt_PVAV) {
                    /* Final AV — clone it iteratively too */
                    SV *leaf = av_clone_iterative(SvRV(current_ref),
                                                  hseen, rdepth, weakrefs);
                    av_store(tail, 0, newRV_noinc(leaf));
                } else if (SvROK(current_ref)) {
                    av_store(tail, 0,
                             sv_clone(current_ref, hseen, 1, rdepth, weakrefs));
                } else {
                    av_store(tail, 0, newSVsv(current_ref));
                }
            }

            return (SV*)root_clone;
        }

        /* Single non-array element */
        if (svp) {
            av_store(root_clone, 0,
                     sv_clone(*svp, hseen, 1, rdepth, weakrefs));
        }
        return (SV*)root_clone;
    }

    /* General case: array with multiple elements */
    arrlen = av_len(self);
    av_extend(root_clone, arrlen);

    {
        SV **dst = AvARRAY(root_clone);
        for (i = 0; i <= arrlen; i++) {
            svp = av_fetch(self, i, 0);
            if (svp) {
                dst[i] = sv_clone(*svp, hseen, 1, rdepth, weakrefs);
            }
        }
        AvFILLp(root_clone) = arrlen;
    }

    return (SV*)root_clone;
}

static SV *
av_clone (SV * ref, SV * target, HV* hseen, int depth, int rdepth, AV * weakrefs)
{
    AV *clone;
    AV *self;
    SV **svp;
    SV **dst;
    I32 arrlen = 0;
    I32 i;
    int recur;

    /* For very deep structures, use the iterative approach */
    if (depth == 0) {
        return av_clone_iterative(ref, hseen, rdepth, weakrefs);
    }

    clone = (AV *) target;
    self = (AV *) ref;
    recur = depth > 0 ? depth - 1 : -1;

    assert(SvTYPE(ref) == SVt_PVAV);

    TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

    arrlen = av_len(self);
    av_extend(clone, arrlen);

    /* Use av_fetch on the source (may be magical/tied) but write
     * directly to the target's AvARRAY (we just created it, no magic). */
    dst = AvARRAY(clone);
    for (i = 0; i <= arrlen; i++) {
        svp = av_fetch(self, i, 0);
        if (svp) {
            dst[i] = sv_clone(*svp, hseen, recur, rdepth, weakrefs);
        }
    }
    AvFILLp(clone) = arrlen;

    TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
    return (SV *) clone;
}

static SV *
sv_clone (SV * ref, HV* hseen, int depth, int rdepth, AV * weakrefs)
{
    SV *clone;
    SV **seen = NULL;
    UV visible;
    int magic_ref = 0;

    if (!ref)
        return NULL;

    rdepth++;

    /* Check for deep recursion and switch to iterative mode.
     * A deeply nested arrayref like [[[...]]] alternates between RV and AV
     * at each level, consuming ~3 C stack frames per nesting level.
     * On Windows (1MB default stack), this overflows around depth 2000.
     * When we exceed MAX_DEPTH, handle both AV and RV-to-AV cases. */
    if (rdepth > MAX_DEPTH) {
        if (SvTYPE(ref) == SVt_PVAV) {
            return av_clone_iterative(ref, hseen, rdepth, weakrefs);
        }
        /* For RVs pointing to AVs, follow the reference and use the
         * iterative path -- this is the common case for [[[...]]] */
        if (SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVAV) {
            SV *clone_av = av_clone_iterative(SvRV(ref), hseen, rdepth, weakrefs);
            SV *clone_rv = newRV_noinc(clone_av);
            if (SvOBJECT(SvRV(ref)))
                sv_bless(clone_rv, SvSTASH(SvRV(ref)));
            return clone_rv;
        }
        /* For other types, just return a reference to avoid stack overflow */
        return SvREFCNT_inc(ref);
    }

    clone = ref;

#if PERL_REVISION >= 5 && PERL_VERSION > 8
  /* This is a hack for perl 5.9.*, save everything */
  /* until I find out why mg_find is no longer working */
  visible = 1;
#else
  visible = (SvREFCNT(ref) > 1) || (SvMAGICAL(ref) && mg_find(ref, '<'));
#endif

  TRACEME(("ref = 0x%x(%d)\n", ref, SvREFCNT(ref)));

  if (depth == 0)
    return SvREFCNT_inc(ref);

  if (visible && (seen = CLONE_FETCH(ref)))
    {
      TRACEME(("fetch ref (0x%x)\n", ref));
      return SvREFCNT_inc(*seen);
    }

  /* threads::shared tiedelem PVLVs are proxies to shared data.
   * They would normally be returned by SvREFCNT_inc (like other PVLVs),
   * but that shares the proxy — mutations go back to the shared var.
   * Copy through magic to get a plain unshared value. (GH #18) */
  if (SvTYPE(ref) == SVt_PVLV && SvMAGICAL(ref))
  {
    MAGIC *mg;
    for (mg = SvMAGIC(ref); mg; mg = mg->mg_moremagic)
    {
      if ((mg->mg_type == PERL_MAGIC_tiedelem
           || mg->mg_type == PERL_MAGIC_tiedscalar)
          && is_threads_shared_tie(mg->mg_obj))
      {
        TRACEME(("threads::shared tiedelem PVLV — copy value\n"));
        clone = newSVsv(ref);
        if (visible && ref != clone)
          CLONE_STORE(ref, clone);
        return clone;
      }
    }
  }

  TRACEME(("switch: (0x%x)\n", ref));
  switch (SvTYPE (ref))
    {
      case SVt_NULL:	/* 0 */
        TRACEME(("sv_null\n"));
        clone = newSVsv (ref);
        break;
      case SVt_IV:		/* 1 */
        TRACEME(("int scalar\n"));
      case SVt_NV:		/* 2 */
        TRACEME(("double scalar\n"));
        clone = newSVsv (ref);
        break;
#if PERL_VERSION <= 10
      case SVt_RV:		/* 3 */
        TRACEME(("ref scalar\n"));
        clone = newSVsv (ref);
        break;
#endif
      case SVt_PV:		/* 4 */
        TRACEME(("string scalar\n"));
/*
* Note: when using a Debug Perl with READONLY_COW
* we cannot do 'sv_buf_to_rw + sv_buf_to_ro' as these APIs calls are not exported
*/
#if defined(SV_COW_REFCNT_MAX) && !defined(PERL_DEBUG_READONLY_COW)
        /* only for simple PVs unblessed */
        if ( SvIsCOW(ref) && !SvOOK(ref) && SvLEN(ref) > 0 ) {

          if ( CowREFCNT(ref) < (SV_COW_REFCNT_MAX - 1) ) {
            /* cannot use newSVpv_share as this going to use a new PV we do not want to clone it */
            /* create a fresh new PV */
            clone = newSV(0);
            sv_upgrade(clone, SVt_PV);
            SvPOK_on(clone);
            SvIsCOW_on(clone);

            /* points the str slot to the COWed one */
            SvPV_set(clone, SvPVX(ref) );
            CowREFCNT(ref)++;

            /* preserve cur, len, and value-relevant flags */
            SvCUR_set(clone, SvCUR(ref));
            SvLEN_set(clone, SvLEN(ref));
            if (SvUTF8(ref))
              SvUTF8_on(clone);
          } else {
            /* we are above SV_COW_REFCNT_MAX, create a new SvPV but preserve the COW */
            clone = newSVsv (ref);
            SvIsCOW_on(clone);
            CowREFCNT(clone) = 0; /* set the CowREFCNT to 0 */
          }

        } else {
          clone = newSVsv (ref);
        }
#else
        clone = newSVsv (ref);
#endif
        break;
      case SVt_PVIV:		/* 5 */
        TRACEME (("PVIV double-type\n"));
      case SVt_PVNV:		/* 6 */
        TRACEME (("PVNV double-type\n"));
        clone = newSVsv (ref);
        break;
      case SVt_PVMG:	/* 7 */
        TRACEME(("magic scalar\n"));
        clone = newSVsv (ref);
        break;
      case SVt_PVAV:	/* 10 */
        clone = (SV *) newAV();
        break;
      case SVt_PVHV:	/* 11 */
        clone = (SV *) newHV();
        break;
      #if PERL_VERSION <= 8
      case SVt_PVBM:	/* 8 */
      #elif PERL_VERSION >= 11
      case SVt_REGEXP:	/* 8 */
      #endif
      case SVt_PVLV:	/* 9 */
      case SVt_PVCV:	/* 12 */
      case SVt_PVGV:	/* 13 */
      case SVt_PVFM:	/* 14 */
      case SVt_PVIO:	/* 15 */
        TRACEME(("default: type = 0x%x\n", SvTYPE (ref)));
        clone = SvREFCNT_inc(ref);  /* just return the ref */
        break;
      default:
        croak("unknown type: 0x%x", SvTYPE(ref));
    }

  /**
    * It is *vital* that this is performed *before* recursion,
    * to properly handle circular references. cb 2001-02-06
    */

  if ( visible && ref != clone )
      CLONE_STORE(ref,clone);

    /* If clone == ref (e.g. for PVLV, PVGV, PVCV types), we just
     * incremented the refcount — skip all internal cloning to avoid
     * adding duplicate magic entries or corrupting the original SV.
     * (fixes GH #42: memory leak when cloning non-existent hash values) */
  if (ref == clone)
      return clone;

    /*
     * We'll assume (in the absence of evidence to the contrary) that A) a
     * tied hash/array doesn't store its elements in the usual way (i.e.
     * the mg->mg_object(s) take full responsibility for them) and B) that
     * references aren't tied.
     *
     * If theses assumptions hold, the three options below are mutually
     * exclusive.
     *
     * More precisely: 1 & 2 are probably mutually exclusive; 2 & 3 are
     * definitely mutually exclusive; we have to test 1 before giving 2
     * a chance; and we'll assume that 1 & 3 are mutually exclusive unless
     * and until we can be test-cased out of our delusion.
     *
     * chocolateboy: 2001-05-29
     */

    /* 1: TIED */
  if (SvMAGICAL(ref) )
    {
      MAGIC* mg;
      int has_qr = 0;

      for (mg = SvMAGIC(ref); mg; mg = mg->mg_moremagic)
      {
        SV *obj = (SV *) NULL;
        TRACEME(("magic type: %c\n", mg->mg_type));

        /* PERL_MAGIC_ext: opaque XS data, handle before the mg_obj check
         * since ext magic often has mg_obj == NULL (GH #27, GH #16) */
        if (mg->mg_type == '~')
        {
#if defined(MGf_DUP) && defined(sv_magicext)
          /* If the ext magic has a dup callback (e.g. Math::BigInt::GMP),
           * clone it properly via sv_magicext + svt_dup.
           * Otherwise skip it (e.g. DBI handles have no dup).
           * Note: we check only for svt_dup presence, not MGf_DUP flag,
           * because some older XS modules (e.g. Math::BigInt::GMP on
           * Perl 5.22) provide svt_dup without setting MGf_DUP. (GH #76) */
          if (mg->mg_virtual && mg->mg_virtual->svt_dup)
          {
            MAGIC *new_mg;
            new_mg = sv_magicext(clone, mg->mg_obj,
                                 mg->mg_type, mg->mg_virtual,
                                 mg->mg_ptr, mg->mg_len);
            new_mg->mg_flags |= MGf_DUP;
            /* CLONE_PARAMS is NULL since we are not in a thread clone.
             * Known callers (e.g. Math::BigInt::GMP) ignore it. */
            mg->mg_virtual->svt_dup(aTHX_ new_mg, NULL);
          }
#endif
          continue;
        }

        /* threads::shared uses tie magic ('P') with a threads::shared::tie
         * object, and shared_scalar magic ('n'/'N') for scalars.
         * Cloning these produces invalid tie objects that crash on access.
         * Strip the sharing magic so hv_clone/av_clone can iterate through
         * the tie to read the actual data. (GH #18) */
        if (mg->mg_type == PERL_MAGIC_shared_scalar
            || mg->mg_type == PERL_MAGIC_shared)
          continue;

        /* Some mg_obj's can be null, don't bother cloning */
        if ( mg->mg_obj != NULL )
        {
          switch (mg->mg_type)
          {
            case 'r':	/* PERL_MAGIC_qr  */
              obj = mg->mg_obj;
              has_qr = 1;
              break;
            case 't':	/* PERL_MAGIC_taint */
            case '<': /* PERL_MAGIC_backref */
            case '@':  /* PERL_MAGIC_arylen_p */
              continue;
              break;
            case 'P': /* PERL_MAGIC_tied */
            case 'p': /* PERL_MAGIC_tiedelem */
            case 'q': /* PERL_MAGIC_tiedscalar */
              /* threads::shared::tie objects are not real tie objects --
               * skip them so the clone becomes a plain unshared copy.
               * The data will be read through the tie during hv_clone/av_clone. */
              if (is_threads_shared_tie(mg->mg_obj))
                continue;
	            magic_ref++;
	      /* fall through */
            default:
              obj = sv_clone(mg->mg_obj, hseen, -1, rdepth, weakrefs);
          }
        } else {
          TRACEME(("magic object for type %c in NULL\n", mg->mg_type));
        }

        { /* clone the mg_ptr pv */
          char *mg_ptr = mg->mg_ptr; /* default */

          if (mg->mg_len >= 0) { /* copy the pv */
            if (mg_ptr) {
              Newxz(mg_ptr, mg->mg_len+1, char);
              Copy(mg->mg_ptr, mg_ptr, mg->mg_len, char);
            }
          } else if (mg->mg_len == HEf_SVKEY) {
            /* let's share the SV for now */
            SvREFCNT_inc((SV*)mg->mg_ptr);
          } else if (mg->mg_len == -1 && mg->mg_type == PERL_MAGIC_utf8) { /* copy the cache */
            if (mg->mg_ptr) {
              STRLEN *cache;
              Newxz(cache, PERL_MAGIC_UTF8_CACHESIZE * 2, STRLEN);
              mg_ptr = (char *) cache;
              Copy(mg->mg_ptr, mg_ptr, PERL_MAGIC_UTF8_CACHESIZE * 2, STRLEN);
            }
          } else if ( mg->mg_ptr != NULL) {
            croak("Unsupported magic_ptr clone");
          }

          sv_magic(clone,
                   obj,
                   mg->mg_type,
                   mg_ptr,
                   mg->mg_len);

        }
      }
      /* Null the qr vtable -- avoid mg_find traversal if we already know */
      if (has_qr && (mg = mg_find(clone, 'r')))
        mg->mg_virtual = (MGVTBL *) NULL;
    }
    /* 2: HASH/ARRAY  - (with 'internal' elements) */
  if ( magic_ref )
  {
    ;;
  }
  else if ( SvTYPE(ref) == SVt_PVHV )
    clone = hv_clone (ref, clone, hseen, depth, rdepth, weakrefs);
  else if ( SvTYPE(ref) == SVt_PVAV )
    clone = av_clone (ref, clone, hseen, depth, rdepth, weakrefs);
    /* 3: REFERENCE (inlined for speed) */
  else if (SvROK (ref))
    {
      TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
      SvREFCNT_dec(SvRV(clone));
      SvRV(clone) = sv_clone (SvRV(ref), hseen, depth, rdepth, weakrefs); /* Clone the referent */
      if (SvOBJECT(SvRV(ref)))
      {
          sv_bless (clone, SvSTASH (SvRV (ref)));
      }
      if (SvWEAKREF(ref)) {
          /* Defer weakening until after the entire clone graph is built.
           * sv_rvweaken decrements the referent's refcount, which can
           * destroy it if no other strong references exist yet.
           * By deferring, we ensure all strong references are in place
           * before any weakening occurs. (fixes GH #15) */
          av_push(weakrefs, SvREFCNT_inc_simple_NN(clone));
      }
    }

  TRACEME(("clone = 0x%x(%d)\n", clone, SvREFCNT(clone)));
  return clone;
}

MODULE = Clone		PACKAGE = Clone

PROTOTYPES: ENABLE

void
clone(self, depth=-1)
	SV *self
	int depth
	PREINIT:
	SV *clone = &PL_sv_undef;
        HV *hseen = newHV();
        AV *weakrefs = newAV();
	PPCODE:
	TRACEME(("ref = 0x%x\n", self));
	clone = sv_clone(self, hseen, depth, 0, weakrefs);
	/* Now apply deferred weakening (GH #15).
	 * All strong references in the clone graph are established,
	 * so it is safe to weaken references without destroying referents. */
	{
	    I32 i;
	    I32 len = av_len(weakrefs);
	    for (i = 0; i <= len; i++) {
	        SV **svp = av_fetch(weakrefs, i, 0);
	        if (svp && *svp && SvROK(*svp)) {
	            sv_rvweaken(*svp);
	        }
	    }
	}
	hv_clear(hseen);  /* Free HV */
        SvREFCNT_dec((SV *)hseen);
        SvREFCNT_dec((SV *)weakrefs);
	EXTEND(SP,1);
	PUSHs(sv_2mortal(clone));
