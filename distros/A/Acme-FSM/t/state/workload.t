# $Id: workload.t 561 2022-12-29 18:54:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;
use 5.010;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.3 );

use t::TestSuite qw| :switches :run :diag |;
use Test::More;

use Acme::FSM;

our( %st, $stderr, @input );
our @inbase = q|Marriner|;
our %opts   = ( source => \&AFSMTS_shift, diag_level => -t STDOUT ? 10 : 1 );

sub toggle_now ( ) {
    @inbase = $inbase[0] ? ( undef ) x 5 :
  qw| Amelia_Ducat Delta_Magna Stegnos Davros Mawdryn |;
    @input = ( )    }

my %cache =
( tstart => { switch => sub {     1 }, tturn => [ q|workload| ]},
  fstart => { switch => sub {     0 }, fturn => [ q|workload| ]},
  ustart => { switch => sub { undef }, uturn => [ q|workload| ]} );

my @data =
([                               q|no {START}{tturn}{action}|,
  [qw|                                                     |],
  { START     =>
    { switch => sub { 1 }, tturn => [ q|workload|, undef ]},
    workload  => {                   switch => \&AFSMTS_D } },
  [ qr.\Q{workload}(eturn): turn !isa defined .,
                               qr.^die switch .             ]          ],
 [                               q|no {START}{fturn}{action}|,
  [qw|                                             eignore |],
  { START     =>
    { switch => sub { 0 }, fturn => [ q|workload|, undef ]},
    workload  => {                   switch => \&AFSMTS_D } },
                                             qr.^die switch .          ],
 [                                   q|no {START}{uturn}{action}|,
  [qw|                                                 eignore |],
  { START     =>
    { switch => sub { undef }, uturn => [ q|workload|, undef ]},
    workload  => {                       switch => \&AFSMTS_D } },
                                                 qr.^die switch .      ],
 [                        q|unknown {START}{tturn}{action}|,
  [qw|                                                   |],
  { START     =>
    { switch => sub { 1 }, tturn => [qw| workload XIV |]},
    workload  => {                 switch => \&AFSMTS_D } },
  [ qr.\Q{workload}(eturn): turn !isa defined .,
                               qr.^die switch .           ]            ],
 [                        q|unknown {START}{fturn}{action}|,
  [qw|                                           eignore |],
  { START     =>
    { switch => sub { 0 }, fturn => [qw| workload XIV |]},
    workload  => {                 switch => \&AFSMTS_D } },
                                           qr.^die switch .            ],
 [                            q|unknown {START}{uturn}{action}|,
  [qw|                                               eignore |],
  { START     =>
    { switch => sub { undef }, uturn => [qw| workload XIV |]},
    workload  => {                     switch => \&AFSMTS_D } },
                                               qr.^die switch .        ],
 [                        q|no {workload}(tturn)|,
  [qw|                                         |],
  { workload => {                              }},
  [ qr.\Q{workload}(eturn): turn !isa defined .,
         qr.\Q{workload}{switch} !isa defined . ]                      ],
 [                    q|no {workload}(fturn)|,
  [qw|                             eignore |],
  { workload => {                          }},
       qr.\Q{workload}{switch} !isa defined .                          ],
 [                    q|no {workload}(uturn)|,
  [qw|                             eignore |],
  { workload => {                          }},
       qr.\Q{workload}{switch} !isa defined .                          ],
 [                                     q|malformed {workload}(tturn)|,
  [qw|                                                             |],
  { workload  => 
    { switch => \&AFSMTS_T, eturn => q|MDCXLV|, tturn => q|MMCCXV| }},
  [ qr.\Q{workload}(eturn): turn isa (), should be (ARRAY) .,
    qr.\Q{workload}(tturn): turn isa (), should be (ARRAY) .        ]  ],
 [                             q|malformed {workload}(fturn)|,
  [qw|                                             eignore |],
  { workload => { switch => \&AFSMTS_F, fturn => q|MCXCIV| }},
     qr.\Q{workload}(fturn): turn isa (), should be (ARRAY) .          ],
 [                             q|malformed {workload}(uturn)|,
  [qw|                                             eignore |],
  { workload => { switch => \&AFSMTS_U, uturn => q|DCCXLI| }},
     qr.\Q{workload}(uturn): turn isa (), should be (ARRAY) .          ],
 [                                        q|empty {workload}(tturn)|,
  [qw|                                                            |],
  { workload => { switch => \&AFSMTS_T, eturn => [ ], tturn => [ ]}},
  [ qr.\Q{workload}(eturn): state !isa defined .,
    qr.\Q{workload}(tturn): state !isa defined .                   ]   ],
 [                          q|empty {workload}(fturn)|,
  [qw|                                      eignore |],
  { workload => { switch => \&AFSMTS_F, fturn => [ ]}},
          qr.\Q{workload}(fturn): state !isa defined .                 ],
 [                          q|empty {workload}(uturn)|,
  [qw|                                      eignore |],
  { workload => { switch => \&AFSMTS_U, uturn => [ ]}},
          qr.\Q{workload}(uturn): state !isa defined .                 ],
 [                                 q|{workload}{tturn} !isa defined|,
  [qw|                                                            |],
  { workload  =>
    { switch => \&AFSMTS_T, eturn => [ undef ], tturn => [ undef ]}},
  [ qr.\Q{workload}(eturn): state !isa defined .,
    qr.\Q{workload}(tturn): state !isa defined .                   ]   ],
 [                         q|{workload}{fturn} !isa defined|,
  [qw|                                            eignore |],
  { workload => { switch => \&AFSMTS_F, fturn => [ undef ]}},
                qr.\Q{workload}(fturn): state !isa defined .           ],
 [                         q|{workload}{uturn} !isa defined|,
  [qw|                                            eignore |],
  { workload => { switch => \&AFSMTS_U, uturn => [ undef ]}},
                qr.\Q{workload}(uturn): state !isa defined .           ],
 [                            q|[T], (noise/undef)|,
  [qw|                                           |],
  { workload  =>
    { switch =>           \&AFSMTS_T,
      eturn  => [ q|MDCXLV|, undef ],
      tturn  => [ q|MMCCXV|, undef ] }            },
  [ qr.\Q{workload}(eturn): action !isa defined .,
    qr.\Q{workload}(tturn): action !isa defined . ]                    ],
 [                                    q|[F], (noise/undef)|,
  [qw|                                           eignore |],
  { workload  =>
    { switch => \&AFSMTS_F, fturn => [ q|MCXCIV|, undef ]}},
              qr.\Q{workload}(fturn): action !isa defined .            ],
 [                                    q|[U], (noise/undef)|,
  [qw|                                           eignore |],
  { workload  =>
    { switch => \&AFSMTS_U, uturn => [ q|DCCXLI|, undef ]}},
              qr.\Q{workload}(uturn): action !isa defined .            ],
 [                        q|[T], (noise/noise)|,
  [qw|                                       |],
  { workload  =>
    { switch =>              \&AFSMTS_T,
      eturn  => [qw| MDCXLV MDCLXVII |],
      tturn  => [qw| MMCCXV MMCCCXLV |] }     },
  [ qr.\Q{MDCXLV}(MDCLXVII): unknown action .,
    qr.\Q{MMCCXV}(MMCCCXLV): unknown action . ]                        ],
 [                                       q|[F], (noise/noise)|,
  [qw|                                              eignore |],
  { workload  =>
    { switch => \&AFSMTS_F, fturn => [qw| MCXCIV MMMCDXXX |]}},
                     qr.\Q{MCXCIV}(MMMCDXXX): unknown action .         ],
 [                                       q|[U], (noise/noise)|,
  [qw|                                              eignore |],
  { workload  =>
    { switch => \&AFSMTS_U, uturn => [qw| DCCXLI MCDXLVII |]}},
                     qr.\Q{DCCXLI}(MCDXLVII): unknown action .         ],
 [                      q|[T], (noise/NEXT)|,
  [qw|                               push |],
  { workload  =>
    { switch =>          \&AFSMTS_T,
      eturn  => [qw| MDCXLV NEXT |],
      tturn  => [qw| MMCCXV NEXT |] }      },
  [ qr.\Q{MDCXLV}(): record !isa defined .,
    qr.\Q{MMCCXV}(): record !isa defined . ]                           ],
 [                                                q|[F], (noise/NEXT)|,
  [qw|                                                 push eignore |],
  { workload => { switch => \&AFSMTS_F, fturn => [qw| MMCCXV NEXT |]}},
                                qr.\Q{MMCCXV}(): record !isa defined . ],
 [                                                q|[U], (noise/NEXT)|,
  [qw|                                                 push eignore |],
  { workload => { switch => \&AFSMTS_U, uturn => [qw| DCCXLI NEXT |]}},
                                qr.\Q{DCCXLI}(): record !isa defined . ],
 [                      q|[T], trailing undef|,
  [qw|                                 push |],
  { workload  =>
    { switch =>                  \&AFSMTS_T,
      eturn  => [qw| MDCXLV NEXT |, undef ],
      tturn  => [qw| MMCCXV NEXT |, undef ] }},
  [ qr.\Q{MDCXLV}(): record !isa defined .,
    qr.\Q{MMCCXV}(): record !isa defined .   ]                         ],
 [                                          q|[F], trailing undef|,
  [qw|                                             push eignore |],
  { workload  =>
    { switch => \&AFSMTS_F, fturn => [qw| MMCCXV NEXT |, undef ]}},
                            qr.\Q{MMCCXV}(): record !isa defined .     ],
 [                                          q|[U], trailing undef|,
  [qw|                                             push eignore |],
  { workload  =>
    { switch => \&AFSMTS_U, uturn => [qw| DCCXLI NEXT |, undef ]}},
                            qr.\Q{DCCXLI}(): record !isa defined .     ],
 [                       q|[T], trailing noise|,
  [qw|                                  push |],
  { workload  =>
    { switch =>                   \&AFSMTS_T,
      eturn  => [qw| MDCXLV NEXT MDCLXVII |],
      tturn  => [qw| MMCCXV NEXT MMCCCXLV |] }},
  [ qr.\Q{MDCXLV}(): record !isa defined .,
    qr.\Q{MMCCXV}(): record !isa defined .    ]                        ],
 [                                           q|[F], trailing noise|,
  [qw|                                              push eignore |],
  { workload  =>
    { switch => \&AFSMTS_F, fturn => [qw| MCXCIV NEXT MMMCDXXX |]}},
                             qr.\Q{MCXCIV}(): record !isa defined .    ],
 [                                           q|[U], trailing noise|,
  [qw|                                              push eignore |],
  { workload  =>
    { switch => \&AFSMTS_U, uturn => [qw| DCCXLI NEXT MCDXLVII |]}},
                             qr.\Q{DCCXLI}(): record !isa defined .    ] );

plan tests => scalar map {
    ( '' ) x ( 2 - grep( q|eignore| eq $_, @{$_->[1]})) } @data;

foreach my $item ( @data ) {
    $st{$_} = $item->[2]{$_}                       foreach keys %{$item->[2]};
    my $res = ref $item->[3] eq q|ARRAY| ?
                              $item->[3] : [ $item->[3], $item->[3] ];
    toggle_now;
    AFSMTS_wrap;
    is_deeply [  $@ =~ $res->[0], scalar @input ],
    [ !0, 4 - grep $_ eq q|push|, @{$item->[1]} ],
      AFSMTS_croakson qq|empty, $item->[0]|                             unless
        grep $_ eq q|eignore|, @{$item->[1]};
    toggle_now;
    AFSMTS_wrap;
    is_deeply [  $@ =~ $res->[1], scalar @input ],
    [ !0, 4 - grep $_ eq q|push|, @{$item->[1]} ],
      AFSMTS_croakson qq|full, $item->[0]|;
    @input = @inbase        }

# vim: set filetype=perl
