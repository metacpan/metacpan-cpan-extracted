package Bio::Graphics::Glyph::decorated_gene;

use strict;
use vars qw($VERSION);
use base 'Bio::Graphics::Glyph::decorated_transcript';

$VERSION = '0.02';

sub my_descripton {
    return <<END;
This glyph has the same functionality as Bio::Graphics::Glyph::gene, but uses
Bio::Graphics::Glyph::decorated_transcript instead of the 
Bio::Graphics::Glyph::processed_transcript to render transcripts, which allows
sequence features to be highlighted on top of gene models. This functionality is for example 
useful when one wants to assess how different splice forms of the same gene differ 
in terms of encoded protein features, such as protein domains, signal peptides, or 
transmembrane regions.

See Bio::Graphics::Glyph::decorated_transcript for a detailed description of how to 
provide protein decorations for transcripts.  
END
}

sub my_options {
    {
	label_transcripts => [
	    'boolean',
	    undef,
	    'If true, then the display_name of each transcript',
	    'will be drawn to the left of the transcript glyph.'],
	thin_utr => [
	    'boolean',
	    undef,
	    'If true, UTRs will be drawn at 2/3 of the height of CDS segments.'],
	utr_color => [
	    'color',
	    'grey',
	    'Color of UTR segments.'],
	decorate_introns => [
	    'boolean',
	    undef,
	    'Draw chevrons on the introns to indicate direction of transcription.'
	],
    }
}

sub extra_arrow_length {
  my $self = shift;
  return 0 unless $self->{level} == 1;
  local $self->{level} = 0;  # fake out superclass
  return $self->SUPER::extra_arrow_length;
}

sub pad_left {
  my $self = shift;
  my $type = $self->feature->primary_tag;
  return 0 unless $type =~ /gene|mRNA/;
  $self->SUPER::pad_left;
}

sub pad_right {
  my $self = shift;
  return 0 unless $self->{level} < 2; # don't invoke this expensive call on exons
  my $strand = $self->feature->strand;
  $strand *= -1 if $self->{flip};
  my $pad    = $self->SUPER::pad_right;
  return $pad unless defined($strand) && $strand > 0;
  my $al = $self->arrow_length;
  return $al > $pad ? $al : $pad;
}

sub pad_bottom {
  my $self = shift;
  return 0 unless $self->{level} < 2 || $self->is_utr; # don't invoke this expensive call on exons
  return $self->SUPER::pad_bottom;
}

sub pad_top {
  my $self = shift;
  return 0 unless $self->{level} < 2 || $self->is_utr; # don't invoke this expensive call on exons
  return $self->SUPER::pad_top;
}

sub bump {
  my $self = shift;
  my $bump;
  if ($self->{level} == 0
      && lc $self->feature->primary_tag eq 'gene'
      && eval {($self->subfeat($self->feature))[0]->type =~ /RNA|pseudogene/i}) {
      $bump = $self->option('bump');
  } else {
      $bump = $self->SUPER::bump;
  }
  return $bump;
}

sub label {
  my $self = shift;
  return unless $self->{level} < 2;
  if ($self->label_transcripts && $self->{feature}->primary_tag =~ /RNA|pseudogene/i) {
    return $self->_label;
  } else {
    return $self->SUPER::label;
  }
}

sub label_position {
  my $self = shift;
  return 'top' if $self->{level} == 0;
  return 'left';
}

sub label_transcripts {
  my $self = shift;
  return $self->{label_transcripts} if exists $self->{label_transcripts};
  return $self->{label_transcripts} = $self->_label_transcripts;
}

sub _label_transcripts {
  my $self = shift;
  return $self->option('label_transcripts');
}

sub draw_connectors {
  my $self = shift;
  if ($self->feature->primary_tag eq 'gene') {
      my @parts = $self->parts;
      return if @parts && $parts[0]->feature->primary_tag =~ /rna|transcript|pseudogene/i;
  }
  $self->SUPER::draw_connectors(@_);
}

sub maxdepth {
  my $self = shift;
  my $md   = $self->Bio::Graphics::Glyph::maxdepth;
  return $md if defined $md;
  return 2;
}


sub _subfeat {
  my $class   = shift;
  my $feature = shift;

  if ($feature->primary_tag =~ /^gene/i) {
    my @transcripts;
# 2012-05-14 | CF | filtering for primary tag in get_SeqFeatures not working for GFF memory adaptor; 
#                   all subfeatures are returned for every function call; using alternative function call 
#                   to avoid duplication of transcripts    
#    for my $t (qw/mRNA tRNA snRNA snoRNA miRNA ncRNA pseudogene/) {
#      push @transcripts, $feature->get_SeqFeatures($t);
#    }
	foreach my $t ($feature->get_SeqFeatures)
	{
		push(@transcripts, $t) if ($t->primary_tag =~ /mRNA|tRNA|snRNA|snoRNA|miRNA|ncRNA|pseudogene/);
	}
#    map { print "  ".$_->id."\n" } @transcripts;
    return @transcripts if @transcripts;
    my @features = $feature->get_SeqFeatures;  # no transcripts?! return whatever's there
    return @features if @features;

    # fall back to drawing a solid box if no subparts and level 0
    return ($feature) if $class->{level} == 0;
  }
  elsif ($feature->primary_tag =~ /^CDS/i) {
      my @parts = $feature->get_SeqFeatures();
      return ($feature) if $class->{level} == 0 and !@parts;
      return @parts;
  }

  my @subparts;
  if ($class->option('sub_part')) {
    @subparts = $feature->get_SeqFeatures($class->option('sub_part'));
  }
  elsif ($feature->primary_tag =~ /^mRNA/i) {
    @subparts = $feature->get_SeqFeatures(qw(CDS five_prime_UTR three_prime_UTR UTR));
  }
  else {
    @subparts = $feature->get_SeqFeatures('exon');
  }
 
  # The CDS and UTRs may be represented as a single feature with subparts or as several features
  # that have different IDs. We handle both cases transparently.
  my @result;
  foreach (@subparts) {
    if ($_->primary_tag =~ /CDS|UTR/i) {
      my @cds_seg = $_->get_SeqFeatures;
      if (@cds_seg > 0) { push @result,@cds_seg  } else { push @result,$_ }
    } else {
      push @result,$_;
    }
  }
  # fall back to drawing a solid box if no subparts and level 0
  return ($feature) if $class->{level} == 0 && !@result;

  return @result;
}

#sub _subfeat {
#  my $class   = shift;
#  my $feature = shift;
#  return $feature->get_SeqFeatures('mRNA') if $feature->primary_tag eq 'gene';
#
#  my @subparts;
#  if ($class->option('sub_part')) {
#    @subparts = $feature->get_SeqFeatures($class->option('sub_part'));
#  }
#  else {
#
#    @subparts = $feature->get_SeqFeatures(qw(CDS five_prime_UTR three_prime_UTR UTR));
#  }
# 
#  # The CDS and UTRs may be represented as a single feature with subparts or as several features
#  # that have different IDs. We handle both cases transparently.
#  my @result;
#  foreach (@subparts) {
#    if ($_->primary_tag =~ /CDS|UTR/i) {
#      my @cds_seg = $_->get_SeqFeatures;
#      if (@cds_seg > 0) { push @result,@cds_seg  } else { push @result,$_ }
#    } else {
#      push @result,$_;
#    }
#  }
#  return @result;
#}

1;

__END__

=head1 NAME

Bio::Graphics::Glyph::decorated_gene - A GFF3-compatible gene glyph with protein decorations

=head1 SYNOPSIS

  See L<Bio::Graphics::Panel> and L<Bio::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph has the same functionality as L<Bio::Graphics::Glyph::gene>, but uses
L<Bio::Graphics::Glyph::decorated_transcript> instead of the 
L<Bio::Graphics::Glyph::processed_transcript> to render transcripts, which allows
sequence features to be highlighted on top of gene models. This functionality is for example 
useful when one wants to assess how different splice forms of the same gene differ 
in terms of encoded protein features, such as protein domains, signal peptides, or 
transmembrane regions.

See L<Bio::Graphics::Glyph::decorated_transcript> for a detailed description of how 
to provide protein decorations for transcripts.  

=head1 BUGS

=head1 SEE ALSO


L<Bio::Graphics::Glyph::gene>,
L<Bio::Graphics::Glyph::decorated_transcript>

=head1 AUTHOR

Christian Frech E<lt>frech.christian@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

