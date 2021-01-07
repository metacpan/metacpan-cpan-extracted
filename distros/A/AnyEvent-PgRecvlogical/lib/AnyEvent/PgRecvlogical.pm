package AnyEvent::PgRecvlogical;
$AnyEvent::PgRecvlogical::VERSION = '1.02';
# ABSTRACT: perl port of pg_recvlogical

=pod

=head1 NAME

AnyEvent::PgRecvlogical - perl port of pg_recvlogical

=for html
<a href="https://travis-ci.org/mydimension/AnyEvent-PgRecvlogical"><img src="https://travis-ci.org/mydimension/AnyEvent-PgRecvlogical.svg?branch=master" /></a>
<a href='https://coveralls.io/github/mydimension/AnyEvent-PgRecvlogical?branch=master'><img src='https://coveralls.io/repos/github/mydimension/AnyEvent-PgRecvlogical/badge.svg?branch=master' alt='Coverage Status' /></a>
<a href="https://badge.fury.io/pl/AnyEvent-PgRecvlogical"><img src="https://badge.fury.io/pl/AnyEvent-PgRecvlogical.svg" alt="CPAN version" height="18"></a>

=head1 SYNOPSIS

    use AnyEvent::PgRecvlogical;

    my $recv = AnyEvent::PgRecvlogical->new(
        dbname     => 'mydb',
        slot       => 'myreplslot',
        on_message => sub {
            my ($record, $guard) = @_;

            process($record);

            undef $guard; # declare done with $record
        }
    );

    $recv->start;

=head1 DESCRIPTION

C<AnyEvent::PgRecvlogical> provides perl bindings of similar functionality to that of
L<pg_recvlogical|https://www.postgresql.org/docs/current/static/app-pgrecvlogical.html>.
The reasoning being that C<pg_recvlogical> does afford the consuming process the opportunity to emit feedback to
PostgreSQL. This results is potentially being sent more data than you can handle in a timely fashion.

=cut

use Moo;
use DBI;
use DBD::Pg 3.7.0 ':async';
use AnyEvent;
use AnyEvent::Util 'guard';
use Promises 0.99 backend => ['AnyEvent'], qw(deferred);
use Types::Standard ':all';
use Try::Tiny;
use Carp 'croak';
use curry;

use constant {
    AWAIT_INTERVAL    => 1,
    USECS             => 1_000_000,
    PG_MIN_VERSION    => 9_04_00,
    PG_MIN_NOEXPORT   => 10_00_00,
    PG_STATE_DUPEOBJ  => '42710',
    PG_EPOCH_DELTA    => 946_684_800,
    XLOGDATA          => 'Aq>3a*',
    PRIMARY_HEARTBEAT => 'Aq>2b',
    STANDBY_HEARTBEAT => 'Aq>4b',
};

use namespace::clean;

my $DBH = (InstanceOf ['DBI::db'])->create_child_type(
    constraint => sub {
        $_->{Driver}->{Name} eq 'Pg'
          and $_->{pg_server_version} >= PG_MIN_VERSION
          and $_->{Name} =~ /replication=/;
    },
    message => sub {
        my $parent_check = (InstanceOf['DBI::db'])->validate($_);
        return $parent_check if $parent_check;
        return "$_ is not a DBD::Pg handle" unless $_->{Driver}->{Name} eq 'Pg';
        return "$_ is connected to an old postgres version ($_->{pg_server_version} < 9.4.0)" unless $_->{pg_server_version} >= PG_MIN_VERSION;
        return "$_ is not a replication connection: $_->{Name}" unless $_->{Name} =~ /replication=/;
    }
);

my $LSNStr = Str->where(sub { m{[0-9A-F]{1,8}/[0-9A-F]{1,8}} })
  ->plus_coercions(Int() => sub { sprintf '%X/%X', (($_ >> 32) & 0xffff_ffff), ($_ & 0xffff_ffff) });

my $LSN = Int->plus_coercions(
    $LSNStr => sub {
        my ($h, $l) = map { hex } split m{/}; ($h << 32) | $l;
    }
);

=head1 ATTRIBUTES

=over

=item C<dbname>

=over

=item L<Str|Types::Standard/Str>, Required

=back

Database name to connect to.

=item C<slot>

=over

=item L<Str|Types::Standard/Str>, Required

=back

Name of the replication slot to use (and/or create, see L</do_create_slot> and L</slot_exists_ok>)

=item C<host>

=over

=item L<Str|Types::Standard/Str>

=back

=item C<port>

=over

=item L<Int|Types::Standard/SInt>

=back

=item C<username>

=over

=item L<Str|Types::Standard/Str>

=back

=item C<password>

=over

=item L<Str|Types::Standard/Str>

=back

Standard PostgreSQL connection parameters, see L<DBD::Pg/connect>.

=item C<do_create_slot>

=over

=item L<Bool|Types::Standard/Bool>, Default: C<0>

=back

If true, the L</slot> will be be created upon connection. Otherwise, it's assumed it already exists. If it does not,
PostgreSQL will raise an exception.

=item C<slot_exists_ok>

=over

=item L<Bool|Types::Standard/Bool>, Default: C<0>

=back

If true, and if L</do_create_slot> is also true, then no exception will be raised if the L</slot> already exists.
Otherwise, one will be raised.

=item C<reconnect>

=over

=item L<Bool|Types::Standard/Bool>, Default: C<1>

=back

If true, will attempt to reconnect to the server and resume logical replication in the event the connection fails.
Otherwise, the connection will gracefully be allowed to close.

=item C<reconnect_delay>

=over

=item L<Int|Types::Standard/Int>, Default: C<5>

=back

Time, in seconds, to wait before reconnecting.

=item C<reconnect_limit>

=over

=item L<Int|Types::Standard/Int>, Default: C<1>

=back

Number of times to attempt reconnecting. If this limit is exceded, an exception will be thrown.

=item C<heartbeat>

=over

=item L<Int|Types::Standard/Int>, Default: C<10>

=back

Interval, in seconds, to report our progress to the PostgreSQL server.

=item C<plugin>

=over

=item L<Str|Types::Standard/Str>, Default: L<test_decoding|https://www.postgresql.org/docs/current/static/test-decoding.html>

=back

The server-sider plugin used to decode the WAL file before being sent to this connection. Only required when
L</create_slot> is true.

=item C<options>

=over

=item L<HashRef|Types::Standard/HashRef>, Default: C<{}>

=back

Key-value pairs sent to the server-side L</plugin>. Keys with a value of C<undef> are sent as the keyword only.

=item C<startpos>

=over

=item L<LSN|https://www.postgresql.org/docs/current/static/datatype-pg-lsn.html>, Default: C<0/0>

=back

Start replication from the given LSN. Also accepts the integer form, but that is considered advanced usage.

=item C<received_lsn>

=over

=item L<LSN|https://www.postgresql.org/docs/current/static/datatype-pg-lsn.html>, Default: C<0/0>, Read Only

=back

Holds the last LSN position received from the server.

=item C<flushed_lsn>

=over

=item L<LSN|https://www.postgresql.org/docs/current/static/datatype-pg-lsn.html>, Default: C<0/0>, Read Only

=back

Holds the last LSN signaled to handled by the client (see: L</on_message>)

=item C<on_error>

=over

=item L<CodeRef|Types::Standard/CodeRef>, Default: L<croak|Carp/croak>

=back

Callback in the event of an error.

=item C<on_message>

=over

=item L<CodeRef|Types::Standard/CodeRef>, Required

=back

Callback to receive the replication payload from the server. This is the raw output from the L</plugin>.

The callback is passed the C<$payload> received and a C<$guard> object. Hang onto the C<$guard> until you have handled
the payload. Once it is released, the server will be informed that the WAL position has been "flushed."

=back

=cut

has dbname   => (is => 'ro', isa => Str, required  => 1);
has host     => (is => 'ro', isa => Str, predicate => 1);
has port     => (is => 'ro', isa => Int, predicate => 1);
has username => (is => 'ro', isa => Str, default => q{});
has password => (is => 'ro', isa => Str, default => q{});
has slot     => (is => 'ro', isa => Str, required  => 1);

has dbh => (is => 'lazy', isa => $DBH, clearer => 1, init_arg => undef);
has do_create_slot     => (is => 'ro', isa => Bool, default   => 0);
has slot_exists_ok     => (is => 'ro', isa => Bool, default   => 0);
has reconnect          => (is => 'ro', isa => Bool, default   => 1);
has reconnect_delay    => (is => 'ro', isa => Int,  default   => 5);
has reconnect_limit    => (is => 'ro', isa => Int,  predicate => 1);
has _reconnect_counter => (is => 'rw', isa => Int,  default   => 0);
has heartbeat          => (is => 'ro', isa => Int,  default   => 10);
has plugin             => (is => 'ro', isa => Str,  default   => 'test_decoding');
has options => (is => 'ro', isa => HashRef, default => sub { {} });
has startpos     => (is => 'rwp', isa => $LSN, default => 0, coerce  => 1);
has received_lsn => (is => 'rwp', isa => $LSN, default => 0, clearer => 1, init_arg => undef, lazy => 1);
has flushed_lsn  => (is => 'rwp', isa => $LSN, default => 0, clearer => 1, init_arg => undef, lazy => 1);

has on_message => (is => 'ro', isa => CodeRef, required => 1);
has on_error => (is => 'ro', isa => CodeRef, default => sub { \&croak });

has _fh_watch => (is => 'lazy', isa => Ref,  clearer => 1, predicate => 1);
has _timer    => (is => 'lazy', isa => Ref,  clearer => 1);

=head1 CONSTRUCTOR

All the L</"ATTRIBUTES"> above are accepted by the constructor, with a few exceptions:

L</"received_lsn"> and L<"flushed_lsn"> are read-only and not accepted by the constructor.

L</"dbname">, L</"slot"> and L</"on_message"> are required.

Note, that logical replication will not automatically commence upon construction. One must call L</"start"> first.

=cut

sub _dsn {
    my $self = shift;

    my %dsn = (replication => 'database', client_encoding => 'sql_ascii');
    foreach (qw(host port dbname)) {
        my $x = "has_$_";
        next if $self->can($x) and not $self->$x;

        $dsn{$_} = $self->$_;
    }

    return 'dbi:Pg:' . join q{;}, map { "$_=$dsn{$_}" } sort keys %dsn;
}

sub _build_dbh {
    my $self = shift;
    my $dbh = DBI->connect(
        $self->_dsn,
        $self->username,
        $self->password,
        { PrintError => 0 },
    );

    croak $DBI::errstr unless $dbh;

    return $dbh;
}

sub _build__fh_watch {
    my $self = shift;
    return AE::io $self->dbh->{pg_socket}, 0, $self->curry::weak::_read_copydata;
}

sub _build__timer {
    my $self = shift;
    if ($AnyEvent::MODEL and $AnyEvent::MODEL eq 'AnyEvent::Impl::EV') {
        my $w = EV::periodic(0, $self->heartbeat, 0, $self->curry::weak::_heartbeat);
        $w->priority(&EV::MAXPRI);
        return $w;
    } else {
        return AE::timer $self->heartbeat, $self->heartbeat, $self->curry::weak::_heartbeat;
    }
}

=head1 METHODS

All L</"ATTRIBUTES"> are also accesible via methods. They are all read-only.

=over

=item start

Initialize the logical replication process asyncronously and return immediately. This performs the following steps:

=over

=item 1. L</"identify_system">

=item 2. L</"create_slot"> (if requested)

=item 3. L</"start_replication">

=item 4. heartbeat timer

=back

This method wraps the above steps for convenience. Should you desire to modify the
L<replication startup protocol|https://www.postgresql.org/docs/current/static/protocol-replication.html> (which you
shouldn't), the methods are described in detail below.

Returns: L<Promises::Promise>

=cut

sub start {
    my $self = shift;

    $self->_post_init(
        deferred {
            shift->chain($self->curry::identify_system, $self->curry::create_slot, $self->curry::start_replication);
        }
    );
}

sub _post_init {
    my ($self, $d) = @_;

    return $d->then(
        sub {
            $self->_fh_watch;
            $self->_timer;
        },
        $self->on_error,
    );
}

=item identify_system

Issues the C<IDENTIFY_SYSTEM> command to the server to put the connection in repliction mode.

Returns: L<Promises::Promise>

=cut

sub identify_system {
    my $self = shift;
    $self->dbh->do('IDENTIFY_SYSTEM', { pg_async => PG_ASYNC });
    return _async_await($self->dbh)->catch(
        sub {
            my @error = @_;
            unshift @error, $DBI::errstr if $DBI::errstr;

            croak @error;
        }
    );
}

=item create_slot

Issues the appropriate C<CREATE_REPLICATION_SLOT> command to the server, if requested.

Returns: L<Promises::Promise>

=cut

sub create_slot {
    my $self = shift;

    return deferred->resolve unless $self->do_create_slot;

    my $dbh = $self->dbh;
    $dbh->do(
        sprintf(
            'CREATE_REPLICATION_SLOT %s LOGICAL %s%s',
            $dbh->quote_identifier($self->slot),
            $dbh->quote_identifier($self->plugin),
            ($dbh->{pg_server_version} >= PG_MIN_NOEXPORT ? ' NOEXPORT_SNAPSHOT' : '')    # uncoverable branch true
        ),
        { pg_async => PG_ASYNC }
    );

    return _async_await($dbh)->catch(
        sub {
            croak @_ unless $dbh->state eq PG_STATE_DUPEOBJ and $self->slot_exists_ok;
        }
    );
}

sub _option_string {
    my $self = shift;

    my @opts;
    while (my ($k, $v) = each %{ $self->options }) {
        push @opts, $self->dbh->quote_identifier($k);
        defined $v and $opts[-1] .= sprintf ' %s', $self->dbh->quote($v);    # uncoverable branch false
    }

    return @opts ? sprintf('(%s)', join q{, }, @opts) : q{};    # uncoverable branch false
}

=item start_replication

Issues the C<START_REPLICATION SLOT> command and immediately returns. The connection will then start receiving
logical replication payloads.

=cut

sub start_replication {
    my $self = shift;

    $self->dbh->do(
        sprintf(
            'START_REPLICATION SLOT %s LOGICAL %s%s',
            $self->dbh->quote_identifier($self->slot),
            $LSNStr->coerce($self->startpos),
            $self->_option_string
        ),
    );
}

=item pause

Pauses reading from the database. Useful for throttling the inbound flow of data so as to not overwhelm your
application. It is safe, albeit redundant, to call this method multiple time in a row without unpausing.

=cut

sub pause { shift->_clear_fh_watch; return; }

=item unpause

Resume reading from the database. After a successful L</pause>, this will pick right back reciving data and sending it
to the provided L</callback>. It is safe, albeit redundant, to call this method multiple time in a row without pausing.

=cut

sub unpause { shift->_fh_watch; return; }

=item is_paused

Returns the current pause state.

Returns: boolean

=cut

sub is_paused { return !shift->_has_fh_watch }

sub _read_copydata {
    my $self = shift;

    my ($n, $msg);
    my $ok = try {
        $n = $self->dbh->pg_getcopydata_async($msg);
        1;
    }
    catch {
        # uncoverable statement count:2
        AE::postpone { $self->_handle_disconnect };
        0;
    };

    # exception thrown, going to reconnect
    return unless $ok;    # uncoverable branch true

    # nothing waiting
    return if $n == 0;

    if ($n == -1) {
        AE::postpone { $self->_handle_disconnect };
        return;
    }

    # uncoverable branch true
    if ($n == -2) {
        # error reading
        # uncoverable statement
        $self->on_error->('could not read COPY data: ' . $self->dbh->errstr);
    }

    # do it again until $n == 0
    my $w; $w = AE::timer 0, 0, sub { undef $w; $self->_read_copydata };

    my $type = substr $msg, 0, 1;

    if ('k' eq $type) {
        # server keepalive
        my (undef, $lsnpos, $ts, $reply) = unpack PRIMARY_HEARTBEAT, $msg;

        $self->_set_received_lsn($lsnpos) if $lsnpos > $self->received_lsn;

        # only interested in the request-reply bit
        # uncoverable branch true
        if ($reply) {
            # uncoverable statement
            AE::postpone { $self->_heartbeat };
        }

        # an inbound heartbeat is proof enough of successful reconnect
        $self->_reconnect_counter(0) if $self->_reconnect_counter;

        return;
    }

    # uncoverable branch true
    unless ('w' eq $type) {
        # uncoverable statement
        undef $w;
        $self->on_error->("unrecognized streaming header: '$type'");
        return;
    }

    my (undef, $startlsn, $endlsn, $ts, $record) = unpack XLOGDATA, $msg;

    $self->_set_received_lsn($startlsn) if $startlsn > $self->received_lsn;

    my $guard = $self->$curry::weak(
        sub {
            my $self = shift;
            $self->_set_flushed_lsn($startlsn) if $startlsn > $self->flushed_lsn;
        }
    );

    $self->on_message->($record, guard(\&$guard));

    return;
}

=item stop

Stop receiving replication payloads and disconnect from the PostgreSQL server.

=back

=cut

sub stop {
    my $self = shift;

    $self->_clear_fh_watch;
    $self->_clear_timer;
    $self->clear_dbh;
}

sub _handle_disconnect {
    my $self = shift;

    $self->stop;

    return unless $self->reconnect;

    if (    $self->has_reconnect_limit
        and $self->_reconnect_counter($self->_reconnect_counter + 1) > $self->reconnect_limit) {
        $self->on_error->('reconnect limit reached: ' . $self->reconnect_limit);
        return;
    }

    $self->_set_startpos($self->flushed_lsn);
    $self->clear_received_lsn;
    $self->clear_flushed_lsn;

    my $w; $w = AE::timer $self->reconnect_delay, 0, sub {
        undef $w;
        $self->_post_init(deferred { $self->start_replication });
    };
}

sub _heartbeat {
    my ($self, $req_reply) = @_;
    $req_reply = !!$req_reply || 0;    #uncoverable condition right

    my $status = pack STANDBY_HEARTBEAT, 'r',     # receiver status update
      $self->received_lsn,                        # last WAL received
      $self->flushed_lsn,                         # last WAL flushed
      0,                                          # last WAL applied
      int((AE::now - PG_EPOCH_DELTA) * USECS),    # ms since 2000-01-01
      $req_reply;                                 # request heartbeat

    $self->dbh->pg_putcopydata($status);
}

sub _async_await {
    my ($dbh) = @_;

    my $d = deferred;

    # no async operation in progress
    return $d->reject if $dbh->{pg_async_status} == 0;    # uncoverable branch true

    my $w; $w = AE::timer 0, AWAIT_INTERVAL, sub {
        return unless $dbh->pg_ready;
        try {
            $d->resolve($dbh->pg_result);
        }
        catch {
            $d->reject($_);
        };
        undef $w;
    };

    return $d->promise;
}

=head1 AUTHOR

William Cox (cpan:MYDMNSN) <mydimension@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2017-2018 William Cox

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.
See L<http://dev.perl.org/licenses/>.

=cut

1;
