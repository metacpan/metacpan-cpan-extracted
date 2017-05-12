use Test::More tests => 1;

use Data::Pipeline::Action::Rename;

my $hash = {
    foo => 'bar',
    bar => 'baz',
    baz => 'foo'
};

Data::Pipeline::Action::Rename -> _copy( 'foo', 'far', $hash );

is( $hash->{'far'}, 'bar' );
