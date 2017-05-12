use Test::More;

use Data::Bvec qw( bit2str );

POD: {

my $bv = Data::Bvec::->new( nums => [1,2,3] );

    my $vec = $bv->get_bvec();

is( bit2str( $vec ), '01110000', 'get_bvec() POD' );

}

use Test::More tests => 1;

__END__
