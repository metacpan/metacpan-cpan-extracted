#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Get_Diary.pl,v 1.5 2009/03/31 13:34:32 mbeijen Exp $
#
# EXAMPLE
#    Get_Diary.pl
#
# DESCRIPTION
#    Log onto the server and dump all diary entries for a particular
#    qualification
#
# AUTHOR
#    jeff murphy
#
# 03/06/96
#
# $Log: Get_Diary.pl,v $
# Revision 1.5  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.4  2003/07/03 19:01:14  jcmurphy
# 1.81rc1 mem fixes from steve drew at hp.com
#
# Revision 1.3  2003/04/02 01:43:35  jcmurphy
# mem mgmt cleanup
#
# Revision 1.2  1998/03/31 15:44:00  jcmurphy
# nada
#
# Revision 1.1  1996/11/21 20:13:54  jcmurphy
# Initial revision
#
#

use ARS;
use strict;

# Parse command line parameters

my ( $server, $username, $password, $schema, $qualifier, $diaryfield ) = @ARGV;
if ( !defined($diaryfield) ) {
    print "usage: $0 [server] [username] [password] [schema] [qualifier]\n";
    print "       [diaryfieldname]\n";
    exit 1;
}

# Log onto the ars server specified

print "schema=$schema
qualifier=$qualifier
diaryfield=$diaryfield\n";

( my $ctrl = ars_Login( $server, $username, $password ) )
  || die "can't login to the server";

# Load the qualifier structure with a dummy qualifier.

( my $qual = ars_LoadQualifier( $ctrl, $schema, $qualifier ) )
  || die "error in ars_LoadQualifier:\n$ars_errstr";

# Retrieve all of the entry-id's for the qualification.

my %entries = ars_GetListEntry( $ctrl, $schema, $qual, 0, 0 );

# Retrieve the fieldid for the diary field

( my $diaryfield_fid = ars_GetFieldByName( $ctrl, $schema, $diaryfield ) )
  || die "no such field in this schema: '$diaryfield'";

foreach my $entry_id ( sort keys %entries ) {

    print ">>>>>  Entry-id: $entry_id <<<<<\n\n";

    # Retrieve the (fieldid, value) pairs for this entry

    my %e_vals = ars_GetEntry( $ctrl, $schema, $entry_id, $diaryfield_fid );

    # Print out the diary entries for this entry-id

    foreach my $diary_entry ( @{ $e_vals{$diaryfield_fid} } ) {
        print scalar localtime( $diary_entry->{timestamp} );
        print " ", $diary_entry->{user}, "\n";
        print $diary_entry->{value};
        print "\n\n";
    }
}

# Log out of the server.

ars_Logoff($ctrl);
