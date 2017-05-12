#!/usr/bin/perl

# Creating and using dependency trees

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 55;
use File::Spec::Functions ':ALL';
use Algorithm::Dependency::Weight;
use Algorithm::Dependency::Source::File;

# Where is the test data located
my $TESTDATA = catdir( 't', 'data' );
ok( -d $TESTDATA, 'Found test data directory' );





# Load the data/basics.txt file in as a source file, and test it rigorously.
my $file = File::Spec->catfile( $TESTDATA, 'basics.txt' );
my $Source = Algorithm::Dependency::Source::File->new( $file );
isa_ok( $Source, 'Algorithm::Dependency::Source::File' );
isa_ok( $Source, 'Algorithm::Dependency::Source' );
my @items = $Source->items;
is( scalar(@items), 6, "Source ->items returns a list" );
is( scalar($Source->items), 6, "Source ->items returns a list" );

# Create a Weight object
my $algorithm = Algorithm::Dependency::Weight->new( source => $Source );
isa_ok( $algorithm, 'Algorithm::Dependency::Weight'         );
isa_ok( $algorithm->source, 'Algorithm::Dependency::Source' );
my $basic = {
	A => 1,	B => 2,	C => 1,
	D => 3,	E => 1,	F => 1,
	};
foreach my $item ( sort keys %$basic ) {
	is( $algorithm->weight($item), $basic->{$item}, "Got weight for '$item'" );
}
is_deeply( $algorithm->weight_all, $basic, 'Got weight for all' );
delete $basic->{B};
delete $basic->{D};
is_deeply( $algorithm->weight_hash(qw{A C E F}), $basic, 'basic: Got weight for selected' );





# Larger scale processing
$file = File::Spec->catfile( $TESTDATA, 'complex.txt' );
$Source = Algorithm::Dependency::Source::File->new( $file );
isa_ok( $Source, 'Algorithm::Dependency::Source::File' );
isa_ok( $Source, 'Algorithm::Dependency::Source' );
@items = $Source->items;
is( scalar(@items), 20, "Source ->items returns a list" );
is( scalar($Source->items), 20, "Source ->items returns a list" );
$algorithm = Algorithm::Dependency::Weight->new( source => $Source );
isa_ok( $algorithm, 'Algorithm::Dependency::Weight'         );
isa_ok( $algorithm->source, 'Algorithm::Dependency::Source' );
my $complex = {
	A => 1,	B => 2,	C => 1,
	D => 3,	E => 2,	F => 1,
	G => 4,	H => 3,	I => 2,
	J => 1,	K => 3,	L => 2,
	M => 1,	N => 1,	O => 2,
	P => 2,	Q => 3,	R => 3,
	S => 6,	T => 11,
	};
foreach my $item ( sort keys %$complex ) {
	is(
		$algorithm->weight($item),
		$complex->{$item},
		"complex: Got weight for '$item'",
	);
}
	




# Test weightings in circulars
$file = File::Spec->catfile( $TESTDATA, 'circular.txt' );
$Source = Algorithm::Dependency::Source::File->new( $file );
isa_ok( $Source, 'Algorithm::Dependency::Source::File' );
isa_ok( $Source, 'Algorithm::Dependency::Source' );
@items = $Source->items;
is( scalar(@items), 8, "Source ->items returns a list" );
is( scalar($Source->items), 8, "Source ->items returns a list" );
$algorithm = Algorithm::Dependency::Weight->new( source => $Source );
isa_ok( $algorithm, 'Algorithm::Dependency::Weight'         );
isa_ok( $algorithm->source, 'Algorithm::Dependency::Source' );
my $circular = {
	A => 7,	B => 6,	C => 5,
	D => 5,	E => 6,	F => 2,
	G => 1,	H => 1,
	};
foreach my $item ( sort keys %$circular ) {
	is( $algorithm->weight($item), $circular->{$item}, "circular: Got weight for '$item'" );
}
