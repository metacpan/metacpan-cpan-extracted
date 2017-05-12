use utf8;
use strict;
use warnings;

package DR::Tarantool::MsgPack::AsyncClient;

=head1 NAME

DR::Tarantool::MsgPack::AsyncClient - async client for tarantool.

=head1 SYNOPSIS

    use DR::Tarantool::MsgPack::AsyncClient;

    DR::Tarantool::MsgPack::AsyncClient->connect(
        host => '127.0.0.1',
        port => 12345,
        spaces => $spaces,
        sub {
            my ($client) = @_;
        }
    );

    $client->insert('space_name', [1,2,3], sub { ... });


=head1 Class methods

=head2 connect

Connect to <Tarantool:http://tarantool.org>, returns (by callback) an
object which can be used to make requests.

=head3 Arguments

=over

=item host & port & user & password

Address and auth information of remote tarantool.

=item space

A hash with space description or a L<DR::Tarantool::Spaces> reference.

=item reconnect_period

An interval to wait before trying to reconnect after a fatal error
or unsuccessful connect. If the field is defined and is greater than
0, the driver tries to reconnect to the server after this interval.

Important: the driver does not reconnect after the first
unsuccessful connection. It calls callback instead.

=item reconnect_always

Try to reconnect even after the first unsuccessful connection.

=back

=cut


use DR::Tarantool::MsgPack::LLClient;
use DR::Tarantool::Spaces;
use DR::Tarantool::Tuple;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Scalar::Util ();
use Data::Dumper;

sub connect {
    my $class = shift;
    my ($cb, %opts);
    if ( @_ % 2 ) {
        $cb = pop;
        %opts = @_;
    } else {
        %opts = @_;
        $cb = delete $opts{cb};
    }

    $class->_llc->_check_cb( $cb );

    my $host = $opts{host} || 'localhost';
    my $port = $opts{port} or croak "port isn't defined";

    my $user        = delete $opts{user};
    my $password    = delete $opts{password};

    my $spaces = Scalar::Util::blessed($opts{spaces}) ?
        $opts{spaces} : DR::Tarantool::Spaces->new($opts{spaces});
    $spaces->family(2);

    my $reconnect_period    = $opts{reconnect_period} || 0;
    my $reconnect_always    = $opts{reconnect_always} || 0;

    DR::Tarantool::MsgPack::LLClient->connect(
        host                => $host,
        port                => $port,
        user                => $user,
        password            => $password,
        reconnect_period    => $reconnect_period,
        reconnect_always    => $reconnect_always,
        sub {
            my ($client) = @_;
            my $self;
            if (ref $client) {
                $self = bless {
                    llc         => $client,
                    spaces      => $spaces,
                } => ref($class) || $class;
            } else {
                $self = $client;
            }

            $cb->( $self );
        }
    );

    return;
}

sub _llc { return $_[0]{llc} if ref $_[0]; 'DR::Tarantool::MsgPack::LLClient' }


sub _cb_default {
    my ($res, $s, $cb) = @_;
    if ($res->{status} ne 'ok') {
        $cb->($res->{status} => $res->{CODE}, $res->{ERROR});
        return;
    }

    if ($s) {
        $cb->(ok => $s->tuple_class->unpack( $res->{DATA}, $s ), $res->{CODE});
        return;
    }

    unless ('ARRAY' eq ref $res->{DATA}) {
        $cb->(ok => $res->{DATA}, $res->{CODE});
        return;
    }

    unless (@{ $res->{DATA} }) {
        $cb->(ok => undef, $res->{CODE});
        return;
    }
    $cb->(ok => DR::Tarantool::Tuple->new($res->{DATA}), $res->{CODE});
    return;
}

=head1 Worker methods

All methods accept callbacks which are invoked with the following
arguments:

=over

=item status

On success, this field has value 'ok'. The value of this parameter
determines the contents of the rest of the callback arguments.

=item a tuple or tuples or an error code

On success, the second argument contains tuple(s) produced by the
request. On error, it contains the server error code.

=item errorstr

Error string in case of an error.

    sub {
        if ($_[0] eq 'ok') {
            my ($status, $tuples) = @_;
            ...
        } else {
            my ($status, $code, $errstr) = @_;
            ...
        }
    }

=back


=head2 ping

Ping the server.

    $client->ping(sub { ... });

=head2 insert, replace


Insert/replace a tuple into a space.

    $client->insert('space', [ 1, 'Vasya', 20 ], sub { ... });
    $client->replace('space', [ 2, 'Petya', 22 ], sub { ... });


=head2 call_lua

Call Lua function.

    $client->call_lua(foo => ['arg1', 'arg2'], sub {  });


=head2 select

Select a tuple (or tuples) from a space by index.

    $client->select('space_name', 'index_name', [ 'key' ], %opts, sub { .. });

Options can be:

=over

=item limit

=item offset

=item iterator

An iterator for index. Can be:

=over

=item ALL

Returns all tuples in space.

=item EQ, GE, LE, GT, LT

=back

=back


=head2 delete

Delete a tuple.

    $client->delete('space_name', [ 'key' ], sub { ... });


=head2 update

Update a tuple.

    $client->update('space', [ 'key' ], \@ops, sub { ... });

C<@ops> is array of operations to update.
Each operation is array of elements:

=over

=item code

Code of operation: C<=>, C<+>, C<->, C<&>, C<|>, etc

=item field

Field number or name.

=item arguments

=back

=cut




sub ping {
    my $self = shift;
    my $cb = pop;

    $self->_llc->_check_cb( $cb );
    $self->_llc->ping(sub { _cb_default($_[0], undef, $cb) });
}

sub insert {
    my $self = shift;
    my $cb = pop;
    $self->_llc->_check_cb( $cb );
    my $space = shift;
    my $tuple = shift;
    $self->_llc->_check_tuple( $tuple );


    my $sno;
    my $s;

    if (Scalar::Util::looks_like_number $space) {
        $sno = $space;
    } else {
        $s = $self->{spaces}->space($space);
        $sno = $s->number,
        $tuple = $s->pack_tuple( $tuple );
    }

    $self->_llc->insert(
        $sno,
        $tuple,
        sub {
            my ($res) = @_;
            _cb_default($res, $s, $cb);
        }
    );
    return;
}

sub replace {
    my $self = shift;
    my $cb = pop;
    $self->_llc->_check_cb( $cb );
    my $space = shift;
    my $tuple = shift;
    $self->_llc->_check_tuple( $tuple );


    my $sno;
    my $s;

    if (Scalar::Util::looks_like_number $space) {
        $sno = $space;
    } else {
        $s = $self->{spaces}->space($space);
        $sno = $s->number,
        $tuple = $s->pack_tuple( $tuple );
    }

    $self->_llc->replace(
        $sno,
        $tuple,
        sub {
            my ($res) = @_;
            _cb_default($res, $s, $cb);
        }
    );
    return;
}

sub delete :method {
    my $self = shift;
    my $cb = pop;
    $self->_llc->_check_cb( $cb );
    
    my $space = shift;
    my $key = shift;


    my $sno;
    my $s;

    if (Scalar::Util::looks_like_number $space) {
        $sno = $space;
    } else {
        $s = $self->{spaces}->space($space);
        $sno = $s->number;
    }

    $self->_llc->delete(
        $sno,
        $key,
        sub {
            my ($res) = @_;
            _cb_default($res, $s, $cb);
        }
    );
    return;
}

sub select :method {
    my $self = shift;
    my $cb = pop;
    $self->_llc->_check_cb( $cb );
    my $space = shift;
    my $index = shift;
    my $key = shift;
    my %opts = @_;

    my $sno;
    my $ino;
    my $s;
    if (Scalar::Util::looks_like_number $space) {
        $sno = $space;
        croak 'If space is number, index must be number too'
            unless Scalar::Util::looks_like_number $index;
        $ino = $index;
    } else {
        $s = $self->{spaces}->space($space);
        $sno = $s->number;
        $ino = $s->_index( $index )->{no};
    }
    $self->_llc->select(
        $sno,
        $ino,
        $key,
        $opts{limit},
        $opts{offset},
        $opts{iterator},
        sub {
            my ($res) = @_;
            _cb_default($res, $s, $cb);
        }
    );
}

sub update :method {
    my $self = shift;
    my $cb = pop;
    $self->_llc->_check_cb( $cb );
    my $space = shift;
    my $key = shift;
    my $ops = shift;

    my $sno;
    my $s;
    if (Scalar::Util::looks_like_number $space) {
        $sno = $space;
    } else {
        $s = $self->{spaces}->space($space);
        $sno = $s->number;
        $ops = $s->pack_operations($ops);
    }
    $self->_llc->update(
        $sno,
        $key,
        $ops,
        sub {
            my ($res) = @_;
            _cb_default($res, $s, $cb);
        }
    );
}

sub call_lua {
    my $self = shift;
    my $cb = pop;
    $self->_llc->_check_cb( $cb );

    my $proc = shift;
    my $tuple = shift;

    $tuple = [ $tuple ] unless ref $tuple;
    $self->_llc->_check_tuple( $tuple );


    $self->_llc->call_lua(
        $proc,
        $tuple,
        sub {
            my ($res) = @_;
            _cb_default($res, undef, $cb);
        }
    );
    return;
}


sub last_code { $_[0]->_llc->last_code }


sub last_error_string { $_[0]->_llc->last_error_string }

1;
