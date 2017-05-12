/* $Id: Holy.xs,v 1.1.1.1 2003/06/16 01:59:11 ian Exp $ */

/*
** Holy.xs
**
** Define the holy() method of Acme::Holy.
**
** Author:        I. Brayshaw <ian@onemore.org>
** Revision:      $Revision: 1.1.1.1 $
** Last modified: $Date: 2003/06/16 01:59:11 $
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Acme::Holy		PACKAGE = Acme::Holy		

SV *
holy( rv )
		SV * rv;

	PROTOTYPE: $

	ALIAS:
		blessed     = 1
		consecrated = 2
		divine      = 3
		hallowed    = 4
		sacred      = 5
		sacrosanct  = 6

	PREINIT:
		SV		*sv;
		char	*name;

	CODE:
		/* if we don't have a blessed reference then return undef */
		if ( ! sv_isobject( rv ) )
			XSRETURN_UNDEF;

		/*
		** OK, so we have a blessed reference - an object - so
		** we should extract the name of the stash.
		*/

		sv		= SvRV( rv );
		name	= HvNAME( SvSTASH( sv ) );

		/* return the name of the package */
		RETVAL	= newSVpv( name , 0 );

	OUTPUT:
		RETVAL
