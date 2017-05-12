use strict;
use warnings;
use Test::More tests => 36;

use lib '../lib';

use Begin::Declare;

{
    MY $x = 3; eval 'is $x, 3'; BEGIN {eval 'is $x, 3'}

    MY ($y, $z) = (4, 5); eval 'is "$x $y $z", "3 4 5"'; BEGIN {eval 'is "$x $y $z", "3 4 5"'}

    MY @array = 1 .. 4; eval 'is "@array", "1 2 3 4"';   BEGIN {eval 'is "@array", "1 2 3 4"'}

    MY ($q, %hash) = ('qqq', a => 1, b => 2);
    BEGIN {
        eval 'is $q, "qqq"';
        eval 'is join(" ", sort keys %hash), "a b"';
    }
    eval 'is $q, "qqq"';
    eval 'is join(" ", sort keys %hash), "a b"';
}

{
    OUR $x = 3; eval 'is $x, 3'; BEGIN {eval 'is $x, 3'}

    OUR ($y, $z) = (4, 5); eval 'is "$x $y $z", "3 4 5"'; BEGIN {eval 'is "$x $y $z", "3 4 5"'}

    OUR @array = 1 .. 4; eval 'is "@array", "1 2 3 4"';   BEGIN {eval 'is "@array", "1 2 3 4"'}

    OUR ($q, %hash) = ('qqq', a => 1, b => 2);
    BEGIN {
        eval 'is $q, "qqq"';
        eval 'is join(" ", sort keys %hash), "a b"';
    }
    eval 'is $q, "qqq"';
    eval 'is join(" ", sort keys %hash), "a b"';
}

{
    {
        MY
        (
            $
            x
            ,
            $
            y
            ,
            $
            z
            ,
        )
        =
        (
            11,
            22,
            33,
        )
        ;
        BEGIN {eval 'is "$x $y $z", "11 22 33"'}
        eval 'is "$x $y $z", "11 22 33"';
    }
    {
        OUR
        $
        x1
        =
        11
        ;
        BEGIN {eval 'is $x1, 11'}
        eval 'is $x1, 11';
    }
}

{
    my $ret = MY $RET = 5;
    is $ret, 5;
    eval 'is $RET, 5';
    BEGIN {eval 'is $RET, 5'}
}

{
    my @ret = MY ($a, $b, @c) = 1 .. 5;
    is "@ret", '1 2 3 4 5';
    eval 'is "@c $a $b", "3 4 5 1 2"';
    BEGIN {eval 'is "@c $a $b", "3 4 5 1 2"'}
}

{
    my $ret = OUR $RET = 5;
    is $ret, 5;
    eval 'is $RET, 5';
    BEGIN {eval 'is $RET, 5'}
}

{
    my @ret = OUR ($ax, $bx, @cx) = 1 .. 5;
    is "@ret", '1 2 3 4 5';
    eval 'is "@cx $ax $bx", "3 4 5 1 2"';
    BEGIN {eval 'is "@cx $ax $bx", "3 4 5 1 2"'}
}
