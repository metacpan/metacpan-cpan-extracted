package DBIx::QuickORM::Manual::Classes;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Classes - Defining an ORM as classes: the orm, table, and row blocks, by example.

=head1 DESCRIPTION

You can define your ORM in a Perl package. The C<orm> and C<table> blocks
collect the arguments you would otherwise pass to C<new>. A C<row> block sets
a row class's parent or applies a role to it
(L<DBIx::QuickORM::Manual::RowClasses>).

The ORM reads the columns from the database, so the package declares none. A
table needs its own class only to adjust what the scan found, or to give its
rows methods.

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

    CREATE TABLE events (
        id      CHAR(36) PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        type    TEXT NOT NULL,
        data    JSON
    );

=head1 THE ORM CLASS

F<lib/My/App.pm>:

=for highlighter language=perl

    package My::App;
    use DBIx::QuickORM::DSL ':orm';

    orm {
        # rows of every table, unless a table class says otherwise
        row_class 'My::App::Row';
        override(omit => {posts => ['views']});    # posts needs nothing else, so it has no class
    };

    1;

C<override> takes any argument of C<new> except the connection arguments
(C<dbh>, C<connect>, C<credentials>). C<row_class>, C<autotype>,
C<append_autotype>, and C<retain_cache> are keywords for the arguments of the
same names (L<DBIx::QuickORM::Manual::Types>,
L<DBIx::QuickORM::Manual::Caching>). C<tables> is the DSL's own (below).

C<new> loads every module directly under F<My/App/>. Those with a C<table>
block adjust their table. The rest (row classes, say) are only loaded.

=head1 A ROW CLASS FOR EVERY TABLE

F<lib/My/App/Row.pm>:

    package My::App::Row;
    use DBIx::QuickORM::DSL ':row';

    row {
        parent;    # DBIx::QuickORM::Row
    };

    sub label { my $self = shift; $self->table . ' #' . $self->field('id') }

    1;

C<parent> loads the class and adds it to C<@ISA>, so there is no C<use
parent>. C<with_role> applies a role instead (L<DBIx::QuickORM::DSL>).

=head1 A TABLE CLASS

F<lib/My/App/Users.pm>, a table class that is also its table's row class:

    package My::App::Users;
    use DBIx::QuickORM::DSL qw/:table :row/;

    table {
        name 'users';             # required: the package name decides nothing
        omit qw/prefs/;           # selected only when asked for
        type created => undef;    # plain text instead of a DateTime
    };

    row {
        parent 'My::App::Row';
    };

    no DBIx::QuickORM::DSL;    # the keywords are gone, so a method may take a keyword's name

    sub name { $_[0]->field('name') }

    1;

A package with both blocks is its table's row class once both have run. Its
C<row_class> keyword may only name itself.

Importing a tag registers nothing. Only a block that runs does. A package
that imports C<:row> but has no C<row> block is not a row class: its table
keeps the default row class.

Each block removes its keywords when it finishes. The C<no> matters only for
a sub named like a keyword: Perl compiles subs before any block runs, so
without it C<sub name> would replace the keyword and the C<table> block would
croak. Renaming the keyword (next section) is the other way out.

The other table keywords: C<default_fields> instead of C<omit> (below), and
C<< fk $table => {field => 'their_field'} >> for a foreign key the database
does not declare (L<DBIx::QuickORM::Manual::ForeignKeys>). A table class
without a C<row> block may name its row class with C<row_class>: another
package, or undef for hashrefs.

=head1 TYPES WITH HINTS, AND A RENAMED KEYWORD

F<lib/My/App/Events.pm>:

    package My::App::Events;
    # frees 'type' for the method below
    use DBIx::QuickORM::DSL qw/:table :row/, type => {-as => 'col_type'};

    table {
        name 'events';
        default_fields qw/id user_id type/;    # data only when asked for
        col_type id => {
            class  => 'UUID',              # generated when an insert leaves it out
            format => sub { uc $_[0] },    # stored upper-case
        };
    };

    row {
        parent 'My::App::Row';
    };

    sub type { $_[0]->field('type') }

    1;

C<type> takes a type name (C<JSON>, or C<+My::Type> for a full class name),
undef, or a hashref of options: the hints C<format> and C<generate>, and
C<class>. A hashref without C<class> keeps the field's type. See
L<DBIx::QuickORM::Manual::Types> and L<DBIx::QuickORM::Manual::Keys>.

=head1 USING IT

    use My::App;

    my $orm = My::App->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $ann = $orm->insert(users => {
        name  => 'Ann',
        prefs => {theme => 'dark'},
    });
    my $name = $ann->name;    # 'Ann'

    my $post = $orm->insert(posts => {
        user_id => $ann->field('id'),
        title   => 'Hi',
    });
    my $label = $post->label;    # 'posts #1', from My::App::Row: posts has no class of its own

    my $event = $orm->insert(events => {
        user_id => $ann->field('id'),
        type    => 'login',
    });
    my $kind = $event->type;               # 'login'
    my $id   = $event->raw_field('id');    # a version 7 UUID in upper case, generated for the insert

=head1 PRECEDENCE

    my $other = My::App->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # replaces the Users class's omit, for this ORM only
        omit => {users => ['prefs', 'email']},
    );

Lowest to highest: the C<orm> block's keywords, its C<override>, the table
classes, the arguments to C<new>.

C<omit>, C<default_fields>, and C<row_classes> merge per table: a higher
source's entry for a table replaces the lower one's whole entry for that
table, and other tables keep theirs. C<omit> and C<default_fields> count as
one setting: either replaces both.

C<types> merge per field, and C<fks> per target table: typing one field in
C<new> keeps the table class's types for the others.

=head1 NAMING THE TABLE CLASSES

    package My::Listed;
    use DBIx::QuickORM::DSL ':orm';

    orm {
        tables ['My::App::Users'];    # only these: nothing under My::Listed:: is searched for
    };

    1;

C<tables> also takes a namespace (C<'My::App'>) to search instead of the ORM
class's own.

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
