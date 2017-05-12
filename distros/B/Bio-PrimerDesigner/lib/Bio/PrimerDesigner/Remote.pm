# $Id: Remote.pm,v 1.10 2004/03/04 23:23:38 kclark Exp $

package Bio::PrimerDesigner::Remote;

=head1 NAME

Bio::PrimerDesigner::Remote - A class for remote access to Bio::PrimerDesigner

=head1 SYNOPSIS

  use Bio::PrimerDesigner::Remote;

=head1 DESCRIPTION

Interface to the server-side binaries.  Passes the primer design
paramaters to a remote CGI, which uses a server-side installation of
Bio::PrimerDesigner to process the request.

=head1 METHODS

=cut

use HTTP::Request;
use LWP::UserAgent;
use base 'Class::Base';
use strict;

use vars '$VERSION';
$VERSION = sprintf "%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/;

# -------------------------------------------------------------------
sub CGI_request {

=pod  

=head2 CGI_request                                                           

Passes arguments to the URL of the remote Bio::PrimerDesigner CGI and 
returns the raw output for further processing by local design classes.

=cut

    
    my $self     = shift;
    my $url      = shift or return $self->error('No URL specified');
    $url         = 'http://' . $url unless $url =~ m{https?://};
    my $args     = shift or return $self->error('No config file');
    my $program  = $args->{'program'};
    my $ua       = LWP::UserAgent->new;

    #
    # Is the remote server able to process our request?
    #
    unless ( $self->check( $url, $ua, $program ) ) {
        return $self->error("$url did not return expected result");
    }

    my $request  = HTTP::Request->new('POST', $url);

    #
    # string-ify the config hash to pass to the CGI
    #
    my @content = ();
    @content = map {"$_=" . $args->{$_}} keys %$args;
    my $content = join "#", @content;
    
    $request->content( "config=$content" );
    my $response = $ua->request( $request );
    my $output   = $response->content;
    
    return $self->error("Some sort of HTTP error")
        unless $ua && $request && $response;

    return map { $_ . "\n" } split "\n", $output;
}

# -------------------------------------------------------------------
sub check {

=pod

=head2 check

Tests the URL to make sure the host is live and the CGI returns the
expected results.

=cut

    my $self     = shift;
    my ($url, $ua, $program) = @_;
    
    my $content  = "check=" . $program;
    my $request  = HTTP::Request->new( 'POST', $url );
    $request->content( $content );
    my $response = $ua->request( $request );
    my $output   = $response->content;

    return $self->error("No reponse from host $url")
        unless $response;

    return $self->error("Incorrect response from host $url")
        unless $response->content =~ /$program OK/m;

    return 1;
}

1;

# -------------------------------------------------------------------

=pod

=head1 AUTHOR

Copyright (C) 2003-2008 Sheldon McKay E<lt>mckays@cshl.eduE<gt>,
                   Ken Y. Clark E<lt>kclark@cpan.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA.

=head1 SEE ALSO

Bio::PrimerDesigner, primer_designer.cgi.

=cut
