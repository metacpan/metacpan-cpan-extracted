#!perl

use strict;
use warnings;

use Test::More;

plan tests => 52;

use_ok( 'Class::Param::Callback' );
can_ok( 'Class::Param::Callback', 'get'    );
can_ok( 'Class::Param::Callback', 'set'    );
can_ok( 'Class::Param::Callback', 'add'    );
can_ok( 'Class::Param::Callback', 'has'    );
can_ok( 'Class::Param::Callback', 'clear'  );
can_ok( 'Class::Param::Callback', 'names'  );
can_ok( 'Class::Param::Callback', 'new'    );
can_ok( 'Class::Param::Callback', 'param'  );
can_ok( 'Class::Param::Callback', 'remove' );

my %store      = ();
my %callbacks  = (
    get    => sub { return $store{ $_[1] }          },
    set    => sub { return $store{ $_[1] } = $_[2]; },
    names  => sub { return keys %store              },
    remove => sub { return delete $store{ $_[1] }   }
);

isa_ok      my $p = Class::Param::Callback->new(%callbacks),   'Class::Param::Callback',      'Class::Param::Callback->new constructs a new instance';
is_deeply   [ $p->names ],                     [],             '->names returns an emplty list';
is_deeply   [ $p->param ],                     [],             '->param returns an emplty list';
is            $p->param('bogus'),              undef,          '->param on non existent name returns undef in scalar context';
is_deeply   [ $p->param('bogus') ],            [],             '->param on non existent name returns an empty list in list context';
is            $p->get('bogus'),                undef,          '->get on non existent name returns undef';
is            $p->remove('bogus'),             undef,          '->remove on non existent name returns undef';
is            $p->param( 'bogus' => undef ),   undef,          '->param( name => undef ) on non existent name returns undef';
is            $p->param(undef),                undef,          '->param with a undefined name returns undef in scalar context';
is_deeply   [ $p->param(undef) ],              [],             '->param with a undefined name returns an emply list in list context';
is            $p->count,                       0,              '->count on with no params';
ok          ! $p->has('bogus'),                                '->has on non existent name returns false';

my @array = ( 1 .. 3 );

ok            $p->param( A => 1 ),                             '->param  A : assign a scalar value';
is            $p->get('A'),                    1,              '->get    A : returns correct value';
is            $p->param('A'),                  1,              '->param  A : returns correct value';
is_deeply   [ $p->param('A') ],                [ 1 ],          '->param  A : returns a list with correct value in list context';
ok            $p->param( B => 1 .. 3 ),                        '->param  B : assign a list of values';
is_deeply     $p->get('B'),                    [ 1 .. 3 ],     '->get    B : returns an array with correct values';
is            $p->param('B'),                  1,              '->param  B : returns first value in scalar context';
is_deeply   [ $p->param('B') ],                [ 1 .. 3 ],     '->param  B : returns an list with correct values in list context';
ok            $p->param( C => [@array] ),                      '->param  C : assign array value';
is_deeply     $p->get('C'),                    \@array,        '->get    C : returns an array with same values';
ok            $p->add( 'C' => 4 ),                             '->add    C : a scalar value';
is_deeply     $p->get('C'),                    [ 1 .. 4 ],     '->get    C : returns an array with correct values';
ok            $p->add( 'C' => 5, 6 ),                          '->add    C : a list of values';
is_deeply     $p->get('C'),                    [ 1 .. 6 ],     '->get    C : returns an array with correct values';
ok            $p->add( 'D' => \@array ),                       '->add    D : a array to non existent name';
is_deeply     $p->get('D'),                    [ \@array ],    '->get    D : returns an array with correct values';
ok            $p->add( 'E' => @array ),                        '->add    E : a list to non existent name';
is_deeply     $p->get('E'),                    \@array ,       '->get    E : returns an array with correct values';
is_deeply     [ sort $p->names ],              [ 'A' .. 'E' ], '->names returns right names';
is_deeply     [ sort $p->param ],              [ 'A' .. 'E' ], '->param returns right names';

my $expected = {
    A => 1,
    B => [ 1 .. 3 ],
    C => [ 1 .. 6 ], 
    D => [ 1 .. 3 ],
    E => [ 1 .. 3 ]
};

is_deeply     scalar $p->as_hash,              $expected,      '->as_hash in scalar context';
is_deeply     { $p->as_hash },                 $expected,      '->as_hash in list context';
is            $p->count,                       5,              '->count returns correct count of params';
ok            $p->has('A'),                                    '->has A : returns true';
is            $p->remove('A'),                 1,              '->remove A : returns right value';
ok          ! $p->has('A'),                                    '->has A : returns false';
is_deeply     $p->remove('C'),                 [ 1 .. 6 ],     '->remove C : returns an array with removed values';
is_deeply     $p->param( 'B' => undef ),       [ 1 .. 3 ],     '->param B : returns an array with removed values';
ok            $p->clear,                                       '->clear';
is_deeply     scalar $p->as_hash,              {},             '->clear cleared all params';
