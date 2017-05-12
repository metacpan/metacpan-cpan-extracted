use utf8;
use strict;
use warnings;

package DR::Tarantool::SyncClient;
use base 'DR::Tarantool::AsyncClient';
use AnyEvent;
use Devel::GlobalDestruction;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

=head1 NAME

DR::Tarantool::SyncClient - a synchronous driver for
L<Tarantool|http://tarantool.org>.

=head1 SYNOPSIS

    my $client = DR::Tarantool::SyncClient->connect(
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


=head1 METHODS

=head2 connect

Connects to the server.

=head3 Arguments

The same as L<DR::Tarantool::AsyncClient/connect>, excluding the callback.

Returns a connection handle or croaks an error.

=head3 Additional arguments

=over

=item raise_error

If B<true> (default behaviour) the driver throws an exception for each
error.

=back

=cut

sub connect {
    my ($class, %opts) = @_;

    my $raise_error = 1;
    $raise_error = delete $opts{raise_error} if exists $opts{raise_error};

    my $cv = condvar AnyEvent;
    my $self;

    $class->SUPER::connect(%opts, sub {
        ($self) = @_;
        $cv->send;
    });

    $cv->recv;


    unless(ref $self) {
        croak $self if $raise_error;
        $! = $self;
        return undef;
    }

    $self->{raise_error} = $raise_error ? 1 : 0;
    $self;
}

=head2 ping

The same as L<DR::Tarantool::AsyncClient/ping>, excluding the callback.

Returns B<true> on success, b<false> in case of an error.

=head2 insert

The same as L<DR::Tarantool::AsyncClient/insert>, excluding the callback.

Returns the inserted tuple.
Croaks error if an error occurred (as long as B<raise_error> is true).

=head2 select

The same as L<DR::Tarantool::AsyncClient/select>, excluding the callback.

Returns tuples contained in the server response or undef.
Croaks error if an error occurred (as long as B<raise_error> is true).

=head2 update

The same as L<DR::Tarantool::AsyncClient/update>, excluding the callback.

Returns the updated tuple.
Croaks error if an error occurred (as long as B<raise_error> is true).

=head2 delete

The same as L<DR::Tarantool::AsyncClient/delete>, excluding the callback.

Returns the deleted tuple or undef.
Croaks error if an error occurred (as long as B<raise_error> is true).

=head2 call_lua

The same as L<DR::Tarantool::AsyncClient/call_lua>, excluding the callback.

Returns tuples contained in the server response or undef.
Croaks error if an error occurred (as long as B<raise_error> is true).

=cut


for my $method (qw(ping insert select update delete call_lua)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my ($self, @args) = @_;
        my @res;
        my $cv = condvar AnyEvent;
        my $m = "SUPER::$method";
        $self->$m(@args, sub { @res = @_; $cv->send });
        $cv->recv;

        if ($res[0] eq 'ok') {
            return 1 if $method eq 'ping';
            return $res[1];
        }
        return 0 if $method eq 'ping';
        return undef unless $self->{raise_error};
        croak  sprintf "%s: %s",
            defined($res[1])? $res[1] : 'unknown',
            $res[2]
        ;
    };
}

sub DESTROY {
    my ($self) = @_;
    return if in_global_destruction;

    my $cv = condvar AnyEvent;
    $self->disconnect(sub { $cv->send });
    $cv->recv;
}

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<https://github.com/dr-co/dr-tarantool/>.

=cut

1;
