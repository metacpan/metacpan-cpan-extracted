package DBIx::ORM::Declarative::Schema;

use strict;
use Carp;

use vars qw(@ISA);
@ISA = qw(DBIx::ORM::Declarative);

# Check a create action against constraints, return a data structure suitable
# for use in constructing the required INSERT statement
sub __check_constraints
{
    my ($self, $tab_obj, %params) = @_;
    carp "This method requires an object" and return unless ref $tab_obj;
    my %rv = ();

    # Create a map of constraints by name
    my %cons = map { @{$_}{qw(name constraint)} } $tab_obj->_columns;

    # Primary keys
    my @pk = $tab_obj->_primary_key;

    my @keys = ();
    my @vals = ();
    my @binds = ();
    my $npk = 0;
    if(@pk)
    {
        for my $k (@pk)
        {
            my $v = delete $params{$k};
            if(defined $v)
            {
                if(not $self->apply_method($cons{$k}, 0, $v))
                {
                    carp "column $k constraint failed";
                    return;
                }
                push @binds, $v;
                push @vals, '?';
                push @keys, $k;
            }
            else
            {
                $npk = 1;
                my $fnp = $tab_obj->_for_null_primary;
                if($fnp)
                {
                    push @vals, $fnp;
                    push @keys, $k;
                }
            }
        }
    }
    
    # Non-primary keys
    for my $k (map { $_->{name} } $tab_obj->_columns)
    {
        next if grep { $_ eq $k } @pk;
        my $v = $params{$k};
        if(not $self->apply_method($cons{$k}, 0, $v))
        {
            carp "column $k constraint failed";
            return;
        }

        # We only need to save the key if it was presented in the parameters
        if(exists $params{$k})
        {
            push @keys, $k;
            if(defined $v)
            {
                push @binds, $v;
                push @vals, '?';
            }
            else
            {
                push @vals, 'NULL';
            }
        }
    }

    # Generate the columns list
    my %n2s = $tab_obj->_column_map;
    my $kstr = '' . join(',', map { $n2s{$_} } @keys);

    # The values string
    my $vstr = '' . join(',', @vals);

    # We return a 1 first, because it's conceivable that everything else
    # is empty
    return (1, $kstr, $vstr, $npk, @binds);
}

# Make a SQL-safe alias from a table's name or alias
sub __make_sql_safe
{
    my ($self, $str) = @_;
    $str =~ s/\W/_/g;
    if($str =~ /^[^a-zA-Z_]/)
    {
        $str = "_$str";
    }
    $str;
}

# Create an alias for a table
sub alias
{
    my ($self, @args) = @_;
    if(@args<2)
    {
        if(@args==1)
        {
            return $self->table(@args);
        }
        my $alias;
        eval { $alias = $self->_alias; };
        return $alias;
    }

    # Create/install a new alias
    my ($alias, $table) = @args;
    my $schema_class = ref $self || $self;
    my $alias_class = $schema_class . "::$alias";
    my $table_class = $schema_class . "::$table";

    # Set it up
    no strict 'refs';
    if(not @{$alias_class . '::ISA'})
    {
        @{$alias_class . '::ISA'} = ($table_class);
        *{$alias_class . '::_class'} = sub { $alias_class; };
        *{$alias_class . '::_table'} = sub { $alias; };
        *{$alias_class . '::_alias'} = sub { $table; };
        my $cons = *{$alias_class} = sub
        {
            my ($self) = @_;
            my $rv = $self->new;
            bless $rv, $alias_class unless $rv->isa($alias_class);
            return $rv;
        } ;

        # Make sure row objects promote to alias objects, NOT table objects
        my $row_class = $alias_class . '::Rows';
        @{$row_class . '::ISA'} = ($self->ROW_CLASS, $alias_class);
        *{$alias_class . '::_row_class'} = sub { $row_class; };

        # Install into the table methods hash
        $self->table_method($alias, $cons);
    }
}

# Get the current table name, or switch to a new table, or create a new
# table class
sub table
{
    my ($self, @args) = @_;
    if(@args<2)
    {
        if(@args==1)
        {
            my $table = shift @args;
            return $self unless $table;
            my $meth = $self->table_method($table);
            return unless $meth;
            return $meth->($self);
        }
        my $table;
        eval { $table = $self->_table; };
        return $table;
    }

    # Get the table's name
    my %args = @args;
    my $table = delete $args{table};
    carp "missing table argument" and return unless $table;
    my $name = delete $args{alias} || $table;

    # Column definitions
    my $primary = delete $args{primary};
    my $unique = delete $args{unique};
    my $columns = delete $args{columns};
    carp "missing column definitions" and return unless
        $primary or $unique or $columns;

    # Other miscellany
    my $onpnull = delete $args{for_null_primary};
    my $selonpnull = delete $args{select_null_primary};
    my $join = delete $args{join_clause};
    my $group_by = delete $args{group_by};

    # class and schema names
    my $super = $self->_schema_class;
    my $table_class = $super . "::$name";
    my $row_class = $table_class . "::Rows";
    my $schema = $self->_schema;
    
    # Set up the class heirarchy
    no strict 'refs';
    @{$table_class . '::ISA'} = ($super, $self->TABLE_CLASS);
    @{$row_class . '::ISA'} = ($self->ROW_CLASS, $table_class);

    # Information methods
    *{$table_class . '::_class'} = sub { $table_class; };
    *{$table_class . '::_row_class'} = sub { $row_class; };
    *{$table_class . '::_table'} = sub { $name; };
    *{$table_class . '::_sql_name'} = sub { $table; };
    *{$table_class . '::_for_null_primary'} = sub { $onpnull; };
    *{$table_class . '::_select_null_primary'} = sub { $selonpnull; };
    *{$table_class . '::_join_clause'} = sub { $join; };

    # handle GROUP BY
    if($group_by)
    {
        my @p = @$group_by;
        *{$table_class . '::_group_by' } = sub { @p; };
    }
    else
    {
        *{$table_class . '::_group_by' } = sub { };
    }

    # The table object constructor
    my $cons = sub
    {
        my ($self) = @_;
        my $rv = $self->new;
        bless $rv, $table_class unless $rv->isa($table_class);
        return $rv;
    } ;

    *{$table_class} = $cons;

    $self->table_method($name, $cons);

    # Handle column information
    my %seen_keys;
    my @newcolumns;
    my @p;

    # The primary keys
    @p = @$primary if $primary;
    *{$table_class . '::_primary_key'} = sub { @p; };

    # Just in case the primary keys aren't formally defined elsewhere...
    $seen_keys{$_} =
        { sql_name => $_, name => $_, constraint => 'isstring' } foreach @p;
    my %pk = map {($_,1);} @p;
    @newcolumns = @p;

    # Process unique keys
    my @uniqs;
    push @uniqs, [@p] if @p;
        # This is not strictly needed, since the loop will autovivify
        # $unique to contain an empty array ref if it's undefined at this
        # point.  The loop provides the lvalue context to make this work.
    $unique ||= [ ];
    for my $un (@$unique)
    {
        # Check to see if they've duplicated the primary key
        my %kv = map {($_,1)} @$un;
        delete @kv{@p};
        next if not %kv and scalar(@p) == scalar(@$un);

        # Create a copy so they can't change things out from under us
        push @uniqs, [ @$un ];

        # Add the keys to the %seen_keys hash
        for my $k (@$un)
        {
            next if $seen_keys{$k};
            $seen_keys{$k} = { sql_name => $k, name => $k,
                constraint => 'isnullablestring' };
            push @newcolumns, $k;
        }
    }

    # Get the unique keys data
    # For stability, this _should_ be a Readonly variable
    # Unfortunately, Readonly is really slow on older Perls
    *{$table_class . '::_unique_keys' } = sub { @uniqs; };

    # The rest of the column definitions
    my @coldefs;
    my %colmap;
    for my $col (@$columns)
    {
        # Copy the column definition, hack-n-slash at will...
        my %cdef = %$col;

        # Column names
        my $sql_name = delete $cdef{name};
        my $name = delete $cdef{alias} || $sql_name;
        $colmap{$name} = $sql_name;
        delete $seen_keys{$sql_name};

        # Handle constraints and type matching
        my $constraint = delete $cdef{constraint};
        my $match = delete $cdef{matches};
        my $type = delete $cdef{type};
        if (not $constraint)
        {
            # The default constraint is "match EVERYTHING"
            $constraint = 'isnullablestring';

            # If we have a regular expression, use it
            if($match)
            {
                $constraint = sub
                {
                    my ($self, $value) = @_;
                    $value =~ /$match/;
                };
            }

            # Or if we have a type, use that
            elsif($type)
            {
                # We check for every type except nullablestring,
                # because we already set that as the default
                if($type eq 'number') { $constraint = 'isnumber'; }
                elsif($type eq 'string') { $constraint = 'isstring'; }
                elsif($type eq 'nullablenumber')
                {
                    $constraint = 'isnullablenumber';
                }
            }
        }

        # Save the column definition
        push @coldefs,
            {
                sql_name    => $sql_name,
                name        => $name,
                constraint  => $constraint,
                column_name => $sql_name,
            };

        # Create the column method
        *{$row_class . "::$name"} = $self->__create_column_accessor(
            $sql_name, $pk{$sql_name});
    }

    # Add columns for missing primary/unique key components
    for my $col (@newcolumns)
    {
        my $def = delete $seen_keys{$col};
        next unless $def;
        push @coldefs, $def;
        $colmap{$col} = $col;
        *{$row_class . "::$col"} = $self->__create_column_accessor(
            $col, $pk{$col});
    }

    # Save the column and mapping information
    *{$table_class . '::_columns' } = sub { @coldefs; } ;
    *{$table_class . '::_column_map' } = sub { %colmap; } ;
    my @sql_cols = sort values %colmap;
    *{$table_class . '::_column_sql_names' } = sub { @sql_cols; };

    return &{$table_class}($self);
}

# Create a new join, or return the name of this join object
sub join
{
    my ($self, @args) = @_;
    if(@args<2)
    {
        # Turn this into a join object, if requested
        if(@args==1)
        {
            my $join = shift @args;
            return $self unless $join;
            my $meth = $self->join_method($join);
            return unless $meth;
            return $meth->($self);
        }

        my $join;
        eval { $join = $self->_join; };
        return $join;
    }

    # If we get to here, we're adding a new join declaration.
    my %args = @args;
    my $name = delete $args{name};
    carp "duplicate table/join declaration" and return if $self->can($name);

    # Class family names
    my $super = $self->_schema_class;
    my $join_class = $super . "::$name";
    my $row_class = $join_class . '::Rows';
    my $schema = $self->_schema;

    my $ptab = delete $args{primary};
    carp "missing join name" and return unless $name;

    my $tables = delete $args{tables};
    carp "missing table(s) to join" and return unless $ptab and $tables;

    # Look for the table class(es) we need
    my @req_tabs = ($ptab, map { $_->{table} } @$tables);

    carp "missing required tables" and return
        if grep { not $self->can($_); } @req_tabs;

    # Create a primary table object
    my $ptab_obj = $self->table($ptab);
    carp "No such table '$ptab'" and return unless $ptab_obj;

    # Info to create the join
    my $ptab_name = $ptab_obj->_table;
    my $ptab_alias = $self->__make_sql_safe($ptab_name);

    # Primary table's columns
    my @ptab_cols = map { $_->{name} } $ptab_obj->_columns;

    # Will be turned into _sql_name
    my @join_table_info = ($ptab_obj->_sql_name . " $ptab_alias");

    # Will be turned into _columns
    my @column_info =
    map
    {
        (
            {
                sql_name    => "$ptab_alias." . $_->{sql_name},
                name        => $_->{name},
                constraint  => $_->{constraint},
                table       => $ptab_name,
                table_alias => $ptab_alias,
                column_name => $_->{sql_name},
            },
            {
                sql_name    => "$ptab_alias." . $_->{sql_name},
                name        => $ptab_name . '_' . $_->{name},
                constraint  => $_->{constraint},
                table       => $ptab_name,
                table_alias => $ptab_alias,
                column_name => $_->{sql_name},
            },
        )
    }
    $ptab_obj->_columns;

    # Will be turned into _column_map
    my %column_map =
        map { @{$_}{qw(name sql_name)} } @column_info;

    # The "where" clause info
    my @wherefrags;

    # The "group by" clause info
    my @group_by = map { $column_map{$_} } $ptab_obj->_group_by;

    # Primary table's primary keys
    my %pkeys = map {($_ => 1, $ptab_name . "_$_" => 1)}
        $ptab_obj->_primary_key;

    my @tables_seen;

    # Need to clone table info so it doesn't get changed out from under us
    my @tab_info;
    for my $tab (@$tables)
    {
        my $tab_name = $tab->{table};
        my $tab_obj = $self->table($tab_name);

        # No sense doing all the work if the table doesn't exist...
        carp "No such table '$tab_name'" and return unless $tab_obj;
        my $info_ref = { table => $tab_name };

        # Support secondary table joins
        my @use_cols = @ptab_cols;
        my $usetab_name = $ptab_name;
        my $usetab_alias = $ptab_alias;
        my $secondary = $tab->{on_secondary};
        if($secondary)
        {
            carp "Secondary table '$secondary' unknown" and return
                unless grep { $secondary eq $_ } @tables_seen;
            my $secondary_obj = $self->table($secondary);
            carp "No such table '$secondary'" and return unless $secondary_obj;
            $info_ref->{on_secondary} = $secondary;
            @use_cols = map { $_->{name} } $secondary_obj->_columns;
            $usetab_name = $secondary;
            $usetab_alias = $self->__make_sql_safe($usetab_name);
        }

        push @tables_seen, $tab_name;

        my $tab_alias = $self->__make_sql_safe($tab_obj->_table);

        my %join_info = %{$tab->{columns}};
        my @tab_cols = $tab_obj->_columns;
        for my $k (keys %join_info)
        {
            carp "No such key '$k' on primary table '$usetab_name'" and return
                unless grep { $k eq $_ } @use_cols;
            carp "No such key '$k' on secondary table '$tab_name'" and return
                unless grep { $join_info{$k} eq $_->{name} } @tab_cols;

            $info_ref->{columns}{$k} = $join_info{$k};

            # We set the join keys as primary so they don't get changed on us
            $pkeys{$k} = $pkeys{$join_info{$k}} = 1;

            # Save the "where" clause info
            push @wherefrags, "$usetab_alias.$k = $tab_alias.$join_info{$k}";
        }
        # Save the copy
        push @tab_info, $info_ref;

        # Save table join information
        push @join_table_info, $tab_obj->_sql_name . " $tab_alias";

        # Save group by information
        my %tab_group_by = map { ($_,1) } $tab_obj->_group_by;

        # Housekeeping information
        for my $col ($tab_obj->_columns)
        {
            my $column_ref = "$tab_alias." . $col->{sql_name};
            # Save the column information
            push @column_info,
            {
                sql_name    => $column_ref,
                name        => $col->{name},
                constraint  => $col->{constraint},
                table       => $tab_name,
                table_alias => $tab_alias,
                column_name => $_->{sql_name},
            },
            {
                sql_name    => $column_ref,
                name        => $tab_name . '_' .$col->{name},
                constraint  => $col->{constraint},
                table       => $tab_name,
                table_alias => $tab_alias,
                column_name => $_->{sql_name},
            };

            # Save column mapping info
            $column_map{$col->{name}} ||= $column_ref;
            $column_map{$tab_name . '_' . $col->{name}} ||= $column_ref;

            push @group_by, $column_ref if $tab_group_by{$col->{name}};
        }

        # Keep track of housekeeping information
        $pkeys{$tab_name . "_$_"} = $pkeys{$_} = 1
            foreach $tab_obj->_primary_key;
    }

    # We're constructing refs, so turn off strictness
    no strict 'refs';
    
    # Class heirarchy
    @{$join_class . '::ISA'} = ($super, $self->JOIN_CLASS);
    @{$row_class . '::ISA'} = ($self->JROW_CLASS, $join_class);

    # Information methods
    *{$join_class . '::_class'} = sub { $join_class; };
    *{$join_class . '::_row_class'} = sub { $row_class; };
    *{$join_class . '::_join'} = sub { $name; };
    *{$join_class . '::_primary'} = sub { $ptab; };

    # The stuff to make searching for joins work...
    my $join_tabs = join(', ', @join_table_info);
    *{$join_class . '::_sql_name'} = sub { $join_tabs; };

    my $where_prefix = join(' AND ', @wherefrags);
    *{$join_class . '::_where_prefix'} = sub { $where_prefix; };
    *{$join_class . '::_columns'} = sub { @column_info; };
    *{$join_class . '::_column_map'} = sub { %column_map; };
    *{$join_class . '::_group_by'} = sub { @group_by; };
    
    # We need to get the list of columns...
    my %h = reverse %column_map;
    my @sql_cols = sort keys %h;
    *{$join_class . '::_column_sql_names' } = sub { @sql_cols; };

    my $cons = sub
    {
        my ($self) = @_;
        my $rv = $self->new;
        bless $rv, $join_class unless $rv->isa($join_class);
        return $rv;
    } ;

    *{$join_class} = $cons;

    $self->join_method($name, $cons);
    
    *{$join_class . '::_join_info'} = sub { @tab_info; };

    # Create the accessors
    *{$row_class . "::$_" } =
        $self->__create_column_accessor($column_map{$_}, $pkeys{$_})
        foreach keys %column_map;

    # Return success
    return &{$join_class}($self);
}

# Create a method to access column data
sub __create_column_accessor
{
    my ($self, $name, $pk_flag) = @_;
    if($pk_flag)
    {
        # This is a primary key, so it's read-only
        return sub
        {
            my $self = shift;
            carp "$name is not a class method" and return unless ref $self;
            carp "$name is part of the primary key" and return $self if @_;
            return $self->{__data}{$name};
        };
    }

    # If we get to here, it's not a primary key, so we can beat on it
    return sub
    {
        my $self = shift;
        carp "$name is not a class method" and return unless ref $self;
        my $val = $self->{__data}{$name};
        if(@_)
        {
            my $nval = $_[0];
            # Changing undef to undef is not a change...
            return $self if not defined $val and not defined $nval;
            if(not defined $val or $nval ne $val)
            {
                delete $self->{__data}{$name};
                $self->{__data}{$name} = $nval if defined $nval;
                $self->{__dirty} = 1;
            }
            return $self;
        }
        return $val;
    };
}

1;
