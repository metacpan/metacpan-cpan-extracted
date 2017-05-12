use lib 't';
use t::UnsafeSourceFilter;
use Acme::SafetyGoggles;
use Test::More tests => length("xx");  # Can't say tests=>2 because of source filter!

my $foo = 42;

ok( Acme::SafetyGoggles->state eq 'unsafe',
    'Acme::SafetyGoggles on altered module marked unsafe' );
ok( $foo + 1 != 43, "foo assignment was altered" );

diag "Differences between source code/source file: ",
	Acme::SafetyGoggles->diff;


