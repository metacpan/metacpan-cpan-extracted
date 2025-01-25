use strict;
use warnings;
use Test::Most;
use CGI::Untaint;

BEGIN { use_ok('CGI::Untaint::CountyStateProvince::GB') }

# Helper function to create CGI::Untaint object
sub create_untaint_object {
	my $value = shift;
	return new_ok('CGI::Untaint' => [ state => $value ]);
}

# Test 1: Valid counties
my @valid_counties = qw(Kent Surrey London Middlesex Cambridgeshire);
foreach my $county (@valid_counties) {
	my $untaint = create_untaint_object($county);
	my $result = $untaint->extract(-as_CountyStateProvince => 'state');
	ok($result, "Valid county '$county' should pass validation");
}

# Test 2: Valid abbreviations
my %abbreviation_tests = (
	'Beds' => 'bedfordshire',
	'Cambs'	=> 'cambridgeshire',
	'Lancs' => 'lancashire',
	'Middx' => 'middlesex',
	'West Yorks' => 'west yorkshire',
	'Herts' => 'hertfordshire',
);
foreach my $abbr (keys %abbreviation_tests) {
	my $expected = $abbreviation_tests{$abbr};
	my $untaint = create_untaint_object($abbr);
	my $result = $untaint->extract(-as_CountyStateProvince => 'state');
	is($result, $expected, "Abbreviation '$abbr' correctly maps to '$expected'");
}

# Test 3: Invalid counties
my @invalid_counties = qw(Queensland California Atlantis);
foreach my $county (@invalid_counties) {
	my $untaint = create_untaint_object($county);
	my $result = $untaint->extract(-as_CountyStateProvince => 'state');
	ok(!$result, "Invalid county '$county' should fail validation");
}

# Test 4: Edge cases
my @edge_cases = (
	{ input => '', expected => undef, description => 'Empty string should fail' },
	{ input => '  ', expected => undef, description => 'Whitespace-only input should fail' },
	{ input => 'KENT', expected => 'kent', description => "Case insensitivity for 'KENT'" },
	{ input => " Middlesex\t", expected => 'middlesex', description => "Trim whitespace for ' Middlesex\t'" },
);
foreach my $case (@edge_cases) {
	my $untaint = create_untaint_object($case->{input});
	my $result = $untaint->extract(-as_CountyStateProvince => 'state');
	is($result, $case->{expected}, $case->{description});
}

done_testing();
