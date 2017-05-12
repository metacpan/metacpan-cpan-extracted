#!perl

use strict;
use warnings;

package Utils::Tester;

use Moo;
with 'Business::Fixflo::Utils';

package main;

use Test::Most;
use DateTime::Tiny;

use Business::Fixflo::Utils;

my $Utils = Utils::Tester->new;

my $params = {
    page          => 1,
	CreatedSince  => '2001-01-01T00:00:00',
};

is( $Utils->normalize_params,'','normalize_params (no arg)' );
is( $Utils->normalize_params( {} ),'','normalize_params (no keys)' );

my $normalized = 'CreatedSince=2001-01-01T00%3A00%3A00&page=1';

is(
	$Utils->normalize_params( $params ),
	$normalized,
	'normalize_params'
);

$params = {
    page         => 1,
	CreatedSince => DateTime::Tiny->new(
		year   => 2001,
		month  => 1,
		day    => 1,
		hour   => 0,
		minute => 0,
		second => 0,
	),
};

is(
	$Utils->normalize_params( $params ),
	$normalized,
	'normalize_params (with DateTime)'
);

done_testing();
