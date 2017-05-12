package DBomb::Query;

=head1 NAME

DBomb::Query - A query abstraction.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
use Carp::Assert;
use DBomb::Conf;
use DBomb::Query::Text;
use DBomb::Query::Expr;
use DBomb::Query::Join;
use DBomb::Query::LeftJoin;
use DBomb::Query::RightJoin;
use DBomb::Query::Limit;
use DBomb::Query::OrderBy;
use DBomb::Query::GroupBy;
use DBomb::Util qw(ctx_0);

## The CVS Revision. See DBomb.pm for the DBomb release version.
our $VERSION = '$Revision: 1.22 $';

use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(column_names where_obj having_obj orderbys groupbys
                     limit_obj table_sources dbh sth)],
    'boolean' => [qw(_sql_small_result)]
    ;

## Lexically scoped unique placeholder value. Used by Expr.
my $place_holder = '?';
sub PlaceHolder { \$place_holder };

## new Query()
## new Query(column_names)
## new Query($dbh,column_names)
sub init
{
    my $self = shift;
    $self->table_sources([]);
    $self->column_names([]);
    $self->orderbys([]);
    $self->groupbys([]);
    $self->where_obj(new DBomb::Query::Expr());
    $self->having_obj(new DBomb::Query::Expr());

    ## Check for a dbh
    $self->dbh(shift) if UNIVERSAL::isa($_[0],'DBI::db');

    $self->select(@_) if @_;
    return $self;
}

sub select
{
    my $self = shift;
    push @{$self->column_names}, (ref($_[0]) ? @{$_[0]}: @_);
    return $self;
}

## mysql-specific extension
sub sql_small_result
{
    my $self = shift;
    $self->_sql_small_result(1);
    return $self;
}

## from($tables..)
sub from
{
    my $self = shift;
    assert(@_ && defined($_[0]), 'valid parameters');
    push @{$self->table_sources}, map { new DBomb::Query::Text($_)} map { ref($_)? @$_ : $_ } @_;
    return $self;
}

## join($right)
## join($left, $right)
sub join
{
    my $self = shift;
    $self->_mk_join('DBomb::Query::Join',@_);
    return $self;
}

## right_join($right)
## right_join($left, $right)
sub right_join
{
    my $self = shift;
    $self->_mk_join('DBomb::Query::RightJoin',@_);
    return $self;
}

## left_join($right)
## left_join($left, $right)
sub left_join
{
    my $self = shift;
    $self->_mk_join('DBomb::Query::LeftJoin',@_);
    return $self;
}

## _mk_join($joinclass,$right)
## _mk_join($joinclass,$left, $right)
sub _mk_join
{
    my $self = shift;
    my $joinclass = shift;
    my($left,$right) = @_;
    my $table_sources = $self->table_sources;
    if(@_ == 1){
        assert(@$table_sources > 0
             && ( UNIVERSAL::isa(ref($table_sources->[$#$table_sources]),'DBomb::Query::Text')
                ||UNIVERSAL::isa(ref($table_sources->[$#$table_sources]),'DBomb::Query::Join')
                ), 'single argument join requires left table (or join)');
        $right = $left;
        $left = pop @$table_sources;
    }
    push @$table_sources,  $joinclass->new($left,$right);
    return $self;
}

sub on
{
    my $self = shift;
    my $table_sources = $self->table_sources;
    assert(@$table_sources, 'ON requires a JOIN');
    assert(UNIVERSAL::isa($table_sources->[$#$table_sources],'DBomb::Query::Join'), 'ON requires a JOIN');

    $table_sources->[$#$table_sources]->on(new DBomb::Query::Expr(@_));
    return $self;
}

sub using
{
    my $self = shift;
    my $table_sources = $self->table_sources;
    assert(scalar(@_), 'USING requires a list of column names');
    assert(UNIVERSAL::isa($table_sources->[$#$table_sources],'DBomb::Query::Join'), 'USING requires a JOIN');
    $table_sources->[$#$table_sources]->using(@_);
    return $self;
}

## where(EXPR, @bind_values)
sub where
{
    my $self = shift;
    $self->where_obj->append(new DBomb::Query::Expr(@_));
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

sub group_by
{
    my $self = shift;
    my $o = new DBomb::Query::GroupBy(@_);
    push @{$self->groupbys}, $o;
    return $self;
}

sub having
{
    my $self = shift;
    my $o = new DBomb::Query::Expr(@_);
    $self->having_obj->append($o);
    return $self;
}

sub order_by
{
    my $self = shift;
    my $o = new DBomb::Query::OrderBy(@_);
    push @{$self->orderbys}, $o;
    return $self;
}

sub asc
{
    my $self = shift;
    assert(@_ == 0, "asc takes no arguments");
    my $orderbys = $self->orderbys;
    assert(@$orderbys > 0, "asc requires previous call to order_by");
    $orderbys->[$#$orderbys]->asc;
    return $self;
}

sub desc
{
    my $self = shift;
    assert(@_ == 0, "desc takes no arguments");
    my $orderbys = $self->orderbys;
    assert(@$orderbys > 0, "asc requires previous call to order_by");
    $orderbys->[$#$orderbys]->desc;
    return $self;
}

sub limit
{
    my $self = shift;
    my $o = new DBomb::Query::Limit(@_);
    $self->limit_obj($o);
    return $self;
}

sub sql
{
    my ($self, $dbh) = @_;
    $self->dbh($dbh) if defined $dbh;
    $dbh = $self->dbh();
    assert(defined($dbh), 'DBomb::Query::sql method requires a dbh');

    my $sql = "SELECT ";

    if ($self->_sql_small_result){
        $sql .= "SQL_SMALL_RESULT ";
    }

    $sql .= CORE::join ',', @{$self->column_names};

    $sql .= " FROM " . CORE::join ', ', map { $_->sql($dbh) } @{$self->table_sources} if @{$self->table_sources};

    my $where_sql  = $self->where_obj->sql($dbh);
    $sql .= " WHERE $where_sql " if length $where_sql;

    my $groupby_sql = CORE::join ', ', map { $_->sql($dbh) } @{$self->groupbys};
    $sql .= " GROUP BY " . $groupby_sql if length $groupby_sql;

    my $having_sql  = $self->having_obj->sql($dbh);
    $sql .= " HAVING $having_sql " if length $having_sql;

    my $orderby_sql = CORE::join ', ', map { $_->sql($dbh) } @{$self->orderbys};
    $sql .= " ORDER BY " . $orderby_sql if length $orderby_sql;

    $sql .= $self->limit_obj->sql($dbh) if defined $self->limit_obj;

    return ctx_0($sql,@{$self->bind_values});
}

sub bind_values
{
    my $self = shift;
    my $bv = [];

    push @$bv, map{ @{$_->bind_values} } @{$self->table_sources};
    push @$bv, @{$self->where_obj->bind_values};
    push @$bv, @{$self->having_obj->bind_values};
    return $bv;
}

## prepare()
## prepare($dbh)
sub prepare
{
    my ($self,$dbh) = @_;

    $self->dbh($dbh) if defined $dbh;
    assert(defined($self->dbh), 'prepare requires a dbh');

    if ($DBomb::Conf::prepare_cached){
        $self->sth($self->dbh->prepare_cached(scalar $self->sql));
    }
    else{
        $self->sth($self->dbh->prepare(scalar $self->sql));
    }
    return $self;
}

## execute(@bind_values)
## execute($dbh,@bind_values)
sub execute
{
    my ($self, @bind_values) = @_;

    $self->dbh(shift @bind_values) if UNIVERSAL::isa($bind_values[0],'DBI::db');
    assert(defined($self->dbh), 'execute requires a dbh');

    $self->prepare unless $self->sth;
    assert($self->sth, 'execute requires a valid sth. Did you forget to call prepare()?');

    $self->sth->execute((@{$self->bind_values},@bind_values));
    return $self;
}

## fetchrow_arrayref()
sub fetchrow_arrayref
{
    my $self = shift;
    assert(defined($self->sth), 'fetchrow_arrayref requires an sth');

    return $self->sth->fetchrow_arrayref;
}

## fetchall_arrayref()
sub fetchall_arrayref
{
    my $self = shift;
    my $a = [];
    while(my $row = $self->fetchrow_arrayref){

        ## DBI reuses array refs, so  create new ones each time
        push @$a, [@$row];
    }
    return $a;
}

## fetchcol_arrayref()
sub fetchcol_arrayref
{
    my $self = shift;
    my $a = [];
    while(my $row = $self->fetchrow_arrayref){

        push @$a, $row->[0];
    }
    return $a;
}

## selectall_arrayref(@bind_values)
## selectall_arrayref($dbh, @bind_values)
sub selectall_arrayref
{
    my ($self, @bind_values) = @_;

    $self->dbh(shift @bind_values) if UNIVERSAL::isa($bind_values[0],'DBI::db');
    assert(defined($self->dbh), 'execute requires a dbh');

    $self->prepare($self->dbh) unless $self->sth;
    $self->execute(@bind_values);
    return $self->fetchall_arrayref;
}

## selectcol_arrayref(@bind_values)
## selectcol_arrayref($dbh, @bind_values)
sub selectcol_arrayref
{
    my ($self, @bind_values) = @_;

    $self->dbh(shift @bind_values) if UNIVERSAL::isa($bind_values[0],'DBI::db');
    assert(defined($self->dbh), 'execute requires a dbh');

    $self->prepare($self->dbh) unless $self->sth;
    $self->execute(@bind_values);
    return $self->fetchcol_arrayref;
}

## finish()
sub finish
{
    my $self = shift;
        assert(defined($self->sth), 'finish() requires an sth');
    $self->sth->finish;
}

## returns a deep copy.
## @note The database handle will be shared by the clone, and
## the internal statement handle will set to undef in the clone.
## clone ()
sub clone
{
    my $self = shift;

        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(@_ == 0);

    my $clone = __PACKAGE__->new();

    ## copy simple lists
    push @{$clone->column_names}, @{$self->column_names} if @{$self->column_names};
    push @{$clone->table_sources}, @{$self->table_sources}  if  @{$self->table_sources};

    ## clone object lists
    push @{$clone->orderbys}, map{$_->clone} @{$self->orderbys} if @{$self->orderbys};
    push @{$clone->groupbys}, map{$_->clone} @{$self->groupbys} if @{$self->groupbys};

    ## clone objects
    $clone->where_obj    ($self->where_obj->clone)  if  $self->where_obj;
    $clone->having_obj   ($self->having_obj)        if  $self->having_obj;
    $clone->limit_obj    ($self->limit_obj->clone)  if  $self->limit_obj;

    ## share the dbh, and undef the sth
    $clone->dbh($self->dbh);
    $clone->sth(undef);

    return $clone;
}

1;
__END__

