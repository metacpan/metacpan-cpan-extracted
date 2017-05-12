#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Builds DAS features from parsed interpro entries served from SRS
#
package Bio::Das::ProServer::SourceAdaptor::interpro;

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
			     'types'    => '1.0',
			    };
}

sub length {
  my ($self, $id) = @_;
  $self->{'_data'}->{$id} ||= $self->transport->query('-e', "[IPRMATCHES:$id]|[IPRMATCHES-pnm:$id]");
  my ($len)       = $self->{'_data'}->{$id} =~ /length="([0-9]+)"/;
  return $len;
}

sub build_types {
  my ($self, $opts) = @_;
  my $seg   = $opts->{'segment'};
  my @types = ();

  if($seg) {
    my %typecount = ();
    map { $typecount{(split(':', $_->{'type'}))[0]}++ } $self->build_features($opts);
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
    $self->{'_data'}->{$seg} ||= $self->transport->query('-e', "[IPRMATCHES:$seg]|[IPRMATCHES-pnm:$seg]");
    $self->{'_data'}->{$seg} =~ s/<interpro.*?name="(.*?)".*?<match id="(\S+)" name="(\S+)" dbname="(\S+)">(.*?)<\/match>/&_add_iprmatches_feature($self, $opts, $1, $2, $3, $4, $5)/smegi;
  }
  
  return @{$self->{'_features'}->{$seg}};
}

sub _add_iprmatches_feature {
  my ($self, $opts, $iprname, $matchid, $matchname, $matchdbname, $location)= @_;
  
  $location =~ s/<location start="(\S+)" end="(\S+)".*?evidence="(\S+)".*?\/>/&_add_iprmatches_location($self, $opts, $iprname, $matchid, $matchname, $matchdbname, $1, $2, $3)/smegi;
  
  return "";
}

sub _add_iprmatches_location {
  my ($self, $opts, $iprname, $matchid, $matchname, $matchdbname, $ftstart, $ftend, $ftevidence) = @_;
  
  ($ftstart, $ftend) = ($ftend, $ftstart) if($ftstart > $ftend);
  
  return if(defined $opts->{'start'} &&
	    defined $opts->{'end'} &&
	    ($ftstart > $opts->{'end'} ||
	     $ftend < $opts->{'start'}));
  
  push @{$self->{'_features'}->{$opts->{'segment'}}}, {
						       'id'     => $matchid,
						       'type'   => $matchdbname,
						       'method' => "$matchdbname:$iprname",
						       'start'  => $ftstart,
						       'end'    => $ftend,
						       'note'   => "$ftevidence:$matchname",
						       'group'  => $matchid,
						      };
  return "";
}

1;
