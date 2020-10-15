#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test all basic member types:
#   --	Create object instance.
#   --	Access existing values using all relevant accessors
#   --	Modify existing values using all relevant accessors
use A_Class;
A_Class::init();

use Class::Generate qw(&class);

Test
{
    class All_Member_Types => {
        Scalar         => "\$",
        Array          => '@',
        Hash           => '%',
        Scalar_Class_1 => 'A_Class',
        Scalar_Class_2 => '$A_Class',
        Array_Class    => '@A_Class',
        Hash_Class     => '%A_Class'
    };
};

use vars qw($v);

Test { $v = new All_Member_Types };

Test { $v->Scalar(1);    $v->Scalar == 1 };
Test { $v->undef_Scalar; !defined $v->Scalar };

Test
{
    $v->Array( [ 1, 2, 3, 4 ] );
    for ( 1 .. 4 ) { die unless $v->Array( $_ - 1 ) == $_ }
    1
};
Test
{
    $v->add_Array(5);
    $v->add_Array( 6, 7, 8 );
    $v->add_Array;
    $v->Array( 8, 9 );
    $v->Array( 0, 88 );
    (          $v->Array_size == 8
            && Arrays_Equal( [ $v->Array ], [ 88, 2 .. 9 ] )
            && $v->last_Array == 9 )
};
Test { $v->undef_Array; $v->Array_size == -1 && !defined $v->last_Array };

Test
{
    my @sample = ( e1 => 1, e2 => 2 );
    $v->Hash( {@sample} );
    (
               Arrays_Equal( [ sort { $a cmp $b } $v->Hash_keys ], [qw(e1 e2)] )
            && Arrays_Equal( [ sort { $a <=> $b } $v->Hash_values ], [ 1, 2 ] )
            && $v->Hash('e1') == 1
            && $v->Hash('e2') == 2
            && Arrays_Equal(
            [ sort { $a cmp $b } $v->Hash ],
            [ sort { $a cmp $b } @sample ]
            )
    )
};

Test { $v->undef_Hash; !defined $v->Hash };

Test
{
    $v->Hash( { map { ( "e$_" => $_ ) } 1 .. 10 } );
    $v->delete_Hash('e1');
    Arrays_Equal [ sort { $a <=> $b } map substr( $_, 1 ), $v->Hash_keys ],
        [ 2 .. 10 ]
};

Test
{
    $v->delete_Hash( map { "e$_" } 2 .. 4 );
    Arrays_Equal [ sort { $a <=> $b } map substr( $_, 1 ), $v->Hash_keys ],
        [ 5 .. 10 ]
};

Test
{
    $v->delete_Hash;
    Arrays_Equal [ sort { $a <=> $b } map substr( $_, 1 ), $v->Hash_keys ],
        [ 5 .. 10 ]
};

Test { $v->Scalar_Class_1( new A_Class ); $v->Scalar_Class_1->value == 1 };
Test { $v->Scalar_Class_2( new A_Class ); $v->Scalar_Class_2->value == 2 };

Test
{
    $v->Array_Class( [ new A_Class, new A_Class ] );
    Arrays_Equal [ map $_->value, $v->Array_Class ], [ 3, 4 ]
};

Test
{
    $v->Array_Class( 2, new A_Class );
    Arrays_Equal [ map $_->value, $v->Array_Class ], [ 3 .. 5 ]
};
Test
{
    $v->Hash_Class( { e1 => new A_Class, e2 => new A_Class } );
    my @keys = sort { $a cmp $b } $v->Hash_Class_keys;
    Arrays_Equal [ map $v->Hash_Class($_)->value, @keys ], [ 6, 7 ]
};
Test
{
    $v->Hash_Class( 'e3', new A_Class );
    my @keys = sort { $a cmp $b } $v->Hash_Class_keys;
    Arrays_Equal [ map $v->Hash_Class($_)->value, @keys ], [ 6, 7, 8 ]
};

Report_Results;
