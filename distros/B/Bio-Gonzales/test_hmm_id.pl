#!/usr/bin/env perl
# created on 2013-08-19

use warnings;
use strict;
use 5.010;

use Bio::Gonzales::Search::IO::HMMER3;
use Bio::Gonzales::Util::File;
use Bio::Gonzales::Util::Cerial;
use Data::Printer;

my $out
  = epath(
  "~/projects/snf2/analysis/snf2_candidates_merged_all/2013-08-16_conserved_motifs/snf2_n-helic_c/HMMSearch_Athaliana.result"
  );
my $q = Bio::Gonzales::Search::IO::HMMER3->new( file => $out )->parse;

# invert $q ( protein => motif => results ), not ( motif => protein => results )

my %q_inv;
while ( my ( $mid, $pset ) = each %$q ) {
  while ( my ( $pid, $doms ) = each %$pset ) {
    # only take the best hit
    $q_inv{$pid} //= {};
    my $max = -100;
    for my $d (@$doms) {
      if ( $d->{score} > $max ) {
        $q_inv{$pid}{$mid} = $d;
        $max = $d->{score};
      }
    }
  }
}
jspew( "test.json",     $q );
jspew( "test_inv.json", \%q_inv );

#for each motif, check if there and match fullfills requirements
#remember start position and the next motif's start position needs to be greater than end pos of last motif
# rember max und min start/end pos for cutout

my @motifs = (
  ##[ name, requirements
  [ 'motif_00', sub { my $r = shift; return 1 } ],
  [ 'motif_01', sub { my $r = shift; return 1 } ],
  [ 'motif_02', sub { my $r = shift; return 1 } ],
  [ 'motif_03', sub { my $r = shift; return 1 } ],
  [ 'motif_04', sub { my $r = shift; return 1 } ],
  [ 'motif_05', sub { my $r = shift; return 1 } ],
  [ 'motif_06', sub { my $r = shift; return 1 } ],
  [ 'motif_07', sub { my $r = shift; return 1 } ],
  [ 'motif_08', sub { my $r = shift; return 1 } ],
  [ 'motif_09', sub { my $r = shift; return 1 } ],
  [ 'motif_10', sub { my $r = shift; return 1 } ],
  [ 'motif_11', sub { my $r = shift; return 1 } ],
);

my %res;
my @failed;
PROTEIN:
while ( my ( $pid, $mset ) = each %q_inv ) {
  my $last_pos = -1;
  my $max      = -1;
  my $min      = 10000000;
  for my $ref_m (@motifs) {
    my $m = $mset->{ $ref_m->[0] };
    if ($m) {
      if ( $m->{env_from} >= $last_pos ) {
        # we still have the right order
        $last_pos = $m->{env_from};
        unless ( $ref_m->[1]->($m) ) {
          push @failed, "$pid is out: $ref_m->[0] SCORE: $m->{score}";
          next PROTEIN;
        }
        $max = $m->{env_from} if ( $m->{env_from} > $max );
        $min = $m->{env_from} if ( $m->{env_from} < $min );

        $max = $m->{env_to} if ( $m->{env_to} > $max );
        $min = $m->{env_to} if ( $m->{env_to} < $min );
      } else {
        # this motif is at the wrong pos, this protein is not a candidate
        push @failed, "$pid is out: $ref_m->[0] $last_pos / " . $m->{env_from};
        next PROTEIN;
      }

    } else {
      # motif not found
      push @failed, "$pid is out: $ref_m->[0] not found";
      next PROTEIN;
    }

  }
  $res{$pid} = [ $min, $max ];
  say STDERR "$pid : $min - $max";
}
jspew("res.json", \%res);
jspew("fail.json", \@failed);
say STDERR join( "\n", keys %res );
