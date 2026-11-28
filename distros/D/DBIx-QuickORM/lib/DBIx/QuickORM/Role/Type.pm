package DBIx::QuickORM::Role::Type;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use Storable();

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Type - The interface for field types.

=head1 DESCRIPTION

A type converts between the raw value a database stores and the inflated
value Perl code works with. A type is a class used through class methods. The
map names it by class (a field's C<orm_type>) and never holds objects. A type
needs C<inflate> and C<deflate>. This role supplies defaults for its other
methods.

The CRUD operations deflate the values they send (see
L<DBIx::QuickORM/"CRUD operations">), and row objects inflate field values
when they are read (see L<DBIx::QuickORM::Role::Row>). NULL is never passed to
C<inflate> or C<deflate>.

C<inflate> and C<deflate> get the map's record for the field and the
L<DBIx::QuickORM::Connection>, which gives the dialect
(C<< $conn->dialect >>) and the time zone (C<< $conn->time_zone >>).

A field record has C<table> and C<name> (the field's own), C<affinity>,
C<db_type>, C<type>, C<size>, C<orm_type> (this type's class), the hints
C<format> and C<generate>, and the scan facts C<db_fills> and
C<db_refuses_value>.
Any key may be missing. A hand-written record may have only some of them.
C<_for_field> turns C<table> and C<name> into text for croaks.

For C<autotype>, a type claims fields with C<base_types>, the base C<type>
names it takes, or C<matches($field_name, \%field, $dialect)>, for fields
known by name. It needs at least one of the two. A type used only through
C<types> needs neither. This role provides neither.

=head2 Cached inflated values

A row caches each value it inflates and hands a reader either the cached
value itself or a copy, so code changing a value it read cannot change what
the next reader gets. The type says which with
C<inflated_is_immutable_for_cache> and C<clone_inflated>.

A custom type takes one of two paths:

=over 4

=item *

It inflates to values nobody can change (plain strings, or objects that
hand out copies to change, as L<DBIx::QuickORM::Type::DateTime::Lazy>
does) and declares C<inflated_is_immutable_for_cache> true.

=item *

It leaves that false (the default), and provides C<clone_inflated> when
C<dclone> (L<Storable>) cannot copy its values.

=back

With it false, every read of a field of that type deep-copies the value (JSON
today). Code reading large values often may prefer C<raw_field>, or a type
with immutable values.

A type class that does not consume this role must provide
C<inflated_is_immutable_for_cache>, and C<clone_inflated> unless it is true.

=head2 Primary key fields

A type on a primary key field needs C<canonical_key_value> (see the
SYNOPSIS), which this role does not provide. Building the map croaks for a
key field whose type lacks it.

It returns the string the row cache files the key value under. It gets every
form a value can arrive in: database text, an inflated value, or what
C<deflate> returned. Every form of one value must give the same string. Keep
it fast: it runs for every row read from a table whose key it covers.

A field with no type is keyed by its value as it is.

=head2 Generated key values

A type may provide C<generate_key_value($field, $conn)>, which this role does
not. It returns a new inflated value for a primary key field an insert left
out. The insert deflates it like any given value. The field's C<generate>
hint decides when it is called.

L<DBIx::QuickORM::Type::UUID> provides one.

=head2 Field hints

A field may carry a C<format> code reference beside its type. After the type
deflates a value to plain text, the ORM sends what C<format> returns for it.
Binary fields are never formatted. Reads and the row cache are unchanged.

    # CREATE TABLE tokens (token CHAR(36) PRIMARY KEY, note TEXT)
    # -- a legacy table: UUIDs in upper case
    my $orm = DBIx::QuickORM->new(
        credentials => \%credentials,
        types       => {
            tokens => {
                token => {
                    class  => 'UUID',
                    format => sub { uc $_[0] },
                },
            },
        },
    );

    my $id = '0190a6e8-1d2c-7c3b-9f00-123456789abc';

    # stores 0190A6E8-...
    my $token = $orm->insert(
        tokens => {
            token => $id,
            note  => 'legacy',
        },
    );

    # looks up 0190A6E8-...
    my $same = $orm->find(
        tokens => $id,
        cache  => 0,
    );

That gives one field a format. C<type_options> gives one to every field of a
type, and a field's own wins:

    type_options => {UUID => {format => sub { uc $_[0] }}},

C<format> must be a code reference, on a field that has a type. C<lc> and
C<uc> are built-in functions, so C<\&lc> does not work: write
C<sub { lc $_[0] }>, or C<\&CORE::lc> on Perl 5.16 and later.

C<generate> says when a primary key field an insert leaves out gets a value
from its type's C<generate_key_value> (see L</Generated key values>):

=over 4

=item C<prefer_db> (the default)

When the database does not fill the column itself, or fills it on a backend
without C<RETURNING> on insert (MySQL), which could not return the value.
Auto-increment integer keys are unaffected: the last insert id reads them.

=item C<prefer_orm>

Always, even over a database default. Use it when the database's own values
are not the ones you want, such as UUIDs of another version.

=item C<none>

Never. On a backend without C<RETURNING>, a key that is not auto-increment
is then unknown after the insert, so call C<insert> in void context or pass
the key.

=back

It is given like C<format>: per field in C<types>, or per type in
C<type_options>, such as C<< {UUID => {generate => 'prefer_orm'}} >>.

C<prefer_orm> on a column that refuses values (PostgreSQL C<GENERATED ALWAYS
AS IDENTITY>) croaks when the map is built. A type without
C<generate_key_value> ignores the hint.

Whether the database fills a column comes from the scan. A map passed as
C<db_map> without those facts reads as "it does not", so C<prefer_db>
generates, and the C<prefer_orm> croak cannot fire.

=head1 SYNOPSIS

    package My::Type::Email;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';

    # claims fields named email
    sub matches { my ($class, $name, $field, $dialect) = @_; $name eq 'email' }

    sub inflate { my ($class, $raw,   $field, $conn) = @_; $raw }
    sub deflate { my ($class, $value, $field, $conn) = @_; lc $value }

    # needed on a primary key field
    sub canonical_key_value { my ($class, $value, $field, $conn) = @_; lc $value }

    sub is_inflated                     { 1 }    # deflate every plain value sent
    sub inflated_is_immutable_for_cache { 1 }    # plain strings: nothing to copy

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials     => \%credentials,
        append_autotype => ['+My::Type::Email'],
    );

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            email => 'Ann@Example.COM',
        },
    );

    my $email = $ann->field('email');    # ann@example.com

=head1 REQUIRED METHODS

=over 4

=item $value = $type->inflate($raw, \%field, $conn)

The inflated value for a raw value the database returned.

=item $raw = $type->deflate($value, \%field, $conn)

The raw value to send to the database for an inflated value.

=back

=cut

requires qw/inflate deflate/;

=head1 PUBLIC METHODS

=over 4

=item $bool = $type->is_inflated($value)

Whether a plain (non-reference) value is in inflated form and must be
deflated before it is sent. Undef by default.

True, false, or undef when the type cannot tell. The ORM deflates a plain
value only when this is true. A reference is always deflated.

=back

=cut

sub is_inflated { undef }

=pod

=over 4

=item $bool = $type->inflated_is_immutable_for_cache

True when nothing can change an inflated value, so a row may hand every reader
the one value it cached. False by default.

False means a row must hand out a copy made by C<clone_inflated>.

=back

=cut

sub inflated_is_immutable_for_cache { 0 }

=pod

=over 4

=item $bool = $type->inflate_is_identity(\%field)

True when C<inflate> returns its input unchanged for the field. False by
default.

A subclass that overrides C<inflate> must override C<inflate_is_identity> too.

The ORM asks once per field when it builds the map and marks such fields
C<passthrough> (see L<DBIx::QuickORM::Map>). Reading one then returns the raw
value with no C<inflate> call and nothing cached.

=back

=cut

sub inflate_is_identity { 0 }

=pod

=over 4

=item $copy = $type->clone_inflated($value)

A copy of an inflated value that shares nothing changeable with it.

Called on the type class with the value, which need not be an object. By
default a plain value is returned as it is and a reference is copied with
C<dclone> (L<Storable>), croaking when that cannot copy it (code references, for
instance).

=back

=cut

sub clone_inflated {
    my $class = shift;
    my ($value) = @_;
    return $value unless ref $value;

    my $copy;
    eval { $copy = Storable::dclone($value); 1 } or croak "$class cannot copy an inflated value with Storable::dclone, so it needs its own clone_inflated() or a true inflated_is_immutable_for_cache(): $@";
    return $copy;
}

=head1 PRIVATE METHODS

=over 4

=item $text = $type->_for_field(\%field)

The C<" for table.field"> suffix for a croak about a field: C<" for name">
when the record has a C<name> but no C<table>, and empty without a C<name>.
Use it as C<< croak "Bad value" . $class->_for_field($field) >>.

=back

=cut

sub _for_field {
    my $class = shift;
    my ($field) = @_;
    return '' unless $field && defined $field->{name};
    return ' for ' . join('.' => grep { defined } $field->{table}, $field->{name});
}

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
