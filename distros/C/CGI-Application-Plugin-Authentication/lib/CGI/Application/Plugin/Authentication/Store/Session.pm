package CGI::Application::Plugin::Authentication::Store::Session;
$CGI::Application::Plugin::Authentication::Store::Session::VERSION = '0.24';
use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authentication::Store);

=head1 NAME

CGI::Application::Plugin::Authentication::Store::Session - Session based Store

=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Session;
 use CGI::Application::Plugin::Authentication;

  __PACKAGE__->authen->config(
        STORE => 'Session',
  );

=head1 DESCRIPTION

This module uses a session to store authentication information across multiple requests.
It depends on the L<CGI::Application::Plugin::Session> plugin being present.  Actually,
it only requires that there be a 'session' method in the CGI::Application module that
will return a valid CGI::Session object.

=head1 METHODS

=head2 fetch

This method accepts a list of parameters and fetches them from the session.

=cut

sub fetch {
    my $self = shift;
    my @params = @_;
    my @items;
    foreach my $param (@params) {
        my $key = &_names_to_keys($param);
        push @items, $self->_session->param($key);
    }

    return @items[0..$#items];
}

=head2 save

This method accepts a hash of parameters and values and saves them into the session.

=cut

sub save {
    my $self = shift;
    my %items = @_;
    my $session = $self->_session;
    while (my ($param, $value) = each %items) {
        my $key = _names_to_keys($param);
        $session->param( $key => $value );
    }
    return 1;
}

=head2 delete

This method accepts a list of parameters and deletes them from the session.

=cut

sub delete {
    my $self = shift;
    my @items = &_names_to_keys(@_);
    $self->_session->clear(\@items);
}

#
# Return the session object
#
sub _session {
    return $_[0]->authen->_cgiapp->session;
}

#
# We want all parameters in the session to have a common prefix
#
sub _names_to_keys {
    my @names = @_;
    my @keys = map { 'AUTH_'.uc($_) } @names;
    return @keys[0..$#keys];
}

=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Store>, L<CGI::Application::Plugin::Authentication>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
