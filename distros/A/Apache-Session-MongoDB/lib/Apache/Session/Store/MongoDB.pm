package Apache::Session::Store::MongoDB;

use 5.010;
use strict;

our $VERSION = '0.21';

use MongoDB;

our $default = {
    host       => 'localhost:27017',
    db_name    => 'sessions',
    collection => 'sessions',
};

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub connection {
    my ( $self, $session ) = splice @_;
    return
      if ( defined $self->{collection} );
    my $conn_args;
    foreach my $w (
        qw(host auth_mechanism auth_mechanism_properties bson_codec
        connect_timeout_ms db_name heartbeat_frequency_ms j local_threshold_ms
        max_time_ms password port read_pref_mode read_pref_tag_sets
        replica_set_name server_selection_timeout_ms server_selection_try_once
        socket_check_interval_ms socket_timeout_ms ssl username w wtimeout
        read_concern_level)
      )
    {
        $conn_args->{$w} = $session->{args}->{$w} || $default->{$w};
        delete $conn_args->{$w} unless ( defined $conn_args->{$w} );
    }
    my $s =
      MongoDB->connect( $session->{args}->{host} || $default->{host},
        $conn_args )
      or die('Unable to connect to MongoDB server');
    $self->{collection} =
      $s->get_database( $session->{args}->{db_name} || $default->{db_name} )
      ->get_collection( $session->{args}->{collection}
          || $default->{collection} );
}

sub insert {
    my ( $self, $session ) = splice @_;
    $self->connection($session);
    die('no id') unless ( $session->{data}->{_session_id} );
    $session->{data}->{_id} = $session->{data}->{_session_id};
    $self->{collection}->insert_one( $session->{data} );
}

sub update {
    my ( $self, $session ) = splice @_;
    $self->remove($session);
    $self->insert($session);
}

sub materialize {
    my ( $self, $session ) = splice @_;
    $self->connection($session);
    $session->{data} = $self->{collection}
      ->find_one( { _id => $session->{data}->{_session_id} } );
    if ( $session->{data}->{_session_id} ) {
        $session->{data}->{_session_id} = $session->{data}->{_id};
    }
    else {
        die "Object does not exist in data store";
    }
}

sub remove {
    my ( $self, $session ) = splice @_;
    $self->connection($session);
    $self->{collection}->delete_one( { _id => $session->{data}->{_session_id} } );
}

sub DESTROY {
    my $self = shift;
    $self->{collection} = undef;
}

1;
__END__

=head1 NAME

Apache::Session::MongoDB - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::MondoDB;
 
 # Using localhost server
 tie %hash, 'Apache::Session::MongoDB', $id, {};
  
 # Example with default values
 tie %hash, 'Apache::Session::MongoDB', $id, {
    host       => 'locahost:27017',
    db_name    => 'sessions',
    collection => 'sessions',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses the MongoDB
backing store and no locking.

=head1 SEE ALSO

L<Apache::Session::MongoDB>, L<Apache::Session>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
