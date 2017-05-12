use Test::More tests => 3;

BEGIN { use_ok( 'Acme::Goatse' ); }

require_ok( 'Acme::Goatse' );


my $foo = goatse();
ok($foo);
