#!perl -w

package App::CamelPKI::Model::WebServer;

use strict;
use warnings;

=head1 NAME

B<App::CamelPKI::Model::WebServer> - The singleton which represents the Camel-PKI
AC Web server.

=head1 SYNOPSIS

  my $apache = $c->model("WebServer")->apache;

=head1 DESCRIPTION

The I<App::CamelPKI::Model::WebServer> is a singleton owned by Catalyst
which host a singleton of L<App::CamelPKI::SysV::Apache>, reprenting the
Web server in which the application is running.

=head1 CAPABILITY DISCIPLINE

An I<App::CamelPKI::Model::WebServer> object represents exactly the same
privileges than the L<App::CamelPKI::SysV::Apache> object which is
encapsulated in it.

=cut

use base 'Catalyst::Model';
use App::CamelPKI::SysV::Apache;

=head1 CONFIGURATION

The following variables are configured in 
I<App::CamelPKI::Model::WebServer>:

=over

=item I<home_dir>

The directory where the server private key and certificate are written.

=back

=cut


=head1 METHODS

=head2 apache

Returns the L<App::CamelPKI::WebServer> instance which represents the 
application Apache server.

=cut

sub apache {
    my ($self) = @_;
    return App::CamelPKI::SysV::Apache->load($self->{home_dir});
}

1;
