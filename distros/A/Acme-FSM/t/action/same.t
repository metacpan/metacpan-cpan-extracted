# $Id: same.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.3 );

use t::TestSuite qw| :run :diag |;
use Test::More;

plan tests => 41;

use Acme::FSM;

our( %st, $rc, %opts, $stderr );
our @inbase = (                         undef,
                           q|Kraljevo|, undef,
  qw|         Seattle Charlottesvill |, undef,
  qw|    Malaysia Marseille LasVegas |, undef,
  qw| Purdue Women Pittsburgh Sonoma |, undef );
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
  { tturn => [qw| workload SAME |],
    fturn => [qw|     STOP DONE |]          },
  STOP     => { switch => sub {           } } );

$tag = q|{tturn}:(SAME), consuming|;
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3 };
$st{workload}{eturn} = [qw| STOP FAIL |];
AFSMTS_wrap;
AFSMTS_deeply @{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [ ]}]},
  qq|$tag, consumes empty|;
is $input[0], q|Kraljevo|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                             FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Kraljevo |]} ]},
  qq|$tag, consumes one|;
is $input[1], q|Seattle|, qq|1-queue $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                            FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Seattle |]} ]},
  qq|$tag, consumes two|;
is $input[0], q|Charlottesvill|, qq|2-queue, $tag, 1 item left behind|;
shift @input                                                       for 0 .. 1;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                             FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Malaysia |]} ]},
  qq|$tag, consumes three|;
is $input[0], q|Marseille|, qq|3-queue, $tag, 2 items left behind|;
shift @input                                                       for 0 .. 2;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                           FAIL |],
   { %common, action => q|FAIL|, queue => [qw| Purdue |]} ]},
  qq|$tag, consumes four|;
is $input[0], q|Women|, qq|4-queue, $tag, 3 items left behind|;

$tag = q|{tturn}:(SAME), refraining|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3, $_[1] };

AFSMTS_wrap;
AFSMTS_deeply @{[[qw| FAIL |], { %common, action => q|FAIL|, queue => [ ]} ]},
  qq|$tag, refrains empty|;
is $input[0], q|Kraljevo|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  DONE |],
   { %common, action => q|DONE|, queue => [qw| Kraljevo | x 3 ]} ]},
  qq|$tag, refrains one|;
is $input[1], q|Seattle|, qq|1-queue $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                 DONE |],
   { %common, action => q|DONE|, queue => [qw| Seattle | x 3 ]} ]},
  qq|$tag, refrains two|;
is $input[0], q|Charlottesvill|, qq|2-queue, $tag, 1 item left behind|;
shift @input                                                       for 0 .. 1;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  DONE |],
   { %common, action => q|DONE|, queue => [qw| Malaysia | x 3 ]} ]},
  qq|$tag, refrains three|;
is $input[0], q|Marseille|, qq|3-queue, $tag, 2 items left behind|;
shift @input                                                       for 0 .. 2;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                DONE |],
   { %common, action => q|DONE|, queue => [qw| Purdue | x 3 ]} ]},
  qq|$tag, refrains four|;
is $input[0], q|Women|, qq|4-queue, $tag, 3 items left behind|;

$tag = q|{eturn}:(SAME), consuming|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3 };
$st{workload}{eturn} = [qw| workload SAME |];

TODO:                                                         {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson qq|$tag, empty| }
is $input[0], q|Kraljevo|, qq|0-queue $tag, no items left behind|;

TODO:                                                            {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson qq|$tag, one item| }
is $input[1], q|Seattle|, qq|1-queue $tag, terminator left behind|;
shift @input;

TODO:                                                             {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson qq|$tag, two items| }
is $input[0], q|Charlottesvill|, qq|2-queue $tag, one item left behind|;
shift @input                                                       for 0 .. 1;

TODO:                                                               {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson qq|$tag, three items| }
is $input[0], q|Marseille|, qq|3-queue $tag, two items left behind|;
shift @input                                                       for 0 .. 2;

TODO:                                                              {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson qq|$tag, four items| }
is $input[0], q|Women|, qq|4-queue $tag, three items left behind|;

$tag = q|{eturn}:(SAME), refraining|;
@input = ( );
$st{workload}{switch} =
  sub { push @{$_[0]->{queue}}, $_[1]; @{$_[0]->{queue}} < 3, $_[1] };

TODO:                                                         {
    local $TODO = qq|$tag, should detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson qq|$tag, empty| }
is $input[0], q|Kraljevo|, qq|0-queue $tag, no items left behind|;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  DONE |],
   { %common, action => q|DONE|, queue => [qw| Kraljevo | x 3 ]} ]},
  qq|$tag, refrains one|;
is $input[1], q|Seattle|, qq|1-queue $tag, terminator left behind|;
shift @input;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                 DONE |],
   { %common, action => q|DONE|, queue => [qw| Seattle | x 3 ]} ]},
  qq|$tag, refrains two|;
is $input[0], q|Charlottesvill|, qq|2-queue, $tag, 1 item left behind|;
shift @input                                                       for 0 .. 1;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  DONE |],
   { %common, action => q|DONE|, queue => [qw| Malaysia | x 3 ]} ]},
  qq|$tag, refrains three|;
is $input[0], q|Marseille|, qq|3-queue, $tag, 2 items left behind|;
shift @input                                                       for 0 .. 2;

AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                DONE |],
   { %common, action => q|DONE|, queue => [qw| Purdue | x 3 ]} ]},
  qq|$tag, refrains four|;
is $input[0], q|Women|, qq|4-queue, $tag, 3 items left behind|;

$tag = q|not reviving {source}|;
$opts{source} = sub { undef };
$st{workload}{switch} = sub { };
TODO:                                              {
    local $TODO = qq|$tag, shoild detect|;
    AFSMTS_wrap;
    isnt $rc->[0], qq|ALRM\n|, AFSMTS_croakson $tag }

# vim: set filetype=perl
