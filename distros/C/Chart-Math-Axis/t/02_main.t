#!/usr/bin/perl

# Full testing for Chart::Math::Axis

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 165;
use Math::BigInt;
use Math::BigFloat;
use Chart::Math::Axis;





#####################################################################
# Preparation

my $Interval = Math::BigFloat->new( 5     );
my $First    = Math::BigFloat->new( 4     );
my $Second   = Math::BigFloat->new( 1.3   );
my $Third    = Math::BigFloat->new( 0     );
my $Fourth   = Math::BigFloat->new( 0.001 );
my $Fifth    = Math::BigFloat->new( -1.3  );
my $Sixth    = Math::BigFloat->new( -5    );





#####################################################################
# Test all the private math stuff first

# Chart::Math::Axis->_round_top
ok( Chart::Math::Axis->_round_top( 4, 5 ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( 1.3, 5 ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( 0, 5 ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( 0.001, 5 ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( -1.3, 5 ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( -5, 5 ) == 0, "->_round_top( -5, 5 )" );

ok( Chart::Math::Axis->_round_top( $First, 5 ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( $Second, 5 ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Third, 5 ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fourth, 5 ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fifth, 5 ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Sixth, 5 ) == 0, "->_round_top( -5, 5 )" );

ok( Chart::Math::Axis->_round_top( 4, $Interval ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( 1.3, $Interval ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( 0, $Interval ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( 0.001, $Interval ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( -1.3, $Interval ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( -5, $Interval ) == 0, "->_round_top( -5, 5 )" );

ok( Chart::Math::Axis->_round_top( $First, $Interval ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( $Second, $Interval ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Third, $Interval ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fourth, $Interval ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fifth, $Interval ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Sixth, $Interval ) == 0, "->_round_top( -5, 5 )" );

# Chart::Math::Axis->_round_bottom
ok( Chart::Math::Axis->_round_bottom( 4, 5 ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 1.3, 5 ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0, 5 ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0.001, 5 ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -1.3, 5 ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -5, 5 ) == -10, "->_round_bottom( -5, 5 )" );

ok( Chart::Math::Axis->_round_bottom( $First, 5 ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Second, 5 ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Third, 5 ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fourth, 5 ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fifth, 5 ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Sixth, 5 ) == -10, "->_round_bottom( -5, 5 )" );

ok( Chart::Math::Axis->_round_bottom( 4, $Interval ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 1.3, $Interval ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0, $Interval ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0.001, $Interval ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -1.3, $Interval ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -5, $Interval ) == -10, "->_round_bottom( -5, 5 )" );

ok( Chart::Math::Axis->_round_bottom( $First, $Interval ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Second, $Interval ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Third, $Interval ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fourth, $Interval ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fifth, $Interval ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Sixth, $Interval ) == -10, "->_round_bottom( -5, 5 )" );

# Chart::Math::Axis->_order_of_magnitude
ok( Chart::Math::Axis->_order_of_magnitude( 4 ) == 0, "->_order_of_magnitude( 4 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $First ) == 0, "->_order_of_magnitude( 4 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 1.3 ) == 0, "->_order_of_magnitude( 1.3 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Second ) == 0, "->_order_of_magnitude( 1.3 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 0 ) == 0, "->_order_of_magnitude( 0 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Third ) == 0, "->_order_of_magnitude( 0 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 0.001 ) == -3, "->_order_of_magnitude( 0.001 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Fourth ) == -3, "->_order_of_magnitude( 0.001 )" );
ok( Chart::Math::Axis->_order_of_magnitude( -1.3 ) == 0, "->_order_of_magnitude( -1.3 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Fifth ) == 0, "->_order_of_magnitude( -1.3 )" );

ok( Chart::Math::Axis->_order_of_magnitude( 10 ) == 1, "->_order_of_magnitude( 10 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 0.1 ) == -1, "->_order_of_magnitude( 0.1 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 50000 ) == 4, "->_order_of_magnitude( 50000 )" );

# Chart::Math::Axis->_reduce_interval
my $Reduced1 = Chart::Math::Axis->_reduce_interval( $Interval );
my $Reduced2 = Chart::Math::Axis->_reduce_interval( 5 );
isa_ok( $Interval, 'Math::BigFloat' );
ok( $Interval == 5, "->_reduce_interval doesn't alter argument" );
isa_ok( $Reduced1, 'Math::BigFloat' );
isa_ok( $Reduced2, 'Math::BigFloat' );
ok( $Reduced1 == 2, '->_reduce_interval( 5 )' );
ok( $Reduced2 == 2, '->_reduce_interval( 5 )' );
ok( Chart::Math::Axis->_reduce_interval( 100 ) == 50, '->_reduce_interval( 100 )' );
ok( Chart::Math::Axis->_reduce_interval( 50 ) == 20, '->_reduce_interval( 50 )' );
ok( Chart::Math::Axis->_reduce_interval( 20 ) == 10, '->_reduce_interval( 20 )' );
ok( Chart::Math::Axis->_reduce_interval( 10 ) == 5, '->_reduce_interval( 10 )' );
ok( Chart::Math::Axis->_reduce_interval( 2 ) == 1, '->_reduce_interval( 2 )' );
ok( Chart::Math::Axis->_reduce_interval( 1 ) == 0.5, '->_reduce_interval( 1 )' );
ok( Chart::Math::Axis->_reduce_interval( 0.5 ) == 0.2, '->_reduce_interval( 0.5 )' );
ok( Chart::Math::Axis->_reduce_interval( 0.2 ) == 0.1, '->_reduce_interval( 0.2 )' );
ok( Chart::Math::Axis->_reduce_interval( 0.1 ) == 0.05, '->_reduce_interval( 0.1 )' );





#####################################################################
# Test the constructor and basic access methods

my $axis = Chart::Math::Axis->new();
isa_ok( $axis, 'Chart::Math::Axis' );
ok( ! defined $axis->max, '->max returns undef for empty object' );
ok( ! defined $axis->min, '->min returns undef for empty object' );
ok( ! defined $axis->top, '->top returns undef for empty object' );
ok( ! defined $axis->bottom, '->bottom returns undef for empty object' );
ok( ! defined $axis->interval_size, '->interval_size returns undef for empty object' );
ok( ! defined $axis->ticks, '->ticks returns undef for empty object' );

# Throw a battery of constructor cases at it
$axis = Chart::Math::Axis->new( 10, 20 );
test_this( $axis, 'new simple case', [ 20, 10, 22, 8, 2, 7 ] );

$axis = Chart::Math::Axis->new( 20, 10 );
test_this( $axis, 'new reversed simple case', [ 20, 10, 22, 8, 2, 7 ] );

$axis = Chart::Math::Axis->new( 0, -10 );
test_this( $axis, 'new negative zero border case', [ 0, -10, 2, -12, 2, 7 ] );

$axis = Chart::Math::Axis->new( 5, -5 );
test_this( $axis, 'zero spanning case', [ 5, -5, 6, -6, 2, 6 ] );

$axis = Chart::Math::Axis->new( 10, 0 );
test_this( $axis, 'new positive zero border case', [ 10, 0, 12, 0, 2, 6 ] );

$axis = Chart::Math::Axis->new( 1.12 );
test_this( $axis, 'new single value case', [ 1.12, 1.12, 2, 1, 0.1, 10 ] );

$axis = Chart::Math::Axis->new( 10 );
test_this( $axis, 'single value case with 1 digit mantissa', [ 10, 10, 20, 0, 2, 10 ] );

$axis = Chart::Math::Axis->new( 0 );
test_this( $axis, 'single value case of 0', [ 0, 0, 1, 0, 1, 1 ] );

$axis = Chart::Math::Axis->new( -1.12 );
test_this( $axis, 'negative single value case', [ -1.12, -1.12, -1, -2, 0.1, 10 ] );

$axis = Chart::Math::Axis->new( -10 );
test_this( $axis, 'negative single value case with 1 digit mantissa', [ -10, -10, 0, -20, 2, 10 ] );





###############################################################################
# Test the modification methods

$axis = Chart::Math::Axis->new( 10 );
ok( $axis->add_data( 0 ), "->add_data returns true" );
ok( all_correct( $axis, [ 10, 0, 12, 0, 2, 6 ] ), "->add_data changes the Axis correctly" );

$axis = Chart::Math::Axis->new( 10 );
ok( $axis->include_zero, "->include_zero returns true" );
ok( all_correct( $axis, [ 10, 0, 12, 0, 2, 6 ] ), "->include_zero changes the Axis correctly" );

$axis = Chart::Math::Axis->new( 5, -5 );
ok( $axis->include_zero, "->include_zero returns true for zero spanning case" );
ok( all_correct( $axis, [ 5, -5, 6, -6, 2, 6 ] ), "->include_zero doesn't affect zero spanning case" );

$axis = Chart::Math::Axis->new( -10 );
ok( $axis->include_zero, "->include_zero returns true for negative case" );
ok( all_correct( $axis, [ 0, -10, 2, -12, 2, 7 ] ), "->include_zero works for negative case" );

$axis = Chart::Math::Axis->new( 10, 0 );
ok( $axis->maximum_intervals == 10, "Default maximum_intervals is correct" );
ok( $axis->set_maximum_intervals( 13 ), "->set_maximum_intervals returns true" );
ok( $axis->maximum_intervals == 13, "->set_maximum_intervals appears to change maximum_intervals" );
ok( all_correct( $axis, [ 10, 0, 11, 0, 1, 11 ] ), "->set_maximum_intervals adjust intervals as expected" );

# Heaps more tests to complete
### FINISH ME





# Function to test the properties of an Axis object
sub test_this {
	my $axis        = shift;
	my $description = shift;
	my $test        = shift;

	isa_ok( $axis, 'Chart::Math::Axis' );
	ok( $axis->max == $test->[0], "->max returns correct for $description" );
	ok( $axis->min == $test->[1], "->min returns correct for $description" );
	ok( $axis->top == $test->[2], "->top returns correct for $description" );
	ok( $axis->bottom == $test->[3], "->bottom returns correct for $description" );
	ok( $axis->interval_size == $test->[4], "->interval_size returns correct for $description" );
	ok( $axis->ticks == $test->[5], "->ticks returns correct for $description" );
}

sub all_correct {
	my $axis = shift;
	my $test = shift;

	return undef unless $axis->isa('Chart::Math::Axis');
	return undef unless $axis->max == $test->[0];
	return undef unless $axis->min == $test->[1];
	return undef unless $axis->top == $test->[2];
	return undef unless $axis->bottom == $test->[3];
	return undef unless $axis->interval_size == $test->[4];
	return undef unless $axis->ticks == $test->[5];

	return 1;
}
