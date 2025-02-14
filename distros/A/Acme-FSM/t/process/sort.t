# $Id: sort.t 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL
# xasi BmhM NCac 5Ddl 1BfZ 2c8C DnV6 uFln ulW1 twae assr JOYl 5Boi uEX5 lqqr jIOe WNto Hwlb JWMF eZnj uQU3 UQzN XJ2T JXdQ mgz3 E25x ZeOo oz0U S76l N7D6 5MIS |

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.3 );

use t::TestSuite qw| :switches :run :utils |;
use Test::More;

plan tests => 9;

use Acme::FSM;

our( %st, $bb );
my( @inbase, @input, $super );

our %opts =
( diag_level =>                                  (-t STDOUT ? 10 : 1),
  namespace  =>                                                    '',
  dumper     => sub                                                {
      my $self = shift @_;
      @input                                         or return q|[-1:-1] (:)|;
      @input == 1 and            return sprintf q|[0:0] (%s:%s)|, @input[0,0];
      exists $self->{mark} or                    return sprintf q|[%2i] (%s)|,
        $self->{base}, $input[$self->{base}];
      return sprintf q|[%2i:%2i] (%s:%s)|,
        @$self{qw| base mark |},
        @input[
          $self->{mark}, $self->{mark} > 0 ? $self->{mark} - 1 : 0] },
  source     => sub {                                      shift @_ } );

%st =
( START             =>
  { switch => sub             {
        my $self = shift @_;
        @input = @{shift @inbase};
        $self->{base} = 0;
                             1 },
    tturn  => [qw| Aurae NEXT |]               },
  STOP              => { switch => sub {     } },
  Aurae             =>
  { switch => sub            {
        my $self = shift @_;
        $self->{base} = 0;
        print STDERR qq|@input\n|;
                     1, $self },
    tturn  => [qw| Aina SAME |]                },
  Aina              =>
  { switch => sub                     {
        my $self = shift @_;
        $self->{base} < $#input, $self },
    tturn  => [qw|          Zaia SAME |],
    fturn  => [qw|          STOP DONE |]       },
  Zaia              =>
  { switch => sub                      {
        my $self = shift @_;
        $self->{mark} = $#input;
                               1, $self },
    tturn => [qw| Riah_Sahiltaahk SAME |]      },
  Riah_Sahiltaahk   =>
  { switch => sub {
        my $self = shift @_;
        $self->{mark} > $self->{base}, $self },
    tturn => [qw|         Do_The_Music SAME |],
    fturn => [qw|            De_Futura SAME |] },
  Do_The_Music      =>
  { switch => sub                        {
        my $self = shift @_;
        ( $input[$self->{mark} - 1] cmp $input[$self->{mark}] ) > 0,
          $self                           },
    tturn => [qw|         Ork_Alarm SAME |],
    fturn => [qw| Maneh_Fur_Da_Zess SAME |]    },
  Ork_Alarm         =>
  { switch => sub                        {
        my $self = shift @_;
        @input[$self->{mark} - 1, $self->{mark}] = @input[$self->{mark},
        $self->{mark} - 1];
                                 1, $self },
    tturn => [qw| Maneh_Fur_Da_Zess SAME |]    },
  Maneh_Fur_Da_Zess =>
  { switch => sub                      {
        my $self = shift @_;
        $self->{mark}--;
        print STDERR qq|@input\n|;
                               1, $self },
    tturn => [qw| Riah_Sahiltaahk SAME |]      },
  De_Futura         =>
  { switch => sub           {
        my $self = shift @_;
        $self->{base}++;
                    1, $self },
    tturn => [qw| Aina SAME |]                 } );

$super = [ ];
@inbase = ( [ @$super ] );
AFSMTS_wrap;
is_deeply \@input, $super, q|empty|;

$super = [qw| Meissa |];
@inbase = ([ @$super ]);
AFSMTS_wrap;
is_deeply \@input, $super, q|one item|;

$super = [qw| Keid Meissa |];
@inbase = ([ @$super ], [ reverse @$super ]);
while( @inbase )                          {
    AFSMTS_wrap;
    is_deeply \@input, $super, q|two items| }

$super = [qw| Atik Keid Meissa |];
@inbase =
( map {; $_, do { my $rc = [ @$_ ]; push @$rc, shift @$rc; $rc }}
  [ @$super ], [ reverse @$super ]);
while( @inbase )                             {
    AFSMTS_wrap;
    is_deeply \@input, $super, q|three items| }

$super =
[qw| Algorab     Ancha     Atik      Azha
     Denebola Keid Meissa Rigil_Kentaurus
     Scheat                          Skat |];
@inbase = ([ @$super ], [ reverse @$super ]);
for ( 2 .. @$super )                          {
    my $base = [ @{$inbase[0]} ];
    push @$base, shift @$base;
    unshift @inbase, $base, [ reverse @$base ] }
while( @inbase )                       {
    AFSMTS_wrap;
# XXX:202501120433:whynot: This is cranky.
    my $backup = defined $inbase[0] ? [ $inbase[0] ] : [[ qw|***qG1k***| ]];
    fail qq|@{$backup->[0]}|                                            unless
      AFSMTS_smartmatch @input, @$super }
pass q|success, you know|;

# vim: set filetype=perl
