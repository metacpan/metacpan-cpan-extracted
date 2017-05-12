package Ace::Object::Wormbase;
use strict;
use Carp;
use Ace::Object;

# $Id: Wormbase.pm,v 1.3 2003/12/27 15:52:35 todd Exp $
use vars '@ISA';
@ISA = 'Ace::Object';

# override the Locus method for backward compatibility with model shift
sub Locus {
  my $self = shift;
  return $self->SUPER::Locus(@_) unless $self->class eq 'Sequence';
  if (wantarray) {
    return ($self->Locus_genomic_seq,$self->Locus_other_seq);
  } else {
    return $self->Locus_genomic_seq || $self->Locus_other_seq;
  }
}

sub Sequence {
  my $self = shift;
  return $self->SUPER::Sequence(@_) unless $self->class eq 'Locus';
  if (wantarray) {
#    return ($self->Genomic_sequence,$self->Other_sequence);
    return ($self->CDS,$self->Other_sequence);
  } else {
#    return $self->Genomic_sequence || $self->Other_sequence;
    return $self->CDS || $self->Other_sequence;
  }
}


1;
