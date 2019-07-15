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

use B;
use BSON;
use BSON::Types ':all';
use Devel::Peek;
use Scalar::Util qw/dualvar/;

my $pn0 = BSON->new( prefer_numeric => 0 );
my $pn1 = BSON->new( prefer_numeric => 1 );
my $dec = BSON->new( wrap_numbers   => 1, wrap_strings => 1 );

sub _flags {
    my $value = shift;
    return B::svref_2object( \$value )->FLAGS;
}

sub w_iv  { _flags(shift) & B::SVf_IOK }
sub wo_iv { _flags(shift) & ~B::SVf_IOK }
sub w_nv  { _flags(shift) & B::SVf_NOK }
sub wo_nv { _flags(shift) & ~B::SVf_NOK }
sub w_pv  { _flags(shift) & B::SVf_POK }

sub w_pviv   { w_pv( $_[0] ) && w_iv( $_[0] ) }
sub w_pvnv   { w_pv( $_[0] ) && w_nv( $_[0] ) }
sub w_pvonly { w_pv( $_[0] ) && !( w_iv( $_[0] ) || w_nv( $_[0] ) ) }

sub _dump {
    my $x = shift;
    my $dump;
    open my $fh, ">", \$dump;
    local *STDERR = $fh;
    Dump($x);
    return $dump;
}

sub _rt {
    my ( $encoder, $x ) = @_;
    return $dec->decode_one( $encoder->encode_one($x) );
}

# LABEL, INPUT, FLAGS, OUTPUT W/O PREFER_NUMERIC, OUTPUT W/ PREFER_NUMERIC
#
# Uses 'dualvar()' to construct duals because other forms of NV->PVNV
# conversion don't consistently set POK on all Perl versions.
my @cases = (
    [ 'Pure int',   42,   \&w_iv,     'BSON::Int32',  'BSON::Int32' ],
    [ 'String int', "42", \&w_pvonly, 'BSON::String', 'BSON::Int32' ],
    [ 'Dual int', dualvar( 42, "42" ), \&w_pviv, 'BSON::Int32', 'BSON::Int32' ],

    [ 'Pure double',   3.14,   \&w_nv,     'BSON::Double', 'BSON::Double' ],
    [ 'String double', "3.14", \&w_pvonly, 'BSON::String', 'BSON::Double' ],
    [ 'Dual double', dualvar( 3.14, "3.14" ), \&w_pvnv, 'BSON::Double', 'BSON::Double' ],
);

for my $c (@cases) {
    my ( $label, $x, $type_chk, $y0, $y1 ) = @$c;
    ok( $type_chk->($x), "$label: SvTYPE(s)" ) or diag _dump($x);
    my $doc = { x => $x };

    for my $enc ( [ "prefer_numeric=0", $pn0, $y0 ], [ "prefer_numeric=1", $pn1, $y1 ] )
    {
        my $rt_x = _rt( $enc->[1], $doc )->{x};
        is( ref($rt_x), $enc->[2], "$label: $enc->[0]" );
        like( $rt_x->value, qr/\Q$x\E/, "$label: value matches $x" );
    }
}

done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2019 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:
