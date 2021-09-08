# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres.pm
## Version v0.4.11
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2021/08/24
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This is the subclassable module for driver specific ones.
package DB::Object::Postgres;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object );
    use version;
    use DBI;
    # use DBD::Pg qw( :pg_types );
    eval
    {
        require DBD::Pg;
        DBD::Pg->import( ':pg_types' );
    };
    die( $@ ) if( $@ );
    use DateTime;
    use DateTime::Format::Strptime;
    use Module::Generic::DateTime;
    use Nice::Try;
    require DB::Object::Postgres::Statement;
    require DB::Object::Postgres::Tables;
    require DB::Object::Postgres::Lo;
    our( $VERSION, $DB_ERRSTR, $ERROR, $DEBUG, $CONNECT_VIA, $CACHE_QUERIES, $CACHE_SIZE );
    our( $CACHE_TABLE, $USE_BIND, $USE_CACHE, $MOD_PERL, @DBH );
    $VERSION     = 'v0.4.11';
    use Devel::Confess;
};

{
    $DB_ERRSTR     = '';
    $DEBUG         = 0;
    $CACHE_QUERIES = [];
    $CACHE_SIZE    = 10;
    # The purpose of this cache is to store table object and avoid the penalty of reloading the structure of a table for every object generated.
    # Thus CACHE_TABLE is in no way an exhaustive list of existing table, but existing table object.
    $CACHE_TABLE   = {};
    $USE_BIND      = 0;
    $USE_CACHE     = 0;
    $MOD_PERL      = 0;
    @DBH           = ();
    if( $INC{ 'Apache/DBI.pm' } && 
        substr( $ENV{ 'GATEWAY_INTERFACE' }|| '', 0, 8 ) eq 'CGI-Perl' )
    {
        $CONNECT_VIA = "Apache::DBI::connect";
        $MOD_PERL++;
    }
}

# sub new is inherited from DB::Object
sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ );
    $self->{ 'driver' } = 'Pg';
    return( $self );
}

# Get/set alias
# sub alias

# sub as_string

# sub avoid

sub attribute($;$@)
{
    my $self = shift( @_ );
    # $h->{AttributeName} = ...;    # set/write
    # ... = $h->{AttributeName};    # get/read
    # 1 means that the attribute may be modified
    # 0 mneas that the attribute may only be read
    my $name  = shift( @_ ) if( @_ == 1 );
    my %arg   = ( @_ );
    my %attr =
    (
        ActiveKids                     => 0,
        AutoCommit                     => 1,
        AutoInactiveDestroy            => 1,
        CachedKids                     => 0,
        ChildHandles                   => 0,
        ChopBlanks                     => 1,
        CursorName                     => 0,
        Driver                         => 0,
        ErrCount                       => 1,
        Executed                       => 0,
        FetchHashKeyName               => 1,
        HandleError                    => 1,
        HandleSetErr                   => 1,
        InactiveDestroy                => 1,
        Kids                           => 0,
        NAME                           => 0,
        NULLABLE                       => 0,
        NUM_OF_FIELDS                  => 0,
        NUM_OF_PARAMS                  => 0,
        # Current database name
        Name                           => 0,
        PRECISION                      => 0,
        PrintError                     => 1,
        PrintWarn                      => 1,
        Profile                        => 1,
        RaiseError                     => 1,
        # Specifies if the current database connection should be in read-only mode or not.
        ReadOnly                       => 1,
        RowCacheSize                   => 0,
        RowsInCache                    => 0,
        SCALE                          => 0,
        ShowErrorStatement             => 1,
        Statement                      => 0,
        TYPE                           => 0,
        Taint                          => 1,
        TaintIn                        => 1,
        TaintOut                       => 1,
        TraceLevel                     => 1,
        Type                           => 1,
        Username                       => 0,
        Warn                           => 1,
        pg_INV_READ                    => 0,
        pg_INV_WRITE                   => 0,
        pg_async_status                => 0,
        # If true, boolean values will be returned as the characters 't' and 'f' instead of '1' and '0'.
        pg_bool_tf                     => 1,
        pg_db                          => 0,
        pg_default_port                => 0,
        pg_enable_utf8                 => 1,
        # Valid entries are 0, 1 and 2
        pg_errorlevel                  => 1,
        pg_expand_array                => 1,
        pg_host                        => 0,
        pg_lib_version                 => 0,
        pg_options                     => 0,
        pg_pass                        => 0,
        pg_pid                         => 0,
        # When true, question marks inside of statements are not treated as placeholders, e.g. geometric operators
        pg_placeholder_dollaronly      => 1,
        # When true, colons inside of statements are not treated as placeholders
        pg_placeholder_nocolons        => 1,
        pg_port                        => 0,
        pg_prepare_now                 => 1,
        pg_protocol                    => 0,
        # Indicates if DBD::Pg should attempt to use server-side prepared statements. On by default
        pg_server_prepare              => 1,
        pg_server_version              => 0,
        pg_socket                      => 0,
        pg_standard_conforming_strings => 0,
        pg_switch_prepared             => 1,
        pg_user                        => 0,
        # Not used
        # LongReadLen => 1,
        # LongTruncOk => 1,
        # CompatMode => 1,
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

# sub available_drivers(@)

sub begin_work($;$@)
{
    my $self = shift( @_ );
    $self->{transaction} = 1;
    return( $self->{dbh}->begin_work( @_ ) );
}

# This method is common to DB::Object and DB::Object::Statement
# sub bind

# sub cache

# sub check_driver(@;$@)

sub commit($;$@)
{
    my $self = shift( @_ );
    $self->{transaction} = 0;
    return( $self->{dbh}->commit( @_ ) );
}

# Inherited by DB::Object, however, DB::Object::connect() will call our subroutine 
# _dbi_connect which format in a particular way the dsn.
sub connect
{
    my $that   = shift( @_ );
    my $param = $that->_connection_params2hash( @_ ) || return;
    $param->{driver} = 'Pg';
    return( $that->SUPER::connect( $param ) );
}

# sub copy

sub create_db
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No database name to create was provided." ) );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[0] ) );
    my $params = [];
    # https://www.postgresql.org/docs/9.5/sql-createdatabase.html
    push( @$params, sprintf( 'OWNER=%s', $opts->{owner} ) ) if( $opts->{owner} );
    push( @$params, sprintf( 'TEMPLATE=%s', $opts->{template} ) ) if( $opts->{template} );
    push( @$params, sprintf( 'ENCODING=%s', $opts->{encoding} ) ) if( $opts->{encoding} );
    push( @$params, sprintf( 'LC_COLLATE=%s', $opts->{lc_collate} ) ) if( $opts->{lc_collate} );
    push( @$params, sprintf( 'LC_CTYPE=%s', $opts->{lc_ctype} ) ) if( $opts->{lc_ctype} );
    push( @$params, sprintf( 'TABLESPACE=%s', $opts->{tablespace} ) ) if( $opts->{tablespace} );
    push( @$params, sprintf( 'ALLOW_CONNECTIONS=%s', $opts->{allowcon} ? 'true' : 'false' ) ) if( length( $opts->{allowcon} ) );
    push( @$params, sprintf( 'CONNECTION LIMIT=%s', $opts->{connlimit} ) ) if( length( $opts->{connlimit} ) );
    push( @$params, sprintf( 'IS_TEMPLATE=%s', $opts->{istemplate} ? 'true' : 'false' ) ) if( length( $opts->{istemplate} ) );
    my $sql = "CREATE DATABASE $name";
    if( scalar( @$params ) )
    {
        $sql .= ' WITH ' . join( ' ', @$params );
    }
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my( $sth, $rc );
    try
    {
        $sth = $dbh->prepare( $sql ) || return( $self->error( "An error occured while prepareing sql query to create database: ", $dbh->errstr ) );
        $rc = $sth->execute || return( $self->error( "An error occured while executing sql query to create database: ", $sth->errstr ) );
        $sth->finish;
    }
    catch( $e )
    {
        $sth->finish;
        return( $self->error( "An unexpected error occurred while trying to execute the sql query to create database: ", $sth->error, "\n$sql" ) );
    }
    my $ref = {};
    my @keys = qw( host port login passwd schema opt debug );
    @$ref{ @keys } = @$self{ @keys };
    $ref->{database} = $name;
    $dbh = $self->connect( $ref ) || return( $self->error( "I could create the database \"$name\" but oddly enough, I could not connect to it with user \"$ref->{login}\" on host \"$ref->{host}\" with port \"$ref->{port}\"." ) );
    return( $dbh );
}

sub create_table
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No table name to create was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Table \"$name\" already exists in the database." ) ) if( $self->table_exists( $name ) );
    my $schema = $self->schema;
    my $sql = $opts->{sql} || return( $self->error( "No sql query was provided to create table \"$name\"." ) );
    # The schema is missing
    if( $schema )
    {
        $sql =~ s/\b(CREATE[[:blank:]]+(?:.*?)\bTABLE(?:[[:blank:]]+IF[[:blank:]]+NOT[[:blank:]]+EXISTS)?)[[:blank:]]+$name\b/$1 ${schema}.${name}/si;
    }
    my $rv = $self->do( $sql ) || return( $self->error( "An error occured while executing sql query to create table \"$name\": ", $self->errstr, "\nOriginal query was: $sql" ) );
    return( $rv );
}

# sub create_table($;%)

# See DB::Object
# sub data_sources($;\%)

# sub data_type

# sub database

sub databases
{
    my $self = shift( @_ );
    # return( $self->error( "Not connected to PostgreSQL server yet. Issue $dbh->connect first." ) ) if( !$self->{ 'dbh' } );
    my $dbh;
    # If there is no connection yet, then create one using the postgres login.
    # There should not be a live user and database just to check what databases there are.
    if( !$self->{dbh} )
    {
        try
        {
            $dbh = $self->connect || return;
        }
        catch( $e )
        {
            $self->message( 3, "An error occurred while trying to connect to get the list of available databases: $e" );
            return;
        }
    }
    else
    {
        $dbh = $self;
    }
    my $temp = $dbh->do( "SELECT datname FROM pg_database" )->fetchall_arrayref;
    my @dbases = map( $_->[0], @$temp );
    return( @dbases );
}

# delete() is inherited from DB::Object
# sub delete

# sub disconnect($)

# sub do($;$@)

# sub enhance

# See DB::Object
# sub err(@)
# Meaning of the error code
# 0  Empty query string
# 1  A command that returns no data successfully completed.
# 2  A command that returns data successfully completed.
# 3  A COPY OUT command is still in progress.
# 4  A COPY IN command is still in progress.
# 5  A bad response was received from the backend.
# 6  A nonfatal error occurred (a notice or warning message)
# 7  A fatal error was returned: the last query failed.

# See DB::Object
# sub errno

# See DB::Object
# sub errmesg

# See DB::Object
# sub errstr(@)
# Affected by the pg_errorlevel setting

# sub fatal

# sub from_unixtime

# Inherited from DB::Object
# sub format_statement($;\%\%@)

# sub format_update($;%)

sub func
{
    my $self      = shift( @_ );
    my $table     = shift( @_ );
    # e.g. table_attributes to get the detail information on table columns
    my $func_name = shift( @_ );
    # Returns:
    # NAME        attribute name
    # TYPE        attribute type
    # SIZE        attribute size (-1 for variable size)
    # NULLABLE    flag nullable
    # DEFAULT     default value
    # CONSTRAINT  constraint
    # PRIMARY_KEY flag is_primary_key
    # REMARKS     attribute description
    return( $self->{ 'dbh' }->func( $table, $func_name ) );
}

# See DB::Object
# sub getdefault($;%)

# sub group

sub get_sql_type
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error( "No sql type was provided to get its constant." ) );
    $self->message( 3, "Trying constant for '$type' using 'DBD::Pg::PG_\U${type}\E'" );
    my $const = $self->{dbh}->can( "DBD::Pg::PG_\U${type}\E" );
    return( '' ) if( !defined( $const ) );
    return( $const->() );
}

# Specific to Postgres
sub having
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->having( @_ ) );
}

# See DB::Object
# sub insert

sub large_object
{
    # Parameter is a bitmask mode
    return( DB::Object::Postgres::Lo->new( $self->{ 'dbh' } ) );
}

# Must be superseded, or better yet, the one in DB::Object should probably be changed to ours
sub last_insert_id
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || $self->{ 'table' };
    return( $self->{ 'dbh' }->last_insert_id( undef, undef, $table, undef ) );
}

# http://www.postgresql.org/docs/9.3/interactive/queries-limit.html
# See DB::Object::Postgres::Query
# sub limit

# sub local

# http://www.postgresql.org/docs/current/static/sql-lock.html
sub lock
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || return( $self->error( "You must provide a table name to lock onto." ) );
    # ACCESS SHARE | ROW SHARE | ROW EXCLUSIVE | SHARE UPDATE EXCLUSIVE | 
    # SHARE | SHARE ROW EXCLUSIVE | EXCLUSIVE | ACCESS EXCLUSIVE
    my $mode  = shift( @_ ) || undef();
    my $nowait= shift( @_ );
    my $query = "LOCK TABLE $table";
    $query   .= " IN $mode MODE" if( defined( $mode ) );
    $query   .= " NOWAIT" if( $nowait );
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my $sth = $dbh->prepare( $query ) ||
    return( $self->error( "Error while preparing query to get lock on table '$table': ", $dbh->errstr() ) );
    $sth->execute() ||
    return( $self->error( "Error while executing query to get lock on table '$table': ", $sth->errstr() ) );
    $sth->finish();
    # We do not really need to track that information.
    # $self->{ '_locks' } ||= [];
    # push( @{ $self->{ '_locks' } }, $table ) if( $res && $res ne 'NULL' );
    return( $res eq 'NULL' ? undef() : $res );
}

sub make_schema
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{ 'database' };
    my $dbh;
    if( $self->{ 'dbh' } )
    {
        $dbh = $self;
    }
    else
    {
        $dbh = $self->connect( { 'login' => 'postgres', 'database' => $db } ) || return( $self->error( "Cannot connect to Postgres database $db: " . $self->error ) );
    }
    my $tables = $dbh->tables;
    return( $self->error( "There is no table in database $db." ) ) if( !@$tables );
    my @schema_tables = ();
    my $max_field_size = <<SQL;
SELECT MAX(LENGTH(a.attname)) AS "max_length"
FROM pg_class c, pg_attribute a, pg_authid o
WHERE c.relkind IN ('r', 'v', 'm', 'f') AND a.attrelid=c.oid AND c.relowner=o.oid AND o.rolname != 'postgres'
SQL
    my $inherited_fields = <<SQL;
SELECT c.relname AS table, a.attname AS field 
FROM pg_class c
JOIN pg_inherits i ON c.oid = i.inhrelid
JOIN pg_attribute a ON i.inhparent = a.attrelid
WHERE attnum > 0
SQL
    my $table_info = <<SQL;
SELECT c.oid, c.relchecks, c.relkind, c.relhasindex, c.relhasrules, c.relhastriggers, c.relhasoids, '', c.reltablespace, CASE WHEN c.reloftype = 0 THEN '' ELSE c.reloftype::pg_catalog.regtype::pg_catalog.text END, c.relpersistence                                                                                      FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_class tc ON (c.reltoastrelid = tc.oid)
WHERE c.relname ~ '^(%s)\$'
SQL
    my $field_info = <<SQL;
SELECT a.attname,
  pg_catalog.format_type(a.atttypid, a.atttypmod),
  (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
   FROM pg_catalog.pg_attrdef d
   WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef),
  a.attnotnull, a.attnum,
  (SELECT c.collname FROM pg_catalog.pg_collation c, pg_catalog.pg_type t
   WHERE c.oid = a.attcollation AND t.oid = a.atttypid AND a.attcollation <> t.typcollation) AS attcollation,
  NULL AS indexdef,
  NULL AS attfdwoptions
FROM pg_catalog.pg_attribute a
WHERE a.attrelid = ? AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum
SQL
    my $get_constraints = <<SQL;
SELECT c2.relname, i.indisprimary, i.indisunique, i.indisclustered, i.indisvalid, pg_catalog.pg_get_indexdef(i.indexrelid, 0, true),
  pg_catalog.pg_get_constraintdef(con.oid, true), contype, condeferrable, condeferred, c2.reltablespace
FROM pg_catalog.pg_class c, pg_catalog.pg_class c2, pg_catalog.pg_index i
  LEFT JOIN pg_catalog.pg_constraint con ON (conrelid = i.indrelid AND conindid = i.indexrelid AND contype IN ('p','u','x'))
WHERE c.oid = ? AND c.oid = i.indrelid AND i.indexrelid = c2.oid
ORDER BY i.indisprimary DESC, i.indisunique DESC, c2.relname
SQL
    my $get_check_constraint = <<SQL;
SELECT r.conname, pg_catalog.pg_get_constraintdef(r.oid, true)
FROM pg_catalog.pg_constraint r
WHERE r.conrelid = ? AND r.contype = 'c'
ORDER BY 1
SQL
    my $get_fkey_constraint = <<SQL;
SELECT conname,
  pg_catalog.pg_get_constraintdef(r.oid, true) as condef
FROM pg_catalog.pg_constraint r
WHERE r.conrelid = ? AND r.contype = 'f' ORDER BY 1
SQL
    my $inheritance = "SELECT c.oid::pg_catalog.regclass FROM pg_catalog.pg_class c, pg_catalog.pg_inherits i WHERE c.oid=i.inhparent AND i.inhrelid = ? ORDER BY inhseqno";
    my $get_tbl_comment = "SELECT description FROM pg_description WHERE (SELECT relname FROM pg_class WHERE oid=objoid) = ? and objsubid = 0";
    my $get_field_comment = "SELECT d.description, a.attname FROM pg_description d, pg_attribute a WHERE (SELECT relname FROM pg_class WHERE oid=d.objoid) = ? AND a.attnum=d.objsubid AND a.attrelid=d.objoid AND d.objsubid > 0";
    
    # Get the max size of the fields to properly format the schema
    my $sth = $dbh->{dbh}->prepare_cached( $max_field_size ) || return( $self->error( $dbh->{dbh}->errstr ) );
    $sth->execute() || return( $self->error( $sth->errstr ) );
    my $fsize = $sth->fetchrow;
    $sth->finish;
    
    # Get the list of all inherited fields per table, so we can exclude them in the schema we produce.
    $sth = $dbh->{dbh}->prepare_cached( $inherited_fields ) || return( $self->error( $dbh->{dbh}->errstr ) );
    $sth->execute() || return( $self->error( $sth->errstr ) );
    my $all = $sth->fetchall_arrayref( {} );
    my $inherited = {};
    foreach my $h ( @$all )
    {
        $inherited->{ $h->{ 'table' } } = [] if( !exists( $inherited->{ $h->{ 'table' } } ) );
        push( @{$inherited->{ $h->{ 'table' } }}, $h->{ 'field' } );
    }
    $sth->finish;
    
    foreach my $t ( @$tables )
    {
        my @table_def = ( "CREATE TABLE $t (" );
        # Get table overall information
        $dbh->bind( 0 );
        $sth = $dbh->{dbh}->prepare_cached( sprintf( $table_info, $t ) ) || return( $self->error( $dbh->{dbh}->errstr ) );
        $sth->execute() || return( $self->error( $sth->errstr ) );
        my $tbl_info = $sth->fetchrow_hashref();
        $sth->finish;
        $dbh->bind( 1 );
        
        # Get field info.
        $sth = $dbh->{Dbh}->prepare_cached( $field_info ) || return( $self->error( $dbh->{dbh}->errstr ) );
        $sth->execute( $tbl_info->{ 'oid' } ) || return( $self->error( $sth->errstr ) );
        my $rows = $sth->fetchall_arrayref( {} );
        foreach my $r ( @$rows )
        {
            next if( exists( $inherited->{ $t } ) && grep( /^$r->{ 'attname' }$/, @{$inherited->{ $t }} ) );
            my @col_def = ( sprintf( "\t%-${fsize}s %s", $r->{ 'attname' }, uc( $r->{ 'format_type' } ) ) );
            push( @col_def, 'NOT NULL' ) if( $r->{ 'attnotnull' } );
            if( $r->{ 'format_type' } =~ /^(integer|int|boolean|decimal)$/i )
            {
                push( @col_def, sprintf( 'DEFAULT %s', $r->{ 'substring' } ) ) if( $r->{ 'substring' } );
            }
            else
            {
                push( @col_def, sprintf( "DEFAULT '%s'", $r->{ 'substring' } ) ) if( $r->{ 'substring' } );
            }
            push( @table_def, join( " ", @col_def ) );
        }
        $sth->finish;
        my @constraints = ();
        my @index = ();
        # Get primary key and unique index constraints
        $sth = $dbh->{dbh}->prepare_cached( $get_constraints ) || return( $self->error( $dbh->{dbh}->errstr ) );
        $sth->execute( $tbl_info->{ 'oid' } ) || return( $self->error( $sth->errstr ) );
        $rows = $sth->fetchall_arrayref( {} );
        foreach my $r ( @$rows )
        {
            if( $r->{ 'indisprimary' } || $r->{ 'indisunique' } )
            {
                push( @constraints, sprintf( "\tCONSTRAINT %s %s", @$r{ qw( relname pg_get_constraintdef ) } ) );
            }
            else
            {
                push( @index, sprintf( 'CREATE INDEX %s;', $r->{ 'pg_get_indexdef' } ) );
            }
        }
        $sth->finish;
        # Get CHECK constraints
        $sth = $dbh->{dbh}->prepare_cached( $get_check_constraint ) || return( $self->error( $dbh->{dbh}->errstr ) );
        $sth->execute( $tbl_info->{ 'oid' } ) || return( $self->error( $sth->errstr ) );
        $rows = $sth->fetchall_arrayref( {} );
        foreach my $r ( @$rows )
        {
            push( @constraints, sprintf( "\tCONSTRAINT %s %s", @$r{ qw( conname pg_get_constraintdef ) } ) );
        }
        $sth->finish;
        # Get foreign key constraints
        $sth = $dbh->{dbh}->prepare_cached( $get_fkey_constraint )  || return( $self->error( $dbh->{dbh}->errstr ) );
        $sth->execute( $tbl_info->{ 'oid' } ) || return( $self->error( $sth->errstr ) );
        $rows = $sth->fetchall_arrayref( {} );
        foreach my $r ( @$rows )
        {
            push( @constraints, sprintf( "\tCONSTRAINT %s %s", @$r{ qw( conname condef ) } ) );
        }
        $sth->finish;
        push( @table_def, @constraints );
        
        # Get table inheritance
        $sth = $dbh->{dbh}->prepare_cached( $inheritance )  || return( $self->error( $dbh->{dbh}->errstr ) );
        $sth->execute( $tbl_info->{ 'oid' } ) || return( $self->error( $sth->errstr ) );
        $rows = $sth->fetchall_arrayref( {} );
        my @inherit = map{ $_->{ 'oid' } } @$rows;
        $sth->finish;
        
        # Add a comma at the end of each line now we know how many there are.
        for( my $i = 0; $i < $#table_def; $i++ )
        {
            $table_def[ $i ] .= ",";
        }
        
        if( @inherit )
        {
            push( @table_def, sprintf( ') INHERITS (%s);', join( ", ", @inherit ) ) );
        }
        else
        {
            push( @table_def, ');' );
        }
        
        # Put here the table indexes
        push( @table_def, @index );
        
        # Get comments on the table itself, if any
        $sth = $dbh->{dbh}->prepare_cached( $get_tbl_comment ) || return( $self->error( $sth->{dbh}->errstr ) );
        $sth->execute( $t ) || return( $self->error( $sth->errstr ) );
        my $ref = $sth->fetchrow_hashref();
        $sth->finish;
        push( @table_def, sprintf( "COMMENT ON TABLE %s IS '%s';", $t, $ref->{ 'description' } ) ) if( $ref->{ 'description' } );
        
        # Get comments for each field
        $sth = $dbh->{dbh}->prepare_cached( $get_field_comment ) || return( $self->error( $sth->{dbh}->errstr ) );
        $sth->execute( $t ) || return( $self->error( $sth->errstr ) );
        $rows = $sth->fetchall_arrayref( {} );
        $sth->finish;
        foreach my $r ( @$rows )
        {
            push( @table_def, sprintf( "COMMENT ON COLUMN %s.%s IS '%s';", $t, @$r{ qw( attname description ) } ) );
        }
        push( @schema_tables, join( "\n", @table_def ) );        
    }
    return( wantarray() ? @schema_tables : join( "\n\n", @schema_tables ) );
}

# sub no_bind

# sub no_cache

# sub order

# See DB::Object
# sub param

sub pg_ping(@)
{
    return( shift->{ 'dbh' }->pg_ping );
}

# See DB::Object
# sub ping(@)

# See DB::Object
# sub prepare($;$)

# See DB::Object
# sub prepare_cached

# sub quote will be automatically loaded via AUTOLOADER

# sub query($$)

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::Postgres::Query', @_ ) ); }

sub release
{
    return( shift->{dbh}->pg_release( @_ ) );
}

sub replace
{
    return( shift->error( "Replace queries are not supported in PostgreSQL" ) );
}

# sub reset

# sub reverse

# sub rollback will be automatically loaded via AUTOLOADER

# Specific to Postgres
sub returning
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->returning( @_ ) );
}

sub rollback
{
    return( shift->{dbh}->rollback() );
}

sub rollback_to(@)
{
    return( shift->{dbh}->pg_rollback_to( @_ ) );
}

sub savepoint(@)
{
    return( shift->{dbh}->pg_savepoint( @_ ) );
}

sub schema { return( shift->_set_get_scalar( 'schema', @_ ) ); }

sub search_path
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = @_ == 1 
            ? $self->_is_array( $_[0] ) 
                ? shift( @_ ) 
                : [ @_ ] 
            : [ @_ ];
        my $arg = sprintf( '"%s"', join( '", "', @$val ) );
        my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
        my $sth = $dbh->prepare_cached( "SET search_path = $arg" ) || return( $self->error( "Unable to prepare sql query to set search path: ", $dbh->errstr() ) );
        my $rc = $sth->execute() || return( $self->error( "Unable to execute sql query to set search path: ", $self->errstr() ) );
        $sth->finish;
        return( $rc );
    }
    else
    {
        my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
        my $sth = $dbh->prepare_cached( "SHOW search_path" ) || return( $self->error( "Unable to prepare sql query to get search path: ", $dbh->errstr() ) );
        my $rc = $sth->execute() || return( $self->error( "Unable to execute sql query to set search path: ", $self->errstr() ) );
        my $val = $sth->fetchrow;
        $sth->finish;
        my $arr = $self->new_array( [ split( /\,[[:blank:]]*/, $val ) ] );
        # Removing surrounding quotes
        for( my $i = 0; $i < scalar( @$arr ); $i++ )
        {
            $arr->[$i] =~ s/^\"|\"$//g;
        }
        return( $arr );
    }
}

# See DB::Object; _query_component is superseded and this makes the select customised to Posgres needs
# sub select

# See DB::Object
# sub set

# See DB::Object
# sub sort

# Was previously getfd()
sub socket
{
    return( shift->{dbh}->{pg_socket} );
}

# See DB::Object
# sub stat

# See DB::Object
# sub state(@)

# See DB::Object
# sub table

# See DB::Object
sub table_exists
{
    my $self = shift( @_ );
    my $table = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $schema = $self->schema || $opts->{schema} || '';
    my $cache_tables = $self->cache_tables;
    my $tables_in_cache = $cache_tables->get({
        host => $self->host,
        driver => $self->driver,
        port => $self->port,
        database => $self->database,
    });
    foreach my $this ( @$tables_in_cache )
    {
        if( $this->{name} eq $table && 
            (
                ( $schema && $this->{schema} eq $schema ) ||
                ( !$schema || $opts->{anywhere} ) 
            ) )
        {
            return(1);
        }
    }
    # We did not find it, so let's try by checking directly the database
    my $def = $self->table_info( $table ) || return;
    return(1) if( scalar( @$def ) );
    return(0);
}

sub table_info
{
    my $self = shift( @_ );
    my $table = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    $self->message( 3, "Getting table/view information for '$table'." );
    my $opts = $self->_get_args_as_hash( @_ );
    my $schema = $self->schema || $opts->{schema} || '';
    my $sql = <<'EOT';
SELECT
     n.nspname AS "schema"
    ,c.relname AS "name"
    ,CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'table' END AS "type"
    ,pg_catalog.pg_get_userbyid(c.relowner) AS "owner"
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = ANY(regexp_split_to_array((SELECT REPLACE(setting,'"$user"', (SELECT CURRENT_USER)) FROM pg_catalog.pg_settings WHERE name = 'search_path'), '\,\s*')) AND c.relname = ?
EOT
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my $sth = $dbh->prepare_cached( $sql ) || return( $self->error( "An error occured while preparing query to check if table \"$table\" exists in our database: ", $dbh->errstr ) );
    $sth->execute( $table ) || return( $self->error( "An error occured while executing query to check if table \"$table\" exists in our database: ", $sth->errstr ) );
    my $all = $sth->fetchall_arrayref( {} );
    $sth->finish;
    return( [] ) if( !scalar( @$all ) );
    return( $all ) if( !$schema || $opts->{anywhere} );
    foreach my $ref ( @$all )
    {
        return( $ref ) if( $ref->{schema} eq $schema );
    }
    return( [] );
}

# See DB::Object
# sub table_push

# See DB::Object
# sub tables

sub tables_info
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{database};
    my @tables = ();
    # Parameters are: ?, schema, table, and type
    # my $sth  =  $self->{ 'dbh' }->table_info( undef, undef, $table, "TABLE,VIEW" );
    # The original query was fetched by connecting to Postgres with psql -E and executing the command \z
    # This revised query will fetch only tables, views, materialised view and foreign tables, but will avoid the mysterious view called sequence_setvals
#     my $query = <<SQL;
# SELECT n.nspname as "schema",
#   c.relname as "name"
# FROM pg_catalog.pg_class c
#      LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
# WHERE c.relkind IN ('r', 'v', 'm', 'f')
#   AND n.nspname !~ '^pg_' AND pg_catalog.pg_table_is_visible(c.oid) AND c.relname != 'sequence_setvals'
# ORDER BY c.oid
# SQL
# AND n.nspname OPERATOR(pg_catalog.~) '^((auth|public))$'
    my $query = <<'EOT';
SELECT
     n.nspname as "schema"
    ,c.relname as "name"
    ,CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'table' END as "type"
    ,pg_catalog.pg_get_userbyid(c.relowner) as "owner"
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','p','s','v','m','f','')
      AND n.nspname !~ '^(pg_|information_schema$)' 
      AND c.relname != 'sequence_setvals'
ORDER BY 1,2
EOT
    my $sth = $self->{dbh}->prepare_cached( $query ) || return( $self->error( sprintf( "Error while preparing query $query: %s", $self->{dbh}->errstr ) ) );
    $sth->execute() || return( $self->error( sprintf( "Error while executing query $query: %s", $sth->errstr ) ) );
    my $all = $sth->fetchall_arrayref( {} );
    return( $all );
}

# See DB::Object
# sub tables_refresh

# See DB::Object
# sub tie

sub trace($;@)
{
    my $self = shift( @_ );
    # Value is a numeric level; see parse_trace_flag.
    return( $self->error( "Trace can only be used on active connection. Use connect first." ) ) if( !$self->{dbh} );
    if( @_ )
    {
        # my( $opt, $filename ) = @_;
        $self->{dbh}->trace( @_ );
    }
    return( $self->{dbh}->trace );
}

sub trace_msg(@)
{
    my $self = shift( @_ );
    return( $self->error( "Trace can only be used on active connection. Use connect first." ) ) if( !$self->{dbh} );
    # $dbh->trace_msg( $message_text, $min_level );
    return( $self->{dbh}->trace_msg( @_ ) );
}

# sub unix_timestamp

sub unlock
{
    shift->error( "unlock() does not work with Postgres." );
}

# See DB::Object
# sub update

# See DB::Object
# sub use

# See DB::Object
# sub use_cache

# See DB::Object
# sub use_bind

sub variables
{
    return( shift->error( "variables is currently unsupported in Postgres" ) );
}

# See DB::Object
# sub where

# https://www.postgresql.org/docs/10/sql-show.html
# show something exists since at lease from 7.1
sub version
{
    my $self  = shift( @_ );
    # If we already have the information, let's use our cache instead of making a query
    return( $self->{_db_version} ) if( length( $self->{_db_version} ) );
    # e.g. 10.4
    my $sql = 'SHOW server_version';
    my $sth = $self->do( $sql ) || return( $self->error( "Unable to issue the sql statement '$sql' to get the server version: ", $self->errstr ) );
    my $ver = $sth->fetchrow;
    $sth->finish;
    # e.g.:
    # 12.1 (Ubuntu 12.1-1.pgdg16.04+1)
    # 10.4
    $ver =~ s/^(\d+(?:\.\S+)?).*?$/$1/;
    # We cache it
    $self->{_db_version} = version->parse( $ver );
    return( $ver );
}

sub _check_connect_param
{
    my $self  = shift( @_ );
    my $param = $self->SUPER::_check_connect_param( @_ );
    # This is also what the psql command line tool does
    $param->{login} = ( getpwuid( $> ) )[0] if( !$param->{login} );
    $param->{database} = 'postgres' if( !$param->{database} );
    # By default
    $param->{port} = 5432 if( !length( $param->{port} ) );
    $self->message( 3, "Returning parameters: ", sub{ $self->dump( $param ) } );
    return( $param );
}

# Called from connect once all check was done to see if there are default to set
sub _check_default_option
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Provided option is not a hash reference." ) ) if( !$self->_is_hash( $opts ) );
    $opts->{client_encoding} = 'utf8' if( !CORE::exists( $opts->{client_encoding} ) );
    # Enabled but with auto-guess
    $opts->{pg_enable_utf8} = -1 if( !CORE::exists( $opts->{pg_enable_utf8} ) && ( $opts->{client_encoding} eq 'utf8' || $opts->{client_encoding} eq 'utf-8' ) );
    return( $opts );
}

# Called by _check_connect_param
sub _connection_options
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    my @pg_params = grep( /^pg_/, keys( %$param ) );
    my $opt = $self->SUPER::_connection_options( $param );
    $self->message( 3, "Inherited options are: ", sub{ $self->dump( $opt ) } );
    @$opt{ @pg_params } = @$param{ @pg_params };
    return( $opt );
}

# Called by _check_connect_param
sub _connection_parameters
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    my $core = [qw( db login passwd host port driver database schema server opt uri debug )];
    my @pg_params = grep( /^pg_/, keys( %$param ) );
    # See DBD::mysql for the list of valid parameters
    # E.g.: mysql_client_found_rows, mysql_compression mysql_connect_timeout mysql_write_timeout mysql_read_timeout mysql_init_command mysql_skip_secure_auth mysql_read_default_file mysql_read_default_group mysql_socket mysql_ssl mysql_ssl_client_key mysql_ssl_client_cert mysql_ssl_ca_file mysql_ssl_ca_path mysql_ssl_cipher mysql_local_infile mysql_multi_statements mysql_server_prepare mysql_server_prepare_disable_fallback mysql_embedded_options mysql_embedded_groups mysql_conn_attrs 
    push( @$core, @pg_params );
    return( $core );
}

sub _convert_datetime2object
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $sth = $opts->{statement} || return( $self->error( "No statement handler was provided to convert data from json to perl." ) );
    # my $data = $opts->{data} || return( $self->error( "No data was provided to convert from json to perl." ) );
    return( $opts->{data} ) if( !CORE::length( $opts->{data} ) );
    my $data = $opts->{data};
    my $names = $sth->FETCH('NAME');
    my $types = $sth->FETCH('pg_type');
    # $self->messagef( 3, "Found %d fields returned.", scalar( @$names ) );
    # $self->message( 3, "PG_JSON is: '", PG_JSON, "' and PG_JSONB is: '", PG_JSONB, "'." );
    my $pg_types = $sth->{pg_type};
    # $self->message( 3, "pg_type has following information: ", sub{ $self->printer( $pg_types ) } );
    my $mode = ref( $data );
    local $convert = sub
    {
        my $str = shift( @_ ) || return;
        if( $str =~ /^(?<year>\d{4})-(?<month>\d{1,2})-(?<day>\d{1,2})(?:[[:blank:]]+(?<hour>\d{1,2})\:(?<minute>\d{1,2})\:(?<second>\d{1,2}))?/ )
        {
            my $hash =
            {
            year => $+{year},
            month => $+{month},
            day => $+{day},
            };
            for( qw( hour minute second ) )
            {
                $hash->{ $_ } = int( $+{ $_ } ) if( defined( $+{ $_ } ) );
            }
            $hash->{time_zone} = 'local';

            try
            {
                my $dt = DateTime->new( %$hash );
                my $fmt = DateTime::Format::Strptime->new(
                    pattern => '%Y-%m-%d %H:%M:%S',
                    locale => 'en_GB',
                    time_zone => 'local',
                );
                $dt->set_formatter( $fmt );
                # To enable extra features
                return( Module::Generic::DateTime->new( $dt ) );
            }
            catch( $e )
            {
                $self->error( "Error converting the date or timestamp \"", $str, "\" to a datetime object: $e" );
            }
        }
        else
        {
            return( $str );
        }
    };
    for( my $i = 0; $i < scalar( @$names ); $i++ )
    {
        # $self->messagef( 3, "Checking field '%s' with type '%s'.", $names->[$i], $types->[$i] );
        if( $types->[$i] eq PG_DATE || $types->[$i] eq PG_TIMESTAMP || $types->[$i] eq 'date' || $types->[$i] eq 'timestamp' )
        {
            $self->messagef( 3, "Found a date(time) field '%s' of type '%s'.", $names->[$i], $types->[$i] );
            if( $mode eq 'ARRAY' )
            {
                for( my $j = 0; $j < scalar( @$data ); $j++ )
                {
                    next if( !$data->[ $j ]->{ $names->[ $i ] } );
                    $data->[ $j ]->{ $names->[ $i ] } = $convert->( $data->[ $j ]->{ $names->[ $i ] } );
                }
            }
            elsif( $mode eq 'HASH' )
            {
                next if( !$data->{ $names->[ $i ] } );
                $data->{ $names->[ $i ] } = $convert->( $data->{ $names->[ $i ] } );
            }
        }
    }
    return( $data );
}

sub _convert_json2hash
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
#     $self->debug( 3 );
#     my( $pack, $file, $line ) = caller( 1 );
#     my $sub = ( caller( 2 ) )[3];
#     $self->message( 3, "Called from package '$pack' in file '$file' at line '$line' within sub '$sub'." );
    # $data can be either hash pr array
    my $sth = $opts->{statement} || return( $self->error( "No statement handler was provided to convert data from json to perl." ) );
    # my $data = $opts->{data} || return( $self->error( "No data was provided to convert from json to perl." ) );
    return( $opts->{data} ) if( !CORE::length( $opts->{data} ) );
    my $data = $opts->{data};
    my $names = $sth->FETCH('NAME');
    my $types = $sth->FETCH('pg_type');
    # $self->messagef( 3, "Found %d fields returned.", scalar( @$names ) );
    # $self->message( 3, "PG_JSON is: '", PG_JSON, "' and PG_JSONB is: '", PG_JSONB, "'." );
    my $pg_types = $sth->{pg_type};
    # $self->message( 3, "pg_type has following information: ", sub{ $self->printer( $pg_types ) } );
    my $mode = ref( $data );
    # $self->messagef( 3, "%d data received.", scalar( @$data ) ) if( $mode eq 'ARRAY' );
    $self->messagef( 3, "%d data received.", scalar( @$data ) ) if( $self->_is_array( $data ) );
    for( my $i = 0; $i < scalar( @$names ); $i++ )
    {
        # $self->messagef( 3, "Checking field '%s' with type '%s'.", $names->[$i], $types->[$i] );
        if( $types->[$i] eq PG_JSON || $types->[$i] eq PG_JSONB || $types->[$i] eq 'json' || $types->[$i] eq 'jsonb' )
        {
            $self->messagef( 3, "Found a json field '%s' of type '%s'.", $names->[$i], $types->[$i] );
            # if( $mode eq 'ARRAY' )
            if( $self->_is_array( $data ) )
            {
                $self->message( 3, "Value is: '", $data->[0], "'." );
                for( my $j = 0; $j < scalar( @$data ); $j++ )
                {
                    next if( !$data->[ $j ]->{ $names->[ $i ] } );
                    my $ref = $self->_decode_json( $data->[ $j ]->{ $names->[ $i ] } );
                    $data->[ $j ]->{ $names->[ $i ] } = $ref if( $ref );
                }
            }
            # elsif( $mode eq 'HASH' )
            elsif( $self->_is_hash( $data ) )
            {
                # $self->message( 3, "Value is: '", $data->{ $names->[ $i ] }, "'." );
                my $ref = $self->_decode_json( $data->{ $names->[ $i ] } );
                # $self->message( 3, "Converted value is: ", sub{ $self->dumper( $ref ) } );
                $data->{ $names->[ $i ] } = $ref if( $ref );
            }
        }
    }
    return( $data );
}

sub _dsn
{
    my $self = shift( @_ );
    my @params = ();
    # $self->message( 3, "\$self contains: ", sub{ $self->dumper( $self ) } );
    # See pg_service.conf
    if( $self->{service} )
    {
        @params = ( sprintf( 'dbi:%s:%s', @$self{ qw( driver service ) } ) );
    }
    else
    {
        # It ends with ':'
        @params = ( sprintf( 'dbi:%s:', $self->{driver} ) );
    }
    push( @params, sprintf( 'dbname=%s', $self->{database} ) ) if( $self->{database} );
    push( @params, sprintf( 'host=%s', $self->{host} ) ) if( $self->{host} );
    push( @params, sprintf( 'port=%d', $self->{port} ) ) if( $self->{port} );
    # push( @params, "options=$options" ) if( length( $options ) );
    return( join( ';', @params ) );
}

# See DB::Object
# sub _cache_this

# See DB::Object
# sub _clean_statement

# See DB::Object
# sub _cleanup

# See DB::Object
# sub _dbi_connect

# See DB::Object
# sub _make_sth

# Moved to DB::Object::Postgres::Query
# sub _query_components

# See DB::Object. The meat of it is really in DB::Object::Query
# sub _reset_query

# See DB::Object
# sub _save_bind

# See DB::Object
# sub _value2bind

# AUTOLOAD is inherited
# AUTOLOAD

DESTROY
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    if( $self->{sth} )
    {
        # $self->message( "DETROY(): Terminating sth '$self' for query:\n$self->{ 'query' }\n" );
        # print( STDERR "DESTROY(): Terminating sth '$self' for query:\n$self->{ 'query' }\n" ) if( $DEBUG );
        $self->{sth}->finish();
    }
    elsif( $self->{dbh} && $class =~ /^AI\:\:DB\:\:Postgres$/ )
    {
        local( $SIG{__WARN__} ) = sub { };
        # $self->{ 'dbh' }->disconnect();
        if( $DEBUG )
        {
            my( $pack, $file, $line, $sub ) = ( caller( 0 ) )[ 0, 1, 2, 3 ];
            my( $pack2, $file2, $line2, $sub2 ) = ( caller( 1 ) ) [ 0, 1, 2, 3 ];
            print( STDERR "DESTROY database handle ($self) [$self->{query}]\ncalled within sub '$sub' ($sub2) from package '$pack' ($pack2) in file '$file' ($file2) at line '$line' ($line2).\n" );
        }
        $self->disconnect();
    }
    my $locks = $self->{_locks};
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

# XXX POD

__END__

=encoding utf8

=head1 NAME

DB::Object::Postgres - SQL API

=head1 SYNOPSIS

    use DB::Object::Postgres;

    my $dbh = DB::Object::Postgres->connect({
    driver => 'Pg',
    conf_file => 'db-settings.json',
    database => 'webstore',
    host => 'localhost',
    login => 'store-admin',
    schema => 'auth',
    debug => 3,
    }) || bailout( "Unable to connect to sql server on host localhost: ", DB::Object->error );
    
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
    
    # and more elaborate:
    # Ref: https://www.postgresql.org/docs/10/sql-insert.html#SQL-ON-CONFLICT
    $login->on_conflict({
        # mandatory, can be a constraint name or a field name or array of fields
        target => 'on constraint idx_prefs_unique',
        action => 'update',
        # where => '',
        # which fields to update. It can also be more specific by providing a hash ref like fields => { val => 'plop' }
        fields => [qw( val )],
    });
    # would become:
    insert into login (..) values(...) on conflict on constraint idx_prefs_unique do update set val = EXCLUDED.val;
    
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
    
=head1 DESCRIPTION

This package inherits from L<DB::Object>, so any method not here, but there you can use.

L<DB::Object::Postgres> is a SQL API much alike L<DBD::Pg>.
So why use a private module instead of using that great L<DBD::Pg> package?

At first, I started to inherit from C<DBI> to conform to C<perlmod> perl 
manual page and to general perl coding guidlines. It became very quickly a 
real hassle. Barely impossible to inherit, difficulty to handle error, too 
much dependent from an API that change its behaviour with new versions.
In short, I wanted a better, more accurate control over the SQL connection.

So, L<DB::Object::Postgres> acts as a convenient, modifiable wrapper that provide the
programmer with an intuitive, user-friendly and hassle free interface.

=head1 CONSTRUCTOR

=head2 new

Create a new instance of L<DB::Object::Postgres>. Nothing much to say.

=head2 connect

Provided with a database, login, password, server, driver, and this will attempt a database connection.

Create a new instance of L<DB::Object::Postgres>, but also attempts a connection to SQL server.

You can specify the following parameters:

=over 4

=item I<datbase>

The database name you wish to connect to

=item I<login>

The login used to access that database

=item I<password>

The password that goes along

=item I<server>

The server, that is hostname of the machine serving a SQL server.

=item I<driver>

The driver you want to use. It needs to be of the same type than the server you want to connect to. If you are connecting to a MySQL server, you would use C<mysql>, if you would connecto to an Oracle server, you would use C<oracle>.

You need to make sure that those driver are properly installed in the system before attempting to connect.

To install the required driver, you could start with the command line:

    perl -MCPAN -e shell

which will provide you a special shell to install modules in a convenient way.

=back

=head1 METHODS

=head2 attribute

Sets or gets one more pg attributes.

Valid attributes are:

=over 4

=item I<ActiveKids>

Is read-only.

=item I<AutoCommit>

Can be changed.

=item I<AutoInactiveDestroy>

Can be changed.

=item I<CachedKids>

Is read-only.

=item I<ChildHandles>

Is read-only.

=item I<ChopBlanks>

Can be changed.

=item I<CursorName>

Is read-only.

=item I<Driver>

Is read-only.

=item I<ErrCount>

Can be changed.

=item I<Executed>

Is read-only.

=item I<FetchHashKeyName>

Can be changed.

=item I<HandleError>

Can be changed.

=item I<HandleSetErr>

Can be changed.

=item I<InactiveDestroy>

Can be changed.

=item I<Kids>

Is read-only.

=item I<NAME>

Is read-only.

=item I<NULLABLE>

Is read-only.

=item I<NUM_OF_FIELDS>

Is read-only.

=item I<NUM_OF_PARAMS>

Is read-only.

=item I<Name>

Is read-only.

=item I<PRECISION>

Is read-only.

=item I<PrintError>

Can be changed.

=item I<PrintWarn>

Can be changed.

=item I<Profile>

Can be changed.

=item I<RaiseError>

Can be changed.

=item I<ReadOnly>

Can be changed.

Specifies if the current database connection should be in read-only mode or not.

=item I<RowCacheSize>

Is read-only.

=item I<RowsInCache>

Is read-only.

=item I<SCALE>

Is read-only.

=item I<ShowErrorStatement>

Can be changed.

=item I<Statement>

Is read-only.

=item I<TYPE>

Is read-only.

=item I<Taint>

Can be changed.

=item I<TaintIn>

Can be changed.

=item I<TaintOut>

Can be changed.

=item I<TraceLevel>

Can be changed.

=item I<Type>

Can be changed.

=item I<Username>

Is read-only.

=item I<Warn>

Can be changed.

=item I<pg_INV_READ>

Is read-only.

=item I<pg_INV_WRITE>

Is read-only.

=item I<pg_async_status>

Is read-only.

=item I<pg_bool_tf>

Can be changed.

If true, boolean values will be returned as the characters 't' and 'f' instead of '1' and '0'.

=item I<pg_db>

Is read-only.

=item I<pg_default_port>

Is read-only.

=item I<pg_enable_utf8>

Can be changed.

=item I<pg_errorlevel>

Can be changed.

Valid entries are 0, 1 and 2

=item I<pg_expand_array>

Can be changed.

=item I<pg_host>

Is read-only.

=item I<pg_lib_version>

Is read-only.

=item I<pg_options>

Is read-only.

=item I<pg_pass>

Is read-only.

=item I<pg_pid>

Is read-only.

=item I<pg_placeholder_dollaronly>

Can be changed.

When true, question marks inside of statements are not treated as placeholders, e.g. geometric operators

=item I<pg_placeholder_nocolons>

Can be changed.

When true, colons inside of statements are not treated as placeholders

=item I<pg_port>

Is read-only.

=item I<pg_prepare_now>

Can be changed.

=item I<pg_protocol>

Is read-only.

=item I<pg_server_prepare>

Can be changed.

Indicates if L<DBD::Pg> should attempt to use server-side prepared statements. On by default

=item I<pg_server_version>

Is read-only.

=item I<pg_socket>

Is read-only.

=item I<pg_standard_conforming_strings>

Is read-only.

=item I<pg_switch_prepared>

Can be changed.

=item I<pg_user>

Is read-only.

=back

=head2 begin_work

Mark the beginning of a transaction.

Any arguments provided are passed along to L<DBD::Pg/begin_work>

=head2 commit

Make any change to the database irreversible.

This must be used only after having called L</begin_work>

Any arguments provided are passed along to L<DBD::Pg/commit>

=head2 connect

Same as L<DB::Object/connect>, only specific to PostgreSQL.

See L</_connection_params2hash>

=head2 create_db

Provided with a database name and some optional parameters and this will prepare and execute the query to create the database.

Upon failure, this will return an error, and upon success, this will connect to the newly created database and return the database handler.

Possible options are:

=over 4

=item I<allowcon>

Sets the C<ALLOW_CONNECTIONS> attribute

"If false then no one can connect to this database. The default is true, allowing connections."

=item I<connlimit>

Sets the C<CONNECTION LIMIT> attribute

"How many concurrent connections can be made to this database. -1 (the default) means no limit."

=item I<encoding>

Sets the C<ENCODING> attribute

"Character set encoding to use in the new database."

=item I<lc_collate>

Sets the C<LC_COLLATE> attribute

"Collation order (LC_COLLATE) to use in the new database."

=item I<lc_ctype>

Sets the C<LC_CTYPE> attribute

"Character classification (LC_CTYPE) to use in the new database."

=item I<istemplate>

Sets the C<IS_TEMPLATE> attribute

"If true, then this database can be cloned by any user with CREATEDB privileges; if false (the default), then only superusers or the owner of the database can clone it."

=item I<owner>

Sets the C<OWNER> attribute

"The role name of the user who will own the new database"

=item I<tablespace>

Sets the C<TABLESPACE> attribute

"The name of the tablespace that will be associated with the new database"

=item I<template>

Sets the C<TEMPLATE> attribute

"The name of the template from which to create the new database"

=back

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/sql-createdatabase.html>

=head2 create_table

Provided with a table name and some options as hash reference and this will create a new table.

A mandatory parameter is I<sql> which must contain the sql script to be used.

The sql script is executed using L<DB::Object/do> and the returned value is returned.

=head2 databases

Returns a list of all available databases.

=head2 func

Provided with a table name and a function name and this will call L<DBD::Pg/func> and returns the result.

=head2 get_sql_type

    my $const $dbh->get_sql_type( 'bytea' );
    # returns 17
    my $const $dbh->get_sql_type( 'json' );
    # returns 114
    my $const $dbh->get_sql_type( 'jsonb' );
    # returns 3802

Provided with a sql type, irrespective of the character case, and this will return the equivalent constant value.

=head2 having

A convenient wrapper to L<DB::Object::Postgres::Query/having>

=head2 large_object

Instantiate a new L<DB::Object::Postgres::Lo> and returns it.

=head2 last_insert_id

Get the id of the primary key from the last insert.

=head2 lock

Takes a table name, a lock mode and an optional C<nowait> and this will lock the given table by issuing the relevant query.

Supported lock types are: C<SHARE>, C<SHARE ROW EXCLUSIVE>, C<EXCLUSIVE>, C<ACCESS EXCLUSIVE>

If the lock failed (NULL), it returns undef(), otherwise, it returns the return value.

=head2 make_schema

Provided with a database name and this will create its schema.

In list context, it returns an array of schema lines, and in scalar context, it returns the schema as a string.

=head2 on_conflict

See L<DB::Object::Postgres::Tables/on_conflict>

=head2 pg_ping

Calls L<DBD::Pg/pg_ping>

=head2 query_object

Set or gets the PostgreSQL query object (L<DB::Object::Postgres::Query>) used to process and format queries.

=head2 release

Calls L<DBD::pg_release> passing it through whatever arguments were provided.

=head2 replace

Replace queries are not supported in PostgreSQL

=head2 returning

A convenient wrapper to L<DB::Object::Postgres::Query/returning>

=head2 rollback

Will roll back any changes made to the database since the last transaction point marked with L</begin_work>

=head2 rollback_to

Will call L<DBD::Pg/pg_rollback_to> and passing it through whatever arguments were provided.

=head2 savepoint

Will call L<DBD::Pg/pg_savepoint> and passing it through whatever arguments were provided.

=head2 schema

Sets or gets the database schema.

It returns the value as a L<Module:Generic::Scalar> object

=head2 search_path

If a search path is provided, this will issue the query to set it using C<SET search_path = $search_path> whatever C<$search_path> is. It returns the returned value from L<DBD::Pg/execute>

If no arguments is provided, this will issue the query C<SHOW search_path> to retrieve the current search path.

It returns an array object (L<Module::Generic::Array>) containing the search paths found.

=head2 set

This is inherited from L<DB::Object>

Please see L<PostgreSQL documentation for the variables that can be set|https://www.postgresql.org/docs/10/runtime-config-client.html>.

=head2 socket

This returns the database handler property C<pg_socket>

=head2 table_exists

Provided with a table name and this will check if the table exists.

It accepts the following options:

=over 4

=item I<anywhere>

If true, this will search anywhere.

=item I<schema>

A database schema.

=back

=head2 table_info

Provided with a table name and some optional parameters and this will retrieve the table information.

It returns an array reference of tables information found if no schema was provided or if I<anywhere> is true.

If a schema was provided, and the table found it returns an hash reference for that table.

Otherwise, if nothing can be found, it returns an empty array reference.

Optional parameters are:

=over 4

=item I<anywhere>

If true, it will search anywhere.

=item I<schema>

A database schema.

=back

=head2 tables_info

Provided with a database name and this returns all the tables information.

Information retrieved from the PostgreSQL system tables for every table found in the given database are:

=over 4

=item I<name>

The object name

=item I<owner>

The object owner (role)

=item I<schema>

Database schema, if any.

=item I<type>

The object type, which may be one of: C<table>, C<view>, C<materialized view>, C<special>, C<foreign table>

=back

=head2 trace

Calls L<DBD::Pg/trace> passing through whatever arguments were provided.

=head2 trace_msg

Calls L<DBD::Pg/trace_msg> and pass it whatever arguments were provided.


=head2 unlock

Unlock does not work with PostgreSQL

=head2 variables

Variables are currently unsupported in Postgres

=head2 version

Returns the PostgreSQL database server version.

This information is cached per object for efficiency.

=head2 _check_connect_param

Given some parameters hash and this will return a proper hash reference of parameters suitable for connection parameters.

This will call L</_connection_parameters> to get the valid parameters and L</_connection_options> to get valid connection options based on the arguments provided.

It returns the hash reference of connection parameters.

=head2 _check_default_option

Based on optional arguments and this will enable default options for the parameters provided.

Currently this only check C<client_encoding> and set the default to C<utf8>

It returns an hash reference of those parameters.

=head2 _connection_options

Based on an hash reference of parameters and this will call L<DB::Object/_connection_options> and return a new hash reference of keys starting with C<pg_>

=head2 _connection_parameters

Based on an hash reference of parameters, this will return an array reference of core properties plus additional PostgreSQL specific properties that start with C<pg_>

The core properties are: C<db>, C<login>, C<passwd>, C<host>, C<port>, C<driver>, C<database>, C<schema>, C<server>, C<opt>, C<uri>, C<debug>

=head2 _convert_datetime2object

Based on an hash reference of parameters and this will transcode any datetime column into a L<DateTime> object.

It returns the I<data> hash reference

Possible parameters are:

=over 4

=item I<data>

An hash reference of data typically returned from a L<DBD::Pg/fetchrow_hashref>

=item I<statement>

This is the statement from which to check for columns

=back

=head2 _convert_json2hash

Based on an hash reference of parameters, and this will check for the I<data> for any json column and if found, it will transcode the json to hash reference.

It returns the I<data> hash reference

Possible parameters are:

=over 4

=item I<data>

An hash reference of data typically returned from a L<DBD::Pg/fetchrow_hashref>

=item I<statement>

This is the statement from which to check for columns

=back

=head2 _dsn

This returns a properly formatted C<dsn> as a string.

=head1 SEE ALSO

L<DBI>, L<Apache::DBI>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
