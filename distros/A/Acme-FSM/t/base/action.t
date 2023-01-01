# $Id: action.t 481 2013-02-17 02:09:10Z whynot $
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
use Test::More tests => 14;

use Acme::FSM;

our( $bb, $rc, $stderr );
my $method = q|action|;

my( $old, $new ) = qw| VOID champagne |;
AFSMTS_class_wrap { diag_level => 10 };
isa_ok $bb, q|Acme::FSM|, q|constructed object|;
is $bb->{_}{action}, $old, qq|initial {action} isa ($old)|;

my $tag = q|no args,|;
AFSMTS_method_wrap $method;
is $rc, $old, qq|$tag {action} is returned|;
is $bb->{_}{action}, $old, qq|$tag correct|;

$tag = q|one arg,|;
AFSMTS_method_wrap $method, $new;
is $bb->{_}{action}, $new, qq|$tag new {action} is set|;
is $rc, $old, qq|$tag old {action} is returned|;
like $stderr, qr<(?m)^\Q[action]: changing action: ($old) ($new)>,
  qq|$tag noted|;

$tag = q|other arg,|;
( $old, $new ) = ( $new, q|ale| );
AFSMTS_method_wrap $method, $new;
is $bb->{_}{action}, $new, qq|$tag new {action} is set again|;
is $rc, $old, qq|$tag old {action} is returned again|;
like $stderr, qr<(?m)^\Q[action]: changing action: ($old) ($new)>,
  qq|$tag noted|;

$tag = q|two args,|;
AFSMTS_method_wrap $method, qw| rum porter |;
is $bb->{_}{action}, $new, qq|$tag old {action} stays|;
ok !defined $rc, qq|$tag ((undef)) is returned|;
like $stderr, qr<(?m)^\Q[action]: too many args (2) >, qq|$tag noted|;
AFSMTS_method_wrap $method;
is $rc, $new, qq|$tag {action} stays|;

# vim: set filetype=perl
