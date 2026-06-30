package DBIx::QuickORM::Schema::Table;
use strict;
use warnings;

our $VERSION = '0.000026';

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
    +db_to_orm
    +has_aliases
    <primary_key_override
    +fields_to_fetch
    +fields_to_omit
    +fields_list_all
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

=item primary_key_override

True when this table's declared primary key is an intentional override.
During a merge, a declared primary key that conflicts with the introspected
one is an error unless this flag is set, in which case the declared key wins.

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

Merge two table objects into a third. The other table provides the ORM column
names; columns in this table (typically introspected and keyed by database
name) are re-keyed onto those ORM names when they refer to the same database
column, and the primary key is translated to ORM names, so the merged table is
uniformly ORM-keyed.

When both tables define a primary key the column sets must match (compared in
ORM-name space); a mismatch croaks unless the other (declared) table has the
C<primary_key_override> flag set, in which case its key wins.

=cut

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    my $mine   = $self->{+COLUMNS};
    my $theirs = $other->{+COLUMNS};

    my $db_to_orm = $theirs ? $other->_db_to_orm : {};

    if (!$params{+COLUMNS} && ($mine || $theirs)) {
        $params{+COLUMNS} = merge_hash_of_objs($self->_rekey_columns($mine // {}, $db_to_orm), $theirs // {});
    }

    $params{+UNIQUE}  //= merge_hash_of_objs($self->_retranslate_unique($self->{+UNIQUE}, $db_to_orm), $other->{+UNIQUE}) if $self->{+UNIQUE} || $other->{+UNIQUE};
    $params{+LINKS}   //= [@{$self->{+LINKS}}, @{$other->{+LINKS}}]                                                      if $self->{+LINKS} || $other->{+LINKS};
    $params{+INDEXES} //= [@{$self->_retranslate_indexes($self->{+INDEXES}, $db_to_orm)}, @{$other->{+INDEXES} // []}]   if $self->{+INDEXES} || $other->{+INDEXES};

    if (!$params{+PRIMARY_KEY} && ($self->{+PRIMARY_KEY} || $other->{+PRIMARY_KEY})) {
        $params{+PRIMARY_KEY} = $self->_merge_primary_key($other, $db_to_orm);
    }

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

    # Drop derived caches carried in from a merge/clone; they are rebuilt lazily
    # from this object's own columns.
    delete $self->{+DB_TO_ORM};
    delete $self->{+HAS_ALIASES};
    delete $self->{+FIELDS_TO_FETCH};
    delete $self->{+FIELDS_TO_OMIT};
    delete $self->{+FIELDS_LIST_ALL};

    $self->{+DB_NAME} //= $self->{+NAME};
    $self->{+NAME}    //= $self->{+DB_NAME};
    croak "The 'name' attribute is required" unless $self->{+NAME};

    my $debug = $self->{+CREATED} ? " (defined in $self->{+CREATED})" : "";

    my $cols = $self->{+COLUMNS} //= {};
    croak "The 'columns' attribute must be a hashref${debug}" unless ref($cols) eq 'HASH';

    my %db_to_orm;
    for my $cname (sort keys %$cols) {
        my $cval = $cols->{$cname} or croak "Column '$cname' is empty${debug}";
        croak "Columns '$cname' is not an instance of 'DBIx::QuickORM::Schema::Table::Column', got: '$cval'$debug" unless blessed($cval) && $cval->isa('DBIx::QuickORM::Schema::Table::Column');

        my $db = $cval->db_name;
        if (defined(my $other = $db_to_orm{$db})) {
            croak "Columns '$other' and '$cname' both map to database column '$db'${debug}";
        }
        $db_to_orm{$db} = $cname;

        # A column's database name must not collide with a different column's
        # ORM name, or lookups (which resolve ORM name first) would silently
        # shadow this column's database name.
        if ($db ne $cname && $cols->{$db}) {
            croak "Column '$cname' has database name '$db', which is also the ORM name of another column${debug}";
        }
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

=pod

=head1 QUERY SOURCE METHODS

These satisfy the L<DBIx::QuickORM::Role::Source> interface.

=over 4

=item $name = $table->source_db_moniker()

The table's database name, as used in SQL.

=item $name = $table->source_orm_name()

The table's schema (ORM) name.

=item $bool = $table->has_field($name)

True if the table has a column with the given name. Accepts either the column's
ORM name or its database name.

=item $db_name = $table->field_db_name($name)

The database column name for a field. Accepts either the ORM name or the
database name and always returns the database name; an unknown name is returned
unchanged.

=item $orm_name = $table->field_orm_name($name)

The ORM column name for a field. Accepts either the ORM name or the database
name and always returns the ORM name; an unknown name is returned unchanged.

=item $bool = $table->field_is_generated($name)

True if the named field is a database-generated column (C<GENERATED ALWAYS>,
stored or virtual). Accepts either the ORM or database name. Unknown names
return false.

=item $bool = $table->source_has_aliases()

True when any column's ORM name differs from its database name. Cached. Lets
callers skip name translation entirely when there is nothing to translate.

=cut

sub source_db_moniker { $_[0]->{+DB_NAME} }
sub source_orm_name   { $_[0]->{+NAME} }

# row_class     # In HashBase at top of file
# primary_key   # In HashBase at top of file

sub has_field { $_[0]->_column($_[1]) ? 1 : 0 }

sub source_has_aliases { $_[0]->{+HAS_ALIASES} //= (grep { $_->name ne $_->db_name } values %{$_[0]->{+COLUMNS}}) ? 1 : 0 }

sub field_db_name {
    my $self = shift;
    my ($name) = @_;
    my $col = $self->_column($name) or return $name;
    return $col->db_name;
}

sub field_orm_name {
    my $self = shift;
    my ($name) = @_;
    my $col = $self->_column($name) or return $name;
    return $col->name;
}

sub field_is_generated {
    my $self = shift;
    my ($name) = @_;
    my $col = $self->_column($name) or return 0;
    return $col->generated ? 1 : 0;
}

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
    my $col = $self->_column($field) or croak "No column '$field' in table '$self->{+NAME}' ($self->{+DB_NAME})";
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
    my $col = $self->_column($field) or croak "No column '$field' in table '$self->{+NAME}' ($self->{+DB_NAME})";
    return $col->affinity($dialect);
}

# }}} Role::Source interface

=pod

=head1 PRIVATE METHODS

=over 4

=item $links = $table->_links()

Internal accessor that fetches and clears the pending raw link definitions.

=item $pk = $table->_merge_primary_key($other, \%db_to_orm)

Resolve the merged primary key (in ORM-name space) for C<merge>. When only
one side defines a key it wins; identical sets pass through; a conflict
croaks unless the other table has C<primary_key_override> set.

=item $col_or_undef = $table->_column($name)

Resolve a column object by either its ORM name or its database name.

=item $map = $table->_db_to_orm()

Lazily-built hashref mapping each column's database name to its ORM name.

=item $hashref = $table->_rekey_columns(\%columns, \%db_to_orm)

Return a copy of a columns hashref re-keyed so each column lands under the ORM
name its database name maps to, falling back to the original key when there is
no mapping.

=item $hashref = $table->_retranslate_unique(\%unique, \%db_to_orm)

Return a copy of a unique-constraint hashref with each constraint's column list
(and its C<column_key> key) translated from database names to ORM names.

=item $arrayref = $table->_retranslate_indexes(\@indexes, \%db_to_orm)

Return a copy of an index list with each index's column list translated from
database names to ORM names. Index entries may be arrayrefs of column names or
hashrefs with a C<columns> arrayref; other shapes pass through.

=item $bool = $table->_has_alias(\%db_to_orm)

True when any database name in the map differs from its ORM name, i.e. real
aliasing is present.

=back

=cut

sub _links { delete $_[0]->{+_LINKS} }

sub _merge_primary_key {
    my $self = shift;
    my ($other, $db_to_orm) = @_;

    my $mine   = $self->{+PRIMARY_KEY};
    my $theirs = $other->{+PRIMARY_KEY};

    my @mine_orm = map { $db_to_orm->{$_} // $_ } @{$mine // []};

    return [@$theirs]  unless $mine && @$mine;
    return [@mine_orm] unless $theirs && @$theirs;

    return [@$theirs]  if $other->{+PRIMARY_KEY_OVERRIDE};
    return [@mine_orm] if column_key(@mine_orm) eq column_key(@$theirs);

    my $name = $other->{+NAME} // $self->{+NAME};
    croak "Table '$name' has conflicting primary keys: the database defines (" . join(', ' => @mine_orm) . ") but the declaration defines (" . join(', ' => @$theirs) . "). If the declared key is intentional, mark the declaration as an intentional override via the primary_key 'override' option";
}

sub _rekey_columns {
    my $self = shift;
    my ($cols, $db_to_orm) = @_;

    my %out;
    for my $key (keys %$cols) {
        my $col = $cols->{$key};
        my $orm = $db_to_orm->{$col->db_name} // $key;
        $out{$orm} = $col;
    }

    return \%out;
}

sub _retranslate_unique {
    my $self = shift;
    my ($unique, $db_to_orm) = @_;

    return $unique unless $unique && $self->_has_alias($db_to_orm);

    my %out;
    for my $key (keys %$unique) {
        my $val = $unique->{$key};
        unless (ref($val) eq 'ARRAY') {
            $out{$key} = $val;
            next;
        }
        my @orm = map { $db_to_orm->{$_} // $_ } @$val;
        $out{column_key(@orm)} = \@orm;
    }

    return \%out;
}

sub _retranslate_indexes {
    my $self = shift;
    my ($indexes, $db_to_orm) = @_;

    return $indexes // [] unless $indexes && @$indexes && $self->_has_alias($db_to_orm);

    return [
        map {
            my $ref = ref($_);
            if ($ref eq 'ARRAY') {
                [ map { $db_to_orm->{$_} // $_ } @$_ ];
            }
            elsif ($ref eq 'HASH') {
                my %spec = %$_;
                $spec{columns} = [ map { $db_to_orm->{$_} // $_ } @{$spec{columns}} ] if ref($spec{columns}) eq 'ARRAY';
                \%spec;
            }
            else {
                $_;
            }
        } @$indexes
    ];
}

sub _has_alias {
    my $self = shift;
    my ($db_to_orm) = @_;
    return 0 unless $db_to_orm;
    for my $db (keys %$db_to_orm) {
        return 1 if $db ne $db_to_orm->{$db};
    }
    return 0;
}

sub _db_to_orm { $_[0]->{+DB_TO_ORM} //= { map { $_->db_name => $_->name } values %{$_[0]->{+COLUMNS}} } }

sub _column {
    my $self = shift;
    my ($name) = @_;

    my $cols = $self->{+COLUMNS};
    return $cols->{$name} if $cols->{$name};

    my $orm = $self->_db_to_orm->{$name} or return undef;
    return $cols->{$orm};
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
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
