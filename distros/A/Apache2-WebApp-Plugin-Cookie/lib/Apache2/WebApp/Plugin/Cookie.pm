#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::Cookie - Plugin providing HTTP cookie methods
#
#  DESCRIPTION
#  Common methods creating for manipulating web browser cookies.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::Cookie;

use strict;
use warnings;
use base 'Apache2::WebApp::Plugin';
use Apache2::Cookie;
use Params::Validate qw( :all );

our $VERSION = 0.10;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# set( \%controller, \%vars )
#
# Set a new browser cookie.

sub set {
    my ( $self, $c, $vars )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF },
          { type => HASHREF }
          );

    my $default = "Mon, 16-Mar-2020 00:00:00 GMT";
    my $expire  = $vars->{expire} ? $vars->{expire} : $default;
    my $secure  = $vars->{secure} ? $vars->{secure} : 0;
    my $domain  = $vars->{domain};

    unless ($domain) {
        $domain = $c->plugin('Filters')->strip_domain_alias( $c->config->{apache_domain} );
        $domain = ".$domain";     # set global across all domain aliases
    }

    my $cookie = Apache2::Cookie->new(
        $c->request,
        -name    => $vars->{name},
        -value   => $vars->{value},
        -expires => $expire,
        -path    => '/',
        -domain  => $domain,
        -secure  => $secure
      );

    $cookie->bake($c->request);

    return;
}

#----------------------------------------------------------------------------+
# get($name)
#
# Return the browser cookie value.

sub get {
    my ( $self, $name )
      = validate_pos( @_,
          { type => OBJECT },
          { type => SCALAR }
          );

    my %cookie = Apache2::Cookie->fetch;

    return unless $cookie{$name};
    return $cookie{$name}->value;
}

#----------------------------------------------------------------------------+
# delete( \%controller, $name )
#
# Delete a browser cookie by name.

sub delete {
    my ( $self, $c, $name )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF },
          { type => SCALAR  }
          );

    my $domain = $c->plugin('Filters')->strip_domain_alias( $c->config->{apache_domain} );

    my $cookie = Apache2::Cookie->new(
        $c->request,
        -name    => $name,
        -value   => '',
        -expires => '-24h',
        -path    => '/',
        -domain  => ".$domain"
      );

    $cookie->bake($c->request);

    return;
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

Apache2::WebApp::Plugin::Cookie - Plugin providing HTTP cookie methods

=head1 SYNOPSIS

  my $obj = $c->plugin('Cookie')->method( ... );     # Apache2::WebApp::Plugin::Cookie->method()

    or

  $c->plugin('Cookie')->method( ... );

=head1 DESCRIPTION

Common methods for creating and manipulating web browser cookies.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  Apache2::WebApp::Plugin::Filters
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-Cookie-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::Cookie'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::Cookie
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 CONFIGURATION

In order to set a browser cookie, you need to specify a valid hostname in your I<webapp.conf>

  [apache]
  domain = www.domain.com

=head1 OBJECT METHODS

=head2 set

Set a new browser cookie.

  $c->plugin('Cookie')->set( $c, {
        name    => 'foo',
        value   => 'bar',
        expires => '24h',
        domain  => 'www.domain.com',    # optional
        secure  => 0,
    });

=head2 get

Return the browser cookie value.

  my $result = $c->plugin('Cookie')->get($name);

  # bar is value of $result

=head2 delete

Delete a browser cookie by name.

  $c->plugin('Cookie')->delete( \%controller, $name );

=head1 EXAMPLE

  package Example;

  use strict;
  use warnings;

  sub _default {
      my ( $self, $c ) = @_;

      $c->plugin('Cookie')->set( $c, {
          name    => 'foo',
          value   => 'bar',
          expires => '1h',
          secure  => 0,
        });

      $c->plugin('CGI')->redirect( $c, '/app/example/verify' );
  }

  sub verify {
      my ( $self, $c ) = @_;

      $c->request->content_type('text/html');

      print $c->plugin('Cookie')->get('foo');
  }

  1;

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Apache2::Cookie>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
