package DBIx::QuickORM::Manual::Values;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Values - How values move between Perl and the database: deflation, inflation, and the raw, inflated, binary, and sql markers, by example.

=head1 DESCRIPTION

A value sent to the database by an insert or update is deflated through its
field's type: a hashref on a JSON field becomes JSON text, a DateTime becomes
the database's text (L<DBIx::QuickORM::Manual::Types>). The values of a
C<where> are sent as given, not deflated: pass database form, or wrap one in
C<inflated()>. A marker from L<DBIx::QuickORM::Value> changes the rule for one
value.

A value read back is inflated through the same type (L</INFLATION>).

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

    CREATE TABLE files (id SERIAL PRIMARY KEY, name TEXT, data BYTEA);
    CREATE TABLE tags  (id SERIAL PRIMARY KEY, names TEXT[]);

=head1 DEFLATION

=for highlighter language=perl

    my $ann = $orm->insert(users => {
        name    => 'Ann',
        prefs   => {theme => 'dark'},
        created => DateTime->new(
            year  => 2024,
            month => 1,
            day   => 2,
        ),
    });
    my $json = $ann->raw_field('prefs');      # '{"theme":"dark"}': what the database holds
    my $text = $ann->raw_field('created');    # '2024-01-02 00:00:00'

    my $bob = $orm->insert(users => {
        name  => 'Bob',
        prefs => '{"theme":"light"}',    # a plain value is sent as given: already JSON text
    });

A reference on a typed field is always deflated. A plain value is deflated
only when its type recognises it as an inflated value (the UUID type knows a
UUID string). A plain value on a JSON field is taken as JSON text already (is
C<123> a number or JSON?), so it goes as given. To store a Perl string as a
JSON string, encode it yourself (L<DBIx::QuickORM::Type::JSON>).

=head1 INFLATION

    my $prefs = $ann->field('prefs');                         # {theme => 'dark'}: inflated by the JSON type
    my $day   = $ann->field('created')->datetime_ref->day;    # 2

C<field> returns a typed field's value inflated by its type
(C<inflated_field>). A row class may change that default. C<raw_field>
returns it as the database returned it (L</DEFLATION>). An untyped field
gives the same from both.

See L<DBIx::QuickORM::Role::Row> for the row methods, and
L<DBIx::QuickORM::Manual::Types> to write a type.

=head1 SQL

    use DBIx::QuickORM::Value qw/raw inflated binary sql/;

    my $cy = $orm->insert(users => {
        name    => 'Cy',
        created => sql('now() - ?::interval', '1 day'),    # literal SQL, with binds
    });

    # the value the database computed, read back through RETURNING
    my $when = $cy->field('created');

    $cy->update({name => sql('upper(name)')});

    my $post = $orm->insert(posts => {
        user_id => $cy->field('id'),
        title   => 'Hi',
    });

    my $bumped = $orm->handle('posts')
        ->where({user_id => $cy->field('id')})
        ->update({views => sql('views + 1')});    # 1: one row changed

    my @recent = $orm->handle('users')
        ->where({created => {'>=' => sql('now() - ?::interval', '1 hour')}})
        ->all;

Write the SQL yourself: nothing in it is quoted, so pass values through C<?>
placeholders. Their binds are sent without a declared type, so the database
decides.

C<sql()> is rejected in primary key lookups (L<DBIx::QuickORM::Manual::Keys>)
and compare-and-swap comparisons. In an insert or update it can set any field,
and C<RETURNING> reads the value back. Without it (MySQL, and MariaDB for
updates, see L<DBIx::QuickORM::Manual::Dialects/RETURNING>) the field is
fetched when first read, and setting a primary key with C<sql()> in an update
croaks, since the new key could not be known.

On MySQL, an insert that computes a single-field primary key with C<sql()>
runs, then croaks, since the key cannot be read back. An C<AUTO_INCREMENT>
key is the exception: MySQL reports the value it stored.

=head1 RAW

    my $eve = $orm->insert(
        users => {
            name    => 'Eve',
            prefs   => '{}',
            created => '2024-01-02 03:04:05',
        },
        raw => 1,    # values are already in database form
    );

    # a PostgreSQL array: a reference on a field without a type, sent as is
    my $tag = $orm->insert(tags => {names => raw(['perl', 'sql'])});

C<raw> sends a value as it is, whatever its field's type would do with it.
Without a marker or C<< raw => 1 >>, a reference on a field without a type
croaks, since nothing can deflate it.

C<< raw => 1 >> is an option of C<insert>, C<insert_many>
(L<DBIx::QuickORM::Manual::BulkInsert>), and the CRUD operations.
A row's C<update> takes none: mark each value instead.

    $eve->update({created => raw('2024-02-03 04:05:06')});

=head1 INFLATED

    my $fay = $orm->insert(
        users => {
            name    => 'Fay',
            created => '2024-01-02 03:04:05',
            prefs   => inflated({theme => 'dark'}),    # deflate this one anyway
        },
        raw => 1,
    );

    my $cutoff = DateTime->new(
        year  => 2024,
        month => 6,
        day   => 1,
    );

    my @before = $orm->handle('users')
        # a where sends values as given: mark one to deflate
        ->where({created => {'<' => inflated($cutoff)}})
        ->order_by('id')
        ->all;

=head1 BINARY

    my $bytes = pack('C*', 0, 255, 10, 13);
    my $file  = $orm->insert(files => {
        name => 'blob',
        data => $bytes,    # a BYTEA field is bound as binary automatically
    });

    # so is a where on the table
    my $same = $orm->handle('files')->where({data => $bytes})->only;

    # raw SQL has no column information, so mark the bytes
    my $found = $orm->handle(\'SELECT * FROM files')->where({data => binary($bytes)})->only;

=head1 WHICH ONE

=over 4

=item *

On insert or update, pass a hashref for a JSON field or a DateTime for a
timestamp: the type deflates them. Text already in database form goes
directly.

=item *

A value the database should compute: C<sql>.

=item *

A reference on a field without a type, or a value its type must not touch:
C<raw>.

=item *

Inflated data under C<< raw => 1 >>, or in a C<where>: C<inflated>.

=item *

Bytes in a query over raw SQL: C<binary>.

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
