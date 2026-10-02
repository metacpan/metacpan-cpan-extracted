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
 * rdepth is passed BY VALUE, so it measures the depth of the current
 * sv_clone() call chain — not the number of calls made.  Sibling
 * elements in the av_clone/hv_clone element loops each receive the
 * same parent rdepth, so width does not accumulate: a flat array of
 * N elements peaks at rdepth 3 regardless of N.  Only nesting raises
 * it (~2 units per [[[...]]] level, 1 per scalar-ref chain link).
 * Do not "fix" width-driven rdepth inflation; it does not occur.
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
    else {								\
	TRACEME(("storing ref = 0x%" UVxf " clone = 0x%" UVxf "\n",	\
		 PTR2UV(x), PTR2UV(y)));				\
	TRACEME(("clone = 0x%" UVxf "(%d)\n",				\
		 PTR2UV(y), SvREFCNT(y)));				\
	TRACEME(("ref = 0x%" UVxf "(%d)\n",				\
		 PTR2UV(x), SvREFCNT(x)));				\
    }									\
} while (0)

#define CLONE_FETCH(x) (hv_fetch(hseen, CLONE_KEY(x), PTRSIZE, 0))

/* Work item for the iterative (past-MAX_DEPTH) cloner: a source
 * container paired with its already-allocated clone shell. */
typedef struct {
    SV *src;	/* source AV or HV                                */
    SV *dst;	/* its clone, already registered in hseen, empty  */
} clone_task;

typedef struct {
    clone_task *items;
    I32 len;
    I32 max;
    /* Scratch buffer rv_clone_chain walks RV chains into.  It lives here
     * so it is allocated once per clone rather than once per element, and
     * so it is covered by the queue's croak-safe cleanup.  rv_clone_chain
     * never re-enters itself, so a single shared buffer is safe. */
    SV **chain;
    I32 chain_max;
} clone_queue;

static SV *hv_clone (SV *, SV *, HV *, int, int, AV *);
static SV *av_clone (SV *, SV *, HV *, int, int, AV *);
static SV *sv_clone (SV *, HV *, int, int, AV *);
static SV *clone_container_iterative(SV *, HV *, int, AV *);
static SV *rv_clone_chain(SV *, HV *, int, AV *, clone_queue *);
static SV *rv_clone_iterative(SV *, HV *, int, AV *);
static int clone_magic(SV *, SV *, HV *, int, AV *);

#ifdef DEBUG_CLONE
/* __FUNCTION__ is supported by GCC, Clang and MSVC (all versions);
 * __func__ needs C99 (MSVC only since VS2015) and is rejected by a
 * strict -std=c89 -pedantic build. */
#define TRACEME(a) do { printf("%s:%d: ",__FUNCTION__, __LINE__); printf a; } while (0)
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

  TRACEME(("ref = 0x%" UVxf "(%d)\n", PTR2UV(ref), SvREFCNT(ref)));

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

  TRACEME(("clone = 0x%" UVxf "(%d)\n", PTR2UV(clone), SvREFCNT(clone)));
  return (SV *) clone;
}

/* ------------------------------------------------------------------- *
 * Iterative container cloning (used once rdepth exceeds MAX_DEPTH)
 *
 * Past MAX_DEPTH the recursive path would overflow the C stack, so
 * nested containers are cloned through an explicit, heap-allocated work
 * queue instead.  Each task pairs a source container with an empty clone
 * shell that is already registered in hseen; draining a task fills the
 * shell and pushes a new task for every nested container it finds.
 *
 * The previous implementation only unrolled single-element array chains
 * and otherwise recursed back through sv_clone, costing one C stack
 * frame per nesting level for hashes and mixed array/hash structures.
 * That overflowed Windows' 1 MB default thread stack (GH #121, GH #146).
 * The queue makes C stack usage O(1) in the nesting depth for every shape.
 * ------------------------------------------------------------------- */

/* Registered with SAVEDESTRUCTOR_X so the queue is released both on the
 * normal path (at LEAVE) and when cloning croaks — a dying __WARN__
 * handler on the depth-limit warning, or a tied FETCH, longjmps straight
 * past any explicit Safefree.  The queue itself lives on the heap because
 * the savestack is unwound after our C frame is already gone. */
static void
clone_queue_free(pTHX_ void *p)
{
    clone_queue *q = (clone_queue *) p;
    I32 i;

    for (i = 0; i < q->len; i++)
        SvREFCNT_dec(q->items[i].src);

    Safefree(q->items);
    Safefree(q->chain);
    Safefree(q);
}

static void
clone_queue_push(clone_queue *q, SV *src, SV *dst)
{
    if (q->len >= q->max) {
        q->max = q->max ? q->max * 2 : 64;
        if (q->items)
            Renew(q->items, q->max, clone_task);
        else
            Newx(q->items, q->max, clone_task);
    }
    /* Hold a reference to the source until the task is drained.  Filling
     * is deferred, and anything running in between (a tied FETCH, a
     * DESTROY, a __WARN__ handler) can drop the caller's last reference to
     * a container we have already queued.  dst needs no such reference:
     * hseen holds one.  clone_queue_free releases these. */
    q->items[q->len].src = SvREFCNT_inc_simple_NN(src);
    q->items[q->len].dst = dst;
    q->len++;
}

/* Return the clone of a container (AV or HV), creating an empty shell and
 * queueing it for filling the first time we see it.  Registering the shell
 * in hseen before it is filled is what makes circular references safe.
 * The returned SV carries one reference for the caller. */
static SV *
clone_shell(SV *ref, HV *hseen, clone_queue *q)
{
    SV **seen;
    SV *clone;	/* named to match CLONE_STORE's TRACEME under DEBUG_CLONE */

    if ((seen = CLONE_FETCH(ref)))
        return SvREFCNT_inc(*seen);

    clone = (SvTYPE(ref) == SVt_PVHV) ? (SV *) newHV() : (SV *) newAV();
    CLONE_STORE(ref, clone);
    clone_queue_push(q, ref, clone);

    return clone;
}

/* Clone one element of a container without recursing into nested
 * containers: those become queued tasks instead. */
static SV *
clone_elem(SV *e, HV *hseen, int rdepth, AV *weakrefs, clone_queue *q)
{
    if (!e)
        return NULL;

    if (SvROK(e)) {
        SV *referent = SvRV(e);

        /* Handled inline rather than through rv_clone_chain: a direct
         * reference to a container is by far the common case, and this
         * skips the chain walk for a chain of length one. */
        if (referent
            && (SvTYPE(referent) == SVt_PVAV || SvTYPE(referent) == SVt_PVHV)) {
            SV *new_rv = newRV_noinc(clone_shell(referent, hseen, q));
            if (SvOBJECT(referent))
                sv_bless(new_rv, SvSTASH(referent));
            if (SvWEAKREF(e))
                av_push(weakrefs, SvREFCNT_inc_simple_NN(new_rv));
            return new_rv;
        }

        /* Scalar-ref chain: walked iteratively, container leaves rejoin
         * this queue. */
        return rv_clone_chain(e, hseen, rdepth, weakrefs, q);
    }

    /* Plain scalar leaf.  rdepth is above MAX_DEPTH here, so sv_clone
     * takes its non-recursive branch (newSVsv, or share-with-warning for
     * types that cannot be copied at all). */
    return sv_clone(e, hseen, 1, rdepth, weakrefs);
}

static void
clone_fill_av(AV *src, AV *dst, HV *hseen, int rdepth, AV *weakrefs,
              clone_queue *q)
{
    SV **svp;
    SV **slot;
    I32 arrlen;
    I32 i;

    arrlen = av_len(src);
    if (arrlen < 0)
        return;

    av_extend(dst, arrlen);

    /* Fetch from the source (which may be magical) but write straight
     * into the target's AvARRAY: we just created it, so it has no magic. */
    slot = AvARRAY(dst);
    for (i = 0; i <= arrlen; i++) {
        svp = av_fetch(src, i, 0);
        if (svp)
            slot[i] = clone_elem(*svp, hseen, rdepth, weakrefs, q);
    }
    AvFILLp(dst) = arrlen;
}

static void
clone_fill_hv(HV *src, HV *dst, HV *hseen, int rdepth, AV *weakrefs,
              clone_queue *q)
{
    HE *next;

    /* Pre-size to avoid incremental resizing */
    if (HvKEYS(src) > 0)
        hv_ksplit(dst, HvKEYS(src));

    hv_iterinit(src);
    while ((next = hv_iternext(src))) {
        I32 klen;
        char *kpv = hv_iterkey(next, &klen);
        SV *val = clone_elem(hv_iterval(src, next), hseen, rdepth,
                             weakrefs, q);
        /* Negate klen for UTF-8 keys per Perl API convention. */
        if (HeKUTF8(next))
            klen = -klen;
        hv_store(dst, kpv, klen, val, HeHASH(next));
    }
}

/* Fill every queued shell.  Tasks appended while draining are picked up
 * by the same loop, so the whole sub-graph is cloned without recursion.
 * q->items may be reallocated by clone_queue_push, hence the re-indexing
 * on each iteration rather than a cached pointer. */
static void
clone_drain(clone_queue *q, HV *hseen, int rdepth, AV *weakrefs)
{
    I32 i;

    for (i = 0; i < q->len; i++) {
        SV *src = q->items[i].src;
        SV *dst = q->items[i].dst;

        if (SvTYPE(src) == SVt_PVHV)
            clone_fill_hv((HV *)src, (HV *)dst, hseen, rdepth, weakrefs, q);
        else
            clone_fill_av((AV *)src, (AV *)dst, hseen, rdepth, weakrefs, q);
    }
}

/* Entry point for cloning an AV or HV past MAX_DEPTH. */
static SV *
clone_container_iterative(SV * ref, HV* hseen, int rdepth, AV * weakrefs)
{
    clone_queue *q;
    SV *root_clone;

    if (!ref) return NULL;

    Newxz(q, 1, clone_queue);
    ENTER;
    SAVEDESTRUCTOR_X(clone_queue_free, q);

    root_clone = clone_shell(ref, hseen, q);
    clone_drain(q, hseen, rdepth, weakrefs);

    LEAVE;
    return root_clone;
}

/* Iterative clone for deeply nested scalar-ref chains past MAX_DEPTH.
 * Avoids stack overflow by unrolling the RV->RV->...->leaf chain without
 * recursion, then rebuilding from the bottom up.
 *
 * This mirrors clone_container_iterative: instead of returning
 * SvREFCNT_inc(ref) (a shared alias), it produces a true deep copy of the
 * entire scalar-ref chain, preserving isolation. (GH #107)
 *
 * A container at the end of the chain is handed to the caller's work
 * queue rather than cloned inline, so an alternating ref/container
 * structure costs no C stack either. */
static SV *
rv_clone_chain(SV * ref, HV* hseen, int rdepth, AV * weakrefs, clone_queue *q)
{
    SV **chain;
    I32 chain_len;
    SV *current;
    SV *leaf_clone;
    SV *result;
    SV **seen;
    I32 i;

    if (!ref || !SvROK(ref)) return NULL;

    if (!q->chain) {
        q->chain_max = 64;
        Newx(q->chain, q->chain_max, SV *);
    }
    chain = q->chain;
    chain_len = 0;

    /* Walk the RV chain, collecting each node until we reach a non-RV leaf
     * or an RV we have already cloned.
     *
     * Cycle guard: a chain reachable only past MAX_DEPTH never passed
     * through the recursive sv_clone path, so nothing registered its nodes
     * in hseen and it can fold back on itself ("my $x; $x = \$x" hung below
     * a deep spine, growing chain[] via Renew() until allocation aborted).
     * Registering a placeholder RV for every link as we descend makes the
     * revisit visible: CLONE_FETCH below then terminates the walk and the
     * rebuild closes the cycle onto the placeholder.  The placeholder is a
     * live RV (to undef) rather than an empty SV so the rebuild can simply
     * retarget it, exactly as the recursive path does in sv_clone.
     *
     * The ordering matters for more than cycles: each node joins chain[]
     * before we descend into its referent, so a referent found cached on
     * the next iteration still has its wrapping RV in the chain and the
     * rebuild produces a proper RV->referent_clone.  Checking the referent
     * before adding the wrapper would hand a bare HV/AV back to a caller
     * expecting an RV ("Bizarre copy of HASH"). */
    leaf_clone = NULL;
    current = ref;
    while (current && SvROK(current)) {
        SV **already;
        SV *placeholder;

        if ((already = CLONE_FETCH(current))) {
            /* Cycle, or an RV shared with somewhere already cloned. */
            leaf_clone = SvREFCNT_inc(*already);
            break;
        }

        if (chain_len >= q->chain_max) {
            q->chain_max *= 2;
            Renew(q->chain, q->chain_max, SV *);
            chain = q->chain;
        }
        chain[chain_len++] = current;

        /* hseen takes the placeholder's only reference (CLONE_STORE incs,
         * so drop ours).  Holding a second one here would leak the whole
         * chain if cloning croaked before the rebuild below could hand it
         * on -- hseen is released during unwinding, nothing else is. */
        placeholder = newRV_noinc(newSV(0));
        CLONE_STORE(current, placeholder);
        SvREFCNT_dec(placeholder);

        current = SvRV(current);
    }

    /* If we did not hit a cached referent above, current is now the non-RV
     * leaf; clone it based on its type. */
    if (!leaf_clone && current) {
        if (SvTYPE(current) == SVt_PVAV || SvTYPE(current) == SVt_PVHV) {
            leaf_clone = clone_shell(current, hseen, q);
        } else {
            seen = CLONE_FETCH(current);
            if (seen) {
                leaf_clone = SvREFCNT_inc(*seen);
            } else {
                /* Mirror the non-cloneable cases from the regular sv_clone
                 * switch (PVCV/PVGV/PVFM/PVIO/PVLV/REGEXP/BM): newSVsv()
                 * croaks on these ("Bizarre copy of CODE in subroutine
                 * entry") or stringifies them.  Share via SvREFCNT_inc
                 * instead. */
                switch (SvTYPE(current)) {
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
                        leaf_clone = SvREFCNT_inc(current);
                        break;
                    default:
                        leaf_clone = newSVsv(current);
                        if ((SvREFCNT(current) > 1) || SvMAGICAL(current))
                            CLONE_STORE(current, leaf_clone);
                        break;
                }
            }
        }
    }

    /* Degenerate case (a ref with no referent at all): the placeholders are
     * already registered in hseen, so hand the chain an undef leaf rather
     * than returning the original and leaving hseen inconsistent. */
    if (!leaf_clone)
        leaf_clone = newSV(0);

    /* Rebuild the RV chain from the bottom up by retargeting each link's
     * placeholder at the clone below it.  Retargeting rather than building
     * fresh RVs is what lets a cycle close: the link that folded back
     * already holds the placeholder it has to point at. */
    result = leaf_clone;
    for (i = chain_len - 1; i >= 0; i--) {
        SV *rv = chain[i];
        SV **php = CLONE_FETCH(rv);
        SV *new_rv;

        if (!php)			/* cannot happen: stored during the walk */
            continue;
        new_rv = *php;

        SvREFCNT_dec(SvRV(new_rv));	/* drop the placeholder's undef  */
        SvRV_set(new_rv, result);	/* hands our reference to new_rv */

        if (SvOBJECT(SvRV(rv)))
            sv_bless(new_rv, SvSTASH(SvRV(rv)));
        if (SvWEAKREF(rv))
            av_push(weakrefs, SvREFCNT_inc_simple_NN(new_rv));

        /* new_rv is owned by hseen; take a reference for whoever ends up
         * holding this link (the next link up, or our caller). */
        result = SvREFCNT_inc_simple_NN(new_rv);
    }

    return result;
}

/* Entry point for cloning a reference past MAX_DEPTH: owns the work
 * queue that rv_clone_chain and clone_elem feed. */
static SV *
rv_clone_iterative(SV * ref, HV* hseen, int rdepth, AV * weakrefs)
{
    clone_queue *q;
    SV *result;

    Newxz(q, 1, clone_queue);
    ENTER;
    SAVEDESTRUCTOR_X(clone_queue_free, q);

    result = rv_clone_chain(ref, hseen, rdepth, weakrefs, q);
    clone_drain(q, hseen, rdepth, weakrefs);

    LEAVE;
    return result;
}

/* Clone all magic entries from ref onto clone.
 * Returns the number of tie-magic entries cloned; the caller uses this
 * to decide whether to skip direct HV/AV element iteration (tied
 * containers are managed entirely by their tie magic). */
static int
clone_magic(SV * ref, SV * clone, HV* hseen, int rdepth, AV * weakrefs)
{
    MAGIC* mg;
    int has_qr = 0;
    int magic_ref = 0;

    for (mg = SvMAGIC(ref); mg; mg = mg->mg_moremagic)
    {
      SV *obj = (SV *) NULL;
      int obj_cloned = 0;
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
            continue; /* resumes the outer magic iteration loop */
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
            obj_cloned = 1;
        }
      } else {
        TRACEME(("magic object for type %c in NULL\n", mg->mg_type));
      }

      { /* clone the mg_ptr pv */
        char *mg_ptr = mg->mg_ptr; /* default */
        U32 obj_rc = obj_cloned ? SvREFCNT(obj) : 0;

        if (mg->mg_len >= 0) {
          /* sv_magic() with non-negative namlen calls savepvn()
           * internally to make its own copy — no need to allocate
           * an intermediate buffer here; just pass the original
           * mg_ptr through.  (fixes 20-year-old memory leak) */
        } else if (mg->mg_len == HEf_SVKEY) {
          /* mg_ptr is an SV*; sv_magic() below will SvREFCNT_inc it */
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

        /* sv_magic() usually takes its own SvREFCNT_inc on obj (setting
         * MGf_REFCOUNTED), in which case the caller reference returned
         * by sv_clone() must be released -- otherwise the cloned mg_obj
         * leaks one refcount per clone (DESTROY never fires on the
         * cloned tie object).
         * But it stores mg_obj *unreferenced* in several cases: a
         * self-referential obj, arylen ('#') / regdata ('D') /
         * regdatum ('d') / symtab (':') magic, and glob-slot
         * back-pointers.  That list has changed across perl releases,
         * so instead of mirroring it here, observe whether the refcount
         * actually went up.  Decrementing when perl took no reference
         * would free an SV the magic still points at. */
        if (obj_cloned && SvREFCNT(obj) > obj_rc)
          SvREFCNT_dec(obj);
      }
    }
    /* Null the qr vtable -- avoid mg_find traversal if we already know */
    if (has_qr && (mg = mg_find(clone, 'r')))
      mg->mg_virtual = (MGVTBL *) NULL;

    return magic_ref;
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

    /* Note: depth is never 0 here.  sv_clone() returns SvREFCNT_inc(ref) on
     * depth == 0 before dispatching to av_clone.  depth < 0 means unlimited
     * (the XS default is -1), which is why recur pins at -1 below instead of
     * decrementing.  Deep structures do not reach here either -- sv_clone's
     * rdepth > MAX_DEPTH guard hands them to clone_container_iterative. */

    clone = (AV *) target;
    self = (AV *) ref;
    recur = depth > 0 ? depth - 1 : -1;

    assert(SvTYPE(ref) == SVt_PVAV);

    TRACEME(("ref = 0x%" UVxf "(%d)\n", PTR2UV(ref), SvREFCNT(ref)));

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

    TRACEME(("clone = 0x%" UVxf "(%d)\n", PTR2UV(clone), SvREFCNT(clone)));
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

    /* depth == 0 means "share, don't clone" — honour it before the
     * MAX_DEPTH iterative fallback below.  Both can trigger on the same
     * call: rdepth advances two per nesting level while depth drops one,
     * so a chain nested MAX_DEPTH/2 levels deep and cloned with that same
     * explicit depth reaches depth 0 exactly as rdepth crosses MAX_DEPTH.
     * Checking depth later let the fallback intercept that call and
     * deep-copy a leaf the caller asked to share. */
    if (depth == 0)
        return SvREFCNT_inc(ref);

    /* Check for deep recursion and switch to iterative mode.
     * A deeply nested arrayref like [[[...]]] alternates between RV and AV
     * at each level, consuming ~3 C stack frames per nesting level.
     * On Windows (1MB default stack), this overflows around depth 2000.
     * When we exceed MAX_DEPTH, handle both AV and RV-to-AV cases. */
    if (rdepth > MAX_DEPTH) {
        if (SvTYPE(ref) == SVt_PVAV || SvTYPE(ref) == SVt_PVHV) {
            return clone_container_iterative(ref, hseen, rdepth, weakrefs);
        }
        /* All RV types (AV, HV, scalar-ref chains) are handled uniformly
         * by rv_clone_iterative, which walks the reference chain, hands
         * container referents to the iterative work queue,
         * and properly preserves blessings and SvWEAKREF flags.
         * (The AV/HV cases were previously inlined here but lacked weakref
         * handling — see GH #107, #116, #119 for the iterative gap pattern.) */
        if (SvROK(ref))
            return rv_clone_iterative(ref, hseen, rdepth, weakrefs);
        /* Simple scalars (non-reference, non-container) can always be
         * safely copied without recursion.  newSVsv creates an independent
         * copy, preventing aliasing of leaf values inside iteratively-cloned
         * containers.  Without this, the iterative container cloner
         * would share leaf SVs between original and clone — mutations
         * through a reference to the clone's value would corrupt the
         * original.  (GH #113) */
        switch (SvTYPE(ref)) {
            case SVt_NULL:
            case SVt_IV:
            case SVt_NV:
#if PERL_VERSION <= 10
            case SVt_RV:
#endif
            case SVt_PV:
            case SVt_PVIV:
            case SVt_PVNV:
            case SVt_PVMG:
                return newSVsv(ref);
            default:
                break;
        }
        /* Non-clonable types past MAX_DEPTH (e.g. PVGV, PVCV, PVFM, PVIO):
         * these cannot be deep-copied regardless of depth; share with a
         * warning. */
        {
            SV *warn_sv = get_sv("Clone::WARN", 0);
            if (!warn_sv || SvTRUE(warn_sv))
                Perl_warn(aTHX_ "Clone: depth limit (%d) exceeded; "
                          "reference will be shared, not deep-copied", MAX_DEPTH);
        }
        return SvREFCNT_inc(ref);
    }

    clone = ref;

  /* Track this SV in hseen only if it could be reached from multiple
   * paths in the data structure.  Single-refcount, non-magical SVs
   * are unique leaves — skipping the hash lookup/store for them is a
   * significant win on structures with many distinct scalar values.
   *
   * Cases that require tracking:
   *  - SvREFCNT > 1 : SV is shared (appears in multiple slots)
   *  - SvMAGICAL     : may be a weakref target (backref '<' magic
   *                    for non-HV types), tied, or carry other magic
   *  - HV with SvOOK : since Perl 5.10, weakref back-references for
   *                    HVs are stored in the HV's AUX struct (via
   *                    SvOOK) rather than as PERL_MAGIC_backref.  An
   *                    HV that is the target of a weakened reference
   *                    has SvOOK set but is NOT SvMAGICAL, so we must
   *                    check SvOOK explicitly for HVs.
   *
   * Historical note: Perl 5.9.x moved HV backrefs from magic to
   * HvAUX; a blanket "visible = 1" was used as a workaround.  The
   * check below replaces that with a targeted condition. */
  visible = (SvREFCNT(ref) > 1) || SvMAGICAL(ref)
          || (SvTYPE(ref) == SVt_PVHV && SvOOK(ref));

  TRACEME(("ref = 0x%" UVxf "(%d)\n", PTR2UV(ref), SvREFCNT(ref)));

  if (visible && (seen = CLONE_FETCH(ref)))
    {
      TRACEME(("fetch ref (0x%" UVxf ")\n", PTR2UV(ref)));
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

  TRACEME(("switch: (0x%" UVxf ")\n", PTR2UV(ref)));
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
#if PERL_VERSION >= 38
      case SVt_PVOBJ:	/* 16 — class instances (Perl 5.38+) */
        clone = newSV(0);
        sv_upgrade(clone, SVt_PVOBJ);
        /* Establish the empty-field state explicitly rather than trusting
         * sv_upgrade to have done it: the field-cloning block below only
         * runs when the source has at least one field, so a field-less
         * class would otherwise ship whatever the upgrade left behind and
         * sv_clear would walk it at free time. */
        ObjectFIELDS(clone) = NULL;
        ObjectMAXFIELD(clone) = -1;
        break;
#endif
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
        TRACEME(("default: type = 0x%x\n", (int)SvTYPE (ref)));
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

    /* 1: TIED / MAGIC */
  if (SvMAGICAL(ref))
      magic_ref = clone_magic(ref, clone, hseen, rdepth, weakrefs);

    /* 2: HASH/ARRAY  - (with 'internal' elements) */
    /* For tied HV/AV (magic_ref > 0): skip direct element iteration;
     * the tie magic cloned above handles the data. */
  if ( !magic_ref )
  {
    if ( SvTYPE(ref) == SVt_PVHV )
      clone = hv_clone (ref, clone, hseen, depth, rdepth, weakrefs);
    else if ( SvTYPE(ref) == SVt_PVAV )
      clone = av_clone (ref, clone, hseen, depth, rdepth, weakrefs);
#if PERL_VERSION >= 38
    /* class instances (Perl 5.38+): clone each object field */
    else if ( SvTYPE(ref) == SVt_PVOBJ )
      {
        SSize_t maxfield = ObjectMAXFIELD(ref);
        if (maxfield >= 0)
          {
            SV **src_fields = ObjectFIELDS(ref);
            SV **dst_fields;
            int recur = depth > 0 ? depth - 1 : -1;
            SSize_t fi;

            Newx(dst_fields, maxfield + 1, SV *);
            for (fi = 0; fi <= maxfield; fi++)
              {
                dst_fields[fi] = src_fields[fi]
                  ? sv_clone(src_fields[fi], hseen, recur, rdepth, weakrefs)
                  : newSV(0);
              }
            ObjectFIELDS(clone) = dst_fields;
            ObjectMAXFIELD(clone) = maxfield;
          }
      }
#endif /* PERL_VERSION >= 38 */
    /* 3: REFERENCE (inlined for speed) */
    else if (SvROK (ref))
      {
        TRACEME(("clone = 0x%" UVxf "(%d)\n", PTR2UV(clone), SvREFCNT(clone)));
        SvREFCNT_dec(SvRV(clone));
        SvRV(clone) = sv_clone (SvRV(ref), hseen, depth, rdepth, weakrefs); /* Clone the referent */
        if (SvOBJECT(SvRV(ref)))
        {
#if PERL_VERSION >= 38
            /* sv_bless rejects class stashes (Perl 5.38+): set directly */
            if (SvTYPE(SvRV(ref)) == SVt_PVOBJ) {
                SV * const robj = SvRV(clone);
                HV * const stash = (HV *)SvREFCNT_inc(SvSTASH(SvRV(ref)));
                /* The referent may come from the hseen cache already
                 * blessed (same instance in several slots).  Release the
                 * stash it holds first, exactly as sv_bless does, or the
                 * stash leaks one reference per extra alias. */
                if (SvOBJECT(robj))
                    SvREFCNT_dec(SvSTASH(robj));
                SvOBJECT_on(robj);
                SvSTASH_set(robj, stash);
            } else
#endif
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
  }

  TRACEME(("clone = 0x%" UVxf "(%d)\n", PTR2UV(clone), SvREFCNT(clone)));
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
	HV *hseen;
	AV *weakrefs;
	PPCODE:
	hseen = newHV();
	weakrefs = newAV();
	/* Register for automatic cleanup on scope exit.  If sv_clone()
	 * or the weakening loop croaks, the longjmp would skip the
	 * explicit SvREFCNT_dec below — SAVEFREESV ensures both are
	 * freed during stack unwinding. */
	SAVEFREESV((SV *)hseen);
	SAVEFREESV((SV *)weakrefs);
	TRACEME(("ref = 0x%" UVxf "\n", PTR2UV(self)));
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
	/* hseen and weakrefs are freed automatically via SAVEFREESV */
	EXTEND(SP,1);
	PUSHs(sv_2mortal(clone));
