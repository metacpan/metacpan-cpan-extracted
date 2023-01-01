# $Id: query_dumper.t 482 2013-03-08 22:47:45Z whynot $
# Copyright 2012, 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::TestSuite::FSM;
use parent qw| Acme::FSM |;

sub shift_shift       {
    my $bb        = shift @_;
    $bb->{matrixone}  = shift @main::flags;
    $bb->{CSSC} = shift @_                                              if @_;
    shift @main::flags }

package t::TestSuite::dumper;

sub new { bless { }, shift @_ }

sub shift_shift       {
    my $bb           = shift @_;
    $bb->{aegis} = shift @main::flags;
    $bb->{slash_briefcase}   = shift @_                                 if @_;
    shift @main::flags }

package main;
use version 0.77; our $VERSION = version->declare( v2.3.2 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 65;

use Acme::FSM;

our( %st, $bb, $rc, $stderr );
our @flags =
qw| Orcrist           Brinning
    Nothung           Gurthang
    Caliburn             Mimun 
    Durandal            Graban
    Ekkisax         Noralltach
    Claidheamh_Solius Samsamha
    Baptism            Galatyn
    Murgleis      Haute_Claire
    Waske             Courtain
    Stormbringer      Hrunting |;

my $method = q|query_dumper|;
my $tag;
my %plug = ( diag_level => 5 );

$tag = q|{dumper} is missing,|;
AFSMTS_class_wrap { %plug }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is $rc, q|(undef)|, qq|$tag default dumper in action|;

$tag = q|{dumper} is missing, argument isa set,|;
AFSMTS_class_wrap { %plug }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Grimtooth|;
is $rc, q|(Grimtooth)|, qq|$tag default dumper in action|;

$tag = q|{dumper} isa (undef),|;
AFSMTS_class_wrap { %plug, dumper => undef }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is $rc, q|(undef)|, qq|$tag default dumper in action|;

$tag = q|{dumper} isa (undef), argument isa scalar,|;
AFSMTS_class_wrap { %plug, dumper => undef }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Schrit|;
is $rc, q|(Schrit)|, qq|$tag default dumper in action|;

$tag = q|{dumper} isa (undef), argument isa object,|;
AFSMTS_class_wrap { %plug, dumper => undef }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, $bb;
like $rc, qr.\(Acme::FSM=HASH\(0x\w+\)\)., qq|$tag default dumper in action|;

$tag = q|{dumper} isa (HASH),|;
AFSMTS_class_wrap { %plug, dumper => \$tag }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q isa (SCALAR)., AFSMTS_croakson $tag;

$tag = q|{dumper} isa (Acme::FSM),|;
AFSMTS_object_wrap $bb, { dumper => $bb };
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q {dumper} isa (Acme::FSM)., AFSMTS_croakson $tag;

$tag = q|{dumper} isa (CODE), {namespace} unset,|;
AFSMTS_class_wrap { %plug, dumper => \&t::TestSuite::FSM::shift_shift }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{matrixone}, exists $bb->{CSSC}, $rc ],
[               q|Orcrist|, '', q|Brinning| ],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_dumper]: {dumper} isa (CODE)., qq|$tag noted|;

$tag = q|{dumper} isa (CODE), {namespace} unset, argument isa set,|;
AFSMTS_class_wrap { %plug, dumper => \&t::TestSuite::FSM::shift_shift }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Dyrnwyn|;
is_deeply
[@$bb{qw| matrixone CSSC |}, $rc ], [qw| Nothung Dyrnwyn Gurthang |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_dumper]: {dumper} isa (CODE)., qq|$tag noted|;

$tag = q|{dumper} isa (CODE), {namespace} isa set,|;
AFSMTS_class_wrap
{ %plug,
  namespace =>                    q|Subversion|,
  dumper    => \&t::TestSuite::FSM::shift_shift },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{matrixone}, exists $bb->{CSSC}, $rc ], [ q|Caliburn|, '', q|Mimun| ],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_dumper]: {dumper} isa (CODE)., qq|$tag noted|;

$tag = q|{dumper} isa (CODE), {namespace} isa set, argument isa set,|;
AFSMTS_class_wrap
{ %plug, namespace => q|vesta|, dumper => \&t::TestSuite::FSM::shift_shift },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Merveilleuse|;
is_deeply
[@$bb{qw| matrixone CSSC |}, $rc ], [qw| Durandal Merveilleuse Graban |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_dumper]: {dumper} isa (CODE)., qq|$tag noted|;

$tag = q|{dumper} isa (), {namespace} !isa defined,|;
AFSMTS_class_wrap { %plug, dumper => q|projector| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q {namespace} !isa defined., AFSMTS_croakson $tag;
like $stderr, qr.(?m)\Q[query_dumper]: {dumper} isa ()., qq|$tag noted|;

$tag = q|{dumper} !isa defined method, {namespace} eq (),|;
$t::TestSuite::class_cheat = q|t::TestSuite::FSM|;
AFSMTS_class_wrap { %plug, namespace => '', dumper => q|tfihs_tfihs| }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q <t::TestSuite::FSM> can't [tfihs_tfihs] method .,
  AFSMTS_croakson $tag;
like $stderr, qr.(?m)\Q[query_dumper]: defaulting {dumper} to \E\x24self.,
  qq|$tag defaulting noted|;
like $stderr, qr.(?m)\Q[query_dumper]: {namespace} isa (t::TestSuite::FSM).,
  qq|$tag defaulted noted|;

$tag = q|{dumper} isa defined method, {namespace} eq (),|;
AFSMTS_class_wrap { %plug, namespace => '', dumper => q|shift_shift| }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{matrixone}, exists $bb->{CSSC}, $rc ],
[             q|Ekkisax|, '', q|Noralltach| ],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_dumper]: going for <t::TestSuite::FSM>->[shift_shift].,
  qq|$tag noted|;

$tag = q|{dumper} isa defined method, {namespace} eq (), argument is set,|;
AFSMTS_class_wrap { %plug, namespace => '', dumper => q|shift_shift| }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Quern_biter|;
is_deeply
[            @$bb{qw| matrixone CSSC |}, $rc ],
[qw| Claidheamh_Solius Quern_biter Samsamha |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_dumper]: going for <t::TestSuite::FSM>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{dumper} !isa defined method, {namespace} eq (t::TestSuite::dumper),|;
my $dumper = t::TestSuite::dumper->new;
undef $t::TestSuite::class_cheat;
AFSMTS_class_wrap
{ %plug, namespace => $dumper, dumper => q|tfihs_tfihs| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q <t::TestSuite::dumper> can't [tfihs_tfihs] method .,
  AFSMTS_croakson $tag;
unlike $stderr, qr.(?m)\Q[query_dumper]: defaulting {dumper} to \E\x24self.,
  qq|$tag no defaulting|;
like $stderr,
  qr.(?m)\Q[query_dumper]: {namespace} isa (t::TestSuite::dumper).,
  qq|$tag {namespace} noted|;

$tag = q|{dumper} isa defined method, {namespace} eq (t::TestSuite::dumper),|;
$dumper = t::TestSuite::dumper->new;
AFSMTS_class_wrap
{ %plug, namespace => $dumper, dumper => q|shift_shift| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $dumper->{aegis}, exists $bb->{matrixone}, $rc ],
[                     q|Baptism|, '', q|Galatyn| ],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_dumper]: going for <t::TestSuite::dumper>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{dumper} isa defined method, {namespace} eq (t::TestSuite::dumper), | .
  q|argument is set,|;
$dumper = t::TestSuite::dumper->new;
AFSMTS_class_wrap
{ %plug, namespace => $dumper, dumper => q|shift_shift| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Sting|;
is_deeply
[@$dumper{qw| aegis slash_briefcase |}, $rc ],
[qw|           Murgleis Sting Haute_Claire |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_dumper]: going for <t::TestSuite::dumper>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{dumper} !isa defined subroutine, {namespace} eq (t::TestSuite::dumper),|;
$dumper = t::TestSuite::dumper->new;
AFSMTS_class_wrap
{ %plug, namespace => q|t::TestSuite::dumper|, dumper => q|tfihs_tfihs| },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@,
  qr.(?x)\[query_dumper\]:\h\<t::TestSuite::dumper\>\hpackage\h
     can't\h\[tfihs_tfihs\].,
  AFSMTS_croakson $tag;
unlike $stderr, qr.(?m)\Q[query_dumper]: defaulting {dumper} to \E\x24self.,
  qq|$tag no defaulting|;
like $stderr, qr.(?m)\Q[query_dumper]: {namespace} isa ().,
  qq|$tag {namespace} isa scalar|;

$tag =
  q|{dumper} isa defined subroutine, {namespace} eq (t::TestSuite::dumper),|;
$dumper = t::TestSuite::dumper->new;
AFSMTS_class_wrap
{ %plug, namespace => q|t::TestSuite::dumper|, dumper => q|shift_shift| },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{aegis}, exists $bb->{matrixone}, $rc ], [ q|Waske|, '', q|Courtain| ],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_dumper]: going for <t::TestSuite::dumper>::[shift_shift].,
  qq|$tag noted|;

$tag =                  q|{dumper} isa defined subroutine, | .
  q|{namespace} eq (t::TestSuite::dumper), argument is set,|;
$dumper = t::TestSuite::dumper->new;
AFSMTS_class_wrap
{ %plug, namespace => q|t::TestSuite::dumper|, dumper => q|shift_shift| },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|Chastiefol|;
is_deeply
[@$bb{qw| aegis slash_briefcase |}, $rc ],
[qw|  Stormbringer Chastiefol Hrunting |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_dumper]: going for <t::TestSuite::dumper>::[shift_shift].,
  qq|$tag noted|;

$tag = q|{dumper} returns empty,|;
AFSMTS_class_wrap { %plug, dumper => sub { } }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply $rc, q|(unclear)|, qq|$tag queried|;

$tag = q|{dumper} returns one item, item isa scalar|;
AFSMTS_class_wrap { %plug, dumper => sub { q|Balisarda| } }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply [ $rc ], [qw| Balisarda |], qq|$tag queried|;

$tag = q|{dumper} returns one item, item isa object|;
my $obj = $bb;
AFSMTS_class_wrap { %plug, dumper => sub { $obj } }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q isa (Acme::FSM), should be ()., qq|$tag queried|;

# vim: set filetype=perl
