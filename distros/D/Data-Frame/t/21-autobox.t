#!perl

use Data::Frame::Setup;

use Test2::V0;

ok( []->isempty, '$array->isempty' );
ok( !( [ 1, 2, 3 ]->isempty ), '$array->isempty' );

my $array = [ 1, 2, 3 ];
$array->set( 1, 0 );
is( $array, [ 1, 0, 3 ], '$array->set' );

my @repeat_cases = (
    {
        params => [ [], 3 ],
        out => [],
    },
    {
        params => [ [ 1, 2, 3 ], 3 ],
        out => [ 1, 2, 3, 1, 2, 3, 1, 2, 3 ],
    },
);

for (@repeat_cases) {
    my $array = $_->{params}[0];
    my $n     = $_->{params}[1];
    is( $array->repeat($n), $_->{out}, '$array->repeat' );
}

my @repeat_to_length_cases = (
    {
        params => [ [], 3 ],
        out => [],
    },
    {
        params => [ [ 1, 2, 3 ], 2 ],
        out => [ 1, 2 ],
    },
    {
        params => [ [ 1, 2, 3 ], 5 ],
        out => [ 1, 2, 3, 1, 2 ],
    },
);
for (@repeat_to_length_cases) {
    my $array = $_->{params}[0];
    my $n     = $_->{params}[1];
    is( $array->repeat_to_length($n), $_->{out}, '$array->repeat_to_length' );
}

subtest array_setops => sub { 
    is(
        [ 'a' .. 'e' ]->intersect([ 'd' .. 'f' ]),
        [ 'd', 'e' ],
        'intersect()'
    );
    is(
        [ 'a' .. 'e' ]->setdiff([ 'd' .. 'f' ]),
        [ 'a' .. 'c' ],
        'setdiff()'
    );
    is(
        [ 'a' .. 'e' ]->union([ 'd' .. 'f' ]),
        [ 'a' .. 'f' ],
        'union()'
    );
};

ok( {}->isempty, '$hash->isempty' );
ok( !( { one => 1 }->isempty ), '$hash->isempty' );
is( {}->names, [], '$hash->names' );
is( { one => 1 }->names, ['one'], '$hash->names' );

{
    my $hash = { one => 1 };
    $hash->set( 'two', 2 );
    is( $hash, { one => 1, two => 2 }, '$hash->set' );
}

{
    my $hash = { a => 1, b => 2, c => 3 };  
    is(
        $hash->rename( { a => 'x', c => 'y' } ),
        { x => 1, b => 2, y => 3 },
        '$hash->rename($href)'
    );
    is(
        $hash->rename( sub { $_[0] . '_foo'} ),
        { a_foo => 1, b_foo => 2, c_foo => 3 },
        '$hash->rename($coderef)'
    );
}

done_testing;
