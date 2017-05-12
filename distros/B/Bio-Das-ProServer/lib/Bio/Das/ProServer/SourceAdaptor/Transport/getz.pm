#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-06-13
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# $Id: getz.pm 687 2010-11-02 11:37:11Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/getz.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::getz;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);
use Carp;
use English qw(-no_match_vars);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub query {
  my ($self, @args) = @_;
  my ($sgetz)  = ($self->config->{getz} || '/usr/local/bin/getz') =~ /([a-z\d\-\_\.\/]+)/mxsi;
  my $query    = join q( ), @args;
  my ($squery) = $query =~ /([a-z\d\[\]\(\)\{\}\.\-_\>\<\:\'\" \|]+)/mxsi;

  if($squery ne $query) {
    carp qq(Detainted '$squery' != '$query');
  }

  local $RS = undef;
  open my $fh, q(-|), "$sgetz $squery" or croak $ERRNO;
  my $data = <$fh>;
  close $fh or croak $ERRNO;
  return $data;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::getz - Pulls features over command-line SRS/getz transport

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 query - Run a query against getz

  my $sGetzData = $getzTransport->query('-e', '[....]');

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Bio::Das::ProServer::SourceAdaptor::Transport::generic
Carp

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
