# $Id: carp.t 482 2013-03-08 22:47:45Z whynot $
# Copyright 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::TestSuite::FSM;
use parent q|Acme::FSM|;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.2 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 6;

use Acme::FSM;

our( $bb, $stderr );
my $method = q|carp|;

AFSMTS_class_wrap { diag_level => 10 };
isa_ok $bb, q|Acme::FSM|, q|constructed object|;

my $tag = q|no args,|;
AFSMTS_method_wrap $method;
unlike $stderr, qr{(?m)^Use of uninitialized value\V+Acme/FSM\V+$},
  qq|$tag no UOUV warning|;
like $stderr, qr{(?m)^\[\(eval\)\]:\h+at t/TestSuite\.pm\V+$},
  qq|$tag noted|;

$tag = q|one arg,|;
AFSMTS_method_wrap $method, q|deer|;
like $stderr, qr{(?m)\V+: deer at \V+}, qq|$tag noted|;

$tag = q|two args,|;
AFSMTS_method_wrap $method, qw| moose alces_alces |;
like $stderr, qr{(?m)^\V+: moosealces_alces at \V+$}, qq|$tag noted|;

$tag = q|trimmed {diag_level}|;
AFSMTS_object_wrap $bb, { diag_level => 0 };
AFSMTS_method_wrap $method;
is $stderr, '', qq|$tag obeyed|;

# vim: set filetype=perl
