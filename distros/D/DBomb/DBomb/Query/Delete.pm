package DBomb::Query::Delete;

=head1 NAME

DBomb::Query::Delete - An SQL DELETE wrapper

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.5 $';

use Carp qw(croak);
use DBomb;
use DBomb::Conf;
use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [ qw(dbh),
                   qw(sth),
                   qw(table_name),
                   qw(where_obj),   # expr
                  ],
    ;

## init()
## init($dbh)
sub init
{
    my $self = shift;
    $self->where_obj(new DBomb::Query::Expr());

    ## First argument might be a dbh or peer object
    for(@_){
        if (UNIVERSAL::isa($_,'DBI::db')){
            $self->dbh($_);
        }
        else{
            croak "unrecognized argument to DBomb::Query::Delete->new";
        }
    }
}

## from($tables)
sub from
{
    my $self = shift;
    my $table_name = shift;
        assert(@_ == 0, 'parameter count to from()');
        assert(defined($table_name), 'table name must be defined');

    $self->table_name(new DBomb::Query::Text( $table_name ));
    return $self;
}

## Same as prepare->execute
## delete()
## delete(@bind_values)
## delete($dbh,@bind_values)
sub delete
{
    my $self = shift;
    my @bv;

    for (@_){
        if (UNIVERSAL::isa($_,'DBI::db')){ $self->dbh($_) }
        else { push @bv, $_ }
    }
    assert(defined($self->dbh), 'delete requires a dbh');
    assert(defined($self->table_name), 'delete requires a table');

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
    assert(defined($self->dbh), 'delete requires a dbh');

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
    }else{
        $self->sth($self->dbh->prepare(scalar $self->sql));
    }
    return $self;
}

## where(EXPR, @bind_values)
sub where
{
    my $self = shift;
    $self->where_obj->append( @_ );
    return $self;
}

## and (EXPR, @bind_values)
sub and
{
    my $self = shift;
    $self->where_obj->and(@_);
    $self
}

## or (EXPR, @bind_values)
sub or
{
    my $self = shift;
    $self->where_obj->or(@_);
    $self
}

sub sql
{
    my $self = shift;
    $self->dbh(shift) if @_;

    assert($self->dbh, 'sql requires a dbh');

    my $sql = "DELETE";

    assert(defined($self->table_name), "DELETE without table name.");
    $sql .= " FROM " . $self->table_name->sql;

    if ( $self->where_obj->is_not_empty ){
        $sql .= " WHERE ";
        $sql .= $self->where_obj->sql($self->dbh);
    }
    return $sql;
}

sub bind_values
{
    my $self = shift;
    my $bv = [];
        assert(@_==0, 'bind_values takes no arguments');

    push @$bv, @{$self->where_obj->bind_values};
    return $bv;
}



1;
__END__

