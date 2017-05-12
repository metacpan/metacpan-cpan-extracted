#!perl -T

use strict;
use warnings;

use Audit::DBI::Utils;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


my $tests = [];
foreach my $line ( <DATA> )
{
	chomp( $line );
	next if !defined( $line ) || $line !~ /\w+/ || substr( $line, 0, 1 ) eq '#';
	push( @$tests, $line );
}

plan( tests => 1 + scalar( @$tests ) );

can_ok(
	'Audit::DBI::Utils',
	'ipv4_to_integer',
);

# Run the tests defined in the DATA section below.
foreach my $test ( @$tests )
{
	my ( $ipv4, $integer ) = split( /\t+/, $test );
	$integer = undef
		if defined( $integer ) && ( $integer eq '' );

	is(
		Audit::DBI::Utils::ipv4_to_integer(
			$ipv4,
		),
		$integer,
		"Convert $ipv4 to integer.",
	);
}


__DATA__
# IPv4	Integer
192.168.0.1	3232235521
0.0.0.1		1
000.000.000.1	1
000.0.000.01	1
255.255.255.255	4294967295
10.0.0.7	167772167
# Verify that an invalid format is handled properly.
10.0.0
x
