#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef CIAO
#include <dmstack.h>
#else
#include <stklib/stack.h>
#endif

typedef Stack CIAO_Lib_StackIO;


MODULE = CIAO::Lib::StackIO	PACKAGE = CIAO::Lib::StackIO::Private

# don't really want the user to see these. eventually new() will
# be in here and these can go away

CIAO_Lib_StackIO *
stk_build(list)
	char *	list

CIAO_Lib_StackIO *
stk_build_gen(list)
	char *	list


CIAO_Lib_StackIO *
stk_expand_n(list, int_suf_num)
	char *	list
	long	int_suf_num


 ###########################################################################
 ###########################################################################

# these are actual class methods. where possible, use the library directly

MODULE = CIAO::Lib::StackIO	PACKAGE = CIAO::Lib::StackIOPtr PREFIX = stk_

###########################################################################

int
append(stack, descriptor, ...)
	CIAO_Lib_StackIO *	stack
	char *	descriptor
   PREINIT:
	int prepend = 0;
   CODE:
  	if ( items > 2 )
    	  prepend = SvIV(ST(2));
	  RETVAL = prepend ? 
			   stk_append( stack, descriptor ) :
			   stk_append_gen( stack, descriptor ) ;
   OUTPUT:
	RETVAL  			   

###########################################################################

int
change(stack, descriptor, ...)
	CIAO_Lib_StackIO *	stack
	char *	descriptor
    PREINIT:
	int idx;
    CODE:
        if ( items > 2 )
        {
	  idx = SvIV(ST(2));
          if ( idx == -1 ) 
	     idx = stk_count( stack );
	  stk_change_num( stack, descriptor, idx );
        }
	else
        {
	  RETVAL = stk_change_current( stack, descriptor );
	}
    OUTPUT:
	RETVAL

###########################################################################

int
stk_count(stack)
	CIAO_Lib_StackIO *	stack

###########################################################################

int
current(stack, ... )
	CIAO_Lib_StackIO *	stack
   PREINIT:
	int idx;	
   CODE:
        RETVAL = stk_current( stack );
	if ( items > 1 )
	{
	  idx = SvIV(ST(1));
	  if (  0 == idx ) 
	    stk_rewind( stack );
          else
	  {
            if ( -1 == idx ) 
	       idx = stk_count( stack );
	    stk_set_current( stack, idx );
	  }
	}
   OUTPUT:
	RETVAL

###########################################################################

int
delete(stack, ... )
	CIAO_Lib_StackIO *	stack
   PREINIT:
	int idx;	
   CODE:
	if ( items > 1 )
	{
	  idx = SvIV(ST(1));
          if ( idx == -1 ) 
	     idx = stk_count( stack );
	  /* make up for bug in stk_delete_num which doesn't 
	     handle error checking */
	  RETVAL = idx < 0 ? -1 : stk_delete_num( stack, idx );
	}
	else
	{
	   RETVAL = stk_delete_current( stack );
	}
   OUTPUT:
	RETVAL

###########################################################################

void
DESTROY(stack)
	CIAO_Lib_StackIO *	stack
  CODE:
	stk_close( stack );

###########################################################################

void
stk_disp(stack)
	CIAO_Lib_StackIO *	stack

###########################################################################

SV *
read(stack, ...)
	CIAO_Lib_StackIO *	stack
  PREINIT:
	int idx;
	char *retval;
  PPCODE:
        /* no particular entry requested */
	if ( items == 1 )
	{
	  /* 
	     scalar context: return the next entry 
	  */
	  if ( GIMME_V == G_SCALAR )
          {
	    retval = stk_read_next( stack );
	    EXTEND(SP, 1);
	    if ( retval )
	    {
	      PUSHs(sv_2mortal(newSVpv(retval, 0)));
	      Safefree( retval );
            }
	    else	  
	    {
	      PUSHs(sv_newmortal());
            }
          }
	  /*
	     array context: return it all
          */
	  else if ( GIMME_V == G_ARRAY )
          {
	    int current = stk_current( stack );
	    EXTEND(SP, stk_count(stack) );
	    stk_rewind(stack);
	    while( retval = stk_read_next( stack ) )
	    {
	      PUSHs(sv_2mortal(newSVpv(retval, 0)));
	      Safefree( retval );
	    }
	    if ( current ) stk_set_current( stack, current );
	    else           stk_rewind( stack );
          }
	}
	/* particular entry requested */
	else
	{
	  idx = SvIV(ST(1));
          if ( idx == -1 ) 
	     idx = stk_count( stack );
	  retval = stk_read_num( stack, idx );
	  EXTEND(SP, 1);
	  if ( retval )
	  {
	    PUSHs(sv_2mortal(newSVpv(retval, 0)));
	    Safefree( retval );
	  }
	  else	  
	  {
	    PUSHs(sv_newmortal());
          }
	}


###########################################################################

void
stk_rewind(stack)
	CIAO_Lib_StackIO *	stack

###########################################################################

