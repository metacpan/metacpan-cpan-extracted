package DBIx::QuickORM::Manual::Caching;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Caching - The ORM's one canonical copy of each row, by
example.

=head1 DESCRIPTION

The ORM caches one copy of the data of each row it has read or written, per
table and primary key: the I<canonical> copy (the code calls it I<canon>). A
row is canonical when its data is that copy. That does not mean it matches
the database right now. Two reads of one row can share it, and a write
through a row object needs it. C<< $row->is_canon >> asks whether a row
object is canonical.

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

=head1 ONE COPY PER ROW

=for highlighter language=perl

    my $one = $orm->find(users => $id);
    my $two = $orm->handle('users')->where({id => $id})->only;

    # true: the same hash, so two objects share one copy of the data
    my $shared = $one->row_data == $two->row_data;

    $one->update({name => 'Ann B'});
    my $stale = $two->is_canon;         # false: $one's write replaced the canonical copy
    my $name  = $two->field('name');    # 'Ann': $two still holds the data it read

    # croaks: $two is not canonical
    my $ok = eval { $two->update({email => 'b@example.com'}); 1 };

    $two->refresh;    # reads the database: $two is canonical again
    $two->update({email => 'b@example.com'});

Refusing the write is the point: C<$one> changed the row, so C<$two> is stale
even for a write to another field, and a write decided on stale data is the
bug this catches. C<cas_update> writes a stale row safely by comparing with
the database (L<DBIx::QuickORM::Manual::Transactions>).

=head1 ENFORCE_CANON

    # write by primary key alone, whatever the ORM holds
    $two->update({email => 'c@example.com'}, enforce_canon => 0);

    my $lax = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        enforce_canon => 0,    # for every write outside a transaction
    );

Inside a transaction every C<update> and C<delete> checks, whatever the
ORM-wide C<enforce_canon> says, unless the call itself passes
C<< enforce_canon => 0 >>.

=head1 READS FROM THE CANONICAL COPY

    my $ann   = $orm->find(users => $id);
    my $again = $orm->find(users => $id);    # no query: the canonical copy has every field asked for

    my $fresh = $orm->find(
        users => $id,
        cache => 0,    # reads the database (same data, so the canonical copy stays)
    );

When another process has changed the row:

    my $changed = $orm->find(
        users => $id,
        cache => 0,    # new data: this becomes the canonical copy
    );

    my $old = $ann->is_canon;    # false
    $ann->refresh;               # true again

C<find> and C<refresh_row> return the canonical copy when it has every field
asked for. C<where> only builds a handle: its first read runs the query, and
later reads and every C<iter> reuse its rows until C<clear>. A query's rows
keep the canonical copy when the data matches and replace it when it does not.

C<< $row->refresh >> always reads the database.

A C<no_cache> handle's queries skip the row cache: their rows are not
canonical, and the row cache does not change. C<cache> undoes it on a handle.

    my $apart = $orm->handle('users')->no_cache;
    my @rows  = $apart->all;    # not canonical, and the row cache does not change

    # find is a CRUD operation and reads the canonical copy first, but cache => 0 forces a read
    my $read = $apart->find($id, cache => 0);

=head1 HOW LONG ROWS ARE HELD

By default a copy is held only while your code holds a row object (or its
data) for it. C<< retain_cache => 1 >> holds every copy until C<clear_cache>.
Inside a transaction every copy is held until the transaction ends.

C<refresh_row> takes the key in any form (L<DBIx::QuickORM::Manual::Keys>).
With C<< db => 0 >> it asks the row cache only, without querying
the database, so it shows whether a copy is held:

    # the row object is gone at once
    my $tmp_id = $orm->insert(users => {name => 'Tmp'})->field('id');
    my $held   = $orm->refresh_row(
        users => {id => $tmp_id},
        db    => 0,    # undef: nothing holds the row any more
    );

    my $keeper = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        retain_cache => 1,
    );

    my $kept_id = $keeper->insert(users => {name => 'Kept'})->field('id');
    my $kept    = $keeper->refresh_row(
        users => {id => $kept_id},
        db    => 0,    # the row: held until clear_cache
    );

=head1 CLEAR_CACHE

    # one row: a hashref, arrayref, row, or single value, as find takes it
    $orm->clear_cache(users => $id);
    $orm->clear_cache('users');      # one table
    $orm->clear_cache;               # everything
    my $current = $ann->is_canon;    # false: refresh makes it canonical again

    my $post = $orm->find(posts => $post_id);

    # a bulk update or delete drops the canonical copies of its table's rows
    $orm->handle('posts')->where({views => 0})->update({views => 1});
    my $dropped = $post->is_canon;    # false

    # mark_deleted: the held rows it deleted also say so
    my $temp = $orm->insert(posts => {
        user_id => $ann->field('id'),
        title   => 'Temp',
    });
    $orm->handle('posts')->where({title => 'Temp'})->delete(mark_deleted => 1);
    my $deleted = $temp->was_deleted;    # true

=head1 TRANSACTIONS

A row read before a transaction is not canonical inside it until it is read
again. A commit keeps what the transaction held, and a rollback forgets it.
L<DBIx::QuickORM::Manual::Transactions/"THE ROWS YOU HOLD"> shows each case.

=head1 TYPED KEYS

A typed primary key finds the canonical copy in any form:
L<DBIx::QuickORM::Manual::Keys/"TYPED KEYS">.

=head1 WHEN TO CARE

=over 4

=item *

Read a row, use it, drop it: never.

=item *

Keep a row object while other code writes the row, or across a transaction:
C<refresh> before writing it, or write it with C<cas_update>.

=item *

Several processes: each has its own copies. For a write that depends on what
was read, use C<cas_update> with C<< cas => [...] >> naming the fields it
depends on. A transaction alone does not stop another writer at the default
isolation level (L<DBIx::QuickORM::Manual::Transactions/ISOLATION>).

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
