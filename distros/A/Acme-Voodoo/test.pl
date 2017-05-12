use Test::More ( no_plan );

use_ok( 'Acme::Voodoo' );

my $doll = Acme::Voodoo->new( 'CGI' );

## make sure our doll is of the right class
isa_ok( $doll, 'Acme::Voodoo::Doll_0' );

## see if we can call a method on it
like( $doll->header(), qr{content-type: text/html}i, 'CGI voodooo doll works');

## see if we can see the pins (aka methods)
ok( $doll->pins() > 10, 'pins() found some pins' ); 

## see if we can sleep
my $start = time();
$doll->zombie( 2 );
$doll->header();
my $end = time();
ok( $end > $start+1, 'zombie() works' );

## see if we can kill our object through our doll
$doll->kill();
eval{ $doll->header() };
like ( $@, qr/an evil curse has struck me down/, 'kill() works' );




