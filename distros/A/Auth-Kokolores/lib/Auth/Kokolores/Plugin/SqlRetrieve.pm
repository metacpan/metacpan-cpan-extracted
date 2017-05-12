package Auth::Kokolores::Plugin::SqlRetrieve;

use Moose;
use DBI;

# ABSTRACT: kokolores plugin for retrieving users from SQL databases
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';

use Auth::Kokolores::ConnectionPool;


has 'handle' => ( is => 'rw', isa => 'Str', default => 'sql' );

has 'select' => (
  is => 'ro', isa => 'Str',
  default => 'SELECT username, method, salt, cost, hash FROM users WHERE username = ?',
);

has 'sth' => (
  is => 'ro', isa => 'DBI::st', lazy => 1,
  default => sub {
    my $self = shift;
    my $dbh = Auth::Kokolores::ConnectionPool->get_handle(
      $self->handle,
    );
    if( ! defined $dbh || ref($dbh) ne 'DBI::db' ) {
      die('There is no SQL connection configured with name \''.$self->handle.'\'!');
    }
    $self->log(4, 'preparing statement '.$self->select.'...');
    return $dbh->prepare($self->select);
  },
);

sub authenticate {
  my ( $self, $r ) = @_;
  my $sth = $self->sth;
  
  $sth->execute( $r->username );
  my $fields = $sth->fetchrow_hashref;
  $sth->finish;

  if( ! defined $fields ) {
    $r->log(3, 'could not find user '.$r->username);
    return 0;
  }

  foreach my $field ( keys %$fields ) {
    if( ! defined $fields->{$field} ) {
      next;
    }
    $r->log(4, 'retrieved userinfo '.$field.'='.$fields->{$field});
    $r->set_info( $field, $fields->{$field} );
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::SqlRetrieve - kokolores plugin for retrieving users from SQL databases

=head1 VERSION

version 1.01

=head1 DESCRIPTION

Retrieve a user from a SQL database.

Will fail if no user is found.

If a user is found all fields of the record will be stored in the
current requests userinfo field.

=head1 EXAMPLE

  <Plugin retrieve-user>
    module = "SqlRetrieve"
    select = "SELECT * FROM passwd WHERE username = ?"
    # handle = 'sql'
  </Plugin>

=head1 MODULE PARAMETERS

=head2 select (default: SELECT username, method, salt, cost, hash FROM users WHERE username = ?)

Define a SQL SELECT query to retrieve the user from the SQL database.

=head2 handle (default: 'sql')

Name of the SQL connection to retrieve from the connection pool.

You must configure a SQL connection with the SqlConnection plugin.
It'll register a connection within the connection pool. The default
name will be 'sql'.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
