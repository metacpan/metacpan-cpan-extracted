package DBomb::Base;

=head1 NAME

DBomb::Base - Provides inheritable methods mapped to database operations.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.27 $';

use DBomb::Query;
use DBomb::GluedQuery;
use DBomb::GluedUpdate;
use DBomb::Value::Column;
use DBomb::Meta::Key;
use DBomb::Tie::PrimaryKeyList;
use Carp::Assert;
use Carp qw(croak);
use base qw(DBomb::Base::Private);

## new()
## new($PrimaryKeyValue)
## new($pk_column)
## new($dbh)
sub new
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $self = bless +{}, $class;

    $self->_dbo_values(+{});

    ## Create values objects
    for (values %{$self->_dbo_table_info->columns}){
        $self->_dbo_values->{$_->name} = new DBomb::Value::Column($_);
        #TODO: default value
    }

    my ($got_dbh, $got_key) = (0,0);

    for (@_) {
        last if $got_key && $got_dbh;

        if (UNIVERSAL::isa($_,'DBI::db') && not $got_dbh){
            $self->dbh($_);
            $got_dbh = 1;
        }
        elsif (UNIVERSAL::isa($_,'DBomb::Value::Key') && not $got_key){
            $self->_dbo_set_primary_key($_);
            $got_key = 1;
        }
        elsif (defined($_) && !ref($_) && !$got_key){
            $self->_dbo_set_primary_key($_);
            $got_key = 1;
        }
        elsif (UNIVERSAL::isa($_,'ARRAY') && not $got_key){
            $self->_dbo_set_primary_key($_);
            $got_key = 1;
        }
        elsif (ref($_) eq 'HASH'){
            #TODO: accept +{key=>value} as passed to new DBomb::Value::PrimaryKey
            die("not implemented yet");
        }
    }

    $self->init;
    return $self;
}

## Meant to be overridden by subclasses.
sub init
{
}

## returns a query object
## $class->select(@column_aliases_or_names)
sub select
{
    my $class = shift;
    my @columns = @_;

    push @columns, values %{$class->_dbo_table_info->primary_key->columns} unless @_;

    ## promote string names to column_info objects
COLUMN: for(@columns){
        next if UNIVERSAL::isa($_,'DBomb::Meta::ColumnInfo');

        if (exists $class->_dbo_table_info->columns->{$_}){
            $_ =   $class->_dbo_table_info->columns->{$_};
            next COLUMN;
        }

        for my $c ( values %{$class->_dbo_table_info->columns}){
            if ($_ eq $c->accessor){
                $_ = $c;
                next COLUMN;
            }
        }

        croak "Column '$_' not found in object $class.";
    }

    return new DBomb::GluedQuery($class->_dbo_dbh,$class->_dbo_expand_select_groups([@columns]))->from($class->_dbo_table_info);
}

# $class->select_count()
sub select_count
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    return new DBomb::Query($class->_dbo_dbh,["COUNT(*)"])->from($class->_dbo_table_info->name);
}


## $class->selectall_arrayref()
## $class->selectall_arrayref(@bind_values)
## $class->selectall_arrayref($dbh, @bind_values)
sub selectall_arrayref
{
    my ($class, @bind_values) = @_;
    my $dbh;

    $dbh = shift(@bind_values) if UNIVERSAL::isa($bind_values[0],'DBI::db');

    # Let $dbh override default dbh
    $dbh = $class->_dbo_dbh unless defined $dbh;

    $class = ref($class) if ref($class);

    ## We don't need a glued query here since we are just selecting the primary key columns.
    ## The tied list will create the objects as needed.
    my $query = new DBomb::Query($dbh,$class->_dbo_table_info->primary_key->column_names)
                        ->from($class->_dbo_table_info->name);
    my $keys_list = $query->selectall_arrayref;
    my @arr;
    tie @arr, 'DBomb::Tie::PrimaryKeyList', $class, $keys_list;
    return \@arr;
}

## delete()
## $class->delete()
sub delete
{
    my $self = shift;
        assert(@_==0, 'delete takes no arguments');

    if (ref $self){
        $self->_dbo_delete(@_);
    }
    else{
        $self->_dbo_delete_static(@_);
    }
}


sub insert
{
    my $self = shift;
    if (ref $self){
        $self->_dbo_insert(@_);
    }
    else{
        $self->_dbo_insert_static(@_);
    }
}

sub update
{
    my $self = shift;
    if (ref $self){
        $self->_dbo_update(@_);
    }
    else{
        $self->_dbo_update_static(@_);
    }
}

sub copy_shallow
{
    my $self = shift;
        assert(ref($self) && UNIVERSAL::isa($self,__PACKAGE__), "copy_shallow requires an object instance");

    my $id = $self->_dbo_copy_shallow(@_);
    if (defined $id){
        return ref($self)->new($id);
    }
    undef
}

sub dbo_is_bound
{
    my $self = shift;
    $self->_dbo_is_bound;
}

1;
__END__

