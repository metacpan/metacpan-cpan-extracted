# $Id: query_source.t 482 2013-03-08 22:47:45Z whynot $
# Copyright 2012, 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::TestSuite::FSM;
use parent qw| Acme::FSM |;

sub shift_shift       {
    my $bb        = shift @_;
    $bb->{Ashevill_pm}  = shift @main::flags;
    $bb->{Anchorage_pm} = shift @_                                      if @_;
    shift @main::flags }

package t::TestSuite::source;

sub new { bless { }, shift @_ }

sub shift_shift       {
    my $bb           = shift @_;
    $bb->{Torino_pm} = shift @main::flags;
    $bb->{Lund_pm}   = shift @_                                         if @_;
    shift @main::flags }

package main;
use version 0.77; our $VERSION = version->declare( v2.3.2 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 62;

use Acme::FSM;

our( $bb, $rc, $stderr );
our %st    = (             );
my $method = q|query_source|;

my $tag;
our @flags =
qw| mustrum_ridcully        quirm
    djelibeybi            pteppic
    bravd                creosote
    xxxx                    tsort
    angua         ponder_stibbons
    king_verence        sto_helit
    bel_shamharoth sergeant_colon
    great_t_phon        boy_willy
    conina               llamedos
    agnes_nitt             lancre |;

my %plug = ( diag_level => 5 );

$tag = q|{source} is missing,|;
AFSMTS_class_wrap { %plug }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
like $stderr, qr<(?m)\Q[connect]: (source): unset >, qq|$tag noted|;
AFSMTS_method_wrap $method;
like $@, qr.\Q {source} !isa defined., AFSMTS_croakson $tag;

$tag = q|{source} isa (undef),|;
AFSMTS_class_wrap { %plug, source => undef }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
like $stderr, qr<(?m)\Q[connect]: (source): unset >, qq|$tag noted|;
AFSMTS_method_wrap $method;
like $@, qr.\Q {source} !isa defined., AFSMTS_croakson $tag;

$tag = q|{source} isa (HASH),|;
AFSMTS_class_wrap { %plug, source => \$tag }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q isa (SCALAR)., AFSMTS_croakson $tag;

$tag = q|{source} isa (Acme::FSM),|;
AFSMTS_object_wrap $bb, { %plug, source => $bb };
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q {source} isa (Acme::FSM)., AFSMTS_croakson $tag;

$tag = q|{source} isa (CODE), {namespace} unset,|;
AFSMTS_class_wrap { %plug, source => \&t::TestSuite::FSM::shift_shift }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{Ashevill_pm}, exists $bb->{Anchorage_pm}, @$rc ],
[         q|mustrum_ridcully|, '',  qw| quirm (quirm) |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_source]: {source} isa (CODE)., qq|$tag noted|;

$tag = q|{source} isa (CODE), {namespace} unset, argument isa set,|;
AFSMTS_class_wrap { %plug, source => \&t::TestSuite::FSM::shift_shift }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|brutha|;
is_deeply
[ @$bb{qw| Ashevill_pm Anchorage_pm |}, @$rc ],
[qw|    djelibeybi brutha pteppic (pteppic) |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_source]: {source} isa (CODE)., qq|$tag noted|;

$tag = q|{source} isa (CODE), {namespace} isa set,|;
AFSMTS_class_wrap
{ %plug, namespace => q|vesta|, source => \&t::TestSuite::FSM::shift_shift },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{Ashevill_pm}, exists $bb->{Anchorage_pm}, @$rc ],
[               q|bravd|, '', qw| creosote (creosote) |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_source]: {source} isa (CODE)., qq|$tag noted|;

$tag = q|{source} isa (CODE), {namespace} isa set, argument isa set,|;
AFSMTS_class_wrap
{ %plug, namespace => q|vesta|, source => \&t::TestSuite::FSM::shift_shift },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|littlebottom|;
is_deeply
[ @$bb{qw| Ashevill_pm Anchorage_pm |}, @$rc ],
[qw|        xxxx littlebottom tsort (tsort) |],
  qq|$tag queried|;
like $stderr, qr.(?m)\Q[query_source]: {source} isa (CODE)., qq|$tag noted|;

$tag = q|{source} isa (), {namespace} !isa defined,|;
AFSMTS_class_wrap { %plug, source => q|vorbis| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q {namespace} !isa defined., AFSMTS_croakson $tag;
like $stderr, qr.(?m)\Q[query_source]: {source} isa ()., qq|$tag noted|;

$tag = q|{source} !isa defined method, {namespace} eq (),|;
$t::TestSuite::class_cheat = q|t::TestSuite::FSM|;
AFSMTS_class_wrap { %plug, namespace => '', source => q|tfihs_tfihs| }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q <t::TestSuite::FSM> can't [tfihs_tfihs] method .,
  AFSMTS_croakson $tag;
like $stderr, qr.(?m)\Q[query_source]: defaulting {source} to \E\x24self.,
  qq|$tag defaulting noted|;
like $stderr, qr.(?m)\Q[query_source]: {namespace} isa (t::TestSuite::FSM).,
  qq|$tag defaulted noted|;

$tag = q|{source} isa defined method, {namespace} eq (),|;
AFSMTS_class_wrap { %plug, namespace => '', source => q|shift_shift| }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{Ashevill_pm}, exists $bb->{Anchorage_pm}, @$rc ],
[ q|angua|, '', qw| ponder_stibbons (ponder_stibbons) |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_source]: going for <t::TestSuite::FSM>->[shift_shift].,
  qq|$tag noted|;

$tag = q|{source} isa defined method, {namespace} eq (), argument is set,|;
AFSMTS_class_wrap { %plug, namespace => '', source => q|shift_shift| }, \%st;
isa_ok $bb, q|t::TestSuite::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|bel_shamharoth|;
is_deeply
[            @$bb{qw| Ashevill_pm Anchorage_pm |}, @$rc ],
[qw| king_verence bel_shamharoth sto_helit (sto_helit) |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_source]: going for <t::TestSuite::FSM>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{source} !isa defined method, {namespace} eq (t::TestSuite::source),|;
my $source = t::TestSuite::source->new;
undef $t::TestSuite::class_cheat;
AFSMTS_class_wrap
{ %plug, namespace => $source, source => q|tfihs_tfihs| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@, qr.\Q <t::TestSuite::source> can't [tfihs_tfihs] method .,
  AFSMTS_croakson $tag;
unlike $stderr, qr.(?m)\Q[query_source]: defaulting {source} to \E\x24self.,
  qq|$tag no defaulting|;
like $stderr,
  qr.(?m)\Q[query_source]: {namespace} isa (t::TestSuite::source).,
  qq|$tag {namespace} noted|;

$tag = q|{source} isa defined method, {namespace} eq (t::TestSuite::source),|;
$source = t::TestSuite::source->new;
AFSMTS_class_wrap
{ %plug, namespace => $source, source => q|shift_shift| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[       $source->{Torino_pm}, exists $bb->{Ashevill_pm}, @$rc ],
[ q|bel_shamharoth|, '', qw| sergeant_colon (sergeant_colon) |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_source]: going for <t::TestSuite::source>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{source} isa defined method, {namespace} eq (t::TestSuite::source), | .
  q|argument is set,|;
$source = t::TestSuite::source->new;
AFSMTS_class_wrap
{ %plug, namespace => $source, source => q|shift_shift| }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|shawn_ogg|;
is_deeply
[          @$source{qw| Torino_pm Lund_pm |}, @$rc ],
[qw| great_t_phon shawn_ogg boy_willy (boy_willy) |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_source]: going for <t::TestSuite::source>->[shift_shift].,
  qq|$tag noted|;

$tag =
  q|{source} !isa defined subroutine, {namespace} eq (t::TestSuite::source),|;
$source = t::TestSuite::source->new;
AFSMTS_class_wrap
{ %plug, namespace => q|t::TestSuite::source|, source => q|tfihs_tfihs| },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
like $@,
  qr.(?mx)\[query_source\]:\h\<t::TestSuite::source\>\hpackage\h
     can't\h\[tfihs_tfihs\].,
  AFSMTS_croakson $tag;
unlike $stderr, qr.(?m)\Q[query_source]: defaulting {source} to \E\x24self.,
  qq|$tag no defaulting|;
like $stderr, qr.(?m)\Q[query_source]: {namespace} isa ().,
  qq|$tag {namespace} isa scalar|;

$tag =
  q|{source} isa defined subroutine, {namespace} eq (t::TestSuite::source),|;
$source = t::TestSuite::source->new;
AFSMTS_class_wrap
{ %plug, namespace => q|t::TestSuite::source|, source => q|shift_shift| },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply
[ $bb->{Torino_pm}, exists $bb->{Ashevill_pm}, @$rc ],
[           q|conina|, '', qw| llamedos (llamedos) |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_source]: going for <t::TestSuite::source>::[shift_shift].,
  qq|$tag noted|;

$tag =                  q|{source} isa defined subroutine, | .
  q|{namespace} eq (t::TestSuite::source), argument is set,|;
$source = t::TestSuite::source->new;
AFSMTS_class_wrap
{ %plug, namespace => q|t::TestSuite::source|, source => q|shift_shift| },
  \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method, q|reg_shoe|;
is_deeply
[     @$bb{qw| Torino_pm Lund_pm |}, @$rc ],
[qw| agnes_nitt reg_shoe lancre (lancre) |],
  qq|$tag queried|;
like $stderr,
  qr.(?m)\Q[query_source]: going for <t::TestSuite::source>::[shift_shift].,
  qq|$tag noted|;

$tag = q|{source} returns empty,|;
AFSMTS_class_wrap { source => sub { } }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply $rc, [ undef, q|(undef)| ], qq|$tag queried|;

$tag = q|{source} returns one item, item isa scalar|;
AFSMTS_class_wrap { source => sub { q|windle_poons| } }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is_deeply $rc, [qw| windle_poons (windle_poons) |], qq|$tag queried|;

$tag = q|{source} returns one item, item isa object|;
my $obj = $bb;
AFSMTS_class_wrap { source => sub { $obj } }, \%st;
isa_ok $bb, q|Acme::FSM|, qq|$tag constructed object|;
AFSMTS_method_wrap $method;
is $rc->[0], $obj, qq|$tag queried|;
like $rc->[1], qr.\(Acme::FSM=HASH\(0x\w+\)\).,
  qq|$tag default dumper in action|;

# vim: set filetype=perl
