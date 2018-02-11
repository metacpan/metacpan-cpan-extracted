use 5.010;
use strict;
use warnings;
use Test::More 0.96;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use Data::Visitor::Tiny qw/visit/;

my $deep = {
    larry => {
        color   => 'red',
        fruit   => 'apple',
        friends => [ { name => 'Moe' }, { name => 'Curly' } ],
    },
    moe => {
        color   => 'yellow',
        fruit   => 'banana',
        friends => [ { name => 'Curly' } ],
    },
    curly => {
        color   => 'purple',
        fruit   => 'plum',
        friends => [ { name => 'Larry', nickname => 'Lray' } ],
    },
};

my @deep_leaves = qw(
  red apple Moe Curly yellow banana Curly purple plum Larry Lray
);

subtest "Callback gets arguments" => sub {
    my $input = { a => 1 };
    my $fcn = sub {
        my ( $k, $vr, $c ) = @_;
        ok( ref($k) eq '',        "arg 0 type correct" );
        ok( ref($vr) eq 'SCALAR', "arg 1 type correct" );
        ok( ref($c) eq 'HASH',    "arg 2 type correct" );
        is( $k,           'a', "arg 0 correct" );
        is( $$vr,         $_,  "arg 1 correct" );
        is( $c->{_depth}, 0,   "arg 2 correct" );
    };
    my @values;
    my $ret = visit( { a => 1 }, $fcn );
    is( $ret->{_depth}, 0, "visit returns the context" );
};

subtest "Depth context" => sub {
    my $input = { a => { b => { c => 1, d => 2 } } };
    my %seen;
    my $fcn = sub {
        my ( $k, undef, $c ) = @_;
        $seen{$k} = $c->{_depth};
    };
    my $exp = { a => 0, b => 1, c => 2, d => 2 };
    visit( $input, $fcn );
    is_deeply( \%seen, $exp, "Correct depth seen at each level" );
};

subtest "Transform input" => sub {
    my $input = { a => "a", b => { c => "c", d => [ qw/e f/, { g => "h" } ] } };
    my $fcn = sub {
        my ( undef, $vr ) = @_;
        return if ref;
        $$vr = uc($_);
    };
    my $exp = { a => "A", b => { c => "C", d => [ qw/E F/, { g => "H" } ] } };
    visit( $input, $fcn );
    is_deeply( $input, $exp, "Input transformed via scalarref" )
      or diag explain $input;
};

done_testing;

#
# This file is part of Data-Visitor-Tiny
#
# This software is Copyright (c) 2018 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:
