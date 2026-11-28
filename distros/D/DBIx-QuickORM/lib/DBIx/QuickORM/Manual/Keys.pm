package DBIx::QuickORM::Manual::Keys;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Keys - Primary keys: their forms, typed keys, the format hint, and generated keys, by example.

=head1 DESCRIPTION

Every primary key argument (C<find>, C<clear_cache>, C<refresh_row>) takes
the same four forms. A typed key (UUID, DateTime) matches the held row in any
form, and a UUID key can be generated when an insert leaves it out.

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

    CREATE TABLE memberships (
        user_id INTEGER NOT NULL REFERENCES users (id),
        team    TEXT NOT NULL,
        role    TEXT,
        PRIMARY KEY (user_id, team)
    );

    CREATE TABLE sessions  (id UUID PRIMARY KEY, owner TEXT);
    CREATE TABLE events    (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT);
    CREATE TABLE snapshots (taken TIMESTAMPTZ PRIMARY KEY, note TEXT);
    CREATE TABLE tokens    (token CHAR(36) PRIMARY KEY, note TEXT);

C<gen_random_uuid()> is built into PostgreSQL 13 and later. Earlier versions
need the C<pgcrypto> extension.

=head1 KEY FORMS

=for highlighter language=perl

    my $ann = $orm->find(users => $id);    # a single value, for a single-field key
    $ann = $orm->find(users => [$id]);     # an arrayref of the values, in the key's declared order

    # a hashref of the key fields (other fields are ignored, so row data works)
    $ann = $orm->find(users => {id => $id});

    # a row object (or its row data): read Ann's row again
    my $fresh = $orm->find(
        users => $ann,
        cache => 0,
    );

    $orm->insert(memberships => {
        user_id => $id,
        team    => 'ops',
        role    => 'lead',
    });

    my $member = $orm->find(memberships => {
        user_id => $id,    # a compound key
        team    => 'ops',
    });

    $member = $orm->find(memberships => [$id, 'ops']);    # user_id, then team: the declared order
    my $pk  = $member->pk;                                # {user_id => $id, team => 'ops'}

    $orm->clear_cache(memberships => [$id, 'ops']);    # the same forms

A single value for a compound key croaks, as does an arrayref of the wrong
length or a missing key field.

=head1 TYPED KEYS

    my $uuid    = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
    my $session = $orm->insert(sessions => {
        id    => $uuid,
        owner => 'Ann',
    });

    my $same = $orm->find(sessions => uc $uuid);    # the held row: a UUID key matches in upper or lower case

    my $taken = DateTime->new(
        year      => 2024,
        month     => 1,
        day       => 2,
        hour      => 3,
        time_zone => 'America/New_York',
    );
    my $snap = $orm->insert(snapshots => {
        taken => $taken,
        note  => 'nightly',
    });

    # the held row: the same instant
    my $again = $orm->find(snapshots => $taken->clone->set_time_zone('UTC'));

The ORM keys each held row (L<DBIx::QuickORM::Manual::Caching>) by its type's
I<canonical form>: one spelling for every form of the same value (lower-case
text for a UUID, the UTC instant for a timestamp with time zone). So every
form of one key finds the same row. The database gets the value as you pass
it, deflated.

A native C<uuid> column gets the UUID type from the scan. So does a text or
binary one with C<uuid> as a word of its name (C<uuid>, C<owner_uuid>,
C<uuid_v7>) and either no declared size or a UUID's (C<CHAR(36)>,
C<BINARY(16)>). Any other column gets no UUID type from the scan, so C<types>
names it, as C<tokens> shows next
(L<DBIx::QuickORM::Manual::Types/"REGISTERING TYPES">).

=head1 THE FORMAT HINT

    my $legacy = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        types => {
            tokens => {
                token => {
                    class  => 'UUID',
                    format => sub { uc $_[0] },    # the table stores upper-case text
                },
            },
        },
    );

    my $token = $legacy->insert(tokens => {
        token => $uuid,
        note  => 'legacy',
    });

    my $text = $token->raw_field('token');    # '0190A6E8-1D2C-7C3B-9F00-123456789ABC', as stored

    my $found = $legacy->find(
        tokens => $uuid,
        cache  => 0,    # the database gets the upper-case form too
    );

C<format> runs on the text a type's deflation produces for a non-binary
field: inserted values, changes, and key lookups. A text column compares
exact text, so without the hint a lower-case UUID would never match this
table.

Values sent as given bypass it: C<raw> values, and the values of a C<where>.
Wrap a C<where> value in C<inflated()> to deflate and format it
(L<DBIx::QuickORM::Manual::Values>).

C<< type_options => {UUID => {format => sub { uc $_[0] }}} >> sets the
default for UUID fields. A field's own C<format> wins.

=head1 GENERATED KEYS

    my $new = $orm->insert(sessions => {owner => 'Bob'});    # id left out: a new version 7 UUID
    my $id7 = $new->field('id');

    # the database fills id (gen_random_uuid), so the ORM leaves it alone
    my $event = $orm->insert(events => {name => 'start'});

Only a type with C<generate_key_value> generates a key. Of the built-in types
only UUID has one, so a DateTime key is never generated. A UUID primary key
an insert leaves out gets a value when the database does not fill the column.
The C<generate> hint changes that:

    my $v7_only = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # always generate, even over the database default
        types => {events => {id => {generate => 'prefer_orm'}}},
    );

    my $forced = $v7_only->insert(events => {name => 'forced'});

    my $never = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        type_options => {UUID => {generate => 'none'}},    # never generate, for every UUID field
    );

    # the database rejects the missing key
    my $ok = eval { $never->insert(sessions => {owner => 'Cy'}); 1 };

C<prefer_db> is the default. On MySQL, which cannot return a key the database
filled (L<DBIx::QuickORM::Manual::Dialects/RETURNING>), C<prefer_db> generates
an omitted UUID anyway. An C<AUTO_INCREMENT> id is still recovered after a
single-row insert. A given value always wins, and a compound key's typed part
is generated the same way.

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
