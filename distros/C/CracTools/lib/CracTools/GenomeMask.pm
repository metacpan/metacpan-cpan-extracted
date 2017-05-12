package CracTools::GenomeMask;
{
  $CracTools::GenomeMask::DIST = 'CracTools';
}
# ABSTRACT: A bit vector mask over the whole genome
$CracTools::GenomeMask::VERSION = '1.25';
use strict;
use warnings;

use CracTools::BitVector;
use CracTools::Utils;
use Carp;

#You can also define is the genome should be consider as uniquely stranded or as double stranded
#with the C<is_stranded> argument.


sub new {
  my $class = shift;

  my %args = @_;

  # the genome mask is not stranded by default
  #my $is_stranded = defined $args{is_stranded}? $args{is_stranded} : 0;
  my $verbose = defined $args{verbose}? $args{verbose} : 0;

  my %bit_vectors;

  if(defined $args{genome}) {

    foreach my $chr (keys %{$args{genome}}) {
      if(!defined $bit_vectors{$chr}) {
        $bit_vectors{$chr} = CracTools::BitVector->new($args{genome}->{$chr});
      } else {
        croak "Multiple definition of sequence $chr inf the genome lengths";
      }
    }
  } elsif(defined $args{crac_index_conf}) {
    print STDERR "Creating GenomeMask from crac index conf file : $args{crac_index_conf}\n" if $verbose;
    my $conf_fh = CracTools::Utils::getReadingFileHandle($args{crac_index_conf});
    my $nb_chr = <$conf_fh>;
    my $nb_chr_found = 0;
    while(<$conf_fh>) {
      my $chr = $_;
      chomp $chr;
      my $chr_length = <$conf_fh>;
      chomp $chr_length;
      if(defined $chr_length) {
        print STDERR "\tCreating bitvecor for chr $chr of length $chr_length\n" if $verbose;
        $bit_vectors{$chr} = CracTools::BitVector->new($chr_length);
        $nb_chr_found++;
      } else {
        croak "Missing genome length for chromosome $chr";
      }
    }
    croak "There is less chromosome found ($nb_chr_found) in $args{crac_index_conf} than expected ($nb_chr)" if $nb_chr_found < $nb_chr;
  } elsif(defined $args{sam_reader}) {
    my $refseq_lengths = $args{sam_reader}->allRefSeqLengths();
    foreach my $chr (keys %{$refseq_lengths}) {
      $bit_vectors{$chr} = CracTools::BitVector->new($refseq_lengths->{$chr});
    }
  } else {
    croak "There is no valid argument to extract the chromosomes names and length";
  }

  my $self = bless {
    bit_vectors => \%bit_vectors,
    #is_stranded => $is_stranded,
  }, $class;

  return $self;
}

#=head2 isStranded
#
#  Description : Return true is genomeMask is double stranded
#
#=cut
#
#sub isStranded {
#  my $self = shift;
#  return $self->{is_stranded};
#}

#Arg [2] : Integer (1,-1) - strand

sub getBitvector {
  my $self = shift;
  my $chr = shift;
  #my $strand = shift;
  if(defined $self->{bit_vectors}->{$chr}) {
    return $self->{bit_vectors}->{$chr};
  } else {
    carp "There is no bitvector for sequence $chr in the genome mask";
    return undef;
  }
}


sub getChrLength {
  my $self = shift;
  my $chr = shift;
  my $bv = $self->getBitvector($chr);
  return defined $bv? $bv->length : undef;
}


sub setPos {
  my ($self,$chr,$pos) = @_;
  my $bv = $self->getBitvector($chr);
  $bv->set($pos) if defined $bv;
}


sub setRegion {
  my ($self,$chr,$start,$end) = @_;
  for(my $i = $start; $i <= $end; $i++) {
    $self->setPos($chr,$i);  
  }
}

 
sub getPos {
  my ($self,$chr,$pos) = @_;
  my $bv = $self->getBitvector($chr);
  return $bv->get($pos) if defined $bv;
}


sub getPosSetInRegion {
  my ($self,$chr,$start,$end) = @_;
  my $bv = $self->getBitvector($chr);
  my @pos;
  if(defined $bv) {
    for(my $i = $start; $i <= $end; $i++) {
      push(@pos,$i) if $bv->get($i) == 1;  
    }
  }
  return \@pos;
}


sub getNbBitsSetInRegion {
  my $self = shift;
  return scalar @{$self->getPosSetInRegion(@_)};
}


sub rank {
  my ($self,$chr,$pos) = @_;
  my $cumulated_bits = 0;
  my $i = 0;
  my @chr_sorted = sort keys %{$self->{bit_vectors}};
  while($chr_sorted[$i] ne $chr) {
    $cumulated_bits += $self->getBitvector($chr_sorted[$i])->nb_set;
    $i++;
  }
  return $cumulated_bits + $self->getBitvector($chr_sorted[$i])->rank($pos);
}


sub select {
  my $self = shift;
  my $i = shift;
  my $cumulated_bits = 0;
  my @chr_sorted = sort keys %{$self->{bit_vectors}};
  my $j = 0;
  while($j < @chr_sorted && $cumulated_bits + $self->getBitvector($chr_sorted[$j])->nb_set < $i) {
    my $chr = $chr_sorted[$j];
    my $bv = $self->getBitvector($chr);
    $cumulated_bits += $self->getBitvector($chr)->nb_set;
    $j++;
  }
  my $chr = $chr_sorted[$j-1];
  my $pos = $self->getBitvector($chr_sorted[$j-1])->select($i - $cumulated_bits + 1);
  return ($chr,$pos);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::GenomeMask - A bit vector mask over the whole genome

=head1 VERSION

version 1.25

=head1 SYNOPSIS

  my $genome_mask = CracTools::GenomeMask->new( genome => { "chr1" => 100000, "chr2" => 20000 } );

  $genome_mask->setRegion("chr1",200,250);

  $genome_mask->getNbBitsSetInRegion("chr1",190,220);

=head1 DESCRIPTION

This module defines a BitVector mask over a whole genome and provide method
to query this mask. It can read genome sequence and length from various sources
(SAM headers, CRAC index, User input).

=head1 SEE ALSO

You can look at L<CracTools::BitVector> that is the underlying datastructure of
L<CracTools::GenomeMask>.

=head1 TODO

The GenomeMask should be able to handle double strand DNA (as an option)

=head1 METHODS

=head2 new

There is mutiple ways to create a genome mask:

One can specify a argument called C<genome> that is a hashref where keys are chromosome names
and values are chromosomes length.

  my $genome_mask = CracTools::GenomeMask->new( genome => { seq_name => length,
                                                            seq_name => length,
                                                            ...} );
One can specify a argument called C<crac_index_conf> that the configuration file of a CRAC index

  my $genome_mask = CracTools::GenomeMask->new(crac_index_conf => file.conf);

One can specify a C<CracTools::SAMReader> object in order to read chromosomes names and lenght from
the header

  my $genome_mask = CracTools::GenomeMask->new(sam_reader => CracTools::SAMReader->new(file.sam));

=head2 getBitvector

  Arg [1] : String - Chromosome

  Description : Return the CracTools::BitVector associated with the reference name given in argument.
                If no bitvectors exists for this reference, a warning will be reported.
  ReturnType  : CracTools::BitVector

=head2 getChrLength

  Arg [1] : String - Chromosome

  Description : Return the length of the chromosome
  ReturnType  : Integer

=head2 setPos

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Position

  Description : Set the bit a this genome location

=head2 setRegion

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Position start
  Arg [3] : Integer - Position end

  Example     ; $genome_mask->setRegion($chr,$start,$end)
  Description : Set all bits to 1 for this region

=head2 getPos

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Position

  Description : Return true is the bit is set at this genomic location
  ReturnType  : Boolean

=head2 getPosSetInRegion

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Position start
  Arg [3] : Integer - Position end

  Example     : my @nb_pos_set = @{$genome_mask->getNbBitsSetInRegion($chr,$start,$end)};
  Description : Return all the posititions of the bits set in this genomic
                region
  ReturnType  : Array(Integer)

=head2 getNbBitsSetInRegion

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Position start
  Arg [3] : Integer - Position end

  Description : Return the number of bits set in this genomic region
  ReturnType  : Integer

=head2 rank

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Position

  Description : Return the number of bits set, up to this genomic
                position as if the genome was linear.
  ReturnType  : Integer

=head2 select 

  Arg [1] : Integer - Nth bit set

  my ($chr,$pos) = $genome_mask->select(12)
  Description : Return an array with the (chr,pos) of the Nth bit set
  ReturnType  : Array(String,Integer)

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
