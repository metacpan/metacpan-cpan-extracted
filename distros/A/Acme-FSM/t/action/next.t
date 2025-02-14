# $Id: next.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.3 );

use t::TestSuite qw| :run :diag |;
use Test::More tests => 41;

use Acme::FSM;

our( %st, $rc, %opts, $stderr );
our @inbase = (                         undef,
                              q|DEATH|, undef,
  qw|                   Famine Satan |, undef,
  qw|                 ADAM Ligur God |, undef,
  qw| Shadwell Brian War Wensleydale |, undef );
our @input = @inbase;
$opts{source} = \&AFSMTS_shift;
my $tag;

my %common =
( state      =>       q|STOP|,
  diag_level =>             1,
  namespace  =>         undef,
  source     => $opts{source},
  dumper     =>         undef );

%st =
( START    =>
  { switch  => sub { $_[0]->{queue} = [ ] },
    tturn   => [qw|        workload VOID |] },
  workload =>
  { tturn => [qw| workload NEXT |],
    fturn => [qw|     STOP DONE |]          },
  STOP     => { switch => sub {           } } );

$tag = q|{tturn}:(NEXT), consuming|;
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3 };
$st{workload}{eturn} = [qw| STOP FAIL |];
AFSMTS_wrap;
AFSMTS_deeply @{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [ ]}]},
  qq|$tag, consumes empty|;
is $input[0], q|DEATH|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [qw| DEATH |]}]},
  qq|$tag, consumes one|;
is $input[0], q|Famine|, qq|1-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                 FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Famine Satan |]} ]},
  qq|$tag, consumes two|;
is $input[0], q|ADAM|, qq|2-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| ADAM Ligur God |]} ]},
  qq|$tag, consumes three|;
is $input[1], q|Shadwell|, qq|3-queue $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                       DONE |],
   { %common, action => q|DONE|, queue => [qw| Shadwell Brian War |]} ]},
  qq|$tag, consumes four|;
is $input[0], q|Wensleydale|, qq|4-queue $tag, 1 item left behind|;

$tag = q|{tturn}:(NEXT), refraining|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3, $_[1] };

AFSMTS_wrap;
AFSMTS_deeply @{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [ ]}]},
  qq|$tag, refrains empty|;
is $input[0], q|DEATH|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [qw| DEATH |]}]},
  qq|$tag, refrains one|;
is $input[0], q|Famine|, qq|1-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                 FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Famine Satan |]} ]},
  qq|$tag, refrains two|;
is $input[0], q|ADAM|, qq|2-queue, $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| ADAM Ligur God |]} ]},
  qq|$tag, refrains three|;
is $input[1], q|Shadwell|, qq|3-queue, $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                       DONE |],
   { %common, action => q|DONE|, queue => [qw| Shadwell Brian War |]} ]},
  qq|$tag, refrains four|;
is $input[0], q|Wensleydale|, qq|4-queue, $tag, 1 item left behind|;

$tag = q|{eturn}:(NEXT), consuming|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3 };
$st{workload}{eturn} = [qw| workload NEXT |];

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                       DONE |],
   { %common, action => q|DONE|, queue => [qw| DEATH Famine Satan |]} ]},
  qq|$tag, consumes empty|;
is $input[1], q|ADAM|, qq|0-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| ADAM Ligur God |]} ]},
  qq|$tag, consumes one|;
is $input[1], q|Shadwell|, qq|1-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                       DONE |],
   { %common, action => q|DONE|, queue => [qw| Shadwell Brian War |]} ]},
  qq|$tag, consumes two|;
is $input[0], q|Wensleydale|, qq|2-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                   DONE |],
   {                                    %common,
     action =>                          q|DONE|,
     queue  => [qw| Wensleydale DEATH Famine |] } ]},
  qq|$tag, consumes three|;
is $input[0], q|Satan|, qq|3-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                     DONE |],
   { %common, action => q|DONE|, queue => [qw| Satan ADAM Ligur |]} ]},
  qq|$tag, consumes four|;
is $input[0], q|God|, qq|4-queue $tag, runs over|;

$tag = q|{eturn}:(NEXT), refraining|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3, $_[1] };

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                       DONE |],
   { %common, action => q|DONE|, queue => [qw| DEATH Famine Satan |]} ]},
  qq|$tag, refrains one|;
is $input[1], q|ADAM|, qq|0-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| ADAM Ligur God |]} ]},
  qq|$tag, refrains one|;
is $input[1], q|Shadwell|, qq|1-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                       DONE |],
   { %common, action => q|DONE|, queue => [qw| Shadwell Brian War |]} ]},
  qq|$tag, refrains two|;
is $input[0], q|Wensleydale|, qq|2-queue, $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                   DONE |],
   {                                    %common,
     action =>                          q|DONE|,
     queue  => [qw| Wensleydale DEATH Famine |] } ]},
  qq|$tag, refrains three|;
is $input[0], q|Satan|, qq|3-queue, $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                     DONE |],
   { %common, action => q|DONE|, queue => [qw| Satan ADAM Ligur |]} ]},
  qq|$tag, refrains four|;
is $input[0], q|God|, qq|4-queue, $tag, runs over|;

$tag = q|not reviving {source}|;
$opts{source} = sub { undef };
$st{workload}{switch} = sub { };
TODO:                                              {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson $tag }

# vim: set filetype=perl
