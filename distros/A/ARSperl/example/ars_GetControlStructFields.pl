#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetControlStructFields.pl,v 1.1 1997/10/29 21:56:43 jcmurphy Exp $
#
# NAME
#   ars_GetControlStructFields.pl
#
# USAGE
#   ars_GetControlStructFields.pl [server] [username] [password]
#
# DESCRIPTION
#   Demo of said function. See manual for details.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetControlStructFields.pl,v $
# Revision 1.1  1997/10/29 21:56:43  jcmurphy
# Initial revision
#
#
#
#

use ARS;

($c = ars_Login(shift, shift, shift))
	|| die "login: $ars_errstr";

($cacheId, $operationTime, $user, $password, $lang,
 $server) = ars_GetControlStructFields($c);

print "Control Struct Fields:
cacheId = $cacheId
operationTime = $operationTime
username = $user
password = $password
language = $lang
server = $server
";

ars_Logoff($c);

