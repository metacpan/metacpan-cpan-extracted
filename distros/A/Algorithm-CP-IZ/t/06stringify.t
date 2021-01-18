use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Algorithm::CP::IZ') };

# const
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(123);

    my $s1 = $v->stringify;
    my $s2 = "$v";

    is($s1, "123");
    is($s2, "123");
}

# single range
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(-1, 5);

    my $s1 = $v->stringify;
    my $s2 = "$v";

    is($s1, "{-1..5}");
    is($s2, "{-1..5}");
}

# 2 ranges
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(-10, 50);

    $v->Neq(12);

    my $s1 = $v->stringify;
    my $s2 = "$v";

    is($s1, "{-10..11, 13..50}");
    is($s2, "{-10..11, 13..50}");
}

# 3 ranges
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(-10, 50);

    $v->Neq(12);

    $v->Neq(32);
    $v->Neq(33);
    $v->Neq(34);

    my $s1 = $v->stringify;
    my $s2 = "$v";

    is($s1, "{-10..11, 13..31, 35..50}");
    is($s2, "{-10..11, 13..31, 35..50}");
}

# many values
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int([1, 3, 5, 7, 9]);

    my $s1 = $v->stringify;
    my $s2 = "$v";

    is($s1, "{1, 3, 5, 7, 9}");
    is($s2, "{1, 3, 5, 7, 9}");
}

# large
{
    my $iz = Algorithm::CP::IZ->new();
    my $v = $iz->create_int(-1000000, 1000000);

    $v->Neq(0);

    my $s1 = $v->stringify;
    my $s2 = "$v";

    is($s1, "{-1000000..-1, 1..1000000}");
    is($s2, "{-1000000..-1, 1..1000000}");
}
