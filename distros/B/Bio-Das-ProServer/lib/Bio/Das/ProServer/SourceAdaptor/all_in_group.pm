#########
# Author:        jws, dj3
# Maintainer:    $Author: zerojinx $
# Created:       2005-04-19
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: all_in_group.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceAdaptor/all_in_group.pm,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/all_in_group.pm $
#
package Bio::Das::ProServer::SourceAdaptor::all_in_group;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor);
use Readonly;

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };
Readonly::Scalar our $SHORT_SEG_LEN => 4;

sub capabilities {
  return {
	  features   => '1.0',
	  stylesheet => '1.0',
	 };
}

sub build_features {
  my ($self, $opts) = @_;
  my $seg     = $opts->{segment};
  my $start   = $opts->{start};
  my $end     = $opts->{end};
  my $dbh     = $self->transport->dbh();
  my $shortsegnamehack = (defined $self->config->{shortsegnamehack})?$self->config->{shortsegnamehack}:1; #e.g. 1 (default) or 0

  if($shortsegnamehack and (CORE::length($seg) > $SHORT_SEG_LEN)) {# speedup - only handle chromosomes or haplotypes
    return;
  }

  # To include group members that are outside the range of the request, first
  # pull back the groups that are within the range, and then retrieve all the
  # features in those groups.

  my $qbounds = q();

  if(defined $start && defined $end) {
    $qbounds = q(AND start <= ) . $dbh->quote($end) .
               q( AND end >= )  . $dbh->quote($start);
  }

  my $query   = qq(SELECT group_id FROM feature
                   WHERE  segment = ? $qbounds);

  my @groups = @{$self->transport->query($query, $seg)};

  if(!scalar @groups) {
    return;
  }

  my $groupstring = qq( AND feature.group_id IN (@{[join q(, ), map { $dbh->quote($_->{group_id}) } @groups]}));
  $query          = qq(SELECT * FROM feature, fgroup
                       WHERE  segment          = ? $groupstring
                       AND    feature.group_id = fgroup.group_id
                       ORDER BY start);
  my @results;

  for ( @{$self->transport->query($query, $seg)} ) {
    my $fstart = $_->{start};
    my $fend   = $_->{end};
    my $type   = $_->{type_id};
    my $method = $_->{method};

    #fake features outside the range - das code will filter these otherwise
    if ($fend < $start) {
      $fend = $fstart = $start;
      $type = "$method:hidden";
    }

    if ($fstart > $end) {
      $fend = $fstart = $end;
      $type = "$method:hidden";
    }

    push @results, {
		    id           => $_->{id},
		    start        => $fstart,
		    end          => $fend,
		    label        => $_->{label},
		    score        => $_->{score},
		    ori          => $_->{orient},
		    phase        => $_->{phase},
		    type         => $type,
		    typecategory => $_->{type_category},
		    method       => $method,
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

Bio::Das::ProServer::SourceAdaptor::all_in_group

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

 Returns all features in groups represented in the range.  First
 fetches all groups represented in the range, then retrieves all
 features in those groups.  Features outside the range are hacked to
 be one bp features on the edge of the range, with a style of hidden.

 All this is so that grouped DAS displays can draw group lines to
 features 'off the edge' off the display

 schema at eof

=head1 SUBROUTINES/METHODS

=head2 capabilities

=head2 build_features

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Bio::Das::ProServer::SourceAdaptor

=item strict

=item warnings

=item base

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: jws, dj3$

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
