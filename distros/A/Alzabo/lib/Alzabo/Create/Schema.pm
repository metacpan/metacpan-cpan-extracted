package Alzabo::Create::Schema;

use strict;
use vars qw($VERSION);

use Alzabo::ChangeTracker;
use Alzabo::Config;
use Alzabo::Create;
use Alzabo::Driver;
use Alzabo::Exceptions
    ( abbr => [ qw( params_exception system_exception ) ] );
use Alzabo::RDBMSRules;
use Alzabo::Runtime;
use Alzabo::SQLMaker;
use Alzabo::Utils;

use File::Spec;

use Params::Validate qw( :all );
Params::Validate::validation_options
    ( on_fail => sub { params_exception join '', @_ } );

use Storable ();
use Tie::IxHash;

use base qw( Alzabo::Schema );

$VERSION = 2.0;

1;

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    validate( @_, { rdbms    => { type => SCALAR },
                    name     => { type => SCALAR },
                    no_cache => { type => SCALAR, default => 0 },
                  } );
    my %p = @_;

    my $self = bless {}, $class;

    params_exception "Alzabo does not support the '$p{rdbms}' RDBMS"
        unless ( ( grep { $p{rdbms} eq $_ } Alzabo::Driver->available ) &&
                 ( grep { $p{rdbms} eq $_ } Alzabo::RDBMSRules->available ) );

    $self->{driver} = Alzabo::Driver->new( rdbms => $p{rdbms},
                                           schema => $self );
    $self->{rules} = Alzabo::RDBMSRules->new( rdbms => $p{rdbms} );

    $self->{sql} = Alzabo::SQLMaker->load( rdbms => $p{rdbms} );

    params_exception "Alzabo::Create::Schema->new requires a name parameter\n"
        unless exists $p{name};

    $self->set_name($p{name});

    $self->{tables} = Tie::IxHash->new;

    $self->_save_to_cache unless $p{no_cache};

    return $self;
}

sub load_from_file
{
    return shift->_load_from_file(@_);
}

sub reverse_engineer
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %p = @_;

    my $self = $class->new( name     => $p{name},
                            rdbms    => $p{rdbms},
                            no_cache => 1,
                          );

    delete $p{rdbms};
    $self->{driver}->connect(%p);

    $self->{rules}->reverse_engineer($self);

    $self->set_instantiated(1);
    my $driver = delete $self->{driver};
    $self->{original} = Storable::dclone($self);
    $self->{driver} = $driver;
    delete $self->{original}{original};
    return $self;
}

sub set_name
{
    my $self = shift;

    validate_pos( @_, { type => SCALAR } );
    my $name = shift;

    return if defined $self->{name} && $name eq $self->{name};

    my $old_name = $self->{name};
    $self->{name} = $name;

    eval { $self->rules->validate_schema_name($self); };
    if ($@)
    {
        $self->{name} = $old_name;

        rethrow_exception($@);
    }

    # Gotta clean up old files or we have a mess!
    $self->delete( name => $old_name ) if $old_name;
    $self->set_instantiated(0);
    undef $self->{original};
}

sub set_instantiated
{
    my $self = shift;

    validate_pos( @_, 1 );
    $self->{instantiated} = shift;
}

sub make_table
{
    my $self = shift;
    my %p = @_;

    my %p2;
    foreach ( qw( before after ) )
    {
        $p2{$_} = delete $p{$_} if exists $p{$_};
    }
    $self->add_table( table => Alzabo::Create::Table->new( schema => $self,
                                                           %p ),
                      %p2 );

    return $self->table( $p{name} );
}

sub add_table
{
    my $self = shift;

    validate( @_, { table  => { isa => 'Alzabo::Create::Table' },
                    before => { optional => 1 },
                    after  => { optional => 1 } } );
    my %p = @_;

    my $table = $p{table};

    params_exception "Table " . $table->name . " already exists in schema"
        if $self->{tables}->EXISTS( $table->name );

    $self->{tables}->STORE( $table->name, $table );

    foreach ( qw( before after ) )
    {
        if ( exists $p{$_} )
        {
            $self->move_table( $_ => $p{$_},
                               table => $table );
            last;
        }
    }
}

sub delete_table
{
    my $self = shift;

    validate_pos( @_, { isa => 'Alzabo::Create::Table' } );
    my $table = shift;

    params_exception "Table " . $table->name ." doesn't exist in schema"
        unless $self->{tables}->EXISTS( $table->name );

    foreach my $fk ($table->all_foreign_keys)
    {
        foreach my $other_fk ( $fk->table_to->foreign_keys_by_table($table) )
        {
            $fk->table_to->delete_foreign_key($other_fk);
        }
    }

    $self->{tables}->DELETE( $table->name );
}

sub move_table
{
    my $self = shift;

    validate( @_, { table  => { isa => 'Alzabo::Create::Table' },
                    before => { isa => 'Alzabo::Create::Table',
                                optional => 1 },
                    after  => { isa => 'Alzabo::Create::Table',
                                optional => 1 } } );
    my %p = @_;

    if ( exists $p{before} && exists $p{after} )
    {
        params_exception
            "move_table method cannot be called with both 'before' and 'after' parameters";
    }

    if ( $p{before} )
    {
        params_exception "Table " . $p{before}->name . " doesn't exist in schema"
            unless $self->{tables}->EXISTS( $p{before}->name );
    }
    else
    {
        params_exception "Table " . $p{after}->name . " doesn't exist in schema"
            unless $self->{tables}->EXISTS( $p{after}->name );
    }

    params_exception "Table " . $p{table}->name . " doesn't exist in schema"
        unless $self->{tables}->EXISTS( $p{table}->name );

    $self->{tables}->DELETE( $p{table}->name );

    my $index;
    if ( $p{before} )
    {
        $index = $self->{tables}->Indices( $p{before}->name );
    }
    else
    {
        $index = $self->{tables}->Indices( $p{after}->name ) + 1;
    }

    $self->{tables}->Splice( $index, 0, $p{table}->name => $p{table} );
}

sub register_table_name_change
{
    my $self = shift;

    validate( @_, { table => { isa => 'Alzabo::Create::Table' },
                    old_name => { type => SCALAR } } );
    my %p = @_;

    params_exception "Table $p{old_name} doesn't exist in schema"
        unless $self->{tables}->EXISTS( $p{old_name} );

    my $index = $self->{tables}->Indices( $p{old_name} );
    $self->{tables}->Replace( $index, $p{table}, $p{table}->name );
}

sub add_relationship
{
    my $self = shift;

    my %p = @_;

    my $tracker = Alzabo::ChangeTracker->new;

    $self->_check_add_relationship_args(%p);

    # This requires an entirely new table.
    unless ( grep { $_ ne 'n' } @{ $p{cardinality} } )
    {
        $self->_create_linking_table(%p);
        return;
    }

    params_exception "Must provide 'table_from' or 'columns_from' parameter"
        unless $p{table_from} || $p{columns_from};

    params_exception "Must provide 'table_to' or 'columns_to' parameter"
        unless $p{table_to} || $p{columns_to};

    $p{columns_from} =
        ( defined $p{columns_from} ?
          ( Alzabo::Utils::is_arrayref( $p{columns_from} ) ?
            $p{columns_from} :
            [ $p{columns_from} ] ) :
          undef );

    $p{columns_to} =
        ( defined $p{columns_to} ?
          ( Alzabo::Utils::is_arrayref( $p{columns_to} ) ?
            $p{columns_to} :
            [ $p{columns_to} ] ) :
          undef );

    my $f_table = $p{table_from} || $p{columns_from}->[0]->table;
    my $t_table = $p{table_to} || $p{columns_to}->[0]->table;

    if ( $p{columns_from} && $p{columns_to} )
    {
        params_exception
            "Cannot create a relationship with differing numbers of columns " .
            "on either side of the relation"
                unless @{ $p{columns_from} } == @{ $p{columns_to} };
    }

    foreach ( [ columns_from => $f_table ], [ columns_to => $t_table ] )
    {
        my ($key, $table) = @$_;
        if ( defined $p{$key} )
        {
            params_exception
                "All the columns in a given side of the relationship ".
                "must be from the same table"
                    if grep { $_->table ne $table } @{ $p{$key} };
        }
    }

    # Determined later.  This is the column that the relationship is
    # to.  As in table A/column B maps _to_ table X/column Y
    my ($col_from, $col_to);

    # cardinality from -> to
    my $cardinality =
        ( $p{cardinality}->[0] eq '1' && $p{cardinality}->[1] eq '1' ?
          '1_to_1' :
          $p{cardinality}->[0] eq '1' && $p{cardinality}->[1] eq 'n' ?
          '1_to_n' :
          'n_to_1'
        );
    my $method = "_create_${cardinality}_relationship";

    ($col_from, $col_to) = $self->$method( %p,
                                           table_from => $f_table,
                                           table_to   => $t_table,
                                         );

    eval
    {
        $f_table->make_foreign_key( columns_from => $col_from,
                                    columns_to   => $col_to,
                                    cardinality  => $p{cardinality},
                                    from_is_dependent => $p{from_is_dependent},
                                    to_is_dependent   => $p{to_is_dependent},
                                    comment => $p{comment},
                                  );
    };
    if ($@)
    {
        $tracker->backout;

        rethrow_exception($@);
    }

    my @fk;
    eval
    {
        foreach my $c ( @$col_from )
        {
            push @fk, $f_table->foreign_keys( table => $t_table,
                                              column => $c );
        }
    };
    if ($@)
    {
        $tracker->backout;

        rethrow_exception($@);
    }

    $tracker->add( sub { $f_table->delete_foreign_key($_) foreach @fk } );

    # cardinality to -> to
    my $inverse_cardinality =
        ( $p{cardinality}->[1] eq '1' && $p{cardinality}->[0] eq '1' ?
          '1_to_1' :
          $p{cardinality}->[1] eq '1' && $p{cardinality}->[0] eq 'n' ?
          '1_to_n' :
          'n_to_1'
        );
    my $inverse_method = "_create_${inverse_cardinality}_relationship";

    ($col_from, $col_to) = $self->$method( table_from => $t_table,
                                           table_to   => $f_table,
                                           columns_from => $col_to,
                                           columns_to   => $col_from,
                                           cardinality  => [ @{ $p{cardinality} }[1,0] ],
                                           from_is_dependent => $p{to_is_dependent},
                                           to_is_dependent   => $p{from_is_dependent},
                                         );

    if ($p{from_is_dependent})
    {
        $_->nullable(0) foreach @{ $p{columns_from} };
    }

    if ($p{to_is_dependent})
    {
        $_->nullable(0) foreach @{ $p{columns_to} };
    }

    eval
    {
        $t_table->make_foreign_key( columns_from => $col_from,
                                    columns_to   => $col_to,
                                    cardinality  => [ @{ $p{cardinality} }[1,0] ],
                                    from_is_dependent => $p{to_is_dependent},
                                    to_is_dependent   => $p{from_is_dependent},
                                    comment => $p{comment},
                                  );
    };
    if ($@)
    {
        $tracker->backout;

        rethrow_exception($@);
    }
}
# old name - deprecated
*add_relation = \&add_relationship;

sub _check_add_relationship_args
{
    my $self = shift;
    my %p = @_;

    foreach my $t ( $p{table_from}, $p{table_to} )
    {
        next unless defined $t;
        params_exception "Table " . $t->name . " doesn't exist in schema"
            unless $self->{tables}->EXISTS( $t->name );
    }

    params_exception "Incorrect number of cardinality elements"
        unless scalar @{ $p{cardinality} } == 2;

    foreach my $c ( @{ $p{cardinality} } )
    {
        params_exception "Invalid cardinality: $c"
            unless $c =~ /^[01n]$/i;
    }

    # No such thing as 1..0 or n..0
    params_exception "Invalid cardinality: $p{cardinality}->[0]..$p{cardinality}->[1]"
        if  $p{cardinality}->[1] eq '0';
}

sub _create_1_to_1_relationship
{
    my $self = shift;
    my %p = @_;

    return @p{ 'columns_from', 'columns_to' }
        if $p{columns_from} && $p{columns_to};

    # Add these columns to the table which _must_ participate in the
    # relationship, if there is one.  This reduces NULL values.
    # Otherwise, just add to the first table specified in the
    # relation.
    my @order;

    # If the from table is dependent or neither one is or both are ...
    if ( $p{from_is_dependent} ||
         $p{from_is_dependent} == $p{to_is_dependent} )
    {
        @order = ( 'from', 'to' );
    }
    # The to table is dependent
    else
    {
        @order = ( 'to', 'from' );
    }

    # Determine which table we are linking from.  This gets a new
    # column or has its column adjusted) ...
    my $f_table = $p{"table_$order[0]"};

    # And which table we are linking to.  We use the primary key from
    # this table if no column has been provided.
    my $t_table = $p{"table_$order[1]"};

    # Determine whether there is a column in 'to' table we can use.
    my $col_to;
    if ( $p{"columns_$order[1]"} )
    {
        $col_to = $p{"columns_$order[1]"};
    }
    else
    {
        my @c = $t_table->primary_key;

        params_exception $t_table->name . " has no primary key."
            unless @c;

        $col_to = \@c;
    }

    my ($col_from);
    if ($p{"columns_$order[0]"})
    {
        $col_from = $p{"columns_$order[0]"};
    }
    else
    {
        my @new_col;
        foreach my $c ( @$col_to )
        {
            push @new_col, $self->_add_foreign_key_column( table  => $f_table,
                                                           column => $c );
        }

        $col_from = \@new_col;
    }

    return ($col_from, $col_to);
}

# This one's simple.  We always add/adjust the column in the table on
# the 'to' side of the relationship.  This table only relates to one
# row in the 'from' table, but a row in the 'from' table can relate to
# 'n' rows in the 'to' table.
sub _create_1_to_n_relationship
{
    my $self = shift;
    my %p = @_;

    my $f_table = $p{table_from};
    my $t_table = $p{table_to};

    my $col_from;
    if ( $p{columns_from} )
    {
        $col_from = $p{columns_from};
    }
    else
    {
        my @c = $f_table->primary_key;

        # Is there a way to handle this properly?
        params_exception $f_table->name . " has no primary key."
            unless @c;

        $col_from = \@c;
    }

    my $col_to;
    if ($p{columns_to})
    {
        $col_to = $p{columns_to};
    }
    else
    {
        # If the columns this links to in the 'to' table ares not specified
        # explicitly we assume that the user wants to have this coumn
        # created/adjusted in the 'to' table.
        my @new_col;
        foreach my $c ( @$col_from )
        {
            push @new_col, $self->_add_foreign_key_column( table  => $t_table,
                                                           column => $c );
        }

        $col_to = \@new_col;
    }

    return ($col_from, $col_to);
}

sub _create_n_to_1_relationship
{
    my $self = shift;
    my %p = @_;

    # reverse everything ...
    ($p{table_from}, $p{table_to}) = ($p{table_to}, $p{table_from});
    ($p{columns_from}, $p{columns_to}) = ($p{columns_to}, $p{columns_from});
    ($p{from_is_dependent}, $p{to_is_dependent}) =
        ($p{to_is_dependent}, $p{from_is_dependent});

    # pass it into the inverse method and then swap the return values.
    # Tada!
    return ( $self->_create_1_to_n_relationship(%p) )[1,0];
}

# Given two tables and a column, it will add the column to the table
# if it doesn't exist.  Otherwise, it adjusts the column in the table
# to match the given column.  In either case, the two columns (the one
# passed to the method and the one altered/created) will share a
# ColumnDefinition object.

# This is called when a relationship is created and the columns aren't
# specified.  This means that changes to the column in one table are
# automatically reflected in the other table, which is generally a
# good thing.
sub _add_foreign_key_column
{
    my $self = shift;

    validate( @_, { table => { isa => 'Alzabo::Create::Table' },
                    column => { isa => 'Alzabo::Create::Column' } } );
    my %p = @_;

    my $tracker = Alzabo::ChangeTracker->new;

    # Note: This code _does_ explicitly want to compare the string
    # representation of the $p{column}->definition reference.
    my $new_col;
    if ( eval { $p{table}->column( $p{column}->name ) } &&
         ( $p{column}->definition ne $p{table}->column( $p{column}->name )->definition ) )
    {
        # This will make the two column share a single definition
        # object.
        my $old_def = $p{table}->column( $p{column}->name )->definition;
        $p{table}->column( $p{column}->name )->set_definition($p{column}->definition);

        $tracker->add
            ( sub { $p{table}->column
                        ( $p{column}->name )->set_definition($old_def) } );
    }
    else
    {
        # Just add the new column, but use the existing definition
        # object.
        $p{table}->make_column( name => $p{column}->name,
                                definition => $p{column}->definition );

        my $del_col = $p{table}->column( $p{column}->name );
        $tracker->add( sub { $p{table}->delete_column($del_col) } );
    }

    # Return the new column we just made.
    return $p{table}->column( $p{column}->name );
}

sub _create_linking_table
{
    my $self = shift;
    my %p = @_;

    my $tracker = Alzabo::ChangeTracker->new;

    my $t1 = $p{table_from} || $p{columns_from}->[0]->table;
    my $t2 = $p{table_to} || $p{columns_to}->[0]->table;

    my $t1_col;
    if ($p{columns_from})
    {
        $t1_col = $p{columns_from};
    }
    else
    {
        my @c = $t1->primary_key;

        params_exception $t1->name . " has no primary key."
            unless @c;

        $t1_col = \@c;
    }

    my $t2_col;
    if ($p{columns_to})
    {
        $t2_col = $p{columns_to};
    }
    else
    {
        my @c = $t2->primary_key;

        params_exception $t2->name . " has no primary key."
            unless @c;

        $t2_col = \@c;
    }

    # First we create the table.
    my $linking;
    my $name;

    if ( exists $p{name} )
    {
        $name = $p{name};
    }
    elsif ( lc $t1->name eq $t1->name )
    {
        $name = join '_', $t1->name, $t2->name;
    }
    else
    {
        $name = join '', $t1->name, $t2->name;
    }

    $linking = $self->make_table( name => $name );
    $tracker->add( sub { $self->delete_table($linking) } );

    eval
    {
        foreach my $c ( @$t1_col, @$t2_col )
        {
            $linking->make_column( name => $c->name,
                                   definition => $c->definition,
                                   primary_key => 1,
                                 );
        }

        $self->add_relationship
            ( table_from => $t1,
              table_to   => $linking,
              columns_from => $t1_col,
              columns_to   => [ $linking->columns( map { $_->name } @$t1_col ) ],
              cardinality  => [ '1', 'n' ],
              from_is_dependent => $p{from_is_dependent},
              to_is_dependent => 1,
              comment => $p{comment},
            );

        $self->add_relationship
            ( table_from => $t2,
              table_to   => $linking,
              columns_from => $t2_col,
              columns_to   => [ $linking->columns( map { $_->name } @$t2_col ) ],
              cardinality  => [ '1', 'n' ],
              from_is_dependent => $p{to_is_dependent},
              to_is_dependent => 1,
              comment => $p{comment},
            );
    };

    if ($@)
    {
        $tracker->backout;

        rethrow_exception($@);
    }
}

sub instantiated
{
    my $self = shift;

    return $self->{instantiated};
}

sub create
{
    my $self = shift;
    my %p = @_;

    my @sql = $self->make_sql;

    local $self->{db_schema_name} = delete $p{schema_name}
        if exists $p{schema_name};

    $self->{driver}->create_database(%p)
        unless $self->_has_been_instantiated(%p);

    $self->{driver}->connect(%p);

    foreach my $statement (@sql)
    {
        $self->{driver}->do( sql => $statement );
    }

    $self->save_current_name;

    $self->set_instantiated(1);
    my $driver = delete $self->{driver};
    $self->{original} = Storable::dclone($self);
    $self->{driver} = $driver;
    delete $self->{original}{original};
}

sub _has_been_instantiated
{
    my $self = shift;

    my $db_schema_name = $self->db_schema_name;

    return 1 if grep { $db_schema_name eq $_ } $self->{driver}->schemas(@_);
}

sub make_sql
{
    my $self = shift;

    if ($self->{instantiated})
    {
        return $self->rules->schema_sql_diff( old => $self->{original},
                                              new => $self );
    }
    else
    {
        return $self->rules->schema_sql($self);
    }
}

sub sync_backend_sql
{
    my $self = shift;
    my %p = @_;

    local $self->{db_schema_name} = delete $p{schema_name}
        if exists $p{schema_name};

    unless ( $self->_has_been_instantiated(%p) )
    {
        return $self->rules->schema_sql($self);
    }

    my $existing = $self->reverse_engineer( %p,
                                            name => $self->db_schema_name,
                                            rdbms => $self->driver->driver_id,
                                          );

    return $self->rules->schema_sql_diff( old => $existing,
                                          new => $self );
}

sub sync_backend
{
    my $self = shift;
    my %p = @_;

    local $self->{db_schema_name} = delete $p{schema_name}
        if exists $p{schema_name};

    unless ( $self->_has_been_instantiated(%p) )
    {
        $self->set_instantiated(0);
        return $self->create(%p);
    }

    $self->{driver}->connect(%p);

    foreach my $statement ( $self->sync_backend_sql(%p) )
    {
        $self->driver->do( sql => $statement );
    }

    $self->save_current_name;

    $self->set_instantiated(1);
    my $driver = delete $self->{driver};
    $self->{original} = Storable::dclone($self);
    $self->{driver} = $driver;
    delete $self->{original}{original};
}

sub drop
{
    my $self = shift;
    my %p = @_;

    local $self->{db_schema_name} = delete $p{schema_name}
        if exists $p{schema_name};

    $self->{driver}->drop_database(%p);
    $self->set_instantiated(0);
}

sub delete
{
    my $self = shift;
    my %p = @_;

    my $name = $p{name} || $self->name;

    my $schema_dir = File::Spec->catdir( Alzabo::Config::schema_dir(), $name );

    my $dh = do { local *DH; };
    opendir $dh, $schema_dir
        or system_exception "Unable to open $schema_dir directory: $!";

    foreach my $f ( grep { /\.alz|\.rdbms|\.version/ } readdir $dh )
    {
        my $file = File::Spec->catfile( $schema_dir, $f );
        next unless -f $file;

        # untaint
        ($file) = $file =~ /^(.+)$/;

        unlink $file
            or system_exception "Unable to delete $file: $!";
    }
    closedir $dh
        or system_exception "Unable to close $schema_dir: $!";

    rmdir $schema_dir
        or system_exception "Unable to delete $schema_dir: $!";
}

sub is_saved
{
    my $self = shift;

    my %p = @_;

    my $name = $p{name} || $self->name;

    my $schema_dir = File::Spec->catdir( Alzabo::Config::schema_dir(), $name );

    return -d $schema_dir;
}

sub save_to_file
{
    my $self = shift;

    my $schema_dir = File::Spec->catdir( Alzabo::Config::schema_dir(), $self->{name} );
    unless (-e $schema_dir)
    {
        mkdir $schema_dir, 0775
            or system_exception "Unable to make directory $schema_dir: $!";
    }

    my $create_save_name = $self->_base_filename( $self->{name} ) . '.create.alz';

    my $fh = do { local *FH; };
    open $fh, ">$create_save_name"
        or system_exception "Unable to write to $create_save_name: $!\n";

    my $driver = delete $self->{driver};
    Storable::nstore_fd( $self, $fh )
        or system_exception "Can't store to filehandle";

    $self->{driver} = $driver;
    close $fh
        or system_exception "Unable to close $create_save_name: $!";

    my $rdbms_save_name = $self->_base_filename( $self->{name} ) . '.rdbms';

    open $fh, ">$rdbms_save_name"
        or system_exception "Unable to write to $rdbms_save_name: $!\n";

    print $fh $self->{driver}->driver_id
        or system_exception "Can't write to $rdbms_save_name: $!";
    close $fh
        or system_exception "Unable to close $rdbms_save_name: $!";

    my $version_save_name = $self->_base_filename( $self->{name} ) . '.version';

    open $fh, ">$version_save_name"
        or system_exception "Unable to write to $version_save_name: $!\n";
    print $fh $Alzabo::VERSION
        or system_exception "Can't write to $version_save_name: $!";
    close $fh
        or system_exception "Unable to close $version_save_name: $!";

    my $rt = $self->runtime_clone;

    my $runtime_save_name = $self->_base_filename( $self->{name} ) . '.runtime.alz';

    open $fh, ">$runtime_save_name"
        or system_exception "Unable to write to $runtime_save_name: $!\n";
    Storable::nstore_fd( $rt, $fh )
        or system_exception "Can't store to filehandle";
    close $fh
        or system_exception "Unable to close $runtime_save_name: $!";

    $self->_save_to_cache;
}

sub clone
{
    my $self = shift;

    validate( @_, { name  => { type => SCALAR } } );
    my %p = @_;

    my $driver = delete $self->{driver};
    my $clone = Storable::dclone($self);
    $self->{driver} = $driver;

    $clone->{name} = $p{name};
    $clone->{driver} = Alzabo::Driver->new( rdbms => $self->{driver}->driver_id,
                                            schema => $clone );

    $clone->rules->validate_schema_name($clone);
    $clone->{original}{name} = $p{name} if $p{name};

    $clone->set_instantiated(0);

    return $clone;
}

sub runtime_clone
{
    my $self = shift;

    my %s;
    my $driver = delete $self->{driver};
    my $clone = Storable::dclone($self);
    $self->{driver} = $driver;

    foreach my $f ( qw( original instantiated rules driver ) )
    {
        delete $clone->{$f};
    }

    foreach my $t ($clone->tables)
    {
        foreach my $c ($t->columns)
        {
            my $def = $c->definition;
            bless $def, 'Alzabo::Runtime::ColumnDefinition';
            bless $c, 'Alzabo::Runtime::Column';

            delete $c->{last_instantiation_name};
        }

        foreach my $fk ($t->all_foreign_keys)
        {
            bless $fk, 'Alzabo::Runtime::ForeignKey';
        }

        foreach my $i ($t->indexes)
        {
            bless $i, 'Alzabo::Runtime::Index';
        }

        delete $t->{last_instantiation_name};

        bless $t, 'Alzabo::Runtime::Table';
    }
    bless $clone, 'Alzabo::Runtime::Schema';

    return $clone;
}

sub save_current_name
{
    my $self = shift;

    $self->{last_instantiated_name} = $self->name;

    foreach my $table ( $self->tables )
    {
        $table->save_current_name;
    }
}

sub former_name { $_[0]->{last_instantiated_name} }

# Overrides method in base to load create schema instead of runtime
# schema
sub _schema_file_type
{
    return 'create';
}

__END__

=head1 NAME

Alzabo::Create::Schema - Schema objects for schema creation

=head1 SYNOPSIS

  use Alzabo::Create::Schema;

=head1 DESCRIPTION

This class represents the whole schema.  It contains table objects,
which in turn contain columns, indexes, etc.  It contains methods that
act globally on the schema, including methods to save it to disk,
create itself in an RDBMS, create relationships between tables, etc.

=head2 Instantiation

Every schema keeps track of whether it has been instantiated or not.
A schema that is instantiated is one that exists in an RDBMS backend.
This can be done explicitly by calling the schema's
L<C<create()>|Alzabo::Create::Schema/create> method.  It is also
implicitly set when a schema is created as the result of L<reverse
engineering|Alzabo::Create::Schema/reverse_engineer>.

The most important effect of instantiation is that once a schema is
instantiated, the way it generates SQL for itself changes.  Before it
is instantiated, if you ask it to generate SQL via L<the C<make_sql()>
the method|Alzabo::Create::Schema/make_sql>, it will generate the set
of SQL statements that are needed to create the schema from scratch.

After it is instantiated, the schema will instead generate the SQL
necessary to convert the version in the RDBMS backend to match the
object's current state.  This can be thought of as a SQL 'diff'.

While this feature is quite useful, it can be confusing too.  The most
surprising aspect of this is that if you create a schema via L<reverse
engineering|Alzabo::Create::Schema/reverse_engineer> and then call
L<the C<make_sql()> method|Alzabo::Create::Schema/make_sql>, you will
not get any SQL.  This is because the schema knows that it is
instantiated and it also knows that it is the same as the version in
the RDBMS, so no SQL is necessary.

You can use L<the C<set_instantiated()>
method|Alzabo::Create::Schema/set_instantiated ($bool)> method to
change whether or not the schem thinks it is instantiated.

=head1 INHERITS FROM

C<Alzabo::Schema>

=for pod_merge merged

=head1 METHODS

=head2 Constructors

=head2 new

This constructor takes the following parameters:

=over 4

=item * name => $name

This is the name of the schema, and will be the name of the database
in the RDBMS.

=item * rdbms => $rdbms

This is a string identifying the RDBMS.  The allowed values are
returned from the
L<C<Alzabo::RDBMSRules-E<gt>available>|Alzabo::RDBMSRules/available>
method.  These are values such as 'MySQL', 'PostgreSQL', etc.

=back

It returns a new C<Alzabo::Create::Schema> object.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::System>|Alzabo::Exceptions>

=head2 load_from_file

This constructor takes the following parameters:

=over 4

=item * name => $schema_name

=back

Returns a schema object previously saved to disk, as specified by the
"name" parameters.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::System>|Alzabo::Exceptions>

=head2 reverse_engineer

Attempts to connect to a database and instantiate a new schema object
based on information in the specified database.  The returned object
will have its instantiated value set to true so that subsequent
changes will lead to SQL diffs, as opposed to SQL to create the
database from scratch.

The schema object returned by this method will have its instantiated
attribute set as true.

It takes the following parameters:

=over 4

=item * name => $name

The name of the database with which to connect.

=item * rdbms => $rdbms

See the L<C<new>|new> method documentation for an explanation of this
parameter.

=back

In addition, this method takes any parameters that can be used when
connecting to the RDBMS, including "user", "password", "host", and
"port".

Returns a new C<Alzabo::Create::Schema> object.

=head2 Other Methods

=for pod_merge name

=head2 set_name ($name)

Changes the schema name.  Since schemas are saved on disk with
filenames based on the schema name, this deletes the files for the old
name.  Call L<C<save_to_file()>|save_to_file> immediately afterwards
if you want to make sure you have a copy of the schema saved.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::System>|Alzabo::Exceptions>

=for pod_merge table

=for pod_merge tables

=for pod_merge has_table

=head2 make_table

This method makes a new table and adds it to the schema, the
parameters given are passed directly to the L<C<<
Alzabo::Create::Table->new() >>|Alzabo::Create::Table/new> method.
The "schema" parameter is filled in automatically.

If a "before" or "after" parameter is given then the
L<C<move_table()>|move_table> method will be called to move the new
table to the appropriate position.

Returns a new L<C<Alzabo::Create::Table>|Alzabo::Create::Table>
object.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions>

=head2 delete_table (C<Alzabo::Create::Table> object)

Removes the given table from the schema.  This method will also delete
all foreign keys in other tables that point at the given table.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 add_table

Add a table to the schema.

This methods takes the following parameters:

=over 4

=item * table => C<Alzabo::Create::Table> object

=item * after => C<Alzabo::Create::Table> object (optional)

... or ...

=item * before => C<Alzabo::Create::Table> object (optional)

=back

Returns a new L<C<Alzabo::Create::Table>|Alzabo::Create::Table>
object.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 move_table

Allows you to change the order of the tables as they are stored in the
schema.

This method takes the following parameters:

=over 4

=item * table => C<Alzabo::Create::Table> object

The table to move.

and either ...

=item * before => C<Alzabo::Create::Table> object

Move the table before this table

... or ...

=item * after => C<Alzabo::Create::Table> object

Move the table after this table.

=back

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 add_relationship

Creates a relationship between two tables.  This involves creating
L<C<Alzabo::Create::ForeignKey>|Alzabo::Create::ForeignKey> objects in
both tables.  If the "columns_from" and "columns_to" parameters are
not specified then the schema object attempts to calculate the proper
values for these attributes.

To do this, Alzabo attempts to determine the dependencies of the
tables.  If you have specified a cardinality of 1..1, or n..1, in
cases where both tables are independent, or where they are both
dependent then the "table_from" is treated as being the dependent
table for the purposes of determining

If no columns with the same names exist in the other table, then
columns with those names will be created.  Otherwise,
C<add_relationship()> changes the dependent columns so that their
L<C<Alzabo::Create::ColumnDefinition>|Alzabo::Create::ColumnDefinition>
objects are the same as the columns in the table upon which they are
dependent, meaning that changes to the type of one column affects both
at the same time.

If you want to make a multi-column relationship, the assumption is
that the order of the columns is significant.  In other words, the
first column in the "columns_from" parameter should correspond to the
first column in hte "columns_to" parameter and so on.

The number of columns given in "columns_from" and "columns_to" must be
the same except when creating a many to many relationship.

If the cardinality is many to many then a new table will be created to
link the two tables together.  This table will contain the primary
keys of both the tables passed into this function.  It will contain
foreign keys to both of these tables as well, and these tables will be
linked to this new table.

This method takes the following parameters:

=over 4

=item * table_from => C<Alzabo::Create::Table> object (optional if columns_from is provided)

=item * table_to => C<Alzabo::Create::Table> object (optional if columns_to is provided)

=item * columns_from => C<Alzabo::Create::Column> object (optional if table_from is provided)

=item * columns_to => C<Alzabo::Create::Column> object (optional if table_to is provided)

=item * cardinality => [1, 1], [1, 'n'], ['n', 1], or ['n', 'n']

=item * name => $name

If provided, and if the specified cardinality requires the creation of
a linking table, this string will be used to name that linking
table. Otherwise, the new table's name will be synthesized from the
names of those it's linking.

=item * from_is_dependent => $boolean

=item * to_is_dependent => $boolean

=item * comment => $comment

=back

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 create

This method causes the schema to connect to the RDBMS, create a new
database if necessary, and then execute whatever SQL is necessary to
make that database match the current state of the schema object.  If
the schema has been instantiated previously, then it will generate the
SQL necessary to change the database.  This may be destructive
(dropping tables, columns, etc) so be careful.  This will cause the
schema to be marked as instantiated.

Wherever possible, existing data will be preserved.

This method takes any parameters that can be used when connecting to
the RDBMS, including "schema_name", "user", "password", "host", and
"port".

If a "schema_name" parameter is given, then this will be the name
given to the schema in the RDBMS.

B<Warning>: Every time you call C<create()> or C<sync_backend()>, the
schema will consider itself to have been instantiated.  This will
affect how schema diffs are generated.  After this, you will almost
certainly need to use C<sync_backend()> to sync the RDBMS schema,
since the schema's internal notion of it's state may be incorrect.

=head2 instantiated

Returns a boolean value indicating whether the schema has been created
in an RDBMS backend, otherwise it is false.

=head2 set_instantiated ($bool)

Set the schema's instantiated attribute as true or false.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>

=head2 make_sql

Returns an array containing the SQL statements necessary to either
create the database from scratch or update the database to match the
schema object.  See the L<C<create()>|Alzabo::Create::Schema/create>
method for more details.

=head2 drop

Drops the database/schema from the RDBMS.  This will cause the schema
to be marked as not instantiated.  This method does not delete the
Alzabo files from disk.  To do this, call the C<delete()> method.

This method takes any parameters that can be used when connecting to
the RDBMS, including "schema_name", "user", "password", "host", and
"port".

Throws: L<C<Alzabo::Exception::Driver>|Alzabo::Exceptions>

=head2 sync_backend

This method will look at the schema as it exists in the RDBMS backend,
and make any changes that are necessary in order to make this backend
schema match the Alzabo schema object.  If there is no corresponding
schema in the RDBMS backend, then this method is equivalent to the
L<C<create()>|Alzabo::Create::Schema/create> method.

After this method is called, the schema will be considered to be
instantiated.

This method will never be perfect because some RDBMS backends alter
table definitions as they are created.  For example, MySQL has default
column "lengths" for all of its integer columns.  Alzabo tries to
account for these.

In the end, this means that Alzabo may never think that a schema in
the RDBMS exactly matches the state of the Alzabo schema object.  Even
immediately after running this method, running it again may still
cause it to execute SQL commands.  Fortunately, the SQL it generates
will not cause anything to break.

This method takes any parameters that can be used when connecting to
the RDBMS, including "schema_name", "user", "password", "host", and
"port".

Throws: L<C<Alzabo::Exception::Driver>|Alzabo::Exceptions>

=head2 sync_backend_sql

If there is no corresponding schema in the RDBMS backend, then this
method returns the SQL necessary to create the schema from scratch.

This method takes any parameters that can be used when connecting to
the RDBMS, including "schema_name", "user", "password", "host", and
"port".

Throws: L<C<Alzabo::Exception::Driver>|Alzabo::Exceptions>

=head2 delete

Removes the schema object from disk.  It does not delete the database
from the RDBMS.  To do this you must call the L<C<drop>|drop> method
first.

Throws: L<C<Alzabo::Exception::System>|Alzabo::Exceptions>

=head2 clone

This method creates a new object identical to the one that the method
was called on, except that this new schema has a different name, it
does not yet exist on disk, its instantiation attribute is set to
false.

It takes the following parameters:

=over 4

=item * name => $name

=back

This method returns a new Alzabo::Create::Schema object.

Throws: L<C<Alzabo::Exception::Params>|Alzabo::Exceptions>,
L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions>

=head2 save_to_file

Saves the schema to a file on disk.

Throws: L<C<Alzabo::Exception::System>|Alzabo::Exceptions>

=head2 runtime_clone

Returns a new C<Alzabo::Runtime::Schema> object based on the current
schema.

=head2 is_saved

Returns true if the schema has been saved to disk.

=for pod_merge begin_work

=for pod_merge rollback

=for pod_merge commit

=for pod_merge run_in_transaction ( sub { code... } )

=for pod_merge driver

=for pod_merge rules

=for pod_merge sqlmaker

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
