package DBomb::Base::Private;

=head1 NAME

DBomb::Base::Private -  The private API for DBomb::Base

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.20 $';

use Carp::Assert;
use Carp qw(croak);
use DBomb::Query;
use DBomb::GluedQuery;
use DBomb::GluedUpdate;
use DBomb::Query::Update;
use DBomb::Query::Insert;
use DBomb::Query::Delete;
use DBomb::Value::Column;
use DBomb::Util;
use DBomb::Tie::PrimaryKeyList;
use base qw(DBomb::DBH::Owner DBomb::Base::Defs);

use Class::MethodMaker
    get_set => [qw(_dbo_values),  ## { column_name => value_obj }
               ];

__PACKAGE__->mk_classdata('_dbo_table_info');
#__PACKAGE__->mk_classdata('_dbo_sth');

## new()
## new($PrimaryKeyValue)
## new($pk_column)
## new($dbh)

## Meant to be overridden by subclasses.

## returns a query object
## $class->select(@column_aliases_or_names)


## $class->selectall_arrayref()
## $class->selectall_arrayref(@bind_values)
## $class->selectall_arrayref($dbh, @bind_values)

## _dbo_column_accessor($column_info)
sub _dbo_column_accessor
{
    my $self = shift;
    my $col = shift;

        assert(UNIVERSAL::isa($col,'DBomb::Meta::ColumnInfo'), 'column accessor requires a column info object');

    if (@_){
        $self->_dbo_column_accessor_set($col,@_);
    }

    $self->_dbo_column_accessor_get($col);
}

sub _dbo_column_accessor_get
{
    my ($self,$col) = @_;
        assert(UNIVERSAL::isa($col,'DBomb::Meta::ColumnInfo'), 'column accessor requires a column info object');

    my $v = $self->_dbo_values->{$col->name};

    ## if a value exists, return it.
    return $v->value if $v->has_value;

    ## auto-fetch
    $self->_dbo_fetch_columns($self->_dbo_expand_select_groups([$col]));

    croak "bug: fetched column '@{[$col->fq_name]}' but value did not get set. This happens when the object has no PK." unless $v->has_value;
    return $v->value;
}

sub _dbo_column_accessor_set
{
    my ($self,$cinfo,$data) = @_;

    assert(UNIVERSAL::isa($cinfo,'DBomb::Meta::ColumnInfo'), 'column accessor requires a column info object');

    $self->_dbo_values->{$cinfo->name}->value($data);

    #TODO: auto-update?
}

## access a column that is part of one or more has_a relationships
sub _dbo_has_a_column_accessor
{
    my $self = shift;
    my $cinfo = shift;
    $self->_dbo_has_a_column_accessor_set($cinfo,@_) if @_;
    $self->_dbo_column_accessor_get($cinfo,@_); ## A regular get.
}

## access a column that is part of one or more has_a relationships
sub _dbo_has_a_column_accessor_set
{
    my ($self,$cinfo,$data) = @_;
    assert(@_ == 3, 'column accessor expects exactly one parameter');

    my $v = $self->_dbo_values->{$cinfo->name};
    return if $v->has_value && DBomb::Util::is_same_value($v->value, $data);

    ## set it
    $v->value($data);

    ## discard any has_a-related objects we have that are based on this column
    for my $has_a (@{$cinfo->table_info->has_as}){
        next unless exists $has_a->one_to_many->many_key->columns->{$cinfo->name};
        $self->{$has_a->attr} = undef;
    }
}

## access a has_a object (_not_ the same things as a FK column.)
sub _dbo_has_a_accessor
{
    my $self = shift;
    my $has_a = shift;
    $self->_dbo_has_a_accessor_set($has_a,@_) if @_;
    $self->_dbo_has_a_accessor_get($has_a);
}

## They want an object based on a has_a relationship
sub _dbo_has_a_accessor_get
{
    my ($self, $has_a) = @_;
    assert(@_ == 2);

    ## See if we already have it
    my $v = $self->{$has_a->attr};
    return $v if defined $v;

    ## Ok, produce an object if we have the all necessary values
    my $key = [];
    my ($one_key, $many_key) = ($has_a->one_to_many->one_key, $has_a->one_to_many->many_key);
    my $dbo_values = $self->_dbo_values;

    for my $cinfo (values %{$many_key->columns}){

        if (not $dbo_values->{$cinfo->name}->has_value){
            # fk_column doesn't have a value, get it.
            my $accessor = $cinfo->accessor;
            $self->$accessor;
        }

        if (not defined $dbo_values->{$cinfo->name}->value){
            ## fk value (NULL).
            return undef;
        }
        push @$key, $dbo_values->{$cinfo->name}->value;
    }

    my $f_class = $one_key->table_info->class;
    my $new_object = $f_class->new(new DBomb::Value::Key($one_key,$key));

    ## Store it for next time.
    $self->{$has_a->attr} = $new_object;

    return $new_object;
}

## Set the has_a value... what should this do?
sub _dbo_has_a_accessor_set
{
    my ($self, $has_a, @args) = @_;
    die "not yet implemented";
}

## Access the list of referring objects in a has_query relationship
sub _dbo_has_query_accessor
{
    my $self = shift;
    my $has_query = shift;
        assert(UNIVERSAL::isa($has_query, 'DBomb::Meta::HasQuery'),'_dbo_has_query_accessor requires a query object');

    $self->_dbo_has_query_accessor_set($has_query,@_) if @_;
    $self->_dbo_has_query_accessor_get($has_query);
}

sub _dbo_has_query_accessor_get
{
    my $self = shift;
    my $has_query = shift;

        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(UNIVERSAL::isa($has_query, 'DBomb::Meta::HasQuery'),'_dbo_has_query_accessor requires a query object');
        assert(@_ == 0);

    ## return our local copy if we have it
    return $self->{$has_query->attr} if defined $self->{$has_query->attr};

    ##
    my @bind_values;
    for (@{$has_query->bind_subs}){
        push @bind_values, $_->($self,$has_query->query);
    }

    my $keys_list = $has_query->query->selectall_arrayref($self->_dbo_dbh, @bind_values);

    ## vivify those objects
    my $obj_class = $has_query->f_table->class;
    my @arr;
    tie @arr, 'DBomb::Tie::PrimaryKeyList', $obj_class, $keys_list;

    $self->{$has_query->attr} = \@arr;
}

## ... what should this do?
sub _dbo_has_query_accessor_set
{
    die "set has_query list not implemented";
}

## Access the list of referring objects in a has_many relationship
sub _dbo_has_many_accessor
{
    my $self = shift;
    my $has_many = shift;
        assert(UNIVERSAL::isa($has_many, 'DBomb::Meta::HasMany'),'_dbo_has_many_accessor requires a has_many object');

    if (@_) {
        ## Since undef is the only allowed value currently, we don't want to immediately trigger a 'get'.
        ## which would fuck up the cached.
        $self->_dbo_has_many_accessor_set($has_many,@_)
    }
    else {
        $self->_dbo_has_many_accessor_get($has_many);
    }
}

## Get the list of objects.
sub _dbo_has_many_accessor_get
{
    my $self = shift;
    my $has_many = shift;
        assert(@_ == 0, 'parameter count');
        assert(UNIVERSAL::isa($has_many, 'DBomb::Meta::HasMany'),'_dbo_has_many_accessor_get requires a has_many object');
        assert(defined($self->_dbo_dbh), 'has_many requires a dbh');

    ## return our local copy if we have it
    return $self->{$has_many->attr} if defined $self->{$has_many->attr};

    ## Must fetch the list.
    my ($one_key, $many_key) = ($has_many->one_to_many->one_key, $has_many->one_to_many->many_key);
    my $where = $many_key->mk_where(@{$self->_dbo_key_values_list});
    my $object_list = $has_many->one_to_many->many_table_info->class->select->where($where)->selectall_arrayref($self->_dbo_dbh);

    $self->{$has_many->attr} = $object_list;
}

## The only valid value is actually
sub _dbo_has_many_accessor_set
{
    my $self = shift;
    my $has_many = shift;
    my $value = shift;

    assert(UNIVERSAL::isa($has_many, 'DBomb::Meta::HasMany'),'_dbo_has_many_accessor_set requires a has_many object');
    assert((not defined $value) && @_ == 0, 'you can only set a has_many field to undef');

    ## Delete the cached values.
    $self->{$has_many->attr} = undef;
    $self;
}

## Unwraps PrimaryKey objects into the column value slots
## _dbo_set_primary_key($PrimaryKeyValueObj)
## _dbo_set_primary_key($ColumnValueObj)
## _dbo_set_primary_key([$data,...])
## _dbo_set_primary_key($single_key_value)
sub _dbo_set_primary_key
{
    my $self = shift;
    my $pk_val = shift;
    my $pk_info = $self->_dbo_table_info->primary_key;
    my $pk_columns_list = $pk_info->columns_list;

    if (UNIVERSAL::isa($pk_val, 'DBomb::Value::Key')){

        my $i = 0;
        for my $cinfo (@$pk_columns_list){
            ## copy the values from the pk object to the corresponding columns
            $self->_dbo_values->{$cinfo->name}->value($pk_val->value_list->[$i++]);
        }
    }
    elsif (UNIVERSAL::isa($pk_val, 'DBomb::Value::Column')){ die "Not yet implemented" }

    elsif (UNIVERSAL::isa($pk_val, 'ARRAY')){

        assert(@$pk_val == @$pk_columns_list, "primary key column count must match key list count");
        my $i = 0;
        for my $cinfo (@$pk_columns_list){
            ## copy the values from the pk array to the corresponding columns
            $self->_dbo_values->{$cinfo->name}->value($pk_val->[$i++]);
        }
    }
    elsif (not ref $pk_val){

        ## it's scalar
        assert(1 == @$pk_columns_list, "new(scalar) only allowed if primary key consists of a single column");
        my $col_name = $pk_columns_list->[0]->name;
        $self->_dbo_values->{ $col_name }->value($pk_val);
    }
    else{
        croak "unsupported primary key type";
    }
}

## returns true if this object has a primary key value, regardless of whether that key really
## exists in the database or if this object has been inserted.
sub _dbo_is_bound
{
    my $self = shift;

    my $pk_info = $self->_dbo_table_info->primary_key;
    my $pk_columns_list = $pk_info->columns_list;

    ## check if every pk column has a value
    for my $pk_col (@$pk_columns_list){
        return undef unless $self->_dbo_values->{$pk_col->name}->has_value;
    }

    1;
}

sub _dbo_fetch_columns
{
    my ($self,$columns) = @_;
        assert(UNIVERSAL::isa($columns,'ARRAY'), 'requires arrayref');
        for(@$columns){
            assert(UNIVERSAL::isa($_,'DBomb::Meta::ColumnInfo'), 'requires a columninfo object');
        }

    my $query = new DBomb::GluedQuery($self->_dbo_dbh, $self, $columns);
    $query->from($self->_dbo_table_info)
          ->where($self->_dbo_mk_where);
    $query->prepare;
    $query->execute;
    my @r = $query->fetch;
    $query->finish;

    wantarray ? @r : $r[0];
}

sub _dbo_mk_where
{
    my $self = shift;
    $self->_dbo_table_info->primary_key->mk_where(@{$self->_dbo_key_values_list})
}

sub _dbo_key_values_list
{
    my $self = shift;
        assert(@_ == 0);
    my $values = $self->_dbo_values;
    [map {$values->{$_}->value} keys %{$self->_dbo_table_info->primary_key->columns}]
}

## Find a dbh at all costs
## _dbo_dbh()
## _dbo_dbh(0) ## disable die() if not found
sub _dbo_dbh
{
    my $self = shift;
    my $dbh;
    my $should_croak = @_? shift : 1; ## default is to croak

        assert(@_ == 0, 'parameter count');

    ## Try through the object

    if (defined($dbh = $self->dbh)){
        return $dbh;
    }

    ## Try through the class
    if (ref($self) && defined($dbh = ref($self)->dbh)){
        return $dbh;
    }

    ## Try through the DBomb global class
    if (defined($dbh = DBomb->dbh)){
        return $dbh;
    }

    croak "Couldn't find a \$dbh to use!" if $should_croak;
    undef
}

## TODO: this should take a group as an argument. currently, it finds the :all and expands everything!!
## _dbo_expand_select_groups($columns_list)
sub _dbo_expand_select_groups
{
    my ($class,$columns_list) = @_;
    my $tinfo = $class->_dbo_table_info;

        assert(UNIVERSAL::isa($class,__PACKAGE__));
        assert(UNIVERSAL::isa($columns_list,'ARRAY'));

    my %new_cols = map { $_->name  => $_ } @$columns_list;

    for my $group_name (keys %{$tinfo->select_groups}){
        next if $group_name eq ':all';

        my $group = $tinfo->select_groups->{$group_name};
        for my $cinfo (@$columns_list){
            next unless exists $group->{$cinfo->name};

            for my $new_cinfo (values %$group){
                $new_cols{$new_cinfo->name} = $new_cinfo;
            }
        }
    }
    return [values %new_cols];
}

## delete()
sub _dbo_delete_static
{
    my $class = shift;
        assert((not ref $class), 'static delete takes a package, not an object reference');
    return new DBomb::Query::Delete($class->_dbo_dbh)
                ->from($class->_dbo_table_info->name);
}

## delete()
sub _dbo_delete
{
    my $self = shift;
        assert(ref($self) && UNIVERSAL::isa($self,__PACKAGE__));
        assert(@_==0, 'delete takes a DBH as an argument');

    ## use the static method to create the deleter object
    my $delete = ref($self)->_dbo_delete_static(@_);

    $delete->where($self->_dbo_mk_where);
    $delete->prepare;
    return $delete->execute;
}

## $class->insert()
## $class->insert($dbh)
## $class->insert( { col_name => value } )
sub _dbo_insert_static
{
    my $class = shift;
    my ($hash, $dbh);
    my $columns = [];
    my @args;

    while (my $a = shift){
        if    (UNIVERSAL::isa($a,'DBI::db')) { $class->dbh($a) }
        elsif (UNIVERSAL::isa($a,'HASH'))    { $hash = $a }
        elsif (UNIVERSAL::isa($a,'ARRAY'))   { push @$columns, @$a }
        elsif (not ref $a)                   { push @$columns, $a }
        else  { croak "unrecognized argument to insert()" }
    }

    ## Allow dbh to be specified later.
    $dbh = $class->_dbo_dbh(0);
    unshift @args, $dbh if $dbh;

    if ($hash){

        my ($values) = ([]);

        ## build list of columns and values
        for my $cinfo (@{$class->_dbo_table_info->columns_list}){

            next if $cinfo->is_generated;
            next if $cinfo->is_expr;

            if    (exists $hash->{$cinfo->fq_name})  { push @$values, $hash->{$cinfo->fq_name}; }
            elsif (exists $hash->{$cinfo->name})     { push @$values, $hash->{$cinfo->name}; }
            elsif (exists $hash->{$cinfo->accessor}) { push @$values, $hash->{$cinfo->accessor}; }
            else  { next }

            push @$columns, $cinfo;
        }

        croak "no valid columns were found in the hash!" unless @$columns;
        push @args, $columns;
        return new DBomb::Query::Insert(@args)->into($class->_dbo_table_info->name)
                ->values($values);
    }

    ## Otherwise, return a query object

    ## default columns list??
#    my $cols = [ map { $_->name }
#                 grep { (not $_->is_generated)
#                   &&   (not $_->is_expr)
#                  }
#                  values %{$class->_dbo_table_info->columns}];
#
#    push @args, $cols if @$cols;

    push @args, $columns;
    return new DBomb::Query::Insert(@args)->into($class->_dbo_table_info->name);
}

## insert()
## insert($dbh)
sub _dbo_insert
{
    my $self = shift;

    $self->dbh(shift) if UNIVERSAL::isa($_[0],'DBI::db');
        assert(defined($self->_dbo_dbh), 'insert requires a dbh');
        assert(@_==0, 'parameter validation');

    ## TODO: allow cols to be passed in.
    my $cols = [grep { $_->has_value
                  && (not $_->column_info->is_generated)
                  && (not $_->column_info->is_expr)
                  } @{$self->_dbo_values_list}];

    my $insert = new DBomb::Query::Insert($self->_dbo_dbh,$cols);

    $insert->prepare;
    my $rv = $insert->execute;

    ## check for any generated primary key columns
    for (values %{$self->_dbo_table_info->primary_key->columns}){
        next unless $_->is_generated;
        my $pk_val = $insert->last_insert_id;
        $self->_dbo_values->{$_->name}->value($pk_val); ## set it

        ##$self->is_bound(1);
    }

    return $rv;
}

## update()
## update($dbh, +{ column_name => value })
## values can be Expr() objects, Value objects, or whatever
sub _dbo_update_static
{
    my $class = shift;
    my ($hash, $dbh);

    while (local $_ = shift){
        if    (UNIVERSAL::isa($_,'DBI::db')) { $class->dbh($_) }
        elsif (UNIVERSAL::isa($_,'HASH'))    { $hash = $_ }
        else  { croak "unrecognized argument to insert()" }
    }

    ## Allow dbh to specified later.
    $dbh = $class->_dbo_dbh(0);
    my @args;
    unshift @args, $dbh if $dbh;

    my $update = new DBomb::Query::Update(@args)->table($class->_dbo_table_info->name);

    if ($hash){

        my $set_count = 0;

        ## build list of columns and values
        for my $cinfo (@{$class->_dbo_table_info->columns_list}){

            next if $cinfo->is_generated;
            next if $cinfo->is_expr;

            my $v;
            if    (exists $hash->{$cinfo->fq_name})  { $v = $hash->{$cinfo->fq_name}; }
            elsif (exists $hash->{$cinfo->name})     { $v = $hash->{$cinfo->name}; }
            elsif (exists $hash->{$cinfo->accessor}) { $v = $hash->{$cinfo->accessor}; }
            else  { next }

            $update->set($cinfo->fq_name, $v);
            $set_count++;
        }
        croak "no valid columns were found in the hash!" unless $set_count > 0;
    }

    return $update;
}

## update()
## update($dbh)
sub _dbo_update
{
    my $self = shift;

    $self->dbh(shift) if UNIVERSAL::isa($_[0],'DBI::db');
        assert(defined($self->_dbo_dbh), 'update requires a dbh');

    my $cols = [grep {$_->has_value
                  &&  $_->is_modified
                  &&  (not $_->column_info->is_in_primary_key)
                  &&  (not $_->column_info->is_expr)
                } @{$self->_dbo_values_list}];

    my $update = new DBomb::GluedUpdate($self,$self->_dbo_dbh,$cols);

    ## glue to the primary key
    $update->where($self->_dbo_mk_where);
    $update->prepare;
    return $update->execute;
}

## copy_shallow()
## copy_shallow($dbh)
## shallow copy and return new UID
sub _dbo_copy_shallow
{
    my $self = shift;
    my $class = ref($self) || $self;

    $self->dbh(shift) if UNIVERSAL::isa($_[0],'DBI::db');
        assert(defined($self->_dbo_dbh), 'update requires a dbh');
    my $tinfo = $self->_dbo_table_info;

    ## Do a an INSERT SELECT statement and return the last insert id

        ## build list of columns and values
    my $col_names = $self->_dbo_insertable_column_names_no_pk;

    my $inserter = $class->_dbo_insert_static;
    $inserter->columns(@$col_names);
    $inserter = $inserter->select(@$col_names);
    $inserter->sql_small_result;
    $inserter->from($tinfo->name)
             ->where($self->_dbo_mk_where);

    $inserter->prepare($self->_dbo_dbh);
    $inserter->execute;

    return $inserter->last_insert_id;
}

## Returns a list of column names.
sub _dbo_insertable_column_names_no_pk
{
    my $self = shift;
    my $class = ref($self) || $self;
    my $col_names = [];
    for my $cinfo (@{$class->_dbo_table_info->columns_list}){

        next if $cinfo->is_generated;
        next if $cinfo->is_expr;
        next if $cinfo->is_in_primary_key;

        push @$col_names, $cinfo->fq_name;
    }
    return $col_names;
}

sub _dbo_values_list { [values %{$_[0]->_dbo_values}] }

1;
__END__

