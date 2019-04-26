package Apache::Session::MongoDB;

use 5.010;
use strict;
use AutoLoader 'AUTOLOAD';

our $VERSION = '0.19';
our @ISA     = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::MongoDB;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::MongoDB;

sub populate {
    my $self = shift;

    $self->{object_store} = Apache::Session::Store::MongoDB->new($self);
    $self->{lock_manager} = Apache::Session::Lock::Null->new($self);
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::MongoDB::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::MongoDB::unserialize;

    return $self;
}

our $default;

*default = \$Apache::Session::Store::MongoDB::default;

1;

__END__
sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    return $class->_query( $args, { $selectField => $value }, @fields );
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    $value =~ s/([\/\\\^\$\.\?\+\[\]\{\}\(\)])/\\$1/g;
    $value =~ s/\*/\.\*/g;
    return $class->_query( $args, { $selectField => qr/$value/i } );
}

sub _query {
    my ( $class, $args, $filter, @fields ) = @_;
    my $col    = $class->_col($args);
    my $cursor = $col->find($filter);
    my $res;
    while ( my $r = $cursor->next ) {
        my $id = $r->{_session_id};
        delete $r->{_id};
        if (@fields) {
            $res->{$id}->{$_} = $r->{$_} foreach (@fields);
        }
        else {
            $res->{$id} = $r;
        }
    }
    return $res;
}

sub get_key_from_all_sessions {
    my ( $class, $args, $data ) = @_;
    my $col = $class->_col($args);
    my $cursor = $col->find( {} );
    my $res;
    while ( my $r = $cursor->next ) {
        my $id = $r->{_session_id};
        delete $r->{_id};
        if ( ref($data) eq 'CODE' ) {
            $res->{$id} = $data->( $r, $id );
        }
        elsif ($data) {
            $data = [$data] unless ( ref $data );
            $res->{$id}->{$_} = $r->{$_} foreach (@$data);
        }
        else {
            $res->{$id} = $r;
        }
    }
    return $res;
}

sub _col {
    my ( $self, $args ) = @_;
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
        $conn_args->{$w} = $args->{$w} || $default->{$w};
        delete $conn_args->{$w} unless ( defined $conn_args->{$w} );
    }
    my $s = MongoDB->connect( $args->{host} || $default->{host}, $conn_args )
      or die('Unable to connect to MongoDB server');
    return $s->get_database( $args->{db_name} || $default->{db_name} )
      ->get_collection( $args->{collection}   || $default->{collection} );

}

1;

=head1 NAME

Apache::Session::MongoDB - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::MongoDB;
 
 # Using localhost server
 tie %hash, 'Apache::Session::MongoDB', $id, {};
  
 # Example with default values
 tie %hash, 'Apache::Session::MongoDB', $id, {
    host       => 'locahost:27017',
    db_name    => 'sessions',
    collection => 'sessions',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the MongoDB
backing store and no locking.

=head1 PARAMETERS

You can set the followong parameters host, db_name, collection, auth_mechanism,
auth_mechanism_properties, connect_timeout_ms, ssl, username and password.
See L<MongoDB> for more

=head1 SEE ALSO

L<MongoDB>, L<Apache::Session>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
