#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Convert::Moji 'unambiguous';
my %ambig = (
    a => 'b',
    c => 'b',
);
my %unambig = (
    a => 'b',
    c => 'd',
);
for my $thing (\%ambig, \%unambig) {
    if (unambiguous ($thing)) {
	print "un";
    }
    print "ambiguous\n";
}

