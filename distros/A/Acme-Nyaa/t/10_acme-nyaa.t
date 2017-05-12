use strict;
use warnings;
use lib './lib';
use utf8;
use Test::More;

BEGIN { use_ok 'Acme::Nyaa' }

my $kijitora = Acme::Nyaa->new;
my $language = [ 'ja' ];
my $cmethods = [ 'new' ];
my $imethods = [ 
    'cat', 'neko', 'nyaa', 'straycat',
    'loadmodule', 'findobject', 'objects', 'subclass',
];

can_ok( 'Acme::Nyaa', @$cmethods );
can_ok( 'Acme::Nyaa', @$imethods );
isa_ok( $kijitora, 'Acme::Nyaa' );
isa_ok( $kijitora->objects, 'ARRAY' );
isa_ok( $kijitora->new, 'Acme::Nyaa' );
is( $kijitora->language, 'ja', '->language() = ja' );
is( $kijitora->language('xx'), 'ja', '->language(xx) = ja' );
is( $kijitora->language('cat'), 'ja', '->language(cat) = ja' );

foreach my $e ( @$language ) {

    my $c = 'Acme::Nyaa::'.ucfirst( $e );
    my $o = Acme::Nyaa->new( 'language' => $e );
    my $p = undef;

    isa_ok( $o, 'Acme::Nyaa' );
    can_ok( $o, @$cmethods );
    can_ok( $o, @$imethods );
    isa_ok( $o->new, 'Acme::Nyaa' );
    isa_ok( $o->objects, 'ARRAY', '->objects() = ARRAY' );
    is( $o->language, $e, sprintf( "->language() = %s", $e ) );
    is( $o->subclass, $c, sprintf( "->subclass() = %s", $c ) );


    $p = $o->findobject( $c, 0 );
    isa_ok( $p, $c, sprintf( "->findobject(0) = %s", $c ));

    $p = $o->findobject( $c, 1 );
    isa_ok( $p, $c, sprintf( "->findobject(1) = %s", $c ));
}

done_testing;
__END__
