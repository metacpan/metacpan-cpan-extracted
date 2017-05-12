package DBIx::ORM::Declarative::Table;

use strict;
use Carp;
use Scalar::Util qw(reftype);

use vars qw(@ISA);
@ISA = qw(DBIx::ORM::Declarative::Schema);

# The default where clause prefix:
sub _where_prefix { ''; }

# We're not a joing
sub _isjoin { 0; }

# Handle a rollback operation
sub __do_rollback
{
    my ($self, @ops) = @_;
    my $handle = $self->handle;
    carp "Can't roll back: no database" and return unless $handle;

    # Do the passed-in undo operations
    $handle->do($_) foreach @ops;

    # Turn off warnings
    local($SIG{__WARN__}) = $self->w__noop;
    $handle->rollback;
}

# The constraints
# Check for a number
sub isnumber
{
    my ($self, $value) = @_;
    return unless defined $value;
    $value =~ /^(?:\.\d+)|(?:\d+(?:\.\d+)?)$/;
}

# Check for any defined string
sub isstring
{
    my ($self, $value) = @_;
    defined $value and length $value;
}

# Check for a number, or nothing
sub isnullablenumber
{
    my ($self, $value) = @_;
    return defined $value?$self->isnumber($value):1;
}

# Always passes
sub isnullablestring { 1; }

# How to handle operators in a search operation
use constant criteriamap =>
{
    eq => [ '=', 1 ],
    ne => [ '!=', 1 ],
    gt => [ '>', 1 ],
    lt => [ '<', 1 ],
    ge => [ '>=', 1 ],
    le => [ '<=', 1 ],
    isnull => [ 'IS NULL', 0 ],
    notnull => [ 'IS NOT NULL', 0 ],
    in => [ undef, 'IN' ],
    notin => [ undef, 'NOT IN' ],
    like => [ 'LIKE', 1 ],
    notlike => [ 'NOT LIKE', 1 ],
} ;

# How many parameters are taken in limit and order clauses
use constant critexceptions =>
{
    'limit by' => 2,
    'order by' => 1,
};

# Look for a 'limit by' clause
sub __find_limit
{
    my ($self, @critera) = @_;
    my ($offset, $count) = $self->__do_special_purpose('limit by', @critera);
    return unless defined $count;
    my $lc = $self->_limit_clause;
    $lc =~ s/%offset%/$offset/g;
    $lc =~ s/%count%/$count/g;
    $lc;
}

# Handle an "order by" clause we've found
sub __find_orderby
{
    my ($self, @critera) = @_;
    my ($colref) = $self->__do_special_purpose('order by', @critera);
    return unless ref $colref;
    'ORDER BY ' . join(',', @$colref);
}

# Pull out a special-purpose clause
sub __do_special_purpose
{
    my ($self, $clause, @criteria) = @_;

    # Go through each search critereon
    for my $crit (@criteria)
    {
        # Look at each element of the critereon
        my @subcrit = @$crit;
        while(@subcrit)
        {
            my $col = shift @subcrit;

            # Did we find the clause?
            if($col eq $clause)
            {
                return @subcrit;
            }

            # Remove any parameters for a special-purpose clause
            my $cnt = $self->critexceptions->{$col} || 0;
            splice @subcrit, 0, $cnt;
            
            # Eat any following parameters
            splice @subcrit, 0, $self->criteriamap->{$col}[1]
                if $self->criteriamap->{$col};
        }
    }
    return;
}

# Create a where clause for use in searching
sub __create_where
{
    my ($self, @criteria) = @_;

    # Keep track of where clause components and the data bound to it
    my @clauses;
    my @binds;

    # The perl to SQL name map
    my %map = $self->_column_map;

    # Iterate over each critereon
    for my $crit (@criteria)
    {
        # The components that make up this chunk of the where clause
        my @sclause = ();

        my @subcrit = @$crit;
        while(@subcrit)
        {
            my $col = shift @subcrit;
            my $cnt = $self->critexceptions->{$col};

            # Is this a special-purpose clause?
            if($cnt)
            {
                splice @subcrit, 0, $cnt;
                next;
            }
            
            # Get the operator for this column
            my $op = shift @subcrit;
            my $test;

            # Do we actually have a column with this name?
            carp "No such column $col" and return unless $map{$col};

            # Is it a regular operator?
            if(defined $self->criteriamap->{$op}[0])
            {
                # Does it take a parameter?
                if($self->criteriamap->{$op}[1])
                {
                    $test = "$map{$col} " . $self->criteriamap->{$op}[0] . ' ';
                    my $val = shift @subcrit;

                    # Handle literal expressions
                    if(ref $val)
                    {
                        $test .= $$val;
                    }

                    # Or a to-be-quoted value
                    else
                    {
                        $test .= '?';
                        push @binds, $val;
                    }
                }
                else    # No parameter
                {
                    $test = "$col " . $self->criteriamap->{$op}[0];
                }
            }
            else    # IN/NOT IN
            {
                $test = "$map{$col} " . $self->criteriamap->{$op}[1] . ' (';
                my $val = shift @subcrit;

                if('SCALAR' eq reftype $val)
                {
                    # It's a subselect, or other literalized expression
                    $test .= $$val;
                }
                elsif('ARRAY' eq reftype $val)
                {
                    # It's an array of values
                    $test .= join(',', ('?')x@$val);
                    push @binds, @$val;
                }
                else
                {
                    # Treat it like a single-element list
                    $test .= '?';
                    push @binds, $val;
                }

                $test .= ')';
            }
            push @sclause, $test;
        }

        # Stick the pieces together
        push @clauses, join(' AND ', @sclause) if @sclause;
    }

    # join the subclauses together
    # Wrap them in parens if there are more than one
    @clauses = map { "($_)" } @clauses if @clauses > 1;

    # Join them together
    my $where = join(' OR ', @clauses) || '';
    
    # Add any required prefix
    my $where_pre = $self->_where_prefix;
    if($where_pre)
    {
        if($where)
        {
            $where = "($where_pre) AND ($where)";
        }
    }
    return ($where, @binds);
}

# Creates one or more items
# Does not return row objects
# Does not validate the input
# Returns an array of undef or 1 values (depending on reported success)
sub create_only
{
    my ($self, @data) = @_;

    # parameter checking
    my $handle = $self->handle;
    carp "can't create without a database handle" and return unless $handle;
    carp "can't create a row in a JOIN" and return if $self->_join_clause;

    my $table = $self->_sql_name;
    my @cols = map { $_->{name}; } $self->_columns;
    my %name2sql = $self->_column_map;
    my @rv = ();

    # We really don't want any warnings...
    local ($SIG{__WARN__}) = $self->w__noop;
    for my $row (@data)
    {
        # Execute a statement per data item
        my @use_cols = grep { exists $row->{$_}; } @cols;
        my $sql = "INSERT INTO $table (" . join(',', @name2sql{@use_cols})
            . ') VALUES (' . join(',', ('?') x @use_cols) . ')';

        # Get a statement handle
        my $sth = $handle->prepare_cached($sql);
        push @rv, undef and next unless $sth;

        # Execute and save the result
        my $rc = $sth->execute(@{$row}{@use_cols});
        push @rv, $rc?1:undef;
    }
    $handle->commit;
    return @rv;
}

# Creates multiple rows, returns the number of rows created (or
# whatever the handle object says is the number of rows)
sub bulk_create
{
    # $cols_ref is an array of column (alias) names
    my ($self, $cols_ref, @data) = @_;

    my $handle = $self->handle;
    carp "can't create without a database handle" and return unless $handle;
    carp "can't create a row in a JOIN" and return if $self->_join_clause;

    my $table = $self->table;
    carp "can't create a row without a table" and return unless $table;
    my @cols = map { $_->{name}; } $self->_columns;
    my %name2sql = $self->_column_map;
    
    my @col_unk = grep { not exists $name2sql{$_} } @$cols_ref;

    warn "Unknown columns '" . join("', '", @col_unk) . "'" and return
        if @col_unk;

    # Map unique keys to avoid duplicates
    my @uniqs_map;
    for my $un ($self->_unique_keys)
    {
        my $h = { };
        for my $i (0..$#$cols_ref)
        {
            if(grep { $name2sql{$cols_ref->[$i]} eq $_ } @$un)
            {
                $h->{$name2sql{$cols_ref->[$i]}} = $i;
            }
        }
        push @uniqs_map, $h if %$h;
    }

    my $sql = "INSERT INTO $table (" . join(',', @name2sql{@$cols_ref}) . ') ';

    # We build the complete insert statement from a bunch of select statements
    # pasted together with UNION ALL
    # To avoid errors, we use another select to make sure the row is unique
    my @selects;
    for my $d (@data)
    {
        my $sel = 'SELECT ' . join(',', map { $handle->quote($_) } @$d)
            . ' FROM DUAL';
        if(@uniqs_map)
        {
            my @wherefrag = ();
            for my $un (@uniqs_map)
            {
                my @wk = map { "$_=" . $handle->quote($d->[$un->{$_}]) }
                    keys %$un;
                push @wherefrag, join(' AND ', @wk);
            }
            $sel .= " WHERE NOT EXISTS (SELECT 1 FROM $table WHERE (" .
                join(') OR (', @wherefrag) . '))';
        }
        push @selects, $sel;
    }

    $sql .= join(' UNION ALL ', @selects);
    my $res = $handle->do($sql);

    # We don't need warnings about commit being ineffective
    local ($SIG{__WARN__}) = $self->w__noop;
    $handle->commit;
    return $res;
}

# Check parameters against the declared constraints and create
# a row in a table, returning the corresponding row object.
sub create
{
    my ($self, %params) = @_;
    my $handle = $self->handle;
    carp "can't create without a database handle" and return unless $handle;
    carp "can't create a row in a JOIN" and return if $self->_join_clause;

    # Get the data we'd need to do the create
    my ($flag, $keys, $values, $npk, @binds) =
        $self->__check_constraints($self, %params);
    return unless $flag;

    # Generate the SQL command
    my $sql = 'INSERT INTO ' . $self->_table . " ($keys) VALUES ($values)";

    # Run the command
    unshift @binds, undef if @binds;    # Avoid DBI breakage
    my $res = $handle->do($sql, @binds);
    carp "Database error: ", $handle->errstr and return unless $res;

    # Get return information
    my @res;

    # Handle the case where the primary key is null
    if($npk)
    {
        my $np = $self->_select_null_primary;
        if($np)
        {
            my $data = $handle->selectall_arrayref($np);
            if(not $data or not defined $data->[0][0])
            {
                carp "Database error: ", $handle->errstr;
                $self->__do_rollback;
                return;
            }
            @res = $self->search([
                map {($_, 'eq', $data->[0][0])} $self->_primary_key]);
        }
    }

    # Handle defined unique keys
    elsif($self->_unique_keys)
    {
        my ($un) = $self->_unique_keys;
        my @pk = @$un;
        
        # We search by the first unique key we find
        @res = $self->search([
            map {($_, (defined $params{$_}?(eq => $params{$_}):('isnull'))) }
            @pk ]);
    }

    # No unique key - do it based on everything we've got in params
    else
    {
        # This does a search on all passed-in parameters
        @res = $self->search([
            map {($_, (defined $params{$_}?(eq => $params{$_}):('isnull'))) }
            grep { exists $params{$_} }
            keys %params ]);
    }

    # Make sure we have exactly one row returned...
    if(not @res)
    {
        carp $self->E_NOROWSFOUND;
        $self->__do_rollback;
        return;
    }
    if(@res > 1)
    {
        carp $self->E_TOOMANYROWS;
        $self->__do_rollback;
        return;
    }

    # Turn off warnings and commit
    local ($SIG{__WARN__}) = $self->w__noop;
    $handle->commit;
    return $res[0];
}

# Delete stuff from the database
sub delete
{
    my ($self, @criteria) = @_;
    my $handle = $self->handle;
    carp "can't delete without a database handle" and return unless $handle;
    carp "can't delete from a JOIN" and return if $self->_join_clause;

    # Create the SQL command
    my ($where, @binds) = $self->__create_where(@criteria);
    my $sql = "DELETE FROM " . $self->_sql_name;
    $sql .= " WHERE $where" if $where;

    unshift @binds, undef if @binds;    # Handle DBI lossage
    my $res = $handle->do($sql, @binds);
    
    # Report errors
    if(not $res)
    {
        carp "Database error " . $handle->errstr;
        $self->__do_rollback;
        return;
    }

    # Commit and return
    local ($SIG{__WARN__}) = $self->w__noop;
    $handle->commit;
    return $self;
}

# Search the database, return a row object per returned item
sub search
{
    my ($self, @criteria) = @_;
    my $handle = $self->handle;
    carp "can't search without a database handle" and return unless $handle;

    # create the base select statement
    my $sql = 'SELECT ' . join(',', $self->_column_sql_names) . ' FROM '
        . $self->_sql_name;

    # Add any join clause
    my $join = $self->_join_clause;
    $sql .= " $join" if $join;

    # Add a where clause, if necessary
    my ($where, @binds) = $self->__create_where(@criteria);
    $sql .= " WHERE $where" if $where;

    # Add any GROUP BY clause
    my @g = $self->_group_by;
    $sql .= " GROUP BY " . join(',',@g) if @g;

    # Add any ORDER BY clause
    my $ord = $self->__find_orderby(@criteria);
    $sql .= " $ord" if $ord;

    # Add any LIMIT clause
    my $limit = $self->__find_limit(@criteria);
    $sql .= " $limit" if $limit;
    
    unshift @binds, undef if @binds;
    my $data = $handle->selectall_arrayref($sql, @binds);

    carp "Database error " . $handle->errstr and return unless $data;

    # The return values row class
    my $rclass = $self->_row_class;
    $rclass = ref $self if $self->isa($rclass);

    # Create the return values
    my @res;
    for my $row (@$data)
    {
        my $robj = bless $self->new, $rclass;
        $robj->__set_data(@$row);

        # Add the where clause, so we can find this row later
        $robj->__create_where;
        push @res, $robj;
    }
    return @res;
}

# Return the number of rows a query would return
sub size
{
    my ($self, @criteria) = @_;
    my $handle = $self->handle;
    carp "can't find table size without a database handle" and return
        unless $handle;

    # Create the base SQL statement
    my $table = $self->_sql_name;
    my $sql = "SELECT COUNT(*) FROM $table";

    # Add any GROUP BY clause
    my @g = $self->_group_by;
    $sql .= " GROUP BY " . join(',',@g) if @g;

    # Add any join clause
    my $join = $self->_join_clause;
    $sql .= " $join" if $join;

    my ($where, @binds) = $self->__create_where(@criteria);
    $sql .= " WHERE $where" if $where;
    
    unshift @binds, undef if @binds;    # Avoid DBI lossage
    my $data = $handle->selectall_arrayref($sql, @binds);

    carp "Database error " . $handle->errstr and return unless $data;
    return $data->[0][0];
}

1;

__END__
