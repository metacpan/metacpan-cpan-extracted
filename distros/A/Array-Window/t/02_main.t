#!/usr/bin/perl

# Formal testing for Array::Window

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 54;
use Array::Window ();

# Run the bulk of the tests
my $group   = 'basic';
my $test_id = 0;
foreach ( <DATA> ) {
	$test_id++;
	chomp;
	next if /^\s*$/ || /^\s*#/;

	# Split
	my @parts = map { $_ eq 'undef' ? undef : $_ } split /\W+/, $_;
	die 'Invalid test format' unless scalar @parts == 17;

	# Create the object
	my $Object = Array::Window->new(
		source_start  => $parts[0],
		source_end    => $parts[1],
		window_start  => $parts[3],
		window_length => $parts[4],
	);
	ok( defined $Object, "$group:$test_id defined " );
	isa_ok( $Object, 'Array::Window' );
	ok( compare($Object->human_source_start, $parts[0] + 1), "$group:$test_id ->human_source_start returns correct" );
	ok( compare($Object->human_source_end,   $parts[1] + 1), "$group:$test_id ->human_source_end returns correct" );
	ok( compare($Object->source_length,         $parts[2]),  "$group:$test_id ->source_length returns correct" );
	ok( compare($Object->window_start,          $parts[5]),  "$group:$test_id ->window_start returns correct" );
	ok( compare($Object->window_end,            $parts[6]),  "$group:$test_id ->window_end returns correct" );
	ok( compare($Object->human_window_start,    $parts[7]),  "$group:$test_id ->human_window_start returns correct" );
	ok( compare($Object->human_window_end,      $parts[8]),  "$group:$test_id ->human_window_end returns correct" );
	ok( compare($Object->window_length,         $parts[9]),  "$group:$test_id ->window_length returns correct" );
	ok( compare($Object->window_length_desired, $parts[4]),  "$group:$test_id ->window_length_desired returns correct" );
	ok( compare($Object->required,              $parts[10]),  "$group:$test_id ->required returns correct" );
	ok( compare($Object->previous_start,        $parts[11]),  "$group:$test_id ->previous_start returns correct" );
	ok( compare($Object->next_start,            $parts[12]), "$group:$test_id ->next_start returns correct" );

	ok( (!! $Object->first)    == (!! $parts[13]),           "$group:$test_id ->first returns correct" );
	ok( (!! $Object->last)     == (!! $parts[14]),           "$group:$test_id ->last returns correct" );
	ok( (!! $Object->previous) == (!! $parts[15]),           "$group:$test_id ->previous returns correct" );
	ok( (!! $Object->next)     == (!! $parts[16]),           "$group:$test_id ->next returns correct" );	
}

sub compare {
	return undef unless scalar @_ == 2;
	my ($a, $b) = @_;

	if ( defined $a and defined $b ) {
		return $a == $b ? 1 : 0;
	} elsif ( ! defined $a and ! defined $b ) {
		return 1;
	} else {
		return 0;
	}
}

__DATA__
0-100:101:0-10  0-9:1-10:10:1       undef:10  0:1:0:1
0-100:101:10-10 10-19:11-20:10:1    0:20      1:1:1:1
0-100:101:98-10 91-100:92-101:10:1  81:undef  1:0:1:0
