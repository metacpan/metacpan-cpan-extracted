package DBIO::MySQL::NotifyTable;
# ABSTRACT: LISTEN/NOTIFY emulated over a notify table for MySQL and MariaDB, without I/O

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'Class::Accessor::Grouped';

use Carp 'croak';
use Scalar::Util qw( looks_like_number refaddr );

my %DEFAULTS = (
  table         => 'dbio_notify',
  poll_interval => 1,
  lookback      => 60,
  retention     => 3600,
  cleanup_limit => 1000,
);

# The widest channel the channel column holds, in characters.
my $MAX_CHANNEL = 255;

# The widest payload the TEXT payload column holds, in bytes.
my $MAX_PAYLOAD = 65535;

# A listener cleans up at most this often, in seconds of polling -- more often
# only while each run fills its whole batch.
my $CLEANUP_PERIOD = 60;

# The server-side format of a cutoff: fixed width, so string order is time
# order.
my $CUTOFF_FORMAT = '%Y-%m-%d %H:%i:%s.%f';

__PACKAGE__->mk_group_ro_accessors(simple => sort keys %DEFAULTS);



sub new {
  my ($class, %args) = @_;

  my @unknown = grep { !exists $DEFAULTS{$_} } sort keys %args;
  croak "unknown notify table setting(s): @unknown" if @unknown;

  my %cfg = map { $_ => $args{$_} // $DEFAULTS{$_} } keys %DEFAULTS;

  croak sprintf(
    "notify table name '%s' is not a plain identifier -- it must match "
  . '[A-Za-z_][A-Za-z0-9_]* and be at most 64 characters long',
    ref $cfg{table} ? 'a reference' : $cfg{table},
  ) unless !ref $cfg{table}
        && $cfg{table} =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
        && length $cfg{table} <= 64;

  for my $key (qw( poll_interval lookback )) {
    croak "notify $key must be a positive number of seconds, got '$cfg{$key}'"
      unless looks_like_number($cfg{$key}) && $cfg{$key} > 0;
  }
  croak "notify lookback must be at least one microsecond, got '$cfg{lookback}'"
    if _micro($cfg{lookback}) < 1;

  croak "notify retention must be 0 (no cleanup) or a positive number of seconds, "
      . "got '$cfg{retention}'"
    unless looks_like_number($cfg{retention}) && $cfg{retention} >= 0;
  croak sprintf(
    'notify retention (%s s) must be greater than lookback plus poll interval '
  . '(%s s): a notification that commits late must still be there when the '
  . 'next poll looks for it',
    $cfg{retention}, $cfg{lookback} + $cfg{poll_interval},
  ) if $cfg{retention} > 0 && $cfg{retention} <= $cfg{lookback} + $cfg{poll_interval};

  croak "notify cleanup_limit must be a positive integer, got '$cfg{cleanup_limit}'"
    unless defined $cfg{cleanup_limit} && $cfg{cleanup_limit} =~ /\A[1-9][0-9]*\z/;

  return bless {
    %cfg,
    channels   => {},   # channel => { mark, cutoff, seen }
    cleanup_in => 1,    # polls until the next cleanup: due after the first
  }, $class;
}


sub defaults { return %DEFAULTS }


sub quoted_table { return '`' . $_[0]->{table} . '`' }


sub check_channel {
  my ($self, $channel) = @_;
  croak 'a notify channel name must be a non-empty string'
    unless defined $channel && !ref $channel && length $channel;
  croak sprintf(
    "notify channel name '%s...' is %d characters long; the notify table holds "
  . "at most $MAX_CHANNEL -- refused rather than truncated",
    substr($channel, 0, 20), length $channel,
  ) if length $channel > $MAX_CHANNEL;
  return $channel;
}


sub create_table_sql {
  my ($self) = @_;
  my $t = $self->quoted_table;
  return <<"SQL";
CREATE TABLE IF NOT EXISTS $t (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `channel`    VARCHAR($MAX_CHANNEL) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `payload`    TEXT CHARACTER SET utf8mb4 NOT NULL,
  `pid`        BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `channel_id` (`channel`, `id`),
  KEY `channel_created_at` (`channel`, `created_at`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL
}


sub drop_table_sql { return 'DROP TABLE IF EXISTS ' . $_[0]->quoted_table }


sub notify_sql {
  my ($self, $channel, $payload) = @_;
  $self->check_channel($channel);
  $payload = defined $payload ? "$payload" : '';

  my $bytes = $payload;
  utf8::upgrade($bytes);
  utf8::encode($bytes);
  croak sprintf(
    'notify payload is %d bytes long in UTF-8; the notify table holds at most '
  . "$MAX_PAYLOAD -- refused rather than truncated",
    length $bytes,
  ) if length $bytes > $MAX_PAYLOAD;

  return (
    'INSERT INTO ' . $self->quoted_table
  . ' (`channel`, `payload`, `pid`, `created_at`)'
  . ' VALUES (?, ?, CONNECTION_ID(), UTC_TIMESTAMP(6))',
    [ $channel, $payload ],
  );
}


sub subscribe_sql {
  my ($self, $channel) = @_;
  $self->check_channel($channel);
  my $t  = $self->quoted_table;
  my $us = _micro($self->{lookback});
  return (
    "SELECT `id`, NULL, NULL, NULL, NULL FROM $t"
  . " WHERE `channel` = ? AND `created_at` >= UTC_TIMESTAMP(6) - INTERVAL $us MICROSECOND"
  . " UNION ALL SELECT (SELECT COALESCE(MAX(`id`), 0) FROM $t WHERE `channel` = ?),"
  . ' NULL, NULL, NULL, ' . _cutoff_sql($us),
    [ $channel, $channel ],
  );
}


sub subscribed {
  my ($self, $channel, $rows) = @_;
  my ($meta) = grep { ref $_ eq 'ARRAY' && defined $_->[4] } @{ $rows || [] }
    or croak "the subscribe statement for channel '$channel' returned no mark row";

  $self->{channels}{$channel} = {
    mark   => defined $meta->[0] ? "$meta->[0]" : '0',
    cutoff => "$meta->[4]",
    seen   => { map { ("$_->[0]" => 1) } grep { !defined $_->[4] } @$rows },
  };
  return;
}


sub unsubscribe {
  my ($self, $channel) = @_;
  delete $self->{channels}{$channel} if defined $channel;
  return;
}


sub channels { return sort keys %{ $_[0]->{channels} } }


sub poll_sql {
  my ($self) = @_;
  my @channels = $self->channels or return;

  my (@by_id, @by_time, @bind_id, @bind_time, %token);
  for my $channel (@channels) {
    my $state = $self->{channels}{$channel};
    push @by_id,     '(`channel` = ? AND `id` > CAST(? AS UNSIGNED))';
    push @bind_id,   $channel, $state->{mark};
    push @by_time,   '(`channel` = ? AND `created_at` >= CAST(? AS DATETIME(6)))';
    push @bind_time, $channel, $state->{cutoff};
    $token{$channel} = $state;
  }

  my $t    = $self->quoted_table;
  my $cols = '`id`, `channel`, `payload`, `pid`, NULL';
  return (
    "SELECT $cols FROM $t WHERE " . join(' OR ', @by_id)
  . " UNION ALL SELECT $cols FROM $t WHERE " . join(' OR ', @by_time)
  . ' UNION ALL SELECT NULL, NULL, NULL, NULL, ' . _cutoff_sql(_micro($self->{lookback})),
    [ @bind_id, @bind_time ],
    \%token,
  );
}


sub polled {
  my ($self, $token, $rows) = @_;
  my ($cutoff) = map { "$_->[4]" } grep { ref $_ eq 'ARRAY' && defined $_->[4] } @{ $rows || [] }
    or croak 'the poll statement returned no cutoff row';

  my %got;   # channel => id => row
  for my $row (grep { !defined $_->[4] } @$rows) {
    my ($id, $channel) = @$row;
    next unless defined $channel && exists $token->{$channel};
    $got{$channel}{"$id"} //= $row;
  }

  my @new;
  for my $channel (keys %$token) {
    my $state   = $token->{$channel};
    my $current = $self->{channels}{$channel};
    next unless $current && refaddr($current) == refaddr($state);

    my $rows_now = $got{$channel} || {};
    for my $id (keys %$rows_now) {
      push @new, $rows_now->{$id} unless $state->{seen}{$id};
      $state->{mark} = $id if _id_cmp($id, $state->{mark}) > 0;
    }
    $state->{seen}   = { map { ($_ => 1) } keys %$rows_now };
    $state->{cutoff} = $cutoff if $cutoff gt $state->{cutoff};
  }

  $self->{cleanup_in}--;
  return [
    map  { [ "$_->[1]", $_->[2] // '', $_->[3] ] }
    sort { _id_cmp("$a->[0]", "$b->[0]") } @new
  ];
}


sub cleanup_sql {
  my ($self) = @_;
  return unless $self->{retention} > 0 && $self->{cleanup_in} <= 0;
  my $us = _micro($self->{retention});
  return (
    'DELETE FROM ' . $self->quoted_table
  . " WHERE `created_at` < UTC_TIMESTAMP(6) - INTERVAL $us MICROSECOND"
  . " LIMIT $self->{cleanup_limit}",
    [],
  );
}


sub cleaned {
  my ($self, $affected) = @_;
  $self->{cleanup_in} =
    (defined $affected && $affected >= $self->{cleanup_limit}) ? 0 : $self->_cleanup_every;
  return;
}

sub _cleanup_every {
  my ($self) = @_;
  my $polls = int($CLEANUP_PERIOD / $self->{poll_interval});
  $polls++ if $polls * $self->{poll_interval} < $CLEANUP_PERIOD;
  return $polls > 1 ? $polls : 1;
}

# Seconds to whole microseconds, for INTERVAL ... MICROSECOND.
sub _micro { return int($_[0] * 1_000_000 + 0.5) }

# The next cutoff, formatted by the server: its clock, fixed width.
sub _cutoff_sql {
  my ($us) = @_;
  return "DATE_FORMAT(UTC_TIMESTAMP(6) - INTERVAL $us MICROSECOND, '$CUTOFF_FORMAT')";
}

# Compare two BIGINT UNSIGNED ids exactly, as the decimal strings they are.
sub _id_cmp { return length($_[0]) <=> length($_[1]) || $_[0] cmp $_[1] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::NotifyTable - LISTEN/NOTIFY emulated over a notify table for MySQL and MariaDB, without I/O

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::MySQL::NotifyTable;

  my $nt = DBIO::MySQL::NotifyTable->new(table => 'dbio_notify');

  # once, from a migration or a deploy script
  $dbh->do($nt->create_table_sql);

  # notify, inside any transaction -- delivered when it commits
  my ($sql, $bind) = $nt->notify_sql(jobs => 'wake up');
  $dbh->do($sql, undef, @$bind);

  # listen: one object per listen connection; the caller runs the statements
  my ($sql, $bind) = $nt->subscribe_sql('jobs');
  $nt->subscribed(jobs => $dbh->selectall_arrayref($sql, undef, @$bind));

  while (1) {
    sleep $nt->poll_interval;
    my ($sql, $bind, $token) = $nt->poll_sql or next;
    my $rows = $dbh->selectall_arrayref($sql, undef, @$bind);
    for my $n (@{ $nt->polled($token, $rows) }) {
      my ($channel, $payload, $sender_pid) = @$n;
      ...
    }
    if (my ($sql, $bind) = $nt->cleanup_sql) {
      $nt->cleaned($dbh->do($sql, undef, @$bind));
    }
  }

=head1 DESCRIPTION

MySQL and MariaDB have no C<LISTEN> / C<NOTIFY>: no server push, and neither
L<DBD::mysql>, L<DBD::MariaDB> nor L<EV::MariaDB> offers a notification API.
This class B<emulates> the core async contract (core ADR 0056) with a table and
polling: C<notify> inserts a row, and a listener polls the table on a timer for
rows that are new to it. It is the part both MySQL async transports share --
the C<future_io> transport in this dist (L<DBIO::MySQL::Storage::Async>) and the
C<ev> transport in C<dbio-mysql-ev> -- and it does B<no I/O> at all: it builds
SQL with its bind values, and it folds the rows a statement returned into its
state. Running the statements (DBI, an async DBD binding, EV::MariaDB
callbacks), the timer and the connection belong to the transport. The design
and its reasons are recorded in this dist's ADR 0008.

Channel names and payloads only ever travel as bind values (core ADR 0017
section 3); the table name is validated as a plain identifier and quoted.

=head2 What a listener gets

=over 4

=item * B<Latency is the poll interval.> A notification is seen by the first
poll after it became visible, not pushed.

=item * B<Delivery on commit.> The row a C<notify> inserts becomes visible when
the transaction that inserted it commits -- the moment PostgreSQL delivers a
C<NOTIFY> too. A rolled-back notification is never delivered.

=item * B<No history.> Subscribing takes a mark: nothing already visible at
that moment is delivered. A notification whose transaction was still open when
the channel was subscribed B<is> delivered once it commits, as with
PostgreSQL.

=item * B<Exactly once, in id order within a poll.> Out-of-order commits are
caught (see L</How the out-of-order commit is caught>) and a notification is
never delivered twice to the same subscription. Across polls the order is the
order in which notifications became visible.

=item * B<Not durable.> The state lives in the object -- one object per listen
connection. A new connection takes a new mark, so whatever was committed while
no connection was listening is not delivered, which is PostgreSQL's behaviour
and what core's C<on_listen_reconnect> hook is for.

=item * An C<undef> payload arrives as C<''> (PostgreSQL has no NULL payload
either). C<$sender_pid> is the C<CONNECTION_ID()> of the notifying session.

=back

=head2 How the out-of-order commit is caught

C<AUTO_INCREMENT> ids are handed out when a row is inserted, but the row
becomes visible when its transaction commits. Transaction A takes id 10,
transaction B takes id 11 and commits first: a poll sees 11, and a listener
that only asks for C<< id > mark >> would never see 10 once A commits.

So a poll asks, per subscribed channel, for rows with C<< id > mark >> B<or>
C<< created_at >= cutoff >> -- the rows above the mark plus a B<lookback
window> of recent rows -- and remembers the ids it got back. A row it did not
get back last time is new; one it did is not. The mark only rises, and the
cutoff is the server's C<UTC_TIMESTAMP(6)> minus L</lookback> as of the
channel's B<previous> poll, and only rises too: a row that has left the window
never comes back into it, which is what makes the remembered set exact and
keeps it no larger than the window.

The one limit: a notification is B<lost> when its transaction commits more than
L</lookback> seconds after its C<INSERT> statement started B<and> a
notification with a higher id on the same channel was delivered in the
meantime. Commit within the lookback and it is delivered, whatever else
happened; no later notification delivered on that channel and it is delivered
however long the transaction took (as long as L</retention> keeps the row).
The clock is the server's -- C<created_at> is written and compared as UTC by
the server -- so neither the client clock nor a session C<time_zone> is
involved; a server clock that jumps forward shortens the window by the jump.

=head2 Retention

Every listener deletes rows older than L</retention> seconds: at most one
C<DELETE ... LIMIT> L</cleanup_limit> per minute, or on the next poll again
while a run deletes a whole batch, so a backlog is worked off in bounded steps.
A range C<DELETE> takes InnoDB next-key locks; it walks the C<created_at>
index, and a notify C<INSERT> waits for it only when the delete reaches the end
of that index -- for the length of one bounded, autocommitted statement. The
listener's database account therefore needs C<DELETE> on the table, besides
C<SELECT>; a notifier needs C<INSERT>. A retention of C<0> turns the cleanup
off, for a deployment that prunes the table itself.

Retention must exceed L</lookback> plus L</poll_interval>, so a notification
that commits late is still there when the next poll looks for it. A listener
whose polling stalls for longer than the retention may find rows it had not
seen deleted by another listener's cleanup.

=head1 ATTRIBUTES

=head2 table

The notify table's name, a plain identifier. Default C<dbio_notify>.

=head2 poll_interval

Seconds between two polls. The latency of a notification. Default 1.

=head2 lookback

Seconds a notification's transaction may stay open between its C<INSERT> and
its C<COMMIT> and still be delivered when a later notification on the same
channel was delivered first (see L</How the out-of-order commit is caught>).
Each poll re-reads this window of the subscribed channels. Default 60.

=head2 retention

Seconds a row is kept before a listener's cleanup deletes it; C<0> turns the
cleanup off. Default 3600.

=head2 cleanup_limit

Rows one cleanup statement deletes at most. Default 1000.

=head1 METHODS

=head2 new

  my $nt = DBIO::MySQL::NotifyTable->new(%config);

Validates the configuration and croaks on anything invalid, naming it: an
unknown key, a table name that is not a plain identifier of at most 64
characters (C<[A-Za-z_][A-Za-z0-9_]*>), a non-positive L</poll_interval> or
L</lookback>, a negative L</retention> or one not greater than L</lookback>
plus L</poll_interval>, a L</cleanup_limit> that is not a positive integer.
Every key is optional; see L</defaults>.

=head2 defaults

  my %defaults = DBIO::MySQL::NotifyTable->defaults;

The configuration L</new> falls back to: C<table> C<dbio_notify>,
C<poll_interval> 1, C<lookback> 60, C<retention> 3600, C<cleanup_limit> 1000.
A transport seeds its own configuration accessors from here, so the defaults
live in one place.

=head2 quoted_table

  my $sql_ident = $nt->quoted_table;   # `dbio_notify`

The validated table name, backtick-quoted, as it appears in every statement.

=head2 check_channel

  $nt->check_channel($channel);

Returns the channel, or croaks when it cannot be one: C<undef>, a reference,
the empty string, or longer than 255 characters -- refused rather than
truncated, because a non-strict C<sql_mode> would silently shorten it on the
way in and it would then never match the name it was sent under.

=head2 create_table_sql

  my $ddl = $nt->create_table_sql;

The C<CREATE TABLE IF NOT EXISTS> statement for the table (see L</THE TABLE>).
Nothing in this class or the transports runs it on its own; MySQL commits
implicitly around DDL, so run it outside any transaction.

=head2 drop_table_sql

  my $sql = $nt->drop_table_sql;   # DROP TABLE IF EXISTS `dbio_notify`

=head2 notify_sql

  my ($sql, $bind) = $nt->notify_sql($channel, $payload);

The C<INSERT> of one notification: channel and payload as bind values, the
sender as C<CONNECTION_ID()>, the time as C<UTC_TIMESTAMP(6)>. Run it inside a
transaction to have it delivered when that transaction commits. An C<undef>
payload is sent as C<''>. Croaks on a channel L</check_channel> refuses and on
a payload over 65535 bytes in UTF-8, the size of the C<TEXT> column, for the
same reason as an over-long channel.

=head2 subscribe_sql

  my ($sql, $bind) = $nt->subscribe_sql($channel);

The statement that takes the mark for a channel: the channel's rows inside the
lookback window as it stands now, and one more row carrying the channel's
highest id and the window's cutoff. Croaks on a channel L</check_channel>
refuses. Hand its rows to L</subscribed>.

=head2 subscribed

  $nt->subscribed($channel, \@rows);

Fold the rows of L</subscribe_sql> into the state: from now on the channel is
polled, and only what was not visible to that statement is delivered. Replaces
any earlier subscription of the channel. Croaks on rows that lack the mark row.

=head2 unsubscribe

  $nt->unsubscribe($channel);

Stop polling a channel. Local bookkeeping, no statement. Rows for it that a
poll already in flight returns are dropped by L</polled>.

=head2 channels

  my @channels = $nt->channels;   # sorted

=head2 poll_sql

  my ($sql, $bind, $token) = $nt->poll_sql;   # () with nothing subscribed

The poll statement over every subscribed channel: its rows above its mark, its
rows inside its lookback window, and one row carrying the next cutoff. Pass
C<$token> back to L</polled> with the rows; it records which subscriptions the
statement was built for.

=head2 polled

  my $notifications = $nt->polled($token, \@rows);
  # [ [ $channel, $payload, $sender_pid ], ... ]

Fold the rows of a L</poll_sql> statement into the state and return what is
new, in id order, in the contract order C<[$channel, $payload, $sender_pid]>.
Rows are matched to channels exactly (the column's collation pads trailing
spaces); rows for a channel that was unsubscribed -- or unsubscribed and
subscribed again -- since the statement was built are dropped, and so is its
bookkeeping for them. Croaks on rows that lack the cutoff row. Counts one poll
towards the next cleanup.

=head2 cleanup_sql

  my ($sql, $bind) = $nt->cleanup_sql;   # () when not due

The retention C<DELETE> (see L</Retention>), when one is due: on the first
poll, then once a minute of polling, and on the very next poll while the last
one deleted a whole batch. An empty list when none is due or the retention is
C<0>. Report its outcome to L</cleaned>.

=head2 cleaned

  $nt->cleaned($affected);   # undef when the statement failed

Record a cleanup run: a full batch makes the next poll clean up again,
anything else waits for the next period.

=head1 THE TABLE

  CREATE TABLE IF NOT EXISTS `dbio_notify` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `channel`    VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    `payload`    TEXT CHARACTER SET utf8mb4 NOT NULL,
    `pid`        BIGINT UNSIGNED NOT NULL,
    `created_at` DATETIME(6) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `channel_id` (`channel`, `id`),
    KEY `channel_created_at` (`channel`, `created_at`),
    KEY `created_at` (`created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

The table is B<never created implicitly> -- deploy it once (L</create_table_sql>,
or C<deploy_notify_table> on the async storage). Until it exists, subscribing
fails with a message saying so. C<created_at> is a C<DATETIME(6)> written as
C<UTC_TIMESTAMP(6)>, not a C<TIMESTAMP>, so sessions with different
C<time_zone> settings agree on it. C<channel> is compared case-sensitively
(C<utf8mb4_bin>); that collation pads trailing spaces in SQL comparisons, so
the rows a poll returns are matched to the subscribed channel names exactly, in
Perl. All statements run unchanged on MySQL 8.0 and MariaDB 10.6 and later.

=head1 USING IT FROM A TRANSPORT

Keep one object per B<listen connection> and drop it with the connection.
Statements run on one connection at a time, in the order the transport issues
them; any connection sees the committed rows, but the subscribe and poll
statements of one object belong on its listen connection, so that their failure
means that connection's failure.

=over 4

=item * C<listen> -- run L</subscribe_sql> for the channel and hand its rows to
L</subscribed> B<before> reporting the subscription in effect: the mark is
taken there.

=item * C<unlisten> -- L</unsubscribe>, no statement.

=item * each tick -- run L</poll_sql> (nothing to run when it returns an empty
list), hand the rows to L</polled> with the token it returned, deliver what
comes back in order. A failed poll statement means a dead connection. Then, if
L</cleanup_sql> returns a statement, run it and report the affected row count
to L</cleaned> -- C<undef> when it failed, which is worth reporting but not a
reason to drop the connection.

=item * C<notify> -- L</notify_sql>, on any connection.

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
