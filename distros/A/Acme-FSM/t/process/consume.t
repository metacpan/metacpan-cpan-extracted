# $Id: consume.t 564 2025-02-13 21:33:15Z whynot $
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

sub consume_if ( & )            {
    my $test = shift @_;
    return sub                 {
        my( $bb, $item ) = @_;
        push @{$bb->{found}}, $item;
# XXX:202212222213:whynot: One day The Perl will bite you.
        return $test->(), undef }}

my %common =
( START =>
  { switch => sub { $_[0]->{found} = [ ] }, tturn => [qw| S0 VOID |] },
  STOP  => {                                       switch => sub { } } );

my %plug =
( diag_level =>             1,
  state      =>       q|STOP|,
  action     =>       q|DONE|,
  namespace  =>         undef,
  source     => $opts{source},
  dumper     =>         undef );

my %tunits =
( q|{consume-all}| =>
 [{                         %common,
    S0 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S0 NEXT |] }                                    },
[[qw| DONE |], { %plug, queue => [ ], found => [ ] }                  ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}        ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix Persian |]}],
[[qw|                                                      DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian Buoysel |]}    ] ],
  q|{consume-all-with-entry}| =>
 [{                         %common,
    S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 SAME |] },
    S1 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 NEXT |] }                                   },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                   ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}        ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix Persian |]}],
[[qw|                                                      DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian Buoysel |]}    ] ],
  q|{consume-all-with-issue}| =>
 [{                       %common,
    S0 =>
    { switch =>   \&consume_one,
      eturn  => [qw| S1 SAME |],
      tturn  => [qw| S0 NEXT |] },
    S1 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw| STOP DONE |] }                                   },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                   ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}        ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix Persian |]}],
[[qw|                                                       DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian Buoysel |]}   ]  ],
  q|{consume-all-fail-if-empty}| =>
 [{                         %common,
    S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw|   S1 SAME |] },
    S1 =>
    { switch =>   \&consume_one,
      eturn  => [qw| S2 SAME |],
      tturn  => [qw| S1 NEXT |]   },
    S2 =>
    { switch =>     \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw| STOP DONE |] }                                    },
[[qw| FAIL |], { %plug, action => q|FAIL|, queue => [ ], found => [ ] }],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}         ],
[[qw|                                               DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian |]}            ],
[[qw|                                   DONE |],
    {                                   %plug,
      queue => [                            ],
      found => [qw| Vulpix Persian Buoysel |] }                        ] ],
  q|{consume-all-fail-unless-empty}| =>
 [{                         %common,
   S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 SAME |] },
    S1 =>
    { switch =>     \&AFSMTS_TK,
      eturn  => [qw| S2 SAME |],
      tturn  => [qw| S1 NEXT |]   },
    S2 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw| STOP FAIL |] }                                    },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                    ],
[[qw|                                                          FAIL |],
    { %plug, action => q|FAIL|, queue => [qw| Vulpix |], found => [ ]} ],
[[qw|                           FAIL |],
    {                           %plug,
      action=>                q|FAIL|,
      queue => [qw| Vulpix Persian |],
      found => [                    ] }                                ],
[[qw|                                    FAIL |],
    {                                   %plug,
      action=>                        q|FAIL|,
      queue => [qw| Vulpix Persian Buoysel |],
      found => [                            ] }                        ] ],
  q|{consume-all-fail-if-one-with-states}| =>
 [{                         %common,
    S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 SAME |] },
    S1 =>
    { switch =>   \&consume_one,
      tturn  => [qw| S2 NEXT |]   },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw|   S3 NEXT |] },
    S3 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S3 NEXT |] }                                    },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                    ],
[[qw|                                                          FAIL |],
    { %plug, action => q|FAIL|, queue => [ ], found => [qw| Vulpix |]} ],
[[qw|                                               DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian |]}            ],
[[qw|                                   DONE |],
    {                                   %plug,
      queue => [                            ],
      found => [qw| Vulpix Persian Buoysel |] }                        ] ],
  q|{consume-all-fail-if-two-with-states}| =>
 [{                         %common,
    S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 SAME |] },
    S1 =>
    { switch =>   \&consume_one,
      tturn  => [qw| S2 NEXT |]   },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S3 NEXT |] },
    S3 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw|   S4 NEXT |] },
    S4 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S4 NEXT |] }                                 },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                 ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}      ],
[[qw|                           FAIL |],
    {                           %plug,
      action=>                q|FAIL|,
      queue => [                    ],
      found => [qw| Vulpix Persian |] }                             ],
[[qw|                                                       DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian Buoysel |]} ]    ],
  q|{consume-all-fail-if-one-with-branches}| =>
 [{                                           %common,
    S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 SAME |]                   },
    S1 =>
    { switch => consume_if { 1 == @{$bb->{found}} },
      eturn  => [qw|                     S3 SAME |],
      tturn  => [qw|                     S1 TSTL |],
      fturn  => [qw|                     S2 NEXT |] },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S2 NEXT |]                   },
    S3 =>
    { switch => sub {           },
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw| STOP FAIL |]                   }                  },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                    ],
[[qw|                                                          FAIL |],
    { %plug, action => q|FAIL|, queue => [ ], found => [qw| Vulpix |]} ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix Persian |]} ],
[[qw|                                                       DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian Buoysel |]}    ] ],
  q|{consume-all-fail-unless-one-with-branches}| =>
 [{                                           %common,
    S0 =>
    { switch =>       \&AFSMTS_tK,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S1 SAME |]                   },
    S1 =>
    { switch => consume_if { 1 == @{$bb->{found}} },
      eturn  => [qw|                     S3 SAME |],
      tturn  => [qw|                     S1 TSTL |],
      fturn  => [qw|                     S2 NEXT |] },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw|   S2 NEXT |]                   },
    S3 =>
    { switch => sub {           },
      eturn  => [qw| STOP DONE |],
      tturn  => [qw| STOP FAIL |]                   }         },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}           ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}],
[[qw|                            FAIL |],
    {                            %plug,
      action =>                q|FAIL|,
      queue  => [                    ],
      found  => [qw| Vulpix Persian |] }                      ],
[[qw|                                    FAIL |],
    {                                    %plug,
      action =>                        q|FAIL|,
      queue  => [                            ],
      found  => [qw| Vulpix Persian Buoysel |] }              ]          ],
  q|{consume-all-fail-if-two-with-branches}| =>
 [{                                          %common,
    S0 =>
    { switch => consume_if { 2 > @{$bb->{found}} },
      eturn  => [qw|                  STOP DONE |],
      tturn  => [qw|                    S0 NEXT |],
      fturn  => [qw|                    S1 TSTL |] },
    S1 =>
    { switch => consume_if { 2 > @{$bb->{found}} },
      eturn  => [qw|                    S3 SAME |],
      tturn  => [qw|                    S1 TSTL |],
      fturn  => [qw|                    S2 TSTL |] },
    S2 =>
    { switch =>     \&consume_one,
      eturn  => [qw| STOP DONE |],
      tturn  => [qw|   S2 NEXT |]                  },
    S3 =>
    { switch => sub {           },
      eturn  => [qw| STOP FAIL |],
      tturn  => [qw| STOP FAIL |]                  }                },
[[qw| DONE |], { %plug, queue => [ ], found => [ ]}                 ],
[[qw| DONE |], { %plug, queue => [ ], found => [qw| Vulpix |]}      ],
[[qw|                           FAIL |],
    {                            %plug,
      action =>                q|FAIL|,
      queue  => [                    ],
      found  => [qw| Vulpix Persian |] }                            ],
[[qw|                                                       DONE |],
    { %plug, queue => [ ], found => [qw| Vulpix Persian Buoysel |]} ]    ] );

plan tests => 40;

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
