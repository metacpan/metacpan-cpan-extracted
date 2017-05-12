#########
# Author:        Andreas Kahari, andreas.kahari@ebi.ac.uk
# Maintainer:    $Author: zerojinx $
# Created:       ?
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: bioseq.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceAdaptor/bioseq.pm,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/bioseq.pm $
#
package Bio::Das::ProServer::SourceAdaptor::bioseq;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub capabilities {
  my $ref = {
	     features => '1.0',
	     dna      => '1.0'
	    };
  return $ref;
}

sub length { ## no critic
  my ($self, $id) = @_;
  my $seq = $self->transport->query($id);

  if (defined $seq) {
    return $seq->length();
  }
  return 0;
}

sub build_features {
  my ($self,$opts) = @_;
  my $seq = $self->transport->query($opts->{segment});

  if (!defined $seq) {
    return ();
  }

  my @features;
  for my $feature ($seq->get_SeqFeatures()) {
    push @features, {
		     type   => $feature->primary_tag(),
		     start  => $feature->start(),
	             end    => $feature->end(),
                     method => $feature->source_tag(),
                     id     => $feature->display_name() ||
                               sprintf q(%s/%s:%d,%d),
                                       $seq->display_name(), $feature->primary_tag(),
                                       $feature->start(), $feature->end(),
                     ori    => $feature->strand(),
		    };
  }

  return @features;
}

sub sequence {
  my ($self, $opts) = @_;
  my $seq = $self->transport->query($opts->{segment});

  if (!defined $seq) {
    return { seq => q(), moltype => q() };
  }

  return {
	  seq     => $seq->seq()      || q(),
	  moltype => $seq->alphabet() || q(),
	 };
}

1;

__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::bioseq

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

Bio::Das::ProServer::SourceAdaptor::bioseq - A ProServer source
adaptor for converting Bio::Seq objects into DAS features.  See also
"Transport/bioseqio.pm".

=head1 SUBROUTINES/METHODS

=head2 capabilities

=head2 length

=head2 build_features

=head2 sequence

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

 Bio::Das::ProServer::SourceAdaptor

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Andreas Kahari, andreas.kahari@ebi.ac.uk

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
