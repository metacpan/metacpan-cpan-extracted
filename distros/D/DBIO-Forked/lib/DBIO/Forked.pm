package DBIO::Forked;
our $VERSION = '0.900001';
# ABSTRACT: Dependency-free, fork-based async layer for DBIO drivers

use strict;
use warnings;

use base 'DBIO::Base';

# Loading the storage backend registers the generic 'forked' async mode on the
# core base storage class (ADR 0030), so that `use DBIO::Forked` is enough to
# make `connect(..., { async => 'forked' })` available on every driver.
use DBIO::Forked::Storage;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Forked - Dependency-free, fork-based async layer for DBIO drivers

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

See L<DBIO::Forked::Storage> for the storage backend and L<DBIO::Forked::Future>
for the loop-free Future.

=head1 DESCRIPTION

Dependency-free, fork-based async layer for L<DBIO> drivers. It makes B<any>
sync DBIO driver async without an async-capable database client and without an
event loop: each query runs in a C<fork()>ed child that speaks the ordinary
sync driver, and the result rows are streamed back to the parent over a pipe.
The parent returns a L<DBIO::Forked::Future> immediately.

C<DBIO::Forked> is a sibling of L<DBIO::Async> on the same layer -- both
satisfy the core L<DBIO::Storage::Async> contract -- but they take opposite
routes. L<DBIO::Async> drives a driver's B<own> async binding -- the non-blocking
interface a DBD such as L<DBD::Pg> (C<pg_async>) or L<DBD::mysql> (C<mysql_async>)
exposes itself -- through L<Future::IO>, so it works only for drivers that offer
one, but pulls in no extra client library. C<DBIO::Forked> uses C<fork()> + pipe
+ the plain sync driver in the child, so it works for B<every> driver, including
the ones that never expose an async binding (Oracle, SQLite, DB2, Sybase, ...).

=head1 ACTIVATION

Loading C<DBIO::Forked> registers a generic C<forked> async I<mode> on the core
base storage class (ADR 0030):

  DBIO::Storage::DBI->register_async_mode( forked => 'DBIO::Forked::Storage' );

so every DBIO driver inherits it. The user then opts a connection into it
per-connection, at C<connect> time:

  use DBIO::Forked;
  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'forked' });

A connection opened with C<< { async => 'forked' } >> answers the six
C<*_async> methods (and the C<*_async> helpers on ResultSet/Row) through
L<DBIO::Forked::Storage>; a connection opened without it stays fully synchronous
(its C<*_async> methods croak). There is no auto-selection -- the mode is
explicit or absent. The core resolver constructs
C<< DBIO::Forked::Storage->new($schema) >> as the embedded async backend; each
async query then forks a child that reconnects the sync driver fresh and runs
the ordinary sync CRUD before streaming the result back.

=head1 DEPENDENCY POSTURE

Only core Perl -- C<fork>, C<pipe>, L<Storable> (serialization), L<IO::Select>
(waiting) -- plus L<DBIO> core. No L<Future>, no L<Future::IO>, no event loop,
no async DB client. That is the whole point: turning a sync driver async pulls
in none of the async ecosystem.

=head1 EXECUTION MODEL

Model A -- one short-lived C<fork()> per query. The child inherits the entire
parent memory (including the real driver's sync storage), throws away the
inherited DBI handle (the fork trap that L<DBIO::Storage::DBI> already guards
against), reconnects fresh from the DBI-form connect info, runs the driver's
B<ordinary> sync CRUD (no SQL is re-implemented in C<DBIO::Forked>), serializes
the result rows back over the pipe with L<Storable>, and exits. The parent
returns a L<DBIO::Forked::Future> bound to the pipe read fd.

=head1 TRANSACTION SEMANTICS

Model A forks per unit of work, so a multi-statement transaction cannot be spread
across forks. C<txn_do_async> therefore runs the B<entire> transaction block in
B<one> C<fork()>ed child: the C<BEGIN>, every statement in the block, and the
final C<COMMIT>/C<ROLLBACK> all execute synchronously in that single child against
the freshly-reconnected sync driver. Only the block's overall result is streamed
back to the parent as a L<DBIO::Forked::Future>.

So C<DBIO::Forked> makes a transaction async at the granularity of the B<whole
block>, not of individual statements. From the parent's side the block is
non-blocking -- you get a Future immediately and the event loop (or other forks)
runs while the child works -- but B<inside> the transaction there are no loop
ticks between statements: the statements do not each return asynchronously, and
you cannot issue one statement, yield to the loop, and issue the next on the same
pinned transaction.

If you need genuine per-statement async transactions over a pinned connection
(send a statement non-blocking, let the loop do other work, then send the next),
use a connection-based backend instead -- L<DBIO::Async> (L<Future::IO> over the
driver's own async binding) or a native EV add-on (L<DBIO::PostgreSQL::EV>,
L<DBIO::MySQL::EV>) -- not C<DBIO::Forked>. This is an intrinsic property of
Model A, not a defect.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
