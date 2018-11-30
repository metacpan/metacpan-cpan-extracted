
use Test::More
    tests => 2;

BEGIN {
    use_ok('CSS::Compressor' => qw( css_compress ) );
}

my $result = css_compress(<<'CSS');
some foo {
    /*! @noflip */ color: red;
}
CSS

is $result => 'some foo{color:red}' => 'match';

