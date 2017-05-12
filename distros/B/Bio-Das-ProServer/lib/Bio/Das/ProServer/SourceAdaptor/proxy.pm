#########
# Author:        dj3
# Maintainer:    $Author: zerojinx $
# Created:       2005-10-21
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: proxy.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceAdaptor/proxy.pm,v $
#
package Bio::Das::ProServer::SourceAdaptor::proxy;
use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;
use Bio::Das::Lite;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub capabilities {
  return {
	  features   => '1.0',
	  stylesheet => '1.0',
	 };
}

sub das_stylesheet {
  my $self = shift;
  return LWP::UserAgent->new->request(HTTP::Request->new('GET', $self->config->{sourcedsn}.'/stylesheet'))->content;
}

sub build_features {
  my ($self, $opts) = @_;
  my $seg   = $opts->{segment};
  my $start = $opts->{start};
  my $end   = $opts->{end};
  my $das   = Bio::Das::Lite->new($self->config->{sourcedsn});
  my @results;
  $das->features((exists $opts->{start})?"$seg:$start,$end":$seg,
                 sub {
                   my $fr = shift;
                   if($fr->{feature_id}) {
		     push @results, $fr;
		   }
                 });
  return @results;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::proxy

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

Passes through all requests to another das server.
Intended to be inherited from by proxies which do more interesting things

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 capabilities

=head2 das_stylesheet

=head2 build_features

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

HTTP::Request
LWP::UserAgent
Bio::Das::Lite
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
