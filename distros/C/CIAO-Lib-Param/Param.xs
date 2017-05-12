/* --8<--8<--8<--8<--
 *
 * Copyright (C) 2006 Smithsonian Astrophysical Observatory
 *
 * This file is part of CIAO-Lib-Param
 *
 * CIAO-Lib-Param is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * CIAO-Lib-Param is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the 
 *       Free Software Foundation, Inc. 
 *       51 Franklin Street, Fifth Floor
 *       Boston, MA  02110-1301, USA
 *
 * -->8-->8-->8-->8-- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Global Data */

#define MY_CXT_KEY "CIAO::Lib::Param::_guts" XS_VERSION

typedef struct {
  int parerr;
  int level;
  char* errmsg;
} my_cxt_t;

START_MY_CXT



#include "ppport.h"

#ifdef FLAT_INCLUDES
#include <parameter.h>
#else
#include <cxcparam/parameter.h>
#endif

/* yes, this is gross, but it beats including pfile.h */
extern int parerr;

/* no choice here; these aren't prototyped anywhere from pfile.c */
typedef void (*vector)();
vector paramerract( void (*newact)() );

/* this is definitely overkill, as this could (and was) handled
   transparently by the XS typemap code. At one point it
   was thought that per-object data was required and the code
   was converted to use this structure as the basis for the
   object, rather than simply blessing the pointer to the paramfile
   structure 
*/
typedef struct PFile
{
  paramfile *pf;
} PFile;

/* needed for typemap magic */
typedef PFile*  CIAO_Lib_ParamPtr;
typedef pmatchlist CIAO_Lib_Param_MatchPtr;

/* use Perl to get temporary space in interface routines; it'll
   get garbage collected automatically */
static void *
get_mortalspace( int nbytes )
{
  SV  *mortal = sv_2mortal( NEWSV(0, nbytes ) );
  char *ptr = SvPVX( mortal );

  /* set the extra NULL byte that Perl gives us to NULL
     to allow easy string overflow checking */
  ptr[nbytes] = '\0';

  return ptr;
}


static SV*
carp_shortmess( char* message )
{
  SV* sv_message = newSVpv( message, 0 );
  SV* short_message;
  int count;

  dSP;
  ENTER ;
  SAVETMPS ;
    
  PUSHMARK(SP);
  XPUSHs( sv_message );
  PUTBACK;

  /* make sure there's something to work with */
  count = call_pv( "Carp::shortmess", G_SCALAR );
    
  SPAGAIN ;

  if ( 1 != count )
    croak( "internal error passing message to Carp::shortmess" );

  short_message = newSVsv( POPs );

  PUTBACK ;
  FREETMPS ;
  LEAVE ;

  return short_message;
}


/* propagate the cxcparam error value up to Perl.
   this is used to cause a croak at the Perl level (see Param.pm for
*/
static void
croak_on_parerr( void )
{
  dMY_CXT;

  SV *sv;

  /* use parerr if specified; else use MY_CXT.parerr.  The latter is
     available if c_paramerr was called. some cxcparam routines
     don't call c_paramerr.  for those that don't, all errors are fatal
  */

  if ( parerr )
  {
    MY_CXT.parerr = parerr;
    MY_CXT.level = 1;
  }

  /* only non-zero levels are fatal */
  if ( MY_CXT.parerr && MY_CXT.level)
  {
    SV* sv_error;
    HV* hash = newHV();
    char *errstr = paramerrstr();
    char *error = MY_CXT.errmsg ? MY_CXT.errmsg : errstr;


    /* construct exception object prior to throwing exception */

    hv_store( hash, "errno" , 5, newSViv(MY_CXT.parerr), 0 );
    hv_store( hash, "error" , 5, carp_shortmess(error), 0 );
    hv_store( hash, "errstr", 6, newSVpv(errstr, 0), 0 );
    hv_store( hash, "errmsg", 6, MY_CXT.errmsg ? newSVpv(MY_CXT.errmsg, 0) : &PL_sv_undef, 0 );

    /* reset internal parameter error */
    parerr = MY_CXT.parerr = 0;
    Safefree( MY_CXT.errmsg );
    MY_CXT.errmsg = NULL;
    
    /* setup exception object and throw it*/
    {
      SV* errsv = get_sv("@", TRUE);
      sv_setsv( errsv, sv_bless( newRV_noinc((SV*) hash),
				 gv_stashpv("CIAO::Lib::Param::Error", 1 ) ) );
    }
    croak( Nullch );

  }
  
  /* here if level == 0 */
  if ( MY_CXT.parerr )
  {
    parerr = MY_CXT.parerr = 0;
    Safefree( MY_CXT.errmsg );
    MY_CXT.errmsg = NULL;
    MY_CXT.level = 0;
  }

}

/* The replacement error message handling routine for cxcparam.
   This is put in place in the BOOT: section
   Note that both paramerrstr() and c_paramerr reset parerr,
   so we need to keep a local copy.
*/
static void
perl_paramerr( int level, char *message, char *name )
{
  dMY_CXT;
  SV* sv;
  char *errstr;
  int len;

  /* save parerr before call to paramerrstr(), as that will
     reset it */
  MY_CXT.parerr = parerr;
  errstr = paramerrstr();

  len = strlen(errstr) + strlen(message) + strlen(name) + 5;

  if ( MY_CXT.errmsg )
    Renew( MY_CXT.errmsg, len, char );
  else
    New( 0, MY_CXT.errmsg, len, char );

  MY_CXT.level = level;
  sprintf( MY_CXT.errmsg, "%s: %s: %s", message, errstr, name );

  /* a level of 0 is non-fatal.  however, it should be passed up to
     the caller to handle, and that's not yet implemented. currently
     cxcparam only issues a level 0 message prior to prompting for 
     a replacement value of a parameter, and since that always
     goes out to the terminal, we output level 0 messages to
     stderr and reset parerr so that they are not treated
     as errors in croak_on_parerr */

  if ( 0 == level )
  {
    fprintf( stderr, "%s\n", MY_CXT.errmsg );
    MY_CXT.parerr = parerr = 0;
  }

}


MODULE = CIAO::Lib::Param::Match	PACKAGE = CIAO::Lib::Param::Match	PREFIX = pmatch

void
DESTROY(mlist)
	CIAO_Lib_Param_MatchPtr	mlist
  CODE:
	pmatchclose(mlist);

MODULE = CIAO::Lib::Param::Match	PACKAGE = CIAO::Lib::Param::MatchPtr	PREFIX = pmatch

int
pmatchlength(mlist)
	CIAO_Lib_Param_MatchPtr	mlist

char *
pmatchnext(mlist)
	CIAO_Lib_Param_MatchPtr	mlist


void
pmatchrewind(mlist)
	CIAO_Lib_Param_MatchPtr	mlist


MODULE = CIAO::Lib::Param		PACKAGE = CIAO::Lib::Param

BOOT:
{
  	MY_CXT_INIT;
	MY_CXT.parerr = 0;
	MY_CXT.level  = 0;
	MY_CXT.errmsg = NULL;
	set_paramerror(0);	/* Don't exit on error */
	paramerract((vector) perl_paramerr);
}

CIAO_Lib_ParamPtr
open(filename, mode, ...)
	char *	filename
	const char *	mode
  PREINIT:
	int argc = 0;
  	char **argv = NULL;
  CODE:
        argc = items - 2;
	if ( argc )
	{
	  int i;
	  argv = get_mortalspace( argc * sizeof(*argv) );
	  for ( i = 2 ; i < items ; i++ )
	  {
	    argv[i-2] = SvOK(ST(i)) ? (char*)SvPV_nolen(ST(i)) : (char*)NULL;
	  }
	}
	RETVAL = New( 0, RETVAL, 1, PFile );
	RETVAL->pf = paramopen(filename, argv, argc, mode);
	if ( NULL == RETVAL->pf )
	{
	  Safefree(RETVAL);
	  RETVAL = NULL;
	  croak_on_parerr();
	}
  OUTPUT:
  	RETVAL

char *
pfind(name, mode, extn, path)
	char *	name
	char *	mode
	char *	extn
	char *	path
  CODE:
	RETVAL = paramfind( name, mode, extn, path );
  	croak_on_parerr();	
  OUTPUT:
	RETVAL

MODULE = CIAO::Lib::Param	PACKAGE = CIAO::Lib::ParamPtr

void
DESTROY(pfile)
	CIAO_Lib_ParamPtr	pfile
  CODE:
	if ( pfile->pf )
	  paramclose(pfile->pf);
	Safefree(pfile);
  	croak_on_parerr();	
 	
void
info( pfile, name )
	CIAO_Lib_ParamPtr	pfile
	char * name
  PREINIT:
	char *	mode = get_mortalspace( SZ_PFLINE );
	char *	type = get_mortalspace( SZ_PFLINE );
	char *	value = get_mortalspace( SZ_PFLINE );
	char *	min = get_mortalspace( SZ_PFLINE );
	char *	max = get_mortalspace( SZ_PFLINE );
	char *	prompt = get_mortalspace( SZ_PFLINE );
	int result;
  PPCODE:
	if ( ParamInfo( pfile->pf, name, mode, type, 
			    value, min, max, prompt ) )
	{
	  EXTEND(SP, 6);
	  PUSHs(sv_2mortal(newSVpv(mode, 0)));
	  PUSHs(sv_2mortal(newSVpv(type, 0)));
	  PUSHs(sv_2mortal(newSVpv(value, 0)));
	  PUSHs(sv_2mortal(newSVpv(min, 0)));
	  PUSHs(sv_2mortal(newSVpv(max, 0)));
	  PUSHs(sv_2mortal(newSVpv(prompt, 0)));
	}
	else
	{
	  croak( "parameter %s doesn't exist", name );
	}
  	croak_on_parerr();	


CIAO_Lib_Param_MatchPtr
match(pfile, ptemplate)
	CIAO_Lib_ParamPtr	pfile
	char *	ptemplate
  CODE:
	RETVAL = pmatchopen( pfile->pf, ptemplate );
  	croak_on_parerr();	
  OUTPUT:
  	RETVAL



MODULE = CIAO::Lib::Param	PACKAGE = CIAO::Lib::ParamPtr	PREFIX = param


char *
paramgetpath(pfile)
	CIAO_Lib_ParamPtr	pfile
  CODE:
	paramgetpath( pfile->pf );
  CLEANUP:
	if (RETVAL) Safefree(RETVAL);
	croak_on_parerr();


MODULE = CIAO::Lib::Param PACKAGE = CIAO::Lib::ParamPtr	PREFIX = p

int
paccess(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  CODE:
	paccess( pfile->pf, pname );
  CLEANUP:
  	croak_on_parerr();	

SV*
pgetb(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  CODE:
  	ST(0) = sv_newmortal();
	sv_setsv( ST(0), pgetb( pfile->pf, pname ) ? &PL_sv_yes : &PL_sv_no );
  	croak_on_parerr();	

short
pgets(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  CODE:
	RETVAL = pgets( pfile->pf, pname );
  	croak_on_parerr();	
  OUTPUT:
  	RETVAL

int
pgeti(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  CODE:
	RETVAL = pgeti( pfile->pf, pname );
  	croak_on_parerr();	
  OUTPUT:
  	RETVAL

float
pgetf(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  CODE:
	RETVAL = pgetf( pfile->pf, pname );
  	croak_on_parerr();	
  OUTPUT:
  	RETVAL

double
pgetd(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  CODE:
	RETVAL = pgetd( pfile->pf, pname );
  	croak_on_parerr();	
  OUTPUT:
  	RETVAL

SV*
get(pfile, pname)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  PREINIT:
	char type[SZ_PFLINE];
  CODE:
  	ST(0) = sv_newmortal();
	if ( ParamInfo( pfile->pf, pname, NULL, type, NULL, NULL, NULL, NULL ))
	{
	  if ( 0 == strcmp( "b", type ) )
	  {
	    sv_setsv( ST(0), 
		      pgetb( pfile->pf, pname ) ? &PL_sv_yes : &PL_sv_no );
	  }
	  else
	  {
	    char *str;
	    size_t buflen = 0;
	    size_t len = 0;
	    while( len == buflen )
	    {	    
	      buflen += SZ_PFLINE;
	      str = get_mortalspace( buflen );
	      pgetstr( pfile->pf, pname, str, buflen );
	      len = strlen( str );
	    }
	    sv_setpv(ST(0), str);
	  }
	}
	else
	  XSRETURN_UNDEF;
  CLEANUP:
  	croak_on_parerr();	


char *
pgetstr(pfile, pname )
	CIAO_Lib_ParamPtr	pfile
	char *	pname
  PREINIT:
	char* str;
	size_t buflen = 0;
	size_t len = 0;
  CODE:
	RETVAL = NULL;
	while( len == buflen )
	{	    
	   buflen += SZ_PFLINE;
	   str = get_mortalspace( buflen );
	   pgetstr( pfile->pf, pname, str, buflen );
	   len = strlen( str );
	 }
        RETVAL = str;
  	croak_on_parerr();	
  OUTPUT:
	RETVAL

void
pputb(pfile, pname, value)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
	int	value
  ALIAS:
	setb = 1	
  CODE:
	pputb( pfile->pf, pname, value );
  	croak_on_parerr();	
	

void
pputd(pfile, pname, value)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
	double	value
  ALIAS:
	setd = 1	
  CODE:
	pputd( pfile->pf, pname, value );
  	croak_on_parerr();	

void
pputi(pfile, pname, value)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
	int	value
  ALIAS:
	seti = 1	
  CODE:
	pputi( pfile->pf, pname, value );
  	croak_on_parerr();	

void
pputs(pfile, pname, value)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
	short	value
  ALIAS:
	sets = 1	
  CODE:
	pputs( pfile->pf, pname, value );
  	croak_on_parerr();	

void
pputstr(pfile, pname, value)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
	char *	value
  ALIAS:
	setstr = 1
  CODE:
	pputstr( pfile->pf, pname, value );
  	croak_on_parerr();	

void
put(pfile, pname, value)
	CIAO_Lib_ParamPtr	pfile
	char *	pname
	SV*	value
  ALIAS:
	set = 1
  PREINIT:
	char type[SZ_PFLINE];
  CODE:
        /* if the parameter exists and is a boolean,
	   translate from numerics to string if it looks like a
	   number, else let pset handle it
	*/
	if ( ParamInfo( pfile->pf, pname, NULL, type, NULL, NULL, NULL, NULL ) &&
	     0 == strcmp( "b", type ) &&
	     ( looks_like_number( value ) ||
	       0 == sv_len(value )
	       ) 
	   )
	{
	  pputb(pfile->pf, pname, SvTRUE(value) );
	}
	else
	{
	  pputstr(pfile->pf, pname, SvOK(value) ? (char*)SvPV_nolen(value) : (char*)NULL );
	}
  CLEANUP:
  	croak_on_parerr();	


char *
evaluateIndir(pfile, name, val)
	CIAO_Lib_ParamPtr	pfile
	char *	name
	char *	val
  CODE:
	RETVAL = evaluateIndir(pfile->pf, name, val);
  CLEANUP:
  	if ( RETVAL ) Safefree( RETVAL );
  	croak_on_parerr();	


