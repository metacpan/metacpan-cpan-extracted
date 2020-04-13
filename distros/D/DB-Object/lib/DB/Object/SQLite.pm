# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/SQLite.pm
## Version 0.4
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/08/25
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This is the subclassable module for driver specific ones.
package DB::Object::SQLite;
BEGIN
{
    require 5.6.0;
    use strict;
    use DBI qw( :sql_types );
    ## use DBD::SQLite;
    eval
    {
		require DBD::SQLite;
    };
    die( $@ ) if( $@ );
	use parent qw( DB::Object );
    require DB::Object::SQLite::Statement;
    require DB::Object::SQLite::Tables;
    use File::Spec;
    use File::Basename;
    use POSIX ();
    use DateTime;
    use DateTime::TimeZone;
    use DateTime::Format::Strptime;
	use Number::Format;
	use TryCatch;
    our( $VERSION, $DB_ERRSTR, $ERROR, $DEBUG, $CONNECT_VIA, $CACHE_QUERIES, $CACHE_SIZE );
    our( $CACHE_TABLE, $USE_BIND, $USE_CACHE, $MOD_PERL, @DBH );
    $VERSION     = '0.4';
    use Devel::Confess;
};

{
    $DB_ERRSTR     = '';
    $DEBUG         = 0;
    $CACHE_QUERIES = [];
    $CACHE_SIZE    = 10;
    ## The purpose of this cache is to store table object and avoid the penalty of reloading the structure of a table for every object generated.
    ## Thus CACHE_TABLE is in no way an exhaustive list of existing table, but existing table object.
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
    
    our $PRIVATE_FUNCTIONS =
    {
		'ceiling'			=>[1, \&_ceiling],
		'concat'			=>[-1, \&_concat],
		'curdate'			=>[0, \&_curdate],
		'curtime'			=>[0, \&_curtime],
		'dayname'			=>[1, \&_dayname],
		'dayofmonth'		=>[1, \&_dayofmonth],
		'dayofweek'			=>[1, \&_dayofweek],
		'dayofyear'			=>[1, \&_dayofyear],
		'distance_miles'	=>[4, \&_distance_miles],
		# 'from_days'			=>[-1, \&_from_days],
		'from_unixtime'		=>[1, \&_from_unixtime],
		'hour'				=>[1, \&_hour],
		'lcase'				=>[1, \&_lcase],
		'left'				=>[2, \&_left],
		'locate'			=>[2, \&_locate],
		'log10'				=>[1, \&_log10],
		'minute'			=>[1, \&_minute],
		'month'				=>[1, \&_month],
		'monthname'			=>[1, \&_monthname],
		'number_format'		=>[4, \&_number_format],
		'power'				=>[2, \&_power],
		'quarter'			=>[1, \&_quarter],
		'rand'				=>[0, \&_rand],
		'regexp'			=>[2, \&_regexp],
		'replace'			=>[3, \&_replace],
		'right'				=>[2, \&_right],
		'second'			=>[1, \&_second],
		'space'				=>[1, \&_space],
		'sprintf'			=>[-1, \&_sprintf],
		'to_days'			=>[1, \&_to_days],
		# 'truncate'			=>[-1, \&_truncate],
		'ucase'				=>[1, \&_ucase],
		'unix_timestamp'	=>[1, \&_unix_timestamp],
		'week'				=>[1, \&_week],
		'weekday'			=>[1, \&_weekday],
		'year'				=>[1, \&_year],
    };
    ## See compile_options method
    ## This is very useful to know which features can be used
    our $COMPILE_OPTIONS = [];
}

## Get/set alias
## sub alias

## sub as_string

## sub avoid

sub attribute($;$@)
{
    my $self = shift( @_ );
    ## $h->{AttributeName} = ...;    # set/write
    ## ... = $h->{AttributeName};    # get/read
    ## 1 means that the attribute may be modified
    ## 0 mneas that the attribute may only be read
    my $name  = shift( @_ ) if( @_ == 1 );
    my %arg   = ( @_ );
    my %attr  = 
    (
    'InactiveDestroy'		=> 1, 
    'AutoInactiveDestroy'	=> 1,
    'RaiseError'			=> 1, 
    'PrintError'			=> 1, 
	'ShowErrorStatement'	=> 1,
    'Warn'					=> 1, 
    'Executed'				=> 0,
    'TraceLevel'			=> 1,
    'Kids'					=> 0,
    'ActiveKids'			=> 0, 
    'CachedKids'			=> 0,
    'ChildHandles'			=> 0,
    'PrintWarn'				=> 1,
    'HandleError'			=> 1,
    'HandleSetErr'			=> 1,
    'ErrCount'				=> 1,
    'FetchHashKeyName'		=> 1,
    'ChopBlanks'			=> 1,
    'Taint'					=> 1,
    'TaintIn'				=> 1,
    'TaintOut'				=> 1,
    'Profile'				=> 1,
    'Type'					=> 1,
    ## Not used
    ## 'LongReadLen'			=> 1,
    ## 'LongTruncOk'			=> 1,
    ## 'CompatMode'			=> 1,
    'AutoCommit'			=> 1, 
    'Name'					=> 0, 
    'RowCacheSize'			=> 0, 
    'NUM_OF_FIELDS'			=> 0, 
    'NUM_OF_PARAMS'			=> 0, 
    'NAME'					=> 0, 
    'TYPE'					=> 0, 
    'PRECISION'				=> 0, 
    'SCALE'					=> 0, 
    'NULLABLE'				=> 0, 
    'CursorName'			=> 0, 
    'Statement'				=> 0, 
    'RowsInCache'			=> 0, 
    ## Current database name
    'Name'					=> 0,
    'Username'				=> 0,
    'Driver'				=> 0,
    'sqlite_version'		=> 0,
    'sqlite_unicode'		=> 1,
    ## If you set this to true, "do" method will process multiple statements at one go.
    ## This may be handy, but with performance penalty. See above for details.
    'sqlite_allow_multiple_statements' => 1,
    ## If you set this to true, DBD::SQLite tries to issue a "begin immediate transaction"
    ## (instead of "begin transaction") when necessary.
    'sqlite_use_immediate_transaction' => 1,
    ## If you set this to true, DBD::SQLite tries to see if the bind values are number or
    ## not, and does not quote if they are numbers.
    'sqlite_see_if_its_a_number' => 1,
    ## Returns an unprepared part of the statement you pass to "prepare".  Typically this
    ## contains nothing but white spaces after a semicolon. 
    'sqlite_unprepared_statements' => 0,
    );
    ## Only those attribute exist
    ## Using an a non existing attribute produce an exception, so we better avoid
    if( $name )
    {
        return( $self->{ 'dbh' }->{ $name } ) if( exists( $attr{ $name } ) );
    }
    else
    {
        my $value;
        while( ( $name, $value ) = each( %arg ) )
        {
            ## We intend to modifiy the value of an attribute
            ## we are allowed to modify this value if it is true
            if( exists( $attr{ $name } ) && 
                defined( $value ) && 
                $attr{ $name } )
            {
                $self->{ 'dbh' }->{ $name } = $value;
            }
        }
    }
}

## sub available_drivers(@)

sub begin_work($;$@)
{
	my $self = shift( @_ );
	$self->{transaction} = 1;
	return( $self->{dbh}->begin_work( @_ ) );
}

## This method is common to DB::Object and DB::Object::Statement
## sub bind

## sub cache

sub can_update_delete_limit { return( shift->has_compile_option( 'ENABLE_UPDATE_DELETE_LIMIT' ) ); }

## sub check_driver(@;$@)

sub commit($;$@)
{
	my $self = shift( @_ );
	$self->{transaction} = 0;
	return( $self->{dbh}->commit( @_ ) );
}

sub compile_options
{
	my $self = shift( @_ );
	return( [ @$COMPILE_OPTIONS ] ) if( scalar( @$COMPILE_OPTIONS ) );
	my $tmpdir = File::Spec->tmpdir();
    my $compile_options_cache_file  = File::Spec->catfile( $tmpdir, 'sql_sqlite_compile_options.cfg' );
    my @options = ();
	if( -e( $compile_options_cache_file ) && !-z( $compile_options_cache_file ) )
	{
		my $fh = IO::File->new( "<$compile_options_cache_file" ) || return( $self->error( "Unable to read the sqlite compile options cache file \"$compile_options_cache_file\": $!" ) );
		my @all = $fh->getlines;
		## Remove any comments
		@options = grep( !/^#/, @all );
		$fh->close;
		if( scalar( @options ) )
		{
			$COMPILE_OPTIONS = \@options;
			## Return a copy only to be safe
			return( [ @options ] );
		}
	}
	## If the cache file does not yet exists or there is no options, we do the query
    my $dbh = $self->{dbh} || return( $self->error( "No active database handler available. You can only call this method once a database connection has been made." ) );
	my $all = $self->do( "PRAGMA compile_options" )->fetchall_arrayref;
	@options = map( $_->[0], @$all );
	my $fh = IO::File->new( ">$compile_options_cache_file" ) || return( $self->error( "Unable to write to sqlite compile options cache file \"$compile_options_cache_file\": $!" ) );
	$fh->autoflush( 1 );
	$fh->print( join( "\n", @options ), "\n" ) || return( $self->error( "Unable to write to the sqlite compile options cache file \"$compile_options_cache_file\": $!" ) );
	$fh->close;
	$COMPILE_OPTIONS = \@options;
    return( \@options );
}

## Inherited by DB::Object, however, DB::Object::connect() will call our subroutine 
## _dbi_connect which format in a particular way the dsn.
sub connect
{
    my $that  = shift( @_ );
    my $param = $that->_connection_params2hash( @_ ) || return( undef() );
    $param->{driver} = 'SQLite';
    $param->{sqlite_unicode} = 1;
    return( $that->SUPER::connect( $param ) );
}

## sub copy

## sub create_table($;%)

## See DB::Object
## sub data_sources($;\%)

## sub data_type

## sub database

sub database_file
{
	return( shift->{database_file} );
}

sub databases
{
	my $self = shift( @_ );
	## return( $self->error( "Not connected to PostgreSQL server yet. Issue $dbh->connect first." ) ) if( !$self->{ 'dbh' } );
	my $dbh;
	## If there is no connection yet, then create one using the postgres login.
	## There should not be a live user and database just to check what databases there are.
	if( !$self->{dbh} )
	{
		try
		{
			$dbh = $self->connect( $con ) || return( undef() );
		}
		catch( $e )
		{
			$self->message( 3, "An error occurred while trying to connect to get the list of available databases: $e" );
			return;
		}
	}
	else
	{
		$self->message( 3, "Already have a connection database handler '$self->{dbh}'" );
		$dbh = $self;
	}
	my $temp = $dbh->do( "PRAGMA database_list" )->fetchall_arrayref( {} );
	my @dbases = map( $_->{name}, @$temp );
	return( @dbases );
}

sub func
{
	my $self      = shift( @_ );
	my $table     = shift( @_ );
	## e.g. table_attributes to get the detail information on table columns
	my $func_name = shift( @_ );
	## Returns:
	## NAME        attribute name
	## TYPE        attribute type
	## SIZE        attribute size (-1 for variable size)
	## NULLABLE    flag nullable
	## DEFAULT     default value
	## CONSTRAINT  constraint
	## PRIMARY_KEY flag is_primary_key
	## REMARKS     attribute description
	return( $self->{ 'dbh' }->func( $table, $func_name ) );
}

sub having
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->having( @_ ) );
}

## https://www.sqlite.org/compile.html
sub has_compile_option
{
	my $self = shift( @_ );
	my $opt  = shift( @_ ) || return( $self->error( "No compile option was provided to check" ) );
	$opt = uc( $opt );
	my $all  = $self->compile_options;
	my @found = grep( /^$opt/, @$all );
	return( $found[0] ) if( scalar( @found ) );
	return( '' );
}

sub init
{
	my $self = shift( @_ );
	$self->SUPER::init( @_ );
	$self->{driver} = 'SQLite';
	$self->{_func} = {};
	return( $self );
}

sub last_insert_id
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || $self->{ 'table' };
    return( $self->{ 'dbh' }->last_insert_id( undef, undef, $table, undef ) );
}

## http://www.postgresql.org/docs/current/static/sql-lock.html
sub lock { return( shift->error( "Table lock is unsupported in SQLite." ) ); }

sub pragma
{
	my $self = shfit( @_ );
	my $key2val =
	{
	'foreign_keys'	=> [ qw( ON OFF ) ],
	'journal_mode'	=> [ qw( DELETE TRUNCATE ) ],
	'legacy_file_format'	=> [ qw( ON OFF ) ],
	'reverse_unordered_selects'	=> [ qw( ON OFF ) ],
	'synchronous'	=> [ qw( ON OFF ) ],
	## To avoid corruption after BEGIN starts, DBD uses BEGIN IMMEDIATE. Default is TRUE
	'sqlite_use_immediate_transaction' => [ qw( 1 0 ) ],
	'cache_size' => qr/^\d+$/
	};
}

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::SQLite::Query', @_ ) ); }

## https://www.sqlite.org/lang_replace.html
## https://www.sqlite.org/lang_conflict.html
## REPLACE is an alias for INSERT OR REPLACE
## https://www.sqlite.org/lang_insert.html
sub replace
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    my %arg  = ();
    my $select = '';
    if( !%arg && $data && $self->_is_hash( $data ) )
    {
        %arg = %$data;
    }
    elsif( $data && ref( $data ) eq 'DB::Object::Statement' )
    {
        $select = $data->as_string();
    }
    %arg = @arg if( @arg );
    my $table   = $self->{ 'table' } ||
    return( $self->error( "No table was provided to replace data." ) );
    my $structure = $self->structure();
    my $null      = $self->null();
    my @avoid     = ();
    foreach my $field ( keys( %$structure ) )
    {
        ## It is useless to insert a blank data in a field whose default value is NULL.
        ## Especially since a test on a NULL field may be made specifically.
        push( @avoid, $field ) if( !CORE::exists( $arg{ $field } ) && $null->{ $field } );
    }
    my $db_data = $self->getdefault({
    	table => $table,
    	arg => \@arg,
    	avoid => \@avoid
    });
    my( $fields, $values ) = $db_data->format_statement();
    $self->_reset_query();
    delete( $self->{ 'query_reset' } );
    $self->{ 'binded_values' } = $db_data->{ 'binded_values' };
    my $query = $self->{ 'query' } = $select ? "REPLACE INTO $table $select" : "REPLACE INTO $table ($fields) VALUES($values)";
    ## Everything meaningfull lies within the object
    ## If no bind should be done _save_bind does nothing
    $self->_save_bind();
    ## Query string should lie within the object
    ## _cache_this sends back an object no matter what or unde() if an error occurs
    my $sth = $self->_cache_this();
    ## STOP! No need to go further
    if( !defined( $sth ) )
    {
        return( $self->error( "Error while preparing query to replace data into table '$table':\n$query", $self->errstr() ) );
    }
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to replace data to table '$table':\n$query" ) );
    }
    return( $sth );
}

sub register_function
{
    my $self = shift( @_ );
    return( $self->error( "I was expecting an hash reference of parameters as only argument." ) ) if( !$self->_is_hash( $_[0] ) );
    my $opts = shift( @_ );
    return( $self->error( "Parameter 'code' to register the private function must be a code reference." ) ) if( ref( $opts->{code} ) ne 'CODE' );
    $opts->{flags} = [] if( !CORE::exists( $opts->{flags} ) );
    return( $self->error( "Parameter 'flags' must be an array reference." ) ) if( !$self->_is_array( $opts->{flags} ) );
    $opts->{argc} = -1 if( !CORE::exists( $opts->{argc} ) );
    return( $self->error( "No name was provided for this private function." ) ) if( !CORE::exists( $opts->{name} ) );
    my $name = $opts->{name};
    return( $self->error( "Name provided for this private function \"$name\" contains illegal characters. Only alphabetical and numerical characters and underscore allowed with name starting with a letter." ) ) if( $name !~ /^[a-zA-Z][a-zA-Z0-9\_]+$/ );
    my $funcs = $self->{func};
    $funcs->{ lc( $opts->{name} ) } = $opts;
    $self->sql_function_register( $opts ) if( $self->{dbh} );
    return( $opts );
}

sub remove_function
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No private function was provided to be removed." ) );
    my $funcs = $self->{func};
    $name = lc( $name );
    return( 0 ) if( !CORE::exists( $funcs->{ $name } ) );
    return( CORE::delete( $funcs->{ $name } ) );
}

sub rollback
{
	return( shift->{dbh}->rollback() );
}

sub sql_function_register
{
    my $self = shift( @_ );
    my $opts = shift( @_ ) || return( $self->error( "No private function hash reference provided." ) );
    my $dbh = $self->{dbh} || return( $self->error( "No active database handler available." ) );
	my $flag;
	my $eval = join( '|', @{$opts->{flags}} );
	$flag = eval( $eval );
	my $code = $opts->{code};
	$self->message( 3, "Regisering private function name '$opts->{name}', max number of arguments '$opts->{argc}'." );
	if( defined( $flag ) )
	{
		$dbh->sqlite_create_function( $opts->{name}, $opts->{argc}, sub{ my @arg = @_; unshift( @arg, $self ); $code->( @arg ); }, $flag );
	}
	else
	{
		$dbh->sqlite_create_function( $opts->{name}, $opts->{argc}, sub{ my @arg = @_; unshift( @arg, $self ); $code->( @arg ); } );
	}
	$opts->{_registered_on} = time();
}

## http://www.sqlite.org/c3ref/c_status_malloc_count.html
sub stat
{
    my $self = shift( @_ );
    my $opt  = {};
    $opt     = shift( @_ ) if( $self->_is_hash( $_[0] ) );
    my $ref  = $opt->{reset} ? DBD::SQLite::sqlite_status( 0 ) : DBD::SQLite::sqlite_status();
    if( $opt->{type} )
    {
        return( exists( $ref->{ $opt->{type} } ) ? $ref->{ $opt->{type} } : undef() );
    }
    else
    {
        return( wantarray() ? () : undef() ) if( !%$ref );
        return( wantarray() ? %$ref : $ref );
    }
}

# sub table_exists
# {
#     my $self = shift( @_ );
# 	my $table = shift( @_ ) || 
#     return( $self->error( "You must provide a table name to access the table methods." ) );
#     my $cache_tables = $self->cache_tables;
#     my $tables_in_cache = $cache_tables->get({
#     	host => 'localhost',
#     	driver => $self->driver,
#     	port => 0,
#     	database => $self->database,
#     });
#     foreach my $ref ( @$tables_in_cache )
#     {
#     	return( 1 ) if( $ref->{name} eq $table );
#     }
#     ## We did not find it, so let's try by checking directly the database
#     my $def = $self->table_info( $table ) || return( undef() );
#     return( 0 ) if( !scalar( @$def ) );
#     return( 1 );
# }

sub table_info
{
    my $self = shift( @_ );
	my $table = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[0] ) );
    my $sql = <<'EOT';
SELECT 
	 name
	,type
FROM sqlite_master
WHERE type IN ('table', 'view') AND name = ?
EOT
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
	my $sth = $dbh->prepare_cached( $sql ) || return( $self->error( "An error occured while preparing query to check if table \"$table\" exists in database \"", $self->database, "\": ", $dbh->errstr ) );
	$sth->execute( $table ) || return( $self->error( "An error occured while executing query to check if table \"$table\" exists in database \"", $self->database, "\: ", $sth->errstr ) );
	my $all = $sth->fetchall_arrayref( {} );
	$sth->finish;
	return( $all );
}

sub tables
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{ 'database' };
    my $all  = $self->tables_info || return( undef() );
    my @tables = map( $_->{name}, @$all );
#     return( wantarray() ? () : undef() ) if( !@tables );
#     return( wantarray() ? @tables : \@tables );
	return( \@tables );
}

sub tables_info
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{ 'database' };
    ## Parameters are: ?, schema, table, and type
    ## my $sth  =  $self->{ 'dbh' }->table_info( undef, undef, $table, "TABLE,VIEW" );
    ## The original query was fetched by connecting to Postgres with psql -E and executing the command \z
    ## This revised query will fetch only tables, views, materialised view and foreign tables, but will avoid the mysterious view called sequence_setvals
    ## https://stackoverflow.com/questions/82875/how-to-list-the-tables-in-a-sqlite-database-file-that-was-opened-with-attach
    my $query = <<SQL;
SELECT name FROM sqlite_master
  WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%'
UNION ALL
SELECT name FROM sqlite_temp_master
  WHERE type IN ('table','view')
ORDER BY 1
SQL
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my $sth = $dbh->prepare_cached( $query ) || return( $self->error( sprintf( "Error while preparing query $query: %s", $dbh->errstr ) ) );
    $sth->execute() || return( $self->error( sprintf( "Error while executing query $query: %s", $sth->errstr ) ) );
    my $all = $sth->fetchall_arrayref( {} );
    return( $all );
}

sub trace { return( shift->error( "Trace is unsupported on SQLite." ) ); }

sub unlock { return( shift->error( "unlock() does not work with SQLite." ) ); }

sub variables
{
	return( shift->error( "variables is currently unsupported in Postgres" ) );
}

## https://www.sqlite.org/versionnumbers.html
sub version
{
    my $self  = shift( @_ );
    ## If we already have the information, let's use our cache instead of making a query
    return( $self->{ '_db_version' } ) if( length( $self->{ '_db_version' } ) );
    my $sql = 'SELECT sqlite_version()';
    my $sth = $self->do( $sql ) || return( $self->error( "Unable to issue the sql statement '$sql' to get the server version: ", $self->errstr ) );
    my $ver = $sth->fetchrow;
    $sth->finish;
    ## We cache it
    $self->{ '_db_version' } = $ver;
    return( $ver );
}

sub _check_connect_param
{
    my $self  = shift( @_ );
    my $param = $self->SUPER::_check_connect_param( @_ );
    if( !$param->{database_file} && $param->{database} )
    {
    	my $uri = CORE::exists( $param->{uri} ) ? $param->{uri} : '';
    	my $db = $param->{database} ? $param->{database} : ( $uri->path_segments )[-1];
    	my $path = $uri ? $uri->path : $db;
		## $db = Cwd::abs_path( $uri ? $uri->path : $db );
		$db = File::Spec->rel2abs( $path );
		## If we cannot find the file and it does not end with .sqlite, let's add the extension
		## So the user can provide the database parameter just like database => 'test' or database => './test'
		$db = "$db.sqlite" if( !-e( $db ) && $db !~ /\.sqlite$/i );
		my( $filename, $path, $ext ) = File::Basename::fileparse( $db, qr/\.[^\.]+$/ );
		$self->message( 3, "Database file path is '$path', file name '$filename' and extension '$ext'." );
		$param->{database} = $filename;
		$param->{database_file} = $self->{database_file} = $db;
    }
    $param->{ 'host' } = 'localhost' if( !length( $param->{ 'host' } ) );
    $param->{ 'port' } = 0 if( !length( $param->{ 'port' } ) );
    $self->message( 3, "Returning parameters: ", sub{ $self->dumper( $param ) } );
    return( $param );
}

sub _check_default_option
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ );
	return( $self->error( "Provided option is not a hash reference." ) ) if( !$self->_is_hash( $opts ) );
	$opts->{sqlite_unicode} = 1 if( !CORE::exists( $opts->{sqlite_unicode} ) );
	return( $opts );
}

sub _connection_options
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    my @sqlite_params = grep( /^sqlite_/, keys( %$param ) );
    my $opt = $self->SUPER::_connection_options( $param );
    ## $self->message( 3, "Inherited options are: ", sub{ $self->dumper( $opt ) } );
    @$opt{ @sqlite_params } = @$param{ @sqlite_params };
    return( $opt );
}

sub _connection_parameters
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    ## Even though login, password, server, host are not used, I was hesitating, but decided to leave them as ok, and ignore them
    ## Or maybe should I issue an error when they are provided?
    my $core = [qw( db login passwd host port driver database server opt uri debug )];
    my @sqlite_params = grep( /^sqlite_/, keys( %$param ) );
    ## See DBD::SQLite for the list of valid parameters
    ## E.g.: sqlite_open_flags sqlite_busy_timeout sqlite_use_immediate_transaction sqlite_see_if_its_a_number sqlite_allow_multiple_statements sqlite_unprepared_statements sqlite_unicode sqlite_allow_multiple_statements sqlite_use_immediate_transaction
    push( @$core, @sqlite_params );
    return( $core );
}

sub _dbi_connect
{
    my $self = shift( @_ );
    my $dbh  = $self->{dbh} = $self->SUPER::_dbi_connect( @_ );
    $self->message( 3, "Database handler returned from dbi_connect is '$dbh'" );
    ## my $func = $self->{_func};
    my $func = $self->{ '_func' };
    foreach my $k ( sort( keys( %$PRIVATE_FUNCTIONS ) ) )
    {
    	my $this = $PRIVATE_FUNCTIONS->{ $k };
    	my $ref =
    	{
    	'name' => $k,
    	'argc' => $this->[0],
    	'code' => $this->[1],
    	};
    	$func->{ $k } = $ref;
    }
    $self->messagef( 3, "Declaring %d private functions.", scalar( keys( %$func ) ) );
    foreach my $name ( sort( keys( %$func ) ) )
    {
    	my $ref = $func->{ $name };
    	if( $ref->{ '_registered_on' } )
    	{
    		$self->message( 3, "Function $ref->{name} already added on ", scalar( localtime( $ref->{ '_registered_on' } ) ) );
    		next;
    	}
    	$self->sql_function_register( $ref );
    	$ref->{ '_registered_on' } = time();
    }
    return( $dbh );
}

sub _dsn
{
    my $self = shift( @_ );
    my $db = $self->{database_file} || return( $self->error( "No database file was specified." ) );
    # return( $self->error( "Database file \"$db\" does not exist." ) ) if( !-e( $db ) );
    return( $self->error( "Database file \"$db\" is not writable." ) ) if( -e( $db ) && !-w( $db ) );
	my @params = ( sprintf( 'dbi:%s:', $self->{driver} ) );
	push( @params, sprintf( 'dbname=%s', $db ) );
	return( join( ';', @params ) );
}

sub _parse_timestamp
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    ## No value was actually provided
    return( undef() ) if( !length( $str ) );
	my $tz = DateTime::TimeZone->new( name => 'local' );
	my $error = 0;
	my $opt = 
	{
	pattern   => '%Y-%m-%d %T',
	locale    => 'en_GB',
	time_zone => $tz->name,
	on_error => sub{ $error++ },
	};
	$self->message( 3, "Checking timestamp string '$str' for appropriate pattern" );
	## 2019-06-19 23:23:57.000000000+0900
	## From PostgreSQL: 2019-06-20 11:02:36.306917+09
	## ISO 8601: 2019-06-20T11:08:27
	if( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})(?:\.\d+)?((?:\+|\-)\d{2,4})?/ )
	{
		my( $date, $time, $zone ) = ( "$1-$2-$3", $4, $5 );
		if( !length( $zone ) )
		{
			my $dt = DateTime->now( time_zone => $tz );
			my $offset = $dt->offset;
			## e.g. 9 or possibly 9.5
			my $offset_hour = ( $offset / 3600 );
			## e.g. 9.5 => 0.5 * 60 = 30
			my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
			$zone  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
		}
		$self->message( 3, "\tMatched pattern #1 with date '$date', time '$time' and time zone '$zone'." );
		$date =~ tr/\//-/;
		$zone .= '00' if( length( $zone ) == 3 );
		$str = "$date $time$zone";
		$self->message( 3, "\tChanging string to '$str'" );
		$opt->{pattern} = '%Y-%m-%d %T%z';
	}
	## From SQLite: 2019-06-20 02:03:14
	## From MySQL: 2019-06-20 11:04:01
	elsif( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})/ )
	{
		my( $date, $time ) = ( "$1-$2-$3", $4 );
		$self->message( 3, "\tMatched pattern #2 with date '$date', time '$time' and without time zone." );
		my $dt = DateTime->now( time_zone => $tz );
		my $offset = $dt->offset;
		## e.g. 9 or possibly 9.5
		my $offset_hour = ( $offset / 3600 );
		## e.g. 9.5 => 0.5 * 60 = 30
		my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
		my $offset_str  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
		$date =~ tr/\//-/;
		$str = "$date $time$offset_str";
		$self->message( 3, "\tAdding time zone '", $tz->name, "' offset of $offset_str with result: '$str'." );
		$opt->{pattern} = '%Y-%m-%d %T%z';
	}
	elsif( $str =~ /^(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})$/ )
	{
		$str = "$1-$2-$3";
		$self->message( 3, "\tMatched pattern #3 with date '$date' only." );
		$opt->{pattern} = '%Y-%m-%d';
	}
	my $strp = DateTime::Format::Strptime->new( %$opt );
	my $dt = $strp->parse_datetime( $str );
	return( $dt );
}

## Private function
sub _ceiling
{
    my $self = shift( @_ );
    my @args = @_;
    $self->message( 3, "Getting ceil for ", join( ', ', @args ) );
    return( POSIX::ceil( $args[0] ) );
}

sub _concat
{
    my $self = shift( @_ );
    my @args = @_;
    return( join( '', @args ) );
}

sub _curdate
{
    my $self = shift( @_ );
    my @args = @_;
    my $tz = DateTime::TimeZone->new( 'name' => 'local' );
    my $d = DateTime->from_epoch( 'epoch' => time(), 'time_zone' => $tz->name );
    return( $d->ymd( '-' ) );
}

sub _curtime
{
    my $self = shift( @_ );
    my @args = @_;
    my $tz = DateTime::TimeZone->new( name => 'local' );
    my $d = DateTime->now( time_zone => $tz->name );
    return( $d->hms( ':' ) );
}

## e.g. Monday
sub _dayname
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_name );
}

## E.g.: 17
sub _dayofmonth
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day );
}

## timestamp, [integer] 1 to 7
sub _dayofweek
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_of_week );
}

## E.g.: 170
sub _dayofyear
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_of_year );
}

## http://stackoverflow.com/questions/10034636/postgres-longitude-longitude-query
sub _distance_miles
{
    my $self = shift( @_ );
    my @args = @_;
    my( $lat1, $lon1, $lat2, $lon2 ) = @args;
    my $x = 69.1 * ( $lat2 - $lat1 );
    my $y = 69.1 * ( $lon2 - $lon1 ) * cos( $lat1 / 57.3 );
    return( sqrt( $x * $x + $y * $y ) );
}

sub _from_days
{
    my $self = shift( @_ );
    my @args = @_;
    my $from_days = $args[0];
	my $tz = DateTime::TimeZone->new( name => 'local' );
	my $origin = DateTime->new(
		year       => 0,
		month      => 1,
		day        => 1,
		hour       => 0,
		minute     => 0,
		second     => 0,
		time_zone => $tz->name,
	);
	my $epoch = DateTime->from_epoch( epoch => 0, time_zone => $tz->name );
	## https://stackoverflow.com/questions/821423/how-can-i-calculate-the-number-of-days-between-two-dates-in-perl#7111718
	my $epoch_days = $epoch->delta_days( $origin )->delta_days();
	my $days_since_epoch = $from_days - int( $epoch_days );
	my $dt = DateTime->from_epoch( epoch => ( $days_since_epoch * 86400 ), time_zone => $tz->name );
	return( $dt );
}

sub _from_unixtime
{
    my $self = shift( @_ );
    my @args = @_;
    return if( $args[0] !~ /^\d+$/ );
    my $dt = DateTime->from_epoch( 'epoch' => $args[0], time_zone => 'local' );
    return( $dt->strftime( '%Y-%m-%d %T%z' ) );
}

sub _hour
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->hour );
}

sub _lcase
{
    my $self = shift( @_ );
    my @args = @_;
    return( lc( $args[0] ) );
}

sub _left
{
    my $self = shift( @_ );
    my @args = @_;
    return( $args[0] ) if( $args[1] !~ /^\d+$/ );
    return( substr( $args[0], 0, $args[1] ) );
}

sub _locate
{
    my $self = shift( @_ );
    my @args = @_;
    return( CORE::index( $args[0], $args[1] ) );
}

sub _log10
{
    my $self = shift( @_ );
    my @args = @_;
    return( log( $args[0] ) / log( 10 ) );
}

sub _minute
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->minute );
}

sub _month
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->month );
}

sub _monthname
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->month_name );
}

sub _number_format
{
    my $self = shift( @_ );
    my @args = @_;
    my( $num, $tho, $dec, $prec ) = @args;
    $self->message( 3, "Number to format '$num' with thousand separator '$tho', decimal separator '$dec' and precision '$prec'." );
    my $fmt = Number::Format->new(
    	-thousands_sep	=> $tho,
		-decimal_point	=> $dec,
		-decimal_digits	=> $prec,
    );
    ## 1 means with trailing zeros
    return( $fmt->format_number( $num, $prec, 1 ) );
}

## 1000 produces 001,000
sub _number_format_v1_not_working
{
    my $self = shift( @_ );
    my @args = @_;
    my( $num, $tho, $dec, $prec ) = @args;
    my $sign = ( $num <=> 0 );
    $num     = abs( $num ) if( $sign < 0 );
    my $mul  = ( 10 ** $prec );
    my $res  = abs( $num );
    $res     = ( int( ( $res * $mul ) + .5000001 ) / $mul );
    ## $num     = -$res if( $sign < 0 );
    $res     = -$res if( $sign < 0 );
    $num     = $res;
    my $int  = int( $num );
    my $decimal;
    $decimal  = substr( $num, length( $int ) + 1 ) if( length( $int ) < length( $num ) );
    $decimal  = '' unless( defined( $decimal ) );
    ## $decimal .= ''0'' x ( $prec - length( $decimal ) ) if( $prec > length( $decimal ) );
    $int      = '0' x ( 3 - ( length( $int ) % 3 ) ) . $int;
    $int      = join( $tho, grep{ $_ ne '' } split( /(...)/, $int ) );
    $int      =~ s/^0+\\Q$tho\\E?//;dd
    $int      = '0' if( $int eq '' );
    $res      = ( ( defined( $decimal ) && length( $decimal ) ) ? join( $dec, $int, $decimal ) : $int );
    ## $res      =~ s/^-//;
    return( ( $sign < 0 ) ? "-$res" : $res );
}

sub _power
{
    my $self = shift( @_ );
    my @args = @_;
    return( CORE::exp( $args[ 1 ] * CORE::log( $args[ 0 ] ) ) );
}

sub _quarter
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->quarter );
}

sub _rand
{
    my $self = shift( @_ );
    my @args = @_;
    return( CORE::rand() );
}

sub _regexp
{
    my $self = shift( @_ );
    my @args = @_;
    my( $re, $what ) = @args;
    return( $what =~ /$re/ );
}

sub _replace
{
    my $self = shift( @_ );
    my @args = @_;
    my( $str, $from, $to ) = @args;
    $str =~ s/($from)/$to/gs;
    return( $str );
}

sub _right
{
    my $self = shift( @_ );
    my @args = @_;
    return( CORE::substr( $args[0], CORE::length( $args[0] ) - $args[1] ) );
}

sub _second
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->second );
}

sub _space
{
    my $self = shift( @_ );
    my @args = @_;
    return( ' ' x CORE::int( $args[0] ) );
}

sub _sprintf
{
    my $self = shift( @_ );
    my @args = @_;
    $self->message( 3, "sprintf formatting with parameters: '", join( "', '", @args ), "'" );
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
    	$args[$i] =~ s/'/\\'/g;
    }
    my $eval = "CORE::sprintf( '" . join( "', '", @args ) . "' )";
    $self->message( 3, "\t evaluating with '$eval'." );
    my $res = eval( $eval );
    $self->message( 3, "\t returning '$res'." );
    ## return( CORE::sprintf( @args ) );
    return( $res );
}

sub _to_days
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
	my $tz = DateTime::TimeZone->new( name => 'local' );
	my $origin = DateTime->new(
		year       => 0,
		month      => 1,
		day        => 1,
		hour       => 0,
		minute     => 0,
		second     => 0,
		time_zone => $tz->name,
	);
    ## https://stackoverflow.com/questions/821423/how-can-i-calculate-the-number-of-days-between-two-dates-in-perl#7111718
	my $days = $dt->delta_days( $origin )->delta_days();
	return( $days );
}

# sub _truncate
# {
#     my $self = shift( @_ );
#     my @args = @_;
#     return if( $args[1] !~ /^\-?\d+$/ );
#     return( CORE::substr( $args[0], 0, $args[1] ) );
# }

sub _ucase
{
    my $self = shift( @_ );
    my @args = @_;
    return( uc( $args[0] ) );
}

sub _unix_timestamp
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->epoch );
}

sub _week
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->week_number );
}

sub _weekday
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_of_week );
}

sub _year
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->year );
}

DESTROY
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    if( $self->{ 'sth' } )
    {
        ## $self->message( "DETROY(): Terminating sth '$self' for query:\n$self->{ 'query' }\n" );
        print( STDERR "DESTROY(): Terminating sth '$self' for query:\n$self->{ 'query' }\n" ) if( $DEBUG );
        $self->{ 'sth' }->finish();
    }
    elsif( $self->{ 'dbh' } && $class =~ /^AI\:\:DB\:\:Postgres$/ )
    {
        local( $SIG{ '__WARN__' } ) = sub { };
        ## $self->{ 'dbh' }->disconnect();
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
    ## foreach my $dbh ( @DBH )
    ## {
    ##     $dbh->disconnect();
    ## }
};

1;

__END__
=encoding utf8

=head1 NAME

DB::Object::Postgres - SQL API

=head1 SYNOPSIS

    use DB::Object::Postgres;

    my $db = DB::Object::Postgres->new();
    my $dbh = DB::Object::Postgres->connect();
    
    my $sth = $dbh->prepare( "SELECT login,name FROM login WHERE login='jack'" ) ||
    die( $dbh->errstr() );
    $sth->execute() || die( $sth->errstr() );
    my $ref = $sth->fetchrow_hashref();
    $sth->finish();
    
    ## Get the table 'login' object
    my $login = $dbh->login();
    $login->where( "login='jack'" );
    ## Now, much better less hassle ;-)
    my $ref = $login->select->fetchrow_hashref();
    
    ## Now let's join
    my $login = $dbh->login();
    $login->where( "login='jack'" );
    ## We get all info regarding user jack and his list
    my $ref = $login->select->join( 'list' )->fetchrow_hashref();
    
    ## Same but we give it a higher priority. Having fun obviously...
    my $ref = $login->select->join( 'list' )->priority( 1 )->fetchrow_hashref();
    
    ## Copy user jack info to user bob
    $login->where( "login='jack'" );
    $login->copy( 'login' => 'bob' );
    
    ## Insert some data. Anything we do not provide will fall back to default values
    $login->insert( 'login' => 'bob' );
    ## Same but with a low *non waiting* flag
    $login->insert( 'login' => 'bob' )->wait();
    ## Same but ignore if already exists or error occur
    $login->insert( 'login' => 'jack' )->ignore();
    
    ## Get the last used insert id
    my $id = $dbh->last_insert_id();
    
    ## Delete that user
    ## you'd better specify a where clause or you'll find yourself
    ## suppressing everything in the table...
    $login->where( "login='bob'" );
    $login->delete();
    ## But you could also write
    my $rows = $login->delete( "login='bob'" )->rows();
    
    ## Make a query but get the qery string instead of performing it in real
    $login->where( "login like 'jac%'" );
    $login->limit( 10 );
    $login->group( 'last_name' );
    $login->order( 'last_name' );
    ## Reverse sorting
    $login->reverse();
    print( STDOUT "Here is my SQL statement:\n",
    $login->select->join( 'list' )->priority( 1 )->as_string() );
    
    ## Lets' dump the result of our query
    ## First to STDERR
    $login->where( "login='jack'" );
    $login->select->dump();
    ## Now dump the result to a file
    $login->select->dump( "my_file.txt" );
    
    ## Get that table 'login' structure
    my $data = $login->structure();
    
    ## Some info on the status of the SQL server
    my $status_ref = $dbh->stat();
    ## or (it does not matter)
    my $status_ref = $login->stat();
    ## optimize the table, i.e. claim for free space and cleanups
    $login->optimize();

=head1 DESCRIPTION

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

=over 4

=item B<new>()

Create a new instance of L<DB::Object::Postgres>. Nothing much to say.

=item B<connect>( DATABASE, LOGIN, PASSWORD, SERVER, DRIVER )

Create a new instance of L<DB::Object::Postgres>, but also attempts a conection
to SQL server.

You can specify the following arguments:

=over 8

=item I<DATABASE>

The database name you wish to connect to

=item I<LOGIN>

The login used to access that database

=item I<PASSWORD>

The password that goes along

=item I<SERVER>

The server, that is hostname of the machine serving a SQL server.

=item I<DRIVER>

The driver you want to use. It needs to be of the same type than the server
you want to connect to. If you are connecting to a MySQL server, you would use
C<mysql>, if you would connecto to an Oracle server, you would use C<oracle>.

You need to make sure that those driver are properly installed in the system 
before attempting to connect.

To install the required driver, you could start with the command line:

    perl -MCPAN -e shell

which will provide you a special shell to install modules in a convenient way.

=back

=back

=head1 METHODS

=over 4

=item B<clear>()

Reset error message.

=item B<debug>( [ 0 | 1 ] )

Toggle debug mode on/off

=item B<error>( [ $string ] )

Get set error message.
If an error message is provided, B<error> will pass it to B<warn>.

=item B<get>( $parameter )

Get object parameter.

=item B<message>( $string )

Provided a multi line string, B<message> will display it on the STDERR if either I<verbose> or I<debug> mode is on.

=item B<verbose>()

Toggle verbose mode on/off

=item B<alias>( %parameters )

Get/set alias for table fields in SELECT queries. The hash provided thus contain a list of field => alias pairs.

=item B<as_string>()

Return the sql query as a string.

=item B<avoid>( [ @fields | \@fields ] )

Set the provided list of table fields to avoid when returning the query result.
The list of fields can be provided either as an array of a reference to an array.

=item B<attribute>( $name | %names )

Sets or get the value of database connection parameters.

If only one argument is provided, returns its value.
If multiple arguments in a form of pair => value are provided, it sets the corresponding database parameters.

The authorised parameters are:

=over 8

=item I<Warn>

Can be overridden.

=item I<Active>

Read-only.

=item I<Kids>

Read-only.

=item I<ActiveKids>

Read-only.

=item I<CachedKids>

Read-only.

=item I<InactiveDestroy>

Can be overridden.

=item I<PrintError>

Can be overridden.

=item I<RaiseError>

Can be overridden.

=item I<ChopBlanks>

Can be overridden.

=item I<LongReadLen>

Can be overridden.

=item I<LongTruncOk>

Can be overridden.

=item I<AutoCommit>

Can be overridden.

=item I<Name>

Read-only.

=item I<RowCacheSize>

Read-only.

=item I<NUM_OF_FIELDS>

Read-only.

=item I<NUM_OF_PARAMS>

Read-only.

=item I<NAME>

Read-only.

=item I<TYPE>

Read-only.

=item I<PRECISION>

Read-only.

=item I<SCALE>

Read-only.

=item I<NULLABLE>

Read-only.

=item I<CursorName>

Read-only.

=item I<Statement>

Read-only.

=item I<RowsInCache>

Read-only.

=back

=item B<available_drivers>()

Return the list of available drivers.

=item B<bind>( [ @values ] )

If no values to bind to the underlying query is provided, B<bind> simply activate the bind value feature.

If values are provided, they are allocated to the statement object and will be applied when the query will be executed.

Example:

  $dbh->bind()
  ## or
  $dbh->bind->where( "something" )
  ## or
  $dbh->bind->select->fetchrow_hashref()
  ## and then later
  $dbh->bind( 'thingy' )->select->fetchrow_hashref()

=item B<cache>()

Activate caching.

  $tbl->cache->select->fetchrow_hashref();

=item B<check_driver>()

Check that the driver set in I<$SQL_DRIVER> in ~/etc/common.cfg is indeed available.

It does this by calling B<available_drivers>.

=item B<copy>( [ \%values | %values )

Provided with either a reference to an hash or an hash of key => value pairs, B<copy> will first execute a select statement on the table object, then fetch the row of data, then replace the key-value pair in the result by the ones provided, and finally will perform an insert.

Return false if no data to copy were provided, otherwise it always returns true.

=item B<create_table>( @parameters )

The idea is to create a table with the givern parameters.

This is currently heavily designed to work for PoPList. It needs to be rewritten.

=item B<data_sources>( [ %options ] )

Given an optional list of options, this return the data source of the database handler.

=item B<data_type>( [ \@types | @types ] )

Given a reference to an array or an array of data type, B<data_type> will check their availability in the database driver.

If nothing found, it return an empty list in list context, or undef in scalar context.

If something was found, it returns a hash in list context or a reference to a hash in list context.

=item B<database>()

Return the name of the current database.

=item B<delete>()

B<delete> will format a delete query based on previously set parameters, such as B<where>.

B<delete> will refuse to execute a query without a where condition. To achieve this, one must prepare the delete query on his/her own by using the B<do> method and passing the sql query directly.

  $tbl->where( "login" => "jack" );
  $tbl->limit( 1 );
  my $rows_affected = $tbl->delete();
  ## or passing the where condition directly to delete
  my( $sth ) = $tbl->delete( "login" => "jack" );

=item B<disconnect>()

Disconnect from database. Returns the return code.

  my $rc = $dbh->disconnect;

=item B<do>( $sql_query, [ \%attributes, \@bind_values ] )

Execute a sql query directly passed with possible attributes and values to bind.

The attributes list will be used to B<prepare> the query and the bind values will be used when executing the query.

It returns the statement handler or the number of rows affected.

Example:

  $rc  = $dbh->do( $statement ) || die( $dbh->errstr );
  $rc  = $dbh->do( $statement, \%attr ) || die( $dbh->errstr );
  $rv  = $dbh->do( $statement, \%attr, @bind_values ) || die( $dbh->errstr );
  my( $rows_deleted ) = $dbh->do(
  q{
       DELETE FROM table WHERE status = ?
  }, undef(), 'DONE' ) || die( $dbh->errstr );

=item B<enhance>( [ @value ] )

Toggle the enhance mode on/off.

When on, the functions I<from_unixtime> and I<unix_timestamp> will be used on date/time field to translate from and to unix time seamlessly.

=item B<err>()

Get the currently set error.

=item B<errno>()

Is just an alias for B<err>.

=item B<errmesg>()

Is just an alias for B<errstr>.

=item B<errstr>()

Get the currently set error string.

=item B<fatal>( [ 1 | 0 ] )

Toggles fatal mode on/off.

=item B<from_unixtime>( [ @fields | \@fields ] )

Set the list of fields that are to be treated as unix time and converted accordingly after the sql query is executed.

It returns the list of fields in list context or a reference to an array in scalar context.

=item B<format_statement>( [ \@data, \@order, $table ] )

Format the sql statement.

In list context, it returns 2 strings: one comma-separated list of fields and one comma-separated list of values. In scalar context, it only returns a comma-separated string of fields.

=item B<format_update>( \@data | \%data | %data | @data )

Formats update query based on the following arguments provided:

=over 8

=item I<data>

An array of key-value pairs to be used in the update query. This array can be provided as the prime argument as a reference to an array, an array, or as the I<data> element of a hash or a reference to a hash provided.

Why an array if eventually we build a list of key-value pair? Because the order of the fields may be important, and if the key-value pair list is provided, B<format_update> honors the order in which the fields are provided.

=back

B<format_update> will then iterate through each field-value pair, and perform some work:

If the field being reviewed was provided to B<from_unixtime>, then B<format_update> will enclose it in the function FROM_UNIXTIME() as in:

  FROM_UNIXTIME(field_name)
  
If the the given value is a reference to a scalar, it will be used as-is, ie. it will not be enclosed in quotes or anything. This is useful if you want to control which function to use around that field.


If the given value is another field or looks like a function having parenthesis, or if the value is a question mark, the value will be used as-is.

If B<bind> is off, the value will be escaped and the pair field='value' created.

If the field is a SET data type and the value is a number, the value will be used as-is without surrounding single quote.

If B<bind> is enabled, a question mark will be used as the value and the original value will be saved as value to bind upon executing the query.

Finally, otherwise the value is escaped and surrounded by single quotes.

B<format_update> returns a string representing the comma-separated list of fields that will be used.

=item B<getdefault>( %default_values )

Does some preparation work such as :

=over 8

=item 1

the date/time field to use the FROM_UNIXTIME and UNIX_TIMESTAMP functions

=item 2

removing from the query the fields to avoid, ie the ones set with the B<avoid> method.

=item 3

set the fields alias based on the information provided with the B<alias> method.

=item 4

if a field last_name and first_name exist, it will also create an alias I<name> based on the concatenation of the 2.

=item 5

it will set the default values provided. This is used for UPDATE queries.

=back

It returns a new L<DB::Object::Postgres::Tables> object with all the data prepared within.

=item B<group>( @fields | \@fields )

Format the group by portion of the query.

It returns an empty list in list context of undef in scalar context if no group by clause was build.
Otherwise, it returns the value of the group by clause as a string in list context and the full group by clause in scalar context.

In list context, it returns: $group_by

In scalar context, it returns: GROUP BY $group_by

=item B<insert>( L<DB::Object::Postgres::Statement> SELECT object, \%key_value | %key_value )

Prepares an INSERT query using the field-value pairs provided.

If a L<DB::Object::Postgres::Statement> object is provided as first argument, it will considered as a SELECT query to be used in the INSERT query, as in: INSERT INTO my table SELECT FROM another_table

Otherwise, B<insert? will build the query based on the fields provided.

In scalar context, it returns the result of B<execute> and in list context, it returns the statement object.

=item B<last_insert_id>()

Get the id of the primary key from the last insert.

=item B<limit>( [ END, [ START, END ] ] )

Set or get the limit for the future statement.

If only one argument is provided, it is assumed to be the end limit. If 2 are provided, they wil be the start and end.

It returns a list of the start and end limit in list context, and the string of the LIMIT in scalar context, such as: LIMIT 1, 10

=item B<local>( %params | \%params )

Not sure what it does. I forgot.

=item B<lock>( $lock_id, [ $timeout ] )

Set a lock using a lock identifier and a timeout.
By default the timeout is 2 seconds.

If the lock failed (NULL), it returns undef(), otherwise, it returns the return value.

=item B<no_bind>()

When invoked, B<no_bind> will change any preparation made so far for caching the query with bind parameters, and instead substitute the value in lieu of the question mark placeholder.

=item B<no_cache>()

Disable caching of queries.

=item B<order>()

Prepares the ORDER BY clause and returns the value of the clause in list context or the ORDER BY clause in full in scalar context, ie. "ORDER BY $clause"

=item B<param>( $param | %params )

If only a single parameter is provided, its value is return. If a list of parameters is provided they are set accordingly using the C<SET> sql command.

Supported parameters are:

=over 8

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

=item B<ping>()

Evals a SELECT 1 statement and returns 0 if errors occurred or the return value.

=item B<prepare>( $query, \%options )

Prepares the query using the options provided. The options are the same as the one in L<DBI> B<prepare> method.

It returns a L<DB::Object::Postgres::Statement> object upon success or undef if an error occurred. The error can then be retrieved using B<errstr> or B<error>.

=item B<prepare_cached>( $query, \%options )

Same as B<prepare> except the query is cached.

=item B<query>( $query, \%options )

It prepares and executes the given SQL query with the options provided and return undef() upon error or the statement handler upon success.

=item B<replace>( L>DB::Object::Postgres::Statement> object, [ %data ] )

Just like for the INSERT query, B<replace> takes one optional argument representing a L<DB::Object::Postgres::Statement> SELECT object or a list of field-value pairs.

If a SELECT statement is provided, it will be used to construct a query of the type of REPLACE INTO mytable SELECT FROM other_table

Otherwise the query will be REPLACE INTO mytable (fields) VALUES(values)

In scalar context, it execute the query and in list context it simply returns the statement handler.

=item B<reset>()

This is used to reset a prepared query to its default values. If a field is a date/time type, its default value will be set to NOW()

It execute an update with the reseted value and return the number of affected rows.

=item B<reverse>( [ true ])

Get or set the reverse mode.

=item B<select>( [ \$field, \@fields, @fields ] )

Given an optional list of fields to fetch, B<select> prepares a SELECT query.

If no field was provided, B<select> will use default value where appropriate like the NOW() for date/time fields.

B<select> calls upon B<tie>, B<where>, B<group>, B<order>, B<limit> and B<local> to build the query.

In scalar context, it execute the query and return it. In list context, it just returns the statement handler.

=item B<set>( $var )

Issues a query to C<SET> the given SQL variable.

If any error occurred, undef will be returned and an error set, otherwise it returns true.

=item B<sort>()

It toggles sort mode on and consequently disable reverse mode.

=item B<stat>( [ $type ] )

Issue a SHOW STATUS query and if a particular $type is provided, it will returns its value if it exists, otherwise it will return undef.

In absence of particular $type provided, it returns the hash list of values returns or a reference to the hash list in scalar context.

=item B<state>()

Queries the DBI state and return its value.

=item B<table>( $table_name )

Given a table name, B<table> will return a L<DB::Object::Postgres::Tables> object. The object is cached for re-use.

=item B<table_push>( $table_name )

Add the given table name to the stack of cached table names.

=item B<tables>( [ $database ] )

Connects to the database and finds out the list of all available tables.

Returns undef or empty list in scalar or list context respectively if no table found.

Otherwise, it returns the list of table in list context or a reference of it in scalar context.

=item B<tables_refresh>( [ $database ] )

Rebuild the list of available database table.

Returns the list of table in list context or a reference of it in scalar context.

=item B<tie>( [ %fields ] )

If provided a hash or a hash ref, it sets the list of fields and their corresponding perl variable to bind their values to.

In list context, it returns the list of those field-variable pair, or a reference to it in scalar context.

=item B<unix_timestamp>( [ \@fields | @fields ] )

Provided a list of fields or a reference to it, this sets the fields to be treated for seamless conversion from and to unix time.

=item B<unlock>( $lock_id )

Given a lock identifier, B<unlock> releases the lock previously set with B<lock>. It executes the underlying sql command and returns undef() if the result is NULL or the value returned otherwise.

=item B<update>( %data | \%data )

Given a list of field-value pairs, B<update> prepares a sql update query.

It calls upon B<where> and B<limit> as previously set.

It returns undef and sets an error if it failed to prepare the update statement. In scalar context, it execute the query. In list context, it simply return the statement handler.

=item B<use>( $database )

Given a database, it switch to it, but before it checks that the database exists.
If the database is different than the current one, it sets the I<multi_db> parameter, which will have the fields in the queries be prefixed by their respective database name.

It returns the database handler.

=item B<use_cache>( [ on | off ] )

Sets or get the I<use_cache> parameter.

=item B<use_bind>( [ on | off ] )

Sets or get the I<use_cache> parameter.

=item B<variables>( [ $type ] )

Query the SQL variable $type

It returns a blank string if nothing was found, or the value found.

=item B<where>( %args )

Build the where clause based on the field-value hash provided.

It returns the where clause in list context or the full where clause in scalar context, ie "WHERE $clause"

=item B<_cache_this>( $query )

Provided with a query, this will cache it for future re-use.

It does some check and maintenance job to ensure the cache does not get too big whenever it exceed the value of $CACHE_SIZE set in the main config file.

It returns the cached statement as an L<DB::Object::Postgres::Statement> object.

=item B<_clean_statement>( \$query | $query )

Given a query string or a reference to it, it cleans the statement by removing leading and trailing space before and after line breaks.

=item B<_cleanup>()

Removes object attributes, namely where, selected_fields, group_by, order_by, limit, alias, avoid, local, and as_string

=item B<_make_sth>( $package, $hashref )

Given a package name and a hashref, this build a statement object with all the necessary parameters.

It also sets the query time to the current time with the parameter I<query_time>

It returns an object of the given $package.

=item B<_reset_query>()

Being called using a statement handler, this reset the object by removing all the parameters set by various subroutine calls, such as B<where>, B<group>, B<order>, B<avoid>, B<limit>, etc.

=item B<_save_bind>( $query_type )

This saves/cache the bin query and return the object used to call it.

=item B<_value2bind>( $query, $ref )

Given a sql query and a array reference, B<_value2bind> parse the query and interpolate values for placeholder (?).

It returns true.

=back

=head1 COPYRIGHT

Copyright (c) 2000-2014 DEGUEST Pte. Ltd.

=head1 CREDITS

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DBI>, L<Apache::DBI>

=cut

