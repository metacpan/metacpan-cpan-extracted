# $Id: break.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2013, 2022 Eric Pozharski <whynot@pozharski.name>
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
our @inbase = (                                            undef, q|Roffa| );
our @input  =                                                        @inbase;
our %opts   = ( source => \&AFSMTS_shift, diag_level => -t STDOUT ? 10 : 1 );

my %common =
( state      =>       q|CONTINUE|,
  diag_level => $opts{diag_level},
  namespace  =>             undef,
  source     =>     $opts{source},
  dumper     =>             undef,
  queue      => [         undef ] );

my @data =
([                                                  q|no {BREAK}|,
  [qw|                                                         |],
  { START => { switch => sub { 1 }, tturn => [qw| BREAK DONE |]}},
                  qr.\Q[verify]: {BREAK}(): record !isa defined .    ],
 [                              q|no workload|,
  [qw|                                      |],
  { BREAK => {                              }},
  [ qr.\Q{BREAK}(eturn): turn !isa defined .,
                qr.\Q{switch} !isa defined . ]                       ],
 [                                    q|[T], no {BREAK}{switch}|,
  [qw|                                                eignore |],
  { START => { switch => sub { 1 }, tturn => [qw| workload |]},
    workload  => 
    { switch => sub { 1 }, tturn => [qw| BREAK DONE |]       } },
                             qr.\Q{BREAK}{switch} !isa defined .     ],
 [                             q|[F], no {BREAK}{switch}|,
  [qw|                                         eignore |],
  { workload  => 
    { switch => sub { 0 }, fturn => [qw| BREAK DONE |] }},
                      qr.\Q{BREAK}{switch} !isa defined .            ],
 [                                 q|[U], no {BREAK}{switch}|,
  [qw|                                             eignore |],
  { workload  => 
    { switch => sub { undef }, uturn => [qw| BREAK DONE |] }},
                          qr.\Q{BREAK}{switch} !isa defined .        ],
 [                 q|[_], no {BREAK}{switch}|,
  [qw|                             |],
  { workload  =>
    { switch => sub {                  1 },
      eturn  => [qw|         BREAK FAIL |],
      turns  => { 1 => [qw| BREAK DONE |]} }},
          qr.\Q{BREAK}{switch} !isa defined .                        ],
 [ q|full-set of turns, no {BREAK}{switch}|,
  [qw|                                   |],
  { BREAK =>
    { eturn => [ ],
      uturn => [ ],
      tturn => [ ],
      fturn => [ ],
      turns => { }                       }},
        qr.\Q{BREAK}{switch} !isa defined .                          ],
 [                              q|[D]|,
  [qw|                              |],
  { BREAK => { switch => \&AFSMTS_D }},
                      qr.^die switch .                               ],
 [      q|[D](noise/noise)x4|,
  [qw|                     |],
  { BREAK =>
    { switch => \&AFSMTS_D,
      eturn  => [        ],
      uturn  => [        ],
      tturn  => [        ],
      fturn  => [        ],
      turns  => {        } }},
             qr.^die switch .                                        ],
 [                              q|[T](noise/noise)|,
  [qw|                                      pass |],
  { BREAK =>
    { switch =>            \&AFSMTS_T,
      eturn  => [qw| stabce ace432 |],
      tturn  => [qw| st7b10 ac3bca |] }},
  [[[qw| FAIL |], { %common, action => q|FAIL| }],
   [[qw| DONE |], { %common, action => q|DONE| }] ]                  ],
 [                              q|[F](noise/noise)|,
  [qw|                              pass eignore |],
  { BREAK =>
    { switch =>                       \&AFSMTS_F,
      fturn  => [qw| st1da3 acd140 |] }        },
  [[qw| DONE |], { %common, action => q|DONE| }]                     ],
 [                              q|[U](noise/noise)|,
  [qw|                              pass eignore |],
  { BREAK =>
    { switch =>                       \&AFSMTS_U,
      uturn  => [qw| st3ff5 ac0872 |] }},
  [[qw| DONE |],    { %common, action => q|DONE| }]                  ],
 [                                               q|[_](noise/noise)|,
  [qw|                                               pass eignore |],
  { BREAK =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| st676c ac7080 |]}}},
  [[qw| DONE |],                     { %common, action => q|DONE| }] ],
 [                             q|[T]{workload}(BREAK/noise)|,
  [qw|                                               pass |],
  { workload  =>
    { switch => sub {            1 },
      eturn  => [qw| BREAK ace432 |],
      tturn  => [qw| BREAK ac3bca |] }                },
  [[[qw| ace432 |], { %common, action => q|ace432| }],
   [[qw| ac3bca |], { %common, action => q|ac3bca| }] ],             ],
 [                           q|[F]{workload}(BREAK/noise)|,
  [qw|                                     pass eignore |],
  { workload  =>
    { switch => sub { 0 }, fturn => [qw| BREAK acd140 |]}},
  [[qw| acd140 |],       { %common, action => q|acd140| }]           ],
 [                                q|[U]{workload}(BREAK/noise)|,
  [qw|                                          pass eignore |],
  { workload  =>
    { switch => sub { undef }, uturn  => [qw| BREAK ac0872 |]}},
  [[qw| ac0872 |],            { %common, action => q|ac0872| }]      ],
 [                                   q|[_]{workload}(BREAK/noise)|,
  [qw|                                             pass eignore |],
  { workload =>
    { switch => sub { 1 }, turns => { 1 => [qw| BREAK ac7080 |]}}},
  [[qw| ac7080 |],               { %common, action => q|ac7080| }]   ],
 [                    q|[T]{workload}(BREAK/undef)|,
  [qw|                                           |],
  { workload  =>
    { switch => sub {           1 },
      eturn  => [ q|BREAK|, undef ],
      tturn  => [ q|BREAK|, undef ] }             }, 
  [ qr.\Q{workload}(eturn): action !isa defined .,
    qr.\Q{workload}(tturn): action !isa defined . ],                 ],
 [                          q|[F]{workload}(BREAK/undef)|,
  [qw|                                         eignore |],
  { workload  =>
    { switch => sub { 0 }, fturn => [ q|BREAK|, undef ]}}, 
            qr.\Q{workload}(fturn): action !isa defined .            ],
 [                              q|[U]{workload}(BREAK/undef)|,
  [qw|                                             eignore |],
  { workload  =>
    { switch => sub { undef }, uturn => [ q|BREAK|, undef ]}}, 
                qr.\Q{workload}(uturn): action !isa defined .        ],
 [                                  q|[_]{workload}(BREAK/undef)|,
  [qw|                                                 eignore |],
  { workload  =>
    { switch => sub { 1 }, turns => { 1 => [ q|BREAK|, undef ]}}},
                   qr.\Q{workload}(turn%1): action !isa defined .    ] );

plan tests => scalar map {
    ( '' ) x (2 - grep q|eignore| eq $_, @{$_->[1]}) } @data;

foreach my $item ( @data ) {
    $st{$_} = $item->[2]{$_}                       foreach keys %{$item->[2]};
    if( grep q|pass| eq $_, @{$item->[1]} )             {
        my $res = grep( q|eignore| eq $_, @{$item->[1]} ) ?
                                    [ undef, $item->[3] ] : $item->[3];
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
