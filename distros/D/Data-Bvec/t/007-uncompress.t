use Test::More;

use Data::Bvec qw( uncompress );

POD: {

    my $bstr = '-134';
    my $str  = uncompress $bstr;  # '01110000'

is( $str, '01110000', 'uncompress() POD' );

}

use Test::More tests => 1;
