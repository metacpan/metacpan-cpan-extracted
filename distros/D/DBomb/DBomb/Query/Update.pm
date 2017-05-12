package DBomb::Query::Update;

=head1 NAME

DBomb::Query::Update - An SQL UPDATE wrapper

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.4 $';

use Carp qw(croak);
use Carp::Assert;
use DBomb;
use DBomb::Conf;

use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [ qw(_column_names),     # [ column_name, ... ]
                   qw(_values),     # [ value, ... ]
                   qw(_table_name),
                   qw(dbh),
                   qw(sth),
                   qw(where_obj),   # expr
                  ],
    ;

## init()
## init($dbh,[$_column_names])
sub init
{
    my $self = shift;
    $self->_column_names([]);
    $self->_values([]);
    $self->where_obj(new DBomb::Query::Expr());

    for(@_){
        if    ( UNIVERSAL::isa($_,'DBI::db')) { $self->dbh($_); }
        elsif ( UNIVERSAL::isa($_,'ARRAY'))   { $self->_column_names($_); }
        else{
            croak "unrecognized argument to Update->new";
        }
    }
}

## set the table
## table($_table_name)
sub table
{
    my $self = shift;
        assert(UNIVERSAL::isa($self,__PACKAGE__));

    while(my $a = shift){
        if    ( UNIVERSAL::isa($a,'DBI::db')) { $self->dbh($a); }
        else { $self->_table_name($a) }
    }

    return $self;
}

## set({ name => value})
## set( name => value)
sub set
{
    my $self = shift;

    if (@_ == 1){
        my $hash = shift;
            assert(UNIVERSAL::isa($hash,'HASH'), "Update::set requires a hashref (or name value)");
        while (my ($column_name, $value) = each %$hash){
            $self->set($column_name, $value);
        }
    }
    else{
        assert(@_ == 2, "Update::set requires a name and a value (or hashref)");
        my ($column_name, $value) = @_;

        ## for expression objects, extract the bind_value
        if (UNIVERSAL::isa($value,'DBomb::Query::Expr')){

        }


        push @{$self->_column_names}, $column_name;
        push @{$self->_values}, $value;
    }

    return $self;
}

## Same as prepare->execute
## update()
## update(@bind_values)
## update($dbh,@bind_values)
sub update
{
    my $self = shift;
    my @bv;

    for (@_){
        if (UNIVERSAL::isa($_,'DBI::db')){ $self->dbh($_) }
        else { push @bv, $_ }
    }
    assert(defined($self->dbh), 'update requires a dbh');

    if (not $self->sth){ $self->prepare }
    return $self->execute(@bv);
}

## execute()
## execute(@bind_values)
## execute($dbh,@bind_values)
sub execute
{
    my $self = shift;
    my @bv;

    for (@_){
        if (UNIVERSAL::isa($_,'DBI::db')){ $self->dbh($_) }
        else { push @bv, $_ }
    }
    assert(defined($self->dbh), 'update requires a dbh');

    if (not $self->sth){ $self->prepare }
    return $self->sth->execute((@{$self->bind_values},@bv));
}


## prepare()
## prepare($dbh)
sub prepare
{
    my $self = shift;

    for (@_){
        $self->dbh($_) if UNIVERSAL::isa($_, 'DBI::db');
    }
        assert(defined($self->dbh), 'prepare requires a dbh');
        assert($self->_table_name, 'update requires a table_name');
        assert(@{$self->_column_names} > 0, 'update requires at least one column');


    if ($DBomb::Conf::prepare_cached){
        $self->sth($self->dbh->prepare_cached(scalar $self->sql));
    }
    else{
        $self->sth($self->dbh->prepare(scalar $self->sql));
    }
    return $self;
}

## where(EXPR, @bind_values)
sub where
{
    my $self = shift;
    $self->where_obj->append( new DBomb::Query::Expr(@_));
    return $self;
}

sub sql
{
    my $self = shift;
    $self->dbh(shift) if @_;
        assert($self->dbh, 'Update::sql requires a dbh');

    my $sql = "UPDATE ";

    $sql .= $self->_table_name if $self->_table_name;

    ## grab the sql from any expression objects in the _values list
    $sql .= " SET ";
    my ($names,$values) = ($self->_column_names,$self->_values);
    $sql .= join ", ", map {
                    UNIVERSAL::isa($values->[$_],'DBomb::Query::Expr')
                        ? ("$names->[$_] = " . $values->[$_]->sql($self->dbh))
                        : ("$names->[$_] = ?")
                } (0..$#$names);

    if ($self->where_obj->is_not_empty){
        $sql .= " WHERE ";
        $sql .= $self->where_obj->sql($self->dbh);
    }
    return $sql;
}

sub bind_values
{
    my $self = shift;
    my $bv = [];
        assert(@_ == 0, 'bind_values takes no parameters');

    ## allow Expr and Value objects as well as scalars
    for (@{$self->_values}, @{$self->where_obj->bind_values}){
        if    (UNIVERSAL::isa($_,'DBomb::Value'))       { push @$bv, $_->value }
        elsif (UNIVERSAL::isa($_,'DBomb::Query::Expr')) { push @$bv, @{$_->bind_values} }
        else  { push @$bv, $_ }
    }
    return $bv;
}


1;
__END__

