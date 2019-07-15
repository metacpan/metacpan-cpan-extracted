use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestUtils;

use BSON;
use BSON::Types ':all';

my $c = BSON->new;

my $q = {};
$q->{'q'} = $q;

eval { $c->encode_one($q); };

like( $@, qr/circular ref/, "circular hashref" );

my %test;
tie %test, 'Tie::IxHash';
$test{t} = \%test;

eval { $c->encode_one( \%test ); };

like( $@, qr/circular ref/, "circular tied hashref" );

my $tie = Tie::IxHash->new;
$tie->Push( "t" => $tie );

eval { $c->encode_one($tie); };

like( $@, qr/circular ref/, "circular Tie::IxHash object" );

# Multiple deep cycles
my $inner1 = { Z1 => { X => 1 } };
my $inner2 = { Z2 => { Y => 2 } };
$inner1->{inner2} = $inner2;
$inner2->{inner1} = $inner1;
my $outer = { A => $inner1, B => $inner2 };
eval { $c->encode_one($outer); };

like( $@, qr/circular ref/, "circular deep object" );

done_testing;

#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:
