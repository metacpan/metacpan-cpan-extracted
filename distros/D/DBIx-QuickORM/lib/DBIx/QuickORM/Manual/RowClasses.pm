package DBIx::QuickORM::Manual::RowClasses;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::RowClasses - Your own row classes: for one table, every table, or one query, and plain hashrefs, by example.

=head1 DESCRIPTION

A row object wraps one row's data (a hashref) with the ORM and the table it
came from. L<DBIx::QuickORM::Row> is the default class. Replace it where you
want methods of your own, or ask for the hashrefs themselves.

L<DBIx::QuickORM::Manual::Classes> shows the same as C<row> blocks.

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

=head1 ONE TABLE

=for highlighter language=perl

    package My::User;
    use parent 'DBIx::QuickORM::Row';

    sub posts { $_[0]->follow_fk('posts') }                 # a handle on this user's posts

    sub theme { ($_[0]->field('prefs') // {})->{theme} }    # from the inflated JSON

    sub change_email {
        my ($self, $email) = @_;
        # rows have no setters: writes go through update
        return $self->update({email => $email});
    }

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_classes => {users => 'My::User'},
    );

    my $ann = $orm->insert(users => {
        name  => 'Ann',
        prefs => {theme => 'dark'},
    });

    my $theme = $ann->theme;    # 'dark'

    # a DBIx::QuickORM::Row: posts has no row class here
    my $post = $orm->insert(posts => {
        user_id => $ann->field('id'),
        title   => 'Hi',
    });

    my $count = $ann->posts->count;    # 1
    $ann->change_email('ann@example.com');

Every C<users> row is a C<My::User>, however it was read: C<insert>, C<find>,
a handle, C<follow_fk> (L<DBIx::QuickORM::Manual::ForeignKeys>), or a
join's C<< ->row('users') >> (L<DBIx::QuickORM::Manual::Joins>). A handle's
C<row_class> can still choose another class for one query (L</THE ROLE>).
The class is loaded for you.

=head1 EVERY TABLE

    package My::Row;
    use parent 'DBIx::QuickORM::Row';

    sub id { $_[0]->field('id') }    # every table here has one

    package main;

    my $app = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_class   => 'My::Row',                # the default for every table
        row_classes => {users => 'My::User'},    # but users
    );

    my $hi = $app->handle('posts')->where({title => 'Hi'})->only;
    my $id = $hi->id;

C<My::User> does not extend C<My::Row>, so here a users row has no C<id>
method. A table's class usually extends the shared one (C<use parent
'My::Row'>) to get both.

=head1 A CLASS PER TABLE, BY NAME

    package My::Rows::Users;
    use parent 'DBIx::QuickORM::Row';

    sub name { $_[0]->field('name') }

    package main;

    my $named = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_namespace => 'My::Rows',
    );

    my $ned  = $named->insert(users => {name => 'Ned'});    # a My::Rows::Users
    my $who  = $ned->name;
    my $note = $named->insert(posts => {
        user_id => $ned->field('id'),
        title   => 'Note',
    });    # no My::Rows::Posts: a DBIx::QuickORM::Row

C<row_namespace> names each table's class from the table: C<user_posts> gets
C<My::Rows::UserPosts>. The class is loaded for you. A table whose class has
no module keeps the default row class. C<row_classes> still wins.

A class found there must be a row class (do L<DBIx::QuickORM::Role::Row>,
as a subclass of L<DBIx::QuickORM::Row> does). Any other module croaks.

    package My::Rows::Person;
    use parent 'DBIx::QuickORM::Row';

    package main;

    my $people = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_namespace  => 'My::Rows',
        row_class_name => sub {
            my ($table) = @_;
            return 'Person' if $table eq 'users';
            return undef;    # the default row class
        },
    );

    my $pat = $people->insert(users => {name => 'Pat'});    # a My::Rows::Person

C<row_class_name> names the class instead: it gets the table and returns the
part after the namespace. Undef keeps the default row class.

A name part that is not valid (it holds C<::>, or starts with a digit) warns
and keeps the default row class, whether it came from the table or from
C<row_class_name>.

=head1 HASHREFS

    my @data = $app->handle('users')->data_only->all;    # the row data itself
    my $name = $data[0]->{name};

    # as the database returned it: JSON text
    my $json = $data[0]->{prefs};

    my $plain = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_class => undef,    # hashrefs for every table
    );

    # a hashref: {id => ..., name => 'Bob', email => undef, ...}
    my $bob  = $plain->insert(users => {name => 'Bob'});
    my $same = $plain->find(users => $bob->{id});

    # new row data ($bob is unchanged)
    my $new  = $plain->update_row(users => $bob, {name => 'Robert'});
    my $gone = $plain->delete_row(users => $new);    # 1

A hashref is the row data the ORM works on everywhere. Treat it as
read-only: a missing key is a field not fetched, undef is NULL, nothing
inflates it, and nothing fetches for it. Write with C<update_row> and keep
what it returns. The hashref you passed is stale after that
(L<DBIx::QuickORM::Manual::Caching>). The ORM's CRUD operations take a hashref
wherever a row is expected.

C<data_only> is short for C<row_class(undef)>.
C<< row_classes => {posts => undef} >> gives one table hashrefs.

=head1 ROWS NOT IN THE DATABASE

    my $draft = $orm->vivify(users => {name => 'Draft'});    # nothing written yet
    $draft->modify({email => 'draft@example.com'});
    my $stored = $draft->is_in_db;    # false

    $draft->insert;                   # now it is
    $draft->update({name => 'Final'});

    $draft->delete;
    my $deleted = $draft->was_deleted;    # true
    $draft->insert;                       # back in, with the same key

C<vivify> builds a row the database does not have yet. C<modify> changes it
and C<insert> writes it. C<update>, C<cas_update>, C<delete>, and C<refresh>
croak on a row not in the database. C<insert> and C<modify> croak on one that
is.

C<is_in_db> is what this ORM last saw, not a check of the database. A row's
own C<delete>, a C<delete_row>, or a C<refresh> or C<find> that finds nothing
marks it deleted. A handle's bulk C<delete> marks nothing unless given
C<< mark_deleted => 1 >>. A transaction rollback undoes the deletes and
inserts made inside it
(L<DBIx::QuickORM::Manual::Transactions/"THE ROWS YOU HOLD">).

=head1 THE ROLE

    package My::RawRow;
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';

    # raw by default, but inflated_field still inflates
    sub field  { my $self = shift; $self->raw_field(@_) }
    sub fields { my $self = shift; $self->raw_fields(@_) }

    package main;

    # one query's rows
    my $raw = $app->handle('users')
        ->where({id => $ann->field('id')})
        ->row_class('My::RawRow')
        ->only;

    my $text  = $raw->field('prefs');             # '{"theme":"dark"}'
    my $prefs = $raw->inflated_field('prefs');    # {theme => 'dark'}

L<DBIx::QuickORM::Role::Row> holds everything a row does (reading, inflation,
C<update>, C<delete>, C<follow_fk>). Consume it when your class cannot extend
L<DBIx::QuickORM::Row>. A subclass can override C<field> and C<fields> the
same way.

The ORM itself needs only a constructor and four methods (the role needs the
same):

    package My::Bare;
    # new, orm, table, row_data, set_row_data: all the ORM needs
    use Object::HashBase qw{<orm <table row_data};

    package main;

    my $bare = $app->handle('users')->row_class('My::Bare')->first;

    # field(), update(), and the rest are yours to add
    my $data = $bare->row_data;

It builds a row with C<< $class->new(row_data => \%data, orm => $orm, table
=> $table) >>, where C<$table> is the table's name (undef for a query's
rows). A class whose C<fast_bless> is true, as L<DBIx::QuickORM::Row> and its
plain subclasses are, is blessed from those directly. When C<update_row> or
C<refresh_row> is given the row, it hands the row the new data through
C<set_row_data>. L<Object::HashBase> is one way to get those. Any class that
has them works.

=head1 WHICH CLASS

The most specific wins, and undef at any level means hashrefs:

=over 4

=item *

The handle's C<row_class> (or C<data_only>), when it was called.

=item *

The table's: C<row_classes>, or a table class (L<DBIx::QuickORM::Manual::Classes>).

=item *

The table's class under C<row_namespace>, when it exists.

=item *

The ORM's C<row_class>, L<DBIx::QuickORM::Row> unless given.

=back

Join rows are L<DBIx::QuickORM::JoinRow> objects
(L<DBIx::QuickORM::Manual::Joins>). The join handle's
C<row_class(undef)> gives flat hashrefs keyed C<component.field> instead. Any
other class there croaks when the query runs. The component rows
(C<< ->row('users') >>) use their tables' classes.

Computed rows (C<fields> with an aggregate, see
L<DBIx::QuickORM::Manual::Aggregates>) are L<DBIx::QuickORM::AggregateRow>
objects, or hashrefs when the class resolved for the table (over a join, the
ORM's C<row_class>) is undef. The handle's C<row_class> replaces either.

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
