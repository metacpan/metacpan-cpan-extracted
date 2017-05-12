#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListEntry.pl,v 1.3 2009/04/14 12:28:07 mbeijen Exp $
#
# NAME
#   ars_GetListEntry.pl [server] [username] [password]
#
# DESCRIPTION
#   Demonstration of GetListEntry().
#
# AUTHOR
#   Jeff Murphy
#   jcmurphy@buffalo.edu
#
# $Log: ars_GetListEntry.pl,v $
# Revision 1.3  2009/04/14 12:28:07  mbeijen
# Updated to work with v5 and higher API
#
# Revision 1.2  2000/06/01 13:45:20  jcmurphy
# *** empty log message ***
#
# Revision 1.1  1998/03/25 22:52:51  jcmurphy
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

# Define form and fields - these may have different names on your server
my $schema     = "User";
my $login_name = "Login Name";
my $lic_type   = "License Type";
my $full_name  = "Full Name";

( my %fids = ars_GetFieldTable( $ctrl, $schema ) )
  || die "ars_GetFieldTable: $ars_errstr";

( my $qual = ars_LoadQualifier( $ctrl, $schema, "(1 = 1)" ) )
  || die "ars_LoadQualifier: $ars_errstr";

# basic format: allow the server to provide sorting order
# and query list fields.

print "Testing: basic format.\n";

( my @entries = ars_GetListEntry( $ctrl, $schema, $qual, 0, 0 ) )
  || die "ars_GetListEntry: $ars_errstr";

for ( my $i = 0 ; $i < $#entries ; $i += 2 ) {
    printf( "%s %s\n", $entries[$i], $entries[ $i + 1 ] );
}

# another format: specify a sorting order.
# sort by license type, ascending.

print "Testing: basic + sorting format.\n";

( my @sorted_entries =
      ars_GetListEntry( $ctrl, $schema, $qual, 0, 0, $fids{$login_name}, 1 ) )
  ||    # sort on Login Name, ascending
  die "ars_GetListEntry: $ars_errstr";

for ( my $i = 0 ; $i < $#sorted_entries ; $i += 2 ) {
    printf( "%s %s\n", $sorted_entries[$i], $sorted_entries[ $i + 1 ] );
}

# another format: specify a custom query list field-list.

print "Testing: basic + sorting + custom field-list format.\n";

if ( !defined( $fids{$login_name} ) || !defined( $fids{$full_name} ) ) {
    print
"Sorry. Either i can't find the field-id for \"$login_name\" or \"$full_name\"\n on your \"$schema\" form. I'm skipping this test.\n";
}
else {
    (
        my @basic_sorted_entries = ars_GetListEntry(
            $ctrl, $schema, $qual, 0, 0,
            [
                {
                    columnWidth => 10,
                    separator   => ' ',
                    fieldId     => $fids{$login_name}
                },    # first field: login name
                {
                    columnWidth => 15,
                    separator   => ' ',
                    fieldId     => $fids{$full_name}
                },    # second field: full name
            ],
            $fids{$full_name},
            2
        )
    ) || die "ars_GetListEntry: $ars_errstr";

    for ( my $i = 0 ; $i < $#basic_sorted_entries ; $i += 2 ) {
        printf( "%s %s\n",
            $basic_sorted_entries[$i],
            $basic_sorted_entries[ $i + 1 ] );
    }
}

ars_Logoff($ctrl);

exit 0;

