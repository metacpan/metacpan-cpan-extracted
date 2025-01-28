#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use CGI::Untaint;

BEGIN { use_ok('CGI::Untaint::CountyStateProvince::US') }

# Mock data to simulate form input
my %params = (
	valid_abbreviation	=> 'MD',	 # Valid two-letter abbreviation
	valid_full_name	=> 'Maryland',	# Valid full state name
	invalid_abbreviation => 'XX',	# Invalid two-letter abbreviation
	invalid_full_name	 => 'Atlantis',	# Invalid full state name
	valid_with_whitespace => '  MD  ',	# Valid abbreviation with extra whitespace
	mixed_case_full_name => 'mArYlAnD',	# Valid full name in mixed case
);

# Create a CGI::Untaint object
my $untaint = new_ok('CGI::Untaint' => [ \%params ]);

# Test valid state abbreviation
ok(
	$untaint->extract(-as_CountyStateProvince => 'valid_abbreviation'),
	'Valid state abbreviation is accepted'
);

# Test valid full state name
ok(
	$untaint->extract(-as_CountyStateProvince => 'valid_full_name'),
	'Valid full state name is accepted'
);

# Test invalid state abbreviation
is(
	$untaint->extract(-as_CountyStateProvince => 'invalid_abbreviation'),
	undef,
	'Invalid state abbreviation is rejected'
);

# Test invalid full state name
is(
	$untaint->extract(-as_CountyStateProvince => 'invalid_full_name'),
	undef,
	'Invalid full state name is rejected'
);

# Test valid abbreviation with extra whitespace
is(
	$untaint->extract(-as_CountyStateProvince => 'valid_with_whitespace'),
	'MD',
	'Valid state abbreviation with whitespace is trimmed and accepted'
);

# Test mixed-case full state name
is(
	$untaint->extract(-as_CountyStateProvince => 'mixed_case_full_name'),
	'MD',
	'Valid full state name in mixed case is accepted and converted to abbreviation'
);

# Done testing
done_testing();
