# $Id: quadratic.t 484 2013-05-09 20:56:46Z whynot $
# Copyright 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.1 );

use t::TestSuite qw| :run :wraps :diag |;
use Test::More;

use Acme::FSM;

our( %st, $bb, $rc );
my( @inbase, @input, $super );

our %opts =
( diag_level =>                                 (-t STDOUT ? 10 : 1),
  namespace  =>                                                   '',
  source     => sub                                               {
      my $self = shift @_;
      $self->{finish}++                          if $self->state eq q|st593e|;
      $self->{finish}                                           and return '';
                                               return shift @input } );

%st =
( START  =>
  { switch => sub {           1 },
    tturn  => [qw| st6936 NEXT |]                     },
  STOP   => { switch => sub { }                       },
  st6936 =>
  { switch => sub                 {
        my( $self, $octet ) = @_;
        return 
          $octet eq '-' && !defined $self->{accum} ? (    q|minus|, '-' ) :
          $octet eq ' '                            ?             q|space| :
          $octet =~ tr/0-9//                       ? ( q|digit|, $octet ) :
          (        undef, $octet ) },
    eturn  => [qw|    st593e NEXT |],
    uturn  => [qw|    st2cca SAME |],
    turns  =>
    { minus => [qw| st3ac5 SAME |],
      digit => [qw| st7af6 SAME |],
      space => [qw| st6936 NEXT |] }                  },
  st7af6 =>
  { switch => sub                {
        my( $self, $octet ) = @_;
        $self->{accum} .= $octet;
                    return !0, '' },
    tturn  => [qw| st4d71 NEXT |]                     },
  st4d71 =>
  { switch => sub                 {
        my( $self, $octet ) = @_;
        return 
          $octet ne ' ' && defined $self->{coeff2} ? (    undef, $octet ) :
          $octet eq '-' && !defined $self->{accum} ? (    q|minus|, '-' ) :
          $octet =~ tr/0-9//                       ? ( q|digit|, $octet ) :
          $octet ne ' '                            ? (    undef, $octet ) :
          !defined $self->{coeff0}                 ? (         q|0|, '' ) :
          !defined $self->{coeff1}                 ? (         q|1|, '' ) :
          !defined $self->{coeff2}                 ? (         q|2|, '' ) :
                          q|space| },
    eturn  => [qw|    st593e NEXT |],
    uturn  => [qw|    st2cca SAME |],
    turns  =>
    { minus => [qw| st3ac5 SAME |],
      digit => [qw| st7af6 SAME |],
      0     => [qw| st00bb SAME |],
      1     => [qw| st44cf SAME |],
      2     => [qw| st80d2 SAME |],
      space => [qw| st4d71 NEXT |] }                  },
  st2cca =>
  { switch => sub            {
        my( $self, $octet ) = @_;
        $self->{fail} = $octet;
                    return !0 },
    tturn  => [qw| STOP fail |]                       },
  st00bb =>
  { switch => sub              {
        my $self = shift @_;
        $self->{coeff0} = delete $self->{accum};
                      return !0 },
    tturn  => [qw| st4d71 NEXT |]                     },
  st44cf =>
  { switch => sub              {
        my $self = shift @_;
        $self->{coeff1} = delete $self->{accum};
                      return !0 },
    tturn  => [qw| st4d71 NEXT |]                     },
  st80d2 =>
  { switch => sub              {
        my $self = shift @_;
        $self->{coeff2} = delete $self->{accum};
                      return !0 },
    tturn  => [qw| st4d71 NEXT |]                     },
  st593e =>
  { switch => sub                           {
        my $self = shift @_;
        $self->{fail} =
          !defined $self->{coeff0} || $self->{coeff0} eq '-' ? q|no coeff0| :
          !defined $self->{coeff1} || $self->{coeff1} eq '-' ? q|no coeff1| :
          !defined $self->{coeff2} || $self->{coeff2} eq '-' ? q|no coeff2| :
          '';
        return !$self->{fail}, $self->{fail} },
    tturn  => [qw|              stf6ed NEXT |],
    fturn  => [qw|              st2cca SAME |]        },
  stf6ed =>
  { switch => sub                                  {
        my $self = shift @_;
        $self->{radical} =
          $self->{coeff1} ** 2 - 4 * $self->{coeff0} * $self->{coeff2};
        $self->{help}    = 2*$self->{coeff0};
        return
        +($self->{coeff0} == 0 && $self->{coeff1} != 0 ? -2 :
          $self->{coeff0} == 0 && $self->{coeff1} == 0 &&
            $self->{coeff2} == 0                       ? -3 :
          $self->{coeff0} == 0 && $self->{coeff1} == 0 &&
            $self->{coeff2} != 0                       ? -4 :
          $self->{radical} <=> 0), $self->{radical} },
    turns  =>
    { -4 => [qw| STOP   none |],
      -3 => [qw| STOP    any |],
      -2 => [qw| st6c79 SAME |],
      -1 => [qw| st4d07 SAME |],
       0 => [qw| st795c SAME |],
       1 => [qw| st0fdc SAME |]                     } },
  st4d07 =>
  { switch => sub            {
        my $self = shift @_;
        $self->{fail} = q|no root|;
                    return !0 },
    tturn  => [qw| STOP fail |]                       },
  st795c =>
  { switch => sub           {
        my $self = shift @_;
        $self->{root} = [ -$self->{coeff1} / $self->{help} ];
                   return !0 },
    tturn  => [qw| STOP one |]                        },
  st0fdc =>
  { switch => sub           {
        my $self = shift @_;
        $self->{root} =
        [ (-$self->{coeff1} - sqrt $self->{radical}) / $self->{help},
          (-$self->{coeff1} + sqrt $self->{radical}) / $self->{help} ];
                   return !0 },
    tturn  => [qw| STOP two |]                        },
  st6c79 =>
  { switch => sub           {
        my $self = shift @_;
        $self->{root} = [ -$self->{coeff2} / $self->{coeff1} ];
                   return !0 },
    tturn  => [qw| STOP one |]                        },
  st3ac5 =>
  { switch => sub {
        my $self = shift @_;
        $self->{accum} = '-';
        return defined $self->{coeff0} },
    tturn  => [qw|        st4d71 NEXT |],
    fturn  => [qw|        st6936 NEXT |]              } );

@inbase =
([ '',          q|fail|, q|no coeff0|, undef, undef, undef, undef, undef ],
 [ q|t|,           q|fail|,      q|t|, undef, undef, undef, undef, undef ],
 [ q| p|,          q|fail|,      q|p|, undef, undef, undef, undef, undef ],
 [ q|4|,        q|fail|, q|no coeff0|, undef, undef, undef, undef, undef ],
 [ q|9u|,          q|fail|,      q|u|, undef, undef, undef, undef, undef ],
 [ q|5 |,       q|fail|, q|no coeff1|,     5, undef, undef, undef, undef ],
 [ q|52 |,      q|fail|, q|no coeff1|,    52, undef, undef, undef, undef ],
 [ q|-|,        q|fail|, q|no coeff0|, undef, undef, undef, undef, undef ],
 [ q|- |,       q|fail|, q|no coeff0|, undef, undef, undef, undef, undef ],
 [ q|-99 |,     q|fail|, q|no coeff1|,   -99, undef, undef, undef, undef ],
 [ q|2-6 |,        q|fail|,      q|-|, undef, undef, undef, undef, undef ],
 [ q|55- |,        q|fail|,      q|-|, undef, undef, undef, undef, undef ],
 [ q|23 1|,     q|fail|, q|no coeff1|,    23, undef, undef, undef, undef ],
 [ q|11 q|,        q|fail|,      q|q|,    11, undef, undef, undef, undef ],
 [ q|32 0a|,       q|fail|,      q|a|,    32, undef, undef, undef, undef ],
 [ q|58 5 |,    q|fail|, q|no coeff2|,    58,     5, undef, undef, undef ],
 [ q|99 31 |,   q|fail|, q|no coeff2|,    99,    31, undef, undef, undef ],
 [ q|58 -|,     q|fail|, q|no coeff1|,    58, undef, undef, undef, undef ],
 [ q|31 - |,    q|fail|, q|no coeff1|,    31,   '-', undef, undef, undef ],
 [ q|94 -40|,   q|fail|, q|no coeff1|,    94, undef, undef, undef, undef ],
 [ q|98 -51 |,  q|fail|, q|no coeff2|,    98,   -51, undef, undef, undef ],
 [ q|71 4-1 |,     q|fail|,      q|-|,    71, undef, undef, undef, undef ],
 [ q|99 13- |,     q|fail|,      q|-|,    99, undef, undef, undef, undef ],
 [ q|92 70 3|,  q|fail|, q|no coeff2|,    92,    70, undef, undef, undef ],
 [ q|87 7 h |,     q|fail|,      q|h|,    87,     7, undef, undef, undef ],
 [ q|77 68 2m|,    q|fail|,      q|m|,    77,    68, undef, undef, undef ],
 [ q|45 3 -82|, q|fail|, q|no coeff2|,    45,     3, undef, undef, undef ],
 [ q|43 51 1-6 |,  q|fail|,      q|-|,    43,    51, undef, undef, undef ],
 [ q|17 10 0- |,   q|fail|,      q|-|,    17,    10, undef, undef, undef ],
 [ q|0 0 0 |,       q|any|,        '',     0,     0,     0, undef, undef ],
 [ q|0 0 93 |,     q|none|,        '',     0,     0,    93, undef, undef ],
 [ q|0 32 40 |,     q|one|,        '',     0,    32,    40, -1.25, undef ],
 [ q|0 37 0 |,      q|one|,        '',     0,    37,     0,     0, undef ],
 [ q|22 0 0 |,      q|one|,        '',    22,     0,     0,     0, undef ],
 [ q|67 0 63 |,   q|fail|, q|no root|,    67,     0,    63, undef, undef ],
 [ q|37 0 -82 |,    q|two|,        '',    37,  0, -82, -1.48870, 1.48870 ],
 [ q|45 95 1 |,     q|two|,        '',    45,  95, 1, -2.10053, -0.01058 ],
 [ q|95 89 75 1|,  q|fail|,      q|1|,    95,    89,    75, undef, undef ],
 [ q|6 69 17 -|,   q|fail|,      q|-|,     6,    69,    17, undef, undef ],
 [ q|64 92 77 v|,  q|fail|,      q|v|,    64,    92,    77, undef, undef ],
 [ q| -13 21 38 |,  q|two|,        '',   -13, 21,  38, 2.69858, -1.08319 ],
 [ q|  -24  81  84  |, q|two|,     '',   -24,  81, 84, 4.20696, -0.83196 ] );

plan tests => scalar @inbase;

while( my $input = shift @inbase )                          {
    @input = split m{}, $input->[0];
    AFSMTS_wrap;
    is_deeply
    [ $rc->[0], @$bb{qw| fail coeff0 coeff1 coeff2 |},
      (defined $input->[6]                            ?
        abs( $input->[6] - $bb->{root}[0] ) < 0.00001 : undef) ],
    [ @$input[ 1 .. 5 ], (defined $input->[6] ? !0 : undef) ],
      sprintf q|(%s) (%s) (%s:%s) (%s:%s)|,
        $input->[0] // q|(undef)|, $bb->{fail} // q||,
        $bb->{root}[0] // q|(undef)|, $bb->{root}[1] // q|(undef)|,
        $input->[6] // q|(undef)|, $input->[7] // q|(undef)| }

# vim: set filetype=perl
