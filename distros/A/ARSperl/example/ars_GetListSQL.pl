#!/usr/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListSQL.pl,v 1.3 2009/03/31 13:34:32 mbeijen Exp $
#
# NAME
#   ars_GetListSQL.pl
#
# USAGE
#   ars_GetListSQL.pl [server] [username] [password]
#
# DESCRIPTIONS
#   Log into the ARServer with the given username and password and
#   request that the SQL command (hardcoded below) be executed. Dump
#   output to stdout.
#
# NOTES
#   Requires Administrator privs to work.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetListSQL.pl,v $
# Revision 1.3  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.2  2000/02/03 21:29:03  jcmurphy
#
#
# fixed bug in GetListSQL
#
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
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

# The arschema table contains information about what schemas are
# in the system. We'll grab some of the columns and dump them.

my $sql = "select name, schemaid, nextid from arschema";

print "Calling GetListSQL with:\n\t$sql\n\n";

( my $sql_hash = ars_GetListSQL( $ctrl, $sql ) )
  || die "GetListSQL Failed: $ars_errstr\n";

# Log off nicely

ars_Logoff($ctrl);

print "GetListSQL returned the following rows:\n";

print "rows fetched: $sql_hash->{numMatches}\n";
print "name\t\tschemaid\t\tnextid\n";
for ( my $col = 0 ; $col < $sql_hash->{numMatches} ; $col++ ) {
    for ( my $row = 0 ; $row <= $#{ @{ $sql_hash->{rows} }[$col] } ; $row++ ) {
        print @{ @{ $sql_hash->{rows} }[$col] }[$row] . "\t\t";
    }
    print "\n";
}

