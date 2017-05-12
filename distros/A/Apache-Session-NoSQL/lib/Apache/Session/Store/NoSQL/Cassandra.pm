
package Apache::Session::Store::NoSQL::Cassandra;

use strict;
use Net::Cassandra;

use vars qw($VERSION);
$VERSION = '0.1';

sub new {
    my ( $class, $session ) = @_;
    my $self;

    $self->{cache} = Net::Cassandra->new( %{$session} )->client;

    bless $self, $class;
}

sub insert {
    my ( $self, $session ) = @_;
    $self->{cache}->insert(
        'Keyspace1',
        $session->{data}->{_session_id},
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        $session->{serialized},
        time,
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
}

*update = *insert;

sub materialize {
    my ( $self, $session ) = @_;
    $self->{cache}->get(
        'Keyspace1',
        $session->{data}->{_session_id},
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    ) or die 'Object does not exist in data store.';
}

sub remove {
    my ( $self, $session ) = @_;
    $self->{cache}->remove(
        'Keyspace1',
        $session->{data}->{_session_id},
        Net::Cassandra::Backend::ColumnPath->new(
            { column_family => 'Standard1', column => 'name' }
        ),
        time,
        Net::Cassandra::Backend::ConsistencyLevel::QUORUM
    );
}

1;

__END__

=pod

=head1 NAME

Apache::Session::Store::NoSQL::Cassandra - An implementation of Apache::Session::Store

=head1 SYNOPSIS

 use Apache::Session::NoSQL;
 
 tie %hash, 'Apache::Session::Cassandra', $id, {
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session::NoSQL. It uses the
Cassandra storage system

=head1 AUTHOR

Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>,
Xavier Guimard E<lt>x.guimard@free.frE<gt>

=head1 SEE ALSO

L<Apache::Session::NoSQL>, L<Apache::Session>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Thomas Chemineau

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
