#!perl

use strict;
use warnings;

use Test::More;

plan tests => 37;

use_ok( 'Class::Param'                );
use_ok( 'Class::Param::Tie'           );
can_ok( 'Class::Param::Tie', 'get'    );
can_ok( 'Class::Param::Tie', 'set'    );
can_ok( 'Class::Param::Tie', 'add'    );
can_ok( 'Class::Param::Tie', 'has'    );
can_ok( 'Class::Param::Tie', 'clear'  );
can_ok( 'Class::Param::Tie', 'names'  );
can_ok( 'Class::Param::Tie', 'new'    );
can_ok( 'Class::Param::Tie', 'param'  );
can_ok( 'Class::Param::Tie', 'remove' );


isa_ok      my $p1 = Class::Param->new,           'Class::Param',      'Class::Param->new constructs a new instance';
isa_ok      my $p2 = Class::Param::Tie->new($p1), 'Class::Param::Tie', 'Class::Param::Tie->new constructs a new instance';

my @array = ( 0 .. 3 );

ok            $p2->param( A => 0 ),                                    '->param  A : assign a scalar value';
is            $p2->{'A'},                         0,                   '->{name} A : returns correct value';
is            $p2->param('A'),                    0,                   '->param  A : returns correct value';
ok            $p2->{'B'} = [ 0 .. 3 ],                                 '->{name} B : assign an array of values';
is_deeply     $p2->get('B'),                      [ 0 .. 3 ],          '->get    B : returns an array with correct values';
is            $p2->param('B'),                    0,                   '->param  B : returns first value in scalar context';
is_deeply     $p2->{'B'},                         [ 0 .. 3 ],          '->{name} B : returns an array with correct values ';
ok            $p2->{'C'} = \@array,                                    '->{name} C : assign array value';
is_deeply     $p2->{'C'},                         [ @array ],          '->{name} C : returns an array with same values';
ok            $p2->{'C'} == \@array,                                   '->{name} C : correctly returns the same array';
ok            $p2->add( 'C' => 4 ),                                    '->add    C : a scalar value';
is_deeply     $p2->{'C'},                         [ 0 .. 4 ],          '->{name} C : returns an array with correct values';
ok            $p2->add( 'C' => [ 5, 6 ] ),                             '->add    C : a array value';
is_deeply     $p2->{'C'},                         [ 0 .. 4, [ 5, 6] ], '->{name} C : returns an array with correct values';
ok            $p2->add( 'D' => 0 ),                                    '->add    D : a scalar to non existent name';
is_deeply     $p2->{'D'},                         0,                   '->{name} D : returns correct value value';
ok            $p2->add( 'E' => \@array ),                              '->add    E : a array to non existent name';
is_deeply     $p2->{'E'},                         [ \@array ],         '->{name} E : returns an array with correct values';
ok            $p2->{'E'} != \@array,                                   '->add    E : correctly dereferenceded array';
eq_set        [ keys %$p2 ],                      [ 'A' .. 'E' ],      'got right keys';
eq_set        [ values %$p2 ],                    [ values %$$p1 ],    'got right values';
is_deeply     { %{ $p2 } },                       $$p1,                'p2 has right params';
is_deeply     delete $p2->{'B'},                  [ 0 .. 3 ],          '->{name} B : delete returns an array with removed values';
is            scalar %$p2,                        $p2->count,          'scalar on tied hash returns count';
ok            exists $p2->{'A'},                                       'exists A returns right value';
ok          ! exists $p2->{'B'},                                       'exists B returns right value';
