package DBIx::QuickORM::Manual::Quickstart;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Quickstart - Introduces the fundamentals with a simple example, then expands into advanced capabilities from there.

=head1 DESCRIPTION

Short examples of what most applications do with the ORM. They use
PostgreSQL and this schema:

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

And a log whose C<user_id> has no foreign key constraint:

    CREATE TABLE audit_log (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER,
        action  TEXT NOT NULL
    );

The ORM reads the schema from the database. Nothing is declared in Perl.
C<prefs> comes back as Perl data and C<created> as a lazy L<DateTime>
(L<DBIx::QuickORM::Type::DateTime::Lazy>), from their declared types
(L<DBIx::QuickORM::Manual::Types>).

Other databases differ in places: L<DBIx::QuickORM::Manual::Dialects>.

=head1 CONNECTING

=for highlighter language=perl

    use DBIx::QuickORM;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

Or a sub that returns a new handle each time it is called:

    my $orm = DBIx::QuickORM->new(
        connect => sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) },
    );

Or a handle you already have, with C<RaiseError> on:

    my $orm = DBIx::QuickORM->new(dbh => $dbh);

The ORM cannot open a second connection from a C<dbh>, so with it a forked
child cannot reconnect, and C<aside()> and C<forked()> croak
(L<DBIx::QuickORM::Manual::Background>).

The ORM controls its handle's attributes and may change any of them. Do not
change them, run SQL on the handle, or control transactions on it outside the
ORM.

Change rows only through the ORM's methods, such as C<< $row->update >>. If
you edit a row's data hash directly, the ORM does not know about it, so its
row cache and change tracking go stale (L<DBIx::QuickORM::Manual::Caching>).

=head1 CREATE, READ, UPDATE, DELETE, FIND

    my $alice = $orm->insert(users => {
        name  => 'Alice',
        email => 'alice@example.com',
        prefs => {theme => 'dark'},
    });

    my $id    = $alice->field('id');                             # the key the database generated
    my $theme = $alice->field('prefs')->{theme};                 # JSON comes back as Perl data
    my $json  = $alice->raw_field('prefs');                      # '{"theme":"dark"}': the value as stored
    my $year  = $alice->field('created')->datetime_ref->year;    # timestamps come back as lazy DateTimes

    my $found = $orm->find(users => $id);    # by primary key

    # undef: no such user
    my $bob = $orm->handle('users')->where({email => 'bob@example.com'})->only;

    $alice->update({name => 'Alice Smith'});
    $alice->refresh;    # read it again from the database

    my $temp = $orm->insert(users => {name => 'Temp'});
    $temp->delete;

Rows have no setters: change them with C<update>.

Find a row, or insert it when there is none:

    my $gil = $orm->find_or_insert(
        users => {
            name  => 'Gil',
            email => 'gil@example.com',
        },
        by => ['email'],    # the fields to find by (the primary key by default)
    );

When another process inserts the same row first, it finds that one, given a
unique constraint on the C<by> fields (limits:
L<DBIx::QuickORM/Finding or inserting>).

A table handle has it too: C<< $users->find_or_insert(\%fields, by => ['email']) >>.

Values are deflated by their field's type on the way in: Alice's C<prefs>
hashref went in as JSON. C<raw()> sends one value as given:

    use DBIx::QuickORM::Value qw/raw/;

    my $hal = $orm->insert(users => {
        name  => 'Hal',
        prefs => raw('{"theme":"light"}'),    # already JSON text: sent as is
    });

C<< raw => 1 >> on the call does the same for every value.

See L<DBIx::QuickORM::Manual::Keys> for the forms a key takes, and
L<DBIx::QuickORM::Manual::Values> for inflation, deflation, and the value
markers. Rows are L<DBIx::QuickORM::Row> objects, and table handles are
L<DBIx::QuickORM::Handle> objects.

=head1 HANDLES

A handle is a query. Modifiers return a new handle. The one they are called
on never changes, so calling one in void context croaks.

    my $users  = $orm->handle('users');
    my $sorted = $users->order_by('name');    # $users is unchanged
    my $page   = $sorted->limit(10)->offset(20);
    my $alices = $users->where({name => {-like => 'Alice%'}});

    my $count = $users->count;
    my @all   = $sorted->all;
    my @data  = $sorted->data_only->all;    # plain hashrefs, not row objects

One row at a time, on a table handle:

    my $carol = $users->insert({name => 'Carol'});
    my $again = $users->find($carol->field('id'));
    $users->update_row($carol, {email => 'carol@example.com'});
    $users->delete_row($carol);

Many rows at once:

    my $added   = $users->insert_many([{name => 'Dan'}, {name => 'Erin'}]);    # an arrayref of rows
    my $renamed = $users->where({name => 'Dan'})->update({name => 'Daniel'});
    my $removed = $users->where({name => 'Erin'})->delete;

See L<DBIx::QuickORM::Manual::BulkInsert> for C<insert_many>, and
L<DBIx::QuickORM::Manual::RowClasses> for C<data_only> and row classes of
your own. L<DBIx::QuickORM::Handle> documents every handle method.

=head1 ITERATING

    my $posts = $orm->handle('posts')->order_by('id');
    while (my $row = $posts->next) {
        my $title = $row->field('title');
    }

    my $it = $posts->iter;    # its own position over the same rows
    $posts->clear;            # forget the rows, so the next read queries again

A handle sends its query on the first read and keeps the rows until C<clear>.
C<next> and C<reset> move the handle's own position. Each C<iter> returns a
new iterator with its own.

A handle from a foreign key knows whether it can match more than one row:

    my $post   = $posts->first;
    my $author = $post->follow_fk('users')->only;    # single: the key points at one row
    my @posts  = $alice->follow_fk('posts')->all;    # multi: any number of rows

C<only> returns the one row, or undef. It croaks when there is more than one,
and always on a multi handle. See L<DBIx::QuickORM::Manual::ForeignKeys>.

C<via> follows fields the database never declared as a key:

    my $entry = $orm->insert(audit_log => {user_id => $alice->field('id'), action => 'login'});
    my $who   = $entry->follow_fk('users', via => {user_id => 'id'})->only;    # Alice

L<DBIx::QuickORM::Iterator> documents iterators.

=head1 JOINS

    my @pairs = $orm->handle('posts')
        ->join('users')
        ->where({'users.name' => 'Alice Smith'})
        ->all;

    for my $pair (@pairs) {
        my $title  = $pair->row('posts')->field('title');
        my $author = $pair->row('users')->field('name');
    }

Each result holds one row per table. Fields are named C<table.field>.

C<left_join> keeps every user. C<row('posts')> is undef for a user without
posts:

    my @everyone = $orm->handle('users')->left_join('posts')->all;

C<as> names the joined table, and its fields are C<alias.field>. C<link>
picks the foreign key when there is more than one way to join, as a self join
has:

    my @referred = $orm->handle('users')
        ->join(
            'users',
            as   => 'referrer',
            link => {referred_by => 'id'},
        )
        ->order_by('referrer.name')
        ->all;

    for my $pair (@referred) {
        my $who = $pair->row('users')->field('name');
        my $by  = $pair->row('referrer')->field('name');
    }

See L<DBIx::QuickORM::Manual::Joins>.

=head1 AGGREGATES

    my @stats = $orm->handle('posts')
        ->group_by('user_id')
        ->fields({
            user_id => 'user_id',
            posts   => [count => '*'],               # COUNT(*)
            titles  => \'COUNT(DISTINCT title)',    # or any SQL
            views   => [sum => 'views'],
        })
        ->order_by('user_id')
        ->all;

    for my $stat (@stats) {
        my $count  = $stat->field('posts');
        my $poster = $stat->follow_fk('users')->only;    # user_id keeps its foreign key
    }

See L<DBIx::QuickORM::Manual::Aggregates>, and L<DBIx::QuickORM::Manual::Values>
for C<sql()>.

=head1 TRANSACTIONS

    $orm->txn(sub {
        my $dave = $orm->insert(users => {name => 'Dave'});
        $orm->insert(posts => {
            user_id => $dave->field('id'),
            title   => 'First post',
        });
    });    # commits when the block returns. An exception rolls back and is rethrown

    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Nobody'});
    $txn->rollback;    # or $txn->commit

A transaction opened inside another is a savepoint.

Rows read before a transaction are not canonical inside it: refresh one before
writing it there, or write it with C<cas_update> (L</COMPARE-AND-SWAP>).

    $orm->txn(
        sub {
            $post->refresh;    # $post was read before the transaction
            $post->update({views => 2});
        },
        isolation => 'serializable',
        retry     => 3,
    );

Every outermost transaction opens at C<read committed> unless C<isolation>
(on the call, or the ORM's) names another level. A savepoint keeps its
transaction's level. At C<serializable>, a write that conflicts with another
transaction fails with a serialization failure instead of overwriting it.

C<retry> runs the block again, up to 3 more times, after a deadlock, a
serialization failure, or a lock timeout (L<DBIx::QuickORM::Manual::Errors>).

See L<DBIx::QuickORM::Manual::Transactions>.

=head1 COMPARE-AND-SWAP

    # cas_update writes only while views still holds the value this row read, and
    # returns undef when it changed elsewhere first: read the row again and retry.
    while (1) {
        last if $post->cas_update({views => $post->field('views') + 1});
        $post->refresh;
    }

The loop ends once this process is the one that incremented C<views>, however
many others increment it at the same time. C<cas_update> compares the fields
it changes. C<< cas => [...] >> names other fields to compare instead.

C<update> compares too, given C<cas>, or C<auto_cas> for every changed field
the row holds:

    $post->update({views => 10}, auto_cas => 1);

C<cas_update> also works on a row that is not canonical, such as one read
before a transaction:

    $orm->txn(sub {
        $post->cas_update({views => 11}) or die "Changed elsewhere\n";
    });

See L<DBIx::QuickORM::Manual::Caching> for which rows are canonical.

=head1 ASYNC, ASIDE, AND FORKED QUERIES

    my $later = $orm->handle('posts')->async->iter;    # starts the query and returns at once

    do_something_else() until $later->ready;

    # waits for the rows when they are not there yet
    my @fetched = $later->all;

An async query runs on the ORM's connection: until its rows are collected,
anything else that sends SQL on that connection croaks. C<aside> and
C<forked> run elsewhere:

    my $aside  = $orm->handle('users')->aside->iter;     # on a second connection
    my $forked = $orm->handle('users')->forked->iter;    # in a child process
    my @found  = ($aside->all, $forked->all);

A handle runs one background query, however many iterators read it.

See L<DBIx::QuickORM::Manual::Background>, and
L<DBIx::QuickORM::Manual::Dialects> for the databases each one runs on.

=head1 DEFINING THE ORM IN PACKAGES

Larger applications can define the ORM, its table adjustments, and row classes
as packages. F<lib/My/ORM.pm>:

    package My::ORM;
    use DBIx::QuickORM::DSL ':orm';

    orm {
        tables 'My::Tables';    # the modules directly under My::Tables
    };

    1;

F<lib/My/Tables/Users.pm> adjusts C<users> and is its row class:

    package My::Tables::Users;
    use DBIx::QuickORM::DSL qw/:table :row/;

    table {
        name 'users';
        omit qw/prefs/;    # selected only when asked for
    };

    row { parent };

    sub display_name { $_[0]->field('name') . ' <' . $_[0]->field('email') . '>' }

    1;

Then:

    use My::ORM;

    my $app = My::ORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $label = $app->find(users => $id)->display_name;    # a My::Tables::Users row

Without the DSL, C<row_namespace> gives each table the row class named after
it, when that module exists: C<users> gets C<My::Rows::Users>.
C<row_class_name> picks other names.

    my $named = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_namespace => 'My::Rows',
    );

See L<DBIx::QuickORM::Manual::Classes> for the class-based ORM and
L<DBIx::QuickORM::Manual::RowClasses> for row classes.

=head1 FORKING

A forked child that uses the ORM gets its own connection. The parent's is
left alone.

    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $count = $orm->handle('users')->count;    # the ORM reconnects in the child by itself
        exit($count ? 0 : 1);
    }
    waitpid($pid, 0);

Rows the child inherited are not canonical there: refresh one before writing
it. See L<DBIx::QuickORM::Manual::Background/"FORKING YOUR OWN PROCESS">.

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
