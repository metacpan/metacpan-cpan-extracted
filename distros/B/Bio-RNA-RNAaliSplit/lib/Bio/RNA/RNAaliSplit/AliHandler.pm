# -*-CPerl-*-
# Last changed Time-stamp: <2019-04-24 00:49:39 mtw>
#
# This a base class for handling alignment files in different formats

package Bio::RNA::RNAaliSplit::AliHandler;

use Moose;
use Bio::RNA::RNAaliSplit::Subtypes;
use namespace::autoclean;
use Data::Dumper;
use diagnostics;
use version; our $VERSION = qv('0.11');

has 'format' => (
                 is => 'ro',
                 isa => 'Str',
                 predicate => 'has_format',
                 default => 'ClustalW',
                 required => 1,
                );

has 'alignment' => (
                    is => 'rw',
                    isa => 'Bio::RNA::RNAaliSplit::AliIO',
                    predicate => 'has_aln',
                    coerce => 1,
                   );

has 'next_aln' => (
                   is => 'rw',
                   isa => 'Bio::SimpleAlign',
                   predicate => 'has_next_aln',
                   init_arg => undef,
                  );

has 'alen' => ( #alignment length
	       is => 'rw',
	       isa => 'Int',
	       predicate => 'has_alen',
	       init_arg => undef,
	      );

has 'nrseq' => ( # number of sequences in alignment
		is => 'rw',
		isa => 'Int',
		predicate => 'has_nrseq',
		init_arg => undef,
	       );

sub _get_alen {
  my $self = shift;
  $self->alen($self->next_aln->length());
}

sub _get_nrseq {
  my $self = shift;
  $self->nrseq($self->next_aln->num_sequences());
}

no Moose;
1;

__END__


