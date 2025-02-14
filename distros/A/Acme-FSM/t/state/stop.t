# $Id: stop.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.5 );

use t::TestSuite qw| :switches :run :diag |;
use Test::More;

use Acme::FSM;

our( %st, $stderr );
our @inbase = ( undef, q|Roffa| );
our @input  =             @inbase;
our %opts   = ( source => \&AFSMTS_shift, diag_level => -t STDOUT ? 10 : 1 );

my %common =
( state      =>           q|STOP|,
  diag_level => $opts{diag_level},
  namespace  =>             undef,
  source     =>     $opts{source},
  dumper     =>             undef,
  queue      => [         undef ] );

my @data =
([                                                  q|no {STOP}|,
  [qw|                                                        |],
  { START => { switch => sub { 1 }, tturn => [qw| STOP DONE |]}},
                  qr.\Q[verify]: {STOP}(): record !isa defined .         ],
 [                             q|no workload|,
  [qw|                                     |],
  { STOP => {                              }},
  [ qr.\Q{STOP}(eturn): turn !isa defined .,
         qr.\Q{STOP}{switch} !isa defined . ]                            ],
 [                                      q|no {STOP}{switch}|,
  [qw|                                                    |],
  { START     =>
    { switch => sub { 1 }, tturn => [qw| workload DONE |]},
    workload  =>
    { switch => sub {               1 },
      eturn  => [qw| STOP      offal |],
      tturn  => [qw| STOP applesauce |]                  } },
                          qr.\Q{STOP}{switch} !isa defined .             ],
 [  q|full-set of turns, no {STOP}{switch}|,
  [qw|                                   |],
  { STOP =>
    { eturn => [ ],
      uturn => [ ],
      tturn => [ ],
      fturn => [ ],
      turns => { } }                      },
         qr.\Q{STOP}{switch} !isa defined .                              ],
 [        q|[D](noise/noise)|,
  [qw|                     |],
  { STOP =>
    { switch => \&AFSMTS_D,
      eturn  => [        ],
      uturn  => [        ],
      tturn  => [        ],
      fturn  => [        ],
      turns  => {        } }},
             qr.^die switch .                                            ],
 [                                          q|[T](noise/noise)|,
  [qw|                                                  pass |],
  { STOP =>
    { switch => \&AFSMTS_T,
      eturn  => [qw| shamble baloney |],
      tturn  => [qw| bull   bullshit |] }                     },
  [[[qw| offal      |], { %common, action =>      q|offal| }],
   [[qw| applesauce |], { %common, action => q|applesauce| }] ]          ],
 [                                                 q|[F](noise/noise)|,
  [qw|                                                 pass eignore |],
  { STOP => { switch => \&AFSMTS_F, fturn => [qw| wander folderol |]}},
  [[qw| applesauce |],          { %common, action => q|applesauce| }]    ],
 [                                                 q|[U](noise/noise)|,
  [qw|                                                 pass eignore |],
  { STOP => { switch => \&AFSMTS_U, uturn => [qw| gibber claptrap |]}},
  [[qw| applesauce |],          { %common, action => q|applesauce| }]    ],
 [                                               q|[_](noise/noise)|,
  [qw|                                               pass eignore |],
  { STOP =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| drivel refuse |]}}},
  [[qw| applesauce |],         { %common, action => q|applesauce| }]     ],
 [                                  q|[workload:T](STOP/noise)|,
  [qw|                                                  pass |],
  { workload  =>
    { switch => sub {               1 },
      eturn  => [qw| STOP      offal |],
      tturn  => [qw| STOP applesauce |] }                     },
  [[[qw| offal      |], { %common, action =>      q|offal| }],
   [[qw| applesauce |], { %common, action => q|applesauce| }] ]          ],
 [                          q|[workload:F](STOP/noise)|,
  [qw|                                  pass eignore |],
  { workload  => { switch => sub { 0 }, fturn => [qw| STOP hogwash |]}},
  [[qw| hogwash |],                 { %common, action => q|hogwash| }]   ],
 [                                 q|[workload:U](STOP/noise)|,
  [qw|                                         pass eignore |],
  { workload  =>
    { switch => sub { undef }, uturn => [qw| STOP garbage |]}},
  [[qw| garbage |],        { %common, action => q|garbage| }]            ],
 [                                    q|[workload:_](STOP/noise)|,
  [qw|                                            pass eignore |],
  { workload  =>
    { switch => sub { 1 }, turns => { 1 => [qw| STOP refuse |]}}},
  [[qw| refuse |],              { %common, action => q|refuse| }]        ],
 [                      q|[workload:T](STOP/undef)|,
  [qw|                                           |],
  { workload  =>
    { switch => sub {          1 },
      eturn  => [ q|STOP|, undef ],
      tturn  => [ q|STOP|, undef ] }              },
  [ qr.\Q{workload}(eturn): action !isa defined .,
    qr.\Q{workload}(tturn): action !isa defined . ]                      ],
 [                                       q|[workload:F](STOP/undef)|,
  [qw|                                                    eignore |],
  { workload => { switch => sub { 0 }, fturn => [ q|STOP|, undef ]}},
                       qr.\Q{workload}(fturn): action !isa defined .     ],
 [                                           q|[workload:U](STOP/undef)|,
  [qw|                                                        eignore |],
  { workload => { switch => sub { undef }, uturn => [ q|STOP|, undef ]}},
                           qr.\Q{workload}(uturn): action !isa defined . ],
 [                                   q|[workload:_](STOP/undef)|,
  [qw|                                                eignore |],
  { workload  =>
    { switch => sub { 1 }, turns => { 1 => [ q|STOP|, undef ]}}},
                  qr.\Q{workload}(turn%1): action !isa defined .         ] );

plan tests => scalar map {
    ( '' ) x (2 - grep q|eignore| eq $_, @{$_->[1]}) } @data;

foreach my $item ( @data ) {
    $st{$_} = $item->[2]{$_}                       foreach keys %{$item->[2]};
    if( grep q|pass| eq $_, @{$item->[1]} )             {
        my $res = grep( q|eignore| eq $_, @{$item->[1]} ) ?
                                    [ undef, $item->[3] ] : $item->[3];
        local $TODO = q|should detect|;
        AFSMTS_wrap;
        AFSMTS_deeply @{$res->[0]}, qq|empty, $item->[0]|               unless
          grep $_ eq q|eignore|, @{$item->[1]};
        AFSMTS_wrap;
        AFSMTS_deeply @{$res->[1]}, qq|full, $item->[0]| }
    else                                                {
        my $res = ref $item->[3] eq q|ARRAY| ?
                                  $item->[3] : [ $item->[3], $item->[3] ];
        AFSMTS_wrap;
        is_deeply [ $@ =~ $res->[0], scalar @input ], [ !0, 1 ],
          AFSMTS_croakson qq|empty, $item->[0]|                         unless
          grep $_ eq q|eignore|, @{$item->[1]};
        AFSMTS_wrap;
        is_deeply [ $@ =~ $res->[1], scalar @input ], [ !0, 0 ],
          AFSMTS_croakson qq|full, $item->[0]|           }
    @input = @inbase        }

# vim: set filetype=perl
