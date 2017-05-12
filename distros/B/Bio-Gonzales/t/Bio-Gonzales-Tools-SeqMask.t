use warnings;
use Test::More;

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing Bio::Gonzales::Feat::IO::GFF3" if $@;

  eval { require Bio::PrimarySeq; require Bio::Location::Simple; };
  plan( skip_all => 'Bio::Perl not installed; skipping' ) if $@;

  use_ok('Bio::Gonzales::Tools::SeqMask');
}

use Bio::PrimarySeq;
use Bio::Location::Simple;

my $d;
sub TEST { $d = $_[0]; }

#TESTS

#masking tests
{
  my $m_dna_seq = Bio::PrimarySeq->new(
    '-seq'              => 'TTGGTGGCGTCAACT',
    '-display_id'       => 'new-id',
    '-alphabet'         => 'dna',
    '-accession_number' => 'X677667',
    '-desc'             => 'Sample Bio::Seq object'
  );

  Bio::Gonzales::Tools::SeqMask->new( -seq => $m_dna_seq )->mask( 2, 5 );
  is( $m_dna_seq->seq, 'TNNNNGGCGTCAACT', 'mask dna sequence' );

  my $m_rna_seq = Bio::PrimarySeq->new(
    '-seq'              => 'UUGGUGGCGUCAACU',
    '-display_id'       => 'new-id',
    '-alphabet'         => 'rna',
    '-accession_number' => 'X677667',
    '-desc'             => 'Sample Bio::Seq object'
  );

  Bio::Gonzales::Tools::SeqMask->new( -seq => $m_rna_seq )->mask( 2, 5 );
  is( $m_rna_seq->seq, 'UNNNNGGCGUCAACU', 'mask rna sequence' );

  my $m_prot_seq = Bio::PrimarySeq->new(
    '-seq'              => 'MDRATPRVCGRRGVS',
    '-display_id'       => 'new-id',
    '-alphabet'         => 'protein',
    '-accession_number' => 'X677667',
    '-desc'             => 'Sample Bio::Seq object'
  );
  Bio::Gonzales::Tools::SeqMask->new( -seq => $m_prot_seq )->mask( 2, 5 );
  is( $m_prot_seq->seq, 'MXXXXPRVCGRRGVS', 'mask protein sequence' );

  my $location = Bio::Location::Simple->new(
    '-start'  => 7,
    '-end'    => 10,
    '-strand' => -1
  );

  Bio::Gonzales::Tools::SeqMask->new( -seq => $m_dna_seq )->mask($location);
  is( $m_dna_seq->seq, 'TNNNNGNNNNCAACT', 'mask dna sequence' );

  Bio::Gonzales::Tools::SeqMask->new( -seq => $m_dna_seq )->mask( $location, 'X' );
  is( $m_dna_seq->seq, 'TNNNNGXXXXCAACT', 'mask dna sequence' );

  Bio::Gonzales::Tools::SeqMask->new( -seq => $m_dna_seq )->mask( 2, 5, 'X' );
  is( $m_dna_seq->seq, 'TXXXXGXXXXCAACT', 'mask dna sequence' );
}

done_testing();
