package DBIO::MySQL::EV::TestHarness;
# ABSTRACT: Reusable live-MySQL harness for EV async on_connect-replay tests

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::AsyncHarness';

use namespace::clean;


__PACKAGE__->harness_env_prefix('DBIO_TEST_MYSQL');
__PACKAGE__->harness_async_mode('ev');
__PACKAGE__->harness_required_modules([qw( EV EV::MariaDB )]);
__PACKAGE__->harness_schema_class('DBIO::MySQL::EV::TestHarness::_Schema');

# The default schema class used when the caller supplies none: an ordinary sync
# MySQL schema. Its MySQL component declares DBIO::MySQL::Storage at connect,
# and that storage registers the 'ev' async mode; no result sources are needed
# because the harness exercises connection-level SQL, not the ORM.
#
# 'MySQL::EV' is loaded ALONGSIDE the driver component deliberately, and is not
# what makes the connection async -- { async => 'ev' } at connect is (ADR 0030).
# DBIO::MySQL::EV is an inert marker (ADR 0032 section 7, karr k14): it defines
# no methods and no connection() hook, so loading it must change nothing. Doing
# it here is the one place that claim is exercised against a REAL server -- a
# marker that ever regained a storage_type pin would break these live tests, not
# just the offline guard in t/00-load.t. Core's DBIO::Test::AsyncHarness has no
# default schema of its own precisely because this choice is per driver.
{
  package DBIO::MySQL::EV::TestHarness::_Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}


sub new {
  my ($class, %opts) = @_;
  my $schema_class = $opts{schema_class}
    // $class->_harness_declaration('harness_schema_class');
  $opts{storage_type} //= 'DBIO::MySQL::Storage'
    if _declares_no_driver($schema_class);
  return $class->SUPER::new(%opts);
}

# Core's reading of storage_type (DBIO::Schema::connection): a schema class
# whose storage class resolves to the generic DBIO::Storage::DBI declares no
# driver (ADR 0067). Inlined because a core before ADR 0067 has no helper for
# it. A class that is no schema is left to core to refuse.
sub _declares_no_driver {
  my ($schema_class) = @_;
  return 0 unless defined $schema_class && $schema_class->can('storage_type');
  my $storage_type = $schema_class->storage_type;
  my ($storage_class) = ref $storage_type
    ? $schema_class->_normalize_storage_type($storage_type)
    : ($storage_type);
  $storage_class =~ s/^\+//;
  $storage_class =~ s/^::/DBIO::Storage::/;
  return $storage_class eq 'DBIO::Storage::DBI';
}


sub _tick_loop {
  require EV;
  EV::run(EV::RUN_ONCE());
}

my %SESSION_SUM;
my $COUNTING;
my @SESSION_COUNTERS = qw( Com_begin Com_commit Com_rollback Com_stmt_prepare Com_stmt_close );
my $SESSION_SQL = 'SHOW SESSION STATUS WHERE Variable_name IN ('
  . join(', ', map { "'$_'" } @SESSION_COUNTERS) . ')';

sub count_session_status {
  return if $COUNTING++;
  require DBIO::MySQL::EV::Storage;
  no warnings 'redefine';
  my $orig = \&DBIO::MySQL::EV::Storage::_reset_pool_connection;
  *DBIO::MySQL::EV::Storage::_reset_pool_connection = sub {
    my ($self, $conn) = @_;
    my $tid = eval { $conn->thread_id };

    # EV::MariaDB takes no reset behind a query queued on the wire, so the
    # reading is answered first and the reset follows from an idle watcher
    # (outside the callback, like every settling of the transport). A handle
    # with a statement in flight is reset as it is.
    return $self->$orig($conn) unless defined $tid && !eval { $conn->pending_count };

    my $outer = $self->future_class->new;
    my ($ok, $idle, $held);
    my $reset = sub {
      $idle = EV::idle(sub {
        undef $idle;
        my $f = $held = eval { $self->$orig($conn) } || $self->future_class->fail($@);
        $f->on_ready(sub {
          my ($inner) = @_;
          undef $held;
          $inner->is_cancelled ? $outer->cancel
            : $inner->is_failed ? $outer->fail($inner->failure)
            : $outer->done($inner->get);
        });
      });
    };
    $ok = eval {
      $conn->query($SESSION_SQL, sub {
        my ($rows, $err) = @_;
        $SESSION_SUM{$tid}{ $_->[0] } += $_->[1] for $err ? () : @{ $rows || [] };
        $reset->();
      });
      1;
    };
    $reset->() unless $ok;
    return $outer;
  };
  return;
}

sub session_status {
  my ($self, $conn) = @_;
  require Time::HiRes;
  my $tick = EV::timer(0.02, 0.02, sub {});   # RUN_ONCE never blocks for long
  my $deadline = Time::HiRes::time() + 10;
  my $busy = sub {
    return $self->pool->_connection_is_resetting($conn) || eval { $conn->pending_count };
  };
  while ($busy->()) {
    return if Time::HiRes::time() > $deadline;
    $self->_tick_loop;
  }

  my $tid = eval { $conn->thread_id } // return;
  my ($rows, $err, $done);
  eval { $conn->query($SESSION_SQL, sub { ($rows, $err) = @_; $done = 1 }); 1 } or return;
  until ($done) {
    return if Time::HiRes::time() > $deadline;
    $self->_tick_loop;
  }
  return if $err || !$rows;

  my %status = map { ($_ => $SESSION_SUM{$tid}{$_} // 0) } @SESSION_COUNTERS;
  $status{ $_->[0] } += $_->[1] for @$rows;
  return \%status;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::TestHarness - Reusable live-MySQL harness for EV async on_connect-replay tests

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use Test::More;
  use DBIO::MySQL::EV::TestHarness;

  # Skip the whole file cleanly unless a live MySQL DSN + EV::MariaDB are available.
  DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

  my $h = DBIO::MySQL::EV::TestHarness->new(
      # each fresh pool connection replays these against the owning sync storage
      connect_attrs => {
          on_connect_do => [ q{SET @dbio_replay_tag = 'live'} ],
          pool_size     => 4,
      },
  );

  # Force 3 DISTINCT pool connections to spawn (each replays the connect
  # actions at spawn) and run an async op on each -- the replay-verification seam.
  my @tags = $h->run_on_each_pooled_connection(3, sub {
      my ($conn, $harness) = @_;
      return $harness->query_on($conn, q{SELECT @dbio_replay_tag});
  });
  is $_->[0][0], 'live', 'connect action replayed on this pooled connection'
      for @tags;

  $h->disconnect;

  # A schema class without a driver gets the MySQL driver ...
  my $shared = DBIO::MySQL::EV::TestHarness->new(
      schema_class => 'DBIO::Test::Schema',
  );

  # ... or the storage_type passed here.
  my $mariadb = DBIO::MySQL::EV::TestHarness->new(
      schema_class => 'DBIO::Test::Schema',
      storage_type => 'DBIO::MySQL::Storage::MariaDB',
  );

  done_testing;

=head1 DESCRIPTION

An B<installable> test harness for the native C<ev> async transport
(L<DBIO::MySQL::EV::Storage>). It removes the boilerplate every live EV test
repeats -- parse C<DBIO_TEST_MYSQL_DSN>, connect an C<< { async => 'ev' } >>
schema, reach the embedded async backend + its pool, drive the EV loop -- and,
crucially, provides the one thing an C<on_connect>-replay test needs and cannot
get from a directly-constructed storage: an EV async backend B<wired to an
owning sync storage> whose C<on_connect_do> / C<on_connect_call> actually replay
on every freshly-spawned pool connection.

None of that is MySQL-specific, so it is B<not implemented here>:
the whole surface -- L<DBIO::Test::AsyncHarness/live_available>,
L<DBIO::Test::AsyncHarness/skip_all_unless_live>, L<DBIO::Test::AsyncHarness/new>,
C<schema>, C<sync_storage>, C<async>, C<pool>, C<timeout>, C<await>, C<query_on>,
C<warm_pool>, C<run_on_each_pooled_connection> and C<disconnect> -- is inherited
from L<DBIO::Test::AsyncHarness>, which grew out of the two
copies C<dbio-postgresql-ev> and this distribution had each written by hand.
What is left here is what core cannot know: four declarations, the seam that
turns the EV loop, a default schema class, and the driver (L</new>).

The harness declares the MySQL driver itself (core ADR 0067 section 4: a
driver's test helper declares its own driver by default). A schema class that
declares no driver -- the shared L<DBIO::Test::Schema> -- is connected as a
clone with C<storage_type> L<DBIO::MySQL::Storage>, and the class itself stays
undeclared. A C<storage_type> passed to L</new> wins over that default.

It ships under C<lib/> (not C<t/>) on purpose: it is consumed both by this
distribution's own live tests B<and> by downstream extension distributions,
which cannot see another dist's C<t/lib>. An extension that carries a
develop/recommends dependency on L<DBIO::MySQL::EV> reaches this class from its
own C<t/>; see L<DBIO::Test::AsyncHarness/REUSE BY AN EXTENSION>.

=head1 METHODS

=head2 new

  my $h = DBIO::MySQL::EV::TestHarness->new(%opts);

L<DBIO::Test::AsyncHarness/new>, with the driver declared by default: when
C<schema_class> (or the default schema class) declares no driver -- its
C<storage_type> is the generic L<DBIO::Storage::DBI> -- and no C<storage_type>
is passed, C<storage_type> is L<DBIO::MySQL::Storage>. A passed C<storage_type>
is handed on as it is. A schema class that declares its driver is left alone:
its C<storage_type> (a storage subclass, a shortcut) stands. A driver
component such as L<DBIO::MySQL> sets its own storage class at connect, over
any C<storage_type> the harness hands on -- also over a passed one.

A core from before ADR 0067 ignores C<storage_type>; there the schema class is
connected as before.

=head2 _tick_loop

Turns the EV loop for one iteration -- the single transport-specific seam
L<DBIO::Test::AsyncHarness/await> drives until a Future is ready. L<EV> is
guaranteed loaded by then: it is in
L<DBIO::Test::AsyncHarness/harness_required_modules>, and
L<DBIO::Test::AsyncHarness/new> croaks unless every one of those loads.

=head2 session_status

  DBIO::MySQL::EV::TestHarness->count_session_status;   # once, before the first borrow
  my $status = $h->session_status($conn);               # { Com_stmt_prepare => 12, ... }

The status counters of the one session behind a pooled connection, from its
spawn on. The pool ends a borrow with C<COM_RESET_CONNECTION>, which sets a
session's counters back to zero (core ADR 0079), so a plain
C<SHOW SESSION STATUS> sees the current borrow only.
L</count_session_status> wraps the transport's
C<_reset_pool_connection>: it reads C<SHOW SESSION STATUS> on the connection
itself, right ahead of the reset on the same wire, and adds the reading up
per C<thread_id>. C<session_status> answers that sum plus the session's current
reading, for C<Com_begin>, C<Com_commit>, C<Com_rollback>, C<Com_stmt_prepare>
and C<Com_stmt_close>. Only the session's own statements are counted, so other
clients of the server do not move the numbers.

It waits (10 seconds at most) until the connection is out of its reset and has
nothing pending, then asks the handle past the pool. It returns undef when the
session cannot be asked.

=head2 count_session_status

Installs the wrapper L</session_status> relies on; idempotent, process wide.
Call it before the first connection is released.

=head1 CAVEAT

This is a B<live> harness: it opens real connections against
C<DBIO_TEST_MYSQL_DSN>. It is for driver/extension test suites, not production
code. It is excluded from the mock-only offline discipline by design -- gate
every consumer with L<DBIO::Test::AsyncHarness/skip_all_unless_live>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
