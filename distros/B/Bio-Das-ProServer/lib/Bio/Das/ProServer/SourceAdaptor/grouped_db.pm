#########
# Author:        jws
# Maintainer:    jws, dj3
# Created:       2005-04-19
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: grouped_db.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceAdaptor/grouped_db.pm,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/grouped_db.pm $
# Builds DAS features from ProServer mysql database
# schema at eof
#
## no critic (ValuesAndExpressions::ProhibitImplicitNewlines)
#
package Bio::Das::ProServer::SourceAdaptor::grouped_db;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor);
use Readonly;

our $VERSION  = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

Readonly::Scalar our $SHORT_SEG_LEN => 4;

sub capabilities {
  return {
	  features     => '1.0',
	  stylesheet   => '1.0',
	  entry_points => '1.0',
	  types        => '1.0',
	 };
}

sub build_features {
  my ($self, $opts) = @_;
  my $seg     = $opts->{segment};
  my $start   = $opts->{start};
  my $end     = $opts->{end};
  my $shortsegnamehack = (defined $self->config->{'shortsegnamehack'})?$self->config->{'shortsegnamehack'}:1; #e.g. 1 (default) or 0

  if($shortsegnamehack && (CORE::length($seg) > $SHORT_SEG_LEN)) {
    return;
  }

  my $qbounds = q();

  if(defined $start && $start ne q() && defined $end && $end ne q()) {
    $start   = $self->transport->dbh->quote($start);
    $end     = $self->transport->dbh->quote($end);
    $qbounds = qq(AND start <= $end AND end >= $start);
  }

  my $query = qq(SELECT * FROM feature, fgroup
                 WHERE  segment          = ? $qbounds
                 AND    feature.group_id = fgroup.group_id
                 ORDER BY start);
  my @results;

  for ( @{$self->transport->query($query, $seg)} ) {
    push @results, {
		    id           => $_->{id},
		    start        => $_->{start},
		    end          => $_->{end},
		    label        => $_->{label},
		    score        => $_->{score},
		    ori          => $_->{orient},
		    phase        => $_->{phase},
		    type         => $_->{type_id},
		    typecategory => $_->{type_category},
		    method       => $_->{method},
		    group        => $_->{group_id},
		    grouptype    => $_->{group_type},
		    grouplabel   => $_->{group_label},
		    groupnote    => $_->{group_note},
		    grouplink    => $_->{group_link_url},
		    grouplinktxt => $_->{group_link_text},
		    target_start => $_->{target_start},
		    target_stop  => $_->{target_end},
		    target_id    => $_->{target_id},
		    link         => $_->{link_url},
		    linktxt      => $_->{link_text},
		    note         => $_->{note},
		   };

  }

  return @results;
}

sub build_types {
  my ($self, @args) = @_;
  if(!scalar @args) {
    my $query   = q(SELECT DISTINCT type_id type, method FROM feature);
    return @{$self->transport->query($query)};
  }

  my @r;

  for (@args) {
    my ($seg, $start, $end) = @{$_}{qw(segment start end)};
    my $qbounds = q();

    if(defined $start && $start ne q() && defined $end && $end ne q()) {
      $start   = $self->transport->dbh->quote($start);
      $end     = $self->transport->dbh->quote($end);
      $qbounds = qq(AND start <= $end AND end >= $start);
    }

    my $query   = qq(SELECT DISTINCT type_id type, method FROM feature
                     WHERE  segment = ? $qbounds);
    push @r, map { $qbounds?$self->_build_types_population($_, $seg, $start, $end):$_; }
                 @{$self->transport->query($query, $seg)};
  }
  return @r;
}

sub _build_types_population {
  my ($self, $ref, $seg, $start, $end) = @_;
  $ref->{segment} = $seg;
  @{$ref}{qw(start end)} = ($start, $end);
  return $ref;
}

sub build_entry_points {
  my ($self) = @_;
  my $query  = q(SELECT DISTINCT segment FROM feature);
  return map { $self->_build_ep_population($_); }
             @{$self->transport->query($query)};
}

sub _build_ep_population {
  my ($self, $ref) = @_;
  $ref->{subparts} = 'no';
  if(exists $self->{config}->{assembly}) {
    $ref->{version}  = $self->{config}->{assembly};
  }
  return $ref;
}

sub segment_version {
  my $self = shift;
  return (exists $self->{config}->{assembly})?$self->{config}->{assembly}:undef;
}

1;

# SCHEMA
# Generic MySQL schema to hold DAS feature data for ProServer
#	
#	feature
#		id		varchar(30)	
#		label		varchar(30)
#		segment		varchar(30)
#		start		int(11)
#		end		int(11)
#		score		float
#		orient		enum('0', '+', '-')
#		phase		enum('0','1','2')
#		type_id		varchar(30)
#		type_category	varchar(30)
#		method		varchar(30)
#		group_id	varchar(30)
#		target_id	varchar(30)
#		target_start	int(11)
#		target_end	int(11)
#		link_url	varchar(255)
#		link_text	varchar(30)
#		note		text
#		
#	fgroup
#		group_id	varchar(30)
#		group_label	varchar(30)
#		group_type	varchar(30)
#		group_note	text
#		group_link_url	varchar(255)
#		group_link_text	varchar(30)
#	
#	Note that spec allows multiple groups, targets, and links per feature,
#	but these aren't implemented here.
#	

__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::grouped_db

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 capabilities

=head2 build_features

=head2 build_types

=head2 build_entry_points

=head2 segment_version

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Bio::Das::ProServer::SourceAdaptor

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
