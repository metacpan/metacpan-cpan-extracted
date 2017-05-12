#!/usr/bin/perl
use strict;
use warnings;
use Business::IBAN;
use Getopt::Long;

my $ib;
my $result = GetOptions(
    "iban=s"   => \$ib,
);
usage() unless defined $ib;

my $iban = Business::IBAN->new();
my $valid = $iban->valid($ib);
if ($valid) {
    print "IBAN $ib is valid\n";
}
else {
    $iban->printError;
}

sub usage {
    print <<EOM;
Usage:
$0 --iban=DE12345678...
EOM
}
