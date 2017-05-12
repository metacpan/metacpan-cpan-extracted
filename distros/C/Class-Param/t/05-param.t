#!perl

use strict;
use warnings;

use Test::More;

plan tests => 53;

use_ok( 'Class::Param' );
can_ok( 'Class::Param', 'get'    );
can_ok( 'Class::Param', 'set'    );
can_ok( 'Class::Param', 'add'    );
can_ok( 'Class::Param', 'has'    );
can_ok( 'Class::Param', 'clear'  );
can_ok( 'Class::Param', 'names'  );
can_ok( 'Class::Param', 'new'    );
can_ok( 'Class::Param', 'param'  );
can_ok( 'Class::Param', 'remove' );


isa_ok      my $p1 = Class::Param->new,         'Class::Param', '->new constructs a new instance';
is_deeply   [ $p1->names ],                     [],             '->names returns an emplty list';
is_deeply   [ $p1->param ],                     [],             '->param returns an emplty list';
is            $p1->param('bogus'),              undef,          '->param on non existent name returns undef in scalar context';
is_deeply   [ $p1->param('bogus') ],            [],             '->param on non existent name returns an empty list in list context';
is            $p1->get('bogus'),                undef,          '->get on non existent name returns undef';
is            $p1->remove('bogus'),             undef,          '->remove on non existent name returns undef';
is            $p1->param( 'bogus' => undef ),   undef,          '->param( name => undef ) on non existent name returns undef';
is            $p1->param(undef),                undef,          '->param with a undefined name returns undef in scalar context';
is_deeply   [ $p1->param(undef) ],              [],             '->param with a undefined name returns an emply list in list context';
is            $p1->count,                       0,              '->count on with no params';
ok          ! $p1->has('bogus'),                                '->has on non existent name returns false';

my @array  = ( 0 .. 3 );
my @assign = ( 0 .. 3 );

isa_ok        my $p2 = $p1->new,                'Class::Param', '->new on instance constructs a new instance';
ok            $p2->param( A => 0 ),                             '->param  A : assign a scalar value';
is            $p2->get('A'),                    0,              '->get    A : returns correct value';
is            $p2->param('A'),                  0,              '->param  A : returns correct value';
is_deeply   [ $p2->param('A') ],                [ 0 ],          '->param  A : returns a list with correct value in list context';
ok            $p2->param( B => 0 .. 3 ),                        '->param  B : assign a list of values';
is_deeply     $p2->get('B'),                    [ 0 .. 3 ],     '->get    B : returns an array with correct values';
is            $p2->param('B'),                  0,              '->param  B : returns first value in scalar context';
is_deeply   [ $p2->param('B') ],                [ 0 .. 3 ],     '->param  B : returns an list with correct values in list context';
ok            $p2->param( C => \@assign ),                      '->param  C : assign array value';
ok            $p2->get('C') == \@assign,                        '->get    C : returns same array';
is_deeply     $p2->get('C'),                    \@array,        '->get    C : returns an array with same values';
ok            $p2->add( 'C' => 4 ),                             '->add    C : a scalar value';
is_deeply     $p2->get('C'),                    [ 0 .. 4 ],     '->get    C : returns an array with correct values';
ok            $p2->add( 'C' => 5, 6 ),                          '->add    C : a list of values';
is_deeply     $p2->get('C'),                    [ 0 .. 6 ],     '->get    C : returns an array with correct values';
ok            $p2->add( 'D' => \@array ),                       '->add    D : a array to non existent name';
is_deeply     $p2->get('D'),                    [ \@array ],    '->get    D : returns an array with correct values';
ok            $p2->add( 'E' => @array ),                        '->add    E : a list to non existent name';
is_deeply     $p2->get('E'),                    \@array ,       '->get    E : returns an array with correct values';
is_deeply     [ sort $p2->names ],              [ 'A' .. 'E' ], '->names returns right names';
is_deeply     [ sort $p2->param ],              [ 'A' .. 'E' ], '->param returns right names';

my $expected = {
    A => 0,
    B => [ 0 .. 3 ],
    C => [ 0 .. 6 ], 
    D => [ 0 .. 3 ],
    E => [ 0 .. 3 ]
};

is_deeply     scalar $p2->as_hash,              $expected,      '->as_hash in scalar context';
is_deeply     { $p2->as_hash },                 $expected,      '->as_hash in list context';
is            $p2->count,                       5,              '->count returns correct count of params';
ok            $p2->has('A'),                                    '->has A : returns true';
is            $p2->remove('A'),                 0,              '->remove A : returns right value';
is_deeply     $p2->remove('C'),                 [ 0 .. 6 ],     '->remove C : returns an array with removed values';
is_deeply     $p2->param( 'B' => undef ),       [ 0 .. 3 ],     '->param B : returns an array with removed values';
ok            $p2->clear,                                       '->clear';
is_deeply     scalar $p2->as_hash,              {},             '->clear cleared all params';
