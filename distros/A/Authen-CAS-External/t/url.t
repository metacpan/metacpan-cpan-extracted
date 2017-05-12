#!perl -T

use strict;
use warnings;

use Test::More;

use Authen::CAS::External;
use URI;

# Define test cases
my %test_cases = (
	'https://cas.example.net' => {
		# Test for no arguments
		'https://cas.example.net/login'
			=> [],
		# Different gateway tests
		'https://cas.example.net/login?gateway=false'
			=> [gateway => q{}],
		'https://cas.example.net/login?gateway=false'
			=> [gateway => 0],
		'https://cas.example.net/login?gateway=true'
			=> [gateway => q{false}],
		'https://cas.example.net/login?gateway=true'
			=> [gateway => 1],
		'https://cas.example.net/login?gateway=true'
			=> [gateway => q{true}],
		'https://cas.example.net/login?gateway=true'
			=> [gateway => q{quack}],
		# Different renew tests
		'https://cas.example.net/login?renew=false'
			=> [renew => q{}],
		'https://cas.example.net/login?renew=false'
			=> [renew => 0],
		'https://cas.example.net/login?renew=true'
			=> [renew => q{false}],
		'https://cas.example.net/login?renew=true'
			=> [renew => 1],
		'https://cas.example.net/login?renew=true'
			=> [renew => q{true}],
		'https://cas.example.net/login?renew=true'
			=> [renew => q{quack}],
		# Different service tests
		'https://cas.example.net/login?service='
			=> [service => q{}],
		'https://cas.example.net/login?service=http%3A%2F%2Fservice.example.net'
			=> [service => q{http://service.example.net}],
		'https://cas.example.net/login?service=http%3A%2F%2Fservice.example.net%2F'
			=> [service => q{http://service.example.net/}],
	},
	'https://cas.example.net/' => {
		# Test for no arguments
		'https://cas.example.net/login'
			=> [],
	},
	'https://cas.example.net//' => {
		# Test for no arguments
		'https://cas.example.net//login'
			=> [],
	},
	'https://cas.example.net/login' => {
		# Test for no arguments
		'https://cas.example.net/login'
			=> [],
	},
	'https://cas.example.net/random/path' => {
		# Test for no arguments
		'https://cas.example.net/random/path/login'
			=> [],
	},
	'https://cas.example.net:88/' => {
		# Test for no arguments
		'https://cas.example.net:88/login'
			=> [],
	},
);

# Plan the tests
plan tests => scalar map { keys %{$test_cases{$_}}, 1 } keys %test_cases;

# Create a new object
my $authen = Authen::CAS::External->new(
	cas_url => 'https://cas.example.net',
);

foreach my $base_url (sort {$a le $b} keys %test_cases) {
	my %is_cases = %{$test_cases{$base_url}};

	# Set the base URL
	$authen->cas_url($base_url);

	is($authen->cas_url, $base_url, "URL $base_url set correctly");

	foreach my $is_url (sort {$a le $b} keys %is_cases) {
		my @args = @{$is_cases{$is_url}};

		is($authen->service_request_url(@args), $is_url,
			join(q{,}, @args) . ' correct');
	}
}
