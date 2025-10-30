#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use_ok('Data::Random::String::Matches');

like(Data::Random::String::Matches->create_random_string(regex => '^\d{2}$'), qr/^\d{2}$/, 'generated string is 2 digits');

subtest 'create_random_string compatibility' => sub {
	my $str = Data::Random::String::Matches->create_random_string(
		length => 3,
		regex => '\d{3}'
	);
	like($str, qr/^\d{3}$/, 'create_random_string works');
};

done_testing();
