use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use PVTests;
use Test::Fatal;
use Test::More;

use Attribute::Params::Validate;
use Params::Validate qw(:all);

sub foo : Validate( c => { type => SCALAR } ) {
    my %data = @_;
    return $data{c};
}

sub bar : Validate( c => { type => SCALAR } ) method {
    my $self = shift;
    my %data = @_;
    return $data{c};
}

sub baz :
    Validate( foo => { type => ARRAYREF, callbacks => { '5 elements' => sub { @{shift()} == 5 } } } )
{
    my %data = @_;
    return $data{foo}->[0];
}

sub buz : ValidatePos( 1 ) {
    return $_[0];
}

sub quux : ValidatePos( { type => SCALAR }, 1 ) {
    return $_[0];
}

{
    my $res;
    is(
        exception { $res = foo( c => 1 ) },
        undef,
        'Call foo with a scalar'
    );

    is(
        $res, 1,
        'Check return value from foo( c => 1 )'
    );

    like(
        exception { foo( c => [] ) },
        qr/The 'c' parameter .* was an 'arrayref'/,
        'Check exception thrown from foo( c => [] )'
    );
}

{
    my $res;
    is(
        exception { $res = main->bar( c => 1 ) },
        undef,
        'Call bar with a scalar'
    );

    is(
        $res, 1,
        'Check return value from bar( c => 1 )'
    );
}

{
    like(
        exception { baz( foo => [ 1, 2, 3, 4 ] ) },
        qr/The 'foo' parameter .* did not pass the '5 elements' callback/,
        'Check exception thrown from baz( foo => [1,2,3,4] )'
    );
}

{
    my $res;
    is(
        exception { $res = baz( foo => [ 5, 4, 3, 2, 1 ] ) },
        undef,
        'Call baz( foo => [5,4,3,2,1] )'
    );

    is(
        $res, 5,
        'Check return value from baz( foo => [5,4,3,2,1] )'
    );
}

{
    like(
        exception { buz( [], 1 ) },
        qr/2 parameters were passed to .* but 1 was expected/,
        'Check exception thrown from quux( [], 1 )'
    );
}

{
    my $res;

    is(
        exception { quux( 1, [] ) },
        undef,
        'Call quux'
    );
}

done_testing();
