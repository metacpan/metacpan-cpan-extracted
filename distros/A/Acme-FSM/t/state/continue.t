# $Id: continue.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.5 );

use t::TestSuite qw| :switches :wraps :run :diag |;
use Test::More;

use Acme::FSM;

our( %st, $stderr, @inbase, @input );
our %opts = ( source => \&AFSMTS_shift, diag_level => -t STDOUT ? 10 : 1 );

sub toggle_now ( ) {
    @inbase = $inbase[0] ? ( undef ) x 5 : qw| mannaro | x 5;
    @input = ( )    }

my $method = q|process|;

sub combo_now ( ) { toggle_now; AFSMTS_wrap; AFSMTS_method_wrap $method }

my %common =
( state      =>       q|CONTINUE|,
  diag_level => $opts{diag_level},
  namespace  =>             undef,
  source     =>     $opts{source},
  dumper     =>             undef,
  queue      => [         undef ] );

my @data =
([               q|no (CONTINUE) record|,
  [qw|                                |],
  {                                    },
  qr.\Q{CONTINUE}{switch} !isa defined .                            ],
 [            q|empty (CONTINUE) record|,
  [qw|                                |],
  { CONTINUE => {                     }},
  qr.\Q{CONTINUE}{switch} !isa defined .                            ],
 [                                 q|[D]|,
  [qw|                                 |],
  { CONTINUE => { switch => \&AFSMTS_D }},
                          qr.^die switch.                           ],
 [                                     q|[T]|,
  [qw|                                     |],
  { CONTINUE => {     switch => \&AFSMTS_T }},
  qr.\Q{CONTINUE}(tturn): turn !isa defined .                       ],
 [                                     q|[F]|,
  [qw|                             eignore |],
  { CONTINUE => {     switch => \&AFSMTS_F }},
  qr.\Q{CONTINUE}(fturn): turn !isa defined .                       ],
 [                                     q|[U]|,
  [qw|                             eignore |],
  { CONTINUE => {     switch => \&AFSMTS_U }},
  qr.\Q{CONTINUE}(uturn): turn !isa defined .                       ],
 [                             q|[T], tturn !isa defined|,
  [qw|                                                 |],
  { CONTINUE => { switch => \&AFSMTS_T, tturn => undef }},
              qr.\Q{CONTINUE}(tturn): turn !isa defined .           ],
 [                             q|[F], fturn !isa defined|,
  [qw|                                         eignore |],
  { CONTINUE => { switch => \&AFSMTS_F, fturn => undef }},
              qr.\Q{CONTINUE}(fturn): turn !isa defined .           ],
 [                             q|[U], uturn !isa defined|,
  [qw|                                         eignore |],
  { CONTINUE => { switch => \&AFSMTS_U, uturn => undef }},
              qr.\Q{CONTINUE}(uturn): turn !isa defined .           ],
 [                                     q|[_], turns !isa defined|,
  [qw|                                                 eignore |],
  { CONTINUE => { switch => \&AFSMTS_T, turns => { 1 => undef }}},
                     qr.\Q{CONTINUE}(turn%1): turn !isa defined .   ],
 [                                q|[T], tturn isa scalar|,
  [qw|                                                  |],
  { CONTINUE => {  switch => \&AFSMTS_T, tturn => q|IC| }},
  qr.\Q{CONTINUE}(tturn): turn isa (), should be (ARRAY) .          ],
 [                                q|[F], fturn isa scalar|,
  [qw|                                          eignore |],
  { CONTINUE => {  switch => \&AFSMTS_F, fturn => q|SC| }},
  qr.\Q{CONTINUE}(fturn): turn isa (), should be (ARRAY) .          ],
 [                                q|[U], fturn isa scalar|,
  [qw|                                          eignore |],
  { CONTINUE => {  switch => \&AFSMTS_U, uturn => q|RQ| }},
  qr.\Q{CONTINUE}(uturn): turn isa (), should be (ARRAY) .          ],
 [                                       q|[_], turns isa scalar|,
  [qw|                                                 eignore |],
  { CONTINUE => { switch => \&AFSMTS_T, turns => { 1 => q|BJ| }}},
        qr.\Q{CONTINUE}(turn%1): turn isa (), should be (ARRAY) .   ],
 [                       q|[T], tturn isa empty ARAAY|,
  [qw|                                              |],
  { CONTINUE => { switch => \&AFSMTS_T, tturn => [ ]}},
          qr.\Q{CONTINUE}(tturn): state !isa defined .              ],
 [                       q|[F], fturn isa empty ARRAY|,
  [qw|                                      eignore |],
  { CONTINUE => { switch => \&AFSMTS_F, fturn => [ ]}},
          qr.\Q{CONTINUE}(fturn): state !isa defined .              ],
 [                       q|[U], fturn isa empty ARRAY|,
  [qw|                                      eignore |],
  { CONTINUE => { switch => \&AFSMTS_U, uturn => [ ]}},
          qr.\Q{CONTINUE}(uturn): state !isa defined .              ],
 [                               q|[_], turns isa empty ARRAY|,
  [qw|                                              eignore |],
  { CONTINUE => { switch => \&AFSMTS_T, turns => { 1 => [ ]}}},
                 qr.\Q{CONTINUE}(turn%1): state !isa defined .      ],
 [                q|[T], state isa undef, action is missing|,
  [qw|                                                    |],
  { CONTINUE => { switch => \&AFSMTS_T, tturn => [ undef ]}},
                qr.\Q{CONTINUE}(tturn): state !isa defined .        ],
 [                q|[F], state isa undef, action is missing|,
  [qw|                                            eignore |],
  { CONTINUE => { switch => \&AFSMTS_F, fturn => [ undef ]}},
                qr.\Q{CONTINUE}(fturn): state !isa defined .        ],
 [                q|[U], state isa undef, action is missing|,
  [qw|                                            eignore |],
  { CONTINUE => { switch => \&AFSMTS_U, uturn => [ undef ]}},
                qr.\Q{CONTINUE}(uturn): state !isa defined .        ],
 [            q|[_], state isa undef, action is missing|,
  [qw|                                        eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, turns => { 1 => [ undef ]}}},
           qr.\Q{CONTINUE}(turn%1): state !isa defined .            ],
 [                        q|[T], state isa undef, action isa undef|,
  [qw|                                                           |],
  { CONTINUE => { switch => \&AFSMTS_T, tturn => [ undef, undef ]}},
                       qr.\Q{CONTINUE}(tturn): state !isa defined . ],
 [                        q|[F], state isa undef, action isa undef|,
  [qw|                                                   eignore |],
  { CONTINUE => { switch => \&AFSMTS_F, fturn => [ undef, undef ]}},
                       qr.\Q{CONTINUE}(fturn): state !isa defined . ],
 [                        q|[U], state isa undef, action isa undef|,
  [qw|                                                   eignore |],
  { CONTINUE => { switch => \&AFSMTS_U, uturn => [ undef, undef ]}},
                       qr.\Q{CONTINUE}(uturn): state !isa defined . ],
 [                    q|[_], state isa undef, action isa undef|,
  [qw|                                               eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, turns => { 1 => [ undef, undef ]}}},
                  qr.\Q{CONTINUE}(turn%1): state !isa defined .     ],
 [                         q|[T], state is noise, action isa undef|,
  [qw|                                                     shift |],
  { CONTINUE => { switch => \&AFSMTS_T, tturn => [ q|IC|, undef ]}},
                                 qr.\Q{IC}(): record !isa defined . ],
 [                         q|[F], state is noise, action isa undef|,
  [qw|                                             shift eignore |],
  { CONTINUE => { switch => \&AFSMTS_F, fturn => [ q|SC|, undef ]}},
                                 qr.\Q{SC}(): record !isa defined . ],
 [                         q|[U], state is noise, action isa undef|,
  [qw|                                             shift eignore |],
  { CONTINUE => { switch => \&AFSMTS_U, uturn => [ q|RQ|, undef ]}},
                                 qr.\Q{RQ}(): record !isa defined . ],
 [                     q|[_], state is noise, action isa undef|,
  [qw|                                         shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, turns => { 1 => [ q|BJ|, undef ]}}},
                             qr.\Q{BJ}(): record !isa defined .     ],
 [                        q|[T], state is noise, action is noise|,
  [qw|                                                   shift |],
  { CONTINUE => { switch => \&AFSMTS_T, tturn => [qw| IC AMS |]}},
                               qr.\Q{IC}(): record !isa defined .   ],
 [                        q|[F], state is noise, action is noise|,
  [qw|                                           shift eignore |],
  { CONTINUE => { switch => \&AFSMTS_F, fturn => [qw| SC FLL |]}},
                               qr.\Q{SC}(): record !isa defined .   ],
 [                        q|[U], state is noise, action is noise|,
  [qw|                                           shift eignore |],
  { CONTINUE => { switch => \&AFSMTS_U, uturn => [qw| RQ AFG |]}},
                               qr.\Q{RQ}(): record !isa defined .   ],
 [                    q|[_], state is noise, action is noise|,
  [qw|                                       shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| BJ DBS |]}}},
                           qr.\Q{BJ}(): record !isa defined .       ],
 [                                      q|[T], trailing undef|,
  [qw|                                                shift |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, tturn => [ q|IC|, undef, undef ]}},
                            qr.\Q{IC}(): record !isa defined .      ],
 [                                      q|[F], trailing undef|,
  [qw|                                        shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_F, fturn => [ q|SC|, undef, undef ]}},
                            qr.\Q{SC}(): record !isa defined .      ],
 [                                      q|[U], trailing undef|,
  [qw|                                        shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_U, uturn => [ q|RQ|, undef, undef ]}},
                            qr.\Q{RQ}(): record !isa defined .      ],
 [                          q|[_], trailing undef|,
  [qw|                            shift eignore |],
  { CONTINUE  =>
    { switch =>                       \&AFSMTS_T,
      turns  => { 1 => [ q|BJ|, undef, undef ]}} },
                qr.\Q{BJ}(): record !isa defined .                  ],
 [                                       q|[T], trailing noise|,
  [qw|                                                 shift |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, tturn  => [ q|IC|, undef, q|JD| ]}},
                             qr.\Q{IC}(): record !isa defined .     ],
 [                                       q|[F], trailing noise|,
  [qw|                                         shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_F, fturn  => [ q|SC|, undef, q|PB| ]}},
                             qr.\Q{SC}(): record !isa defined .     ],
 [                                       q|[U], trailing noise|,
  [qw|                                         shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_U, uturn  => [ q|RQ|, undef, q|RC| ]}},
                             qr.\Q{RQ}(): record !isa defined .     ],
 [                          q|[_], trailing noise|,
  [qw|                            shift eignore |],
  { CONTINUE  =>
    { switch =>                       \&AFSMTS_T,
      turns  => { 1 => [ q|BJ|, undef, q|MF| ]}} },
                qr.\Q{BJ}(): record !isa defined .                  ],
 [                   q|(CONTINUE/noise)|,
  [qw|                                |],
  { CONTINUE =>
    { eturn => [ ],
      uturn => [ ],
      tturn => [ ],
      fturn => [ ],
      turns => { } }                   },
  qr.\Q{CONTINUE}{switch} !isa defined .                            ],
 [                   q|[T](CONTINUE/noise)|,
  [qw| shift                             |],
  { CONTINUE  =>
    { switch =>          \&AFSMTS_T,
      eturn  => [qw| CONTINUE JR |],
      tturn  => [qw| CONTINUE EL |] }     },
  [ qr.\Q{CONTINUE}(JR): unknown action .,
    qr.\Q{CONTINUE}(EL): unknown action . ]                         ],
 [                                  q|[F](CONTINUE/noise)|,
  [qw|                                    shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_F, fturn => [qw| CONTINUE MB |]}},
                     qr.\Q{CONTINUE}(MB): unknown action .          ],
 [                                  q|[U](CONTINUE/noise)|,
  [qw|                                    shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_U, uturn => [qw| CONTINUE GP |]}},
                     qr.\Q{CONTINUE}(GP): unknown action .          ],
 [                                           q|[_](CONTINUEnoise)|,
  [qw|                                            shift eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_T, turns => { 1 => [qw| CONTINUE HC |]}}},
                             qr.\Q{CONTINUE}(HC): unknown action .  ],
 [                 q|[T](CONTINUE/NEXT)|,
  [qw|                           todo |],
  { CONTINUE  =>
    { switch =>            \&AFSMTS_T,
      eturn  => [qw| CONTINUE NEXT |],
      tturn  => [qw| CONTINUE NEXT |] }}                            ],
 [                                     q|[F](CONTINUE/NEXT)|,
  [qw|                                       todo eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_F, fturn => [qw| CONTINUE NEXT |]}}        ],
 [                                     q|[U](CONTINUE/NEXT)|,
  [qw|                                       todo eignore |],
  { CONTINUE  =>
    { switch => \&AFSMTS_U, uturn => [qw| CONTINUE NEXT |]}}        ],
 [                         q|[_](CONTINUE/NEXT)|,
  [qw|                           todo eignore |],
  { CONTINUE  =>
    { switch =>                     \&AFSMTS_T,
      turns  => { 1 => [qw| CONTINUE NEXT |]}} }                    ] );

plan tests => 2 + scalar map {
    ( '' ) x ( 2 - grep( q|eignore| eq $_, @{$_->[1]})) } @data;

%st =
( START    => { switch => sub { 1 }, tturn => [qw| workload |]},
  workload =>
  { switch  =>              \&AFSMTS_T,
    eturn   => [qw| BREAK    bodine |],
    tturn   => [qw| BREAK godolphin |]                        },
  BREAK    => {                          switch => \&AFSMTS_T } );
AFSMTS_wrap;
AFSMTS_deeply @{[[qw| bodine |], { %common, action => q|bodine| }]},
  qq|FST sample consumes empty|;
toggle_now;
AFSMTS_wrap;
AFSMTS_deeply
@{[[qw|                                                  godolphin |],
   { %common, action => q|godolphin|, queue => [ q|mannaro|, undef ]} ]},
  qq|FST sample consumes one|;

foreach my $item ( @data ) {
    $st{$_} = $item->[2]{$_}                       foreach keys %{$item->[2]};
    if( grep q|todo| eq $_, @{$item->[1]} )       {
        local $TODO = q|should detect|;
        combo_now;
        unlike $@, qr.^ALRM., qq|empty, $item->[0]|                     unless
          grep $_ eq q|eignore|, @{$item->[1]};
        combo_now;
        unlike $@, qr.^ALRM., qq|full, $item->[0]| }
    else                                          {
        my $res = ref $item->[3] eq q|ARRAY| ?
                                  $item->[3] : [ $item->[3], $item->[3] ];
        combo_now;
        is_deeply [                 $@ =~ $res->[0], scalar @input ],
        [ !0, scalar( grep q|shift| eq $_, @{$item->[1]} ) ? 3 : 4 ],
          AFSMTS_croakson qq|empty, $item->[0]|                         unless
          grep $_ eq q|eignore|, @{$item->[1]};
        combo_now;
        is_deeply [                 $@ =~ $res->[1], scalar @input ],
        [ !0, scalar( grep q|shift| eq $_, @{$item->[1]} ) ? 3 : 4 ],
          AFSMTS_croakson qq|full, $item->[0]|     }
    @input = @inbase        }

# vim: set filetype=perl
