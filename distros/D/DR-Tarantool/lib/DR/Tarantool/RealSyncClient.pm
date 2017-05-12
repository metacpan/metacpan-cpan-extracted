use utf8;
use strict;
use warnings;

package DR::Tarantool::RealSyncClient;


=head1 NAME

DR::Tarantool::RealSyncClient - a synchronous driver for L<Tarantool/Box|http://tarantool.org>

=head1 SYNOPSIS

    my $client = DR::Tarantool::RealSyncClient->connect(
        port    => $tnt->primary_port,
        spaces  => $spaces
    );

    if ($client->ping) { .. };

    my $t = $client->insert(
        first_space => [ 1, 'val', 2, 'test' ], TNT_FLAG_RETURN
    );

    $t = $client->call_lua('luafunc' =>  [ 0, 0, 1 ], 'space_name');

    $t = $client->select(space_name => $key);

    $t = $client->update(space_name => 2 => [ name => set => 'new' ]);

    $client->delete(space_name => $key);


=head1 DESCRIPTION

The module is a clone of L<DR::Tarantool::SyncClient> but it doesn't
use L<AnyEvent> or L<Coro>.

The module uses L<IO::Socket> sockets.

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<|https://github.com/dr-co/dr-tarantool/>.

=cut

use DR::Tarantool::LLSyncClient;
use DR::Tarantool::Spaces;
use DR::Tarantool::Tuple;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Data::Dumper;
use Scalar::Util 'blessed';

my $unpack = sub {
    my ($self, $res, $s) = @_;
    return undef unless $res and $res->{status} eq 'ok';
    return $s->tuple_class->unpack( $res->{tuples}, $s ) if $s;
    return $res->{tuples};
};

sub connect {
    my ($class, %opts) = @_;

    my $host = $opts{host} || 'localhost';
    my $port = $opts{port} or croak "port isn't defined";

    my $spaces = blessed($opts{spaces}) ?
        $opts{spaces} : DR::Tarantool::Spaces->new($opts{spaces});
    my $reconnect_period    = $opts{reconnect_period} || 0;
    my $reconnect_always    = $opts{reconnect_always} || 0;

    my $client = DR::Tarantool::LLSyncClient->connect(
        host                => $host,
        port                => $port,
        reconnect_period    => $reconnect_period,
        reconnect_always    => $reconnect_always,
        exists($opts{raise_error}) ?
            (   raise_error => $opts{raise_error} ?  1: 0 )
            : (),
    );


    return undef unless $client;
    return bless { llc => $client, spaces => $spaces } => ref($class) || $class;
}

sub space {
    my ($self, $name) = @_;
    return $self->{spaces}->space($name);
}


sub ping {
    my ($self) = @_;
    $self->{llc}->ping;
}

sub insert {
    my $self = shift;
    my $space = shift;
    $self->_llc->_check_tuple( my $tuple = shift );
    my $flags = pop || 0;

    my $s = $self->{spaces}->space($space);

    my $res =
        $self->_llc->insert( $s->number, $s->pack_tuple( $tuple ), $flags );
    return $unpack->($self, $res, $s);
}

sub call_lua {
    my $self = shift;
    my $lua_name = shift;
    my $args = shift;

    unshift @_ => 'space' if @_ == 1;
    my %opts = @_;

    my $flags = $opts{flags} || 0;
    my $space_name = $opts{space};
    my $fields = $opts{fields};

    my $s;
    croak "You can't use 'fields' and 'space' at the same time"
        if $fields and $space_name;

    if ($space_name) {
        $s = $self->space( $space_name );
    } elsif ( $fields ) {
        $s = DR::Tarantool::Space->new(
            0 =>
            {
                name    => 'temp_space',
                fields  => $fields,
                indexes => {}
            },
        );
    } else {
        $s = DR::Tarantool::Space->new(
            0 =>
            {
                name            => 'temp_space',
                fields          => [],
                indexes         => {}
            },
        );
    }

    if ($opts{args}) {
        my $sa = DR::Tarantool::Space->new(
            0 =>
            {
                name    => 'temp_space_args',
                fields  => $opts{args},
                indexes => {}
            },
        );
        $args = $sa->pack_tuple( $args );
    }

    my $res = $self->_llc->call_lua( $lua_name, $args, $flags );

    return $unpack->($self, $res, $s);
}


sub select {
    my $self = shift;
    my $space = shift;
    my $keys = shift;

    my ($index, $limit, $offset);

    if (@_ == 1) {
        $index = shift;
    } elsif (@_ == 3) {
        ($index, $limit, $offset) = @_;
    } elsif (@_) {
        my %opts = @_;
        $index = $opts{index};
        $limit = $opts{limit};
        $offset = $opts{offset};
    }

    $index ||= 0;

    my $s = $self->space($space);

    my $res = $self->_llc->select(
        $s->number,
        $s->_index( $index )->{no},
        $s->pack_keys( $keys, $index ),
        $limit,
        $offset
    );

    return $unpack->($self, $res, $s);
}

sub update {
    my $self = shift;
    my $space = shift;
    my $key = shift;
    my $op = shift;
    my $flags = shift || 0;

    my $s = $self->space($space);

    my $res = $self->_llc->update(
        $s->number,
        $s->pack_primary_key( $key ),
        $s->pack_operations( $op ),
        $flags,
    );
    return $unpack->($self, $res, $s);
}

sub delete :method {
    my $self = shift;
    my $space = shift;
    my $key = shift;
    my $flags = shift || 0;

    my $s = $self->space($space);

    my $res = $self->_llc->delete(
        $s->number,
        $s->pack_primary_key( $key ),
        $flags,
    );
    return $unpack->($self, $res, $s);
}

sub last_code { $_[0]->{llc}->last_code }
sub last_error_string { $_[0]->{llc}->last_error_string }
sub raise_error { $_[0]->raise_error };
sub _llc { $_[0]{llc} }

1;
