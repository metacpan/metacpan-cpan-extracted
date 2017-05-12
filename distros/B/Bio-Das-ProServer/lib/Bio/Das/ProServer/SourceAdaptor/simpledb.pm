#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-12-12
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# $Id: simpledb.pm 687 2010-11-02 11:37:11Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/simpledb.pm $
#
package Bio::Das::ProServer::SourceAdaptor::simpledb;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub capabilities {
  return {
    features => '1.0',
  };
}

sub build_features {
  my ($self, $opts) = @_;
  my $segment       = $opts->{segment};
  my $start         = $opts->{start};
  my $end           = $opts->{end};
  my $dsn           = $self->{dsn};
  my $dbtable       = $self->config->{dbtable} || $dsn;

  #########
  # if this is a hydra-based source the table name contains the hydra name and needs to be switched out
  #
  my $hydraname     = $self->config->{hydraname};

  if($hydraname) {
    my $basename = $self->config->{basename} || q();
    $dbtable     =~ s/$hydraname/$basename/mxs;
  }

  my @bound      = ($segment);
  my $query      = qq(SELECT segmentid,featureid,start,end,type,note,link FROM $dbtable WHERE segmentid = ?);

  if($start && $end) {
    $query .= q(AND start <= ? AND end >= ?);
    push @bound, ($end, $start);
  }

  my $ref      = $self->transport->query($query, @bound);
  my @features;

  for my $row (@{$ref}) {
    my ($f_start, $f_end) = ($row->{start}, $row->{end});
    if($f_start > $f_end) {
      ($f_start, $f_end) = ($f_end, $f_start);
    }
    push @features, {
                     id     => $row->{featureid},
                     type   => $row->{type} || $dbtable,
                     method => $row->{type} || $dbtable,
                     start  => $f_start,
                     end    => $f_end,
                     note   => $row->{note},
                     link   => $row->{link},
                    };
  }
  return @features;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::simpledb - Builds simple DAS features from a database

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

  Build simple segment:start:stop features from a basic database table structure:

  segmentid,featureid,start,end,type,note,link

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 capabilities

=head2 build_features - Return an array of features based on a query given in the config file

  my @aFeatures = $oSourceAdaptor->build_features({
                                                   segment => $sSegmentId,
                                                   start   => $iSegmentStart, # Optional
                                                   end     => $iSegmentEnd,   # Optional
                                                   dsn     => $sDSN,          # if used as part of a hydra
                                                  });
=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

  [mysource]
  adaptor   = simpledb
  transport = dbi
  dbhost    = mysql.example.com
  dbport    = 3308
  dbname    = proserver
  dbuser    = proserverro
  dbpass    = topsecret
  dbtable   = mytable

  Or for SourceHydra use:
  [mysimplehydra]
  adaptor   = simpledb           # SourceAdaptor to clone
  hydra     = dbi                # Hydra implementation to use
  transport = dbi
  basename  = hydra              # dbi: basename for db tables containing servable data
  dbname    = proserver
  dbhost    = mysql.example.com
  dbuser    = proserverro
  dbpass    = topscret

=head1 DEPENDENCIES

 Bio::Das::ProServer::SourceAdaptor

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger M Pettett$

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
