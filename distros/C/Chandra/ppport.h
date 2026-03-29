/* Minimal ppport.h for this prototype */
/* Run: perl -MDevel::PPPort -e 'Devel::PPPort::WriteFile()' for full version */

#ifndef PPPORT_H
#define PPPORT_H

#ifndef PERL_REVISION
#  if !defined(__PATCHLEVEL_H_INCLUDED__) && !(defined(PATCHLEVEL) && defined(SUBVERSION))
#    define PERL_PATCHLEVEL_H_IMPLICIT
#    include <patchlevel.h>
#  endif
#  if !(defined(PERL_VERSION) || (defined(SUBVERSION) && defined(PATCHLEVEL)))
#    include <could_not_find_Perl_patchlevel.h>
#  endif
#  ifndef PERL_REVISION
#    define PERL_REVISION       (5)
#    define PERL_VERSION        PATCHLEVEL
#    define PERL_SUBVERSION     SUBVERSION
#  endif
#endif

#ifndef dTHX
#  define dTHX
#endif

#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(x) ((void)x)
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif

#ifndef NOOP
#  define NOOP          /*EMPTY*/(void)0
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

#ifndef SvPV_nolen
#  define SvPV_nolen(sv) SvPV(sv, PL_na)
#endif

#endif /* PPPORT_H */
