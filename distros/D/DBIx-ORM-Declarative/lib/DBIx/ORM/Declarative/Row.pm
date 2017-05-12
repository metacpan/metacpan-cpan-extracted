package DBIx::ORM::Declarative::Row;

use strict;
use Carp;

use vars qw(@ISA);
@ISA = qw(DBIx::ORM::Declarative::Table);

# Mark a row for deletion
sub delete
{
    my ($self) = @_;
    carp "delete: not a class method" and return unless ref $self;
    $self->{__deleted} = 1;
    return $self;
}

# Set the data items for this item
sub __set_data
{
    my ($self, @data) = @_;
    carp "not a class method" and return unless ref $self;

    @{$self->{__data}}{$self->_column_sql_names} = @data;
    return $self;
}

# How do we find this item?
sub __create_where
{
    my ($self) = @_;
    carp "not a class method" and return unless ref $self;

    # create the where clause, if we haven't already
    if(not exists $self->{__whereinfo})
    {
        # Column info
        my  @cols = $self->_columns;
        my %name2sql = $self->_column_map;
        my @binds;
        my @wclause;

        # We use either the first set of unique keys, or everything
        my @un = $self->_unique_keys;
        my @colv;
        @colv = map { $name2sql{$_} } @{$un[0]} if @un;
        @colv = map { $_->{sql_name} } @cols unless @colv;

        # Walk the list of columns
        for my $k (@colv)
        {
            # If the data is defined, we use it.  Otherwise, we use IS NULL
            if(defined($self->{__data}{$k}))
            {
                push @wclause, "$k=?";
                push @binds, $self->{__data}{$k};
            }
            else
            {
                push @wclause, "$k IS NULL";
            }
        }

        # Save the where clause and bind values
        @{$self->{__whereinfo}} = (join(' AND ', @wclause), @binds);
    }

    return @{$self->{__whereinfo}};
}

# Save changes to the database
sub commit
{
    my ($self) = @_;

    # Parameter checking
    carp "commit: not a class method" and return unless ref $self;
    my $handle = $self->handle;
    carp "can't commit without a database handle" and return unless $handle;
    return $self unless $self->{__deleted} or $self->{__dirty};

    my ($where, @binds) = $self->__create_where;
    my $sql;

    # Create the SQL command
    if($self->{__deleted})
    {
        $sql = "DELETE FROM " . $self->_sql_name . " WHERE $where";
    }
    else
    {
        my @cols = $self->_columns;
        $sql = "UPDATE " . $self->_sql_name . " SET ";
        $sql .= join(',', map { $_->{sql_name} . '=?' } @cols);
        unshift @binds, map { $self->{__data}{$_->{sql_name}} } @cols;

        $sql .= " WHERE $where";
    }

    unshift @binds, undef if @binds;    # Avoid DBI lossage
 
    # Execute the SQL
    if(not $handle->do($sql, @binds))
    {
        carp "Database error: ", $handle->errstr;
        $self->__do_rollback;
        return;
    }

    # Clean up the object
    delete $self->{__dirty};
    delete $self->{__whereinfo};

    # If we've deleted this data, we're no longer a row object
    if($self->{__deleted})
    {
        delete $self->{__data};
        delete $self->{__deleted};
        bless $self, $self->_class;
    }
    else
    {
        # Reload the "where" clause
        $self->__create_where
    }

    # Commit and return
    local ($SIG{__WARN__}) = $self->w__noop;
    $handle->commit;
    return $self;
}
1;

__END__
