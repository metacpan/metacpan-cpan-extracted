package DBIx::QuickORM::Schema::Table::Column;
use strict;
use warnings;

our $VERSION = '0.000023';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;

use DBIx::QuickORM::Affinity qw{
    validate_affinity
    affinity_from_type
};

use Object::HashBase qw{
    +name
    <sql_default
    <perl_default
    <omit
    <order
    <nullable
    <identity
    <generated
    +affinity
    <type
    <created
    <compiled
    +db_name
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Schema::Table::Column - Metadata for a single table column.

=head1 DESCRIPTION

Holds the schema metadata for one column: its name, ordinal position,
nullability, identity flag, defaults, type, and storage affinity. The
affinity is resolved lazily from an explicit value, a scalar-ref type name,
or a type object, and cached.

User-provided columns and introspected columns can be combined with C<merge>,
where the other column's values win.

=head1 SYNOPSIS

    my $col = DBIx::QuickORM::Schema::Table::Column->new(
        name  => 'id',
        order => 1,
        type  => \'integer',
    );

    my $affinity = $col->affinity;

=head1 ATTRIBUTES

=over 4

=item name

The column's ORM (schema) name. Defaults to C<db_name>.

=item db_name

The column's name in the database. Defaults to C<name>.

=item sql_default

The column's SQL-level default.

=item perl_default

A Perl-side default value or generator.

=item omit

True if the column should be omitted from default fetches.

=item order

The column's ordinal position in the table.

=item nullable

True if the column accepts NULL.

=item identity

True if the column is an identity / auto-increment column.

=item generated

True if the column's value is computed by the database (a stored or virtual
C<GENERATED> column). Generated columns are readable on fetch but are excluded
from C<INSERT> and C<UPDATE> column lists, and setting one via the row layer
croaks.

=item affinity

Storage affinity; resolved from C<type> on demand if not given.

=item type

The column type: a scalar ref naming a SQL type, or a type object.

=item created

Human-readable note of where the column was defined.

=item compiled

Cached compiled form of the column.

=back

=cut

sub name    { $_[0]->{+NAME}    //= $_[0]->{+DB_NAME} }
sub db_name { $_[0]->{+DB_NAME} //= $_[0]->{+NAME} }

sub init {
    my $self = shift;

    $self->{+DB_NAME} //= $self->{+NAME};
    $self->{+NAME}    //= $self->{+DB_NAME};

    my $debug = $self->{+CREATED} ? " (defined in $self->{+CREATED})" : "";

    croak "A 'name' is a required${debug}"           unless $self->{+NAME};
    croak "Column must have an order number${debug}" unless $self->{+ORDER};
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $name = $col->name

The column's ORM (schema) name.

=item $name = $col->db_name

The column's name in the database.

=item $affinity = $col->affinity($dialect)

Return the column's storage affinity, resolving and caching it from the type
when not set explicitly. Croaks when no affinity is set and none can be
derived from the type.

=cut

sub affinity {
    my $self = shift;
    my ($dialect) = @_;

    return $self->{+AFFINITY} if $self->{+AFFINITY};

    my $debug = $self->{+CREATED} ? " (defined in $self->{+CREATED})" : "";
    my $type = $self->{+TYPE} or croak "No affinity specified, and no type provided${debug}";

    if (ref($type) eq 'SCALAR') {
        $self->{+AFFINITY} //= affinity_from_type($$type);

        croak "'affinity' was not provided, and could not be derived from type '$$type'${debug}"
            unless $self->{+AFFINITY};

        croak "'$self->{+AFFINITY}' is not a valid affinity${debug}"
            unless validate_affinity($self->{+AFFINITY});

        return $self->{+AFFINITY};
    }

    croak "'$type' is not a valid type${debug}" unless $type->DOES('DBIx::QuickORM::Role::Type');

    return $self->{+AFFINITY} = $type->qorm_affinity(column => $self, dialect => $dialect);
}

=pod

=item $col = $col->merge($other, %params)

Return a new column combining this column with another (and any extra
params), where the other column's values and the params win.

=cut

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    return ref($self)->new(%$self, %$other, %params);
}

=pod

=item $copy = $col->clone(%params)

Return a copy of this column with any passed params overriding its values.

=back

=cut

sub clone {
    my $self   = shift;
    my %params = @_;

    return ref($self)->new(%$self, %params);
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
