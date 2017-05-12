#!perl -w
use strict;
use Test::More tests => 1;
use Archive::Merged;
use Archive::Dir;

my $merged = Archive::Merged->new(
    Archive::Dir->new( 't/' ),
);

ok $merged->contains_file('01-synopsis.t');