package Auth::Kokolores::Plugin::SqlConnection;

use Moose;
use DBI;

# ABSTRACT: kokolores plugin to configure a SQL connection
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';

use Auth::Kokolores::ConnectionPool;


has 'handle' => ( is => 'rw', isa => 'Str', default => 'sql' );

has 'user' => ( is => 'ro', isa => 'Str', default => '' );
has 'password' => ( is => 'ro', isa => 'Str', default => '' );

has 'dsn' => (
  is => 'ro', isa => 'Str',
  default => 'dbi:SQLite:dbname=/var/lib/saslauthd/saslauth.sqlite',
);

has 'dbh' => (
  is => 'ro', isa => 'DBI::db',
  lazy => 1,
  default => sub {
    my $self = shift;
    $self->log(3, 'connecting to '.$self->dsn.'...');
    my $dbh = DBI->connect(
      $self->dsn, $self->user, $self->password,
      { RaiseError => 1 },
    );
    return $dbh;
  },
);

sub child_init {
  my ( $self, $r ) = @_;
  
  $self->log(3, 'registring sql connection \''.$self->handle.'\'...');
  Auth::Kokolores::ConnectionPool->add_handle(
    $self->handle => $self->dbh,
  );

  return;
}

sub shutdown {
  my ( $self, $r ) = @_;
  
  $self->log(3, 'unregistring sql connection \''.$self->handle.'\'...');
  Auth::Kokolores::ConnectionPool->clear_handle( $self->handle );

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::SqlConnection - kokolores plugin to configure a SQL connection

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This plugin creates a connection to an SQL database for use
by further SQL plugins.

=head1 EXAMPLE

  <Plugin database>
    module = "SqlConnection"
    dsn = "dbi:SQLite:dbname=/var/lib/kokolores/users.sqlite"
    # handle = "sql"
  </Plugin>

=head1 MODULE PARAMETERS

=head2 user (default: '')

User used to connect to SQL database.

=head2 password (default: '')

Password used to connect to SQL database.

=head2 dsn (default: 'dbi:SQLite:dbname=/var/lib/saslauthd/saslauth.sqlite')

A connection string for the database in perl-DBI format.

=head2 handle (default: 'sql')

This string is used to register the database connection
within the kokolores connection pool.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
