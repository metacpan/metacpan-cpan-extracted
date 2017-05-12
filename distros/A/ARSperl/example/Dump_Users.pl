#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Dump_Users.pl,v 1.8 2009/03/31 13:34:32 mbeijen Exp $
#
# EXAMPLE
#    Dump_Users.pl
#
# DESCRIPTION
#    Log onto the server and dump all users in the "User" schema.
#
# NOTES
#    This might require special permission for the username you login
#    as, depending upon how the ar admininstrator has the User schema
#    configured.
#
# AUTHOR
#    jeff murphy
#
# 01/12/96
#
# $Log: Dump_Users.pl,v $
# Revision 1.8  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.7  2007/03/13 13:20:32  jeffmurphy
# minor update to example scripts
#
# Revision 1.6  2003/03/27 17:58:42  jcmurphy
# 5.0 changes, bug fixes
#
# Revision 1.5  1999/05/05 19:57:59  rgc
# DumpUsers.
#
# Revision 1.4  1998/12/28 15:23:29  jcmurphy
# fixed up "Login name" query for ARS4.0 ("Login Name")
#
# Revision 1.3  1997/09/30 04:49:13  jcmurphy
# added some error output
# /
#
# Revision 1.2  1997/02/19 22:41:25  jcmurphy
# misspelling
#
# Revision 1.1  1996/11/21 20:13:51  jcmurphy
# Initial revision
#
#

use ARS;
use strict;

my $SCHEMA = "User";

# Parse command line parameters

my ( $server, $username, $password ) = @ARGV;
if ( !defined($password) ) {
    print "usage: $0 [server] [username] [password]\n";
    exit 1;
}

# Log onto the ars server specified

( my $ctrl = ars_Login( $server, $username, $password ) )
  || die "can't login to the server: $ars_errstr";

# Load the qualifier structure with a dummy qualifier.

( my $qual = ars_LoadQualifier( $ctrl, $SCHEMA, "(1 = 1)" ) )
  || die "error in ars_LoadQualifier: $ars_errstr";

# Retrieve the fieldid's for the "Login name" and "Full name" fields.
# As of ARS4.0, "name" has become "Name", so we'll check for both fields
# and use whatever we find.

my $loginname_fid = ars_GetFieldByName( $ctrl, $SCHEMA, "Login name" );
if ( !defined($loginname_fid) ) {
    ( $loginname_fid = ars_GetFieldByName( $ctrl, $SCHEMA, "Login Name" ) )
      || die "no such field in this schema: 'Login name'";
}

# Retrieve all of the entry-id's for the schema.

my @entries =
  ars_GetListEntry( $ctrl, $SCHEMA, $qual, 0, 0, [], $loginname_fid,
    &ARS::AR_SORT_ASCENDING );

die "No entries found in User schema? [$ars_errstr]"
  if $#entries == -1;

( my $fullname_fid = ars_GetFieldByName( $ctrl, $SCHEMA, "Full Name" ) )
  || die "no such field in this schema: 'Full Name'";

# Loop over all of the entries (in ascending order)

printf( "%-30s %-45s\n", "Login name", "Full name" );

for ( my $i = 0 ; $i <= $#entries ; $i += 2 ) {

    #foreach $entry_id (sort keys %entries) {

    # Retrieve the (fieldid, value) pairs for this entry

    my %e_vals = ars_GetEntry( $ctrl, $SCHEMA, $entries[$i] );

    # Print out the Login name and Full name for each record

    printf( "%-30s %-45s\n", $e_vals{$loginname_fid}, $e_vals{$fullname_fid} );
}

# Log out of the server.
ars_Logoff($ctrl);
