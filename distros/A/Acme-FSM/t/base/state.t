# $Id: state.t 481 2013-02-17 02:09:10Z whynot $
# Copyright 2012, 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::TestSuite::FSM;
use parent q|Acme::FSM|;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.1 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 10;

use Acme::FSM;

our( $bb, $rc, $stderr );
my $method = q|state|;

my( $old, $new ) = qw| START OK |;
AFSMTS_class_wrap { diag_level => 10 };
isa_ok $bb, q|Acme::FSM|, q|constructed object|;
is $bb->{_}{state}, $old, qq|initial {state} isa ($old)|;

my $tag = q|no args,|;
AFSMTS_method_wrap $method;
is_deeply [ $rc, $bb->{_}{state} ], [ $old, $old ], qq|$tag queried|;

$tag = q|one arg,|;
AFSMTS_method_wrap $method, $new;
is_deeply [ $rc, $bb->{_}{state} ], [ $old, $new ], qq|$tag queried|;
like $stderr, qr<(?m)^\Q[state]: changing state: ($old) ($new)>,
  qq|$tag noted|;

$tag = q|other arg,|;
( $old, $new ) = ( $new, q|APOP| );
AFSMTS_method_wrap $method, $new;
is_deeply [ $rc, $bb->{_}{state} ], [ $old, $new ], qq|$tag queried|;
like $stderr, qr<(?m)^\Q[state]: changing state: ($old) ($new)>,
  qq|$tag noted|;

$tag = q|two args,|;
AFSMTS_method_wrap $method, qw| LIST PASS |;
is_deeply [ !defined $rc, $bb->{_}{state} ], [ !0, $new ], qq|$tag queried|;
like $stderr, qr<(?m)^\Q[state]: too many args (2) >, qq|$tag noted|;
AFSMTS_method_wrap $method;
is $rc, $new, qq|$tag {state} stays|;

# vim: set filetype=perl
