#!/usr/bin/perl

use strict;
use warnings;
use Data::Google::Visualization::DataTable;

use Test::More;

my $timestamp = 1346692671;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($timestamp);
$year += 1900;

for my $test (
	{
		name => 'Epoch Timestamp',
		input => 1346692671,
		expected => {
			date      => "new Date( $year, $mon, $mday )",
			datetime  => "new Date( $year, $mon, $mday, $hour, $min, $sec )",
			timeofday => "[$hour, $min, $sec]"
		},
	},
	{
		name => 'Epoch Timestamp with useless "with_timezone"',
		input => 1346692671,
		with_timezone => 1, # Shouldn't do any thing
		expected => {
			date      => "new Date( $year, $mon, $mday )",
			datetime  => "new Date( $year, $mon, $mday, $hour, $min, $sec )",
			timeofday => "[$hour, $min, $sec]"
		},
	},
	{
		name => 'DateTime',
		input => sub {
			my $dt = DateTime->from_epoch( epoch => $timestamp );
			$dt->set_time_zone( 'Asia/Kathmandu' );
			return $dt;
		},
		with_timezone => 0, # Shouldn't do any thing
		requires => 'DateTime',
		expected => {
			date      => "new Date( 2012, 8, 3 )",
			datetime  => "new Date( 2012, 8, 3, 23, 2, 51 )",
			timeofday => "[23, 2, 51]"
		},
	},
	{
		name => 'DateTime with ms',
		input => sub {
			my $dt = DateTime->from_epoch( epoch => $timestamp );
			$dt->set_nanosecond( 500_000_000 );
			$dt->set_time_zone( 'Asia/Kathmandu' );
			return $dt;
		},
		with_timezone => 0, # Shouldn't do any thing
		requires => 'DateTime',
		expected => {
			date      => "new Date( 2012, 8, 3 )",
			datetime  => "new Date( 2012, 8, 3, 23, 2, 51, 500 )",
			timeofday => "[23, 2, 51, 500]"
		},
	},
	{
		name => 'DateTime with Timezone',
		input => sub {
			my $dt = DateTime->from_epoch( epoch => $timestamp );
			$dt->set_time_zone( 'Asia/Kathmandu' );
			return $dt;
		},
		with_timezone => 1, # Shouldn't do any thing
		requires => 'DateTime',
		expected => {
			date      => 'new Date("Mon, 03 Sep 2012 23:02:51 GMT+0545")',
			datetime  => 'new Date("Mon, 03 Sep 2012 23:02:51 GMT+0545")',
			timeofday => "[23, 2, 51]"
		},
	},
	{
		name => 'Time::Piece',
		input => sub { Time::Piece->new( $timestamp ) },
		with_timezone => 0, # Shouldn't do any thing
		requires => 'Time::Piece',
		expected => {
			date      => "new Date( $year, $mon, $mday )",
			datetime  => "new Date( $year, $mon, $mday, $hour, $min, $sec )",
			timeofday => "[$hour, $min, $sec]"
		},
	},
	{
		name => 'Time::Piece, with useless "with_timezone"',
		input => sub { Time::Piece->new( $timestamp ) },
		with_timezone => 1, # Shouldn't do any thing
		requires => 'Time::Piece',
		expected => {
			date      => "new Date( $year, $mon, $mday )",
			datetime  => "new Date( $year, $mon, $mday, $hour, $min, $sec )",
			timeofday => "[$hour, $min, $sec]"
		},
	},
) {
	note "Test case: " . $test->{'name'};

	if ( $test->{'requires'} ) {
		eval "require $test->{'requires'}";
		if ( $@ ) {
			note "Skipping: $@";
			next;
		}
	}

	my $datatable = Data::Google::Visualization::DataTable->new(
		( $test->{'with_timezone'} ? ({ with_timezone => 1 }) : () )
	);
	$datatable->add_columns(
		{ id => 'date', type => 'date' },
		{ id => 'datetime', type => 'datetime' },
		{ id => 'timeofday', type => 'timeofday' }
	);

	my $input = $test->{'input'};
	$input = $input->() if ref $input;

	$datatable->add_rows({
		date => $input,
		datetime => $input,
		timeofday => $input,
	});

	for my $key ( keys %{ $test->{'expected'} } ) {
		my $output = $datatable->output_javascript( columns => [ $key ]);
		$output =~ s/^.+\{"v"\:(.+?)\}.+$/$1/;
		is( $output, $test->{'expected'}->{$key}, "$key matches" );
	}

}

done_testing();
