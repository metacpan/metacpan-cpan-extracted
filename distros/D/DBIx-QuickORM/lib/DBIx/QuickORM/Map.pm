package DBIx::QuickORM::Map;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;

use Object::HashBase qw{
    <tables
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Map - The database map: tables, fields, and keys as plain data.

=head1 DESCRIPTION

One object over plain nested data (strings, hashes, and arrays only, plus a
field's C<format> code reference), keyed by table name. The ORM builds it in
its constructor. After that, treat the map and everything its methods return
as read-only.

    {
        users => {
            fields => {
                id => {
                    affinity => 'numeric',
                    db_type  => 'integer',
                    type     => 'integer',
                },
                name => {
                    affinity => 'string',
                    db_type  => 'varchar(255)',
                    type     => 'varchar',
                    size     => 255,
                },
                prefs => {
                    affinity => 'string',
                    db_type  => 'jsonb',
                    type     => 'jsonb',
                    orm_type => 'DBIx::QuickORM::Type::JSON',
                },
            },
            pk             => ['id'],                          # undef when the table has none
            # each sorted, and the primary key is not repeated
            unique         => [['email']],
            fk             => {orgs => [{org_id => 'id'}]},    # several links may name one table
            default_fields => ['id', 'name'],                  # absent: every field
            # absent: the ORM's default, undef: hashrefs
            row_class      => 'My::User',
        },
    }

C<db_type> is the field's type as the database reports it, C<type> its
lowercased base name, C<size> its declared length or precision when it has
one, and C<affinity> one of C<string>, C<numeric>, C<binary>, or C<boolean>.
C<orm_type> is the type class chosen for the field, if any, and C<format> and
C<generate> its hints (see L<DBIx::QuickORM::Role::Type/Field hints>).
C<passthrough> is 1 when that type's C<inflate> returns the raw value
unchanged for the field (C<inflate_is_identity>). The ORM sets it, and rows
then skip inflating the field. C<db_fills> is 1 when the database fills the
column when an insert leaves it out, and C<db_refuses_value> is 1 when it
rejects an explicit value for it. Both come from the scan and are absent
otherwise. A hand-written map without them reads as "no", so C<prefer_db>
generates and the C<prefer_orm> build croak cannot fire. C<pk_types> holds
the C<orm_type> of each primary key field, in key order, for the lookup
table. The ORM sets it only when a key field has a type.

A scanned field record also holds its own C<table> and C<name> (left out
above), so messages can name the field.

Names are exact and case-sensitive, and a table or field named C<0> works. A
foreign key may name a table that is not in the map.

=head1 SYNOPSIS

    my $map = $orm->db_map;

    if (my $field = $map->field(users => 'name')) { ... }
    my $pk = $map->pk('users');

    my $copy = $map->clone;

=head1 ATTRIBUTES

=over 4

=item \%tables = $map->tables

The data, as shown above. Required.

=back

=cut

sub init {
    my $self = shift;
    croak "'tables' must be a hashref" unless ref($self->{+TABLES}) eq 'HASH';
}

=head1 PUBLIC METHODS

=over 4

=item $map = DBIx::QuickORM::Map->new(tables => \%tables)

Holds C<\%tables> as given, without copying it. Croaks unless it is a hashref.

=item $copy = $map->clone

A new map over a deep copy of the data. Code references (a field's
C<format>) are kept as they are. Any other reference but a plain hash or
array croaks.

=back

=cut

sub clone {
    my $self = shift;
    return ref($self)->new(tables => $self->_copy($self->{+TABLES}));
}

=pod

=over 4

=item \%table = $map->table($name)

=item \%field = $map->field($table, $name)

The record, or undef when there is none.

=back

=cut

sub table {
    my $self = shift;
    my ($name) = @_;
    return $self->{+TABLES}->{$name};
}

sub field {
    my $self = shift;
    my ($table, $name) = @_;
    my $t = $self->{+TABLES}->{$table} or return undef;
    return $t->{fields}->{$name};
}

=pod

=over 4

=item \@fields = $map->pk($table)

The primary key fields in key order, or undef when the table has none. Croaks
when there is no such table.

=back

=cut

sub pk {
    my $self    = shift;
    my ($table) = @_;
    my $t       = $self->{+TABLES}->{$table} or croak "The table '$table' is not in the database map";
    return $t->{pk};
}

=pod

=over 4

=item \@values = $map->normalize_pk($table, $pk)

The primary key values of C<$table>, in key order, from any key form. It
judges the form, not the values: they come back as given, and deflating them
is the caller's job (the ORM's key arguments do it).

=over 4

=item *

A hashref holding the key fields. Other fields are ignored, so row data works.

=item *

A row object (any object with C<row_data>), taken as its row data.

=item *

An arrayref of the values, in the primary key's declared order.

=item *

A single value, for a single-field key. Any blessed object that is not a row
is a value, such as a C<DateTime> or a value marker.

=back

Croaks when the table has no primary key, on a single value for a compound
key, on an arrayref of the wrong length, on a missing or undef key value, and
on an unblessed reference that is not a hash or an array.

=back

=cut

sub normalize_pk {
    my $self = shift;
    my ($table, $pk) = @_;

    my $fields = $self->pk($table);
    confess "The table '$table' has no primary key" unless $fields && @$fields;
    my $names = join(', ' => @$fields);

    $pk = $pk->row_data if blessed($pk) && $pk->can('row_data');

    my @values;
    if (ref($pk) eq 'HASH') {
        @values = map { $pk->{$_} } @$fields;
    }
    elsif (ref($pk) eq 'ARRAY') {
        confess "The table '$table' has " . @$fields . " primary key field(s) ($names), but the arrayref holds " . @$pk . " value(s)" unless @$pk == @$fields;
        @values = @$pk;
    }
    else {
        confess "Primary key must be a value, an arrayref, a hashref, or a row; got $pk"                                                          if ref($pk) && !blessed($pk);
        confess "The table '$table' has a compound primary key ($names); give a hashref of its fields or an arrayref of its values in that order" if @$fields > 1;
        @values = ($pk);
    }

    for my $i (0 .. $#$fields) {
        confess "The primary key field '$fields->[$i]' of the table '$table' is missing or undefined" unless defined $values[$i];
    }

    return \@values;
}

=head1 PRIVATE METHODS

=over 4

=item $copy = $map->_copy($data)

A deep copy of map data, with the croak C<clone> documents.

=back

=cut

sub _copy {
    my $self = shift;
    my ($data) = @_;

    my $type = ref($data) or return $data;
    return $data                                                 if $type eq 'CODE';    # a field's format, which nothing changes
    return {map { $_ => $self->_copy($data->{$_}) } keys %$data} if $type eq 'HASH';
    return [map { $self->_copy($_) } @$data]                     if $type eq 'ARRAY';
    croak "The database map holds only strings, hashes, arrays, and code references, found a '$type' reference";
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
