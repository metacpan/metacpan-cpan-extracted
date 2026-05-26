package DBIx::QuickORM::Schema::Table;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key merge_hash_of_objs clone_hash_of_objs/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Linked';

use Object::HashBase qw{
    +name
    +db_name
    +columns
    <unique
    <row_class
    <row_class_autofill
    <created
    <compiled
    <is_temp
    <links
    <indexes
    <primary_key
    +_links
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Schema::Table - Object representing a single table in a schema.

=head1 DESCRIPTION

Represents a single table (or view) in a schema, including its columns, unique
constraints, indexes, primary key, and links to other tables. Also serves as a
query source via L<DBIx::QuickORM::Role::Source>.

=head1 SYNOPSIS

    my $table = $schema->table('users');

    my @columns = $table->columns;
    my $col     = $table->column('email');

=head1 ATTRIBUTES

=over 4

=item name

The schema (ORM) name for the table. Defaults to C<db_name>.

=item db_name

The name of the table in the database. Defaults to C<name>.

=item columns

Hashref of column name to L<DBIx::QuickORM::Schema::Table::Column> instance.

=item unique

Hashref of unique constraints keyed by column key.

=item row_class

The row class used when fetching rows from this table.

=item row_class_autofill

Autofill object used to generate row class accessors, if any.

=item created

Trace string for where the table was initially defined.

=item compiled

Trace string for where the table was compiled.

=item is_temp

True if the table is temporary.

=item links

Arrayref of L<DBIx::QuickORM::Link> objects connecting this table to others.

=item indexes

Arrayref of index definitions.

=item primary_key

Arrayref of column names making up the primary key.

=back

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $bool = $table->is_view()

True if this source is a view. Always false for a plain table.

=item $name = $table->name()

The schema (ORM) name for the table.

=item $name = $table->db_name()

The name of the table in the database.

=item @columns = $table->columns()

Get all column objects.

=item @names = $table->column_names()

Get all column names, sorted.

=cut

sub is_view { 0 }
sub name    { $_[0]->{+NAME}    //= $_[0]->{+DB_NAME} }
sub db_name { $_[0]->{+DB_NAME} //= $_[0]->{+NAME} }

sub columns      { values %{$_[0]->{+COLUMNS}} }
sub column_names { sort keys %{$_[0]->{+COLUMNS}} }

=pod

=item $col_or_undef = $table->column($name)

Get the column with the given name, or undef if it does not exist.

=cut

sub column {
    my $self = shift;
    my ($cname) = @_;

    return $self->{+COLUMNS}->{$cname} // undef;
}

=pod

=item $new_table = $table->merge($other, %params)

Merge two table objects into a third.

=cut

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+COLUMNS}     //= merge_hash_of_objs($self->{+COLUMNS}, $other->{+COLUMNS}) if $self->{+COLUMNS}     || $other->{+COLUMNS};
    $params{+UNIQUE}      //= merge_hash_of_objs($self->{+UNIQUE}, $other->{+UNIQUE})   if $self->{+UNIQUE}      || $other->{+UNIQUE};
    $params{+LINKS}       //= [@{$self->{+LINKS}}, @{$other->{+LINKS}}]                 if $self->{+LINKS}       || $other->{+LINKS};
    $params{+INDEXES}     //= [@{$self->{+INDEXES}}, @{$other->{+INDEXES}}]             if $self->{+INDEXES}     || $other->{+INDEXES};
    $params{+PRIMARY_KEY} //= [@{$self->{+PRIMARY_KEY} // $other->{+PRIMARY_KEY}}]        if $self->{+PRIMARY_KEY} || $other->{+PRIMARY_KEY};

    return blessed($self)->new(%$self, %$other, %params);
}

=pod

=item $new_table = $table->clone(%params)

Create a copy of the table, with any attributes you wish to have changed in the
copy.

=back

=cut

sub clone {
    my $self = shift;
    my (%params) = @_;

    $params{+COLUMNS}     //= clone_hash_of_objs($self->{+COLUMNS}) if $self->{+COLUMNS};
    $params{+UNIQUE}      //= clone_hash_of_objs($self->{+UNIQUE})  if $self->{+UNIQUE};
    $params{+LINKS}       //= [@{$self->{+LINKS}}]                  if $self->{+LINKS};
    $params{+INDEXES}     //= [@{$self->{+INDEXES}}]                if $self->{+INDEXES};
    $params{+PRIMARY_KEY} //= [@{$self->{+PRIMARY_KEY}}]            if $self->{+PRIMARY_KEY};

    return blessed($self)->new(%$self, %params);
}

sub init {
    my $self = shift;

    $self->{+DB_NAME} //= $self->{+NAME};
    $self->{+NAME}    //= $self->{+DB_NAME};
    croak "The 'name' attribute is required" unless $self->{+NAME};

    my $debug = $self->{+CREATED} ? " (defined in $self->{+CREATED})" : "";

    my $cols = $self->{+COLUMNS} //= {};
    croak "The 'columns' attribute must be a hashref${debug}" unless ref($cols) eq 'HASH';

    for my $cname (sort keys %$cols) {
        my $cval = $cols->{$cname} or croak "Column '$cname' is empty${debug}";
        croak "Columns '$cname' is not an instance of 'DBIx::QuickORM::Schema::Table::Column', got: '$cval'$debug" unless blessed($cval) && $cval->isa('DBIx::QuickORM::Schema::Table::Column');
    }

    if (my $pk = $self->{+PRIMARY_KEY}) {
        for my $cname (@$pk) {
            my $col = $self->{+COLUMNS}->{$cname} or croak "Primary Key column '$cname' is not present in the column list";
            croak "Primary key column '$cname' is set to be omitted, this is not allowed" if $col->omit;
        }
    }

    $self->{+UNIQUE}  //= {};
    $self->{+LINKS}   //= [];
    $self->{+INDEXES} //= [];
}

# {{{ Role::Source interface

with 'DBIx::QuickORM::Role::Source';

use Object::HashBase qw{
    +fields_to_fetch
    +fields_to_omit
    +fields_list_all
};

=pod

=head1 QUERY SOURCE METHODS

These satisfy the L<DBIx::QuickORM::Role::Source> interface.

=over 4

=item $name = $table->source_db_moniker()

The table's database name, as used in SQL.

=item $name = $table->source_orm_name()

The table's schema (ORM) name.

=item $bool = $table->has_field($name)

True if the table has a column with the given name.

=cut

sub source_db_moniker { $_[0]->{+DB_NAME} }
sub source_orm_name   { $_[0]->{+NAME} }

# row_class     # In HashBase at top of file
# primary_key   # In HashBase at top of file

sub has_field { $_[0]->{+COLUMNS}->{$_[1]} ? 1 : 0 }

=pod

=item $list = $table->fields_to_fetch()

Arrayref of column names to fetch (omitting columns flagged C<omit>).

=item $list = $table->fields_to_omit()

Arrayref of column names flagged to be omitted.

=item $list = $table->fields_list_all()

Arrayref of all column names.

=cut

sub fields_to_fetch { $_[0]->{+FIELDS_TO_FETCH} //= [ map { $_->name } grep { !$_->omit } values %{$_[0]->{+COLUMNS}} ] }
sub fields_to_omit  { $_[0]->{+FIELDS_TO_OMIT}  //= [ map { $_->name } grep { $_->omit }  values %{$_[0]->{+COLUMNS}} ] }
sub fields_list_all { $_[0]->{+FIELDS_LIST_ALL} //= [ map { $_->name }                    values %{$_[0]->{+COLUMNS}} ] }

=pod

=item $type_or_undef = $table->field_type($field)

The L<DBIx::QuickORM::Role::Type> object for a field, or undef if the field has
no type object.

=cut

sub field_type {
    my $self = shift;
    my ($field) = @_;
    my $col = $self->{+COLUMNS}->{$field} or croak "No column '$field' in table '$self->{+NAME}' ($self->{+DB_NAME})";
    my $type = $col->type or return undef;
    return undef if ref($type);
    return $type if $type->DOES('DBIx::QuickORM::Role::Type');
    return undef;
}

=pod

=item $affinity = $table->field_affinity($field, $dialect)

The affinity for a field, optionally for a specific dialect.

=back

=cut

sub field_affinity {
    my $self = shift;
    my ($field, $dialect) = @_;
    my $col = $self->{+COLUMNS}->{$field} or croak "No column '$field' in table '$self->{+NAME}' ($self->{+DB_NAME})";
    return $col->affinity($dialect);
}

# }}} Role::Source interface

=pod

=head1 PRIVATE METHODS

=over 4

=item $links = $table->_links()

Internal accessor that fetches and clears the pending raw link definitions.

=back

=cut

sub _links { delete $_[0]->{+_LINKS} }

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
