use Test::More;

use Data::Bvec qw( compress );

POD: {

    my $bstr;
    $bstr = compress '01110000';  # '-134'

is( $bstr, '-134', 'compress() -134 POD' );

    my $str = ('1'x100).('0'x30).('1'x6);
    $bstr = compress $str;        # '+@1cU6'

is( $bstr, '+@1cU6', 'compress() +@1cU6 POD' );

}

use Test::More tests => 2;
