use utf8;
use strict;
use warnings;

package DR::Tarantool::CoroClient;
use base 'DR::Tarantool::AsyncClient';
use Coro;
use Carp;
use AnyEvent;

=head1 NAME

DR::Tarantool::CoroClient - an asynchronous coro driver for
L<Tarantool|http://tarantool.org>

=head1 SYNOPSIS

    use DR::Tarantool::CoroClient;
    use Coro;
    my $client = DR::Tarantool::CoroClient->connect(
        port    => $port,
        spaces  => $spaces;
    );

    my @res;
    for (1 .. 100) {
        async {
            push @res => $client->select(space_name => $_);
        }
    }
    cede while @res < 100;


=head1 METHODS

=head2 connect

Connects to Tarantool.

=head3 Arguments

The same as L<DR::Tarantool::AsyncClient/connect>, excluding the callback.

Returns a connection handle or croaks an error.

=head3 Additional arguments

=over

=item raise_error

If B<true> (default behaviour) the driver throws an exception for each
server error.

=back

=cut

sub connect {
    my ($class, %opts) = @_;

    my $raise_error = 1;
    $raise_error = delete $opts{raise_error} if exists $opts{raise_error};

    my $cb = Coro::rouse_cb;
    $class->SUPER::connect(%opts, $cb);

    my ($self) = Coro::rouse_wait;
    unless (ref $self) {
        croak $self if $raise_error;
        $! = $self;
        return undef;
    }
    $self->{raise_error} = $raise_error ? 1 : 0;
    $self;
}

=head2 ping

The same as L<DR::Tarantool::AsyncClient/ping>, excluding the callback.

Returns B<true> on success, B<false> on error.

=head2 insert

The same as L<DR::Tarantool::AsyncClient/insert>, excluding the callback.

Returns the inserted tuple or undef.
Croaks an error if insert failed (B<raise_error> must be set).

=head2 select

The same as L<DR::Tarantool::AsyncClient/select>, excluding the callback.

Returns tuple or tuples that match selection criteria, or undef
if no matching tuples were found.
Croaks an error if an error occurred (provided B<raise_error> is set).

=head2 update

The same as L<DR::Tarantool::AsyncClient/update>, excluding the callback.

Returns the new value of the tuple.
Croaks an error if update failed (provided B<raise_error> is set).

=head2 delete

The same as L<DR::Tarantool::AsyncClient/delete>, excluding the callback.

Returns the deleted tuple, or undef.
Croaks error if an error occurred (provided B<raise_error> is set).

=head2 call_lua

The same as L<DR::Tarantool::AsyncClient/call_lua>, excluding the callback.

Returns a tuple or tuples returned by the called procedure.
Croaks an error if an error occurred (provided B<raise_error> is set).

=cut


for my $method (qw(ping insert select update delete call_lua)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my ($self, @args) = @_;

        my $cb = Coro::rouse_cb;
        my $m = "SUPER::$method";
        $self->$m(@args, $cb);

        my @res = Coro::rouse_wait;

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

1;
