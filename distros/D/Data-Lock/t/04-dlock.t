#!perl -T
#
# $Id: 04-dlock.t,v 1.1 2013/05/13 15:31:54 dankogai Exp $
#
use strict;
use warnings;
use Data::Lock qw/dlock dunlock/;

#use Test::More 'no_plan';
use Test::More tests => 27;

{
    dlock( my $a = [ 0, 1, 2, 3 ] );
    is_deeply [ 0, 1, 2, 3 ], $a, '$a => [0,1,2,3]';
    eval { shift @$a };
    ok $@, $@;
    eval { $a->[0]-- };
    ok $@, $@;
    dunlock $a;
    eval { $a->[0]-- };
    ok !$@, '$a->[0]--';
    is_deeply [ -1, 1, 2, 3 ], $a, '$a => [-1,1,2,3]';
}
{
    my @a = (0, 1, 2, 3);
    dlock \@a;
    is_deeply [ 0, 1, 2, 3 ], \@a, '@a => (0,1,2,3)';
    eval { shift @a };
    ok $@, $@;
    eval { $a[0]-- };
    ok $@, $@;
    dunlock \@a;
    eval { $a[0]-- };
    ok !$@, '$a[0]--';
    is_deeply [ -1, 1, 2, 3 ], \@a, '@a => (-1,1,2,3)';
}
{
    dlock( my $h = { one => 1, two => 2 } );
    is_deeply { one => 1, two => 2 }, $h, '$h => {one=>1, two=>2}';
    eval { $h = {} };
    ok $@, $@;
    eval { $h->{one}-- };
    ok $@, $@;
    dunlock $h;
    eval { $h->{one}-- };
    ok !$@, '$h->{one}--';
    is_deeply { one => 0, two => 2 }, $h, '$h => {one=>0, two=>2}';
}
{
    my %h = (one => 1, two => 2);
    dlock \%h;
    is_deeply { one => 1, two => 2 }, \%h, '%h => (one=>1, two=>2)';
    eval { %h = () };
    ok $@, $@;
    eval { $h{one}-- };
    ok $@, $@;
    dunlock \%h;
    eval { $h{one}-- };
    ok !$@, '$h{one}--';
    is_deeply { one => 0, two => 2 }, \%h, '%h => (one=>0, two=>2)';
}
{
    my $a = [];
    $a->[0] = $a;
    dlock $a;
    eval { pop @$a };
    ok $@, $@;
    dunlock $a;
    eval { pop @$a };
    ok !$@ && @$a == 0, '$a => [$a]'
}
{
    dlock( my $s = 0 );
    eval { ++$s };
    ok $@, $@;
    dunlock $s;
    eval { ++$s };
    ok !$@, '++$s';
    is $s, 1, '$s => 1';
}
{
    eval { dlock "" };
    ok !$@, "dlock on constant is no-op";
    eval { dunlock "" };
    ok !$@, "dunlock on constant is no-op";
}

__END__
#SCALAR
ARRAY
HASH
#CODE
#REF
#GLOB
#LVALUE
#FORMAT
#IO
#VSTRING
#Regexp
