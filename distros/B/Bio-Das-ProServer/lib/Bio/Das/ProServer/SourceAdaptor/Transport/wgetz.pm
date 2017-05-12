#########
# Author:        ak
# Maintainer:    $Author: zerojinx $
# Created:       2004
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: wgetz.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/wgetz.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::wgetz;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);
use LWP::UserAgent;
use Carp;
use Readonly;

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };
Readonly::Scalar our $TIMEOUT => 30;

sub _useragent {
  # Caching an LWP::UserAgent instance within the current
  # object.

  my $self = shift;

  if (!defined $self->{_useragent}) {
    $self->{_useragent} = LWP::UserAgent->new(
					      env_proxy  => 1,
					      keep_alive => 1,
					      timeout    => $TIMEOUT,
					     );
  }

  return $self->{_useragent};
}

sub init {
  my $self = shift;
  return $self->_useragent();
}

sub query {
  my ($self, @args) = @_;
  my $swgetz = $self->config->{wgetz} || 'http://srs.ebi.ac.uk/srsbin/cgi-bin/wgetz';
  my $query  = my $squery = join q(+), @args;

  #########
  # Remove characters not allowed in transport.
  #
  $swgetz =~ s/[^\w.\/:-]//mxs;

  #########
  # Remove characters not allowed in query.
  #
  $squery =~ s/[^\w[\](){}.><:'"\ |+-]//mxs;

  if ($squery ne $query) {
    carp "Detainted '$squery' != '$query'";
  }

  my $reply = $self->_useragent()->get("$swgetz?$squery+-ascii");

  if (!$reply->is_success()) {
    carp "wgetz request failed: $swgetz?$squery+-ascii\n";
  }

  return $reply->content();
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::wgetz - A ProServer transport module for wgetz (SRS web access)

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 _useragent

=head2 init

=head2 query

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Bio::Das::ProServer::SourceAdaptor::Transport::generic

=item LWP::UserAgent

=item Carp

=item Readonly

=item strict

=item warnings

=item base

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Andreas Kahari, <andreas.kahari@ebi.ac.uk>

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
