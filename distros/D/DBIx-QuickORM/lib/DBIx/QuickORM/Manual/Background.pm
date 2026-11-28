package DBIx::QuickORM::Manual::Background;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Background - Run queries in the background with async, aside, and forked, by example.

=head1 DESCRIPTION

C<async>, C<aside>, and C<forked> are handle modifiers. The first read
(C<iter>, C<ready>, or another) then starts the query without waiting.
Reading the rows waits for them.

=head1 SCHEMA

The examples use PostgreSQL and this schema:

=for highlighter language=sql

    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

=head1 ASYNC

=for highlighter language=perl

    my $it = $orm->handle('posts')
        ->order_by('id')
        ->async
        ->iter;    # the query starts, and iter returns at once

    do_something_else() until $it->ready;    # polls, and collects the result when ready

    my @posts = $it->all;

The query runs on the ORM's own connection. Until the iterator collects its
rows (C<ready> finding them, or any reading method), anything else that sends
SQL on that connection croaks:

    my $pending = $orm->handle('posts')->async->iter;

    # croaks: an async query is pending on this connection
    my $count = eval { $orm->handle('users')->count };

    my @rows = $pending->all;    # collected, and the connection is free again

A C<find> answered from the canonical copy still works meanwhile
(L<DBIx::QuickORM::Manual::Caching>).

Discard the handle and every iterator over its query before the rows are
collected and the query is given up: PostgreSQL is asked to cancel it, while
MySQL and MariaDB wait for the result and discard it
(L<DBIx::QuickORM::Manual::Dialects>). On PostgreSQL, giving a query up inside
a transaction aborts that transaction.

=head1 ASIDE

C<aside> is like C<async>, but runs on a second connection, so the ORM's own
connection stays free. It cannot be used inside a transaction. You can start
it, run a whole transaction on the main connection, then read its rows once
the transaction is done (L</AND TRANSACTIONS>).

    my $aside = $orm->handle('posts')->aside->iter;    # on a second connection
    my $count = $orm->handle('users')->count;          # the ORM's own connection is free meanwhile
    my @posts = $aside->all;                           # the second connection closes

=head1 FORKED

C<forked> is like C<async> and C<aside>, but runs in a separate child
process, on that process's own connection.

    # in a child process, on its own connection
    my $forked = $orm->handle('posts')->forked->iter;
    my $count  = $orm->handle('users')->count;
    my @posts  = $forked->all;    # the child sent the rows and exited

C<forked> needs no async support from the database, only a second
connection, so it also works on a SQLite file.

=head1 ON THE HANDLE OR A NEW ITERATOR

    my $h = $orm->handle('users')->async;
    do_something_else() until $h->ready;    # the first call starts the query
    my @users = $h->all;                    # that same query's rows

    my $it = $h->iter;    # a new iterator over the same query
    $h->clear;            # the next read starts another query

A handle runs one query, started by its first read (C<iter> included), and
sends it once. Its reading methods and every iterator share that one
response, and collecting through any of them collects for all. Each iterator
keeps its own position. Each read builds a new row object, but the row
objects for one row all wrap the same row data hash. (With C<data_only> or
C<row_class(undef)>, every read hands out that hash itself.) C<clear> forgets
the query.

With C<async>, starting a query croaks while another is pending on the
connection.

=head1 AND TRANSACTIONS

    # aside and forked: start before the transaction, read after it
    my $posts = $orm->handle('posts')->aside->iter;

    $orm->txn(sub {
        $orm->insert(users => {name => 'Zoe'});    # another table meanwhile

        my @mine = $orm->handle('posts')
            ->async
            ->iter
            ->all;    # async: the transaction's own connection, sees its writes
    });

    my @posts = $posts->all;

    # croaks: aside and forked cannot start, or be read, inside a transaction
    my $ok = eval {
        $orm->txn(sub { $orm->handle('posts')->aside->iter });
        1;
    };

C<async> runs on the ORM's own connection, so inside a transaction it works
like any query: it sees the transaction's writes.

C<aside> and C<forked> run on other connections. Starting one, or reading its
rows (C<ready> included), croaks while a transaction is open. One started
before a transaction may keep running during it. Read it after the
transaction ends.

Rows read then are ingested like any others, and may be stale if the
transaction changed the same rows. Reading one table in the background while
a short transaction writes another is fine.

Table rows with a primary key become canonical when collected, which
ordinary updates and deletes check by default
(L<DBIx::QuickORM::Row/"Keys and canonical data">,
L<DBIx::QuickORM::Manual::Caching>).

An explicit C<rollback> croaks while an async query is pending. When the
transaction unwinds by itself (its block died, or its object went out of
scope) the query is given up, and later reads from the iterator croak.

=head1 ERRORS

    # a scalar reference: a handle over SQL you write
    my $bad = $orm->handle(\'SELECT * FROM no_such_table')->async->iter;

    # the database error is thrown here, and again on every later read
    my $rows = eval { [$bad->all] };

A forked child's error arrives the same way, as C<The forked query failed: ...>.
L<DBIx::QuickORM::Manual::Errors> covers database errors.

=head1 FORKING YOUR OWN PROCESS

    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $count = $orm->handle('users')->count;    # the ORM reconnects in the child by itself
        exit($count ? 0 : 1);
    }
    waitpid($pid, 0);

Rows the child inherited are not canonical there: refresh one before writing
it (L<DBIx::QuickORM::Manual::Caching>). A pending iterator from the parent
cannot be collected in the child. On an ORM given a C<dbh>, on DuckDB, or on
an in-memory SQLite database the child cannot reconnect, and croaks.

=head1 BACKEND SUPPORT

    my $it = $orm->handle('posts')
        ->order_by('id')
        ->maybe_async
        ->iter;    # async where the database can, otherwise an ordinary query

    do_something_else() until $it->ready;    # the same iterator API either way
    my @rows = $it->all;

When the mode cannot run, C<maybe_async>, C<maybe_aside>, and C<maybe_forked>
leave the handle as it was: an ordinary handle runs an ordinary query on the
ORM's connection. Inside a transaction that query sees the
transaction's own uncommitted writes, where C<aside> and C<forked> croak.
C<can_async>, C<can_aside>, and C<can_forked> ask first.
L<DBIx::QuickORM::Manual::Dialects> has the other differences.

=over 4

=item C<async> and C<aside>

PostgreSQL, MySQL, and MariaDB. SQLite and DuckDB croak.

=item C<forked>

Any database a second connection can reach: not DuckDB, and not an in-memory
SQLite database.

=item An ORM given a C<dbh>

It cannot open a second connection, so C<aside> and C<forked> croak, and a
forked child cannot use the ORM.

=back

=cut

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
