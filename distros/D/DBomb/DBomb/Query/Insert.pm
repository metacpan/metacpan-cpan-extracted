package DBomb::Query::Insert;

=head1 NAME

DBomb::Query::Insert - An SQL INSERT wrapper.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.14 $';

use Carp::Assert;
use DBomb::Util qw(ctx_0);
use DBomb::Query;
use DBomb::Conf;

use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(_column_names), ## [names]
                  qw(_table),   ## [name]
                  qw(_values),  ## [values or Values]
                  qw(_sql_values), ## [ PlaceHolder,...,Expr,...]
                  qw(_query),   ##  Query object for INSERT ... SELECT
                  qw(dbh sth)],
    ;

## new Insert()
## new Insert(@columns)
## new Insert($dbh,[@columns])
sub init
{
    my $self = shift;
    $self->_column_names([]);
    $self->_values([]);
    $self->_sql_values([]);
    $self->_table();

    ## Check for a dbh
    for ( map{ UNIVERSAL::isa($_, 'ARRAY') ? (@$_) : $_ }  @_){
        if (UNIVERSAL::isa($_,'DBI::db')){
            $self->dbh($_)
        }
        elsif (UNIVERSAL::isa($_,'DBomb::Meta::TableInfo')){
            $self->into($_);
        }
        else{
            $self->columns($_);
        }
    }
}

## Same as prepare->execute
## insert()
## insert(@bind_values)
## insert($dbh,@bind_values)
sub insert
{
    my $self = shift;
    my @bv;

    for (@_){
        if (UNIVERSAL::isa($_,'DBI::db')){ $self->dbh($_) }
        else { push @bv, $_ }
    }
    assert(defined($self->dbh), 'insert requires a dbh');

    $self->prepare unless $self->sth;
    return $self->execute(@bv);
}

## Note: ValuesObjects are automatically added to values() list
## columns(names or infos or values)
## columns([names or infos or values])
sub columns
{
    my $self = shift;
        assert(@_);

    ## allow listrefs
    my @a = map {UNIVERSAL::isa($_,'ARRAY')? (@$_) : $_ } @_;

    for (@a){
        if (UNIVERSAL::isa($_,'DBomb::Value::Column')){
            $self->_table($_->column_info->table_info->name);
            push @{$self->_column_names}, $_->column_info->name;
            push @{$self->_values}, $_;
        }
        elsif (UNIVERSAL::isa($_,'DBomb::Meta::ColumnInfo')){
            $self->_table($_->table_info->name);
            push @{$self->_column_names}, $_->name;
        }
        else{
            push @{$self->_column_names}, $_;
        }
        push @{$self->_sql_values}, DBomb::Query::PlaceHolder();
    }
    return $self;
}


## into($table_name)
## into($table_info)
sub into
{
    my $self = shift;
        assert(@_ == 1 && defined($_[0]), 'valid parameters');

    my $table = shift;

    if (UNIVERSAL::isa($table,'DBomb::Meta::TableInfo')){
        $self->_table($table->name);
    }
    elsif(ref($table)){
        croak("invalid parameter. expected TableInfo or table_name");
    }
    else {
        $self->_table($table);
    }

    return $self;
}

## values($values..)
## values(Value objects....)
sub values
{
    my $self = shift;

    my @a = map {UNIVERSAL::isa($_, 'ARRAY')? (@$_) : $_ } @_;
    assert(@a, 'valid parameters');

    my $ix = 0;
    for (@a){
        assert( (not defined $_)
                || !ref($_)
                || UNIVERSAL::isa($_,'DBomb::Value')
                || UNIVERSAL::isa($_,'DBomb::Query::Expr')
                || UNIVERSAL::isa($_,'DBomb::Query')
                || $_ eq DBomb::Query::PlaceHolder(),
                'values() must be scalars, PlaceHolders, Values, or Expr objects');

        next if (defined($_) && $_ eq DBomb::Query::PlaceHolder());
        if (UNIVERSAL::isa($_, 'DBomb::Query::Expr')){
            $self->_sql_values->[$ix] = $_; ## expressions go in the sql...
        }
        push @{$self->_values}, $_;

    }continue{ $ix++ }

    return $self;
}

sub select
{
    my $self = shift;
    $self->_query(new DBomb::Query(@_));
    $self
}

sub sql
{
    my ($self, $dbh) = @_;
    $self->dbh($dbh) if defined $dbh;
    $dbh = $self->dbh;

    assert(defined($dbh), 'DBomb::Query::Insert::sql method requires a dbh');

    my $sql = "INSERT INTO " . $self->_table;

    my $names = $self->_column_names;
    $sql .= " ( " . CORE::join(', ', @$names) . ")" if @$names;


    my $sql_values = $self->_sql_values;

    if (defined $self->_query){
        $sql .= $self->_query->sql($self->dbh);
    }
    else{
        $sql .= (" VALUES (" . CORE::join(',', map{
                        UNIVERSAL::isa($_,'DBomb::Query::Expr')
                            ? $_->sql($self->dbh)
                            : '?'
                    } @$sql_values) . ')') if @$sql_values;
    }


    return ctx_0($sql,wantarray?@{$self->bind_values} : ());
}

sub bind_values
{
    my $self = shift;
    my $bv = [];
        assert(!@_, 'bind_values takes no parameters');

    for (@{$self->_values}){
        if    (UNIVERSAL::isa($_,'DBomb::Value::Column')) { push @$bv, $_->get_value_for_update; }
        elsif (UNIVERSAL::isa($_,'DBomb::Query::Expr'))   { push @$bv, @{$_->bind_values} }
        else  { push @$bv, $_ }
    }
    
    if ($self->_query){
        push @$bv, @{$self->_query->bind_values};
    }
    return $bv;
}

## prepare()
## prepare($dbh)
sub prepare
{
    my ($self,$dbh) = @_;

    $self->dbh($dbh) if defined $dbh;
        assert(defined($self->dbh), 'insert prepare requires a dbh');
        assert(defined($self->_table), 'insert prepare requires a table');

    if ($DBomb::Conf::prepare_cached){
        $self->sth($self->dbh->prepare_cached(scalar $self->sql));
    }else{
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

    $self->sth->execute((@{$self->bind_values},@bind_values));
    return $self;
}

## returns a deep copy.
## @note The database handle will be shared by the clone, and
## the internal statement handle will set to undef in the clone.
## clone ()
sub clone
{
    die "Not implemented";
    my $self = shift;

        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(@_ == 0);

    my $clone = __PACKAGE__->new();

    return $clone;
}

## Grabs the last auto_increment column
## last_insert_id
sub last_insert_id
{
    my $self = shift;
    assert(@_ == 0, "last_insert_id takes no arguments");
    assert($self->dbh, "last_insert_id requires a valid dbh");

    ## DANGER!! MYSQL-SPECIFIC!
    ## DANGER!! dbh must return the same (if from a pool)
    return $self->dbh->{'mysql_insertid'};
}



## Wrappers around _query for INSERT...SELECT
##
sub  from        {  my  $self  =  shift;  assert($self->_query);  $self->_query->from(@_)        ;  $self  }
sub  join        {  my  $self  =  shift;  assert($self->_query);  $self->_query->join(@_)        ;  $self  }
sub  right_join  {  my  $self  =  shift;  assert($self->_query);  $self->_query->right_join(@_)  ;  $self  }
sub  left_join   {  my  $self  =  shift;  assert($self->_query);  $self->_query->left_join(@_)   ;  $self  }
sub  on          {  my  $self  =  shift;  assert($self->_query);  $self->_query->on(@_)          ;  $self  }
sub  using       {  my  $self  =  shift;  assert($self->_query);  $self->_query->using(@_)       ;  $self  }
sub  where       {  my  $self  =  shift;  assert($self->_query);  $self->_query->where(@_)       ;  $self  }
sub  and         {  my  $self  =  shift;  assert($self->_query);  $self->_query->and(@_)         ;  $self  }
sub  or          {  my  $self  =  shift;  assert($self->_query);  $self->_query->or(@_)          ;  $self  }
sub  group_by    {  my  $self  =  shift;  assert($self->_query);  $self->_query->group_by(@_)    ;  $self  }
sub  having      {  my  $self  =  shift;  assert($self->_query);  $self->_query->having(@_)      ;  $self  }
sub  order_by    {  my  $self  =  shift;  assert($self->_query);  $self->_query->order_by(@_)    ;  $self  }
sub  asc         {  my  $self  =  shift;  assert($self->_query);  $self->_query->asc(@_)         ;  $self  }
sub  desc        {  my  $self  =  shift;  assert($self->_query);  $self->_query->desc(@_)        ;  $self  }
sub  limit       {  my  $self  =  shift;  assert($self->_query);  $self->_query->limit(@_)       ;  $self  }
sub  sql_small_result {  my  $self  =  shift;  assert($self->_query);  $self->_query->sql_small_result(@_)       ;  $self  }


1;
__END__

