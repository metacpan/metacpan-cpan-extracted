# $Id: parse.t 482 2013-03-08 22:47:45Z whynot $
# Copyright 2013 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.1 );

use t::TestSuite qw| :switches :run :wraps |;
use Test::More;

use Acme::FSM;

our( %st, $bb, $rc );
my( @inbase, @input, $super );

our %opts =
( diag_level =>                                 (-t STDOUT ? 10 : 1),
  namespace  =>                                                   '',
  source     => sub                                               {
      my $self = shift @_;
      $self->{fail}                                          and return undef;
      return $self->{octet} ? delete $self->{octet} : shift @input } );

%st =
( START           =>
  { switch => sub {                    1 },
    tturn  => [qw| queen_of_hearts NEXT |]                },
  STOP            => { switch => sub {   }                },
  queen_of_hearts =>
  { switch => sub                       {
        my( $self, $octet ) = @_;
        $octet eq ' ' && !defined $self->{left}                 and return !0;
                       return !1, $octet },
    eturn  => [qw| STOP          finish |],
    tturn  => [qw| queen_of_hearts NEXT |],
    fturn  => [qw| duchess         SAME |]                },
  duchess         =>
  { switch => sub                      {
        my( $self, $octet ) = @_;
        if( !defined $self->{left} && $octet !~ tr/0-9// ) {
                                 $self->{fail} = q|no left| }
        elsif( $octet =~ tr/0-9//                        ) {
                                    $self->{left} .= $octet }
        else                                               {
                                          return !1, $octet }
                              return !0 },
    eturn => [qw| STOP          finish |],
    tturn => [qw| queen_of_hearts NEXT |],
    fturn => [qw| white_rabbit    SAME |]                 },
  white_rabbit    =>
  { switch => sub                    {
        my( $self, $octet ) = @_;
        $octet eq ' ' && !defined $self->{op}                   and return !0;
                    return !1, $octet },
    eturn  => [qw| STOP       finish |],
    tturn  => [qw| white_rabbit NEXT |],
    fturn  => [qw| white_queen  SAME |]                   },
  white_queen     =>
  { switch => sub                    {
        my( $self, $octet ) = @_;
        if( $octet =~ tr/-+//    ) {     $self->{op} = $octet }
        elsif( $octet !~ tr/-+// ) { $self->{fail} = q|no op| }
        else                       {        return !1, $octet }
                            return !0 },
    eturn  => [qw| STOP       finish |],
    tturn  => [qw| fish_footman NEXT |],
    fturn  => [qw| fish_footman SAME |]                   },
  fish_footman    =>
  { switch => sub                    {
        my( $self, $octet ) = @_;
        $octet eq ' ' && !defined $self->{right}                and return !0;
                    return !1, $octet },
    eturn  => [qw| STOP       finish |],
    tturn  => [qw| fish_footman NEXT |],
    fturn  => [qw| hatta        SAME |]                   },
  hatta           =>
  { switch => sub              {
        my( $self, $octet ) = @_;
        if( !defined $self->{right} && $octet !~ tr/0-9// ) {
                                 $self->{fail} = q|no right| }
        elsif( $octet =~ tr/0-9//                         ) {
                                    $self->{right} .= $octet }
        else                                                {
                                           return !1, $octet }
                      return !0 },
    eturn  => [qw| STOP finish |],
    tturn  => [qw| hatta  NEXT |],
    fturn  => [qw| mouse  SAME |]                         },
  mouse           =>
  { switch => sub                   {
        my( $self, $octet ) = @_;
        if( $octet =~ tr/-+ // ) { $self->{octet} = $octet }
        else                     {       return !1, $octet }
                           return !0 },
    eturn  => [qw| STOP      finish |],
    tturn  => [qw| BREAK        fix |],
    fturn  => [qw| white_queen SAME |]                    },
  BREAK           =>
  { switch => sub { my $self = shift @_; $self->{octet} } },
  CONTINUE        =>
  { switch => sub {                 1 },
    eturn  => [qw| STOP       finish |],
    tturn  => [qw| white_rabbit SAME |]                   } );

@inbase =
([ q||,                    undef, undef ],
 [ q|0|,                   undef,     0 ],
 [ q|3|,                   undef,     3 ],
 [ q| 8|,                  undef,     8 ],
 [ q|4 |,                  undef,     4 ],
 [ q| 7 |,                 undef,     7 ],
 [ q|x6|,             q|no left|, undef ],
 [ q|3s|,               q|no op|,     3 ],
 [ q|h6n|,            q|no left|, undef ],
 [ q|71|,                  undef,    71 ],
 [ q| 99|,                 undef,    99 ],
 [ q|06 |,                 undef,     6 ],
 [ q|40+|,           q|no right|,    40 ],
 [ q|38-|,           q|no right|,    38 ],
 [ q|+16|,            q|no left|, undef ],
 [ q|-84|,            q|no left|, undef ],
 [ q|93+81|,               undef,   174 ],
 [ q| 76+75|,              undef,   151 ],
 [ q|56 +15|,              undef,    71 ],
 [ q|21+ 64|,              undef,    85 ],
 [ q|38+35 |,              undef,    73 ],
 [ q| 36 + 22 |,           undef,    58 ],
 [ q|1+0|,                 undef,     1 ],
 [ q|0+26|,                undef,    26 ],
 [ q|36+y|,          q|no right|,    36 ],
 [ q|17++|,          q|no right|,    17 ],
 [ q|75+13+22|,            undef,   110 ],
 [ q|42+16 + 35|,          undef,    93 ],
 [ q|5+52+w|,        q|no right|,    57 ],
 [ q|22+8i|,            q|no op|,    22 ],
 [ q|10+75+-|,       q|no right|,    85 ],
 [ q| 36 + 62 + 88 + 39 |, undef,   225 ] );

plan tests => scalar @inbase;

sub do_stuff ( )    {
    $bb->action eq q|fail|                                         and return;
    $bb->{fail} = q|no right|           if $bb->{op} && !defined $bb->{right};
    $bb->{fail}                                                    and return;
    $bb->{left} = eval qq|$bb->{left} $bb->{op} $bb->{right}|               if
      $bb->{op} && defined $bb->{right};
    $bb->{left} = eval qq|$bb->{left}|                 if defined $bb->{left};
    delete $bb->{right};
    delete $bb->{op} }

while( my $input = shift @inbase )                                {
    @input = split m{}, $input->[0];
    AFSMTS_wrap;
    do_stuff;
    until( $bb->state eq q|STOP| ) { AFSMTS_method_wrap q|process|; do_stuff }
    is_deeply
    [ $bb->action, @$bb{qw| fail left |} ], [ q|finish|, @$input[1 .. 2] ],
      sprintf q|(%s) (%s) (%s)|,
        $input->[0], $bb->{left} // q|(undef)|, $bb->{fail} // q|| }

# vim: set filetype=perl
