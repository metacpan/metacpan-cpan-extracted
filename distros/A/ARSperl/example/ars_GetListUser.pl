#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListUser.pl,v 1.3 2009/03/31 13:34:32 mbeijen Exp $
#
# NAME
#   ars_GetListUser.pl
#
# USAGE
#   ars_GetListUser.pl [server] [username] [password]
#
# DESCRIPTION
#   Demo of said function. Fetches and prints listing of
#   all currently connected users and their license info.
#
# NOTES
#   email addr and notify mech are (as far as we can tell) part of the
#   return values from the API, but are never filled in. this is not a
#   bug in arsperl.
#
# AUTHOR
#   jeff murphy
#
# $Log: ars_GetListUser.pl,v $
# Revision 1.3  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.2  2001/04/11 15:10:15  jcmurphy
# updates to Makefile.PL for server info map
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

my @noteMech = ( "NONE", "NOTIFIER", "EMAIL",     "?" );
my @licType  = ( "NONE", "FIXED",    "FLOATING",  "FIXED2" );
my @licTag   = ( "",     "WRITE",    "FULL_TEXT", "RESERVED1" );

print "Calling GetListUser and asking for all connected users...\n";

# 0 = current user's info
# 1 = all users' info
# 2 = all connected users' info
#
# default = 0

( my @h = ars_GetListUser( $ctrl, 2 ) ) || die "ERR: $ars_errstr\n";

print "GetListUser returned the following:\n";

foreach (@h) {
    print "userName: $_->{userName}\n";
    print "\tconnectTime: " . localtime( $_->{connectTime} ) . "\n";
    print "\tlastAccess: " . localtime( $_->{lastAccess} ) . "\n";
    print "\tnotify mech: $_->{defaultNotifyMech} ("
      . $noteMech[ $_->{defaultNotifyMech} ] . ")\n";
    print "\temail addr: $_->{emailAddr}\n";

    for ( my $i = 0 ; $i <= $#{ $_->{licenseTag} } ; $i++ ) {
        print "\tlicense \#$i info:\n";

        print "\t\tlicenseTag: "
          . @{ $_->{licenseTag} }[$i] . " ("
          . $licTag[ @{ $_->{licenseTag} }[$i] ] . ")\n";
        print "\t\tlicenseType: "
          . @{ $_->{licenseType} }[$i] . " ("
          . $licType[ @{ $_->{licenseType} }[$i] ] . ")\n";
        print "\t\tcurrentLicenseType: "
          . @{ $_->{currentLicenseType} }[$i] . " ("
          . $licType[ @{ $_->{currentLicenseType} }[$i] ] . ")\n";
    }
}

ars_Logoff($ctrl);
