#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/GetField.pl,v 1.5 2009/03/31 13:34:32 mbeijen Exp $
#
# EXAMPLE
#    GetField.pl [server] [username] [password] [schema] [fieldname]
#
# DESCRIPTION
#    Connect to the server and fetch information about the
#    named field. Print the information out.
#
# NOTES
#    We'll be looking up the field names in the Default Admin View.
#
# AUTHOR
#    jeff murphy
#
# 02/19/97
#
# $Log: GetField.pl,v $
# Revision 1.5  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.4  1998/09/11 14:46:18  jcmurphy
# altered script logic so that it figures out whether it
# should decode a hash or array on the fly.
# fixed typo that was causing arrays not to be printed.
#
# Revision 1.3  1997/11/26 20:05:54  jcmurphy
# nada
#
# Revision 1.2  1997/05/07 15:38:19  jcmurphy
# fixed incorrect hash usage
#
# Revision 1.1  1997/02/19 22:41:16  jcmurphy
# Initial revision
#
#
#

use ARS;
use strict;

# Parse command line parameters

my ( $server, $username, $password, $schema, $fieldname ) = @ARGV;
if ( !defined($fieldname) ) {
    print "usage: $0 [server] [username] [password] [schema] [fieldname]\n";
    exit 1;
}

# Log onto the ars server specified

print "Logging in ..\n";

( my $ctrl = ars_Login( $server, $username, $password ) )
  || die "can't login to the server";

# Fetch all of the fieldnames/ids for the specified schema

print "Fetching field table ..\n";

( my %fids = ars_GetFieldTable( $ctrl, $schema ) )
  || die "GetFieldTable: $ars_errstr";

# See if the specified field exists.

if ( !defined( $fids{$fieldname} ) ) {
    print "ERROR: I couldn't find a field called \"$fieldname\" in the 
Default Admin View of schema \"$schema\"\n";
    exit 0;
}

# Get the field info

print "Fetching field information ..\n";

( my $fieldInfo = ars_GetField( $ctrl, $schema, $fids{$fieldname} ) )
  || die "GetField: $ars_errstr";

print "Here are some of the field attributes. More are available.

fieldId: $fieldInfo->{fieldId}
createMode: $fieldInfo->{createMode}
dataType: $fieldInfo->{dataType}
defaultVal: $fieldInfo->{defaultVal}
owner: $fieldInfo->{owner}

";

dumpKV( $fieldInfo, 0 );

ars_Logoff($ctrl);

exit 0;

sub dumpKV {
    my $hr = shift;
    my $i  = shift;

    foreach my $k ( keys %$hr ) {
        print "\t" x $i . "key=<$k> val=<$hr->{$k}>\n";
        if ( ref( $hr->{$k} ) eq "HASH" ) {
            dumpKV( $hr->{$k}, $i + 1 );
        }
        elsif ( ref( $hr->{$k} ) eq "ARRAY" ) {
            dumpAV( $hr->{$k}, $i + 1 );
        }
    }
}

sub dumpAV {
    my $ar = shift;
    my $i  = shift;
    my $a  = 0;

    foreach (@$ar) {
        print "\t" x $i . "index=<$a> val=<$_>\n";
        if ( ref($_) eq "HASH" ) {
            dumpKV( $_, $i + 1 );
        }
        elsif ( ref($_) eq "ARRAY" ) {
            dumpAV( $_, $i + 1 );
        }

        $a++;
    }

}

