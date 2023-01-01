# $Id: connect.t 481 2013-02-17 02:09:10Z whynot $
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
use Test::More tests => 54;

use Acme::FSM;

our( $bb, $bback, $stderr );

$bb = eval { AFSMTS_class_wrap; 1 };
ok !$bb && $@ =~ m<{options} HASH is required>,
  AFSMTS_croakson q|class, no {options}|;

my %common =
( fst        => {      },
  state      => q|START|,
  action     =>  q|VOID|,
  diag_level =>       10,
  namespace  =>    undef,
  source     =>    undef,
  dumper     =>    undef );

my $tag = q|class, empty {options},|;
AFSMTS_class_wrap { };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, diag_level => 1 }, qq|$tag init done|;
like $stderr, qr<(?m)^\Q[connect]: FST has no {START} state>,
  qq|$tag no {START} noted|;
like $stderr, qr<(?m)^\Q[connect]: FST has no {STOP} state>,
  qq|$tag no {STOP} noted|;

$bback = $bb;
undef $bb;

$bb = eval { AFSMTS_object_wrap $bback; 1 };
ok !$bb && $@ =~ m<{options} HASH is required>,
  AFSMTS_croakson q|object, no {options}|;

$tag = q|object, empty {options},|;
AFSMTS_object_wrap $bback, { };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, diag_level => 1 }, qq|$tag init done|;
like $stderr, qr<(?m)^\Q[connect]: FST has no {START} state>,
  qq|$tag no {START} noted|;
like $stderr, qr<(?m)^\Q[connect]: FST has no {STOP} state>,
  qq|$tag no {STOP} noted|;
is_deeply
[ $bb->{_}{fst}, $bb->{_} ne $bback->{_} ], [ $bback->{_}{fst}, !0 ],
  qq|$tag {fst} check|;

$tag = q|class, minimal FST explicitly in {@_},|;
AFSMTS_class_wrap { diag_level => 10 }, qw| START splat STOP tic_tac_toe |;
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, fst => {qw| START splat STOP tic_tac_toe |}},
  qq|$tag init done|;
like $stderr, qr<(?m)^\Q[connect]: clean init with (2) >,
  qq|$tag items in FST noted|;

$bback = $bb;
$tag = q|object, minimal FST explicity in {@_},|;
AFSMTS_object_wrap $bback, { }, qw| START hash_mark STOP pound_sign |;
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, fst => {qw| START splat STOP tic_tac_toe |}},
  qq|$tag init done|;
is_deeply
[ $bb->{_}{fst}, $bb->{_} ne $bback->{_} ], [ $bback->{_}{fst}, !0 ],
  qq|$tag {fst} check|;
like $stderr, qr<(?m)^\Q[connect]: stealing (2) >,
  qq|$tag items in FST noted|;
like $stderr, qr<(?m)^\Q[connect]: ignoring (4) >,
  qq|$tag items in trailer noted|;

$tag = q|class, minimal FST in HASH,|;
my $fsta = {qw| START flash STOP thump |};
AFSMTS_class_wrap { diag_level => 10 }, $fsta;
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, fst => { %$fsta }}, qq|$tag init done|;
is $bb->{_}{fst}, $fsta, qq|$tag {fst} isa prepared HASH|;
like $stderr, qr<(?m)^\Q[connect]: clean init with (2) >,
  qq|$tag items in FST noted|;

$bback = $bb;
$tag = q|object, minimal FST in HASH,|;
my $fstb = {qw| START thud STOP sharp |};
AFSMTS_object_wrap $bback, { }, $fstb;
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, fst => { %$fsta }}, qq|$tag init done|;
is_deeply
[ $bb->{_}{fst}, $bb->{_} ne $bback->{_}, $bb->{_}{fst} ],
[                           $bback->{_}{fst}, !0, $fsta ],
  qq|$tag {fst} check|;
like $stderr, qr<(?m)^\Q[connect]: stealing (2) >,
  qq|$tag items in FST noted|;
like $stderr, qr<(?m)^\Q[connect]: ignoring (2) >,
  qq|$tag items in trailer noted|;

$tag = q|class, minimal FST in HASH, minimal trailer,|;
$fsta = {qw| START mesh STOP crosshatch |};
AFSMTS_class_wrap { diag_level => 10 }, $fsta, hex => q|octalthorpe|;
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, fst => { %$fsta }}, qq|$tag init done|;
is $bb->{_}{fst}, $fsta, qq|$tag {fst} isa prepared HASH|;
like $stderr, qr<(?m)^\Q[connect]: clean init with (2) >,
  qq|$tag items in FST noted|;
like $stderr, qr<(?m)^\Q[connect]: ignoring (2) >,
  qq|$tag items in trailer noted|;

$bback = $bb;
$tag = q|object, minimal FST in HASH, minimal trailer,|;
$fstb = {qw| START octothorn STOP crunch |};
AFSMTS_object_wrap $bback, { }, $fstb, noughts_and_crosses => q|widget_mark|;
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, fst => { %$fsta }}, qq|$tag init done|;
is $bb->{_}{fst}, $fsta, qq|$tag {fst} isa prepared HASH|;
like $stderr, qr<(?m)^\Q[connect]: stealing (2) >,
  qq|$tag items in FST noted|;
like $stderr, qr<(?m)^\Q[connect]: ignoring (2) >,
  qq|$tag items in traler noted|;

$t::TestSuite::class_cheat = q|t::TestSuite::FSM|;
$tag = q|just checking,|;
$fsta = {qw| START pig_pen STOP comment_sign |};
AFSMTS_class_wrap { }, $fsta;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag processed|;

$bback = $bb;
$tag = q|object, inheritance,|;
AFSMTS_object_wrap $bback, { };
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag processed|;
undef $t::TestSuite::class_cheat;

$tag = q|class, unknown {options},|;
AFSMTS_class_wrap { diag_level => 10, noughts_and_crosses => q|octothorpe| };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common }, qq|$tag init done|;
like $stderr, qr<(?m)^\Q[connect]: (noughts_and_crosses): unknown option>,
  qq|$tag noted|;

$bback = $bb;
$tag = q|object, unknown {options},|;
AFSMTS_object_wrap $bback, { hex => q|gate| };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common }, qq|$tag init done|;
like $stderr, qr<(?m)^\Q[connect]: (hex): unknown option>, qq|$tag noted|;

$tag = q|class, {options}{namespace},|;
AFSMTS_class_wrap { diag_level => 10, namespace => q|gate| };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, namespace => q|gate| },
  qq|$tag {namespace} accepted|;

$bback = $bb;
$tag = q|object, {options}{namespace}, get from source,|;
AFSMTS_object_wrap $bback, { };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, namespace => q|gate| }, qq|$tag init done|;

$tag = q|object, {options}{namespace}, overwrite one from source,|;
AFSMTS_object_wrap $bback, { namespace => q|gridlet| };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, namespace => q|gridlet| },
  qq|$tag init done|;

$tag = q|object, {options}{namespace}, overwrite with (),|;
AFSMTS_object_wrap $bback, { namespace => '' };
isa_ok $bb, q|Acme::FSM|, qq|$tag processed|;
is_deeply $bb->{_}, { %common, namespace => '' },
  qq|$tag init done|;

# vim: set filetype=perl

