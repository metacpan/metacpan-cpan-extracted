#!/usr/bin/env perl
use Test2::V0;
use strict;
use warnings;

use Data::Xslate;

my $xslate = Data::Xslate->new();

my @tests = (
    [
        { a=>1, b=>'=a' },
        { a=>1, b=>1 },
        'basic substituion',
    ],
    [
        { a=>1, b=>'b is <: $a :>!' },
        { a=>1, b=>'b is 1!' },
        'basic concatination',
    ],
    [
        { a=>'A', b=>{ c=>{ d=>'=bb' }, bb=>'BB' } },
        { a=>'A', b=>{ c=>{ d=>'BB' }, bb=>'BB' } },
        'complex substition',
    ],
    [
        { a=>'A', b=>{ c=>q[C<: node('a') :><: $a :>], d=>q[D<: node('c') :><: $c :>] } },
        { a=>'A', b=>{ c=>'CAA', d=>'DCAACAA' } },
        'complex concatination',
    ],
    [
        { a=>1, b=>{ a=>2, a_local=>'=a', a_root=>'=.a' } },
        { a=>1, b=>{ a=>2, a_local=>2, a_root=>1 } },
        'absolute versus relative substitution',
    ],
    [
        { a=>{b=>1,c=>2}, 'a.b='=>'=c' },
        { a=>{b=>2,c=>2} },
        'foo',
    ],
);

foreach my $test (@tests) {
    my ($input, $expected, $message) = @$test;

    is(
        $xslate->render( $input ),
        $expected,
        $message,
    );
}

done_testing;
