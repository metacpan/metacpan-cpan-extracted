#!perl -T
#
# $Id: 02-avhv.t,v 1.0 2013/04/03 06:49:25 dankogai Exp $
#
use strict;
use warnings;
use Attribute::Constant;
#use Test::More 'no_plan';
use Test::More tests => 18;

{
    my @a : Constant( 0, 1, 2, 3 );
    is_deeply [ 0, 1, 2, 3 ], \@a, '@a => (0,1,2,3)';
    eval { shift @a };
    ok $@, $@;
    eval { $a[0]-- };
    ok $@, $@;
    my $a : Constant([ 0, 1, 2, 3 ]);
    is_deeply [ 0, 1, 2, 3 ], $a, '$a => [0,1,2,3]';
    eval { shift @$a };
    ok $@, $@;
    eval { $a->[0]-- };
    ok $@, $@;
    my $aa : Constant([ 0, [ 1, [ 2, [3] ] ] ]);
    is_deeply [ 0, [ 1, [ 2, [3] ] ] ], $aa, '$aa => [0,[1,[2,[3]]]]';
    eval { shift @$aa };
    ok $@, $@;
    eval { $aa->[1][1][1][0]-- };
    ok $@, $@;
}
{
    my %h : Constant( one => 1, two => 2 );
    is_deeply { one => 1, two => 2 }, \%h, '%h => (one=>1, two=>2)';
    eval { %h = ( three => 3 ) };
    ok $@, $@;
    eval { $h{one}-- };
    ok $@, $@;
    my $h : Constant({ one => 1, two => 2 });
    is_deeply { one => 1, two => 2 }, $h, '$h => {one=>1, two=>2}';
    eval { $h = { three => 3 } };
    ok $@, $@;
    eval { $h->{one}-- };
    ok $@, $@;
    my $hh : Constant({ one => 1, two => { be => 2 } });
    is_deeply { one => 1, two => { be => 2 } }, $hh,
	'$hh => {one=>1, two=>{three=>3}}';
    eval { $h = { three => 3 } };
    ok $@, $@;
    eval { $h->{one}++};
    ok $@, $@;
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

