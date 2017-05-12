#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-10-28
# Last Modified: 2003-10-28
#
# Builds das from parser genesat tab-delimited flat files of the form:
# gene.name\tgene.id
#
package Bio::Das::ProServer::SourceAdaptor::gensat;

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
			    };
}

sub length {
  0;
}

sub build_features {
  my ($self, $opts) = @_;

  return if(defined $opts->{'start'} || defined $opts->{'end'});

  my $baseurl = $self->config->{'baseurl'};
  my $segment = $opts->{'segment'};

  my @matches = @{$self->transport->query(sprintf($self->config->{'feature_query'}, $segment))};
  my @results = ();

  for my $match (@matches) {
      for my $matchlink (split(/ /, @{$match}[2])) {
	  my ($linktxt, $link) = split(':', $matchlink, 2);
	  push @results, {
	      'id'      => $segment,
	      'type'    => "link",
	      'method'  => "link",
	      'link'    => $link,
	      'linktxt' => $linktxt,
	      'note'    => $linktxt,
	  };
      }

      my $description = (@{$match}[1]||"") . ": " . (@{$match}[9]||""). " " . @{$match}[2];
      if($description) {
	  push @results, {
	      'id'      => $segment,
	      'type'    => "description",
	      'method'  => "description",
	      'note'    => $description,
	      'link'    => "http://www.gensat.org/",
	  };
      }

      push @results, {
	  'id'     => $segment,
	  'type'   => "navigation",
	  'method' => "navigation",
	  'note'   => qq(@{[map { my ($whichway, $id) = split(':', $_, 2); qq($whichway:navigation://$id) } split(" ", @{$match}[10])]}),
      };
  }

  return @results;
}

1;
