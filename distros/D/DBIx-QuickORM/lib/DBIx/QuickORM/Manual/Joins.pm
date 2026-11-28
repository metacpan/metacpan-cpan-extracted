package DBIx::QuickORM::Manual::Joins;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Joins - Join tables and read the joined rows, by example.

=head1 DESCRIPTION

A join handle returns one join row per result row. A join row holds a row
object for every table in the join, or undef for a left-joined table that
matched nothing.

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

C<posts.user_id> and C<users.referred_by> both reference C<users.id>.

=head1 INNER AND LEFT JOINS

=for highlighter language=perl

    my $joined = $orm->handle('posts')
        ->join('users')
        ->order_by('posts.id');

    my @pairs = $joined->all;
    my $count = $joined->count;
    my $first = $joined->first;

    my $it = $joined->iter;
    while (my $pair = $it->next) {
        my $post   = $pair->row('posts');                 # a full posts row
        my $title  = $post->field('title');
        my $author = $pair->row('users')->field('name');
        my @names  = $pair->aliases;                      # ('posts', 'users')
    }

A join handle is a handle: C<all>, C<first>, C<only>, C<iter>, and C<count>
work as on a table. C<row> returns a component's row, in its table's row
class (L<DBIx::QuickORM::Manual::RowClasses>), with every row method:
C<field>, C<update>, C<follow_fk>, and the rest.

A left join keeps rows that match nothing. Here there is one row per
user-post pair, and one for each user without posts, with C<row('posts')>
undef:

    my @everyone = $orm->handle('users')
        ->left_join('posts')
        ->order_by('users.id')
        ->all;

C<join> and C<inner_join> are the same. Omit C<link> when exactly one foreign
key connects the two tables, in either direction. Otherwise the join croaks.
A self reference counts once per direction (L</SELF JOINS>). To join on
fields no foreign key connects, name them with C<via>, in C<link>'s form
(L<DBIx::QuickORM::Manual::ForeignKeys/KEYS THE MAP DOES NOT KNOW>).

=head1 FILTERING, ORDERING, AND FIELDS

    my @popular = $orm->handle('posts')
        ->join('users')
        ->where({
            'users.name'  => 'Alice',
            'posts.views' => {'>' => 5},
        })
        ->order_by([{-desc => 'posts.views'}, 'posts.id'])
        ->fields(['posts.title', 'users.name'])    # a subset (each primary key is always added)
        ->all;

    my $n = $orm->handle('posts')
        ->join('users')
        ->where({'users.name' => 'Alice'})
        ->count;

Fields are named C<alias.field>. The alias defaults to the table name.

=head1 ALIASES

    my @by_author = $orm->handle('posts')
        ->join('users', as => 'author')
        ->order_by('author.name')
        ->all;

    my $writer = $by_author[0]->row('author')->field('name');

=head1 SELF JOINS

    # Each referred user with whoever referred them.
    my @referred = $orm->handle('users')
        ->join(
            'users',
            as   => 'referrer',
            link => {referred_by => 'id'},
        )
        ->order_by('users.id')
        ->all;

    for my $pair (@referred) {
        my $who = $pair->row('users')->field('name');
        my $by  = $pair->row('referrer')->field('name');
    }

    # The other way round: each referrer with the users they referred.
    my @referrals = $orm->handle('users')
        ->join(
            'users',
            as   => 'referral',
            link => {id => 'referred_by'},
        )
        ->order_by('referral.id')
        ->all;

C<as> names the second C<users> row. C<link> picks the direction of
C<referred_by>: a self reference offers each direction as its own mapping,
so without C<link> the join croaks. C<link> is
C<< {from_field => joined_field} >>: the left side is a field of the table
joined from (the base table, unless C<from> names another), the right side a
field of the table being joined.

=head1 JOINING FROM A JOINED TABLE

    my @chain = $orm->handle('posts')
        ->join('users')
        ->left_join(
            'users',
            as   => 'referrer',
            from => 'users',
            link => {referred_by => 'id'},
        )
        ->order_by('posts.id')
        ->all;

    my $author   = $chain[0]->row('users')->field('name');
    my $referrer = $chain[0]->row('referrer');    # undef when the author was not referred

C<from> names a component already in the join, by its alias (the table name
unless C<as> gave another). The default is the base table.

=head1 FLAT ROWS

    # one join row per post
    my @pairs = $orm->handle('users')
        ->join('posts')
        ->order_by('posts.id')
        ->all;

    my @aliases = $pairs[0]->aliases;    # ('users', 'posts'), in join order

    # {'users.id' => 1, 'users.name' => 'Alice', 'posts.title' => 'Hello', ...}
    my $data = $pairs[0]->data;

    # Plain hashrefs keyed table.field, with no row objects at all.
    my @raw = $orm->handle('users')
        ->join('posts')
        ->row_class(undef)
        ->all;

Results are flat: a user with two posts appears in two rows, and both rows in
this result share one user object.

=head1 WRITING AND FOLLOWING KEYS

    my $pair = $orm->handle('posts')
        ->join('users')
        ->where({'posts.id' => $post_id})
        ->only;

    $pair->row('posts')->update({views => 11});    # write through the table's row
    my @posts = $pair->row('users')->follow_fk('posts')->all;

A join row has no write methods. Following keys from join rows:
L<DBIx::QuickORM::Manual::ForeignKeys/"FROM AGGREGATE AND JOIN ROWS">.

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
