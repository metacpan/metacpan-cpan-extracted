package DBIx::ORM::Declarative::JRow;
use strict;
use Carp;

use vars qw(@ISA);

@ISA = qw(DBIx::ORM::Declarative::Row);

sub delete
{
    carp "You must delete each component of a join individually";
    return;
}

# Create a collection of where clause to find this particular join object
sub __create_where
{
    my ($self) = @_;
    carp "not a class method" and return unless ref $self;

    # Assemble the information, if we haven't already
    if(not exists $self->{__whereinfo})
    {
        # We'll work on these tables...
        for my $table ($self->_primary, map { $_->{table} } $self->_join_info)
        {
            my $tab_obj = $self->table($table);
            
            # Get a list of keys to use
            my ($un) = $tab_obj->_unique_keys;
            $un ||= [ map { $_->{name} } $tab_obj->_columns ];
            my %name2sql_map = $tab_obj->_column_map;

            # Get the data and keys
            my (@wclause, @binds);
            for my $key (@$un)
            {
                my $sql_name = $name2sql_map{$key};
                my $value = $self->{__data}{"$table.$sql_name"};

                # Create the subclause
                if(defined $value)
                {
                    push @wclause, "$sql_name=?";
                    push @binds, $value;
                }
                else
                {
                    push @wclause, "$sql_name IS NULL";
                }
            }

            # Paste it all together
            @{$self->{__whereinfo}{$table}} =
                # The WHERE clause        the data
                (join(' AND ', @wclause), @binds);
        }
    }

    return %{$self->{__whereinfo}};
}

sub commit
{
    my ($self) = @_;
    carp "commit: not a class method" and return unless ref $self;
    return $self unless $self->{__dirty};
    my $handle = $self->handle;
    carp "Can't commit without a handle" and return unless $handle;

    # Give it the business...
    my %whereinfo = $self->__create_where;
    for my $table (keys %whereinfo)
    {
        # Gather our data
        my $tab_obj = $self->table($table);
        my @cols= map { $_->{sql_name} } $tab_obj->_columns;

        # Silly as it may be, a table with no columns is still "legal"
        carp "encountered a table with no columns" and next unless @cols;

        my ($wclause, @binds) = @{$whereinfo{$table}};
        unshift @binds, @{$self->{__data}}{map { "$table.$_" } @cols};

        # The SQL statement
        my $table_name = $tab_obj->_sql_name;
        my $sql = "UPDATE $table_name SET "
            . join(',', map { "$_=?" } @cols) . " WHERE $wclause";

        if(not $handle->do($sql, undef, @binds))
        {
            carp "Database error: ", $handle->errstr;
            $self->__do_rollback;
            return;
        }
    }

    delete $self->{__dirty};
    return $self;
}

1;
__END__
