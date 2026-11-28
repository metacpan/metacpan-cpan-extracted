package DBIx::QuickORM::Manual::Transactions;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Transactions - Transactions, savepoints, retries, and the rows you hold, by example.

=head1 DESCRIPTION

C<< $orm->txn >> opens a transaction. One opened inside another is a
savepoint.

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

=head1 BLOCK FORM

=for highlighter language=perl

    $orm->txn(sub {
        my $ann = $orm->insert(users => {name => 'Ann'});
        $orm->insert(posts => {
            user_id => $ann->field('id'),
            title   => 'Hello',
        });
    });    # commits when the block returns

    my $ok = eval {
        $orm->txn(sub {
            $orm->insert(users => {name => 'Bob'});
            die "no\n";    # rolls back, and the exception is rethrown
        });
        1;
    };

    # returns what the block returns
    my $count = $orm->txn(sub { $orm->handle('users')->count });

    $orm->txn(sub {
        my $txn = shift;
        $orm->insert(users => {name => 'Cy'});
        # or commit: the transaction is over, and the rest of the block runs outside it
        $txn->rollback;
    });

=head1 OBJECT FORM

    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Di'});
    $txn->commit;

    my $undo = $orm->txn;
    $orm->insert(users => {name => 'Eve'});
    $undo->rollback;

C<commit> and C<rollback> end the transaction, not your code: what follows
them runs outside it. A transaction object that goes out of scope unfinished
is rolled back, with a warning saying where it was opened.

=head1 SAVEPOINTS

    $orm->txn(sub {
        $orm->insert(users => {name => 'Fay'});
        eval {
            $orm->txn(sub {
                $orm->insert(users => {name => 'Gus'});
                die "undo Gus only\n";
            });
        };
        $orm->insert(users => {name => 'Hal'});
    });    # Fay and Hal are committed, but Gus was rolled back with his savepoint

    my $outer = $orm->txn;
    my $inner = $orm->txn;    # a savepoint
    $orm->insert(users => {name => 'Ian'});
    $inner->rollback;         # the innermost open transaction has to finish first
    $outer->commit;           # without Ian

Committing or rolling back C<$outer> while C<$inner> is still open croaks.
DuckDB has no savepoints, so nesting croaks there
(L<DBIx::QuickORM::Manual::Dialects/TRANSACTIONS>).

=head1 A FAILED STATEMENT

    $orm->insert(users => {name => 'Lu', email => 'lu@example.com'});

    $orm->txn(sub {
        # the failure rolls back only the nested transaction
        my $dup = !eval {
            $orm->txn(sub {
                $orm->insert(users => {name => 'Lu2', email => 'lu@example.com'});
            });
            1;
        };
        $orm->insert(users => {name => 'Mo'});
    });    # Mo is committed

    my $ok = eval {
        $orm->txn(sub {
            $orm->insert(users => {name => 'Ned'});
            # caught, but the failure marks the transaction failed
            eval { $orm->insert(users => {name => 'Ned2', email => 'lu@example.com'}) };
        });    # croaks: the commit rolls back instead, so Ned is gone too
        1;
    };

A statement that fails inside a transaction marks it failed, even when your
code catches the error. From then on every statement croaks, except the
rollback. A commit rolls back instead, then croaks. This holds on every
database, so no failed work is ever taken for committed.

To recover and go on, run the work that may fail in a nested transaction.
Rolling back the savepoint clears the mark. The block form does that when
the exception leaves it. C<find_or_insert> does this itself. DuckDB has no
savepoints, so there a failure leaves the transaction nothing but its
rollback.

=head1 ISOLATION

    # every outermost transaction opens at read committed unless told otherwise
    $orm->txn(sub { $orm->insert(users => {name => 'Kim'}) });

    # one transaction at another level
    my $total = $orm->txn(
        sub { $orm->handle('posts')->count },
        isolation => 'repeatable read',
    );

    # another default for every transaction of this ORM
    my $strict = DBIx::QuickORM->new(
        connect   => sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) },
        isolation => 'serializable',
    );

    # a plain BEGIN: the database's own default level
    $orm->txn(sub { $orm->handle('users')->count }, isolation => 'server');

Every outermost transaction states its isolation level when it opens. The
default is C<read committed> on every database that can set a level, so a
transaction behaves the same on PostgreSQL and the MySQL family, whose
servers default to different levels. Stating it each time also means a
changed server or session setting cannot change it.

The levels are C<read uncommitted>, C<read committed>, C<repeatable read>,
and C<serializable>, in upper or lower case. C<server> sends a plain C<BEGIN>
and leaves the level to the database. Anything else croaks.

The level comes from the C<txn> call's C<isolation>, else the ORM's
C<isolation> (C<new> argument, or C<override> in the DSL), else C<read
committed>. Only an outermost transaction takes one. A savepoint runs at its
transaction's level. A retried block begins at the same level each time.

What each database is sent, and its own default:

=over 4

=item PostgreSQL

C<BEGIN ISOLATION LEVEL READ COMMITTED>, one statement. The server's default
is C<read committed>. C<read uncommitted> runs as C<read committed>.

=item MySQL and MariaDB

C<SET TRANSACTION ISOLATION LEVEL READ COMMITTED>, then C<BEGIN>. The SET
covers the next transaction only. The server's default is C<repeatable
read>.

=item SQLite

C<BEGIN>. SQLite has no level to set: its transactions are serializable.

=item DuckDB

C<BEGIN>. DuckDB has no level to set: its transactions use snapshot
isolation.

=back

On SQLite and DuckDB the default sends nothing extra. There, leave
C<isolation> out or give C<server>: naming any level, C<read committed>
included, croaks when a transaction opens, whether the C<txn> call or the ORM
names it.

The MySQL family with binary logging on and C<binlog_format=STATEMENT>:
InnoDB refuses writes at C<read committed> and C<read uncommitted>, since
statement-based logging needs C<repeatable read>. Use C<ROW> (MySQL's
default) or C<MIXED> (MariaDB's), or give the ORM
C<< isolation => 'repeatable read' >>.

=head1 RETRY

    use DBIx::QuickORM::Value qw/sql/;

    my $post_id = $orm->handle('posts')->only->field('id');

    $orm->txn(
        sub {
            my $post = $orm->find(posts => $post_id);
            $post->update({views => $post->field('views') + 1});
        },
        # the database reports a conflicting write as a serialization failure
        isolation => 'serializable',
        retry     => 3,    # then the block runs again, up to 3 more times
    );

    my $post = $orm->find(posts => $post_id);

    # the database does the arithmetic, so concurrent increments all count
    $post->update({views => sql('views + 1')});

Only an outermost transaction can be retried, and the block must be safe to
run again. C<< retry => 3 >> allows four attempts. The last failure is
rethrown. L<DBIx::QuickORM::Manual::Errors> shows which errors count.

At the default C<read committed> level a read-then-write like this does not
fail: the second writer silently overwrites the first. C<isolation>
makes the database notice the conflict. Better, let the database do the
arithmetic with C<sql()> (L<DBIx::QuickORM::Manual::Values>), or use
C<cas_update> (below) when the new value depends on what was read.

=head1 THE ROWS YOU HOLD

C<< $row->is_canon >> asks whether a row object's data is the ORM's canonical
copy of its row (L<DBIx::QuickORM::Manual::Caching>).

    my $post = $orm->find(posts => $post_id);    # canonical: the ORM's cached copy of the row

    my ($before, $inside);
    $orm->txn(sub {
        # false: a row read before the transaction is not canonical inside it
        $before = $post->is_canon;

        # read again: the database holds the same data, so $post's copy is reused
        my $same = $orm->find(posts => $post_id);
        $inside = $post->is_canon;    # true
    });

    my $after = $post->is_canon;    # true: the commit kept the copy the transaction reused

    my $gone;
    $orm->txn(sub {
        my $txn = shift;
        my $tmp = $orm->insert(users => {name => 'Jo'});
        $txn->rollback;
        $gone = $tmp->is_canon;    # false: a rollback forgets everything the transaction held
    });

    my $stale;
    $orm->txn(sub {
        my $post = $orm->find(posts => $post_id);
        eval {
            $orm->txn(sub {
                $post->update({views => 99});
                die "undo\n";
            });
        };
        $stale = $post->is_canon;    # false: the savepoint's data was rolled back
        $post->refresh;              # reads the database: back to the earlier views
    });

A commit keeps the copies the transaction read or wrote, and its deletes,
held weakly unless C<retain_cache>. A rollback forgets them. Either way, rows
from before that the transaction did not touch are canonical again once it
ends.

Once the transaction writes, deletes, re-reads with changed data, or clears
(C<clear_cache>) a row, that row's copy from before is gone, even after a
rollback. A bulk C<update> or C<delete> drops every copy of its table's rows
from before the transaction. So after a rollback no row the transaction wrote,
or re-read with changed data, is canonical: C<refresh> one it updated, and
insert again one it inserted.

A savepoint starts with the row cache of the transaction around it. Rolling
it back restores that, so a row changed or deleted inside it is canonical
again in its earlier form. A row object that took the savepoint's data is
not, so C<refresh> it.

Row state follows the transaction. A rollback undoes its deletes: those rows
are no longer C<was_deleted>. It undoes its inserts too: those rows are no
longer C<is_in_db>, and can be inserted again. A savepoint rollback undoes
only what the savepoint did.

When a commit or rollback statement itself fails, the outcome is unknown and
the error says so. Row state then follows the rollback rules as a guess. The
database may in fact have committed. Re-read the rows the transaction
touched before trusting C<is_in_db> or C<was_deleted>.

Caveat: a row inserted in the transaction and then re-read with changed data
(not through C<update> or C<refresh>) may still report C<is_in_db> after the
rollback. C<refresh> it to check.

=head1 WRITING A ROW READ BEFORE THE TRANSACTION

    my $post = $orm->find(posts => $post_id);

    $orm->txn(sub {
        # croaks: $post is not canonical inside the transaction
        my $ok = eval { $post->update({views => 5}); 1 };

        # succeeds only if views still equals the value $post read
        $post->cas_update({views => 5}) or die "Changed elsewhere\n";
    });

    $orm->txn(sub {
        $post->refresh;                 # reads the database: $post is canonical again
        $post->update({views => 6});    # then update as usual
    });

Inside a transaction C<update> and C<delete> check that the row is canonical,
whatever the ORM-wide C<enforce_canon> says, unless the call passes
C<< enforce_canon => 0 >> (L<DBIx::QuickORM::Manual::Caching/ENFORCE_CANON>).
C<cas_update> never checks: it compares the fields it changes (or the C<cas>
fields) with the database instead.

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
