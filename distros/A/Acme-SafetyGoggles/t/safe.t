use t::SafeSourceFilter;
use Acme::SafetyGoggles;
use Test::More tests => 3;

my $foo = 42;

ok( Acme::SafetyGoggles->state eq 'safe',
    'Acme::SafetyGoggles on unaltered module certified safe' )
or diag(Acme::SafetyGoggles->state);
ok( Acme::SafetyGoggles->diff eq '',
    'No differences reported between source code and source file' );
ok( $foo + 1 == 43, "foo assignment not changed" );


