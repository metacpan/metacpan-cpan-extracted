package DBIx::QuickORM::Schema::Table;
use strict;
use warnings;

our $VERSION = '0.000011';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key merge_hash_of_objs clone_hash_of_objs/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Linked';

use DBIx::QuickORM::Util::HashBase qw{
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

sub is_view { 0 }
sub name    { $_[0]->{+NAME}    //= $_[0]->{+DB_NAME} }
sub db_name { $_[0]->{+DB_NAME} //= $_[0]->{+NAME} }
sub _links  { delete $_[0]->{+_LINKS} }

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

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+COLUMNS}     //= merge_hash_of_objs($self->{+COLUMNS}, $other->{+COLUMNS}) if $self->{+COLUMNS}     || $other->{+COLUMNS};
    $params{+UNIQUE}      //= merge_hash_of_objs($self->{+UNIQUE}, $other->{+UNIQUE})   if $self->{+UNIQUE}      || $other->{+UNIQUE};
    $params{+LINKS}       //= [@{$self->{+LINKS}}, @{$other->{+LINKS}}]                 if $self->{+LINKS}       || $other->{+LINKS};
    $params{+INDEXES}     //= [@{$self->{+INDEXES}}, @{$other->{+INDEXES}}]             if $self->{+INDEXES}     || $other->{+INDEXES};
    $params{+PRIMARY_KEY} //= [@{$self->{+PRIMARY_KEY}}]                                if $self->{+PRIMARY_KEY} || $other->{+PRIMARY_KEY};

    return blessed($self)->new(%$self, %$other, %params);
}

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

sub columns      { values %{$_[0]->{+COLUMNS}} }
sub column_names { sort keys %{$_[0]->{+COLUMNS}} }

sub column {
    my $self = shift;
    my ($cname) = @_;

    return $self->{+COLUMNS}->{$cname} // undef;
}

# QuerySource role implementation
{
    with 'DBIx::QuickORM::Role::Source';

    use DBIx::QuickORM::Util::HashBase qw{
        +fields_to_fetch
        +fields_to_omit
        +fields_list_all
    };

    sub source_db_moniker  { $_[0]->{+DB_NAME} }
    sub source_orm_name { $_[0]->{+NAME} }

    # row_class     # In HashBase at top of file
    # primary_key   # In HashBase at top of file

    sub field_type {
        my $self = shift;
        my ($field) = @_;
        my $col = $self->{+COLUMNS}->{$field} or croak "No column '$field' in table '$self->{+NAME}' ($self->{+DB_NAME})";
        my $type = $col->type or return undef;
        return undef if ref($type);
        return $type if $type->DOES('DBIx::QuickORM::Role::Type');
        return undef;
    }

    sub field_affinity {
        my $self = shift;
        my ($field, $dialect) = @_;
        my $col = $self->{+COLUMNS}->{$field} or croak "No column '$field' in table '$self->{+NAME}' ($self->{+DB_NAME})";
        return $col->affinity($dialect);
    }

    sub has_field { $_[0]->{+COLUMNS}->{$_[1]} ? 1 : 0 }

    sub fields_to_fetch  { $_[0]->{+FIELDS_TO_FETCH}  //= [ map { $_->name } grep { !$_->omit } values %{$_[0]->{+COLUMNS}} ] }
    sub fields_to_omit   { $_[0]->{+FIELDS_TO_OMIT}   //= [ map { $_->name } grep { $_->omit }  values %{$_[0]->{+COLUMNS}} ] }
    sub fields_list_all  { $_[0]->{+FIELDS_LIST_ALL}  //= [ map { $_->name }                    values %{$_[0]->{+COLUMNS}} ] }
}

1;
