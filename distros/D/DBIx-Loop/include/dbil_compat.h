#ifndef DBIL_COMPAT_H
#define DBIL_COMPAT_H

/* Perl-version portability shims for the C core, so DBIx::Loop builds on every
 * perl it claims (5.8.3+). Include after EXTERN.h / perl.h / XSUB.h and before
 * any other dbil_ header, so the definitions are in scope everywhere below.
 *
 * Each shim is the standard definition of the thing it stands in for; on a
 * perl new enough to have the real one, none of this is compiled. */

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in perl's XSUB.h at 5.16.
 * The C-closure callbacks (dbil_pool.h's reader and worker callbacks,
 * dbil_txn.h, dbil_future.h) are declared XS_INTERNAL, so without these the
 * build fails with "XS_INTERNAL undeclared" and then "cv undeclared" for every
 * one of them. */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* mg_findext (5.14) and croak_sv (5.13.1). dbil_pool.h uses mg_findext to
 * reach the magic carrying a C closure's captures; the future settle path
 * croak_sv's an error SV it was handed rather than flattening it to a string. */
#if PERL_REVISION == 5 && PERL_VERSION < 14

static MAGIC *DBIL_mg_findext(SV *sv, int type, const MGVTBL *vtbl) {
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == type && (const MGVTBL *)mg->mg_virtual == vtbl)
                return mg;
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) DBIL_mg_findext((sv), (type), (vtbl))

/* SVfARG is itself only 5.10, and without it the croak_sv shim below compiles
 * to an implicit call and the .so fails to load with "undefined symbol". This
 * is ppport.h's definition. */
#  ifndef SVfARG
#    define SVfARG(p) ((void *)(p))
#  endif
#  define croak_sv(sv) Perl_croak(aTHX_ "%" SVf, SVfARG(sv))

#endif

#endif /* DBIL_COMPAT_H */
