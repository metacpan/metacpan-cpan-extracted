use Test::More;
use Csistck;

plan tests => 2;

is(option('pkg_type', 'testing123'), 'testing123');
is(option('pkg_type'), 'testing123');

