# $Id: filter.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.3 );

use t::TestSuite qw| :switches :run :utils |;
use Test::More;

use Acme::FSM;

our( %st, $bb, $rc );
my @inbase = (                  undef,
                     q|Vulpix|, undef,
  qw|         Vulpix Persian |, undef,
  qw| Vulpix Persian Buoysel |, undef );
my @input = @inbase;
our %opts = ( source => sub {
    @input = @inbase                                            unless @input;
    return shift @input      } );

sub consume_one     {
    my( $bb, $item ) = @_;
    push @{$bb->{found}}, $item;
    return !0, undef }

my %common =
( START =>
  { switch => sub { $_[0]->{found} = [ ] }, tturn => [qw| S0 VOID |] },
  STOP  => {                                       switch => sub { } } );

my %plug =
( state      =>       q|STOP|,
  action     =>       q|DONE|,
  diag_level =>             1,
  namespace  =>         undef,
  source     => $opts{source},
  dumper     =>         undef );

my %tunits =
# TODO:201302161629:whynot: Move that stuff to YAML and {DATA}
( q|{filter-first-with-states}| =>
 [{                                             %common,
    S0 =>
    { switch => sub { push @{$_[0]->{queue}}, $_[1] },
      eturn  => [qw|                     STOP DONE |],
      tturn  => [qw|                       S1 NEXT |] },
    S1 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 NEXT |]                     }                 },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                     ],
[[qw| DONE |], { %plug, queue => [qw| Vulpix |], found => [ ]}          ],
[[qw| DONE |],
    { %plug, queue => [qw| Vulpix |], found => [qw| Persian |]}         ],
[[qw|                                                           DONE |],
    { %plug, queue => [qw| Vulpix |], found => [qw| Persian Buoysel |]} ] ],
  q|{filter-second-with-states}| =>
 [{                                             %common,
    S0 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 NEXT |]                     },
    S1 =>
    { switch => sub { push @{$_[0]->{queue}}, $_[1] },
      eturn  => [qw|                     STOP DONE |],
      tturn  => [qw|                       S2 NEXT |] },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S2 NEXT |]                     }         },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}             ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}  ],
[[qw|                                                  DONE |],
    { %plug, queue => [qw| Persian |], found => [qw| Vulpix |]} ],
[[qw|                            DONE |],
    { %plug,
      queue  => [qw|        Persian |],
      found  => [qw| Vulpix Buoysel |] }                        ]         ],
  q|{filter-third-with-states}| =>
 [{                                             %common,
    S0 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 NEXT |]                     },
    S1 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S2 NEXT |]                     },
    S2 =>
    { switch => sub { push @{$_[0]->{queue}}, $_[1] },
      eturn  => [qw|                     STOP DONE |],
      tturn  => [qw|                       S2 NEXT |] }                },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                    ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}         ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix Persian |]} ],
[[qw|                           DONE |],
    { %plug,
      queue => [qw|        Buoysel |],
      found => [qw| Vulpix Persian |] }                                ] ],
  q|{filter-first-with-branches}| =>
 [{                                                        %common,
    S0 =>
    { switch => sub {
          !@{$_[0]->{queue}} and push @{$_[0]->{queue}}, $_[1] },
      eturn  => [qw|                                STOP DONE |],
      tturn  => [qw|                                  S1 NEXT |] },
    S1 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 NEXT |]                                } },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                ],
[[qw| DONE |], { %plug, queue => [qw| Vulpix |], found => [ ]}     ],
[[qw|                                                  DONE |],
    { %plug, queue => [qw| Vulpix |], found => [qw| Persian |]}    ],
[[qw|                            DONE |],
    { %plug,
      queue => [qw|          Vulpix |],
      found => [qw| Persian Buoysel |] }                           ]      ],
  q|{filter-second-with-branches}| =>                              
 [{                                             %common,
    S0 =>
    { switch => sub             {
          push @{$_[0]->{found}}, $_[1];
          @{$_[0]->{found}} <= 0 },
      eturn  => [qw|  STOP DONE |],
      tturn  => [qw|    S0 NEXT |],
      fturn  => [qw|    S1 NEXT |]                    },
    S1 =>
    { switch => sub { push @{$_[0]->{queue}}, $_[1] },
      eturn  => [qw|                     STOP DONE |],
      tturn  => [qw|                       S2 NEXT |] },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S2 NEXT |]                     }         },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}             ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}  ],
[[qw|                                                  DONE |],
    { %plug, queue => [qw| Persian |], found => [qw| Vulpix |]} ],
[[qw|                            DONE |],
    { %plug,
      queue => [qw|        Persian |],
      found => [qw| Vulpix Buoysel |] }                         ]         ],
  q|{filter-third-with-branches}| =>
 [{                                             %common,
    S0 =>
    { switch => sub             {
          push @{$_[0]->{found}}, $_[1];
          @{$_[0]->{found}} <= 1 },
      eturn  => [qw|  STOP DONE |],
      tturn  => [qw|    S0 NEXT |],
      fturn  => [qw|    S1 NEXT |]                    },
    S1 =>
    { switch => sub { push @{$_[0]->{queue}}, $_[1] },
      eturn  => [qw|                     STOP DONE |],
      tturn  => [qw|                       S2 NEXT |] },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S2 NEXT |]                     }                 },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                     ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}          ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix Persian |]}  ],
[[qw|                                                           DONE |],
    { %plug, queue => [qw| Buoysel |], found => [qw| Vulpix Persian |]} ] ] );

plan tests => 24;

while( my( $tag, $tunit ) = each %tunits ) {
    @ARGV && not AFSMTS_grep qq|$tag|, @ARGV                         and next;
    %st = %{shift @$tunit};
    AFSMTS_wrap;
    AFSMTS_deeply @{shift @$tunit}, qq|$tag consumes empty|;
    AFSMTS_wrap;
    AFSMTS_deeply @{shift @$tunit}, qq|$tag consumes one|;
    AFSMTS_wrap;
    AFSMTS_deeply @{shift @$tunit}, qq|$tag consumes two|;
    AFSMTS_wrap;
    AFSMTS_deeply @{shift @$tunit}, qq|$tag consumes three|;
    fail sprintf q|%s -- oops, (%i) inputs left behind|,
      $tag, scalar @input                                           if @input;
    fail sprintf q|%s -- oops, (%i) tests left behind|,
      $tag, scalar @$tunit       if @$tunit }

# vim: set filetype=perl
