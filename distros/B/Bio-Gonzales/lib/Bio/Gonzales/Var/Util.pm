package Bio::Gonzales::Var::Util;

use warnings;
use strict;
use Carp;

use 5.010;

use Exporter 'import';

our $VERSION = 0.01_01;

our %EXPORT_TAGS = ( 'all' => [qw/geno2haplo renumber_genotypes merge_alleles only_geno/ ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub geno2haplo {
  my $genotypes = shift;
  # check if also coverage, etc. is part of the genotype then
  # split the genotypes into haplotypes
  my @haplotypes;
  my $phased = 1;
  for my $g_raw (@$genotypes) {
    my $g = index( $g_raw, ':' ) >= 0 ? substr( $g_raw, 0, index( $g_raw, ':' ) ) : $g_raw;
    # we need to find only one genotype of x/y to set phased to false
    $phased &&= not index( $g, '|' ) < 0;
    push @haplotypes, split /[|\/]/, $g;
  }
  return ( \@haplotypes, $phased );
}

sub only_geno {
  my $genotypes = shift;
  my @res = map { index( $_, ':' ) >= 0 ? substr( $_, 0, index( $_, ':' ) ) : $_ } @$genotypes;
}

sub renumber_genotypes {
  my ( $map , $genotypes, ) = @_;
  my @renumbered;
  for my $g_raw (@$genotypes) {
    my $idx = index( $g_raw, ':' );
    my $g = $idx >= 0 ? substr( $g_raw, 0, $idx ) : $g_raw;
    my @g_split = split /([|\/])/, $g;
    for ( my $i = 0; $i < @g_split; $i += 2 ) {
      $g_split[$i] = $map->[ $g_split[$i] ] if($g_split[$i] ne '.');
    }
    if($idx < 0) {
      $g_raw = join '', @g_split;
    } else {
      substr( $g_raw, 0, $idx, join( '', @g_split));
    }
  }
  return $genotypes;
}

sub merge_alleles {
  my ( $ref_alleles, $alleles ) = @_;

  my $i = 0;
  my %ra = map { $_ => $i++ } @$ref_alleles;

  my @map;
  my @merged_alleles = @$ref_alleles;
  my $allele_idx     = @$ref_alleles;
  for ( my $idx = 0; $idx < @$alleles; $idx++ ) {
    if ( defined $ra{ $alleles->[$idx] } ) {
      $map[$idx] = $ra{ $alleles->[$idx] };
    } else {
      $map[$idx] = $allele_idx++;
      push @merged_alleles, $alleles->[$idx];
    }
  }
  return ( \@merged_alleles, \@map );
}

1;
