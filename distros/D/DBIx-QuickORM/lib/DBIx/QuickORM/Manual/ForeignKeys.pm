package DBIx::QuickORM::Manual::ForeignKeys;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::ForeignKeys - Follow foreign keys from a row, and insert rows linked to it, by example.

=head1 DESCRIPTION

C<follow_fk> returns a handle for the row this key points to, or for rows
pointing back to this one. C<insert_fk> and C<insert_many_fk> insert rows
that point back to this one.

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

And a log whose C<user_id> has no foreign key constraint:

    CREATE TABLE audit_log (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER,
        action  TEXT NOT NULL
    );

C<posts.user_id> and C<users.referred_by> both reference C<users.id>.

=head1 FOLLOWING A KEY

=for highlighter language=perl

    my $post = $orm->handle('posts')->where({id => $post_id})->only;

    # the user posts.user_id points at
    my $author = $post->follow_fk('users')->only;

    # the posts whose user_id points at this user
    my @posts = $author->follow_fk('posts')->order_by('id')->all;

=head1 SINGLE AND MULTI

    my $one  = $post->follow_fk('users');      # single: user_id reaches the users primary key
    my $many = $author->follow_fk('posts');    # multi: any number of posts may point here

    my $user  = $one->only;      # the row, or undef
    my @all   = $many->all;
    my $state = $many->state;    # 'multi': only() croaks if multi is true

Single when the linked fields on the other table are its primary key or a
unique key, multi otherwise. The schema decides, not the data.

=head1 DIRECTION WITH LINK

    # users.referred_by points at users.id: the same key read both ways.

    # who referred Bob
    my $referrer = $bob->follow_fk('users', link => {referred_by => 'id'})->only;

    # whom Alice referred
    my @referrals = $alice->follow_fk('users', link => {id => 'referred_by'})
        ->order_by('id')
        ->all;

C<link> is C<< {my_field => their_field} >>: this row's field on the left,
the other table's on the right. Omit it when exactly one field mapping fits
between the two tables, counting both directions. Otherwise C<follow_fk>
croaks. Here C<link> distinguishes Bob's referrer from the users Bob referred.

=head1 NULL LINKS

    # Alice was not referred
    my $nobody = $alice->follow_fk('users', link => {referred_by => 'id'});
    my $who    = $nobody->only;    # undef: a NULL key points at nothing

A NULL key matches nothing, not even rows holding NULL in the linked field.
The handle keeps its single or multi state.

=head1 NARROWING AND JOINING

    my @popular = $author->follow_fk('posts')
        ->and({views => {'>' => 5}})
        ->all;

    # Bob's referrer with each of their posts
    my @theirs = $bob->follow_fk('users', link => {referred_by => 'id'})
        ->join('posts')
        ->order_by('posts.id')
        ->all;

C<and> keeps the key condition. C<where> would replace it. Either one drops
the single or multi state. C<join> is in L<DBIx::QuickORM::Manual::Joins>.

=head1 KEYS THE MAP DOES NOT KNOW

    # audit_log.user_id points at users.id, but nothing declares it
    my $entry = $orm->insert(audit_log => {user_id => $alice_id, action => 'login'});

    my $who = $entry->follow_fk('users', via => {user_id => 'id'})->only;
    my @log = $alice->follow_fk('audit_log', via => {id => 'user_id'})->all;

    my @pairs = $orm->handle('audit_log')
        ->join('users', via => {user_id => 'id'})
        ->all;

    my $next = $alice->insert_fk('audit_log', via => {id => 'user_id'}, {action => 'logout'});

C<via> takes a mapping in C<link>'s form, C<< {my_field => their_field} >>,
and needs no foreign key. It works wherever C<link> does. Both tables and
every named field must exist, so a typo still croaks. C<via> and C<link>
together croak. Single or multi still comes from the target fields.

To declare the key once, for every call, give C<fks> to C<new>
(L<DBIx::QuickORM>). C<link> and the plain forms then work too.

=head1 INSERTING LINKED ROWS

    my $post  = $alice->insert_fk('posts', {title => 'Hi'});    # user_id is Alice's id
    my $posts = $alice->insert_many_fk('posts', {title => 'A'}, {title => 'B'});    # an arrayref of rows
    my $count = $alice->insert_many_fk('posts', count => 1, {title => 'C'}, {title => 'D'});

    # only keys pointing back at Alice count, so users.referred_by needs no link
    my $dan = $alice->insert_fk('users', {name => 'Dan'});    # referred by Alice

    my $note = $orm->insert_fk(users => {id => $alice_id}, 'posts', {title => 'Note'});

The new rows' foreign key fields come from the row, so the given fields must
not set them. Options go between the table and the rows: C<link> picks the
key when more than one points back, and the rest are C<insert>'s or
C<insert_many>'s. C<insert_fk> returns the row. C<insert_many_fk> returns
what C<insert_many> does (L<DBIx::QuickORM::Manual::BulkInsert>).

Only rows pointing at this one: to add the row it points at, insert that row,
then C<update> this one. A NULL linked value, or a row not in the database,
croaks.

=head1 WITHOUT ROW OBJECTS

    my $data = $orm->handle('posts')
        ->data_only
        ->where({id => $post_id})
        ->only;    # a hashref

    my $who = $orm->follow_fk('posts', $data, 'users')->only;    # a users row object

    # user_id is fetched first
    my $by_key = $orm->follow_fk('posts', {id => $post_id}, 'users')->only;

C<< $orm->follow_fk >> takes row data in place of a row object
(L<DBIx::QuickORM::Manual::RowClasses/HASHREFS>). If a linked field is
missing, supply the row's primary key so the ORM can fetch it.

=head1 FROM AGGREGATE AND JOIN ROWS

    my $stat = $orm->handle('posts')
        ->group_by('user_id')
        ->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
        })
        ->order_by('user_id')
        ->first;

    my $user = $stat->follow_fk('users')->only;    # user_id kept its key

    my $jrow = $orm->handle('posts')
        ->join('users')
        ->order_by('posts.id')
        ->first;
    # each table's row in a join is an ordinary row
    my @more = $jrow->row('users')->follow_fk('posts')->all;

L<DBIx::QuickORM::Manual::Aggregates> shows which computed columns keep a
foreign key, and how to declare one. L<DBIx::QuickORM::Manual::Joins> covers
join rows.

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
