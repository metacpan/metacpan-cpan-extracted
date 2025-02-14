# $Id: diag.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.4 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 25;

use Acme::FSM;

our( $bb, $stderr );
my $method = q|diag|;

AFSMTS_class_wrap { diag_level => 10 };
isa_ok $bb, q|Acme::FSM|, q|constructed object|;

my $tag = q|no args,|;
AFSMTS_method_wrap $method;
like $stderr, qr{(?m)^Use of uninitialized value in numeric\V+Acme/FSM\V+$},
  qq|$tag UOUV in level check|;
like $stderr, qr{(?m)^Use of uninitialized value in sprintf\V+Acme/FSM\V+$},
  qq|$tag UOUV in sprintf|;
like $stderr, qr{(?m)^\[\(eval\)\]: $}, qq|$tag noted|;

$tag = q|limit isn't numeric,|;
AFSMTS_method_wrap $method, q|northwest|;
like $stderr, qr{(?m)"northwest" isn't numeric in numeric\V+Acme/FSM\V+$},
  qq|$tag ININ in level check|;
like $stderr, qr{(?m)^Use of uninitialized value in sprintf\V+Acme/FSM\V+$},
  qq|$tag UOUV in sprintf|;
like $stderr, qr{(?m)^\[\(eval\)\]: $}, qq|$tag noted|;

$tag = q|no format,|;
AFSMTS_method_wrap $method, 9;
unlike $stderr, qr{(?m)\V+ in numeric\V+Acme/FSM\V+$},
  qq|$tag no ININ in level check|;
like $stderr, qr{(?m)^Use of uninitialized value in sprintf\V+Acme/FSM\V+$},
  qq|$tag UOUV in sprintf|;
like $stderr, qr{(?m)^\[\(eval\)\]: $}, qq|$tag noted|;

$tag = q|format, no conversion,|;
AFSMTS_method_wrap $method, 9, q|south|;
unlike $stderr, qr{(?m)\V+Acme/FSM\V+$}, qq|$tag no warnings|;
like $stderr, qr{(?m)^\[\(eval\)\]: south$}, qq|$tag noted|;

$tag = q|format, conversion, no paramter,|;
AFSMTS_method_wrap $method, 9, q|%s|;
like $stderr, qr{(?m)^Missing argument in printf\V+Acme/FSM\V+$},
  qq|$tag MAI printf|;
like $stderr, qr{(?m)^\[\(eval\)\]: $}, qq|$tag noted|;

$tag = q|format, conversion, paramter,|;
AFSMTS_method_wrap $method, 9, q|%s|, q|southwest|;
unlike $stderr, qr{(?m)\V+Acme/FSM\V+$}, qq|$tag no warnings|;
like $stderr, qr{(?m)^\[\(eval\)\]: southwest$}, qq|$tag noted|;

$tag = q|format, conversion, extra paramter,|;
AFSMTS_method_wrap $method, 9, q|%s|, qw| east west |;
TODO: {
    local $TODO = q|not enabling C<no warnings "redundant">|;
    like $stderr, qr{(?m)\V+Acme/FSM\V+$}, qq|$tag no warnings| }
like $stderr, qr{(?m)^\[\(eval\)\]: east$}, qq|$tag noted|;

my @in = qw| Narrator Tinky_Winky Baby_Sun Po Trumpets Noo_Noo Dipsy |;
my @data =
([qw|                                                Narrator |],
 [qw|                                    Narrator Tinky_Winky |],
 [qw|                           Narrator Tinky_Winky Baby_Sun |],
 [qw|                        Narrator Tinky_Winky Baby_Sun Po |],
 [qw|               Narrator Tinky_Winky Baby_Sun Po Trumpets |],
 [qw|       Narrator Tinky_Winky Baby_Sun Po Trumpets Noo_Noo |],
 [qw| Narrator Tinky_Winky Baby_Sun Po Trumpets Noo_Noo Dipsy |] );

foreach my $level ( 0 .. 6 )                                             {
    my @out;
    AFSMTS_object_wrap $bb, { diag_level => $level };
    foreach my $diag ( 0 .. 6 ) {
        AFSMTS_method_wrap $method, $diag, $in[$diag];
        push @out, $in[$diag]                                               if
          $stderr                }
    is_deeply [ @out ], $data[$level], qq|respects {diag_level} ($level)| }

# vim: set filetype=perl
