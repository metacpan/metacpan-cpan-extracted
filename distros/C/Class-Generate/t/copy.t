#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test the copy() method.  The equals() method is used to
# do much of the testing.

use Class::Generate qw(&class);

class Basic_Class => [ mem => '@', new => { style => 'positional mem' } ];
class All_Types   => {
    Scalar       => "\$",
    Array        => '@',
    Hash         => '%',
    Scalar_Class => 'Basic_Class',
    Array_Class  => '@Basic_Class',
    Hash_Class   => '%Basic_Class'
};

use vars qw($v $w);
$v = new All_Types;
Test
{
    $v = ( new All_Types )->copy;
    !grep defined $v->$_(),
        qw(Scalar Array Hash Scalar_Class Array_Class Hash_Class)
};

Test { ( new All_Types )->equals( ( new All_Types )->copy ) };

Test
{
    $v = ( new All_Types Scalar => 1 )->copy;
    $v->Scalar == 1
};

Test
{
    ( new All_Types Scalar => 1 )->equals( ( new All_Types Scalar => 1 )->copy )
};

Test
{
    my @a = ( 1, 2, 3 );
    $v = ( new All_Types Array => [@a] )->copy;
    Arrays_Equal [ $v->Array ], [@a];
};

Test
{
    my %h = ( e1 => 1, e2 => 2 );
    $v = ( new All_Types Hash => {%h} )->copy;
    Arrays_Equal [ sort { $a cmp $b } $v->Hash ], [ sort { $a cmp $b } (%h) ];
};

Test
{
    my @a = ( 1, 2, 3 );
    $v = ( new All_Types Scalar_Class => ( new Basic_Class [@a] ) )->copy;
    Arrays_Equal [ $v->Scalar_Class->mem ], [@a];
};

Test
{
    my @a0 = ( 1, 2, 3 );
    my @a1 = ( 4, 5, 6 );
    $v = ( new All_Types Array_Class =>
            [ ( new Basic_Class [@a0] ), ( new Basic_Class [@a1] ) ] )->copy;
    (          $v->Array_Class_size == 1
            && Arrays_Equal( [ $v->Array_Class(0)->mem ], [@a0] )
            && Arrays_Equal( [ $v->Array_Class(1)->mem ], [@a1] ) );
};

Test
{
    my @a0 = ( 1, 2, 3 );
    my @a1 = ( 4, 5, 6 );
    $v = (
        new All_Types Hash_Class => {
            e1 => ( new Basic_Class [@a0] ),
            e2 => ( new Basic_Class [@a1] )
        }
    )->copy;
    (
        scalar( $v->Hash_Class_keys ) == 2
            && Arrays_Equal( [ sort { $a cmp $b } $v->Hash_Class_keys ],
            [qw(e1 e2)] )
            && Arrays_Equal( [ $v->Hash_Class('e1')->mem ], [@a0] )
            && Arrays_Equal( [ $v->Hash_Class('e2')->mem ], [@a1] )
    );
};

Test
{
    $v = new All_Types;
    $v->Scalar(1);
    $v->Array( [ 2, 3 ] );
    $v->Hash( { e1 => 3, e2 => 4 } );
    $v->Scalar_Class( new Basic_Class [ 5, 6 ] );
    $v->Array_Class( [ ( new Basic_Class [7] ), ( new Basic_Class [8] ) ] );
    $v->Hash_Class(
        { e1 => ( new Basic_Class [7] ), e2 => ( new Basic_Class [8] ) } );
    $v->equals( $v->copy );
};

Test
{
    class Picky_Copy => {
        Array => { type => '@', nocopy => 1 },
        Hash  => { type => '%', nocopy => 1 }
    };
    1;
};

Test
{
    $v = new Picky_Copy
        Array => [ 1, 2, 3 ],
        Hash  => { e1 => 4, e2 => 5 };
    $w = $v->copy;
    $v->equals($w) && $w->equals($v);
};

Test { $v->Array( 3, 4 ); $v->equals($w) };
Test
{
    $v->Hash( 'e3', 6 );
    $v->Hash( 'e1', 7 );
    $v->delete_Hash('e2');
    $v->equals($w);
};

Report_Results;

