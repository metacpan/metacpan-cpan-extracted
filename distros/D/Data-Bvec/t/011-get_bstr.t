use Test::More;

use Data::Bvec qw( bit2str );

POD: {

my $bv = Data::Bvec::->new( nums => [1,2,3] );

    my $bstr = $bv->get_bstr();

is( $bstr, '-134', 'get_bstr() POD' );

}

use Test::More tests => 1;

__END__
