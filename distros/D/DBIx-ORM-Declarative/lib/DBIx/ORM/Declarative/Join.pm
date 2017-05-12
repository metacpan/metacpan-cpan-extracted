package DBIx::ORM::Declarative::Join;
use strict;
use Carp;

use vars qw(@ISA);
@ISA = qw(DBIx::ORM::Declarative::Table);

# For compatibility with old-style join syntax
sub _join_clause { ''; }

# this is a join
sub _isjoin { 1; }

# Create a row in a multi-table join, observing column constraints
sub create
{
    my ($self, %params) = @_;
    my $handle = $self->handle;
    carp "can't create without a database handle" and return unless $handle;

    # Get table information
    my $primary = $self->_primary;
    my @table_info = $self->_join_info;

    # Check the primary table first
    my $tab_obj = $self->table($primary);
    my ($flag) = $self->__check_constraints($tab_obj, %params);
    return unless $flag;
    my %primary_map = $tab_obj->_column_map;

    # Assemble the data
    my @row_data;

    # Do each other table in turn
    my @backout_cmds;
    for my $tab (@table_info)
    {
        # Get a table object
        my $table = $tab->{table};
        $tab_obj = $self->table($table);
        my $tab_name = $tab_obj->_sql_name;

        # Copy the primary table parameters to where they map on the secondary
        my %p = %params;
        $p{$tab->{columns}{$_}} = delete $p{$_}
                foreach grep { exists $p{$_} } keys %{$tab->{columns}};

        # Override with any long-named parameters
        for my $col (grep { $_->{table} eq $table } $self->_columns)
        {
            # Construct the name, skip this entry if the name is already
            # constructed
            my $nm = $col->{name};
            my $tab_alias = $col->{table_alias};
            next if length($nm)>length($tab_alias)
                and $tab_alias eq substr($nm, length($tab_alias));

            my $augmented_name = $tab_alias . '_' . $nm;
            $p{$nm} = $params{$augmented_name}
                if exists $params{$augmented_name};
        }

        my ($flag, $keys, $values, $npk, @binds)
            = $self->__check_constraints($tab_obj, %p);
        if(not $flag)
        {
            # We have a constraint violation
            $self->__do_rollback(@backout_cmds);
            return;
        }

        # Might as well conditionally create the row
        my $sql = "INSERT INTO $tab_name ($keys) SELECT $values FROM DUAL";
        my %map = $tab_obj->_column_map;

        # Check for a defined primary key
        my @pk = $tab_obj->_primary_key;
        my @conditions;
        if(@pk and not $npk)
        {
            my @wk;
            for my $k (@pk)
            {
                if(exists $p{$k})
                {
                    push @wk, $map{$k} . '=?';
                    push @binds, $p{$k};
                }
            }
            if(@wk)
            {
                # We have part or all of the primary key
                push @conditions, join(' AND ', @wk);
            }
        }

        # Check for other unique keys
        my @uniques = $tab_obj->_unique_keys;
        shift @uniques if @pk;
        for my $un (@uniques)
        {
            my @wk;
            for my $k (@$un)
            {
                if(exists $p{$k})
                {
                    push @wk, $map{$k} . '=?';
                    push @binds, $p{$k};
                }
                else
                {
                    push @wk, $map{$k} . ' IS NULL';
                }
            }
            # save it if we've got it
            push @conditions, join(' AND ', @wk) if @wk;
        }

        # Add the conditional part
        if(@conditions)
        {
            $sql .= " WHERE NOT EXISTS (SELECT 1 FROM $tab_name WHERE "
                 . join(' OR ', map { "($_)" } @conditions)
                 . ')';
        }

        # We have the command - now create the row
        unshift @binds, undef if @binds;    # Deal with DBI bone-headedness
        my $dbres = $handle->do($sql, @binds);
        if(not $dbres)
        {
            carp "Database error: " . $handle->errstr;
            $self->__do_rollback(@backout_cmds);
            return;
        }

        # Get the primary key, if we have one
        if($npk)
        {
            # Set the data return to a string so we know if we never tried
            # to get any data from the database.
            my $data = 'never called';

            # See if we actually created a row
            if($dbres != 0)
            {
                my $np = $tab_obj->_select_null_primary;
                if($np)
                {
                    $data = $handle->selectall_arrayref($np);
                }
            }
            # See if we can find the conflicting row
            else
            {
                # Use the first non-primary unique key we have, or
                # everything if we don't have one.
                my ($ign, $un) = $tab_obj->_unique_keys;
                my @cols;
                if($un)
                {
                    @cols = @$un;
                }
                else
                {
                    @cols = grep { exists $p{$_} }
                            map { $_->{name} }
                            $tab_obj->_columns;
                }

                @binds = ();
                # Generate the SQL
                $sql = 'SELECT ' . join(',', map { $map{$_} } @pk)
                    . " FROM $tab_name WHERE ";
                
                my @wk;
                push @wk, $map{$_} . (defined $p{$_}?'=?':' IS NULL')
                    foreach @cols;
                push @binds, $p{$_} foreach grep { defined $p{$_} } @cols;

                $sql .= join(' AND ', @wk);
                unshift @binds, undef if @binds;

                $data = $handle->selectall_arrayref($sql, @binds);
            }

            # check for errors
            if(not $data)
            {
                carp "Database error: " . $handle->errstr;
                $self->__do_rollback(@backout_cmds);
                return;
            }
            if(ref $data and not defined $data->[0][0])
            {
                carp "Database error: can't find primary key";
                $self->__do_rollback(@backout_cmds);
                return;
            }
            # Save the primary key data
            @p{@pk} = @{$data->[0]} if ref $data;
        }

        # We're gonna have problems if we don't have anything in %p by now...
        if(not %p)
        {
            carp "Database error: no search parameters";
            $self->__do_rollback(@backout_cmds);
            return;
        }

        # Find the row for this join
        # First - create the "WHERE" clause
        # Note that we're literalizing the values so we can reuse this later
        my @cols = map { $_->{name} } $tab_obj->_columns;
        my @wk = map { $map{$_}
            . ((defined $p{$_})?('=' . $handle->quote($p{$_})):(' IS NULL')) }
            grep { exists $p{$_} } @cols;

        my $table_name = $tab_obj->_sql_name;
        my $wclause = " FROM $table_name WHERE " . join(' AND ', @wk);

        # Create the SQL
        $sql = 'SELECT ' . join(',', map { $map{$_} } @cols) . $wclause;

        # Get the data
        my $data = $handle->selectall_arrayref($sql);

        # blow up if we can't find it
        if(not $data or not $data->[0])
        {
            carp $self->E_NOROWSOUND if $data;
            carp 'Database error: ', $handle->errstr unless $data;
            $self->__do_rollback(@backout_cmds);
            return;
        }

        # Blow up if there's too much of a good thing
        if(@$data > 1)
        {
            carp $self->E_TOOMANYROWS;
            $self->__do_rollback(@backout_cmds);
            return;
        }

        # Copy stuff back to the %p hash
        @p{@cols} = @{$data->[0]};

        # Rename it back to what's expected by the primary table
        $p{$_} = delete $p{$tab->{columns}{$_}}
            foreach grep { exists $p{$tab->{columns}{$_}} }
            keys %{$tab->{columns}};

        # Copy it back to the %params hash
        $params{$_} = $p{$_} foreach grep { exists $p{$_} }
            keys %{$tab->{columns}};

        # Save it to the results object
        push @row_data, @{$data->[0]};

        # Save undo instructions
        push @backout_cmds, "DELETE $wclause";
    }

    # Now that we have the secondary rows, create the main one
    my ($keys, $values, $npk, @binds);
    $tab_obj = $self->table($primary);
    ($flag, $keys, $values, $npk, @binds) =
        $self->__check_constraints($tab_obj, %params);

    $self->__do_rollback(@backout_cmds) and return unless $flag;

    # Prepare & execute the statement
    my $table_name = $tab_obj->_sql_name;
    my $sql = "INSERT INTO $table_name ($keys) VALUES ($values)";
    unshift @binds, undef if @binds;
    my $dbres = $handle->do($sql, @binds);

    # Get any null primary key info
    if($npk)
    {
        my @pk = $tab_obj->_primary_key;
        my $np = $tab_obj->_select_null_primary;
        if(@pk and $np)
        {
            my $data = $handle->selectall_arrayref($np);
            if(not $data or not defined $data->[0][0])
            {
                carp $self->E_NOROWSFOUND if $data;
                carp "Database error: " . $handle->errstr unless $data;
                $self->__do_rollback(@backout_cmds);
                return;
            }

            # Save the primary key data
            @params{@pk} = @{$data->[0]};
        }
    }

    # Finally, look for what we just inserted
    my @search_params =
        map {($_, (defined $params{$_}?(eq => $params{$_}):('isnull')))}
        grep { exists $params{$_} }
        map { $_->{name} }
        $self->_columns;

    my @res = $self->search(\@search_params);

    if(not @res)
    {
        $self->__do_rollback(@backout_cmds);
        return;
    }

    if(@res>1)
    {
        # Now we're in somewhat murky water:  we have too many matching
        # rows.  We can't delete what we've inserted, because we may
        # nuke too many rows.  We can't delete the secondary table rows
        # because that may screw up referential integrity.  So, just call
        # rollback on the handle, and if the database is transactional, let
        # it handle the fallout.  Otherwise, there's not a whole lot we can
        # do...
        carp $self->E_TOOMANYROWS;
        $self->__do_rollback;
        return;
    }

    # Turn off warnings and commit
    local ($SIG{__WARN__}) = $self->w__noop;
    $handle->commit;
    return $res[0];
}

sub no_can_do
{
    my ($self, $method) = @_;
    carp "Can't $method via a join - use the individual tables for that";
    return
}

sub delete { $_[0]->no_can_do('delete'); }
sub bulk_create { $_[0]->no_can_do('bulk_create'); }
sub create_only { $_[0]->no_can_do('create_only'); }

1;
__END__
