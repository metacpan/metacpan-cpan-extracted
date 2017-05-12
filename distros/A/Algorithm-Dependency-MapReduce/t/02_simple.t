#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Algorithm::Dependency::MapReduce   ();
use Algorithm::Dependency::Source::HoA ();

my $data = {
	1 => [],
	2 => [ 3 ],
	3 => [],
	4 => [ 5, 6 ],
	5 => [],
	6 => [],
};

my $simple = Algorithm::Dependency::MapReduce->new(
	source => Algorithm::Dependency::Source::HoA->new($data),
	map    => sub { $_[1] + 1     },
	reduce => sub { $_[1] + $_[2] },
);
isa_ok( $simple, 'Algorithm::Dependency::MapReduce' );
isa_ok( $simple->source, 'Algorithm::Dependency::Source::HoA' );

# Test all single element answers
my @mapreduce = qw{
	1  2
	2  7
	3  4
	4  18
	5  6
	6  7
};
while ( @mapreduce ) {
	my $input    = shift @mapreduce;
	my $expected = shift @mapreduce;
	my $got      = $simple->mapreduce( $input );
	is( $got, $expected, "mapreduce($input) ok" );
}
