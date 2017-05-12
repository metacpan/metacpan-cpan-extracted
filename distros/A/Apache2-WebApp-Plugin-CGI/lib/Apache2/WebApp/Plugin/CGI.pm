#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::CGI - Plugin providing common CGI methods
#
#  DESCRIPTION
#  Common methods for dealing with HTTP requests.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::CGI;

use strict;
use warnings;
use base 'Apache2::WebApp::Plugin';
use Params::Validate qw( :all );

our $VERSION = 0.10;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# params(\%controller)
#
# Get the request paramters; return name/value parameters as a hash.

sub params {
    my ( $self, $c )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF }
          );

    return
      ( map { $_ => $c->request->param($_) || "" } $c->request->param() );
}

#----------------------------------------------------------------------------+
# redirect( \%controller, $target )
#
# Redirect an HTTP request to a target URI/URL.

sub redirect {
    my ( $self, $c, $target )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF },
          { type => SCALAR  },
          );

    my $status = $c->request->protocol eq "HTTP/1.1" ? 303 : 302;

    $c->request->status($status);
    $c->request->headers_out->set( 'Location' => $target );
    $c->request->headers_out();
    exit;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%params)
#
# Return a reference of $self to the caller.

sub _init {
    my ( $self, $params ) = @_;
    return $self;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin::CGI - Plugin providing common CGI methods

=head1 SYNOPSIS

  my $obj = $c->plugin('CGI')->method( ... );     # Apache2::WebApp::Plugin::CGI->method()

    or

  $c->plugin('CGI')->method( ... );

=head1 DESCRIPTION

Common methods for dealing with HTTP requests.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-CGI-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::CGI'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::CGI
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 OBJECT METHODS

=head2 params

Get the request paramters; return name/value parameters as a hash.

  my %param = $c->plugin('CGI')->params(\%controller);

=head2 redirect

Redirect an HTTP request to a target URI or URL.

  $c->plugin('CGI')->redirect( \%controller, $target );

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Apache2::Request>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
