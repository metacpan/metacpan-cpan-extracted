use v5.10;
use experimental qw(signatures);

use Test::More;

require './t/lib/common.pl';
local %ENV;

my $password = 'Hello World';
my $hash     = '$2b$12$WUHhXETkKBCwKxOzLha2MOdvzFtt3s0trJ8VWDYL7AVqQCsIAkcUO';


subtest matches => sub {
	my $result = run_command( input => $password, args => ['--compare', $hash ] );
	like $result->{output}, qr/Match/, 'Password matches the hash';
	is $result->{exit}, 0, 'Exits successfully';
	};

subtest misses => sub {
	my $result = run_command( input => "abc$password", args => ['--compare', $hash ] );
	like $result->{output}, qr/Does not match/, 'Password matches the hash';
	is $result->{exit}, 1, 'Exits unsuccessfully';
	};

done_testing();
