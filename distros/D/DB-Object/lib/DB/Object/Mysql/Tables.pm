# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Mysql/Tables.pm
## Version v0.300.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2017/07/19
## Modified 2020/05/22
## 
##----------------------------------------------------------------------------
## This package's purpose is to separate the object of the tables from the main
## DB::Object package so that when they get DESTROY'ed, it does not interrupt
## the SQL connection
##----------------------------------------------------------------------------
package DB::Object::Mysql::Tables;
BEGIN
{
    require 5.6.0;
    use strict;
    our( $VERSION, $VERBOSE, $DEBUG );
    use parent qw( DB::Object::Mysql DB::Object::Tables );
    $VERSION    = 'v0.300.1';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
};

sub init
{
    return( shift->DB::Object::Tables::init( @_ ) );
}

# sub init
# {
#     my $self  = shift( @_ );
#     my $table = '';
#     $table    = shift( @_ ) if( @_ && @_ % 2 );
#     return( $self->error( "You must provide a table name to create a table object." ) ) if( !$table );
#     my %arg   = ( @_ );
#     map{ $self->{ $_ } = $arg{ $_ } } keys( %arg );
#     $self->{ 'table' }        = $table if( $table );
#     $self->{ 'structure' }    ||= {};
#     $self->{ 'fields' }        ||= {};
#     $self->{ 'default' }    ||= {};
#     $self->{ 'null' }        ||= {};
#     $self->{ 'alias' }        = {};
#     $self->{ 'avoid' }        = [];
#     ## Load table default, fields, structure informations
#     my $db = $self->database();
#     $self->structure();
#     return( $self->error( "There is no table by the name of $table" ) ) if( !%$ref );
#     return( $self );
# }

##----{ End of generic routines }----##
## Inherited from DB::Object::Tables
## sub alter

sub check
{
    my $self = shift( @_ );
    my $table = $self->{ 'table' } ||
    return( $self->error( 'No table was provided to check' ) );
    my $opt   = shift( @_ ) if( @_ == 1 );
    my %arg   = ( @_ );
    $opt      = \%arg if( !$opt && %arg );
    my $query = "CHECK TABLE $table";
    $query   .= " TYPE = QUICK" if( $opt->{ 'quick' } );
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to check table '$table':\n$query\n", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to check table '$table':\n$query\n", $sth->errstr() ) );
    }
    return( $sth );
}

sub create
{
    my $self  = shift( @_ );
    ## $tbl->create( [ 'ROW 1', 'ROW 2'... ], { 'temporary' => 1, 'TYPE' => ISAM }, $obj );
    my $data  = shift( @_ ) || [];
    my $opt   = shift( @_ ) || {};
    my $sth   = shift( @_ );
    my $table = $self->{ 'table' };
    ## Set temporary in the object, so we can use it to recreate the table creation info as string:
    ## $table->create( [ ... ], { ... }, $obj )->as_string();
    my $temp  = $self->{ 'temporary' } = delete( $opt->{ 'temporary' } );
    ## Check possible options
    my $allowed = 
    {
    'type'                => qr/^(ISAM|MYISAM|HEAP)$/i,
    'auto_increment'    => qr/^(1|0)$/,
    'avg_row_length'    => qr/^\d+$/,
    'checksum'            => qr/^(1|0)$/,
    'comment'            => qr//,
    'max_rows'            => qr/^\d+$/,
    'min_rows'            => qr/^\d+$/,
    'pack_keys'            => qr/^(1|0)$/,
    'password'            => qr//,
    'delay_key_write'    => qr/^\d+$/,
    'row_format'        => qr/^(default|dynamic|static|compressed)$/i,
    'raid_type'            => qr/^(?:1|STRIPED|RAID0|RAID_CHUNKS\s*=\s*\d+|RAID_CHUNKSIZE\s*=\s*\d+)$/,
    };
    my @options = ();
    my @errors  = ();
    ## Avoid working for nothing, make this condition
    if( %$opt )
    {
        my %lc_opt  = map{ lc( $_ ) => $opt->{ $_ } } keys( %$opt );
        $opt = \%lc_opt;
        foreach my $key ( keys( %$opt ) )
        {
            next if( $opt->{ $key } =~ /^\s*$/ || !exists( $allowed->{ $key } ) );
            if( $opt->{ $key } !~ /$allowed->{ $key }/ )
            {
                push( @errors, $key );
            }
            else
            {
                push( @options, $key );
            }
        }
        $opt->{ 'comment' } = "'" . quotemeta( $opt->{ 'comment' } ) . "'" if( exists( $opt->{ 'comment' } ) );
        $opt->{ 'password' } = "'" . $opt->{ 'password' } . "'" if( exists( $opt->{ 'password' } ) );
    }
    if( @errors )
    {
        warn( "The options '", join( ', ', @errors ), "' were either not recognized or malformed and thus were ignored.\n" );
    }
    ## Check statement
    my $select = '';
    if( $sth && ref( $sth ) && ( $sth->isa( "DB::Object::Statement" ) || $sth->can( 'as_string' ) ) )
    {
        $select = $sth->as_string();
        if( $select !~ /^\s*(?:IGNORE|REPLACE)*\s*\bSELECT\s+/ )
        {
            return( $self->error( "SELECT statement to use to create table is invalid:\n$select" ) );
        }
    }
    if( $self->exists() == 0 )
    {
        my $query = 'CREATE ' . ( $temp ? 'TEMPORARY ' : '' ) . "TABLE $table ";
        ## Structure of table if any - 
        ## structure may very well be provided using a select statement, such as:
        ## CREATE TEMPORARY TABLE ploppy TYPE=HEAP COMMENT='this is kewl' MAX_ROWS=10 SELECT * FROM some_table LIMIT 0,0
        my $def    = "(\n" . CORE::join( ",\n", @$data ) . "\n)" if( $data && ref( $data ) && @$data );
        my $tdef   = CORE::join( ' ', map{ "\U$_\E = $opt->{ $_ }" } @options );
        if( !$def && !$select )
        {
            return( $self->error( "Lacking table '$table' structure information to create it." ) );
        }
        $query .= join( ' ', $def, $tdef, $select );
        my $new = $self->prepare( $query ) ||
        return( $self->error( "Error while preparing query to create table '$table':\n$query", $self->errstr() ) );
        ## Trick so other method may follow, such as as_string(), fetchrow(), rows()
        if( !defined( wantarray() ) )
        {
            $self->message( "create(): wantarray in void context" );
            print( STDERR "create(): wantarrays in void context.\n" );
            $new->execute() ||
            return( $self->error( "Error while executing query to create table '$table':\n$query", $new->errstr() ) );
        }
        return( $new );
    }
    else
    {
        return( $self->error( "Table '$table' already exists." ) );
    }
}

sub create_info
{
    my $self    = shift( @_ );
    my $table   = $self->{ 'table' };
    $self->structure();
    my $struct  = $self->{ 'structure' };
    my $fields  = $self->{ 'fields' };
    my $default = $self->{ 'default' };
    my $primary = $self->{ 'primary' };
    my @output = ();
    foreach my $field ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
    {
        push( @output, "$field $struct->{ $field }" );
    }
    push( @output, "PRIMARY KEY(" . CORE::join( ',', @$primary ) . ")" ) if( $primary && @$primary );
    my $info = $self->stat( $table );
    my @opt  = ();
    push( @opt, "TYPE = $info->{ 'type' }" ) if( $info->{ 'type' } );
    my $addons = $info->{ 'create_options' };
    if( $addons )
    {
        $addons =~ s/(\A|\s+)([\w\_]+)\s*=\s*/$1\U$2\E=/g;
        push( @opt, $addons );
    }
    push( @opt, "COMMENT='" . quotemeta( $info->{ 'comment' } ) . "'" ) if( $info->{ 'comment' } );
    my $str = "CREATE TABLE $table (\n\t" . CORE::join( ",\n\t", @output ) . "\n)";
    $str   .= ' ' . CORE::join( ' ', @opt ) if( @opt );
    $str   .= ';';
    return( @output ? $str : undef() );
}

## Inherited from DB::Object::Tables
## sub default

sub drop
{
    my $self  = shift( @_ );
    my $table = $self->{ 'table' } || 
    return( $self->error( "No table was provided to drop." ) );
    my $query = "DROP TABLE $table";
    my $sth = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to drop table '$table':\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to drop table '$table':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub exists
{
    return( shift->table_exists( shift( @_ ) ) );
}

sub lock
{
    my $self = shift( @_ );
    ## There is two arguments, the first one does not look like an exiting table name and the second is a number...
    ## It pretty much looks like a statement lock
    if( @_ == 2 && ( !$self->exists( $_[ 0 ] ) || $_[ 1 ] =~ /^\d+$/ ) )
    {
        return( $self->SUPER::lock( @_ ) );
    }
    my @tables = ();
    my $chk_opt = sub
    {
        my $self  = shift( @_ );
        my $table = shift( @_ );
        my $opt   = shift( @_ );
        my $alias = shift( @_ );
        if( $opt !~ /^(READ|READ\s+LOCAL|(LOW_PRIORITY\s+)?WRITE)$/i )
        {
            return( $self->error( "Bad table '$table' locking option '$opt'." ) );
        }
        if( $alias )
        {
            if( $self->_simple_exist( $alias ) )
            {
                return( $self->error( "Alias '$alias' for table '$table' seems to match an already existing table." ) );
            }
            elsif( $alias !~ /^[\w\_]+$/ )
            {
                return( $self->error( "Illegal characters for table '$table' alias name '$alias'." ) );
            }
        }
        return( 1 );
    };
    ## No parameter, so we default to WRITE for read/write access, but with a low priority
    if( !@_ )
    {
        push( @tables, "$self->{ 'table' } LOW_PRIORITY WRITE" );
    }
    elsif( @_ == 1 )
    {
        my $arg   = shift( @_ );
        my $alias = '';
        my $opt   = '';
        ## Array reference means 'table alias', 'access mode'
        if( $self->_is_array( $arg ) )
        {
            ( $alias, $opt ) = @$arg;
        }
        ## Otherwise just 'access mode'
        else
        {
            $opt = $arg;
        }
        $opt ||= 'LOW_PRIORITY WRITE';
        $chk_opt->( $self, $self->{ 'table' }, $opt, $alias ) || return;
        my @lck = ( $self->{ 'table' } );
        push( @lck, "AS $alias" ) if( $alias );
        push( @lck, uc( $opt ) );
        push( @tables, CORE::join( ' ', @lck ) );
    }
    else
    {
        my %arg = ( @_ );
        my( $tbl, $value );
        while( ( $tbl, $value ) = each( %arg ) )
        {
            my( $alias, $opt );
            if( !$value )
            {
                $opt = 'LOW_PRIORITY WRITE';
            }
            elsif( ref( $value ) )
            {
                ( $alias, $opt ) = @$value;
            }
            else
            {
                $opt = $value;
            }
            $opt ||= 'LOW_PRIORITY WRITE';
            $chk_opt->( $self, $tbl, $opt, $alias ) || return;
            my @lck = ( $tbl );
            push( @lck, "AS $alias" ) if( $alias );
            push( @lck, uc( $opt ) );
            push( @tables, CORE::join( ' ', @lck ) );
        }
    }
    my $query = 'LOCK TABLES ' . CORE::join( ', ', @tables );
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to do tables locking:\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to do tables locking:\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

## Inherited from DB::Object::Tables
## sub name

## Inherited from DB::Object::Tables
## sub null

sub optimize
{
    my $self  = shift( @_ );
    my $table = $self->{ 'table' } ||
    return( $self->error( 'No table was provided to optmize' ) );
    return( $self->error( "Table '$table' does not exist." ) ) if( !$self->exists( $table ) );
    my $query = "OPTIMIZE TABLE $table";
    my $sth = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to optimize table '$table':\n$query\n", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to optimize table '$table':\n$query\n", $sth->errstr() ) );
    }
    return( $sth );
}

## Inherited from DB::Object::Tables
## sub primary

sub rename
{
    my $self  = shift( @_ );
    my $table = $self->{ 'table' } ||
    return( $self->error( 'No table was provided to rename' ) );
    my $new   = shift( @_ ) ||
    return( $self->error( "No new table name was provided to rename table '$table'." ) );
    if( $new !~ /^[\w\_]+$/ )
    {
        return( $self->error( "Bad new table name '$new'." ) );
    }
    my $query = "ALTER TABLE $table RENAME AS $new";
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to rename table '$table' into '$new':\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to rename table '$table' into '$new':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub repair
{
    my $self = shift( @_ );
    my $table = $self->{ 'table' } ||
    return( $self->error( 'No table was provided to repair' ) );
    return( $self->error( "Table '$table' does not exist." ) ) if( !$self->exists( $table ) );
    my $opt   = shift( @_ ) if( @_ == 1 );
    my %arg   = ( @_ );
    $opt      = \%arg if( !$opt && %arg );
    my $query = "REPAIR TABLE $table";
    $query   .= " TYPE = QUICK" if( $opt->{ 'quick' } );
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to repair table '$table':\n$query\n", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to repair table '$table':\n$query\n", $sth->errstr() ) );
    }
    return( $sth );
}

sub stat
{
    my $self  = shift( @_ );
    ## If no $table argument is provided, we will stat all tables
    my $table = shift( @_ );
    my $db    = $self->{ 'database' };
    my $query = $table ? "SHOW TABLE STATUS FROM $db LIKE '$table'" : "SHOW TABLE STATUS FROM $db";
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to get the status of table", ( $table ? " '$table'" : 's' ), ":\n$query", $self->errstr() ) );
    $sth->execute() ||
    return( $self->error( "Error while executing query to get the status of table", ( $table ? " '$table'" : 's' ), ":\n$query", $sth->errstr() ) );
    my $tables = {};
    my $ref    = '';
    while( $ref = $sth->fetchrow_hashref() )
    {
        my %data = map{ lc( $_ ) => $ref->{ $_ } } keys( %$ref );
        my $name = $data{ 'name' };
        map{ $tables->{ $name }->{ $_ } = $data{ $_ } } keys( %data );
    }
    $sth->finish();
    return( wantarray() ? () : undef() ) if( !%$tables );
    return( wantarray() ? %{ $tables->{ $table } } : $tables->{ $table } ) if( $table && exists( $tables->{ $table } ) );
    return( wantarray() ? %$tables : $tables );
}

sub structure
{
    my $self    = shift( @_ );
    my $table   = shift( @_ ) || $self->{ 'table' } ||
    do
    {
        $self->error( "No table provided to get its structure." );
        return( wantarray() ? () : undef() );
    };
    my $sth1 = $self->prepare_cached( "SELECT * FROM information_schema.tables WHERE table_name = ?" ) ||
    return( $self->error( "An error occured while preparing the sql query to get the details of table \"$table\": ", $self->errstr() ) );
    $sth1->execute( $table ) || return( $self->error( "An erro occured while executing the sql query to get the details of table \"$table\": ", $sth1->errstr() ) );
    my $def = $sth1->fetchrow_hashref;
    $sth1->finish;
    $self->{ 'type' } = lc( $def->{table_type} );
    $self->{ 'type' } = 'table' if( $self->{ 'type' } eq 'base table' );
    ## $self->_reset_query();
    ## delete( $self->{ 'query_reset' } );
    ## my $struct  = $self->{ '_structure_real' } || $self->{ 'struct' }->{ $table };
    my $struct  = $self->{ 'structure' };
    my $fields  = $self->{ 'fields' };
    my $default = $self->{ 'default' };
    my $null    = $self->{ 'null' };
    my $types   = $self->{ 'types' };
    if( !%$fields || !%$struct || !%$default )
    {
        my $sth = $self->prepare( "SHOW COLUMNS FROM $table" ) ||
        return( $self->error( "Error while preparing query to get table '$table' columns specification: ", $self->errstr() ) );
        $sth->execute() ||
        return( $self->error( "Error while executing query to get table '$table' columns specification: ", $sth->errstr() ) );
## Returns:
## +-----------+---------------------+------+-----+---------+----------------+
## | Field     | Type                | Null | Key | Default | Extra          |
## +-----------+---------------------+------+-----+---------+----------------+
        my @primary = ();
        my $ref = '';
        my $c   = 0;
        while( $ref = $sth->fetchrow_hashref() )
        {
            my %data = map{ lc( $_ ) => $ref->{ $_ } } keys( %$ref );
            $data{ 'default' } = '' if( !defined( $data{ 'default' } ) );
            ## push( @order, $data{ 'field' } );
            $fields->{ $data{ 'field' } }  = ++$c;
            $types->{ $data{ 'field' } } = $data{ 'type' };
            $default->{ $data{ 'field' } } = '';
            $default->{ $data{ 'field' } } = $data{ 'default' } if( $data{ 'default' } ne '' && !$data{ 'null' } );
            $null->{ $data{ 'field' } } = $data{ 'null' } ? 1 : 0;
            my @define = ( $data{ 'type' } );
            push( @define, "DEFAULT '$data{ 'default' }'" ) if( $data{ 'default' } ne '' || !$data{ 'null' } );
            push( @define, "NOT NULL" ) if( !$data{ 'null' } );
            push( @primary, $data{ 'field' } ) if( $data{ 'key' } );
            $struct->{ $data{ 'field' } } = CORE::join( ' ', @define );
        }
        $sth->finish();
        if( @primary )
        {
            ## $struct->{ '_primary' } = \@primary;
            $self->{ 'primary' } = \@primary;
        }
        ## $self->{ '_structure_real' } = $struct;
        $self->{ 'default' }   = $default;
        $self->{ 'fields' }    = $fields;
        $self->{ 'structure' } = $struct;
        $self->{ 'types' }       = $types;
    }
    return( wantarray() ? () : undef() ) if( !%$struct );
    return( wantarray() ? %$struct : \%$struct );
}

sub unlock
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->CORE::unlock( @_ ) );
    }
    my $query = 'UNLOCK TABLES';
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to unlock tables:\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to unlock tables:\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

DESTROY
{
    ## Do nothing
    ## DB::Object::Tables are never destroyed.
    ## They are just gateway to tables, and they are cached by DB::Object::table()
    ## print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

__END__

