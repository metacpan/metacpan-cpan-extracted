
use Test::More
    tests => 2;

BEGIN {
    use_ok('CSS::Compressor' => qw( css_compress ) );
}

my $result = css_compress(<<CSS);
/* calc test */
p + p {
    width: calc(100vw - 20px + 11%);
    height: calc(100vh + 10px - 5%);
    top: calc(100% / 3 * 2);
    left: calc(10% * var(--foo) + 10px);
}
CSS

is $result => 'p+p{width:calc(100vw - 20px + 11%);height:calc(100vh + 10px - 5%);top:calc(100% / 3 * 2);left:calc(10% * var(--foo) + 10px)}' => 'match';

