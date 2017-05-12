#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetServerInfo.pl,v 1.3 2009/03/31 13:34:32 mbeijen Exp $
#
# NAME
#   ars_GetServerInfo.pl
#
# USAGE
#   ars_GetServerInfo.pl [server] [username] [password]
#
# DESCRIPTION
#   Retrieve and print server configuration information.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetServerInfo.pl,v $
# Revision 1.3  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.2  2007/02/03 02:33:11  tstapff
# arsystem 7.0 port, new ars_Create/Set functions
#
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;
use strict;

die "usage: $0 server username password \n"
  unless ( $#ARGV >= 2 );

my ( $server, $user, $password ) = ( shift, shift, shift );

#Logging in to the server
( my $ctrl = ars_Login( $server, $user, $password ) )
  || die "ars_Login: $ars_errstr";

print "Calling GetServerInfo ..\n";

( my %h = ars_GetServerInfo($ctrl) ) || die "ERR: $ars_errstr\n";

for my $it ( sort keys %h ) {
    printf( "%25s %s\n", $it, $h{$it} );
}

ars_Logoff($ctrl);
