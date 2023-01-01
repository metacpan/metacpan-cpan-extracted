# $Id: start.t 484 2013-05-09 20:56:46Z whynot $
# Copyright 2012, 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.3 );

use t::TestSuite qw| :switches :run :diag |;
use Test::More;

use Acme::FSM;

our( %st, $bb, $stderr, @input );
our @inbase = q|detritus|;
our %opts   = ( source => \&AFSMTS_shift, diag_level => -t STDOUT ? 10 : 1 );

sub toggle_now ( ) {
    @inbase = $inbase[0] ? ( undef ) x 5 :
  qw| twoflower pseudopolis magrat_garlick offler granny_weatherwax |;
    @input = ( )    }

my @data =
([ q|empty state table|, [qw| void |], { }, qr.\Q{switch} !isa defined . ],
 [       q|empty (START) record|,
  [qw|                   void |],
  { START => {                }},
    qr.\Q{switch} !isa defined .                                         ],
 [                                            q|no (START) state|,
  [qw|                                                    void |],
  { exit => { eturn => [qw| exit DONE |], switch => \&AFSMTS_D }},
                                     qr.\Q{switch} !isa defined .        ],
 [                              q|[D]|,
  [qw|                         void |],
  { START => { switch => \&AFSMTS_D }},
                       qr.^die switch.                                   ],
 [                              q|[T]|,
  [qw|                         void |],
  { START => { switch => \&AFSMTS_T }},
     qr.\Q(tturn): turn !isa defined .                                   ],
 [                              q|[F]|,
  [qw|                 void eignore |],
  { START => { switch => \&AFSMTS_F }},
     qr.\Q(fturn): turn !isa defined .                                   ],
 [                              q|[U]|,
  [qw|                 void eignore |],
  { START => { switch => \&AFSMTS_U }},
     qr.\Q(uturn): turn !isa defined .                                   ],
 [                          q|[T], tturn !isa defined|,
  [qw|                                         void |],
  { START => { switch => \&AFSMTS_T, tturn => undef }},
                     qr.\Q(tturn): turn !isa defined .                   ],
 [                          q|[F], fturn !isa defined|,
  [qw|                                 void eignore |],
  { START => { switch => \&AFSMTS_F, fturn => undef }},
                     qr.\Q(fturn): turn !isa defined .                   ],
 [                          q|[U], uturn !isa defined|,
  [qw|                                 void eignore |],
  { START => { switch => \&AFSMTS_U, uturn => undef }},
                     qr.\Q(uturn): turn !isa defined .                   ],
 [                                  q|[T], turns !isa defined|,
  [qw|                                         void eignore |],
  { START => { switch => \&AFSMTS_T, turns => { 1 => undef }}},
                            qr.\Q(turn%1): turn !isa defined .           ],
 [                              q|[T], tturn isa scalar|,
  [qw|                                           void |],
  { START => { switch => \&AFSMTS_T, tturn => q|Ursa| }},
          qr.\Q(tturn): turn isa (), should be (ARRAY) .                 ],
 [                              q|[F], fturn isa scalar|,
  [qw|                                   void eignore |],
  { START => { switch => \&AFSMTS_F, fturn => q|Ursa| }},
          qr.\Q(fturn): turn isa (), should be (ARRAY) .                 ],
 [                              q|[U], uturn isa scalar|,
  [qw|                                   void eignore |],
  { START => { switch => \&AFSMTS_U, uturn => q|Ursa| }},
          qr.\Q(uturn): turn isa (), should be (ARRAY) .                 ],
 [                                      q|[T], turns isa scalar|,
  [qw|                                           void eignore |],
  { START => { switch => \&AFSMTS_T, turns => { 1 => q|Ursa| }}},
                 qr.\Q(turn%1): turn isa (), should be (ARRAY) .         ],
 [                    q|[T], tturn isa empty ARAAY|,
  [qw|                                      void |],
  { START => { switch => \&AFSMTS_T, tturn => [ ]}},
                 qr.\Q(tturn): state !isa defined .                      ],
 [                    q|[F], fturn isa empty ARRAY|,
  [qw|                              void eignore |],
  { START => { switch => \&AFSMTS_F, fturn => [ ]}},
                 qr.\Q(fturn): state !isa defined .                      ],
 [                    q|[U], uturn isa empty ARRAY|,
  [qw|                              void eignore |],
  { START => { switch => \&AFSMTS_U, uturn => [ ]}},
                 qr.\Q(uturn): state !isa defined .                      ],
 [                            q|[T], turns isa empty ARRAY|,
  [qw|                                      void eignore |],
  { START => { switch => \&AFSMTS_T, turns => { 1 => [ ]}}},
                        qr.\Q(turn%1): state !isa defined .              ],
 [             q|[T], state isa undef, action is missing|,
  [qw|                                            void |],
  { START => { switch => \&AFSMTS_T, tturn => [ undef ]}},
                       qr.\Q(tturn): state !isa defined .                ],
 [             q|[F], state isa undef, action is missing|,
  [qw|                                    void eignore |],
  { START => { switch => \&AFSMTS_F, fturn => [ undef ]}},
                       qr.\Q(fturn): state !isa defined .                ],
 [             q|[U], state isa undef, action is missing|,
  [qw|                                    void eignore |],
  { START => { switch => \&AFSMTS_U, uturn => [ undef ]}},
                       qr.\Q(uturn): state !isa defined .                ],
 [                    q|[T_], state isa undef, action is missing|,
  [qw|                                            void eignore |],
  { START => { switch => \&AFSMTS_T, turns => { 1 => [ undef ]}}},
                               qr.\Q(turn%1): state !isa defined.        ],
 [                     q|[T], state isa undef, action isa undef|,
  [qw|                                                   void |],
  { START => { switch => \&AFSMTS_T, tturn => [ undef, undef ]}},
                              qr.\Q(tturn): state !isa defined .         ],
 [                     q|[F], state isa undef, action isa undef|,
  [qw|                                           void eignore |],
  { START => { switch => \&AFSMTS_F, fturn => [ undef, undef ]}},
                              qr.\Q(fturn): state !isa defined .         ],
 [                     q|[U], state isa undef, action isa undef|,
  [qw|                                           void eignore |],
  { START => { switch => \&AFSMTS_U, uturn => [ undef, undef ]}},
                              qr.\Q(uturn): state !isa defined .         ],
 [                   q|[T_], state isa undef, action isa undef|,
  [qw|                                          void eignore |],
  { START =>
    { switch => \&AFSMTS_T, turns => { 1 => [ undef, undef ]}}},
                            qr.\Q(turn%1): state !isa defined .          ],
 [                          q|[T], state is noise, action isa undef|,
  [qw|                                                            |],
  { START => { switch => \&AFSMTS_T, tturn => [ q|zircon|, undef ]}},
                              qr.\Q{zircon}(): record !isa defined .     ],
 [                           q|[F], state is noise, action isa undef|,
  [qw|                                                     eignore |],
  { START => { switch => \&AFSMTS_F, fturn => [ q|jadeite|, undef ]}},
                              qr.\Q{jadeite}(): record !isa defined .    ],
 [                             q|[U], state is noise, action isa undef|,
  [qw|                                                       eignore |],
  { START => { switch => \&AFSMTS_U, uturn => [ q|turquoise|, undef ]}},
                              qr.\Q{turquoise}(): record !isa defined .  ],
 [                        q|[T_], state is noise, action isa undef|,
  [qw|                                                   eignore |],
  { START =>
    { switch => \&AFSMTS_T, turns => { 1 => [ q|garnet|, undef ]}}},
                             qr.\Q{garnet}(): record !isa defined .      ],
 [                   q|(START/noise)|,
  [qw|                        void |],
  { START =>
    { eturn => [ ],
      uturn => [ ],
      tturn => [ ],
      fturn => [ ],
      turns => { } }                },
         qr.\Q{switch} !isa defined .                                    ],
 [                      q|[T](START/noise)|,
  [qw|                                   |],
  { START =>
    { switch =>          \&AFSMTS_T,
      eturn  => [qw| START Rilla |],
      tturn  => [qw| START Trigo |] }     },
  [ qr.\Q{START}(Rilla): unknown action .,
    qr.\Q{START}(Trigo): unknown action . ]                              ],
 [                                              q|[F](START/noise)|,
  [qw|                                                   eignore |],
  { START => { switch => \&AFSMTS_F, fturn => [qw| START  Argo |]}},
                               qr.\Q{START}(Argo): unknown action .      ],
 [                                              q|[U](START/noise)|,
  [qw|                                                   eignore |],
  { START => { switch => \&AFSMTS_U, uturn => [qw| START Peric |]}},
                              qr.\Q{START}(Peric): unknown action .      ],
 [                                             q|[_](START/noise)|,
  [qw|                                                  eignore |],
  { START =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| START Janno |]}}},
                             qr.\Q{START}(Janno): unknown action .       ],
 [                 q|[T](START/NEXT)|,
  [qw|                        todo |],
  { START =>
    { switch =>         \&AFSMTS_T,
      eturn  => [qw| START NEXT |],
      tturn  => [qw| START NEXT |] }}                                    ],
 [                                              q|[F](START/NEXT)|,
  [qw|                                             eignore todo |],
  { START => { switch => \&AFSMTS_F, fturn => [qw| START NEXT |]}}       ],
 [                                              q|[U](START/NEXT)|,
  [qw|                                             eignore todo |],
  { START => { switch => \&AFSMTS_U, uturn => [qw| START NEXT |]}}       ],
 [                                             q|[_](START/NEXT)|,
  [qw|                                            eignore todo |],
  { START =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| START NEXT |]}}}        ],
 [                             q|[T](noise/noise)|,
  [qw|                                          |],
  { START =>
    { switch =>           \&AFSMTS_T,
      eturn  => [qw| agate  Rilla |],
      tturn  => [qw| zircon Trigo |] }           },
  qr.\Q[verify]: {zircon}(): record !isa defined .                       ],
 [                                               q|[F](noise/noise)|,
  [qw|                                                    eignore |],
  { START => { switch => \&AFSMTS_F, fturn => [qw| jadeite Argo |]}},
                   qr.\Q[verify]: {jadeite}(): record !isa defined .     ],
 [                                                  q|[U](noise/noise)|,
  [qw|                                                       eignore |],
  { START => { switch => \&AFSMTS_U, uturn => [qw| turquoise Peric |]}},
                    qr.\Q[verify]: {turquoise}(): record !isa defined .  ],
 [                                              q|[_](noise/noise)|,
  [qw|                                                   eignore |],
  { START =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| garnet Janno |]}}},
                   qr.\Q[verify]: {garnet}(): record !isa defined .      ],
 [                                          q|[T], trailing undef|,
  [qw|                                                          |],
  { START =>  
    { switch => \&AFSMTS_T, tturn => [ q|zircon|, undef, undef ]}},
                            qr.\Q{zircon}(): record !isa defined .       ],
 [                                           q|[F], trailing undef|,
  [qw|                                                   eignore |],
  { START =>
    { switch => \&AFSMTS_F, fturn => [ q|jadeite|, undef, undef ]}},
                            qr.\Q{jadeite}(): record !isa defined .      ],
 [                                             q|[U], trailing undef|,
  [qw|                                                     eignore |],
  { START =>
    { switch => \&AFSMTS_U, uturn => [ q|turquoise|, undef, undef ]}},
                            qr.\Q{turquoise}(): record !isa defined .    ],
 [                              q|[_], trailing undef|,
  [qw|                                      eignore |],
  { START =>
    { switch =>                          \&AFSMTS_T,
      turns  => { 1 => [ q|garnet|, undef, undef ]} }},
                  qr.\Q{garnet}(): record !isa defined .                 ],
 [                                             q|[T], trailing noise|,
  [qw|                                                             |],
  { START =>
    { switch => \&AFSMTS_T, tturn => [ q|zircon|, undef, q|Rilla| ]}},
                               qr.\Q{zircon}(): record !isa defined .    ],
 [                                              q|[F], trailing noise|,
  [qw|                                                      eignore |],
  { START =>
    { switch => \&AFSMTS_F, fturn => [ q|jadeite|, undef, q|Rilla| ]}},
                               qr.\Q{jadeite}(): record !isa defined .   ],
 [                                                q|[U], trailing noise|,
  [qw|                                                        eignore |],
  { START =>
    { switch => \&AFSMTS_U, uturn => [ q|truquoise|, undef, q|Rilla| ]}},
                               qr.\Q{truquoise}(): record !isa defined . ],
 [                                 q|[_], trailing noise|,
  [qw|                                         eignore |],
  { START =>
    { switch =>                             \&AFSMTS_T,
      turns  => { 1 => [ q|garnet|, undef, q|Rilla| ]} }},
                   qr.\Q{garnet}(): record !isa defined .                ] );

plan tests =>
  scalar map { ( '' ) x ( 2 - grep( q|eignore| eq $_, @{$_->[1]})) } @data;

foreach my $item ( @data ) {
    %st = %{$item->[2]};
    if( grep q|todo| eq $_, @{$item->[1]} )                       {
        local $TODO = q|should detect|;
        toggle_now;
        AFSMTS_wrap;
        unlike $@, qr<^ALRM>, AFSMTS_croakson qq|empty, $item->[0]|     unless
          grep $_ eq q|eignore|, @{$item->[1]};
        toggle_now;
        AFSMTS_wrap;
        unlike $@, qr<^ALRM>, AFSMTS_croakson qq|full, $item->[0]| }
    else                                                          {
        my $res = ref $item->[3] eq q|ARRAY| ?
                                  $item->[3] : [ $item->[3], $item->[3] ];
        toggle_now;
        AFSMTS_wrap;
        is_deeply [                $@ =~ $res->[0], scalar @input ],
        [ !0, scalar( grep q|void| eq $_, @{$item->[1]} ) ? 0 : 4 ],
          AFSMTS_croakson qq|empty, $item->[0]|                         unless
            grep $_ eq q|eignore|, @{$item->[1]};
        toggle_now;
        AFSMTS_wrap;
        is_deeply [                $@ =~ $res->[1], scalar @input ],
        [ !0, scalar( grep q|void| eq $_, @{$item->[1]} ) ? 0 : 4 ],
          AFSMTS_croakson qq|full, $item->[0]|                     }
    @input = @inbase        }

# vim: set filetype=perl
