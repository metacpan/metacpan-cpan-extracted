#
# BioStudio functions
#

=head1 NAME

Bio::BioStudio::Analyze::ProteinCodingGenes

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Analyze::ProteinCodingGenes;

require Exporter;
use Bio::BioStudio::Mask;

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  _analyze
);
our %EXPORT_TAGS = (BS=> \@EXPORT_OK);

my @pcgs = qw(gene mRNA CDS intron five_prime_UTR_intron
    three_prime_UTR_intron);

my @pcgmods = qw(PCR_product tag stop_retained_variant synonymous_codon
    non_synonymous_codon);
    
=head1 Functions

=head2 _analyze()

=cut

sub _analyze
{
  my ($chromosome, $start, $stop) = @_;

  my %REPORT;
  my %FLATS;

  $start = $start || 1;
  $stop  = $stop || length($chromosome->sequence);
  my $range = Bio::Range->new(-start => $start, -end => $stop);

  my @PCGS;
  my @cdnas;
  my @genes = $chromosome->db->get_features_by_type('gene');
  foreach my $gene (grep { $range->contains($_) } @genes)
  {
    my @exons = grep { $_->primary_tag eq 'CDS'} $chromosome->flatten_subfeats($gene);
    if (scalar @exons)
    {
      push @PCGS, $gene;
      push @cdnas, $chromosome->make_cDNA($gene);
    }
  }
          
  #Number of protein coding genes
  {
    my $key = 'number of protein coding genes';
    $FLATS{$key} = scalar(@PCGS);
  }

  #Codon Usage
  {
    my $key = 'codon usage report';
    $FLATS{$key} = $chromosome->GD->generate_codon_report(-sequences => \@cdnas);
  }

  my %genehsh = map {$_->id => $_} @PCGS;
  my %genetags;
  foreach my $gene (@PCGS)
  {
    $genetags{$_}++ foreach ($gene->get_all_tags());
  }
  my %genelengths  = map {$_->id => $_->stop - $_->start + 1} @PCGS;

  my @longgenes = sort {$genelengths{$b->id} <=> $genelengths{$a->id}} @PCGS;

  #Largest PCG
  {
    my $key = 'largest protein coding gene';
    my $largestgene = $longgenes[0];
    my $note = $genelengths{$largestgene->id} . ' bp';
    $REPORT{$key} = [[$largestgene, $note]];
  }

  #Ten largest PCGs
  {
    my $key = 'largest protein coding genes';
    my @largestgenes = @longgenes[0..9];
    $REPORT{$key} = [];
    foreach my $obj (@largestgenes)
    {
      my $note = $genelengths{$obj->id} . ' bp';
      push @{$REPORT{$key}}, [$obj, $note];
    }
  }

  my @shortgenes = reverse @longgenes;
  
  #Smallest PCG
  {
    my $key = 'smallest protein coding gene';
    my $smallestgene = $shortgenes[0];
    my $note = $genelengths{$smallestgene->id} . ' bp';
    $REPORT{$key} = [[$smallestgene, $note]];
  }

  #Ten smallest PCGs
  {
    my $key = 'smallest protein coding genes';
    my @smallestgenes = @shortgenes[0..9];
    $REPORT{$key} = [];
    foreach my $obj (@smallestgenes)
    {
      my $note = $genelengths{$obj->id} . ' bp';
      push @{$REPORT{$key}}, [$obj, $note];
    }
  }

  if (exists $genetags{orf_classification})
  {
    #Smallest verified PCG
    {
      my @vgenes = grep { $_->Tag_orf_classification && $_->Tag_orf_classification ne 'Dubious' } @shortgenes;
      my $key = 'smallest verified protein coding gene';
      my $smallestvgene = $vgenes[0];
      my $note = $genelengths{$smallestvgene->id} . ' bp';
      $REPORT{$key} = [[$smallestvgene, $note]];
    }
    
    #Essential PCGs
    {
      my @essentials = grep {$_->Tag_essential_status && $_->Tag_essential_status eq 'Essential'} @PCGS;
      my $key = 'essential protein coding genes';
      $REPORT{$key} = [];
      push @{$REPORT{$key}}, [$_] foreach (@essentials);
    }
    
    #Fastgrowth PCGs
    {
      my @fasts = grep {$_->Tag_essential_status && $_->Tag_essential_status eq 'fast_growth'} @PCGS;
      my $key = 'protein coding genes required for rapid growth';
      $REPORT{$key} = [];
      push @{$REPORT{$key}}, [$_] foreach (@fasts);
    }
  }

  #Genes with introns
  {
    my $key = 'protein coding genes with introns';
    $REPORT{$key} = [];
    my @keywords = qw(intron five_prime_UTR_intron three_prime_UTR_intron);
    my %itypes = map {$_ => 1} @keywords;
    foreach my $gene (sort {$a->start <=> $b->start} @PCGS)
    {
      my @subfeats = $chromosome->flatten_subfeats($gene);
      my @introns = grep { exists( $itypes{$_->primary_tag} ) } @subfeats;
      if (scalar(@introns))
      {
        my $number = scalar(@introns) > 1 ? 's' : q{};
        my $note = scalar(@introns) . " intron$number";
        push @{$REPORT{$key}}, [$gene, $note];
      }
    }
  }

  my $genemask = $chromosome->type_mask('CDS');
  #Ten largest PCG deserts
  {
    my $key = 'largest protein coding gene deserts';
    $REPORT{$key} = [];
    
    my $deserts = $genemask->find_deserts();
    my @ordered = sort {$b->length <=> $a->length}
                  grep {$range->contains($_)}
                  @{$deserts};
    foreach my $desert (@ordered[0..9])
    {
      push @{$REPORT{$key}}, [$desert, $desert->length . ' bp'];
    }
  }

  #Overlapping PCGs
  {
    my $key = 'protein coding genes overlapping other protein coding genes';
    $REPORT{$key} = [];
    
    my $olaps = $genemask->find_overlaps();
    my @ordered = sort {$b->length <=> $a->length}
                  grep {$range->contains($_)}
                  @{$olaps};
    foreach my $olap (@ordered)
    {
      my $str = $olap->length . q{ bp };
      my @subs = $olap->get_SeqFeatures;
      $str .= join q{, }, map {$_->display_name} @subs;
      push @{$REPORT{$key}}, [$olap, $str];
    }
  }

  return (\%REPORT, \%FLATS);
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

