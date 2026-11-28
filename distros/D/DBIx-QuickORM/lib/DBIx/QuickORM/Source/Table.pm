package DBIx::QuickORM::Source::Table;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use Object::HashBase qw{
    <table
    <db_map
    +field_records
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Source';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Source::Table - A table as a source.

=head1 DESCRIPTION

A table in the map, as L<DBIx::QuickORM::Role::Source> describes. It holds
the table name and the map, and answers from the map. It is immutable: the ORM
builds one per table and C<< $orm->handle($table) >> reuses it.

=head1 SYNOPSIS

    my $source = DBIx::QuickORM::Source::Table->new(
        table  => 'users',
        db_map => $orm->db_map,
    );

    my $h = $orm->handle($source);

=head1 ATTRIBUTES

=over 4

=item $name = $source->table

Required. Croaks when the map has no such table.

=item $map = $source->db_map

Required: the L<DBIx::QuickORM::Map>.

=back

=cut

sub init {
    my $self = shift;

    my ($table, $map) = @{$self}{+TABLE, +DB_MAP};
    croak "A 'db_map' is required"                        unless $map;
    croak "A 'table' is required"                         unless defined($table) && length($table);
    croak "The table '$table' is not in the database map" unless $map->table($table);
}

=head1 PUBLIC METHODS

=over 4

=item \@fields = $source->pk

The table's primary key fields from the map, or undef when it has none.

=item () = $source->query_sql

An empty list: a table source has no SQL of its own to run.

=back

=cut

sub pk        { $_[0]->{+DB_MAP}->pk($_[0]->{+TABLE}) }
sub query_sql { () }

=pod

=over 4

=item \%fields = $source->field_records

The table's fields in the map, by name and qualified as C<table.field>.
Built on first use, then the same shared hash every call: do not change it.

=back

=cut

sub field_records {
    my $self = shift;
    return $self->{+FIELD_RECORDS} //= do {
        my $table  = $self->{+TABLE};
        my $fields = $self->{+DB_MAP}->table($table)->{fields};
        +{%$fields, map { ("$table.$_" => $fields->{$_}) } keys %$fields};
    };
}

=pod

=over 4

=item \@fields = $source->select_fields($given)

The fields to select. With no C<$given>, the table's C<default_fields>, or
every field sorted. For an arrayref, those fields with the primary key added,
without duplicates. Computed fields (a hashref) come back as they are.

Croaks for a name in the arrayref that is not a field of the table.

=back

=cut

sub select_fields {
    my $self = shift;
    my ($given) = @_;

    return $given if ref($given) eq 'HASH';

    my $t = $self->{+DB_MAP}->table($self->{+TABLE});
    if ($given) {
        $t->{fields}->{$_} or croak "The table '$self->{+TABLE}' has no field '$_'" for @$given;
        my %seen;
        return [grep { !$seen{$_}++ } @$given, @{$self->pk // []}];
    }

    return $t->{default_fields} // [sort keys %{$t->{fields}}];
}

=pod

=over 4

=item ($sql, \@binds) = $source->from_sql($dialect)

The quoted table name, with no binds.

=back

=cut

sub from_sql {
    my $self = shift;
    my ($dialect) = @_;
    return ($dialect->quote_identifier($self->{+TABLE}), []);
}

=pod

=over 4

=item (\@rows, \&build) = $source->results($orm, \@raw, $ingest, @class)

The rows, built as the ORM builds rows of the table, with the handle's
C<row_class> when given.

With a primary key and C<$ingest>, each row is ingested into the Connection's
lookup table and the canon row data kept. Otherwise the rows are kept as
fetched.

=back

=cut

sub results {
    my $self = shift;
    my ($orm, $raw, $ingest, @class) = @_;

    my $table = $self->{+TABLE};
    my $pk    = $self->pk;
    my $rows  = $raw;
    if ($ingest && $pk && @$pk) {
        my $lookup = $orm->connection->lookup;
        $rows = [map { $lookup->ingest($table, $_) } @$raw];
    }

    return ($rows, $orm->_row_builder($table, @class));
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
