#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Builds das from parser swissprot featuretables served from SRS
#
package Bio::Das::ProServer::SourceAdaptor::swissprot;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use vars qw(@ISA);
use Bio::Das::ProServer::SourceAdaptor;
@ISA = qw(Bio::Das::ProServer::SourceAdaptor);

sub init {
  my $self = shift;
  $self->{'capabilities'} = {
			     'features' => '1.0',
			     'dna'      => '1.0',
			     'types'    => '1.0',
			    };
  $self->{'_features'} ||= {};
  $self->{'_data'}     ||= {};
}

sub dna {
  my $self = shift;
  return $self->sequence(@_);
}

sub sequence {
  my ($self, $opts) = @_;
  my $seg = $opts->{'segment'};

  if(!exists $self->{'_sequence'}->{$seg}) {
    $self->{'_data'}->{$seg} ||= $self->transport->query('-e', "[SWISSPROT-acc:$seg]|[SWISSPROT-id:$seg]");
    $self->{'_data'}->{$seg} =~ s/^     (.*)\n/&_add_sequence($self, $seg, $1)/meg;
  }

  my $seq = $self->{'_sequence'}->{$opts->{'segment'}} || "";
  if(defined $opts->{'start'} && defined $opts->{'end'}) {
    $seq = substr($seq, $opts->{'start'}-1, $opts->{'end'}+1-$opts->{'start'});
  }

  return {
	  'seq'     => $seq,
	  'moltype' => 'Protein',
  };
}

sub _add_sequence {
  my ($self, $seg, $seq) = @_;
  $seq =~ s/\s+//g;
  $self->{'_sequence'}->{$seg} .= $seq;
  return "";
}

sub length {
  my ($self, $id) = @_;

  $self->{'_data'}->{$id} ||= $self->transport->query('-e', "[SWISSPROT-acc:$id]|[SWISSPROT-id:$id]");
  my ($len) = $self->{'_data'}->{$id} =~ /([0-9]+) AA/;

  return $len;
}

sub build_types {
  my ($self, $opts) = @_;
  my $seg   = $opts->{'segment'};
  my @types = ();

  if(defined $seg) {
    my %typecount = ();
    map { $typecount{$_->{'type'}}++ } $self->build_features($opts);
    @types = sort { $b->{'count'} <=> $a->{'count'} } map { {
        'type'  => $_,
        'count' => $typecount{$_},
    } } keys %typecount;
  }
  return @types;
}

sub build_features {
  my ($self, $opts) = @_;
  my $seg = $opts->{'segment'};
  
  $self->{'_features'}->{$seg} ||= [];
  
  if(scalar @{$self->{'_features'}->{$seg}} == 0) {
    $self->{'_data'}->{$seg} ||= $self->transport->query('-e', "[SWISSPROT-acc:$seg]|[SWISSPROT-id:$seg]");
    return unless($self->{'_data'}->{$seg});

    $self->{'_data'}->{$seg}   =~ s/^DE\s+(.*?)\n/&_add_swissprot_description($self, $opts, $1)/meg;
    $self->{'_data'}->{$seg}   =~ s/^(R.)\s+(.*?)\n/&_add_swissprot_reference($self, $opts, $1, $2)/meg;
    $self->{'_data'}->{$seg}   =~ s/^FT\s+(.*?)\n/&_add_swissprot_feature($self, $opts, $1)/meg;
  }
  
  return @{$self->{'_features'}->{$seg}};
}

sub _add_swissprot_reference {
  my ($self, $opts, $tag, $line) = @_;
  my $seg = $opts->{'segment'};

  if($tag eq "RN") {
    $self->{'_current_reference'} = {
				     'type'   => "reference",
				     'method' => "reference",
				     'start'  => $self->start(),
				     'end'    => $self->length($seg),
				     'id'     => $seg,
				     'note'   => "",
				    };
    push @{$self->{'_features'}->{$seg}}, $self->{'_current_reference'};

  } elsif($tag eq "RX") {
    my ($pubmed) = $line =~ /pubmed=([0-9]+)/i;
    return unless($pubmed);
    $self->{'_current_reference'}->{'note'}   .= qq( pubmed:http://www.ncbi.nlm.nih.gov/entrez/utils/qmap.cgi?uid=$pubmed&form=6&db=m&Dopt=r );
#    $self->{'_current_reference'}->{'linktxt'} = $pubmed;

  } elsif($tag eq "RA" || $tag eq "RT" || $tag eq "RL") {
    $self->{'_current_reference'}->{'note'} .= "$line ";
  }
}


sub _add_swissprot_description {
  my ($self, $opts, $line) = @_;
  my $seg = $opts->{'segment'};

  if($self->{'_desc_feats'}->{$seg}) {
    $self->{'_desc_feats'}->{$seg}->{'note'} .= $line;
    
  } else {
    $self->{'_desc_feats'}->{$seg} = {
				      'type'   => "description",
				      'method' => "description",
				      'start'  => $self->start(),
				      'end'    => $self->length($seg),
				      'note'   => $line || "",
				      'id'     => $seg,
				      'link'   => qq(http://srs.sanger.ac.uk/srsbin/cgi-bin/wgetz?-e+[SWISSPROT-acc:$seg]|[SWISSPROT-id:$seg]),
				     };
    push @{$self->{'_features'}->{$seg}}, $self->{'_desc_feats'}->{$seg};
  }
}

sub _add_swissprot_feature {
  my ($self, $opts, $line) = @_;
  my ($type, $start, $end, $note) = $line =~ /(\S+)\s+([0-9]+)\s+([0-9]+)(.*)/;
  
  if(!defined $type && !defined $start && !defined $end) {
    return "" unless(defined $self->{'_lastfeature'});
    #########
    # this line is a continuation of a previous feature
    #
    $note   = $line;
    $note ||= "";
    $note   =~ s/^\s+//;
    
    #########
    # pull feature id if it's available
    #
    $note   =~ s/\/FTId=(.*?)\.//;
    $self->{'_lastfeature'}->{'id'}    = $1 if($1 && $1 ne "");
    
    $self->{'_lastfeature'}->{'note'} .= qq( $note) if($note && $note ne "");
    
  } else {
    #########
    # this is a new feature
    #
    $note ||= "";
    $note   =~ s/^\s+//;
    my $id  = $note;
    
    if($id =~ /^(\S+)\s+[0-9]+\./) {
      $id   = $1;
      $note = $1;
      
    } else {
      $id = undef;
    }
    
    if(defined $opts->{'start'} &&
       defined $opts->{'end'}   &&
       ($start > $opts->{'end'} ||
	$end   < $opts->{'start'})) {
      undef($self->{'_lastfeature'});
      return "";
    }
    
    $self->{'_lastfeature'} = {
			       'type'   => $type,
			       'method' => $type,
			       'start'  => $start,
			       'end'    => $end,
			       'note'   => $note,
			       'id'     => qq(${type}:${start}:${end}),
			      };
    push @{$self->{'_features'}->{$opts->{'segment'}}}, $self->{'_lastfeature'};
  }
  return "";
}

1;
