package CGI::Application::Plugin::Authentication::Driver::Authen::Simple;
$CGI::Application::Plugin::Authentication::Driver::Authen::Simple::VERSION = '0.22';
use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authentication::Driver);

use Carp;
use UNIVERSAL::require;

=head1 NAME

CGI::Application::Plugin::Authentication::Driver::Authen::Simple - Authen::Simple Authentication driver

=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authentication;

  __PACKAGE__->authen->config(
        DRIVER => [ 'Authen::Simple::Kerberos', realm => 'REALM.COMPANY.COM' ],
  );

=head1 DESCRIPTION

This driver allows you to use any modules that following the Authen::Simple
API.  All options that you provide will be passed on to the given Authen::Simple
module.

=head1 EXAMPLE

  __PACKAGE__->authen->config(
        DRIVER => [ 'Authen::Simple::CDBI', class => 'MyApp::Model::User' ],
  );


=head1 METHODS

=head2 verify_credentials

This method will test the provided credentials against the Authen::Simple module
that was configured.

=cut

sub verify_credentials {
    my $self    = shift;
    my @creds   = @_;
    my @options = $self->options;
    my $authen_class = shift @options;

    return undef unless defined $creds[0] && defined $creds[1];

    $authen_class->require || Carp::croak("The $authen_class module is not installed");

    my $authen_obj = $authen_class->new(@options);
    croak("Failed to create $authen_class instance") if !defined $authen_obj;

    return $authen_obj->authenticate(@creds) ? $creds[0] : undef;
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, L<CGI::Application::Plugin::Authentication>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
