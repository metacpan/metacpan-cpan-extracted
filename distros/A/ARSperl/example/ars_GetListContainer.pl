#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListContainer.pl,v 1.1 2000/02/10 19:31:09 jcmurphy Exp $
#
# NAME
#   ars_GetListContainer.pl
#
# USAGE
#   ars_GetListContainer.pl [server] [username] [password]
#
# DESCRIPTION
#   demonstrate use of ars_GetListContainer call.
#
# AUTHOR
#   jeff murphy
#

use ARS 1.67;

$c = new ARS(-server => shift,
		-username => shift,
		-password => shift);
@l = ars_GetListContainer($c->ctrl(), 0,
				&ARS::AR_HIDDEN_INCREMENT, 
				&ARS::ARCON_GUIDE,
				&ARS::ARCON_APP);

exit 0;
