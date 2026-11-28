package DBIx::QuickORM::Manual::Aggregates;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Aggregates - Group, count, and compute columns, by example.

=head1 DESCRIPTION

C<group_by>, C<having>, or a hashref given to C<fields> makes a handle query
computed columns. Its rows are L<DBIx::QuickORM::AggregateRow> objects by
default: they inflate values and follow foreign keys
(L<DBIx::QuickORM::Manual::ForeignKeys>), but cannot be written.

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

=head1 COUNTING

=for highlighter language=perl

    my $total = $orm->handle('posts')->count;                                   # SELECT COUNT(*)
    my $alice = $orm->handle('posts')->where({user_id => $alice_id})->count;    # with its WHERE

=head1 GROUPING

    use DBIx::QuickORM::Value qw/sql/;

    my @per_user = $orm->handle('posts')
        ->group_by('user_id')
        ->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
            views   => [sum => 'views'],
        })
        ->order_by('user_id')
        ->all;

    for my $stat (@per_user) {
        my $posts = $stat->field('posts');
        my ($user_id, $views) = $stat->fields(qw/user_id views/);
        my $user = $stat->follow_fk('users')->only;    # user_id keeps its foreign key
    }

    # Without group_by the whole table is one group.
    my $all = $orm->handle('posts')->fields({
        posts => [count => '*'],
        top   => [max => 'views'],
    })->only;

    my ($count, $top) = $all->fields(qw/posts top/);

    # group_by alone selects the grouped fields.
    my @groups = $orm->handle('posts')
        ->group_by('user_id')
        ->order_by('user_id')
        ->all;

    # Several fields: pass them all. One row per user and title.
    my @per_title = $orm->handle('posts')
        ->group_by('user_id', 'title')
        ->fields({
            user_id => 'user_id',
            title   => 'title',
            posts   => [count => '*'],
        })
        ->order_by(['user_id', 'title'])
        ->all;

Each row is an L<DBIx::QuickORM::AggregateRow>. C<field>, C<fields>, and
C<raw_field> read its columns. C<follow_fk> follows a column that kept a
foreign key (L</COLUMN SPECS>).

C<count> croaks on a grouped handle. Use C<< posts => [count => '*'] >>, as
above, to count the rows in each group.

=head1 HAVING

C<having> filters groups, as C<where> filters rows. Use it with C<group_by>
or computed fields. Without either, it croaks.

Name a computed column to filter on it:

    my @busy = $orm->handle('posts')
        ->where({views => {'>' => 0}})         # filters rows, before grouping
        ->group_by('user_id')
        ->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
        })
        ->having({posts => {'>' => 1}})        # filters groups
        ->all;

This works on every database. On MySQL and MariaDB the ORM sends the name as
written, and the server computes the count once. Elsewhere it writes the
column's SQL there instead, C<COUNT(*) E<gt> ?>: PostgreSQL rejects the
name in C<HAVING>, and SQLite would let a table column of the same name win.

Every database can name a grouped field:

    my @later = $orm->handle('posts')
        ->group_by('user_id')
        ->having({user_id => {'>' => 1}})
        ->all;

C<sql()> writes the condition yourself. Extra arguments to C<sql()> are
binds:

    my @two = $orm->handle('posts')
        ->group_by('user_id')
        ->having(sql('COUNT(*) > ?', 1))
        ->all;

SQLite sends a bind as text, which never compares with a count, whether the
having names the column or writes C<sql()>. Write the number into the SQL
there, C<< {posts => {'>' => \'1'}} >>, or cast the bind:
C<< sql('COUNT(*) > CAST(? AS INTEGER)', $minimum) >>
(L<DBIx::QuickORM::Manual::Dialects/"SQL YOU WRITE">). C<sql()> is in
L<DBIx::QuickORM::Manual::Values>.

=head1 COLUMN SPECS

    my $stat = $orm->handle('posts')
        ->group_by('user_id')
        ->fields({
            # the field itself: its type and single-column foreign keys come along
            user_id => 'user_id',
            posts   => [count => '*'],                  # COUNT(*): '*' stands for the whole row
            titles  => sql('COUNT(DISTINCT title)'),    # any SQL: no type, no foreign key
            chars   => \'SUM(LENGTH(title))',          # short for sql('SUM(LENGTH(title))')

            # MAX(views): min and max keep the field's type and single-column keys
            top   => [max => 'views'],
            views => [sum => 'views'],    # SUM(views): other functions keep neither

            # MAX(id), declared a foreign key to posts
            latest => {
                agg => [max => 'id'],
                fk  => 'posts',
            },
        })
        ->order_by('user_id')
        ->first;

    my $author = $stat->follow_fk('users')->only;    # user_id kept its key
    my $latest = $stat->follow_fk('posts')->only;    # latest was given one

In C<fields>, a reference to a string, C<\'SQL'>, is short for C<sql('SQL')>.
C<having> and C<order_by> already take L<SQL::Abstract>'s C<\'SQL'> literals.
C<group_by> takes field names only.

Insert and update values do not take the shorthand, since a scalar reference
there can be a JSON boolean (C<\1>, C<\0>). Use C<sql()>.

=head1 TYPES

    my $signups = $orm->handle('users')->fields({
        newest => [max => 'created'],
        total  => [count => '*'],
    })->only;

    my $year = $signups->field('newest')->datetime_ref->year;    # MAX kept created's type: a DateTime
    my $text = $signups->raw_field('newest');                    # the value as fetched

    my $span = $orm->handle('users')->fields({
        # an sql() column inflates only when told: like takes created's type and keys
        first => {
            sql  => sql("date_trunc('day', MIN(created))"),
            like => 'created',
        },
        # or name the type by hand
        last => {
            sql     => sql("date_trunc('day', MAX(created))"),
            type    => 'DateTime',
            db_type => 'timestamp',
        },
    })->only;

    my ($first, $last) = map { $_->datetime_ref->ymd } $span->fields(qw/first last/);

C<date_trunc> is PostgreSQL's. Other databases have their own functions.

=head1 LIKE_AGGREGATES

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        like_aggregates => ['any_value'],
    );

    # ANY_VALUE (PostgreSQL 16 and later) gives one of the group's values, so the
    # column keeps the field's type and keys.
    my @groups = $orm->handle('users')
        ->group_by('referred_by')
        ->fields({
            referred_by => 'referred_by',
            joined      => [any_value => 'created'],
        })
        ->order_by('referred_by')
        ->all;

    my $year = $groups[0]->field('joined')->datetime_ref->year;    # a DateTime, like created

Plain fields, C<min>, and C<max> keep the field's type and single-column
foreign keys, because their result is one of the field's values.
C<like_aggregates> adds functions to that list.

=head1 OVER A JOIN

    my @by_name = $orm->handle('posts')
        ->join('users')
        ->group_by('users.id', 'users.name')    # several fields: a list
        ->fields({
            name   => 'users.name',
            posts  => [count => '*'],
            newest => [max => 'users.created'],
        })
        ->order_by('name')
        ->all;

    my ($name, $posts) = $by_name[0]->fields(qw/name posts/);

With C<group_by> or computed fields, C<all> returns
L<DBIx::QuickORM::AggregateRow> objects, joined or not, never join rows. When
the row class is undef it returns hashrefs instead: C<data_only>, the table's
row class, or over a join the ORM's C<row_class>. A handle C<row_class>
replaces C<AggregateRow> (L<DBIx::QuickORM::Manual::RowClasses>).

Fields are named C<table.field> (or C<alias.field>), as on any join handle
(L<DBIx::QuickORM::Manual::Joins>).
C<order_by> may also name a selected column, as C<name> is here.

=head1 AGGREGATE ROWS

    my $stat = $per_user[0];    # from GROUPING

    my $posts    = $stat->field('posts');
    my ($id, $n) = $stat->fields(qw/user_id posts/);
    my $pk       = $stat->pk;    # undef: no primary key

    # Plain hashrefs instead.
    my @data = $orm->handle('posts')
        ->group_by('user_id')
        ->data_only
        ->all;

Aggregate rows are L<DBIx::QuickORM::AggregateRow> objects. They have no
primary key, so C<update>, C<delete>, and C<refresh> croak.

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
