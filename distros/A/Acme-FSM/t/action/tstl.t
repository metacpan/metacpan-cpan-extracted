# $Id: tstl.t 561 2022-12-29 18:54:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;
use 5.010;

package main;
use version 0.77; our $VERSION = version->declare( v2.2.4 );

use t::TestSuite qw| :run :diag |;
use Test::More;

plan tests => 41;

use Acme::FSM;

our( %st, $rc, %opts, $stderr );
our @inbase = (                       undef,
                            q|Adams|, undef,
  qw|              Roosevelt Hayes |, undef,
  qw|   Jefferson Harrison Johnson |, undef,
  qw| Buchanan Bush Lincoln Carter |, undef );
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
  { tturn => [qw| workload TSTL |],
    fturn => [qw|     STOP DONE |]          },
  STOP     => { switch => sub {           } } );

$tag = q|{tturn}:(TSTL), consuming|;
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3 };
$st{workload}{eturn} = [qw| STOP FAIL |];
AFSMTS_wrap;
AFSMTS_deeply @{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [ ]} ]},
  qq|$tag, consumes empty|;
is $input[0], q|Adams|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                          FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Adams |]} ]},
  qq|$tag, consumes one|;
is $input[0], q|Roosevelt|, qq|1-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                    FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Roosevelt Hayes |]} ]},
  qq|$tag, consumes two|;
is $input[0], q|Jefferson|, qq|2-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                     DONE |],
   { %common,
     action =>                            q|DONE|,
     queue  => [qw| Jefferson Harrison Johnson |] } ]},
  qq|$tag, consumes three|;
is $input[1], q|Buchanan|, qq|3-queue $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                DONE |],
   {                                 %common,
     action =>                       q|DONE|,
     queue  => [qw| Buchanan Bush Lincoln |] } ]},
  qq|$tag, consumes four|;
is $input[0], q|Carter|, qq|4-queue $tag, 1 item left behind|;

$tag = q|{tturn}:(TSTL), refraining|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3, $_[1] };

AFSMTS_wrap;
AFSMTS_deeply @{[[qw| FAIL |], { %common, action => q|FAIL|, queue  => [ ]}]},
  qq|$tag, refrains empty|;
is $input[0], q|Adams|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                               DONE |],
   { %common, action => q|DONE|, queue => [qw| Adams | x 3 ]} ]},
  qq|$tag, refrains one|;
is $input[1], q|Roosevelt|, qq|1-queue $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| Roosevelt | x 3 ]} ]},
  qq|$tag, refrains two|;
is $input[0], q|Hayes|, qq|2-queue, $tag, stuck at first|;
shift @input                                                       for 0 .. 1;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| Jefferson | x 3 ]} ]},
  qq|$tag, refrains three|;
is $input[0], q|Harrison|, qq|3-queue, $tag, stuck at first|;
shift @input                                                       for 0 .. 2;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  DONE |],
   { %common, action => q|DONE|, queue => [qw| Buchanan | x 3 ]} ]},
  qq|$tag, refrains four|;
is $input[0], q|Bush|, qq|4-queue, $tag, stuck at first|;

$tag = q|{eturn}:(TSTL), consuming|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3 };
$st{workload}{eturn} = [qw| workload TSTL |];

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                          DONE |],
   { %common, action => q|DONE|, queue => [qw| Adams Roosevelt Hayes |]} ]},
  qq|$tag, consumes empty|;
is $input[1], q|Jefferson|, qq|0-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                     DONE |],
   {                                      %common,
     action =>                            q|DONE|,
     queue  => [qw| Jefferson Harrison Johnson |] } ]},
  qq|$tag, consumes one|;
is $input[1], q|Buchanan|, qq|1-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                          DONE |],
   { %common, action => q|DONE|, queue => [qw| Buchanan Bush Lincoln |]} ]},
  qq|$tag, consumes two|;
is $input[0], q|Carter|, qq|2-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                           DONE |],
   { %common, action => q|DONE|, queue => [qw| Carter Adams Roosevelt |]} ]},
  qq|$tag, consumes three|;
is $input[0], q|Hayes|, qq|3-queue $tag, runs over|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                   DONE |],
   {                                    %common,
     action =>                          q|DONE|,
     queue  => [qw| Hayes Jefferson Harrison |] } ]},
  qq|$tag, consumes four|;
is $input[0], q|Johnson|, qq|4-queue $tag, runs over|;

$tag = q|{eturn}:(TSTL), refraining|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3, $_[1] };

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw| DONE |], { %common, action => q|DONE|, queue => [qw| Adams | x 3 ]}]},
  qq|$tag, refrains one|;
is $input[1], q|Roosevelt|, qq|0-queue $tag, runs over|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| Roosevelt | x 3 ]} ]},
  qq|$tag, refrains one|;
is $input[0], q|Hayes|, qq|1-queue $tag, stucks on first|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw| DONE |], { %common, action => q|DONE|, queue => [qw| Hayes | x 3 ]}]},
  qq|$tag, refrains two|;
is $input[1], q|Jefferson|, qq|2-queue, $tag, stucks on first|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                   DONE |],
   { %common, action => q|DONE|, queue => [qw| Jefferson | x 3 ]} ]},
  qq|$tag, refrains three|;
is $input[0], q|Harrison|, qq|3-queue, $tag, stucks on first|;
shift @input for 0 .. 2;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  DONE |],
   { %common, action => q|DONE|, queue => [qw| Buchanan | x 3 ]} ]},
  qq|$tag, refrains four|;
is $input[0], q|Bush|, qq|4-queue, $tag, stucks on first|;

$tag = q|not reviving {source}|;
$opts{source} = sub { undef };
$st{workload}{switch} = sub { };
TODO:                                              {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson $tag }

# vim: set filetype=perl
