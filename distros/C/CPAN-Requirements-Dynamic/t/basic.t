#! perl

use strict;
use warnings;

use Test::More;
use Config;
use CPAN::Requirements::Dynamic;

my $dynamic = CPAN::Requirements::Dynamic->new;

my $result1 = $dynamic->evaluate({
	version => 1,
	expressions => [
		{ 
			condition => [ has_perl => "$]" ],
			prereqs => { Foo => "1.2" },
		},
		{
			condition => [ not => has_perl => 5 ],
			prereqs => { Bar => "1.3" },
		},
		{
			condition => [ is_os => $^O ],
			prereqs => { Baz => "1.4" },
		},
		{
			condition => [ or => [ config_defined => 'useperlio' ] ],
			prereqs => { Quz => "1.5" },
		},
		{
			condition => [ and => [ has_perl => "$]" ], [ is_os => 'non-existent' ] ],
			prereqs => { Euz => "1.7" },
		},
	],
});

my $hash1 = $result1->as_string_hash;
is_deeply($hash1, { runtime => { requires => { Foo => '1.2', Baz => '1.4', Quz => '1.5' } } }) or diag explain $hash1;

done_testing;
