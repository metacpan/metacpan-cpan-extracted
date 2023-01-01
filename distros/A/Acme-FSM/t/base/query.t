# $Id: query.t 482 2013-03-08 22:47:45Z whynot $
# Copyright 2012, 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::TestSuite::FSM;
use parent qw| Acme::FSM |;

sub shift_shift       {
    my $bb          = shift @_;
    $bb->{bull}     = shift @main::flags;
    $bb->{shambles} = shift @_                                          if @_;
    shift @main::flags }

package t::TestSuite::havoc;

sub new { bless { }, shift @_ }

sub shift_shift       {
    my $bb       = shift @_;
    $bb->{mess}  = shift @main::flags;
    $bb->{slops} = shift @_                                             if @_;
    shift @main::flags }

package main;
use version 0.77; our $VERSION = version->declare( v2.3.2 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 45;

use Acme::FSM;

our( $bb, $rc, $stderr );
our %st    = (      );
my $method = q|query|;

our @flags =
qw| The_Night_We_Died                Zaia
    Muh                            Ka_III
    Zombies              De_Zeuhl_Undazir
    Eliphas_Levi        Maneh_Fur_Da_Zess
    Troller_Tanz           Ek_Sun_Da_Zess
    C_est_la_Vie_Qui_les_A_Menes_La  Nono
    Do_The_Music   Da_Zeuhl_Worts_Mekanik
    Thaud                        Wainsaht
    The_Last_Seven_Minutes Nebehr_Gudahtt
    Udu_Wudu                  Kohntarkosz |;

my $tag;
my $mf = q|{havoc}|;
my %plug = ( diag_level => 5 );

$tag = q|{havoc} is missing,|;
AFSMTS_class_wrap { %plug }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, undef, $mf;
like $@, qr.\Q {havoc} !isa defined., AFSMTS_croakson $tag;

$tag = q|{havoc} isa (HASH),|;
AFSMTS_method_wrap $method, \$tag, $mf;
like $@, qr.\Q isa (SCALAR)., AFSMTS_croakson $tag;

$tag = q|{havoc} isa (Acme::FSM),|;
AFSMTS_method_wrap $method, $bb, $mf;
like $@, qr.\Q {havoc} isa (Acme::FSM)., AFSMTS_croakson $tag;

$tag = q|{havoc} isa (CODE), {namespace} unset,|;
AFSMTS_method_wrap $method, \&t::TestSuite::FSM::shift_shift, $mf;
is_deeply
[ $bb->{bull}, exists $bb->{shambles}, $rc ],
[        q|The_Night_We_Died|, '', q|Zaia| ],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[(eval)]: {havoc} isa (CODE).,
  qq|$tag noted|;

$tag = q|{havoc} isa (CODE), {namespace} unset, argument isa set,|;
AFSMTS_method_wrap $method,
  \&t::TestSuite::FSM::shift_shift, $mf, q|Fur_Dihhel_Kobaia|;
is_deeply
[@$bb{qw| bull shambles |}, $rc ], [qw| Muh Fur_Dihhel_Kobaia Ka_III |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[(eval)]: {havoc} isa (CODE).,
  qq|$tag noted|;

$tag = q|{havoc} isa (CODE), {namespace} isa set,|;
AFSMTS_class_wrap { %plug, namespace => q|swill| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, \&t::TestSuite::FSM::shift_shift, $mf;
is_deeply
[ $bb->{bull}, exists $bb->{shambles}, $rc ],
[      q|Zombies|, '', q|De_Zeuhl_Undazir| ],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[(eval)]: {havoc} isa (CODE).,
  qq|$tag noted|;

$tag = q|{havoc} isa (CODE), {namespace} isa set, argument isa set,|;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, \&t::TestSuite::FSM::shift_shift, $mf, q|Hhai|;
is_deeply
[@$bb{qw|           bull shambles |}, $rc ],
[qw| Eliphas_Levi Hhai Maneh_Fur_Da_Zess |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[(eval)]: {havoc} isa (CODE).,
  qq|$tag noted|;

$tag = q|{havoc} isa (), {namespace} !isa defined,|;
AFSMTS_class_wrap { %plug }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|junk|, $mf;
like $@, qr.\Q {namespace} !isa defined., AFSMTS_croakson $tag;
like $stderr, qr.(?m)\Q[(eval)]: {havoc} isa ()., qq|$tag noted|;

$tag = q|{havoc} !isa defined method, {namespace} eq (),|;
$t::TestSuite::class_cheat = q|t::TestSuite::FSM|;
AFSMTS_class_wrap { %plug, namespace => '' }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|tfihs_tfihs|, $mf;
like $@, qr.\Q <t::TestSuite::FSM> can't [tfihs_tfihs] method .,
  AFSMTS_croakson $tag;
like $stderr, qr.(?m)\Q[(eval)]: defaulting {havoc} to \E\x24self.,
  qq|$tag defaulting noted|;
like $stderr, qr.(?m)\Q[(eval)]: {namespace} isa (t::TestSuite::FSM).,
  qq|$tag defaulted noted|;

$tag = q|{havoc} isa defined method, {namespace} eq (),|;
AFSMTS_method_wrap $method, q|shift_shift|, $mf;
is_deeply
[ $bb->{bull}, exists $bb->{shambles}, $rc ],
[   q|Troller_Tanz|, '', q|Ek_Sun_Da_Zess| ],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[(eval)]: going for <t::TestSuite::FSM>->[shift_shift].,
  qq|$tag noted|;

$tag = q|{havoc} isa defined method, {namespace} eq (), argument is set,|;
AFSMTS_method_wrap $method, q|shift_shift|, $mf, q|Coltrane_Sundia|;
is_deeply
[@$bb{qw|                            bull shambles |}, $rc ],
[qw| C_est_la_Vie_Qui_les_A_Menes_La Coltrane_Sundia Nono |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[(eval)]: going for <t::TestSuite::FSM>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{havoc} !isa defined method, {namespace} eq (t::TestSuite::havoc),|;
my $havoc = t::TestSuite::havoc->new;
undef $t::TestSuite::class_cheat;
AFSMTS_class_wrap { %plug, namespace => $havoc }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|tfihs_tfihs|, $mf;
like $@, qr.\Q <t::TestSuite::havoc> can't [tfihs_tfihs] method .,
  AFSMTS_croakson $tag;
unlike $stderr, qr.(?m)\Q[(eval)]: defaulting {havoc} to \E\x24self.,
  qq|$tag no defaulting|;
like $stderr, qr.(?m)\Q[(eval)]: {namespace} isa (t::TestSuite::havoc).,
  qq|$tag {namespace} noted|;

$tag = q|{havoc} isa defined method, {namespace} eq (t::TestSuite::havoc),|;
AFSMTS_method_wrap $method, q|shift_shift|, $mf;
is_deeply
[        $havoc->{mess}, exists $bb->{bull}, $rc ],
[ q|Do_The_Music|, '', q|Da_Zeuhl_Worts_Mekanik| ],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[(eval)]: going for <t::TestSuite::havoc>->[shift_shift].,
  qq|$tag noted|;

$tag =
 q|{havoc} isa defined method, {namespace} eq (t::TestSuite::havoc), | .
 q|argument is set,|;
AFSMTS_method_wrap $method, q|shift_shift|, $mf, q|Kohntark|;
is_deeply [@$havoc{qw| mess slops |}, $rc ], [qw| Thaud Kohntark Wainsaht |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[(eval)]: going for <t::TestSuite::havoc>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{havoc} !isa defined subroutine, {namespace} eq (t::TestSuite::havoc),|;
AFSMTS_class_wrap { %plug, namespace => q|t::TestSuite::havoc| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|tfihs_tfihs|, $mf;
like $@,
  qr.(?m)\Q[(eval)]: <t::TestSuite::havoc> package can't [tfihs_tfihs].,
  AFSMTS_croakson $tag;
unlike $stderr, qr.(?m)\Q[(eval)]: defaulting {havoc} to \E\x24self.,
  qq|$tag no defaulting|;
like $stderr, qr.(?m)\Q[(eval)]: {namespace} isa ().,
  qq|$tag {namespace} isa scalar|;

$tag =
  q|{havoc} isa defined subroutine, {namespace} eq (t::TestSuite::havoc),|;
AFSMTS_method_wrap $method, q|shift_shift|, $mf;
is_deeply
[             $bb->{mess}, exists $bb->{bull}, $rc ],
[ q|The_Last_Seven_Minutes|, '', q|Nebehr_Gudahtt| ],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[(eval)]: going for <t::TestSuite::havoc>::[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{havoc} isa defined subroutine, {namespace} eq (t::TestSuite::havoc), | .
  q|argument is set,|;
AFSMTS_method_wrap $method, q|shift_shift|, $mf, q|Ka_I|;
is_deeply [@$bb{qw| mess slops |}, $rc ], [qw| Udu_Wudu Ka_I Kohntarkosz |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[(eval)]: going for <t::TestSuite::havoc>::[shift_shift].,
  qq|$tag noted|;

$tag = q|{havoc} returns empty,|;
AFSMTS_class_wrap { }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, sub { }, $mf;
is_deeply $rc, [ ], qq|$tag queried|;

$tag = q|{havoc} returns one item, item isa scalar|;
AFSMTS_method_wrap $method, sub { q|Ek_Sun_Da_Zess| }, $mf;
is_deeply [ $rc ], [qw| Ek_Sun_Da_Zess |], qq|$tag queried|;

$tag = q|{havoc} returns one item, item isa object|;
my $obj = $bb;
AFSMTS_method_wrap $method, sub { $obj }, $mf;
is $rc, $obj, qq|$tag queried|;

# vim: set filetype=perl
