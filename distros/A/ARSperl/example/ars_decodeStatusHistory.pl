#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_decodeStatusHistory.pl,v 1.3 2007/08/02 14:48:21 mbeijen Exp $
#
# NAME
#   ars_decodeStatusHistory.pl [server] [username] [password] [schema] [eid]
#
# DESCRIPTION
#   retrieves the entryid from the given schema and decodes it's status
#   history values.
#
# AUTHOR
#   Jeff murphy
#
# $Log: ars_decodeStatusHistory.pl,v $
# Revision 1.3  2007/08/02 14:48:21  mbeijen
# modified examples for ExecuteProcess and decodeStatusHistory
#
# Revision 1.2  1998/09/14 17:39:20  jcmurphy
# changed #!perl path
#
# Revision 1.1  1998/09/11 15:51:42  jcmurphy
# Initial revision
#
#
#

use ARS;
use warnings;
use strict;

die "usage: ars_decodeStatusHistory.pl [server] [username] [password] [form] [entry]\n" unless ($#ARGV == 4);

# Log in to the server
(my $ctrl = ars_Login(shift, shift, shift)) ||
    die "login: $ars_errstr";

(my $form, my $entry) = (shift, shift);

# get the information for this entry. ars_GetEntry returns a hash of field ID's and its values.
# in fact, we only are interested in this example in field 15 which contains the Status History.
(my %entry = ars_GetEntry($ctrl, $form, $entry, 15)) ||
    die "GetEntry: $ars_errstr (no entry $entry in form $form ?)";

# load the field information for field 7 (Status) so we can determine what the names are for 
# the different statuses.
(my $field_info = ars_GetField($ctrl, $form, 7)) ||
    die "GetField: $ars_errstr ";

# retrieving all status values for enumerated field Status
my @enum_vals = @{$field_info->{limit}{enumLimits}{regularList}};

print "Status values: ".join(', ', @enum_vals)."\n";

#The Status History field is always field number 15.
my @status_values = ars_decodeStatusHistory($entry{15});
my $i;
# loop trough the created Status Values array, which is an array that contains hash refs
# we'll print the Status name with it, which we retrieved earlier using ars_GetField.
foreach (@status_values) {
    print $enum_vals[$i++].": \n";
	if ($_->{USER}) { 
	print "\tUSER: ".$_->{USER}."\n";
    print "\tTIME: ".localtime($_->{TIME})."\n"; # with localtime we convert Epoch to human-readable
	} else {
    print "\tNo Status History entry\n"; 
    }	
}
# log off nicely.
ars_Logoff($ctrl);

exit 0;