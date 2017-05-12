/*
** Damn.xs
**
** Define the damn() method of Acme::Damn.
**
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* for Perl > 5.6, additional magic must be handled */
#if ( PERL_REVISION == 5 ) && ( PERL_VERSION > 6 )
/* if there's magic set - Perl extension magic - then unset it */
# define SvUNMAGIC( sv )  if ( SvSMAGICAL( sv ) )                     \
                            if (    mg_find( sv , PERL_MAGIC_ext  )   \
                                 || mg_find( sv , PERL_MAGIC_uvar ) ) \
                                    mg_clear( sv )

#else

/* for Perl <= 5.6 this becomes a no-op */
# define SvUNMAGIC( sv )

#endif

/* ensure SvPV_const is declared */
#ifndef SvPV_const
# define  SvPV_const(s,l) ((const char *)SvPV(s,l))
#endif


/* handle the evolution of Perl_warner and Perl_ck_warner */
#ifdef packWARN
# ifdef ckWARN
#  define WARNER(t,s)   if (ckWARN(t)) { Perl_warner( aTHX_ packWARN(t) , s ); }
# else
#  define WARNER(t,s)   Perl_ck_warner( aTHX_ packWARN(t) , s )
# endif
#else
# define  WARNER(t,s)   if (ckWARN(t)) { Perl_warner( aTHX_ t , s ); }
#endif

static SV *
__damn( rv )
  SV * rv;
{
  /* need to dereference the RV to get the SV */
  SV  *sv = SvRV( rv );

  /*
  ** if this is read-only, then we should do the right thing and slap
  ** the programmer's wrist; who know's what might happen otherwise
  */
  if ( SvREADONLY( sv ) )
    /*
    ** use "%s" rather than just PL_no_modify to satisfy gcc's -Wformat
    **   see https://rt.cpan.org/Ticket/Display.html?id=45778
    */
    croak( "%s" , PL_no_modify );

  SvREFCNT_dec( SvSTASH( sv ) );  /* remove the reference to the stash */
  SvSTASH( sv ) = NULL;
  SvOBJECT_off( sv );             /* unset the object flag */
#if PERL_VERSION < 18
  if ( SvTYPE( sv ) != SVt_PVIO ) /* if we don't have an IO stream, we */
    PL_sv_objcount--;             /* should decrement the object count */
#endif

  /* we need to clear the magic flag on the given RV */
  SvAMAGIC_off( rv );
  /* as of Perl 5.8.0 we need to clear more magic */
  SvUNMAGIC( sv );

  return  rv;
} /* __damn() */


MODULE = Acme::Damn   PACKAGE = Acme::Damn    

PROTOTYPES: ENABLE

SV *
damn( rv , ... )
    SV * rv;

  PROTOTYPE: $;$$$

  PREINIT:
    SV    * sv;

  CODE:
    /* if we don't have a blessed reference, then raise an error */
    if ( ! sv_isobject( rv ) ) {
      /*
      ** if we have more than one parameter, then pull the name from
      ** the stack ... otherwise, use the method[] array
      */
      if ( items > 1 ) {
        char  *name  = (char *)SvPV_nolen( ST(1) );
        char  *file  = (char *)SvPV_nolen( ST(2) );
        int    line  = (int)SvIV( ST(3) );

        croak( "Expected blessed reference; can only %s the programmer "
               "now at %s line %d.\n" , name , file , line );
      } else {
        croak( "Expected blessed reference; can only damn the programmer now" );
      }
    }

    rv  = __damn( rv );

  OUTPUT:
    rv


SV *
bless( rv , ... )
  SV * rv;

  PROTOTYPE: $;$

  CODE:
    /*
    ** how many arguments do we have?
    **    - if we have two arguments, with the second being 'undef'
    **      then we call damn()
    **    - otherwise, we default to CORE::bless()
    */
    if ( items == 2 && ! SvOK( ST(1) ) )
      rv  = __damn(rv);
    else {
      HV          *stash;
      STRLEN       len;
      const char  *ptr;
      SV          *sv;

      /* have we been called as a two-argument bless? */
      if ( items == 2 ) {
        /*
        ** here we replicate Perl_pp_bless()
        **    - see pp.c
        */

        /* ensure we have a package name, not a reference as argument #2 */
        sv    = ST(1);
        if ( ! SvGMAGICAL( sv ) && ! SvAMAGIC( sv ) && SvROK( sv ) )
          croak( "Attempt to bless into a reference" );

        /* extract the name of the target package */
        ptr   = SvPV_const( sv , len );
        if ( len == 0 )
          WARNER(WARN_MISC, "Explicit blessing to '' (assuming package main)");

        /* extract the named stash (creating it if needed) */
        stash = gv_stashpvn( ptr , len , GV_ADD | SvUTF8(sv) );
      } else {

        /* if no package name as been given, then use the current package */
        stash = CopSTASH( PL_curcop );
      }

      /* bless the target reference */
      (void)sv_bless( rv , stash );
    }

  OUTPUT:
    rv
