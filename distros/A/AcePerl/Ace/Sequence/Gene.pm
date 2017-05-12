package Ace::Sequence::Gene;

use strict;
use Ace;
use Ace::Sequence::Feature;
use vars '$AUTOLOAD';
use overload 
  '""' => 'asString',
  ;


# autoload delegates everything to the Ace::Sequence::Feature object
# contained in base
sub AUTOLOAD {
  my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
  my $self = shift;
  $self->{base}->$func_name(@_);
}

sub new {
  my $class = shift;
  my $args = shift;
  bless $args,$class;
  return $args;

# for documentation only
#  my %args = @_;
#  my $introns  = $args{intron};
#  my $exons    = $args{exon};
#  my $sequence = $args{base};  # this is the Ace::Sequence::Feature object
#  return bless {base => $sequence,
#		introns  => $introns,
#		exons    => $exons},$class;

}

sub asString {
  shift->{base}->info;
}

sub relative {
  my $self = shift;
  my $d = $self->{relative};
  $self->{relative} = shift if @_;
  $d;
}

sub introns {
  my $self = shift;
  return $self->{intron} ? @{$self->{intron}} : () unless $self->relative;
  # otherwise, we have to handle relative coordinates
  my $base   = $self->{base};
  my @e = map {Ace::Sequence->new(-refseq=>$base,-seq=>$_)} @{$self->{intron}};
  return $self->strand < 0 ? reverse @e : @e;
}

sub exons {
  my $self = shift;
  return $self->{exon} ? @{$self->{exon}} : () unless $self->relative;
  # otherwise, we have to handle relative coordinates
  my $base   = $self->{base};
  my @e = map {Ace::Sequence->new(-refseq=>$base,-seq=>$_)} @{$self->{exon}};
  return $self->strand < 0 ? reverse @e : @e;
}

1;

__END__

=head1 NAME

Ace::Sequence::Gene - Simple "Gene" Object

=head1 SYNOPSIS

    # open database connection and get an Ace::Object sequence
    use Ace::Sequence;

    # get a megabase from the middle of chromosome I
    $seq = Ace::Sequence->new(-name   => 'CHROMOSOME_I,
                              -db     => $db,
			      -offset => 3_000_000,
			      -length => 1_000_000);

    # get all the genes
    @genes = $seq->genes;

    # get the exons from the first one
    @exons = $genes[0]->exons;

    # get the introns
    @introns = $genes[0]->introns

    # get the CDSs (NOT IMPLEMENTED YET!)
    @cds = $genes[0]->cds;

=head1 DESCRIPTION

Ace::Sequence::Gene is a subclass of Ace::Sequence::Feature.  It
inherits all the methods of Ace::Sequence::Feature, but adds the
ability to retrieve the annotated introns and exons of the gene.

=head1  OBJECT CREATION

You will not ordinarily create an I<Ace::Sequence::Gene> object
directly.  Instead, objects will be created in response to a genes()
call to an I<Ace::Sequence> object.

=head1 OBJECT METHODS

Most methods are inherited from I<Ace::Sequence::Feature>.  The
following methods are also supported:

=over 4

=item exons()

  @exons = $gene->exons;

Return a list of Ace::Sequence::Feature objects corresponding to
annotated exons.

=item introns()

  @introns = $gene->introns;

Return a list of Ace::Sequence::Feature objects corresponding to
annotated introns.

=item cds()

  @cds = $gene->cds;

Return a list of Ace::Sequence::Feature objects corresponding to
coding sequence.  THIS IS NOT YET IMPLEMENTED.

=item relative()

  $relative = $gene->relative;
  $gene->relative(1);

This turns on and off relative coordinates.  By default, the exons and
intron features will be returned in the coordinate system used by the
gene.  If relative() is set to a true value, then coordinates will be
expressed as relative to the start of the gene.  The first exon will
(usually) be 1.

=head1 SEE ALSO

L<Ace>, L<Ace::Object>, L<Ace::Sequence>,L<Ace::Sequence::Homol>,
L<Ace::Sequence::Feature>, L<Ace::Sequence::FeatureList>, L<GFF>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1999, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

