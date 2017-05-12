#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::Session - Plugin providing session handling methods
#
#  DESCRIPTION
#  An abstract class that provides common methods for managing session data
#  across servers, within a database, or local file.  Data persistence is
#  maintained between requests using web browser cookies.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::Session;

use strict;
use base 'Apache2::WebApp::Plugin';
use Params::Validate qw( :all );
use Switch;

our $VERSION = 0.16;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# create(\%controller, $name, \%data)
#
# Create a new session.

sub create {
    my $self = shift;
    $self->_init_new($_[0]);
    $self->{OBJECT}->create(@_);
}

#----------------------------------------------------------------------------+
# get(\%controller, $name)
#
# Return session data as a hash reference.

sub get {
    my $self = shift;
    $self->_init_new($_[0]);
    $self->{OBJECT}->get(@_);
}

#----------------------------------------------------------------------------+
# delete(\%controller, $name)
#
# Delete an existing session.

sub delete {
    my $self = shift;
    $self->_init_new($_[0]);
    $self->{OBJECT}->delete(@_);
}

#----------------------------------------------------------------------------+
# update(\%controller, $name, \%data)
#
# Update existing session data.

sub update {
    my $self = shift;
    $self->_init_new($_[0]);
    $self->{OBJECT}->update(@_);
}

#----------------------------------------------------------------------------+
# id(\%controller, $name)
#
# Return the unique identifier for the given session.

sub id {
    my $self = shift;
    $self->_init_new($_[0]);
    $self->{OBJECT}->id(@_);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  PRIVATE METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# _init(\%params)
#
# Return a reference of $self to the caller.

sub _init {
    my ($self, $params) = @_;
    return $self;
}

#----------------------------------------------------------------------------+
# _init_new(\%controller)
#
# Based on config value for 'storage_type', include the correct sub-class.

sub _init_new {
    my ($self, $c)
      = validate_pos(@_,
          { type => OBJECT  },
          { type => HASHREF }
      );

    my $package;

    switch ($c->config->{session_storage_type}) {
        case /file/      { $package = "Apache2::WebApp::Plugin::Session::File"      }
        case /memcached/ { $package = "Apache2::WebApp::Plugin::Session::Memcached" }
        case /mysql/     { $package = "Apache2::WebApp::Plugin::Session::MySQL"     }
        else {
            $self->error("Missing config value for 'storage_type'");
        }
    }

    unless ( $package->can('isa') ) {
        eval "require $package";

        $self->error("Failed to load package '$package': $@") if $@;
    }

    if ( $package->can('new') ) {
        $self->{OBJECT} = $package->new;
    }

    return $self;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Plugin::Session - Plugin providing session handling methods

=head1 SYNOPSIS

  my $obj = $c->plugin('Session')->method( ... );     # Apache2::WebApp::Plugin::Session->method()

    or

  $c->plugin('Session')->method( ... );

=head1 DESCRIPTION

An abstract class that provides common methods for managing session data
across servers, within a database, or local file.  Data persistence is
maintained between requests using web browser cookies.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  Apache2::WebApp::Plugin::Cookie
  Apache::Session
  Params::Validate
  Switch

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-Session-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::Session'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::Session
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 CONFIGURATION

Unless it already exists, add the following to your projects I<webapp.conf>

  [session]
  storage_type = file     # options - file | mysql | memcached
  expires      = 1h       # default 24h

=head1 OBJECT METHODS

=head2 create

Create a new session.

By default, when a new session is created, a browser cookie is set that contains 
a C<session_id>.  Upon success, this session identifier is returned, which can 
also be used to set a customized session cookie.

  my $session_id = $c->plugin('Session')->create($c, 'login',
      {
          username => 'foo',
          password => 'bar',
      }
    );

=head2 get

Takes the cookie unique identifier or session id as arguments.  Returns the 
session data as a hash reference. 

  my $data_ref = $c->plugin('Session')->get($c, 'login');

  print $data_ref->{username};     # outputs 'foo'

=head2 update

Takes the cookie unique identifier or session id as arguments.  Updates 
existing session data.

  $c->plugin('Session')->update($c, 'login',
      {
          last_login => localtime(time),
          remember   => 1,
      }
    );

=head2 delete

Takes the cookie unique identifier or session id as arguments.  Deletes an 
existing session.

  $c->plugin('Session')->delete($c, 'login');

=head2 id

Return the cookie unique identifier for a given session.

  my $session_id = $c->plugin('Session')->id($c, 'login');

=head1 EXAMPLE

  package Example;

  sub _default {
      my ($self, $c) = @_;

      $c->plugin('Session')->create($c, 'login',
          {
              username => 'foo',
              password => 'bar',
          }
        );

      $c->plugin('CGI')->redirect($c, '/app/example/verify');
  }

  sub verify {
      my ($self, $c) = @_;

      my $data_ref = $c->plugin('Session')->get($c, 'login');

      $c->request->content_type('text/html');

      print $data_ref->{username} . '-' . $data_ref->{password};     # outputs 'foo-bar'
  }

  1;

=head1 SUPPORTED TYPES

Apache2::WebApp::Plugin::Session::File
Apache2::WebApp::Plugin::Session::Memcached
Apache2::WebApp::Plugin::Session::MySQL

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Apache2::WebApp::Plugin::Cookie>, 
L<Apache::Session>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
