#!/usr/bin/perl -w
# -----------------------------------
# $Id: convert.pl,v 1.3 2002/10/16 18:56:28 tina Exp $
# Tool to convert big BLZ-files into a minimum format.
# Requires Storable.pm
# -----------------------------------

use strict;
use Storable;
usage() unless @ARGV == 3;
my ($orig_file,$mode,$dest) = @ARGV;
usage() if $mode !~ m/(BANK|POST)/;
my %dest;
open BLZ, "<$orig_file" or die "Could not open BLZ-File $orig_file $!";
if ($mode eq 'BANK') {
	while (<BLZ>) {
		my ($D_BLZ, $D_EIGEN, $OLD_BLZ, undef, undef, undef, $D_INST, $D_K_ORT, $D_PLZ, $D_ORT, undef, undef, undef, $D_BIC, $D_METHOD, undef) =
		unpack "A8A1A8AA4A5A58A20A5A29A27A5AA9A2A5", $_;
		$dest{$D_BLZ} = $D_METHOD;
		$dest{$OLD_BLZ} = $D_METHOD if $OLD_BLZ =~ m/^\d{8}$/ && $D_BLZ ne $OLD_BLZ; # BUGFIX 2.10.2002
	}
}
else {
	while (<BLZ>) {
		if (my ($D_BLZ, $D_INST, $D_PLZ, $D_ORT, $D_METHOD, $REST) =
			m/^(\d{8})(.{58})(\d{5})(.{30})(\d\d)(\d)/ ) {
			$dest{$D_BLZ} = $D_METHOD;
		}
	}
}
store \%dest, $dest or die "Problem writing to $dest: $!";
sub usage {
	print <<"EOM";
Usage: $^X $0 SOURCE MODE DESTINATION

SOURCE:      the original blz-file, either from POSTBANK or from BUNDESBANK
MODE:        'BANK' if from BUNDESBANK, 'POST' if from POSTBANK
DESTINATION: the new file

This will read in the original file, take only the information
needed for checking a bank account number and write it into
a new file. This can be a speedup if you invoke the check-script
very often because the file will be much smaller.

EOM
	exit;
}
