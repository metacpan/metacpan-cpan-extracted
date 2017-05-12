package CracTools::GFF::Annotation;
{
  $CracTools::GFF::Annotation::DIST = 'CracTools';
}
# ABSTRACT: Parse GFF lines.
$CracTools::GFF::Annotation::VERSION = '1.25';
use strict;
use warnings;

use Carp;
use CracTools::Utils;


sub new {
  my $class = shift;
  my $line = shift;
  my $format = shift;
  if(!defined $format) {
    $format = 'gff3';
  }

  my $self = bless {format => $format}, $class;

  if(defined $line) {
    $self->_init($line);  
  }

  return $self;
}

sub _init {
  my ($self,$line) = @_;

  # Split the line with TABS
  my ($chr,$source,$feature,$start,$end,$score,$strand,$phase,$attributes) = split("\t",$line);

  # Get the strand if 1/-1 format
  $strand = CracTools::Utils::convertStrand($strand);

  # We do not want any "chr" string before the reference sequence value
  $chr =~ s/^chr//;

  # Loading the 8 first columns
  $self->{chr} = $chr;
  $self->{source} = $source;
  $self->{feature} = $feature;

  # Conversion to 0-based coordinate system
  $self->{start} = $start-1;
  $self->{end} = $end-1;

  $self->{score} = $score;
  $self->{strand} = $strand;
  $self->{phase} = $phase;

  # Loading attributes
  my @attributes_tab = split(";",$attributes);
  foreach my $attr (@attributes_tab) {
    my ($k,$v);
    if($self->{format} =~ /gff3/i || $self->{format} =~ /gff$/i) {
      ($k,$v) = $attr =~ /(\S+)=(.*)/;
    } elsif ($self->{format} =~ /gtf/i){
      ($k,$v) = $attr =~ /(\S+)\s+"(.*)"/;
    }else{
	croak "Missing format argument (gff3,gtf) in CracTools::GFF::Annotation constructor";
    }
    if(defined $k && defined $v) {
      if($k eq "Parent") {
        my @parents = split(',',$v);
        $v = \@parents;
      }
      $self->{attributes}{$k} = $v;
    } #else {
    #  carp("Error parsing attribute $attr");
    #}
  }

}


sub chr {
  my $self = shift;
  my $chr = shift;
  if(defined $chr) {
    $self->{chr} = $chr;
  }
  return $self->{chr};
}


sub source {
  my $self = shift;
  my $source = shift;
  if(defined $source) {
    $self->{source} = $source;
  }
  return $self->{source};
}


sub feature {
  my $self = shift;
  my $feature = shift;
  if(defined $feature) {
    $self->{feature} = $feature;
  }
  return $self->{feature};
}


sub start {
  my $self = shift;
  my $start = shift;
  if(defined $start) {
    $self->{start} = $start;
  }
  return $self->{start};
}


sub end {
  my $self = shift;
  my $end = shift;
  if(defined $end) {
    $self->{end} = $end;
  }
  return $self->{end};
}


sub score {
  my $self = shift;
  my $score = shift;
  if(defined $score) {
    $self->{score} = $score;
  }
  return $self->{score};
}


sub strand {
  my $self = shift;
  my $strand = shift;
  if(defined $strand) {
    $self->{strand} = $strand;
  }
  return $self->{strand};
}


sub gffStrand {
  my $self = shift;
  return CracTools::Utils::convertStrand($self->{strand});
}


sub phase {
  my $self = shift;
  my $phase = shift;
  if(defined $phase) {
    $self->{phase} = $phase;
  }
  return $self->{phase};
}


sub parents {
  my $self = shift;
  if(defined $self->attribute('Parent')) {
    return $self->attribute('Parent');
  } else {
    return [];
  }
}


sub attribute {
  my $self = shift;
  my $key = shift;
  my $value = shift;
  if(defined $value) {
    return $self->{attributes}{$key} = $value;
  } elsif(defined $key) {
    return $self->{attributes}{$key};
  } else {
    return undef;
    #croak ("Missing attribute key to retreive attribute value");
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::GFF::Annotation - Parse GFF lines.

=head1 VERSION

version 1.25

=head1 SYNOPSIS

  use CracTools::GFF::Query;

  # Creating the reader
  my $gffQuery = CracTools::GFF::Query->new('annotations.gff');

  my @annotations = $gffQuery->fetchByLocation('1',298345,'+');

  foreach my $gff_line (@annotations) {
    my $annotation = CracTools::GFF::Annotation->new($gff_line);
    print "Gene_id : ",$annotation->attribute('gene_id'),"\n";
  }

=head1 DESCRIPTION

This module defines an object to easily parse and access GFF line's fields.

=head1 TODO

Set Parent for feature in GTF format (gene_id for transcript and transcript_id for exons).

=head1 METHODS

=head2 new

  Arg [1] : String - $line
            GFF line
  Arg [2] : String - $format (optional) - default 'gff3'
            GFF format (gtf or gff3)

  Example     : my $annotation = CracTools::GFF::Annotation->new($gff_line);
  Description : Create a new CracTools::GFF::Annotation object
                If a gff line is passed in argument, the line will be parsed
                and loaded.
  ReturnType  : CracTools::GFF::Query

=head1 GETTERS AND SETTERS

=head2 chr

  Description : Getter/setter for attribute chr

=head2 source

  Description : Getter/setter for attribute source

=head2 feature

  Description : Getter/setter for attribute feature

=head2 start

  Description : Getter/setter for attribute start

=head2 end

  Description : Getter/setter for attribute end

=head2 score

  Description : Getter/setter for attribute score

=head2 strand

  Description : Getter/setter for attribute strand ('1','-1' convention)

=head2 gffStrand

  Description : Return strand using "+","-" convention.

=head2 phase

  Description : Getter/setter for attribute phase

=head2 parents

  Description : Getter for attribute parents.
  ReturnType  : Array of strings with parents ID

=head2 attribute

  Description : Getter/setter for attribute attribute

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
