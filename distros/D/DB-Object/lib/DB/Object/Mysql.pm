# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Mysql.pm
## Version v1.1.1
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2024/04/11
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This is the subclassable module for driver specific ones.
package DB::Object::Mysql;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object );
    use vars qw(
        $VERSION $CACHE_QUERIES $CACHE_SIZE $CONNECT_VIA $DB_ERRSTR @DBH 
        $DEBUG $ERROR $MOD_PERL $USE_BIND $USE_CACHE $PLACEHOLDER_REGEXP
        $DATATYPES_DICT $TABLE_CACHE
    );
    eval{ require DBD::mysql; };
    die( $@ ) if( $@ );
    our $TABLE_CACHE = {};
    # <https://dev.mysql.com/doc/refman/8.0/en/data-types.html>
    # the 'constant' property in the dictionary hash is added in structure()
    # See also: SELECT DISTINCT(data_type) FROM information_schema.columns ORDER by data_type
    # but this does not provide a complete list of datatype
    our $DATATYPES_DICT =
    {
        bigint => {
            constant => '',
            name => 'SQL_BIGINT',
            re => qr/^(bigint)/,
            type => 'bigint',
        },
        binary => {
            constant => '',
            name => 'SQL_BINARY',
            re => qr/^binary/,
            type => 'binary',
        },
        bit => {
            constant => '',
            name => 'SQL_BIT',
            re => qr/^(bit)/,
            type => 'bit',
        },
        blob => {
            constant => '',
            name => 'SQL_BLOB',
            re => qr/^blob/,
            type => 'blob',
        },
        curve => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(curve)\b/,
            type => 'curve',
        },
        date => {
            constant => '',
            name => 'SQL_DATE',
            re => qr/^(date)\b/,
            type => 'date',
        },
        datetime => {
            constant => '',
            name => 'SQL_DATETIME',
            re => qr/^(datetime)/,
            type => 'datetime',
        },
        decimal => {
            alias => [qw( dec )],
            constant => '',
            name => 'SQL_DECIMAL',
            re => qr/^(dec|decimal)/,
            type => 'decimal',
        },
        double => {
            alias => [ 'double precision' ],
            constant => '',
            name => 'SQL_DOUBLE',
            re => qr/^(double\s+precision|double)/,
            type => 'double',
        },
        enum => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(enum)\b/,
            type => 'enum',
        },
        float => {
            constant => '',
            name => 'SQL_FLOAT',
            re => qr/^(float)/,
            type => 'float',
        },
        geometry => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(geometry)\b/,
            type => 'geometry',
        },
        geometrycollection => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(geometrycollection)\b/,
            type => 'geometrycollection',
        },
        int => {
            alias => [qw( integer )],
            constant => '',
            name => 'SQL_INTEGER',
            re => qr/^(integer|int)/,
            type => 'int',
        },
        json => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(json)\b/,
            type => 'json',
        },
        linestring => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(linestring)\b/,
            type => 'linestring',
        },
        longlob => {
            constant => '',
            name => 'SQL_BLOB',
            re => qr/^(longlob)\b/,
            type => 'longlob',
        },
        longtext => {
            constant => '',
            name => 'SQL_LONGVARCHAR',
            re => qr/^(longtext)\b/,
            type => 'longtext',
        },
        mediumblob => {
            constant => '',
            name => 'SQL_BLOB',
            re => qr/^(mediumblob)\b/,
            type => 'mediumblob',
        },
        mediumint => {
            constant => '',
            name => 'SQL_BIT',
            re => qr/^(mediumint)/,
            type => 'mediumint',
        },
        mediumtext => {
            constant => '',
            name => 'SQL_LONGVARCHAR',
            re => qr/^(mediumtext)\b/,
            type => 'mediumtext',
        },
        multicurve => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(multicurve)\b/,
            type => 'multicurve',
        },
        multilinestring => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(multilinestring)\b/ ,
            type => 'multilinestring',
        },
        multipoint => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(multipoint)\b/,
            type => 'multipoint',
        },
        multipolygon => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(multipolygon)\b/,
            type => 'multipolygon',
        },
        point => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(point)\b/,
            type => 'point',
        },
        polygon => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(polygon)\b/,
            type => 'polygon',
        },
        set => {
            constant => '',
            name => 'SQL_UNKNOWN_TYPE',
            re => qr/^(set)\b/,
            type => 'set',
        },
        smallint => {
            constant => '',
            name => 'SQL_SMALLINT',
            re => qr/^(smallint)/,
            type => 'smallint',
        },
        text => {
            constant => '',
            name => 'SQL_LONGVARCHAR',
            re => qr/^text/,
            type => 'text',
        },
        timestamp => {
            constant => '',
            name => 'SQL_TIMESTAMP',
            re => qr/^(timestamp)/,
            type => 'timestamp',
        },
        tinyblob => {
            constant => '',
            name => 'SQL_BLOB',
            re => qr/^(tinyblob)\b/,
            type => 'tinyblob',
        },
        tinyint => {
            constant => '',
            name => 'SQL_TINYINT',
            re => qr/^(tinyint)/,
            type => 'tinyint',
        },
        tinytext => {
            constant => '',
            name => 'SQL_LONGVARCHAR',
            re => qr/^(tinytext)\b/,
            type => 'tinytext',
        },
        varbinary => {
            constant => '',
            name => 'SQL_VARBINARY',
            re => qr/^varbinary/,
            type => 'varbinary',
        },
        varchar => {
            alias => [qw( char character ), 'character varying' ],
            constant => '',
            name => 'SQL_VARCHAR',
            re => qr/^((?:character varying|varchar)|(?:(?:character|char)\b(?![[:blank:]]+varying)))/,
            type => 'varchar',
        },
        year => {
            constant => '',
            name => 'SQL_INTERVAL_YEAR',
            re => qr/^(year)/,
            type => 'year',
        },
    };
    # DBI->trace(5);
    our $PLACEHOLDER_REGEXP = qr/\b\?\b/;
    our $VERSION = 'v1.1.1';
    use Devel::Confess;
};

use strict;
use warnings;
our $DB_ERRSTR     = '';
our $DEBUG         = 0;
our $CACHE_QUERIES = [];
our $CACHE_SIZE    = 10;
our $CACHE_TABLE   = {};
our $USE_BIND      = 0;
our $USE_CACHE     = 0;
our $MOD_PERL      = 0;
our @DBH           = ();
our $CONNECT_VIA;
if( $INC{ 'Apache/DBI.pm' } && 
    substr( $ENV{GATEWAY_INTERFACE}|| '', 0, 8 ) eq 'CGI-Perl' )
{
    $CONNECT_VIA = "Apache::DBI::connect";
    $MOD_PERL++;
}
# Actually the one in DB::Object is used, because DBD::mysql has no datatype constants of its own
# our $DATATYPES = {};
foreach my $type ( keys( %$DATATYPES_DICT ) )
{
    if( CORE::exists( $DATATYPES_DICT->{ $type }->{alias} ) && 
        ref( $DATATYPES_DICT->{ $type }->{alias} ) eq 'ARRAY' &&
        scalar( @{$DATATYPES_DICT->{ $type }->{alias}} ) )
    {
        foreach my $alias ( @{$DATATYPES_DICT->{ $type }->{alias}} )
        {
            next if( CORE::exists( $DATATYPES_DICT->{ $alias } ) );
            $DATATYPES_DICT->{ $alias } = $DATATYPES_DICT->{ $type };
        }
    }
}

my $keys = $DBI::EXPORT_TAGS{sql_types};
my @constants_to_ignore = qw(
    SQL_GUID SQL_WLONGVARCHAR SQL_WVARCHAR SQL_WCHAR SQL_LONGVARBINARY SQL_LONGVARCHAR
    SQL_UNKNOWN_TYPE SQL_ALL_TYPES SQL_NUMERIC SQL_REAL SQL_INTERVAL SQL_TIME SQL_BOOLEAN
    SQL_UDT SQL_UDT_LOCATOR SQL_ROW SQL_REF SQL_BLOB_LOCATOR SQL_CLOB SQL_CLOB_LOCATOR
    SQL_ARRAY SQL_ARRAY_LOCATOR SQL_MULTISET SQL_MULTISET_LOCATOR SQL_TYPE_DATE 
    SQL_TYPE_TIME SQL_TYPE_TIMESTAMP SQL_TYPE_TIME_WITH_TIMEZONE SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
    SQL_INTERVAL_YEAR SQL_INTERVAL_MONTH SQL_INTERVAL_DAY SQL_INTERVAL_HOUR SQL_INTERVAL_MINUTE
    SQL_INTERVAL_SECOND SQL_INTERVAL_YEAR_TO_MONTH SQL_INTERVAL_DAY_TO_HOUR 
    SQL_INTERVAL_DAY_TO_MINUTE SQL_INTERVAL_DAY_TO_SECOND SQL_INTERVAL_HOUR_TO_MINUTE
    SQL_INTERVAL_HOUR_TO_SECOND SQL_INTERVAL_MINUTE_TO_SECOND
);
foreach my $c ( @$keys )
{
    next if( scalar( grep( /^$c$/, @constants_to_ignore ) ) );
    if( $c =~ /^SQL_(\w+)$/ )
    {
        my $type = lc( $1 );
        my $code = \&{"DBI::$c"};
        my $val = $code->();
        if( !CORE::exists( $DATATYPES_DICT->{ $type } ) )
        {
            warn( "Unknown MySQL constant DBI::${c}" ) if( DB::Object::Mysql->_is_warnings_enabled( 'DB::Object' ) );
            next;
        }
        $DATATYPES_DICT->{ $type }->{constant} = $val;
    }
}

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ );
    $self->{ 'driver' } = 'mysql';
    return( $self );
}
# End of generic routines 

# ROUTINES PROPRIETAIRE 
sub attribute($;$@)
{
    my $self = shift( @_ );
    # $h->{AttributeName} = ...;    # set/write
    # ... = $h->{AttributeName};    # get/read
    # 1 means that the attribute may be modified
    # 0 mneas that the attribute may only be read
    my $name  = shift( @_ ) if( @_ == 1 );
    my %arg   = ( @_ );
    my %attr  = 
    (
    'Warn'            => 1, 
    'Active'        => 0, 
    'Kids'            => 0, 
    'ActiveKids'    => 0, 
    'CachedKids'    => 0,
    'InactiveDestroy'    => 1, 
    'PrintError'    => 1, 
    'RaiseError'    => 1, 
    'ChopBlanks'    => 1, 
    'LongReadLen'    => 1, 
    'LongTruncOk'    => 1, 
    'AutoCommit'    => 1, 
    'Name'            => 0, 
    'RowCacheSize'    => 0, 
    'NUM_OF_FIELDS'    => 0, 
    'NUM_OF_PARAMS'    => 0, 
    'NAME'            => 0, 
    'TYPE'            => 0, 
    'PRECISION'        => 0, 
    'SCALE'            => 0, 
    'NULLABLE'        => 0, 
    'CursorName'    => 0, 
    'Statement'        => 0, 
    'RowsInCache'    => 0 
    );
    # Only those attribute exist
    # Using an a non existing attribute produce an exception, so we better avoid
    if( $name )
    {
        return( $self->{ 'dbh' }->{ $name } ) if( exists( $attr{ $name } ) );
    }
    else
    {
        my $value;
        while( ( $name, $value ) = each( %arg ) )
        {
            # We intend to modifiy the value of an attribute
            # we are allowed to modify this value if it is true
            if( exists( $attr{ $name } ) && 
                defined( $value ) && 
                $attr{ $name } )
            {
                $self->{ 'dbh' }->{ $name } = $value;
            }
        }
    }
}

sub begin_work($;$@)
{
    my $self = shift( @_ );
    $self->{transaction} = 1;
    $self->{AutoCommit_previous} = $self->{dbh}->{AutoCommit};
    $self->{dbh}->{AutoCommit} = 0;
    return( $self );
}

sub commit($;$@)
{
    my $self = shift( @_ );
    $self->{transaction} = 0;
    $self->{dbh}->commit( @_ );
    $self->{dbh}->{AutoCommit} = $self->{AutoCommit_previous} if( length( $self->{AutoCommit_previous} ) );
    return( $self );
}

sub connect
{
    my $that   = shift( @_ );
    my $param = $that->_connection_params2hash( @_ ) || return;
    $param->{driver} = 'mysql';
    $param->{port} = 3306 if( !length( $param->{port} ) );
    return( $that->SUPER::connect( $param ) );
}

# NOTE: sub constant_to_datatype is inherited

sub create_db
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No database name to create was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $params = [];
    # https://dev.mysql.com/doc/refman/5.6/en/create-database.html
    push( @$params, sprintf( 'CHARACTER SET = %s', $opts->{charset} ) ) if( $opts->{charset} );
    push( @$params, sprintf( 'COLLATE = %s', $opts->{collate} ) ) if( $opts->{collate} );
    my $sql = "CREATE DATABASE " . ( $opts->{if_not_exists} ? 'IF NOT EXISTS ' : '' ) . $name;
    if( scalar( @$params ) )
    {
        $sql .= ' ' . join( ' ', @$params );
    }
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my( $sth, $rc );
    # try-catch
    local $@;
    $sth = eval
    {
        $dbh->prepare( $sql );
    };
    if( $@ )
    {
        return( $self->error( "An error occured while prepareing SQL query to create database: ", $@ ) );
    }
    $sth or return( $self->error( "An error occured while prepareing SQL query to create database: ", $dbh->errstr ) );
    
    $rc = eval
    {
        $dbh->prepare( $sql );
    };
    if( $@ )
    {
        return( $self->error( "An error occured while prepareing SQL query to create database: ", $@ ) );
    }
    $rc or return( $self->error( "An error occured while prepareing SQL query to create database: ", $dbh->errstr ) );

    # try-catch
    eval
    {
        $sth->finish;
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error occurred while trying to finish the SQL query to create database: ", $@, "\n$sql" ) );
    }

    my $ref = {};
    my @keys = qw( host port login passwd opt debug );
    @$ref{ @keys } = @$self{ @keys };
    $ref->{database} = $name;
    $dbh = $self->connect( $ref ) || return( $self->error( "I could create the database \"$name\" but oddly enough, I could not connect to it with user \"$ref->{login}\" on host \"$ref->{host}\" with port \"$ref->{port}\"." ) );
    return( $dbh );
}

sub databases
{
    my $self = shift( @_ );
    # return( $self->error( "Not connected to PostgreSQL server yet. Issue $dbh->connect first." ) ) if( !$self->{ 'dbh' } );
    my $dbh;
    # If there is no connection yet, then create one using the postgres login.
    # There should not be a live user and database just to check what databases there are.
    if( !$self->{dbh} )
    {
        my $con = 
        {
        'database' => 'mysql',
        };
        $con->{mysql_read_default_file} = '/etc/my.cnf' if( -f( '/etc/my.cnf' ) );
        if( CORE::exists( $ENV{ 'DB_MYSQL_CON' } ) )
        {
            @$con{ qw( host login passwd ) } = split( /;/, $ENV{ 'DB_MYSQL_CON' } );
        }
        else
        {
            @$con{ qw( host login passwd ) } = @_;
        }
        
        # try-catch
        local $@;
        $dbh = eval
        {
            $self->connect( $con );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to connect to the MySQL server: $@" ) );
        }
        $dbh or return( $self->pass_error );
    }
    else
    {
        $dbh = $self;
    }
    my $temp = $dbh->do( "SHOW DATABASES" )->fetchall_arrayref;
    my @dbases = map( $_->[0], @$temp );
    return( @dbases );
}

# NOTE: sub datatype_dict is inherited

# NOTE: sub datatype_to_constant is inherited

# NOTE: sub datatypes is in inherited

sub get_sql_type
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error( "No sql type was provided to get its constant." ) );
    $type = lc( $type );
    if( CORE::exists( $DATATYPES_DICT->{ $type } ) &&
        $type ne $DATATYPES_DICT->{ $type }->{type} )
    {
        $type = $DATATYPES_DICT->{ $type }->{type};
    }
    my $const;
    if( substr( $type, 0, 4 ) eq 'sql_' )
    {
        $const = $self->{dbh}->can( "DBI::\U${type}\E" );
    }
    else
    {
        $const = $self->{dbh}->can( "DBI::SQL_\U${type}\E" );
    }
    return( '' ) if( !defined( $const ) );
    return( $const->() );
}

# Specific to Mysql (Postgres also uses it)
sub having
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->having( @_ ) );
}

sub last_insert_id
{
    my $self = shift( @_ );
    my $query = $self->{dbh}->prepare( "SELECT LAST_INSERT_ID()" ) || return;
    $query->execute();
    my $val = $query->fetchrow();
    $query->finish();
    return( $val );
}

sub lock
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    my $timeout = shift( @_ ) || 2;
    # my $res = $self->select( "GET_LOCK( '$str', $timeout )" )->fetchrow();
    my $sth = $self->{dbh}->prepare( "SELECT GET_LOCK( '$str', $timeout )" ) ||
    return( $self->error( "Error while preparing query to get lock '$str': ", $self->{dbh}->errstr() ) );
    $sth->execute() ||
    return( $self->error( "Error while executing query to get lock '$str': ", $sth->errstr() ) );
    my $res = $sth->fetchrow;
    $sth->finish();
    $self->{ '_locks' } ||= [];
    push( @{ $self->{_locks} }, $str ) if( $res && $res ne 'NULL' );
    return( $res eq 'NULL' ? undef() : $res );
}

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::Mysql::Query', @_ ) ); }

sub rollback
{
    my $self = shift( @_ );
    $self->{transaction} = 0;
    $self->{dbh}->{AutoCommit} = $self->{AutoCommit_previous} if( length( $self->{AutoCommit_previous} ) );
    return( $self->{dbh}->rollback() );
}

sub stat
{
    my $self = shift( @_ );
    my $type = lc( shift( @_ ) );
    my $sth  = $self->{dbh}->prepare( "SHOW STATUS" );
    $sth->execute();
    my @data = ();
    my $ref  = {};
    while( @data = $sth->fetchrow() )
    {
        $ref->{ lc( $data[ 0 ] ) } = $data[ 1 ];
    }
    $sth->finish();
    if( $type )
    {
        return( exists( $ref->{ $type } ) ? $ref->{ $type } : undef() );
    }
    else
    {
        return( wantarray() ? () : undef() ) if( !%$ref );
        return( wantarray() ? %$ref : $ref );
    }
}

# sub table_exists inherited from DB::Object

sub table_info
{
    my $self = shift( @_ );
    my $table = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $db = $opts->{database} || $self->database;
    # my $sth = $self->{dbh}->table_info( undef(), undef(), $table );
    my $sql = <<EOT;
SELECT
     table_schema AS "schema"
    ,table_name AS "name"
    ,table_type AS "type"
FROM information_schema.tables WHERE table_name=?
EOT
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my $sth = $dbh->prepare_cached( $sql ) || return( $self->error( "An error occured while preparing query to check if table \"$table\" exists in our database: ", $dbh->errstr ) );
    $sth->execute( $table, ( $db ? $db : () ) ) || return( $self->error( "An error occured while executing query to check if table \"$table\" exists in our database: ", $sth->errstr ) );
    my $all = $sth->fetchall_arrayref( {} );
    $sth->finish;
    return( [] ) if( !scalar( @$all ) );
    foreach my $ref ( @$all )
    {
        # example: BASE TABLE
        if( $ref->{type} =~ /^(?:(?:\S+)[[:blank:]]+)?(.*?)$/ )
        {
            $ref->{type} = $2;
        }
    }
    return( $all ) if( $opts->{anywhere} );
    foreach my $ref ( @$all )
    {
        if( $ref->{schema} eq $db )
        {
            return( $ref );
        }
    }
    return( [] );
}

sub tables
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{ 'database' };
    my $sth  = $self->{dbh}->prepare( "SHOW TABLES FROM $db" ) ||
    return( $self->error( "Error while preparing query to get all tables from database '$db'." ) );
    $sth->execute();
    my $ref  = $sth->fetchall_arrayref();
    $sth->finish;
    my @tables = map{ $_->[0] } @$ref;
    return( \@tables );
}

sub tables_info
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{database};
    my @tables = ();
    my $query = <<EOT;
SELECT
   *
  ,table_schema AS "database"
  ,table_name AS "name"
  ,table_type AS "type"
FROM information_schema.tables
WHERE table_schema=?
EOT
    my $sth = $self->{dbh}->prepare_cached( $query ) || return( $self->error( sprintf( "Error while preparing query $query: %s", $self->{dbh}->errstr ) ) );
    $sth->execute( $db ) || return( $self->error( sprintf( "Error while executing query $query: %s", $sth->errstr ) ) );
    my $all = $sth->fetchall_arrayref( {} );
    return( $all );
}

sub unlock
{
    my $self = shift( @_ );
    my $str  = shift( @_ ) ||
    return( $self->error( "No lock string identifier provided." ) );
    # my $res = $self->select( "RELEASE_LOCK( '$str' )" )->fetchrow();
    my $sth = $self->{dbh}->prepare( "SELECT RELEASE_LOCK( '$str' )" ) ||
    return( $self->error( "Error while preparing query to release lock '$str': ", $self->errstr() ) );
    $sth->execute() ||
    return( $self->error( "Error while executing query to release lock '$str': ", $sth->errstr() ) );
    my $res = $sth->fetchrow;
    $sth->finish();
    # Take out the lock from the saved locks pile (used by DESTROY)
    my $locks = $self->{ '_locks' } ||= [];
    my @new   = grep{ !/$str/ } @$locks;
    $locks = [ @new ];
    return( $res eq 'NULL' ? undef() : $res );
}

sub variables
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    $self->error( "Variable '$type' is a read-only value." ) if( @_ );
    my $vars = $self->{ 'variables' } ||= {};
    if( !%$vars )
    {
        my $sth = $self->{dbh}->prepare( "SHOW VARIABLES" ) ||
        return( $self->error( "SHOW VARIABLES is not supported." ) );
        $sth->execute();
        my $ref = $self->fetchall_arrayref();
        my %vars = map{ lc( $_->[ 0 ] ) => $_->[ 1 ] } @$ref;
        $vars = \%vars if( %vars );
        $sth->finish();
    }
    my @found = grep{ /$type/i } keys( %$vars );
    return( '' ) if( !scalar( @found ) );
    return( $vars->{ $found[ 0 ] } );
}

# https://dev.mysql.com/doc/refman/8.0/en/show-variables.html
sub version
{
    my $self  = shift( @_ );
    # If we already have the information, let's use our cache instead of making a query
    return( $self->{_db_version} ) if( length( $self->{_db_version} ) );
    my $sql = 'SELECT @@innodb_version';
    my $sth = $self->do( $sql ) || return( $self->error( "Unable to issue the sql statement '$sql' to get the server version: ", $self->errstr ) );
    my $ver = $sth->fetchrow;
    $sth->finish;
    # We cache it
    $self->{_db_version} = version->parse( $ver );
    return( $ver );
}

sub _connection_options
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    # This should really not be an option. This decode utf8 in database
    $param->{mysql_enable_utf8} = 1 if( !CORE::exists( $param->{mysql_enable_utf8} ) );
    my @mysql_params = grep( /^mysql_/, keys( %$param ) );
    my $opt = $self->SUPER::_connection_options( $param );
    @$opt{ @mysql_params } = @$param{ @mysql_params };
    return( $opt );
}

sub _connection_parameters
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    my $core = [qw( db login passwd host port driver database server opt uri debug cache_connections cache_table unknown_field )];
    my @mysql_params = grep( /^mysql_/, keys( %$param ) );
    # See DBD::mysql for the list of valid parameters
    # E.g.: mysql_client_found_rows, mysql_compression mysql_connect_timeout mysql_write_timeout mysql_read_timeout mysql_init_command mysql_skip_secure_auth mysql_read_default_file mysql_read_default_group mysql_socket mysql_ssl mysql_ssl_client_key mysql_ssl_client_cert mysql_ssl_ca_file mysql_ssl_ca_path mysql_ssl_cipher mysql_local_infile mysql_multi_statements mysql_server_prepare mysql_server_prepare_disable_fallback mysql_embedded_options mysql_embedded_groups mysql_conn_attrs 
    push( @$core, @mysql_params );
    return( $core );
}

sub _dsn
{
    my $self = shift( @_ );
    # "DBI:mysql:database=$sql_db;host=$sql_host;port=$sql_port;mysql_read_default_file=/etc/my.cnf"
    my @params = ( sprintf( 'dbi:%s:database=%s', @$self{ qw( driver database ) } ) );
    if( $self->{host} )
    {
        $self->_load_class( 'Net::IP' ) || return( $self->pass_error );
        my $ip = Net::IP->new( $self->{host} );
        if( $ip )
        {
            if( $ip->version == 6 )
            {
                push( @params, sprintf( 'host=[%s]', $ip->ip ) );
            }
            else
            {
                push( @params, sprintf( 'host=%s', $ip->ip ) );
            }
        }
        else
        {
            push( @params, sprintf( 'host=%s', $self->{host} ) );
        }
    }
    # my @params = sprintf( "dbi:%s:database=%s;host=%s", @$self{ qw( driver database server ) } );
    push( @params, sprintf( 'port=%d', $self->{port} ) ) if( $self->{port} );
    push( @params, sprintf( 'mysql_read_default_file=%s', $self->{mysql_read_default_file} ) ) if( $self->{mysql_read_default_file} );
    return( join( ';', @params ) );
}

sub _placeholder_regexp { return( $PLACEHOLDER_REGEXP ) }

DESTROY
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    if( $self->{ 'sth' } )
    {
        print( STDERR "DESTROY(): Terminating sth '$self' for query:\n$self->{query}\n" ) if( $DEBUG );
        $self->{ 'sth' }->finish();
    }
    elsif( $self->{ 'dbh' } && $class eq 'DB::Object' )
    {
        local( $SIG{ '__WARN__' } ) = sub { };
        # $self->{ 'dbh' }->disconnect();
        if( $DEBUG )
        {
            my( $pack, $file, $line, $sub ) = ( caller( 0 ) )[ 0, 1, 2, 3 ];
            my( $pack2, $file2, $line2, $sub2 ) = ( caller( 1 ) ) [ 0, 1, 2, 3 ];
            print( STDERR "DESTROY database handle ($self) [$self->{ 'query' }]\ncalled within sub '$sub' ($sub2) from package '$pack' ($pack2) in file '$file' ($file2) at line '$line' ($line2).\n" );
        }
        $self->disconnect();
    }
    my $locks = $self->{ '_locks' };
    if( $locks && $self->_is_array( $locks ) )
    {
        foreach my $name ( @$locks )
        {
            $self->unlock( $name );
        }
    }
}

END
{
    # foreach my $dbh ( @DBH )
    # {
    #     $dbh->disconnect();
    # }
};

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DB::Object::Mysql - Mysql Database Object

=head1 SYNOPSIS

    use DB::Object;

    my $dbh = DB::Object->connect({
    driver => 'mysql',
    conf_file => 'db-settings.json',
    database => 'webstore',
    host => 'localhost',
    login => 'store-admin',
    debug => 3,
    }) || bailout( "Unable to connect to Mysql server on host localhost: ", DB::Object->error );

    # Legacy regular query
    my $sth = $dbh->prepare( "SELECT login,name FROM login WHERE login='jack'" ) ||
    die( $dbh->errstr() );
    $sth->execute() || die( $sth->errstr() );
    my $ref = $sth->fetchrow_hashref();
    $sth->finish();
    
    # Get a list of databases;
    my @databases = $dbh->databases;
    # Doesn't exist? Create it:
    my $dbh2 = $dbh->create_db( 'webstore' );
    # Load some sql into it
    my $rv = $dbh2->do( $sql ) || die( $dbh->error );
    
    # Check a table exists
    $dbh->table_exists( 'customers' ) || die( "Cannot find the customers table!\n" );
    
    # Get list of tables, as array reference:
    my $tables = $dbh->tables;
    
    my $cust = $dbh->customers || die( "Cannot get customers object." );
    $cust->where( email => 'john@example.org' );
    my $str = $cust->delete->as_string;
    # Becomes: DELETE FROM customers WHERE email='john\@example.org'
    
    # Do some insert with transaction
    $dbh->begin_work;
    # Making some other inserts and updates here...
    my $cust_sth_ins = $cust->insert(
        first_name => 'Paul',
        last_name => 'Goldman',
        email => 'paul@example.org',
        active => 0,
    ) || do
    {
        # Rollback everything since the begin_work
        $dbh->rollback;
        die( "Error while create query to add data to table customers: " . $cust->error );
    };
    $result = $cust_sth_ins->as_string;
    # INSERT INTO customers (first_name, last_name, email, active) VALUES('Paul', 'Goldman', 'paul\@example.org', '0')
    $dbh->commit;
    # Get the last used insert id
    my $id = $dbh->last_insert_id();
    
    $cust->where( email => 'john@example.org' );
    $cust->order( 'last_name' );
    $cust->having( email => qr/\@example/ );
    $cust->limit( 10 );
    my $cust_sth_sel = $cust->select || die( "An error occurred while creating a query to select data frm table customers: " . $cust->error );
    # Becomes:
    # SELECT id, first_name, last_name, email, created, modified, active, created::ABSTIME::INTEGER AS created_unixtime, modified::ABSTIME::INTEGER AS modified_unixtime, CONCAT(first_name, ' ', last_name) AS name FROM customers WHERE email='john\@example.org' HAVING email ~ '\@example' ORDER BY last_name LIMIT 10
    
    $cust->reset;
    $cust->where( email => 'john@example.org' );
    my $cust_sth_upd = $cust->update( active => 0 )
    # Would become:
    # UPDATE ONLY customers SET active='0' WHERE email='john\@example.org'
    
    # Lets' dump the result of our query
    # First to STDERR
    $login->where( "login='jack'" );
    $login->select->dump();
    # Now dump the result to a file
    $login->select->dump( "my_file.txt" );
    
=head1 VERSION

    v1.1.1

=head1 DESCRIPTION

This package inherits from L<DB::Object>, so any method not mentioned here, but listed there, you can use.

L<DB::Object> is a SQL API much alike C<DBI>.
So why use a private module instead of using that great C<DBI> package?

At first, I started to inherit from C<DBI> to conform to C<perlmod> perl manual page and to general perl coding guidlines. It became very quickly a real hassle. Barely impossible to inherit, difficulty to handle error, too much dependent from an API that change its behaviour with new versions.
In short, I wanted a better, more accurate control over the SQL connection.

So, L<DB::Object> acts as a convenient, modifiable wrapper that provide the programmer with an intuitive, user-friendly and hassle free interface.

=head1 CONSTRUCTOR

=head2 new

Create a new instance of L<DB::Object>. Nothing much to say.

=head2 connect

Create a new instance of L<DB::Object>, but also attempts a connection to SQL server.

You can specify the following arguments:

=over 4

=item * C<database>

The database name you wish to connect to

=item * C<login>

The login used to access that database

=item * C<password>

The password that goes along

=item * C<server>

The server, that is hostname of the machine serving a SQL server.

=item * C<driver>

The driver you want to use. It needs to be of the same type than the server you want to connect to. If you are connecting to a MySQL server, you would use C<mysql>, if you would connecto to an Oracle server, you would use C<oracle>.

You need to make sure that those driver are properly installed in the system before attempting to connect.

To install the required driver, you could start with the command line:

    perl -MCPAN -e shell

which will provide you a special shell to install modules in a convenient way.

=back

=head1 METHODS

=head2 alias

Get/set alias for table fields in SELECT queries. The hash provided thus contain a list of field => alias pairs.

=head2 as_string

Return the sql query as a string.

=head2 avoid

Set the provided list of table fields to avoid when returning the query result.
The list of fields can be provided either as an array of a reference to an array.

=head2 attribute

Sets or get the value of database connection parameters.

If only one argument is provided, returns its value.
If multiple arguments in a form of pair => value are provided, it sets the corresponding database parameters.

The authorised parameters are:

=over 4

=item * C<Warn>

Can be overridden.

=item * C<Active>

Read-only.

=item * C<Kids>

Read-only.

=item * C<ActiveKids>

Read-only.

=item * C<CachedKids>

Read-only.

=item * C<InactiveDestroy>

Can be overridden.

=item * C<PrintError>

Can be overridden.

=item * C<RaiseError>

Can be overridden.

=item * C<ChopBlanks>

Can be overridden.

=item * C<LongReadLen>

Can be overridden.

=item * C<LongTruncOk>

Can be overridden.

=item * C<AutoCommit>

Can be overridden.

=item * C<Name>

Read-only.

=item * C<RowCacheSize>

Read-only.

=item * C<NUM_OF_FIELDS>

Read-only.

=item * C<NUM_OF_PARAMS>

Read-only.

=item * C<NAME>

Read-only.

=item * C<TYPE>

Read-only.

=item * C<PRECISION>

Read-only.

=item * C<SCALE>

Read-only.

=item * C<NULLABLE>

Read-only.

=item * C<CursorName>

Read-only.

=item * C<Statement>

Read-only.

=item * C<RowsInCache>

Read-only.

=back

=head2 available_drivers

Return the list of available drivers.

=head2 begin_work

Mark the beginning of a transaction.

Any arguments provided are passed along to L<DBD::mysql/begin_work>

=head2 bind

If no values to bind to the underlying query is provided, L<DB::Object/bind> simply activate the bind value feature.

If values are provided, they are allocated to the statement object and will be applied when the query will be executed.

Example:

    $dbh->bind()
    # or
    $dbh->bind->where( "something" )
    # or
    $dbh->bind->select->fetchrow_hashref()
    # and then later
    $dbh->bind( 'thingy' )->select->fetchrow_hashref()

=head2 cache

Activate caching.

    $tbl->cache->select->fetchrow_hashref();

=head2 check_driver

Check that the driver set in I<$SQL_DRIVER> in ~/etc/common.cfg is indeed available.

It does this by calling L<DB::Object/available_drivers>.

=head2 commit

Make any change to the database irreversible.

This must be used only after having called L</begin_work>

Any arguments provided are passed along to L<DBD::mysql/commit>

=head2 copy

Provided with either a reference to an hash or an hash of key => value pairs, L<DB::Object/copy> will first execute a select statement on the table object, then fetch the row of data, then replace the key-value pair in the result by the ones provided, and finally will perform an insert.

Return false if no data to copy were provided, otherwise it always returns true.

=head2 create_db

Provided with a database name and some optional parameters and this will prepare and execute the query to create the database.

Upon failure, this will return an error, and upon success, this will connect to the newly created database and return the database handler.

Possible options are:

=over 4

=item * C<charset>

The character encoding.

=item * C<collate>

Sets the C<COLLATE> attribute

=item * C<if_not_exists>

Add the condition C<IF NOT EXISTS>

=back

See L<MySQL documentation for more information|https://dev.mysql.com/doc/refman/5.7/en/creating-database.html>

=head2 create_table

The idea is to create a table with the givern parameters.

=head2 databases

Returns a list of all available databases.

=head2 data_sources

Given an optional list of options, this return the data source of the database handler.

=head2 datatype_dict

Returns an hash reference of each data type with their equivalent C<constant>, regular expression (C<re>), constant C<name> and C<type> name.

Each data type is an hash with the following properties for each type: C<constant>, C<name>, C<re>, C<type>


=head2 data_type

Given a reference to an array or an array of data type, L<DB::Object/data_type> will check their availability in the database driver.

If nothing found, it return an empty list in list context, or undef in scalar context.

If something was found, it returns a hash in list context or a reference to a hash in list context.

=head2 database

Return the name of the current database.

=head2 delete

L<DB::Object/delete> will format a delete query based on previously set parameters, such as L<DB::Object/where>.

L<DB::Object/delete> will refuse to execute a query without a where condition. To achieve this, one must prepare the delete query on his/her own by using the L<DB::Object/do> method and passing the sql query directly.

    $tbl->where( "login" => "jack" );
    $tbl->limit( 1 );
    my $rows_affected = $tbl->delete();
    # or passing the where condition directly to delete
    my( $sth ) = $tbl->delete( "login" => "jack" );

=head2 disconnect

Disconnect from database. Returns the return code.

    my $rc = $dbh->disconnect;

=head2 do

Execute a sql query directly passed with possible attributes and values to bind.

The attributes list will be used to L<DB::Object/prepare> the query and the bind values will be used when executing the query.

It returns the statement handler or the number of rows affected.

Example:

    $rc  = $dbh->do( $statement ) || die( $dbh->errstr );
    $rc  = $dbh->do( $statement, \%attr ) || die( $dbh->errstr );
    $rv  = $dbh->do( $statement, \%attr, @bind_values ) || die( $dbh->errstr );
    my( $rows_deleted ) = $dbh->do(
    q{
       DELETE FROM table WHERE status = ?
    }, undef(), 'DONE' ) || die( $dbh->errstr );

=head2 enhance

Toggle the enhance mode on/off.

When on, the functions I<from_unixtime> and I<unix_timestamp> will be used on date/time field to translate from and to unix time seamlessly.

=head2 from_unixtime

Set the list of fields that are to be treated as unix time and converted accordingly after the sql query is executed.

It returns the list of fields in list context or a reference to an array in scalar context.

=head2 format_statement

Format the sql statement.

In list context, it returns 2 strings: one comma-separated list of fields and one comma-separated list of values. In scalar context, it only returns a comma-separated string of fields.

=head2 format_update

Formats update query based on the following arguments provided:

=over 4

=item * C<data>

An array of key-value pairs to be used in the update query. This array can be provided as the prime argument as a reference to an array, an array, or as the I<data> element of a hash or a reference to a hash provided.

Why an array if eventually we build a list of key-value pair? Because the order of the fields may be important, and if the key-value pair list is provided, L<DB::Object/format_update> honors the order in which the fields are provided.

=back

L</format_update> will then iterate through each field-value pair, and perform some work:

If the field being reviewed was provided to L<DB::Object/from_unixtime>, then L</format_update> will enclose it in the function FROM_UNIXTIME() as in:

    FROM_UNIXTIME(field_name)
  
If the the given value is a reference to a scalar, it will be used as-is, ie. it will not be enclosed in quotes or anything. This is useful if you want to control which function to use around that field.

If the given value is another field or looks like a function having parenthesis, or if the value is a question mark, the value will be used as-is.

If L<DB::Object/bind> is off, the value will be escaped and the pair field='value' created.

If the field is a SET data type and the value is a number, the value will be used as-is without surrounding single quote.

If L<DB::Object/bind> is enabled, a question mark will be used as the value and the original value will be saved as value to bind upon executing the query.

Finally, otherwise the value is escaped and surrounded by single quotes.

L<DB::Object/format_update> returns a string representing the comma-separated list of fields that will be used.

=head2 get_sql_type

Provided with a SQL type, irrespective of the character case, and this will return the equivalent constant value.

Values are taken from C<DBI::SQL_*>

=head2 getdefault

Does some preparation work such as:

=over 4

=item 1

the date/time field to use the FROM_UNIXTIME and UNIX_TIMESTAMP functions

=item 2

removing from the query the fields to avoid, ie the ones set with the L<DB::Object/avoid> method.

=item 3

set the fields alias based on the information provided with the L<DB::Object/alias> method.

=item 4

if a field last_name and first_name exist, it will also create an alias I<name> based on the concatenation of the 2.

=item 5

it will set the default values provided. This is used for UPDATE queries.

=back

It returns a new L<DB::Object::Tables> object with all the data prepared within.

=head2 group

Format the group by portion of the query.

It returns an empty list in list context of undef in scalar context if no group by clause was build.
Otherwise, it returns the value of the group by clause as a string in list context and the full group by clause in scalar context.

In list context, it returns: $group_by

In scalar context, it returns: GROUP BY $group_by

=head2 having

A convenient wrapper to L<DB::Object::Mysql::Query/having>

=head2 insert

Prepares an INSERT query using the field-value pairs provided.

If a L<DB::Object::Statement> object is provided as first argument, it will considered as a SELECT query to be used in the INSERT query, as in: INSERT INTO my table SELECT FROM another_table

Otherwise, L<DB::Object/insert> will build the query based on the fields provided.

In scalar context, it returns the result of L<DB::Object/execute> and in list context, it returns the statement object.

=head2 last_insert_id

Get the id of the primary key from the last insert.

=head2 limit

Set or get the limit for the future statement.

If only one argument is provided, it is assumed to be the end limit. If 2 are provided, they wil be the start and end.

It returns a list of the start and end limit in list context, and the string of the LIMIT in scalar context, such as: LIMIT 1, 10

=head2 local

Not sure what it does. I forgot.

=head2 lock

Set a lock using a lock identifier and a timeout.
By default the timeout is 2 seconds.

If the lock failed (NULL), it returns undef(), otherwise, it returns the return value.

=head2 no_bind

When invoked, L<DB::Object/no_bind> will change any preparation made so far for caching the query with bind parameters, and instead substitute the value in lieu of the question mark placeholder.

=head2 no_cache

Disable caching of queries.

=head2 order

Prepares the ORDER BY clause and returns the value of the clause in list context or the ORDER BY clause in full in scalar context, ie. "ORDER BY $clause"

=head2 param

If only a single parameter is provided, its value is return. If a list of parameters is provided they are set accordingly using the C<SET> sql command.

Supported parameters are:

=over 4

=item SQL_AUTO_IS_NULL

=item AUTOCOMMIT

=item SQL_BIG_TABLES

=item SQL_BIG_SELECTS

=item SQL_BUFFER_RESULT

=item SQL_LOW_PRIORITY_UPDATES

=item SQL_MAX_JOIN_SIZE 

=item SQL_SAFE_MODE

=item SQL_SELECT_LIMIT

=item SQL_LOG_OFF

=item SQL_LOG_UPDATE 

=item TIMESTAMP

=item INSERT_ID

=item LAST_INSERT_ID

=back

If unsupported parameters are provided, they are considered to be private and not passed to the database handler.

It then execute the query and return undef() in case of error.

Otherwise, it returns the object used to call the method.

=head2 ping

Evals a SELECT 1 statement and returns 0 if errors occurred or the return value.

=head2 prepare

Prepares the query using the options provided. The options are the same as the one in L<DBI/prepare> method.

It returns a L<DB::Object::Statement> object upon success or undef if an error occurred. The error can then be retrieved using L<DB::Object/errstr> or L<DB::Object/error>.

=head2 prepare_cached

Same as L<DB::Object/prepare> except the query is cached.

=head2 query

It prepares and executes the given SQL query with the options provided and return undef() upon error or the statement handler upon success.

=head2 query_object

Set or gets the PostgreSQL query object (L<DB::Object::Mysql::Query>) used to process and format queries.

=head2 replace

Just like for the INSERT query, L<DB::Object::Mysql::Tables/replace> takes one optional argument representing a L<DB::Object::Statement> SELECT object or a list of field-value pairs.

If a SELECT statement is provided, it will be used to construct a query of the type of REPLACE INTO mytable SELECT FROM other_table

Otherwise the query will be REPLACE INTO mytable (fields) VALUES(values)

In scalar context, it execute the query and in list context it simply returns the statement handler.

=head2 reset

This is used to reset a prepared query to its default values. If a field is a date/time type, its default value will be set to NOW()

It execute an update with the reseted value and return the number of affected rows.

=head2 reverse

Get or set the reverse mode.

=head2 rollback

Will roll back any changes made to the database since the last transaction point marked with L</begin_work>

=head2 select

Given an optional list of fields to fetch, L<DB::Object/select> prepares a SELECT query.

If no field was provided, L<DB::Object/select> will use default value where appropriate like the NOW() for date/time fields.

L<DB::Object/select> calls upon L<DB::Object/tie>, L<DB::Object/where>, L<DB::Object/group>, L<DB::Object/order>, L<DB::Object/limit> and L<DB::Object/local> to build the query.

In scalar context, it execute the query and return it. In list context, it just returns the statement handler.

=head2 set

Issues a query to C<SET> the given SQL variable.

If any error occurred, undef will be returned and an error set, otherwise it returns true.

=head2 sort

It toggles sort mode on and consequently disable reverse mode.

=head2 stat

Issue a SHOW STATUS query and if a particular $type is provided, it will returns its value if it exists, otherwise it will return undef.

In absence of particular $type provided, it returns the hash list of values returns or a reference to the hash list in scalar context.

=head2 state

Queries the DBI state and return its value.

=head2 table

Given a table name, L<DB::Object/table> will return a L<DB::Object::Tables> object. The object is cached for re-use.

=head2 table_info

Provided with a table name and some optional parameters and this will retrieve the table information.

It returns an array reference of tables information found if no schema was provided or if I<anywhere> is true.

If a schema was provided, and the table found it returns an hash reference for that table.

Otherwise, if nothing can be found, it returns an empty array reference.

Optional parameters are:

=over 4

=item * C<anywhere>

If true, it will search anywhere.

=item * C<schema>

A database schema.

=back

=head2 table_push

Add the given table name to the stack of cached table names.

=head2 tables

Connects to the database and finds out the list of all available tables.

Returns undef or empty list in scalar or list context respectively if no table found.

Otherwise, it returns the list of table in list context or a reference of it in scalar context.

=head2 table_info

Provided with a table name and this returns all the matching table information from the MySQL system.

It returns an array reference of tables information found if no schema was provided or if C<anywhere> is true.

If a schema was provided, and the table found it returns an hash reference for that table.

Otherwise, if nothing can be found, it returns an empty array reference.

It takes the following options:

=over 4

=item * C<anywhere>

If true, this will have this method an array reference of hash reference for each match.

=item * C<database>

An optional database name to restrict the search.

=back

Information retrieved are:

=over 4

=item * C<name>

The table name

=item * C<schema>

Database schema, if any.

=item * C<type>

The object type, which may be one of: C<table>, C<view>, C<materialized view>, C<special>, C<foreign table>

=back

=head2 tables_info

Provided with a database name and this returns all the tables information.

Information retrieved from the MySQL system tables for every table found in the given database are:

=over 4

=item * C<name>

The object name

=item * C<database>

Database name.

=item * C<type>

The object type, which may be one of: C<base table>, C<view>

=back

=head2 tables_refresh

Rebuild the list of available database table.

Returns the list of table in list context or a reference of it in scalar context.

=head2 tie

If provided a hash or a hash ref, it sets the list of fields and their corresponding perl variable to bind their values to.

In list context, it returns the list of those field-variable pair, or a reference to it in scalar context.

=head2 unix_timestamp

Provided a list of fields or a reference to it, this sets the fields to be treated for seamless conversion from and to unix time.

=head2 unlock

Given a lock identifier, L<DB::Object/unlock> releases the lock previously set with L<DB::Object/lock>. It executes the underlying sql command and returns undef() if the result is NULL or the value returned otherwise.

=head2 update

Given a list of field-value pairs, L<DB::Object/update> prepares a sql update query.

It calls upon L<DB::Object/where> and L<DB::Object/limit> as previously set.

It returns undef and sets an error if it failed to prepare the update statement. In scalar context, it execute the query. In list context, it simply return the statement handler.

=head2 use

Given a database, it switch to it, but before it checks that the database exists.
If the database is different than the current one, it sets the I<multi_db> parameter, which will have the fields in the queries be prefixed by their respective database name.

It returns the database handler.

=head2 use_cache

Sets or get the I<use_cache> parameter.

=head2 use_bind

Sets or get the I<use_cache> parameter.

=head2 variables

Query the SQL variable $type

It returns a blank string if nothing was found, or the value found.

=head2 version

Returns the MySQL database server version.

This information is cached per object for efficiency.

=head2 where

Build the where clause based on the field-value hash provided.

It returns the where clause in list context or the full where clause in scalar context, ie "WHERE $clause"

=head2 _cache_this

Provided with a query, this will cache it for future re-use.

It does some check and maintenance job to ensure the cache does not get too big whenever it exceed the value of $CACHE_SIZE set in the main config file.

It returns the cached statement as an L<DB::Object::Statement> object.

=head2 _clean_statement

Given a query string or a reference to it, it cleans the statement by removing leading and trailing space before and after line breaks.

=head2 _cleanup

Removes object attributes, namely where, selected_fields, group_by, order_by, limit, alias, avoid, local, and as_string

=head2 _make_sth

Given a package name and a hashref, this build a statement object with all the necessary parameters.

It also sets the query time to the current time with the parameter I<query_time>

It returns an object of the given $package.

=head2 _reset_query

Being called using a statement handler, this reset the object by removing all the parameters set by various subroutine calls, such as L<DB::Object/where>, L<DB::Object/group>, L<DB::Object/order>, L<DB::Object/avoid>, L<DB::Object/limit>, etc.

=head2 _save_bind

This saves/cache the bin query and return the object used to call it.

=head2 _value2bind

Given a sql query and a array reference, L<DB::Object/_value2bind> parse the query and interpolate values for placeholder (?).

It returns true.

=head1 SEE ALSO

L<DB::Object>

L<DBI>, L<Apache::DBI>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
