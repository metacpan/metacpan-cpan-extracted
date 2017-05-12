#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/getCharSets.pl,v 1.1 2009/03/31 13:29:50 mbeijen Exp $
#
# NAME
#   GetCharSets.pl
#
# USAGE
#   GetCharSets.pl [server] [username] [password]
#
# DESCRIPTION
#   Fetches and prints the charsets used by client and server
#
# AUTHOR
#  Michiel Beijen
#
# $Log: getCharSets.pl,v $
# Revision 1.1  2009/03/31 13:29:50  mbeijen
# added new examples: ChangePassword.pl, ars_DateToJulianDate.pl, getCharSets.pl
#
#

use ARS;
use strict;

die "usage: $0 server username password \n"
  unless ( $#ARGV >= 2 );

my ( $server, $user, $password, ) = ( shift, shift, shift );

# if you'd like to use UTF8:
# $ENV{'LANG'} = "en_US.utf8";

#Logging in to the server
( my $ctrl = ars_Login( $server, $user, $password ) )
  || die "ars_Login: $ars_errstr";

print "Fetching the charsets - easy...\n";

( my $servercharset = ars_GetServerCharSet($ctrl) ) || die "ERR: $ars_errstr\n";
( my $clientcharset = ars_GetClientCharSet($ctrl) ) || die "ERR: $ars_errstr\n";

ars_Logoff($ctrl);

print
"The server uses the $servercharset character set and the client uses $clientcharset.\n";
