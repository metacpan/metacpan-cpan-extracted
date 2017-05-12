#ifdef WIN32 /* Win32 doesn't get PERL_CORE, so use the next best thing */
#define PERL_NO_GET_CONTEXT
#endif

/* For versions of ExtUtils::ParseXS > 3.04_02, we need to
 * explicitly enforce exporting of XSUBs since we want to
 * refer to them using XS(). This isn't strictly necessary,
 * but it's by far the simplest way to be backwards-compatible.
 */
#define PERL_EUPXS_ALWAYS_EXPORT

#include "EXTERN.h"
#include "perl.h"

/* want this eeaarly, before perl spits in the soup with XSUB.h */
#include "cxsa_memory.h"

/*
 * Quoting chocolateboy from his Method::Lexical module at 2009-02-08:
 *
 * for binary compatibility (see perlapi.h), XS modules perform a function call to
 * access each and every interpreter variable. So, for instance, an innocuous-looking
 * reference to PL_op becomes:
 *
 *     (*Perl_Iop_ptr(my_perl))
 *
 * This (obviously) impacts performance. Internally, PL_op is accessed as:
 *
 *     my_perl->Iop
 *
 * (in threaded/multiplicity builds (see intrpvar.h)), which is significantly faster.
 *
 * defining PERL_CORE gets us the fast version, at the expense of a future maintenance release
 * possibly breaking things: https://groups.google.com/group/perl.perl5.porters/browse_thread/thread/9ec0da3f02b3b5a
 *
 * Rather than globally defining PERL_CORE, which pokes its fingers into various headers, exposing
 * internals we'd rather not see, just define it for XSUB.h, which includes
 * perlapi.h, which imposes the speed limit.
 */

#ifdef WIN32 /* thanks to Andy Grundman for pointing out problems with this on ActivePerl >= 5.10 */
#include "XSUB.h"
#else /* not WIN32 */
#define PERL_CORE
#include "XSUB.h"
#undef PERL_CORE
#endif

#include "ppport.h"

#include "cxsa_main.h"
#include "cxsa_locking.h"

#define CXAA(name) XS_Class__XSAccessor__Array_ ## name
#define CXAH(name) XS_Class__XSAccessor_ ## name

#define CXA_CHECK_HASH(self)                                                            \
if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)) {                                 \
    croak("Class::XSAccessor: invalid instance method invocant: no hash ref supplied"); \
}

#define CXA_CHECK_ARRAY(self)                                                            \
if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVAV)) {                                  \
    croak("Class::XSAccessor: invalid instance method invocant: no array ref supplied"); \
}

/*
 * chocolateboy: 2009-09-06 - 2009-11-14:
 *
 * entersub OPs that call our accessors are optimized (i.e. replaced with optimized versions)
 * in versions of perl >= 5.10.0. This section describes the implementation.
 *
 * TL;DR: the first time one of our fast (XS) accessors is called, we reach up into the
 * calling OP (OP_ENTERSUB) and change its implementation (PL_op->op_ppaddr) to an optimized
 * version that takes advantage of the fact that our accessors are straightforward hash/array lookups.
 * In order for this to work safely, we need to be able to disable/prevent this optimization
 * in some circumstances. This is done by setting a "don't optimize me" flag on the entersub OP.
 * Prior to 5.10.0, there were no spare bits available on entersub OPs we could use for this, but
 * perls >= 5.10.0 have a new OP member called op_spare that gives us 3 whole bits to play with!
 *
 * First, some preliminaries: a method call is performed as a subroutine call at the OP
 * level. There's some additional work to look up the method CV and push the invocant
 * on the stack, but the current OP inside a method call is the subroutine call OP, OP_ENTERSUB.
 *
 * Two distinct invocations of the same method will have two entersub OPs and will receive
 * the same CV on the stack:
 *
 *     $foo->bar(...); # OP 1: CV 1
 *     $foo->bar(...); # OP 2: CV 1
 *
 * There are also situations in which the same entersub OP calls more than one CV:
 *
 *     $foo->$_() for ('foo', 'bar'); # OP 1: CV 1, CV 2
 *
 * Inside each Class::XSAccessor XSUB, we can access the current entersub OP (PL_op).
 * The default entersub implementation (pp_entersub in pp_hot.c) has a lot of boilerplate for
 * dealing with all the different ways in which subroutines can be called. It sets up
 * and tears down a new scope; it deals with the fact that the code ref can be passed
 * in as a GV or CV; and it has numerous conditional statements to deal with the various
 * different types of CV.
 *
 * For our XSUB accessors, we don't need most of that. We don't need to open a new scope;
 * the subroutine is almost always a CV (that's what OP_METHOD and OP_METHOD_NAMED usually return);
 * and we don't need to deal with all the non-XSUB cases. This allows us to replace the
 * OP's implementation (op_ppaddr) with a version optimized for our simple XSUBs. (This
 * is inspired by B::XSUB::Dumber: nothingmuch++)
 *
 * We do this inside the accessor i.e. at runtime. We can also back out the optimization
 * if a call site proves to be dynamic e.g. if a method is redefined or the method is
 * called with multiple different CVs (see below).
 *
 * In practice, this is rarely the case. the vast majority of method calls in perl,
 * and in most dynamic languages (cf. Google's v8), behave like method calls in static
 * languages. for instance, 97% of the call sites exercised by perl 5.10.0's test suite are
 * monomorphic.
 *
 * We only replace the op_ppaddr pointer of entersub OPs that use the default pp_entersub.
 * this ensures we don't interfere with any modules that assign a new op_ppaddr e.g.
 * Data::Alias, Faster. it also ensures we don't tread on our own toes and repeatedly
 * re-assign the same optimized entersub.
 *
 * There's one optimized entersub for each type of Class::XSAccessor accessor. To save typing,
 * they're generated by C preprocessor macros i.e. poor man's generic programming.
 *
 * If, for some reason, the entersub should not be optimized, a flag is set on the
 * entersub OP. This flag is detected inside the accessor. If the flag is set,
 * the accessor will never try to optimize the entersub OP.
 *
 * There are a number of situations in which optimization is disabled.
 *
 * 1) if the entersub is not perl's default entersub i.e. if another module has
 * provided its own entersub implementation, then we don't replace it.
 *
 * 2) if the call site is dynamic. the optimized entersub is optimized for a particular
 * type of Class::XSAccessor accessor (e.g. getter, setter, predicate &c.). if
 * an optimized entersub finds itself invoking a function other than the
 * specific XSUB it's tailored for, then the entersub optimization is disabled.
 * This also applies if a method is redefined so that an optimized
 * entersub is passed a different type of CV than the one it's optimized for.
 *
 * 1) is detected inside the accessor. 2) is detected inside the optimized entersub.
 * In the second case, we reinstate the previous entersub, which by 1) was perl's pp_entersub.
 *
 * Note: Class::XSAccessor XSUBs continue to optimize "new" call sites, regardless of what may
 * have happened to a "previous" OP or what may happen to a "subsequent" OP. Take the following
 * example:
 *
 *     1: package Example;
 *     2:
 *     3: use Class::XSAccessor { getters => 'foo' };
 *     4:
 *     5: for (1 .. 10) {
 *     6:     $self->foo();
 *     7:     $self->$_ for ('foo', 'bar');
 *     8:     $self->foo();
 *     9: }
 *
 * Here, line 6 is optimized as normal. Line 7 is optimized on the first call, when $_ is "foo",
 * but the optimization is disabled on the second call, when $_ is "bar", because &Example::bar
 * is not a Class::XSAccessor getter. All subsequent calls on line 7, use perl's default entersub.
 * Line 8 is optimized as normal. i.e. the disabled optimization on line 7 doesn't affect subsequent
 * optimizations. On line 7, only the entersub OP is "pessimized". &Example::foo continues to "look for"
 * "new" entersub OPs to optimize. Indeed, any calls to &Example::foo will get the optimization treatment,
 * even call sites outside the Example package/file.
 *
 * The following CXAA_OPTIMIZE_ENTERSUB* (Array) and CXAH_OPTIMIZE_ENTERSUB* (Hash) macros are
 * called from within our accessors to install the optimized entersub (if possible).
 * The CXAA_GENERATE_ENTERSUB* and CXAH_GENERATE_ENTERSUB* macros further down
 * generate optimized entersubs for the accessors defined in XS/Array.xs and XS/Hash.xs.
 */

#if (PERL_BCDVERSION >= 0x5010000)
#define CXA_ENABLE_ENTERSUB_OPTIMIZATION
#endif

#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION

#define CXA_OPTIMIZATION_OK(op) ((op->op_spare & 1) != 1)
#define CXA_DISABLE_OPTIMIZATION(op) (op->op_spare |= 1)

/* see t/08hash_entersub.t */
#define CXAH_OPTIMIZE_ENTERSUB_TEST(name)                                     \
STMT_START {                                                                  \
    /* print op_spare so that we get failing tests if perl starts using it */ \
    warn("cxah: accessor: op_spare: %u", PL_op->op_spare);                    \
                                                                              \
    if (PL_op->op_ppaddr == CXA_DEFAULT_ENTERSUB) {                           \
        if (CXA_OPTIMIZATION_OK(PL_op)) {                                     \
            warn("cxah: accessor: optimizing entersub");                      \
            PL_op->op_ppaddr = cxah_entersub_ ## name;                        \
        } else {                                                              \
            warn("cxah: accessor: entersub optimization has been disabled");  \
        }                                                                     \
    } else if (PL_op->op_ppaddr == cxah_entersub_ ## name) {                  \
        warn("cxah: accessor: entersub has been optimized");                  \
    }                                                                         \
} STMT_END

#define CXAH_OPTIMIZE_ENTERSUB(name)                                                \
STMT_START {                                                                        \
    if ((PL_op->op_ppaddr == CXA_DEFAULT_ENTERSUB) && CXA_OPTIMIZATION_OK(PL_op)) { \
        PL_op->op_ppaddr = cxah_entersub_ ## name;                                  \
    }                                                                               \
} STMT_END

#define CXAA_OPTIMIZE_ENTERSUB(name)                                                \
STMT_START {                                                                        \
    if ((PL_op->op_ppaddr == CXA_DEFAULT_ENTERSUB) && CXA_OPTIMIZATION_OK(PL_op)) { \
        PL_op->op_ppaddr = cxaa_entersub_ ## name;                                  \
    }                                                                               \
} STMT_END

#else /* if CXA_ENABLE_ENTERSUB_OPTIMIZATION is not defined... */

#define CXAA_GENERATE_ENTERSUB(name)
#define CXAA_OPTIMIZE_ENTERSUB(name)
#define CXAH_GENERATE_ENTERSUB(name)
#define CXAH_OPTIMIZE_ENTERSUB(name)
#define CXAH_GENERATE_ENTERSUB_TEST(name)
#define CXAH_OPTIMIZE_ENTERSUB_TEST(name)

#endif /* end #ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION */

/*
 * VMS mangles XSUB names so that they're less than 32 characters, and
 * ExtUtils::ParseXS provides no way to XS-ify XSUB names that appear
 * anywhere else but in the XSUB definition.
 *
 * The mangling is deterministic, so we can translate from every other
 * platform => VMS here
 *
 * This will probably never get used.
 */

/* FIXME: redo this to include new names */
#ifdef VMS
#define Class__XSAccessor_lvalue_accessor Class_XSAcc_lvacc
#define Class__XSAccessor_array_setter Cs_XSAcesor_ary_set
#define Class__XSAccessor_array_accessor Cs_XSAcesor_ary_accessor
#define Class__XSAccessor_chained_setter Clas_XSAcesor_chained_seter
#define Class__XSAccessor_chained_accessor Clas_XSAcesor_chained_acesor
#define Class__XSAccessor_exists_predicate Clas_XSAcesor_eprdicate
#define Class__XSAccessor_defined_predicate Clas_XSAcesor_dprdicate
#define Class__XSAccessor_constructor Class_XSAccessor_constructor
#define Class__XSAccessor_constant_false Clas_XSAcesor_constant_false
#define Class__XSAccessor_constant_true Clas_XSAcesor_constant_true
#define Class__XSAccessor__Array_getter Clas_XSAcesor_Aray_geter
#define Class__XSAccessor__Array_lvalue_accessor Class_XSAcc_Ay_lvacc
#define Class__XSAccessor__Array_setter Clas_XSAcesor_Aray_seter
#define Class__XSAccessor__Array_chained_setter Cs_XSAs_Ay_cid_seter
#define Class__XSAccessor__Array_accessor Clas_XSAcesor_Aray_acesor
#define Class__XSAccessor__Array_chained_accessor Cs_XSAs_Ay_cid_acesor
#define Class__XSAccessor__Array_predicate Clas_XSAcesor_Aray_predicate
#define Class__XSAccessor__Array_constructor Cs_XSAs_Ay_constructor
#endif

#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION
#define CXAH_GENERATE_ENTERSUB_TEST(name)                                        \
OP * cxah_entersub_ ## name(pTHX) {                                              \
    dVAR; dSP; dTOPss;                                                           \
    warn("cxah: entersub: inside optimized entersub");                           \
                                                                                 \
    if (sv                                                                       \
        && (SvTYPE(sv) == SVt_PVCV)                                              \
        && (CvXSUB((CV *)sv) == CXAH(name))                                      \
    ) {                                                                          \
        (void)POPs;                                                              \
        PUTBACK;                                                                 \
        (void)CXAH(name)(aTHX_ (CV *)sv);                                        \
        return NORMAL;                                                           \
    } else { /* not static: disable optimization */                              \
        if (!sv) {                                                               \
            warn("cxah: entersub: disabling optimization: SV is null");          \
        } else if (SvTYPE(sv) != SVt_PVCV) {                                     \
            warn("cxah: entersub: disabling optimization: SV is not a CV");      \
        } else {                                                                 \
            warn("cxah: entersub: disabling optimization: SV is not " # name);   \
        }                                                                        \
        CXA_DISABLE_OPTIMIZATION(PL_op); /* make sure it's not reinstated */     \
        PL_op->op_ppaddr = CXA_DEFAULT_ENTERSUB;                                 \
        return CXA_DEFAULT_ENTERSUB(aTHX);                                       \
    }                                                                            \
}

#define CXAH_GENERATE_ENTERSUB(name)                                                    \
OP * cxah_entersub_ ## name(pTHX) {                                                     \
    dVAR; dSP; dTOPss;                                                                  \
                                                                                        \
    if (sv                                                                              \
        && (SvTYPE(sv) == SVt_PVCV)                                                     \
        && (CvXSUB((CV *)sv) == CXAH(name))                                             \
    ) {                                                                                 \
        (void)POPs;                                                                     \
        PUTBACK;                                                                        \
        (void)CXAH(name)(aTHX_ (CV *)sv);                                               \
        return NORMAL;                                                                  \
    } else { /* not static: disable optimization */                                     \
        CXA_DISABLE_OPTIMIZATION(PL_op); /* make sure it's not reinstated */            \
        PL_op->op_ppaddr = CXA_DEFAULT_ENTERSUB;                                        \
        return CXA_DEFAULT_ENTERSUB(aTHX);                                              \
    }                                                                                   \
}

#define CXAA_GENERATE_ENTERSUB(name)                                                    \
OP * cxaa_entersub_ ## name(pTHX) {                                                     \
    dVAR; dSP; dTOPss;                                                                  \
                                                                                        \
    if (sv                                                                              \
        && (SvTYPE(sv) == SVt_PVCV)                                                     \
        && (CvXSUB((CV *)sv) == CXAA(name))                                             \
    ) {                                                                                 \
        (void)POPs;                                                                     \
        PUTBACK;                                                                        \
        (void)CXAA(name)(aTHX_ (CV *)sv);                                               \
        return NORMAL;                                                                  \
    } else { /* not static: disable optimization */                                     \
        CXA_DISABLE_OPTIMIZATION(PL_op); /* make sure it's not reinstated */            \
        PL_op->op_ppaddr = CXA_DEFAULT_ENTERSUB;                                        \
        return CXA_DEFAULT_ENTERSUB(aTHX);                                              \
    }                                                                                   \
}
#endif /* CXA_ENABLE_ENTERSUB_OPTIMIZATION */

/* Install a new XSUB under 'name' and automatically set the file name */
#define INSTALL_NEW_CV(name, xsub)                                            \
STMT_START {                                                                  \
  if (newXS(name, xsub, (char*)__FILE__) == NULL)                             \
    croak("ARG! Something went really wrong while installing a new XSUB!");   \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * Requires a previous declaration of a CV* cv!
 * TODO: Once the array case has been migrated to storing pointers instead
 *       of indexes, this macro can probably go away.
 **/
#define INSTALL_NEW_CV_WITH_INDEX(name, xsub, function_index)               \
STMT_START {                                                                \
  cv = newXS(name, xsub, (char*)__FILE__);                                  \
  if (cv == NULL)                                                           \
    croak("ARG! Something went really wrong while installing a new XSUB!"); \
  XSANY.any_i32 = function_index;                                           \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_WITH_PTR(name, xsub, user_pointer)                   \
STMT_START {                                                                \
  cv = newXS(name, xsub, (char*)__FILE__);                                  \
  if (cv == NULL)                                                           \
    croak("ARG! Something went really wrong while installing a new XSUB!"); \
  XSANY.any_ptr = (void *)user_pointer;                                     \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * for array-based objects. Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_ARRAY_OBJ(name, xsub, obj_array_index)                \
STMT_START {                                                                 \
  const U32 function_index = get_internal_array_index((I32)obj_array_index); \
  INSTALL_NEW_CV_WITH_INDEX(name, xsub, function_index);                     \
  CXSAccessor_arrayindices[function_index] = obj_array_index;                \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * for hash-based objects. Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_HASH_OBJ(name, xsub, obj_hash_key, obj_hash_key_len)  \
STMT_START {                                                                 \
  autoxs_hashkey *hk_ptr = get_hashkey(aTHX_ obj_hash_key, obj_hash_key_len);\
  INSTALL_NEW_CV_WITH_PTR(name, xsub, hk_ptr);                               \
  hk_ptr->key = (char*)cxa_malloc(obj_hash_key_len+1);                       \
  cxa_memcpy(hk_ptr->key, obj_hash_key, obj_hash_key_len);                   \
  hk_ptr->key[obj_hash_key_len] = 0;                                         \
  hk_ptr->len = obj_hash_key_len;                                            \
  PERL_HASH(hk_ptr->hash, obj_hash_key, obj_hash_key_len);                   \
} STMT_END

#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION
static Perl_ppaddr_t CXA_DEFAULT_ENTERSUB = NULL;

/* predeclare the XSUBs so we can refer to them in the optimized entersubs */

XS(CXAH(getter));
CXAH_GENERATE_ENTERSUB(getter);

XS(CXAH(lvalue_accessor));
CXAH_GENERATE_ENTERSUB(lvalue_accessor);

XS(CXAH(setter));
CXAH_GENERATE_ENTERSUB(setter);

/* for the Class::Accessor compatibility layer only! */
XS(CXAH(array_setter));
CXAH_GENERATE_ENTERSUB(array_setter);

XS(CXAH(chained_setter));
CXAH_GENERATE_ENTERSUB(chained_setter);

XS(CXAH(accessor));
CXAH_GENERATE_ENTERSUB(accessor);

/* for the Class::Accessor compatibility layer only! */
XS(CXAH(array_accessor));
CXAH_GENERATE_ENTERSUB(array_accessor);

XS(CXAH(chained_accessor));
CXAH_GENERATE_ENTERSUB(chained_accessor);

XS(CXAH(defined_predicate));
CXAH_GENERATE_ENTERSUB(defined_predicate);

XS(CXAH(exists_predicate));
CXAH_GENERATE_ENTERSUB(exists_predicate);

XS(CXAH(constructor));
CXAH_GENERATE_ENTERSUB(constructor);

XS(CXAH(constant_false));
CXAH_GENERATE_ENTERSUB(constant_false);

XS(CXAH(constant_true));
CXAH_GENERATE_ENTERSUB(constant_true);

XS(CXAH(test));
CXAH_GENERATE_ENTERSUB_TEST(test);

XS(CXAA(getter));
CXAA_GENERATE_ENTERSUB(getter);

XS(CXAA(lvalue_accessor));
CXAA_GENERATE_ENTERSUB(lvalue_accessor);

XS(CXAA(setter));
CXAA_GENERATE_ENTERSUB(setter);

XS(CXAA(chained_setter));
CXAA_GENERATE_ENTERSUB(chained_setter);

XS(CXAA(accessor));
CXAA_GENERATE_ENTERSUB(accessor);

XS(CXAA(chained_accessor));
CXAA_GENERATE_ENTERSUB(chained_accessor);

XS(CXAA(predicate));
CXAA_GENERATE_ENTERSUB(predicate);

XS(CXAA(constructor));
CXAA_GENERATE_ENTERSUB(constructor);

#endif /* CXA_ENABLE_ENTERSUB_OPTIMIZATION */

/* magic vtable and setter function for lvalue accessors */
STATIC int
setter_for_lvalues(pTHX_ SV *sv, MAGIC* mg);

STATIC int
setter_for_lvalues(pTHX_ SV *sv, MAGIC* mg)
{
  PERL_UNUSED_VAR(mg);
  sv_setsv(LvTARG(sv), sv);
  return TRUE;
}

STATIC MGVTBL cxsa_lvalue_acc_magic_vtable = {
     0                               /* get   */
    ,setter_for_lvalues              /* set   */
    ,0                               /* len   */
    ,0                               /* clear */
    ,0                               /* free  */
#if (PERL_BCDVERSION >= 0x5008000)
    ,0                               /* copy  */
    ,0                               /* dup   */
#if (PERL_BCDVERSION >= 0x5008009)
    ,0                               /* local */
#endif /* perl >= 5.8.0 */
#endif /* perl >= 5.8.9 */
};

MODULE = Class::XSAccessor        PACKAGE = Class::XSAccessor
PROTOTYPES: DISABLE

BOOT:
#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION
CXA_DEFAULT_ENTERSUB = PL_ppaddr[OP_ENTERSUB];
#endif
#ifdef USE_ITHREADS
_init_cxsa_lock(&CXSAccessor_lock); /* cf. CXSAccessor.h */
#endif /* USE_ITHREADS */
/*
 * testing the hashtable implementation...
 */
/*
{
  HashTable* tb = CXSA_HashTable_new(16, 0.9);
  CXSA_HashTable_store(tb, "test", 4, 12);
  CXSA_HashTable_store(tb, "test5", 5, 199);
  warn("12==%u\n", CXSA_HashTable_fetch(tb, "test", 4));
  warn("199==%u\n", CXSA_HashTable_fetch(tb, "test5", 5));
  warn("0==%u\n", CXSA_HashTable_fetch(tb, "test123", 7));
}
*/

void
END()
    PROTOTYPE:
    CODE:
        if (CXSAccessor_reverse_hashkeys) {
            /* This can run before Perl is done, so accessors might still be called,
             * so we can't free our memory here. Solution? Special global destruction
             * phase *AFTER* all Perl END() subs were run? */

            /*CXSA_HashTable_free(CXSAccessor_reverse_hashkeys, true);*/
        }

void
__entersub_optimized__()
    PROTOTYPE:
    CODE:
#ifdef CXA_ENABLE_ENTERSUB_OPTIMIZATION
        XSRETURN(1);
#else
        XSRETURN(0);
#endif

INCLUDE: XS/Hash.xs

INCLUDE: XS/HashCACompat.xs

INCLUDE: XS/Array.xs
