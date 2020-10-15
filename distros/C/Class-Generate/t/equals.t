#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test the equals() method.

use Class::Generate qw(&class);

class Basic_Class => [ mem => "\$", new => { style => 'positional mem' } ];
class No_Key      => {
    Scalar       => "\$",
    Array        => '@',
    Hash         => '%',
    Scalar_Class => 'Basic_Class',
    Array_Class  => '@Basic_Class',
    Hash_Class   => '%Basic_Class'
};

use vars qw($v $w);
$v = new No_Key
    Scalar       => 1,
    Array        => [ 2, 3 ],
    Hash         => { e1 => 4, e2 => 5 },
    Scalar_Class => ( new Basic_Class 6 ),
    Array_Class  => [ ( new Basic_Class 7 ), ( new Basic_Class 8 ) ],
    Hash_Class   => {
    e1 => ( new Basic_Class 9 ),
    e2 => ( new Basic_Class 10 )
    };
Test { $v->equals( $v->copy ) };
Test { !$v->equals( new No_Key ) };
Test { !$v->equals( new No_Key Scalar       => 1 ) };
Test { !$v->equals( new No_Key Array        => [ 2, 3 ] ) };
Test { !$v->equals( new No_Key Hash         => { e1 => 4, e2 => 5 } ) };
Test { !$v->equals( new No_Key Scalar_Class => ( new Basic_Class 6 ) ) };
Test
{
    !$v->equals( new No_Key Array_Class =>
            [ ( new Basic_Class 7 ), ( new Basic_Class 8 ) ] )
};
Test
{
    !$v->equals(
        new No_Key Hash_Class => {
            e1 => ( new Basic_Class 9 ),
            e2 => ( new Basic_Class 10 )
        }
    )
};

Test
{
    class Scalar_Key => {
        Scalar       => { type => "\$", key => 1 },
        Array        => '@',
        Hash         => '%',
        Scalar_Class => 'Basic_Class',
        Array_Class  => '@Basic_Class',
        Hash_Class   => '%Basic_Class'
    };
    $v = new Scalar_Key Scalar => 1, Array => [ 2, 3 ];
    (          $v->equals( new Scalar_Key Scalar => 1, Array => [ 2, 3 ] )
            && $v->equals( new Scalar_Key Scalar  => 1, Array => [ 3, 4 ] )
            && !$v->equals( new Scalar_Key Scalar => 2 ) );
};

Test
{
    class Two_Keys => {
        Scalar       => "\$",
        Array        => { type => '@', key => 1 },
        Hash         => '%',
        Scalar_Class => { type => '$Basic_Class', key => 1 },
        Array_Class  => '@Basic_Class',
        Hash_Class   => '%Basic_Class'
    };
    $v = new Two_Keys
        Scalar       => 1,
        Array        => [ 2, 3 ],
        Scalar_Class => ( new Basic_Class 4 );
    (
        $v->equals(
            new Two_Keys
                Array => [ 2, 3 ],
            Scalar_Class => ( new Basic_Class 4 )
            )
            && !$v->equals(
            new Two_Keys
                Array => [ 3, 4 ],
            Scalar_Class => ( new Basic_Class 4 )
            )
            && !$v->equals(
            new Two_Keys
                Array => [ 2, 3 ],
            Scalar_Class => ( new Basic_Class 5 )
            )
            && !$v->equals( new Two_Keys Array        => [ 2, 3 ] )
            && !$v->equals( new Two_Keys Scalar_Class => ( new Basic_Class 4 ) )
    );
};

Report_Results;

