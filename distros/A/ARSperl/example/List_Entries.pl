#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/List_Entries.pl,v 1.2 2009/04/14 12:55:54 mbeijen Exp $
#
# EXAMPLE
#    List_Entries.pl
#
# DESCRIPTION
#    Log onto the server and printout a listing of Entry IDs and
#    Short Description (for each ID) for the given schema.
#
# NOTES
#    "Short Description" is *not* (neccessarily) the contents of the
#    "short-description" field. It is, in fact, the contents of the
#    "Query List Fields" for this schema. Try it on a schema that
#    you have some custom "Query List Fields" defined for to see
#    what we mean.
#
# AUTHOR
#    jeff murphy
#
# 01/12/96
#
# $Log: List_Entries.pl,v $
# Revision 1.2  2009/04/14 12:55:54  mbeijen
# Updated to work with version 5 and newer servers
#
# Revision 1.1  1996/11/21 20:13:54  jcmurphy
# Initial revision
#
#

use ARS;
use strict;

# Parse command line parameters

my ( $server, $username, $password, $schema ) = @ARGV;
if ( !defined($schema) ) {
    print "usage: $0 [server] [username] [password] [schema]\n";
    exit 1;
}

# Log onto the ars server specified

( my $ctrl = ars_Login( $server, $username, $password ) )
  || die "can't login to the server";

# Load the qualifier structure with a dummy qualifier.

( my $qual = ars_LoadQualifier( $ctrl, $schema, "(1 = 1)" ) )
  || die "error in ars_LoadQualifier";

# Retrieve all of the entry-id's for the schema.

my %entries = ars_GetListEntry( $ctrl, $schema, $qual, 0, 0 );

printf( "%-15s %-60s\n", "Entry-ID", "Short Description" );

foreach my $entry_id ( sort keys %entries ) {
    printf( "%-15s %-60s\n", $entry_id, $entries{$entry_id} );
}

# Log out of the server.

ars_Logoff($ctrl);
