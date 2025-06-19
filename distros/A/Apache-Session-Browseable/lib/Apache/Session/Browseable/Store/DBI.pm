package Apache::Session::Browseable::Store::DBI;

use strict;
use Apache::Session::Store::DBI;
our @ISA     = qw(Apache::Session::Store::DBI);
our $VERSION = 1.3.11;

sub insert {
    my ( $self, $session ) = @_;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    $self->{insert_sth} //=
      $self->{dbh}->prepare_cached( "INSERT INTO $self->{table_name} ("
          . join( ',', 'id', 'a_session', map { s/'/''/g; $_ } @$index )
          . ') VALUES ('
          . join( ',', ('?') x ( 2 + @$index ) )
          . ')' );

    $self->{insert_sth}->bind_param( 1, $session->{data}->{_session_id} );
    $self->{insert_sth}->bind_param( 2, $session->{serialized} );
    my $i = 3;
    foreach my $f (@$index) {
        $self->{insert_sth}->bind_param( $i, $session->{data}->{$f} );
        $i++;
    }

    $self->{insert_sth}->execute;

    $self->{insert_sth}->finish;
}

sub update {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    if ( !defined $self->{update_sth} ) {
        $self->{update_sth} =
          $self->{dbh}->prepare_cached( "UPDATE $self->{table_name} SET "
              . join( ' = ?, ', 'a_session', @$index )
              . ' = ? WHERE id = ?' );
    }

    $self->{update_sth}->bind_param( 1, $session->{serialized} );
    my $i = 2;
    foreach my $f (@$index) {
        $self->{update_sth}->bind_param( $i, $session->{data}->{$f} );
        $i++;
    }
    $self->{update_sth}->bind_param( $i, $session->{data}->{_session_id} );

    $self->{update_sth}->execute;

    $self->{update_sth}->finish;
}

1;
