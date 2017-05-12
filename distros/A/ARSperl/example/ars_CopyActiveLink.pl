#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_CopyActiveLink.pl,v 1.2 1998/09/14 17:38:47 jcmurphy Exp $
#
# NAME
#   ars_CopyActiveLink.pl [server] [username] [password] [active link]
#
# DESCRIPTION
#   copies the given active link to "Copy of ..."
#
# AUTHOR
#   Jeff murphy
#
# $Log: ars_CopyActiveLink.pl,v $
# Revision 1.2  1998/09/14 17:38:47  jcmurphy
# changed #!perl path
#
# Revision 1.1  1997/09/04 00:16:00  jcmurphy
# Initial revision
#
#

use ARS;

($c = ars_Login(shift, shift, shift)) ||
	die "login: $ars_errstr";


($a = ars_GetActiveLink($c, shift)) || 
    die "GetActiveLink: $ars_errstr";


$a->{name} .= "Copy of ";

ars_CreateActiveLink($c, $a) || 
    die "$0: ERROR in CreateActiveLink:\n\n$ars_errstr";

ars_Logoff($c) || 
	die "Logoff: $ars_errstr";

