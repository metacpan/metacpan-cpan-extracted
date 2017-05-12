#!perl -T

use Test::More tests => 3;

SKIP: {
    eval { require Imager };
    skip "No Imager, we cannot generate pixel images", 1 if $@;
    my $im = Imager->new;
    isa_ok( $im, 'Imager' );
    diag( "Good. We can generate pixel images." );
}

chdir("t") if -d "t";

SKIP: {
    skip "Sorry, no NPP pixel images", 2
      unless -s "../res/drawable-nodpi-v4/quality_h.png";
    ok( -s "../res/drawable-nodpi-v4/quality_h.png", 'NPP prefab images' );
    diag( "Good. We can generate NPP pixel images." );
    ok( -s "../res/drawable-nodpi-v4/quality_h_hand.png", 'NPP prefab hand images' );
    diag( "Good. We can generate NPP pixel images, hand-written style." );
}
