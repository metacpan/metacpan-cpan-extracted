#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-10-28
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# $Id: simple.pm 687 2010-11-02 11:37:11Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/simple.pm $
#
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
#
package Bio::Das::ProServer::SourceAdaptor::simple;

use strict;
use warnings;

use Carp;
use POSIX;

use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub capabilities {
  my $ref = {
             'features'      => '1.1',
             'types'         => '1.1',
             'feature-by-id' => '1.0',
             'stylesheet'    => '1.1',
            };
  return $ref;
}

sub build_features {
  my ($self, $opts) = @_;

  my $baseurl = $self->config->{'baseurl'};

  my @rows;
  my @features;

  if ($opts->{'feature_id'}) {
    my $tmp = $self->transport->query(sprintf 'field5 lceq "%s"', $opts->{'feature_id'});
    $tmp->[0] || return ();
    $opts->{'segment'} = $tmp->[0]->[0];
    $opts->{'start'} = $tmp->[0]->[1];
    $opts->{'end'} = $tmp->[0]->[2];
  }

  if ($opts->{'segment'}) {
    $opts->{'start'} ||= 1;
    $opts->{'end'}   ||= INT_MAX;
    @rows = @{ $self->transport->query(sprintf 'field0 lceq "%s" AND field2 >= "%d" AND field1 <= "%d"', $opts->{'segment'}, $opts->{'start'}, $opts->{'end'}) };
  } else {
    @rows = @{ $self->transport->query('field0 like .*') };
  }

  # segment	start	end	type	note	id	parents	parts
  # Y	01	89	transcript	This is transcript 3	TRANS003		EXON005,EXON006,EXON007
  my %features_seen;
  while (scalar @rows) {

    my @related;

    while (my $row = shift @rows) {
      my $id = $row->[5] || q();
      my @parentstmp = split /,/mxs, ($row->[6]||q());
      my @partstmp   = split /,/mxs, ($row->[7]||q());
      push @related, @parentstmp;
      push @related, @partstmp;
      push @features, {
        'type'    => $row->[3],
        'method'  => $row->[3],
        'segment' => $row->[0],
        'id'      => $id,
        'start'   => $row->[1],
        'end'     => $row->[2],
        'parent'  => \@parentstmp,
        'part'    => \@partstmp,
        'note'    => $row->[4],
        'link'    => $baseurl.$row->[5],
      };
      $features_seen{$id} = 1;
    }

    # Fill in any parents or parts features not already included:
    for my $id (@related) {
      if (!$features_seen{$id}) {
        $self->{debug} && print {*STDERR} "Adding in parent/part outside of range: $id\n";
        push @rows, @{ $self->transport->query(sprintf 'field5 = "%s"', $id) };
      }
    }

  }

  return @features;
}

sub das_stylesheet {
  return q(<?xml version="1.0" standalone="yes"?>
<!DOCTYPE DASSTYLE SYSTEM "http://www.biodas.org/dtd/dasstyle.dtd">
<DASSTYLE>
  <STYLESHEET version="1.0">
    <CATEGORY id="default">
      <TYPE id="default">
        <GLYPH>
          <BOX>
            <FGCOLOR>red</FGCOLOR>
            <BGCOLOR>black</BGCOLOR>
          </BOX>
        </GLYPH>
      </TYPE>
      <TYPE id="transcript">
        <GLYPH>
          <LINE>
            <FGCOLOR>red</FGCOLOR>
            <STYLE>hat</STYLE>
          </LINE>
        </GLYPH>
      </TYPE>
    </CATEGORY>
  </STYLESHEET>
</DASSTYLE>);
}

sub known_segments {
  my $self = shift;

  my $rows = $self->transport->query('field0 like .*');
  my %segs;
  map { $segs{$_->[0]} = 1 } @{ $rows || [] };

  return keys %segs;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::simple

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

Builds das from parser genesat tab-delimited flat files of the form:

 gene.name	gene.id

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 init - Initialise capabilities for this source

  $oSourceAdaptor->init();

=head2 build_features - Return an array of features based on a query given in the config file

  my @aFeatures = $oSourceAdaptor->build_features({
                                                   'segment'    => $sSegmentId,
                                                   'start'      => $iSegmentStart, # Optional
                                                   'end'        => $iSegmentEnd,   # Optional
                                                  });
  my @aFeatures = $oSourceAdaptor->build_features({
                                                   'feature_id' => $sFeatureId,
                                                  });

=head2 das_stylesheet - Return a DAS XML stylesheet

  Overrides the superclass method to return a hardcoded XML DAS stylesheet.

=head2 known_segments - Return a list of known entry point segment IDs

  Returns a list of all segment identifiers in the file.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

 Bio::Das::ProServer::SourceAdaptor
 Carp
 POSIX

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

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
