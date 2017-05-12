package DBomb::GluedUpdate;

=head1 NAME

DBomb::GluedUpdate - An update glued to a DBomb::Base object.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.11 $';

use DBomb;
use DBomb::Conf;
use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [ qw(columns_list),     # [ column_value_object, ... ]
                   qw(peer),        # a DBomb::Base object
                   qw(dbh),
                   qw(sth),
                   qw(where_obj),   # expr
                  ],
    ;

## init($peer)
## init($peer,$dbh,[$columns_list])
sub init
{
    my $self = shift;
    $self->columns_list([]);
    $self->where_obj(new DBomb::Query::Expr());

    ## First argument might be a dbh or peer object
    for(@_){

        if (UNIVERSAL::isa($_,'DBI::db')){
            $self->dbh($_);
        }
        elsif (UNIVERSAL::isa($_,'DBomb::Base')){
            $self->peer($_);
        }
        elsif (UNIVERSAL::isa($_,'ARRAY')){
            for (@$_){
                assert(UNIVERSAL::isa(ref($_),'DBomb::Value::Column'), 'GluedUpdate requires column value objs');
            }
            $self->columns_list($_);
        }
    }
    assert(defined($self->peer), 'GluedUpdate requires a peer');

    if (@{$self->columns_list} == 0){
        ## Default is all updatable columns.
        $self->columns_list([
                grep { $_->has_value
                  && $_->is_modified
                  && (not $_->column_info->is_in_primary_key)
                  } values %{$self->peer->_dbo_values}]);
    }
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

    if ($DBomb::Conf::prepare_cached){
        $self->sth($self->dbh->prepare_cached(scalar $self->sql));
    }
    else{
        $self->sth($self->dbh->prepare(scalar $self->sql));
    }
    return $self;
}

## where(EXPR)
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

    assert($self->dbh, 'sql requires a dbh');

    my $sql = "UPDATE ";
    assert(@{$self->columns_list} > 0, 'update attempted but no columns have been modified');

    my $col = $self->columns_list->[0];
    $sql .= $col->column_info->table_info->name;

    $sql .= " SET ";
    $sql .= join ", ", map { "$_ = ?" } map { $_->column_info->name } @{$self->columns_list};
    $sql .= " WHERE ";
    $sql .= $self->where_obj->sql($self->dbh);
    return $sql;
}

sub bind_values
{
    my $self = shift;
    my $bv = [];

    for my $col_val (@{$self->columns_list}){
        next unless $col_val->has_value;
        push @$bv, $col_val->get_value_for_update;
    }

    push @$bv, @{$self->where_obj->bind_values};
    return $bv;
}


1;
__END__

