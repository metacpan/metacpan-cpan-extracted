#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Plugin::DBI - Database interface wrapper
#
#  DESCRIPTION
#
#  A database independent interface that gives your application universal
#  supports across many databases including MySQL, PostGRe, and Oracle.
#  Also supports many common flat file formats.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Plugin::DBI;

use strict;
use base 'Apache2::WebApp::Plugin';
use DBI;
use Params::Validate qw( :all );

our $VERSION = 0.10;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# connect(\%config)
#
# Make a new database connection.

sub connect {
    my ( $self, $config )
      = validate_pos( @_,
          { type => OBJECT  },
          { type => HASHREF }
          );

    my $driver   = $config->{driver};
    my $host     = $config->{host}    || 'localhost';
    my $name     = $config->{name};
    my $user     = $config->{user};
    my $password = $config->{password};
    my $commit   = $config->{commit};

    return if (!$name && !$user && !$password);

    return DBI->connect(
        "dbi:$driver:$name:$host", $user, $password,
          {
              PrintError => 1,
              RaiseError => 1,
              AutoCommit => ($commit) ? 1 : 0,
          }
      )
      or $self->error($DBI::errstr);
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

Apache2::WebApp::Plugin::DBI - Database interface wrapper

=head1 SYNOPSIS

  my $obj = $c->plugin('DBI')->method( ... );     # Apache2::WebApp::Plugin::DBI->method()

    or

  $c->plugin('DBI')->method( ... );

=head1 DESCRIPTION

A database independent interface that gives your application universal support 
across many databases including MySQL, PostGRe, and Oracle.  Also supports many
common flat file formats.

=head1 PREREQUISITES

This package is part of a larger distribution and was NOT intended to be used 
directly.  In order for this plugin to work properly, the following packages
must be installed:

  Apache2::WebApp
  Apache::DBI
  DBI
  Params::Validate

=head1 INSTALLATION

From source:

  $ tar xfz Apache2-WebApp-Plugin-DBI-0.X.X.tar.gz
  $ perl MakeFile.PL PREFIX=~/path/to/custom/dir LIB=~/path/to/custom/lib
  $ make
  $ make test
  $ make install

Perl one liner using CPAN.pm:

  $ perl -MCPAN -e 'install Apache2::WebApp::Plugin::DBI'

Use of CPAN.pm in interactive mode:

  $ perl -MCPAN -e shell
  cpan> install Apache2::WebApp::Plugin::DBI
  cpan> quit

Just like the manual installation of Perl modules, the user may need root access during
this process to insure write permission is allowed within the installation directory.

=head1 CONFIGURATION

Unless it already exists, add the following to your projects I<webapp.conf>

  [database]
  driver      = mysql
  host        = localhost
  name        = database
  user        = foo
  password    = bar
  auto_commit = 0

=head1 OBJECT METHODS

=head2 connect

Make a new database connection.

  my $dbh = $c->plugin('DBH')->connect({
      driver    => 'mysql',
      host      => 'localhost',
      name      => 'database',
      user      => 'bar',
      password  => 'baz',
      commit    => 1 || 0,
    });

  my $sth = $dbh->prepare("SELECT * FR..");

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Plugin>, L<Apache::DBI>, L<DBI>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> - L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
