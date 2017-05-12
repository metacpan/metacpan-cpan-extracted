#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/PrintQual.pl,v 1.2 1999/10/03 04:09:08 jcmurphy Exp $
#
# EXAMPLE
#    PrintQual.pl
#
# DESCRIPTION
#    Using ars_perl_qualifier, decode the QualifierStruct and
#    print it in human readable form. This script is really
#    only a basis and handles most of the generic cases. Further
#    developement would be needed to fully implement a qualifier
#    re-builder.
#
#    You can include the routine Decode_QualHash() and Decode_FVoAS()
#    in your own scripts by requiring 'ars_QualDecode.pl';
# 
# TODO
#    TR. and DB. references need to be implemented in ARS.xs
#    as of now, we don't get that information, so we can't
#    decode it.
#
#    ArithStruct is not handled. See the GetFilter.pl example
#    for routines that will handle this. This probably doesnt
#    matter since i dont think ARS allows you to use arith
#    expression in a qualification.
#
# AUTHOR
#    jeff murphy
#
# 02/20/97
#
# $Log: PrintQual.pl,v $
# Revision 1.2  1999/10/03 04:09:08  jcmurphy
# various
#
# Revision 1.1  1997/02/20 19:33:02  jcmurphy
# Initial revision
#
#
#

use ARS;

require 'ars_QualDecode.pl';

$debug = 0;

# Parse command line parameters

($server, $username, $password, $schema, $qual) = @ARGV;
if(!defined($password)) {
    print "usage: $0 [server] [username] [password] [schema] [qualification]\n";
    exit 1;
}

# Log onto the ars server specified

($ctrl = ars_Login($server, $username, $password)) || 
    die "can't login to the server";

# Load the qualifier structure 

($q = ars_LoadQualifier($ctrl,$schema, $qual)) ||
    die "error in ars_LoadQualifier:\n$ars_errstr\n";

# Decode the encoded structure

($dq = ars_perl_qualifier($ctrl, $q)) ||
    die "ars_perl_qualifier failed: $ars_errstr\n";

# Convert the decoded structure to a readable format

$e = ars_Decode_QualHash($ctrl, $schema, $dq);

print "$e\n";

ars_Logoff($ctrl);

exit 0;

