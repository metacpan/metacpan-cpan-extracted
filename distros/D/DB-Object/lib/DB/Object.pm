# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object.pm
## Version 0.9.2
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2020/03/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This is the subclassable module for driver specific ones.
package DB::Object;
BEGIN
{
    require 5.6.0;
    use strict;
    use parent qw( Module::Generic DBI );
    use IO::File;
    use File::Spec;
    use Scalar::Util qw( blessed );
    require DB::Object::Statement;
    require DB::Object::Tables;
    use DB::Object::Cache::Tables;
    use DBI;
    use JSON;
    use POSIX ();
    use Want;
    ## DBI->trace( 5 );
    our( $VERSION, $DB_ERRSTR, $ERROR, $DEBUG, $CONNECT_VIA, $CACHE_QUERIES, $CACHE_SIZE );
    our( $CACHE_TABLE, $USE_BIND, $USE_CACHE, $MOD_PERL, @DBH, $CACHE_DIR );
    our( $CONSTANT_QUERIES_CACHE );
    $VERSION     = '0.9.2';
    use Devel::Confess;
};

{
    $DB_ERRSTR     = '';
    $DEBUG         = 0;
    $CACHE_QUERIES = [];
    $CACHE_SIZE    = 10;
    $CACHE_TABLE   = {};
    $USE_BIND      = 0;
    $USE_CACHE     = 0;
    $MOD_PERL      = 0;
    @DBH           = ();
    $CACHE_DIR	   = '';
    $CONSTANT_QUERIES_CACHE = {};
    if( $INC{ 'Apache/DBI.pm' } && 
        substr( $ENV{ 'GATEWAY_INTERFACE' }|| '', 0, 8 ) eq 'CGI-Perl' )
    {
        $CONNECT_VIA = "Apache::DBI::connect";
        $MOD_PERL++;
    }
    our $DRIVER2PACK = 
    {
    'mysql'		=> 'DB::Object::Mysql',
    'Pg'		=> 'DB::Object::Postgres',
    'SQLite'	=> 'DB::Object::SQLite',
    };
}

sub new
{
    my $that  = shift( @_ );
    my $class = ref( $that ) || $that;
    my $self  = {};
    bless( $self, $class );
    return( $self->init( @_ ) );
}

sub init
{
	my $self = shift( @_ );
	$self->{ 'cache_connections' } = 1;
	$self->{ 'cache_dir' } = File::Spec->tmpdir();
	$self->{ 'driver' } = '';
	## Auto-decode json data into perl hash
	$self->{ 'auto_decode_json' } = 1;
	$self->{ 'auto_convert_datetime_to_object' } = 0;
	$self->{ 'allow_bulk_delete' } = 0;
	$self->{ 'allow_bulk_update' } = 0;
	$self->Module::Generic::init( @_ );
	# $self->{ 'constant_queries_cache' } = $DB::Object::CONSTANT_QUERIES_CACHE;
	return( $self );
}

##----{ End of generic routines }----##

##----{ ROUTINES PROPRIETAIRE }----##
## Get/set alias
sub alias
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->alias( @_ ) );
}

sub allow_bulk_delete { return( shift->_set_get_scalar( 'allow_bulk_delete', @_ ) ); }

sub allow_bulk_update { return( shift->_set_get_scalar( 'allow_bulk_update', @_ ) ); }

sub AND { shift( @_ ); return( DB::Object::AND->new( @_ ) ); }

## This should be in the DB::Object::Statement package. Not much reason to have it here really
# sub as_string
# {
#     my $self = shift( @_ );
#     ## my $q = $self->_query_object_current;
#     ## used by select, insert, update, delete to flag that we need to reformat the query
#     $self->{ 'as_string' }++;
#     ## return( $self->{ 'sth' }->{ 'Statement' } );
#     ## Same:
#     ## return( $q->as_string );
#     return( $self->{ 'query' } );
# }

sub auto_convert_datetime_to_object { return( shift->_set_get_scalar( 'auto_convert_datetime_to_object', @_ ) ); }

sub auto_decode_json { return( shift->_set_get_scalar( 'auto_decode_json', @_ ) ); }

sub avoid
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->avoid( @_ ) );
}

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
    'Warn'					=> 1, 
    'Active'				=> 0, 
    'Executed'				=> 0,
    'Kids'					=> 0, 
    'ActiveKids'			=> 0, 
    'CachedKids'			=> 0,
    'Type'					=> 0,
    'ChildHandles'			=> 0,
    'CompatMode'			=> 1,
    'InactiveDestroy'		=> 1, 
    'AutoInactiveDestroy'	=> 1,
    'PrintWarn'				=> 1,
    'PrintError'			=> 1,
    'RaiseError'			=> 1, 
    'HandleError'			=> 1,
    'HandleSetErr'			=> 1,
    'ErrCount'				=> 0,
    'ShowErrorStatement'	=> 1,
    'TraceLevel'			=> 1,
    'FetchHashKeyName'		=> 0,
    'ChopBlanks'			=> 1, 
    'LongReadLen'			=> 1, 
    'LongTruncOk'			=> 1, 
    'TaintIn'				=> 1,
    'TaintOut'				=> 1,
    'Taint'					=> 1,
    'Profile'				=> 0,
    'ReadOnly'				=> 1,
    'Callbacks'				=> 1,
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
    'RowsInCache'			=> 0 
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

sub available_drivers(@)
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    ## @ary = DBI->available_drivers( $quiet );
    return( $class->SUPER::available_drivers( 1 ) );
}

sub base_class
{
	my $self = shift( @_ );
    my @supported_classes = $self->supported_class;
    push( @supported_classes, 'DB::Object' );
    my $ok_classes = join( '|', @supported_classes );
    my $class = ref( $self ) ? ref( $self ) : $self;
    my $base_class = ( $class =~ /^($ok_classes)/ )[0];
    return( $base_class );
}

## This method is common to DB::Object and DB::Object::Statement
sub bind
{
    my $self = shift( @_ );
    ## Usage:
    ## This activate the binding stuff
    ## $dbh->bind() or $dbh->bind->where( "something" ) or $dbh->bind->select->fetchrow_hashref();
    ## Later, $dbh->bind( 'thingy' )->select->fetchrow_hashref()
    ## When used like $table->bind; this means the user is setting the use bind option as a setting for all transactions, but
    ## when used like $table->bind->select then the use bind option is only used for this transaction only and is reset after
    $self->{bind} = Want::want('VOID') 
    	? 2 
    	## Otherwise is it already set maybe?
    	: $self->{bind} 
    		## Then use it
    		? $self->{bind} 
    		: 1;
    if( @_ )
    {
        ## If we are using the cache system, we search the object of this query
        my $obj = '';
        ## Ensure that we have something to look for at the least
        ## my $queries = $self->{ 'queries' };
        my $queries = $CACHE_QUERIES;
        my $base_class = $self->base_class;
        if( $self->isa( "${base_class}::Statement" ) )
        {
            $obj = $self;
        }
        elsif( $self->{cache} && @$queries )
        {
            $obj = $queries->[ 0 ];
        }
        ## Otherwise, our object is the statement object to use
        else
        {
            $obj = $self;
        }
        $obj->{binded} = [ @_ ];
        ## Since new binded parameters have been passed, since mean a new request to the
        ## same statement is pending, so we need to re-execute the statement
        ## and since most of the fetch method rely on AUTOLOAD that call
        ## execute() automatically *IF* the statement was not already executed....
        ## we need to delete 'executed' value or set it to false, so the statement gets re-executed
        $obj->{executed} = 0;
        return( $obj );
    }
    return( $self );
}

sub cache
{
    my $self = shift( @_ );
    ## activate cache
    ## So we may be called as: $tbl->cache->select->fetchrow_hashref();
    $self->{cache}++;
    return( $self );
}

sub cache_connections
{
	my $self = shift( @_ );
	$self->{ '_cache_connections' } = shift( @_ ) if( @_ );
	return( $self->{ '_cache_connections' } );
}

sub cache_dir { return( shift->_set_get_scalar( 'cache_dir', @_ ) ); }

sub cache_tables { return( shift->_set_get_object( 'cache_tables', 'DB::Object::Cache::Tables', @_ ) ); }

sub check_driver()
{
    my $self   = shift( @_ );
    ##----{ $SQL_DRIVER provient de 'common.cfg'
    my $driver = shift( @_ ) || $SQL_DRIVER;
    my $ok     = undef();
    local $_;
    my @drivers = $self->available_drivers();
    $self->message( 2, "Found available drivers: '", join( ', ', @drivers ), "'." );
    foreach( @drivers ) 
    {
        if( m/$driver/s )
        {
            $ok++;
            last;
        }
    }
    return( $ok );
}

sub connect
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    ## We pass the arguments so that debug and other init parameters can be set early
    my $that  = ref( $this ) ? $this : $this->Module::Generic::new( @_ );
    ## my $this  = { @_ };
    ## print( STDERR "${class}::connect() DEBUG is $DEBUG\n" );
    my $param = $that->_connection_params2hash( @_ ) || return( $self->error( "No valid connection parameters found" ) );
    ## print( STDERR $class, "::connect(): \$param is: ", $that->dumper( $param ), "\n" );
    my $driver2pack = 
    {
    'mysql'		=> 'DB::Object::Mysql',
    'Pg'		=> 'DB::Object::Postgres',
    'SQLite'	=> 'DB::Object::SQLite',
    };
    return( $that->error( "No driver was provided." ) ) if( !exists( $param->{ 'driver' } ) );
    if( !exists( $driver2pack->{ $param->{driver} } ) )
    {
    	return( $that->error( "Driver $param->{driver} is not supported." ) );
    }
    $that->message( 3, "Installing driver $param->{driver}" ) if( $param->{driver} );
    ## For example, will make this object a DB::ObjectD::Postgres object
    my $driver_class = $driver2pack->{ $param->{driver} };
    my $driver_module = $driver_class;
    $that->message( 3, "Loading database handler class $driver_class" );
    $driver_module =~ s|::|/|g;
    $driver_module .= '.pm';
    ## print( STDERR "${class}::connect() Requiring class '$driver_class' ($driver_module)\n" );
    eval
    {
#     	local $SIG{ '__DIE__' } = sub{ };
#     	local $SIG{ '__WARN__' } = sub{ };
		local $DEBUG;
    	require $driver_module;
    };
    $that->message( 3, "Getting object using class $driver_class" );
    ## print( STDERR "${class}::connect() eval error? '$@'\n" ) if( $self->{debug} );
    return( $that->error( "Unable to load module $driver_class ($driver_module): $@" ) ) if( $@ );
    my $self = $driver_class->new || die( "Cannot get object from package $driver_class\n" );
    ## $self->debug( 3 );
    $self->{debug} = CORE::exists( $param->{debug} ) ? CORE::delete( $param->{debug} ) : CORE::exists( $param->{Debug} ) ? CORE::delete( $param->{Debug} ) : $DEBUG;
    $self->{cache_dir} =  CORE::exists( $param->{cache_dir} ) ? CORE::delete( $param->{cache_dir} ) : CORE::exists( $that->{cache_dir} ) ?  $that->{cache_dir} : $CACHE_DIR;
    
    $param = $self->_check_connect_param( $param ) || return( undef() );
    $self->message( 3, "Connection parameters are: ", sub{ $self->dumper( $param ) } );
    my $opt = {};
    if( exists( $param->{opt} ) )
    {
		$opt = CORE::delete( $param->{opt} );
		$opt = $self->_check_default_option( $opt );
    }
    $self->message( 3, "\$param returned from _check_connect_param include: ", sub{ $self->dumper( $param ) } );
    ## print( STDERR ref( $self ), "::connect(): \$param is: ", $self->dumper( $param ), "\n" );
    $self->{database} = CORE::exists( $param->{database} ) ? CORE::delete( $param->{database} ) : CORE::exists( $param->{db} ) ? CORE::delete( $param->{db} ) : undef();
    $self->{host} = CORE::exists( $param->{host} ) ? CORE::delete( $param->{host} ) : CORE::exists( $param->{server} ) ? CORE::delete( $param->{server} ) : undef();
    $self->{port} = CORE::delete( $param->{port} );
    ## $self->{database} = CORE::delete( $param->{ 'db' } );
    $self->{login} = CORE::delete( $param->{login} );
    $self->{passwd} = CORE::delete( $param->{passwd} );
    $self->{driver} = CORE::delete( $param->{driver} );
    $self->{cache} = CORE::exists( $param->{use_cache} ) ? CORE::delete( $param->{use_cache} ) : $USE_CACHE;
    $self->{bind} = CORE::exists( $param->{use_bind} ) ? CORE::delete( $param->{use_bind} ) : $USE_BIND;
    $self->message( 3, "\$self contains: ", sub{ $self->dumper( $self ) } );
    
    ## If parameters starting with an upper case are provided, they are DBI database parameters
    #my @dbi_opts = grep( /^[A-Z][a-zA-Z]+/, keys( %$param ) );
    #@$opt{ @dbi_opts } = @$param{ @dbi_opts };
    
    $self->{drh} = $that->SUPER::install_driver( $self->{driver} ) if( $self->{driver} );
	$opt->{RaiseError} = 0 if( !CORE::exists( $opt->{RaiseError} ) );
	$opt->{AutoCommit} = 1 if( !CORE::exists( $opt->{AutoCommit} ) );
	$opt->{PrintError} = 0 if( !CORE::exists( $opt->{PrintError} ) );
    $self->{opt} = $opt;
    ## Debug( $DB, $LOGIN, $PASSWD, $SERVER, $DRIVER );
    ## return( DBI->connect( "$DRIVER:$DB:$SERVER", $LOGIN, $PASSWD, \%OPT ) );
    ## open( DEB, '>>/tmp/manager_db_debug.txt' );
    ## print( DEB "DB::Object::connect( '$driver:$db:$server', '$login', '$passwd', '$opt', 'undef()', '$CONNECT_VIA'\n" );
    ## close( DEB );
    $self->message( 3, "Calling _dbi_connect" );
    my $dbh = $self->_dbi_connect || return( undef() );
    $self->{dbh} = $dbh;
    $self->message( 3, "Database handler is: '$dbh'" );
    ## If we are not running under mod_perl, cleanup the database object handle in case it was not shutdown
    ## using the DESTROY, but also the END block
    push( @DBH, $dbh ) if( !$MOD_PERL );
    #$self->param(
    #  ## Do not allow SELECT that will take too long or too much resource, i.e. over 2Gb of data
    #  ## This is idiot proof mode
    #  'SQL_BIG_SELECTS'    => 0,
    #  ## SQL will abort if a DELETE or UPDATE is being executed w/o LIMIT nor WHERE clause
    #  'SQL_SAFE_MODE'    => 1,
    #);
    local $/ = "\n";
    my $tables = [];
    ## 1 day
    ## my $tbl_cache_timeout = 86400;
    my $host = $self->{host} || 'localhost';
    my $port = $self->{port} || 0;
    my $driver = $self->{driver};
    my $database = $self->database;
    my $cache_params = {};
    $cache_params->{cache_dir} = $self->{cache_dir} if( $self->{cache_dir} );
    $cache_params->{debug} = $self->{debug} if( $self->{debug} );
    $self->message( 3, "Parameters to cache handler are: ", sub{ $self->dumper( $cache_params ) } );
    my $cache_tables = DB::Object::Cache::Tables->new( $cache_params );
    $self->cache_tables( $cache_tables );
	$tables = $self->tables_info;
	$self->messagef( 3, "%d tables found for host '$host', driver '$driver', port '$port', and database '$database'.", scalar( @$tables ) );
	my $cache = 
	{
	host => $host,
	driver => $driver,
	port => $port,
	database => $database,
	tables => $tables,
	};
	if( !defined( $cache_tables->set( $cache ) ) )
	{
		warn( "Unable to write to tables cache: ", $cache_tables->error, "\n" );
	}
    return( $self );
}

# sub constant_queries_cache { return( shift->_set_get_hash( 'constant_queries_cache', @_ ) ); }
sub constant_queries_cache { return( $CONSTANT_QUERIES_CACHE ); }

sub constant_queries_cache_get
{
	my( $self, $def ) = @_;
	my $hash = $self->constant_queries_cache;
	## $self->messagef( 3, "%d elements in our constant query cache found.", scalar( keys( %$hash ) ) );
	return( $self->error( "Parameter provided must be a hash, but I got '$def'." ) ) if( ref( $def ) ne 'HASH' );
	foreach my $k ( qw( pack file line ) )
	{
		return( $self->error( "Parameter \"$k\" is missing from the hash." ) ) if( !CORE::length( $def->{ $k } ) );
	}
	my $key = CORE::join( '|', @$def{qw( pack file line )} );
	my $ref = $hash->{ $key };
	## $ts is thee timestamp of the file recorded at the time
	my $ts = $ref->{ts};
	## A DB::Object::Statement object
	my $qo = $ref->{query_object};
	return if( !CORE::length( $def->{file} ) );
	return if( !-e( $def->{file} ) );
	## $self->message( 3, "Is file \"$def->{file}\" modification time stamp '", ( CORE::stat( $def->{file} ) )[9], "' same as on record '$ts'? ", ( ( CORE::stat( $def->{file} ) )[9] == $ts ? 'yes' : 'no' ) );
	return if( ( CORE::stat( $def->{file} ) )[9] != $ts );
	return( $self->error( "Query object retrieved from constant query cache is void!" ) ) if( !$qo );
	return( $self->error( "Query object retrieved from constant query cache is not a DB::Object::Query object or one of its sub classes." ) ) if( !$self->_is_object( $qo ) || !$qo->isa( 'DB::Object::Query' ) );
	# $self->message( 3, "Is our current database \"", $self->database, "\" same as the one cached \"", $qo->database_object->database, "\" ?" );
	return if( $self->database ne $qo->database_object->database );
	## $self->message( 3, "query obejct retrieved is for table \"", $qo->table_object->name, "\" and the join_tables contains ", $qo->join_tables->length, " item(s)." );
	return( $self->_cache_this( $qo ) );
}

sub constant_queries_cache_set
{
	my( $self, $def ) = @_;
	my $hash = $self->constant_queries_cache;
	## $self->messagef( 3, "Storing following constant data to cache that has already %d entries: %s", scalar( keys( %$hash ) ), $self->dumper( $def, { depth => 1 } ) );
	foreach my $k ( qw( pack file line query_object ) )
	{
		return( $self->error( "Parameter \"$k\" is missing from the hash." ) ) if( !CORE::length( $def->{ $k } ) );
	}
	return( $self->error( "Provided query object is not a DB::Object::Query." ) ) if( !$self->_is_object( $def->{query_object} ) || !$def->{query_object}->isa( 'DB::Object::Query' ) );
	$def->{ts} = ( CORE::stat( $def->{file} ) )[9];
	## $self->message( 3, "File $def->{file} modification time is $def->{ts}" );
	my $key = CORE::join( '|', @$def{qw( pack file line )} );
	$hash->{ $key } = $def;
	# $self->messagef( 3, "Constant queries cache has %d elements now.", scalar( keys( %$CONSTANT_QUERIES_CACHE ) ) );
	# $self->message( 3, "Constant queries cache global hash is '$CONSTANT_QUERIES_CACHE' and pointer in object is: '$hash'" );
	return( $def );
}

sub copy
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my %arg  = ( @_ );
    if( !%arg && %$data )
    {
        %arg = %$data;
    }
    my $ref = $self->select->fetchrow_hashref();
    my %data = %$ref;
    map{ $data{ $_ } = $arg{ $_ } } keys( %arg );
    return( 0 ) if( !%data );
    $self->insert( \%data );
    return( 1 );
}

sub create_db { return( shift->error( "THe driver has not implemented the create database method create_db." ) ); }

sub create_table { return( shift->error( "THe driver has not implemented the create table method create_table." ) ); }

sub data_sources($;\%)
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $opt = shift( @_ ) || undef();
    my $driver = $self->{ 'driver' } || $SQL_DRIVER;
    return( $class->SUPER::data_sources( $driver, $opt ) );
}

sub data_type
{
    my $self = shift( @_ );
    my $type = @_ == 1 ? shift( @_ ) : [ @_ ] if( @_ );
    my $ref  = eval
    {
        local $SIG{ '__DIE__' }  = sub{ };
        local $SIG{ '__WARN__' } = sub{ };
        $self->{ 'dbh' }->type_info_all();
    };
    return( $self->error( "type_info_all() is unsupported by vendor '$self->{ 'driver' }'." ) ) if( $@ );
    ## First item is a reference to hash containing the order of the header
    my $header   = shift( @$ref );
    my $hash     = {};
    my $name_idx = $header->{ 'TYPE_NAME' };
    my @found = ();
    if( $type )
    {
        my @types = ref( $type ) ? @$type : ( $type );
        foreach my $requested ( @types )
        {
            push( @found, grep{ uc( $requested ) eq $_->[ $name_idx ] } @$ref );
        }
    }
    else
    {
        @found = @$ref;
    }
    ## Stop. No need to go further
    return( wantarray() ? () : undef() ) if( !@found );
    my @names = map{ lc( $_ ) } keys( %$header );
    my $len   = scalar( keys( %$header ) );
    my @order = values( %$header );
    map
    {
        next if( @$_ != $len );
        my %data;
        @data{ @names } = @{ $_ }[ @order ];
        $hash->{ lc( $_->[ $name_idx ] ) } = \%data;
    } @found;
    return( wantarray() ? () : undef() ) if( !%$hash );
    return( wantarray() ? %$hash : $hash );
}

sub database
{
    ## Read only
    return( shift->{database} );
}

sub databases { return( shift->error( "Method databases() is not implemented by driver." ) ); }

sub delete
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    ## If the user wants to execute this, then we reset the query, 
    ## but if the user wants to call other methods chained like as_string we don't do anything
    CORE::delete( $self->{ 'query_reset' } ) if( !defined( wantarray() ) );
    # return( $q->delete( @_ ) );
    return( $q->delete( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
		my( @val ) = $q->delete( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
		return( @val );
    }
    else
    {
    	my $val = $q->delete( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
    	return( $val );
    }
}

sub disconnect($)
{
    my $self = shift( @_ );
    ## my( $pack, $file, $line ) = caller();
    ## print( STDERR "disconnect() called from package '$pack' in file '$file' at line '$line'.\n" );
    my $rc = $self->{ 'dbh' }->disconnect( @_ );
    return( $rc );
}

sub do($;$@)
{
    my $self = shift( @_ );
    ## $rc  = $dbh->do( $statement )           || die( $dbh->errstr );
    ## $rc  = $dbh->do( $statement, \%attr )   || die( $dbh->errstr );
    ## $rv  = $dbh->do( $statement, \%attr, @bind_values ) || ...
    ## my( $rows_deleted ) = $dbh->do( 
    ## q{
    ##     DELETE FROM table WHERE status = ?
    ## }, undef(), 'DONE' ) || die( $dbh->errstr );
    my $query     = shift( @_ );
    my $opt_ref   = shift( @_ ) || undef();
    my $param_ref = shift( @_ ) || [];
    my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
    my $sth = $dbh->prepare( $query, $opt_ref ) || 
    return( $self->error( "Error while preparing do query:\n$query", $dbh->errstr() ) );
    $sth->execute( @$param_ref ) || 
    return( $self->error( "Error while executing do query:\n$query", $sth->errstr() ) );
    ## my $rows = $sth->rows();
    ## return( ( $rows == 0 ) ? "0E0" : $rows );
    return( $sth );
}

sub driver { return( shift->_set_get( 'driver' ) ); }

sub enhance
{
    my $self = shift( @_ );
    my $prev = $self->{enhance};
    $self->{enhance} = shift( @_ ) if( @_ );
    return( $prev );
}

sub err(@)
{
    my $self = shift( @_ );
    ## $rv = $h->err;
    if( defined( $self->{sth} ) )
    {
        return( $self->{sth}->err() );
    }
    elsif( $self->{dbh} )
    {
        return( $self->{dbh}->err() );
    }
    #else
    #{
        ## return( $self->{ 'drh' }->err() );
    ## return( DBI::err();
    #}
}

sub errno
{
    goto( &err );
}

sub errmesg
{
    goto( &errstr );
}

sub errstr(@)
{
    my $self = shift( @_ );
    if( !ref( $self ) )
    {
        return( $DBI::errstr || $DB_ERRSTR );
    }
    elsif( defined( $self->{sth} ) && $self->{sth}->errstr() )
    {
        return( $self->{sth}->errstr() );
    }
    elsif( defined( $self->{dbh} ) && $self->{dbh}->errstr() )
    {
        return( $self->{dbh}->errstr() );
    }
    else
    {
        return( $self->{errstr} );
    }
}

sub fatal
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{fatal} = int( shift( @_ ) );
    }
    return( $self->{fatal} );
}

sub from_unixtime
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->from_unixtime( @_ ) );
}

sub format_statement($;\%\%@)
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->format_statement( @_ ) );
}

sub format_update($;%)
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->format_update( @_ ) );
}

sub group
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->group( @_ ) );
}

sub host { return( shift->_set_get_scalar( 'host', @_ ) ); }

sub insert
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    ## If the user wants to execute this, then we reset the query, 
    ## but if the user wants to call other methods chained like as_string we don't do anything
    CORE::delete( $self->{ 'query_reset' } ) if( !defined( wantarray() ) );
    return( $q->insert( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
		my( @val ) = $q->insert( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
		return( @val );
    }
    else
    {
    	my $val = $q->insert( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
    	return( $val );
    }
}

## $rv = $dbh->last_insert_id($catalog, $schema, $table, $field, \%attr);
sub last_insert_id
{
    my $self = shift( @_ );
    return( $self->error( "Method \"last_insert_id\" has not been implemented by driver $self->{driver} (object = $self)." ) );
}

sub limit
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->limit( @_ ) );
}

sub local
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->local( @_ ) );
}

sub lock
{
    my $self = shift( @_ );
    return( $self->error( "Method \"lock\" has not been implemented by driver $self->{driver} (object = $self)." ) );
}

sub login { return( shift->_set_get_scalar( 'login', @_ ) ); }

sub no_bind
{
    my $self = shift( @_ );
    ## Done, already
    return( $self ) if( !$self->{ 'bind' } );
    $self->{ 'bind' } = 0;
    my $q = $self->_reset_query;
    my $where = $q->where();
    my $group = $q->group();
    my $order = $q->order();
    my $limit = $q->limit();
    my $binded_where = $q->binded_where;
    my $binded_group = $q->binded_group;
    my $binded_order = $q->binded_order;
    my $binded_limit = $q->binded_limit;
    ## Replace the place holders by their corresponding value
    ## and have them re-processed by their corresponding method
    if( $where && @$binded_where )
    {
        $where =~ s/(=\s*\?)/"='" . quotemeta( $binded_where->[ $#+ ] ) . "'"/ge;
        $self->where( $where );
    }
    if( $group && @$binded_group )
    {
        $group =~ s/(=\s*\?)/"='" . quotemeta( $binded_group->[ $#+ ] ) . "'"/ge;
        $self->group( $group );
    }
    if( $order && @$binded_order )
    {
        $order =~ s/(=\s*\?)/"='" . quotemeta( $binded_order->[ $#+ ] ) . "'"/ge;
        $self->order( $order );
    }
    if( $limit && @$binded_limit )
    {
        ## $limit =~ s/(=\s*\?)/"='" . quotemeta( $binded_limit[ $#+ ] ) . "'"/ge;
        $self->limit( @$binded_limit );
    }
    $q->reset_bind;
    return( $self );
}

sub no_cache
{
    my $self = shift( @_ );
    $self->{ 'cache' } = 0;
    return( $self );
}

sub NOT { shift( @_ ); return( DB::Object::NOT->new( @_ ) ); }

sub NULL { return( 'NULL' ); }

sub OR { shift( @_ ); return( DB::Object::OR->new( @_ ) ); }

sub order
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->order( @_ ) );
}

sub param
{
    my $self = shift( @_ );
    return() if( !@_ );
    my @supported = 
    qw( 
    SQL_AUTO_IS_NULL AUTOCOMMIT SQL_BIG_TABLES SQL_BIG_SELECTS
    SQL_BUFFER_RESULT SQL_LOW_PRIORITY_UPDATES SQL_MAX_JOIN_SIZE 
    SQL_SAFE_MODE SQL_SELECT_LIMIT SQL_LOG_OFF SQL_LOG_UPDATE 
    TIMESTAMP INSERT_ID LAST_INSERT_ID 
    );
    my $params = $self->{ 'params' } ||= {};
    if( @_ == 1 )
    {
        my $type = shift( @_ );
        $type    = uc( $type ) if( scalar( grep{ /^$_[ 0 ]$/i } @supported ) );
        return( $params->{ $type } );
    }
    else
    {
        my %arg = ( @_ );
        my( $type, $value );
        my @query = ();
        while( ( $type, $value ) = each( %arg ) )
        {
            my @found = grep{ /^(SQL_)?$type$/i } @supported;
            ## SQL parameter
            if( scalar( @found ) )
            {
                $type     = uc( $type );
                $value    = 0 if( !defined( $value ) || $value eq '' );
                $params->{ $type } = $value;
                if( $type eq 'AUTOCOMMIT' && $self->{ 'dbh' } && $value =~ /^(?:1|0)$/ )
                {
                    $self->{ 'dbh' }->{ 'AutoCommit' } = $value;
                }
                push( @query, "$type = $value" );
            }
            ## Private parameter - May be anything
            else
            {
                $params->{ $type } = $value;
            }
        }
        return( $self ) if( !scalar( @query ) );
		my $dbh = $self->{dbh} || return( $self->error( "Could not find database handler." ) );
        my $query = 'SET ' . CORE::join( ', ', @query );
        my $sth = $dbh->prepare( $query ) ||
        return( $self->error( "Unable to set options '", CORE::join( ', ', @query ), "'" ) );
        $sth->execute();
        $sth->finish();
        return( $self );
    }
}

sub passwd { return( shift->_set_get_scalar( 'passwd', @_ ) ); }

sub ping(@)
{
	#return( shift->{ 'dbh' }->ping );
	my $self = shift( @_ );
	## $self->message( 3, "Our object contains: ", sub{ $self->dumper( $self ) } );
	return( $self->{ 'dbh' }->ping );
}

sub ping_select(@)
{
    my $self = shift( @_ );
    ## $rc = $dbh->ping;
    ##----{ Some new ping method replacement.... See Apache::DBI
    ## my( $dbh ) = @_;
    my $ret = 0;
    eval 
    {
        local( $SIG{ '__DIE__' }  ) = sub{ return( 0 ); };
        local( $SIG{ '__WARN__' } ) = sub{ return( 0 ); };
        ## adapt the select statement to your database:
        my $sth = $self->prepare( "SELECT 1" );
        $ret = $sth && ( $sth->execute() );
        $sth->finish();
    };
    return( ($@)  ? 0 : $ret );
}

sub port { return( shift->_set_get_number( 'port', @_ ) ); }

## Gateway to DB::Object::Statement
sub prepare($;$)
{
    my $self    = shift( @_ );
    my $class   = ref( $self ) || $self;
    my $query   = shift( @_ );
    my $opt_ref = shift( @_ ) || undef();
    my $base_class = $self->base_class;
    my $q;
    if( ref( $q ) && $q->isa( 'DB::Object::Query' ) )
    {
    	$q = $query;
    	$query = $q->as_string;
    }
    $self->_clean_statement( \$query );
    ## Wether we are called from DB::Object or DB::Object::Tables object
    my $dbo = $self->{ 'dbo' } || $self;
    $self->message( 3, "Is database handler active? ", ( $dbo->ping ? 'Yes' : 'No' ) );
    if( !$dbo->ping )
    {
    	my $dbh = $dbo->_dbi_connect || return( undef() );
    	$self->{ 'dbh' } = $dbo->{ 'dbh' } = $dbh;
    }
    my $sth = eval
    {
        local( $SIG{ '__DIE__' } )  = sub{ };
        local( $SIG{ '__WARN__' } ) = sub{ };
        $dbo->{ 'dbh' }->prepare( $query, $opt_ref );
    };
    if( $sth )
    {
        ## my $data = { 'sth' => $sth, 'query' => $query };
        my $data = 
        {
		sth 			=> $sth,
		query			=> $query,
		query_values	=> $self->{query_values},
		selected_fields => $self->{selected_fields},
		query_object	=> $q
        };
        return( $self->_make_sth( "${base_class}::Statement", $data ) );
    }
    else
    {
        my $err = $@ || $self->{dbh}->errstr() || 'Unknown error while cache preparing query.';
        $self->{query} = $query;
        return( $self->error( $err ) );
    }
}

sub prepare_cached
{
    my $self    = shift( @_ );
    my $class   = ref( $self ) || $self;
    my $query   = shift( @_ );
    my $opt_ref = shift( @_ ) || undef();
    my $base_class = $self->base_class;
    my $q;
    if( ref( $q ) && $q->isa( 'DB::Object::Query' ) )
    {
    	$q = $query;
    	$query = $q->as_string;
    }
    $self->_clean_statement( \$query );
    ## Wether we are called from DB::Object or DB::Object::Tables object
    my $dbo = $self->{dbo} || $self;
    $self->message( 3, "Is database handler active? ", ( $dbo->ping ? 'Yes' : 'No' ) );
    if( !$dbo->ping )
    {
    	my $dbh = $dbo->_dbi_connect || return( undef() );
    	$self->{dbh} = $dbo->{dbh} = $dbh;
    }
    my $sth = eval
    {
        local( $SIG{ '__DIE__' } )  = sub{ };
        local( $SIG{ '__WARN__' } ) = sub{ };
        $dbo->{dbh}->prepare_cached( $query, $opt_ref );
    };
    if( $sth )
    {
        ## my $data = { %$self, 'sth' => $sth, 'query' => $query };
        ## my $data = { 'sth' => $sth, 'query' => $query };
        my $data = 
        {
        sth				=> $sth,
        query			=> $query,
        query_values	=> $self->{query_values},
        selected_fields => $self->{selected_fields},
        query_object	=> $q,
        };
        ## CORE::delete( $data->{ 'executed' } );
        ## This is an inner package
        ## bless( $data, "DB::Object::Statement" );
        ## return( $data );
        return( $self->_make_sth( "${base_class}::Statement", $data ) );
    }
    else
    {
        my $err = $@ || $self->{ 'dbh' }->errstr() || 'Unknown error while cache preparing query.';
        $self->{query} = $query;
        return( $self->error( $err ) );
    }
}

sub query($$)
{
    my $self = shift( @_ );
    my $sth  = $self->prepare( @_ );
    my $result;
    if( $sth && !( $result = $sth->execute() ) )
    {
        return( undef() );
    }
    else
    {
        ## bless( $sth, ref( $self ) );
        return( $sth );
    }
}

sub quote
{
	my $self = shift( @_ );
	my $dbh = $self->{dbh} || return( $self->error( "No database handler was set." ) );
	return( $dbh->quote( @_ ) );
}

sub replace
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    ## If the user wants to execute this, then we reset the query, 
    ## but if the user wants to call other methods chained like as_string we don't do anything
    CORE::delete( $self->{ 'query_reset' } ) if( !defined( wantarray() ) );
    # return( $q->replace( @_ ) );
    return( $q->replace( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
		my( @val ) = $q->replace( @_ ) || return( $self->pass_error( $q->error ) );
		return( @val );
    }
    else
    {
    	my $val = $q->replace( @_ ) || return( $self->pass_error( $q->error ) );
    	return( $val );
    }
}

sub reset 
{
    my $self = shift( @_ );
    ## $self->message( 3, "Resetting query for table \"", $self->name, "\"." );
    CORE::delete( $self->{query_reset} );
	$self->_reset_query( @_ );
	## To allow chaining of commands
	return( $self );
}

sub reverse
{
    my $self = shift( @_ );
    if( @_ )
    {
    	my $q = $self->_reset_query;
        $self->{ 'reverse' }++;
        $q->reverse( $self->{ 'reverse' } );
    }
    return( $self->{ 'reverse' } );
}

sub select
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    ## If the user wants to execute this, then we reset the query, 
    ## but if the user wants to call other methods chained like as_string we don't do anything
    ## CORE::delete( $self->{query_reset} ) if( !defined( wantarray() ) );
    CORE::delete( $self->{query_reset} ) if( Want::want('VOID') || Want::want('OBJECT') );
    # return( $q->select( @_ ) );
    return( $q->select( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
		my( @val ) = $q->select( @_ ) || return( $self->pass_error( $q->error ) );
		## a statement handler is returned and we reset the query so that other calls would not use the previous DB::Object::Query object
		$self->reset;
		return( @val );
    }
    else
    {
    	my $val = $q->select( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
    	return( $val );
    }
}

sub set
{
    my $self = shift( @_ );
    my $vars = '';
    $vars    = shift( @_ );
    $vars  ||= $self->local();
    ## Are there any variable declaration?
    if( $vars )
    {
        ## print( STDERR "Got here for query: '", $self->{ 'query' }, "'\n" );
        my $query = "SET $vars";
        eval
        {
            local( $SIG{ '__DIE__' } )  = sub{ };
            local( $SIG{ '__WARN__' } ) = sub{ };
            local( $SIG{ 'ALRM' } )     = sub{ die( "Timeout while processing query to set variables:\n$query\n" ) };
            $self->do( $query );
        };
        if( $@ )
        {
            my $err = '*** ' . join( "\n*** ", split( /\n/, $@ ) );
            if( $self->fatal() )
            {
                die( "Error occured while setting SQL variables before executing query:\n$self->{ 'sth' }->{ 'Statement' }\n$err\n" );
            }
            else
            {
                return( $self->error( $@ ) );
            }
        }
    }
    return( 1 );
}

sub sort
{
    my $self = shift( @_ );
    if( @_ )
    {
    	my $q = $self->_reset_query;
        $self->{ 'reverse' } = 0;
        $q->sort( $self->{ 'reverse' } );
    }
    return( $self->{ 'reverse' } );
}

## To also consider:
## $sth = $dbh->statistics_info( undef, $schema, $table, $unique_only, $quick );
sub stat
{
    my $self = shift( @_ );
    my $type = lc( shift( @_ ) );
    my $sth  = $self->prepare( "SHOW STATUS" );
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

sub state(@)
{
    my $self = shift( @_ );
    ## $str = $h->state;
    if( !ref( $self ) )
    {
        return( $DBI::state );
    }
    else
    {
        return( $self->SUPER::state() );
    }
}

sub supported_class
{
	my $self = shift( @_ );
	my @classes = values( %$DRIVER2PACK );
	return( @classes );
}

sub supported_drivers
{
	my $self = shift( @_ );
	my @drivers = keys( %$DRIVER2PACK );
	return( @drivers );
}

sub table
{
    my $self   = shift( @_ );
    my $base_class = $self->base_class;
    $self->message( 3, "Base class is '$base_class'" );
    return( $self->error( "You must use the database object to access this method." ) ) if( ref( $self ) ne $base_class );
    my $table  = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    my $table_class = "${base_class}::Tables";
    my $host   = $self->{ 'server' };
    my $db     = $self->{ 'database' };
    my $cache_table = ${"$base_class\::CACHE_TABLE"};
    return( $self->error( "CACHE_TABLE is not set in base class $base_class" ) ) if( !$self->_is_hash( $cache_table ) );
    my $tables = $cache_table->{ "${host}:${db}" } ||= {};
    ## my $tables = {};
    my $tbl    = $tables->{ $table };
    if( !$tbl )
    {
        ## Prepare what we want to share with DB::Object::Tables *before* creating the object
        ## Because, during DB::Object::Tables object initialization, 'dbh' is required
        my $hash = {};
        ## map{ $hash->{ $_ } = $self->{ $_ } } qw( dbh drh server login passwd database driver tables verbose debug bind cache params );
        ## The database handler must be shared here because during the initiation process
        $self->message( 3, "Initiating $table_class object for table $table" );
        my @new_keys = qw( dbh tables verbose debug bind cache params );
        @$hash{ @new_keys } = @$self{ @new_keys };
        $hash->{dbo} = $self;
        $tbl = $table_class->new( $table, %$hash ) || return( $self->pass_error( $table_class->error ) );
        ## $tbl->{ 'table' }   = $table;
        ## Activate auto binding. With cache, this speeds up a lot this API.
        ## $tbl->{ 'bind' }    = $USE_BIND;
        ## $tables->{ $table } = $tbl unless( $table =~ /^email_/ );
    }
    $tbl->{ 'dbo' } = $self;
    ## $tbl->{ 'drh' } = $self->{ 'drh' };
    ## We set debug and verbose again here in case it changed since the table object was instantiated
    $tbl->{ 'debug' } = $self->{ 'debug' };
    $tbl->{ 'verbose' } = $self->{ 'verbose' };
    $tbl->{ 'bind' }  = $self->use_bind();
    $tbl->{ 'cache' } = $self->use_cache();
    $tbl->{ 'enhance' } = 1;
    ## $self->message( 3, "\$dbo object inherited is: $tbl->{dbo}" );
    return( $tbl );
}

sub table_exists
{
    my $self = shift( @_ );
	my $table = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    $self->message( 3, "Checking if table/view '$table' exists." );
    my $cache_tables = $self->cache_tables;
    my $tables_in_cache = $cache_tables->get({
    	host => $self->host,
    	driver => $self->driver,
    	port => $self->port,
    	database => $self->database,
    });
    foreach my $ref ( @$tables_in_cache )
    {
    	return( 1 ) if( $ref->{name} eq $table );
    }
    ## We did not find it, so let's try by checking directly the database
    my $def = $self->table_info( $table ) || return( undef() );
    return( 0 ) if( !scalar( @$def ) );
    return( 1 );
}

sub table_info 
{
	my $self = shift( @_ );
	return( $self->error( "table_info() has not been implemented by driver \"$self->{driver}\" (object = $self)." ) );
}

sub table_push
{
    my $self = shift( @_ );
    my $table = shift( @_ ) || return( $self->error( "No table provided to add to our cache." ) );
    my $def = $self->tables_info || return( undef() );
    my $hash =
    {
    host => $self->host,
    driver => $self->driver,
    port => $self->port,
    database => $self->database,
    tables => $def,
    };
    my $cache_tables = $self->cache_tables;
    if( !defined( $cache_tables->set( $hash ) ) )
    {
    	return( $self->pass_error( $cache_tables->error ) );
    }
    return( $table );
}

sub tables
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->database;
    my $opts = {};
    $opts = pop( @_ ) if( @_ && $self->_is_hash( $_[-1] ) );
    $db = $opts->{database} if( $opts->{database} );
    my $all = [];
    if( !$opts->{no_cache} && !$opts->{live} )
    {
     	if( my $cache_tables = $self->cache_tables )
     	{
			$all = $cache_tables->get({
				host => $self->host,
				driver => $self->driver,
				port => $self->port,
				database => $db,
			}) || do
			{
				$self->error( "Warning only: an error occured while trying to fetch the tables cache for host '", $self->host, "', driver '", $self->driver, "', port '", $self->port, "' and database '", $self->database, "': ", $cache_tables->error, "\n" );
			};
    	}
    	else
    	{
    		$self->error( "Warning only: no cache tables object found in our self ($self)! Current keys are: '", join( "', '", sort( keys( %$self ) ) ), "'." );
    	}
    }
    if( $opts->{no_cache} || $opts->{live} || !scalar( @$all ) )
    {
		$all = $self->tables_info || return( undef() );
    }
    my @tables = ();
    @tables = map( $_->{name}, @$all ) if( scalar( @$all ) );
#     return( wantarray() ? () : [] ) if( !@tables );
#     return( wantarray() ? @tables : \@tables );
	return( \@tables );
}

sub tables_cache
{
    my $self = shift( @_ );
    my $opts = {};
    $opts    = shift( @_ ) if( @_ && $self->_is_hash( $_[0] ) );
    my $cache_tables = $self->cache_tables;
    my $cache = $cache_tables->get({
    	host => $self->host,
    	driver => $self->driver,
    	port => $self->port,
    	database => $self->database,
    });
    return( $cache );
}

sub tables_info { return( shift->error( "tables_info() has not been implemented by driver." ) ); }

sub tables_refresh
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->database;
    my $tables = $self->tables_info || return( undef() );
    my $hash =
    {
    host => $self->host,
    driver => $self->driver,
    port => $self->port,
    database => $self->database,
    tables => $def,
    };
    my $cache_tables = $self->cache_tables;
    if( !defined( $cache_tables->set( $hash ) ) )
    {
    	return( $self->pass_error( $cache_tables->error ) );
    }
    return( wantarray() ? @$tables : $tables );
}

sub tie
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->tie( @_ ) );
}

sub unix_timestamp
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->unix_timestamp( @_ ) );
}

sub unlock
{
    my $self = shift( @_ );
    return( $self->error( "Method \"unlock\" has not been implemented by driver $self->{driver} (object $self)." ) );
}

sub update
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    ## If the user wants to execute this, then we reset the query, 
    ## but if the user wants to call other methods chained like as_string we don't do anything
    CORE::delete( $self->{ 'query_reset' } ) if( !defined( wantarray() ) );
    # return( $q->update( @_ ) );
    return( $q->update( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
		my( @val ) = $q->update( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
		return( @val );
    }
    else
    {
    	my $val = $q->update( @_ ) || return( $self->pass_error( $q->error ) );
		$self->reset;
    	return( $val );
    }
}

sub use
{
    my $self = shift( @_ );
    my $base_class = $self->base_class;
    return( $self->error( "You must use the the database object to switch database." ) ) if( ref( $self ) ne $base_class );
    my $db   = shift( @_ );
    ## No need to go further
    return( $self ) if( $db eq $self->{database} );
    if( !@AVAILABLE_DATABASES )
    {
        @AVAILABLE_DATABASES = $self->databases();
    }
    $self->message( 3, "Checking if database to use ($db) is among existing ones (", join( ', ', @AVAILABLE_DATABASES ), ")." );
    if( !scalar( grep{ /^$db$/ } @AVAILABLE_DATABASES ) )
    {
        return( $self->error( "The database '$db' does not exist." ) );
    }
    my $dbh = $base_class->connect( $db ) ||
    return( $self->error( "Unable to connect to database '$db'." ) );
    $self->param( 'multi_db' => 1 );
    $dbh->param( 'multi_db' => 1 );
    return( $dbh );
}

sub use_cache { return( shift->_set_get_boolean( 'cache', @_ ) ) }

sub use_bind { return( shift->_set_get_boolean( 'bind', @_ ) ) }

sub variables
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    $self->error( "Variable '$type' is a read-only value." ) if( @_ );
    my $vars = $self->{ 'variables' } ||= {};
    if( !%$vars )
    {
        my $sth = $self->prepare( "SHOW VARIABLES" ) ||
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

sub version
{
	return( shift->error( "This driver has not set the version() method." ) );
}

sub where
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    if( @_ )
    {
    	## $self->message( 3, "Calling where using object '$q' with parameters '", join( "', '", @_ ), "'." );
    	$q->where( @_ );
    	return( $self );
    }
    return( $q->where );
}

sub _cache_this
{
    my $self    = shift( @_ );
    ## When this method is accessed by method from package DB::Object::Statement, they CAN NOT
    ## implicitly passed the statement string or they would risk to modify the previous stored
    ## query object they represent.
    ## For instance:
    ## $obj->select->join( 'some_table', { 'parameter', 'list' } )->fetchrow_hashref()
    ## here the first query is prepared and cached and its resulting object is passed on to join
    ## here join will rebuild the query, but will search first if there was one already cached
    ## if join passes implictly the statement string, this means it will modify the cached query select()
    ## has just previously stored... This is why method such as join must pass explicitly the query string
    my $q       = shift( @_ );
    my $query   = ( ref( $q ) && $q->isa( 'DB::Object::Query' ) ) ? $q->as_string : $q;
    my $base_class = $self->base_class;
    my $cache   = $self->{cache};
    my $bind    = $self->{bind};
    my $queries = '';
    my @saved   = ();
    my $cachedb = ${"${base_class}\::CACHE_QUERIES"};
    return( $self->error( "CACHE_QUERIES is not set in class $base_class" ) ) if( !$self->_is_array( $cachedb ) );
    my $cache_size = scalar( @$cachedb );
    my $cached_sth = '';
    ## If database object exists, this means this is a DB::Object::Tables object, otherwise a DB::Object object
    ## my $dbo = $self->{ 'dbo' } || $self;
    $self->message( 3, "Checking cache for query '$query'." );
    if( $cache )
    {
        if( $CACHE_SIZE > 0 && $cache_size > $CACHE_SIZE )
        {
            ## Take 20% off of the cache
            my $truncate_limit = int( ( $cache_size * 20 ) / 100 );
            splice( @$cachedb, ( $cache_size - $truncate_limit ) );
        }
        foreach my $obj ( @$cachedb )
        {
            ## print( STDERR ref( $self ) . "::_cache_this(): Is query:\n\t'$query'\nthe same than:\n\t'$obj->{ 'query' }'\n" );
            if( $query && $obj->{query} && $obj->{query} eq $query )
            {
                $cached_sth = $obj;
            	last;
            }
        }
    }
    my $sth = '';
    ## We found a previous query exactly the same
    if( $cached_sth )
    {
    	$self->message( 3, "\tFound cached query, re-using it." );
        ## $self->message( "select(): Found a previously prepared query ($obj):\n$query" );
        my $data = { 'sth' => $cached_sth->{sth}, 'query' => $cached_sth->{query} };
        ## This is an inner package
        $sth = $self->_make_sth( "${base_class}::Statement", $data );
    }
    else
    {
    	$self->message( 3, "\tQuery does not yet exist in cache, preparing it." );
        ## Maybe we ought to write:
        ## $prepare = $cache ? \&prepare_cached : \prepare;
        ## $sth = $prepare->( $self, $self->{ 'query' } ) ||
    
        ## $sth = $self->prepare_cached( $query ) ||
        $sth = $self->prepare( $query ) || do
        {
        	$self->message( 3, "An error occured while preparing the query '$query': ", $self->error );
			return( undef() );
        };
        ## $sth = $self->prepare( $self->{ 'query' } ) ||
        ## return( $self->error( "Error while preparing the query on table '$self->{ 'table' }':\n$self->{ 'query' }\n", $self->errstr() ) );
        ## Let the proper method set its error text
        ## If caching of queries is turned on, cache the request
        if( $cache )
        {
            unshift( @$cachedb, $sth );
        }
        ## If caching is off, but the query is a binded parameters' one,
        ## make the current object hold the statement object
        elsif( $bind )
        {
            $self->{sth} = $sth;
        }
    }
    # $self->message( 3, "Returning statement handler" );
    $sth->{query_object} = ( ref( $q ) && $q->isa( 'DB::Object::Query' ) ) ? $q : '';
    ## print( STDERR ref( $self ) . "::_cache_this(): prepared statement was ", $cached_sth ? 'cached' : 'not cached.', "\n" );
    ## Caching the query as a constant
    if( $q && $self->_is_object( $q ) && $q->isa( 'DB::Object::Query' ) )
    {
		my $constant = $q->constant;
		# $self->message( 3, "Found constant data to store: ", sub{ $self->dumper( $constant, { depth => 1 } ) } );
		if( scalar( keys( %$constant ) ) )
		{
			foreach my $k (qw( pack file line ))
			{
				return( $self->error( "Could not find the parameter \"$k\" in the constant query hash reference." ) ) if( !$constant->{ $k } );
			}
			$constant->{query_object} = $q;
			# $self->messagef( 3, "Caching constant for package '%s' in file '%s' at line '%d' with query: %s", @$constant{qw( pack file line )}, $q->as_string );
			## $self->messagef( 3, "Query object ($q) join tables contains %d elements: '%s'", $q->join_tables->length, $q->join_tables->join( "', '" ) );
			$self->constant_queries_cache_set( $constant );
		}
    }
    return( $sth );
}

sub _check_connect_param
{
	my $self  = shift( @_ );
    my $param = shift( @_ );
    $self->message( 3, "\$param is: ", sub{ $self->dumper( $param ) } );
    ## my @valid = qw( db login passwd host driver database server debug );
    my $valid = $self->_connection_parameters( $param );
    my $opts = $self->_connection_options( $param );
    $self->message( 3, "Options returned are: ", sub{ $self->dumper( $opts ) } );
    foreach my $k ( keys( %$param ) )
    {
    	## If it is not in the list and it does not start with an upper case; those are like RaiseError, AutoCommit, etc
    	if( CORE::length( $param->{ $k } ) && !grep( /^$k$/, @$valid ) && !CORE::exists( $opts->{ $k } ) )
    	{
    		return( $self->error( "Invalid parameter '$k'." ) );
    	}
    }
    my @opts_to_remove = keys( %$opts );
    CORE::delete( @$param{ @opts_to_remove } ) if( scalar( @opts_to_remove ) );
    $param->{opt} = $opts;
    $param->{database} = CORE::delete( $param->{db} ) if( !length( $param->{database} ) && $param->{db} );
    $self->message( 3, "\$param is: ", sub{ $self->dumper( $param ) } );
    return( $param );
}

sub _check_default_option
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ );
	return( $self->error( "Provided option is not a hash reference." ) ) if( !$self->_is_hash( $opts ) );
	## This method should be superseded by an inherited class
	return( $opts );
}

sub _connection_options
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    my @dbi_opts = grep( /^[A-Z][a-zA-Z]+/, keys( %$param ) );
    my $opt = {};
    $opt = CORE::delete( $param->{opt} ) if( $param->{opt} && $self->_is_hash( $param->{opt} ) );
    @$opt{ @dbi_opts } = @$param{ @dbi_opts };
    return( $opt );
}

sub _connection_parameters
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    return( [qw( db login passwd host port driver database server opt uri debug )] );
}

sub _connection_params2hash
{
	my $self = shift( @_ );
    my $param  = {};
    if( !( @_ % 2 ) )
    {
    	$param = { @_ };
    }
    elsif( ref( $_[ 0 ] ) eq 'HASH' )
    {
    	$param = shift( @_ );
    }
    else
    {
    	my @keys = qw( database login passwd host driver schema );
    	## Only add in the $param hash the keys value we were given, so we don't create keys entry when not needed
    	for( my $i = 0; $i < scalar( @_ ); $i++ )
    	{
    		$param->{ $keys[ $i ] } = $_[ $i ];
    	}
    }
    
	my $equi =
	{
	database => 'DB_NAME',
	login => 'DB_LOGIN',
	passwd => 'DB_PASSWD',
	host => 'DB_HOST',
	port => 'DB_PORT',
	driver => 'DB_DRIVER',
	schema => 'DB_SCHEMA',
	};
	foreach my $prop ( keys( %$equi ) )
	{
		$param->{ $prop } = $ENV{ $equi->{ $prop } } if( $ENV{ $equi->{ $prop } } && !length( $param->{ $prop } ) );
	}
	
	## A simple json file
	## An URI coul be http://localhost:5432?database=somedb etc...
	## or it could also be file:/foo/bar?opt={"RaiseError":true}
	if( $param->{uri} || $ENV{ 'DB_CON_URI' } )
	{
		my $uri;
		eval
		{
			require URI;
			$uri = URI->new( $param->{uri} || $ENV{ 'DB_CON_URI' } );
		};
		if( !$@ && $uri )
		{
			## Make sure our parameter is a valid URI object
			$param->{uri} = $uri;
			if( $uri->can( 'port' ) )
			{
				$param->{host} = $uri->host;
				$param->{port} = $uri->port if( $uri->port );
			}
			## file:/
			elsif( length( $uri->path ) )
			{
				$param->{database} = ( $uri->path_segments )[-1];
			}
			my( %q ) = $uri->query_form;
			$param->{host} = $q{host} if( $q{host} );
			$param->{port} = $q{port} if( $q{port} );
			$param->{database} = $q{database} if( $q{database} );
			$param->{schema} = $q{schema} if( $q{schema} );
			$param->{user} = $q{user} if( $q{user} );
			$param->{login} = $q{login} if( $q{login} );
			$param->{password} = $q{password} if( $q{password} );
			$param->{opt} = $q{opt} if( $q{opt} );
			$param->{login} = CORE::delete( $param->{user} ) if( !$param->{login} && $param->{user} );
			if( $q{opt} )
			{
				my $jdata = {};
				eval
				{
					require JSON;
					if( defined( *{ "JSON::" } ) )
					{
						my $j = JSON->new->allow_nonref;
						$jdata = $j->decode( $q{opt} );
					}
				};
				if( $@ )
				{
					warn( "Found the database connection opt parameter provided in the connection uri \"$uri\", but could not decode its json value: $@\n" );
				}
				$param->{opt} = $jdata if( scalar( keys( %$jdata ) ) );
			}
		}
	}
	
	if( $param->{conf_file} || $param->{config_file} || $ENV{ 'DB_CON_FILE' } )
	{
		my $db_con_file = CORE::delete( $param->{conf_file} ) || CORE::delete( $param->{config_file} ) || $ENV{ 'DB_CON_FILE' };
		my $db_con_file_ok = 0;
		if( !-e( $db_con_file ) )
		{
			warn( "Database connection parameter file \"$db_con_file\" was provided but does not exist.\n" );
		}
		elsif( -z( $db_con_file ) )
		{
			warn( "Database connection parameter file \"$db_con_file\" was provided but the file is empty.\n" );
		}
		elsif( !-r( $db_con_file ) )
		{
			warn( "Database connection parameter file \"$db_con_file\" was provided but the file lacks privileges to be read.\n" );
		}
		else
		{
			$db_con_file_ok++;
		}
		
		my $json = {};
		eval
		{
			require JSON;
			if( defined( *{ "JSON::" } ) )
			{
				my $j = JSON->new->allow_nonref;
				if( my $io = IO::File->new( "<$db_con_file" ) )
				{
					$io->binmode( ':utf8' );
					my $data = join( '', $io->getlines );
					$io->close;
					$json = $j->decode( $data );
				}
				else
				{
					warn( "Unable to open database connection parameter file \"$db_con_file\": $!\n" );
				}
			}
		};
		if( $@ )
		{
			warn( "Database connection parameter file \"$db_con_file\" was provided, but I encountered the following error while trying to read its json data: $@\n" );
		}
		$json = {} if( !$self->_is_hash( $json ) );
		my $ref = {};
		if( exists( $json->{databases} ) )
		{
			return( $self->error( "Found a property 'databases' in the connections configuration file \"$db_con_file\". I was expecting this property to be an array reference and instead I found this: '$json->{databases}'" ) ) if( !$self->_is_array( $json->{databases} ) );
			## When called from sub classes, this is set
			my $driver = $self->driver;
			## We take the first one matching our driver if any, or else we just take the first one
			foreach my $this ( @{$json->{databases}} )
			{
				if( !$param->{database} && ( !$driver || $this->{driver} eq $driver ) )
				{
					$ref = $this;
					last;
				}
				elsif( $param->{database} && $this->{database} eq $param->{database} &&
					( !$param->{host} || $param->{host} eq $this->{host} ) && 
					( !$param->{port} || $param->{port} eq $this->{port} ) )
				{
					$ref = $this;
					last;
				}
			}
		}
		else
		{
			$ref = $json;
		}
		if( scalar( keys( %$ref ) ) )
		{
			foreach my $k ( qw( database login passwd host port driver schema opt ) )
			{
				$param->{ $k } = $ref->{ $k } if( !length( $param->{ $k } ) && length( $ref->{ $k } ) );
			}
		}
	}
	if( CORE::exists( $param->{host} ) && index( $param->{host}, ':' ) != -1 )
	{
		@$param{ qw( host port ) } = split( /:/, $param->{host}, 2 );
	}
	
	if( !$param->{ 'opt' } && $ENV{ 'DB_OPT' } )
	{
		my $jdata = {};
		eval
		{
			require JSON;
			if( defined( *{ "JSON::" } ) )
			{
				my $j = JSON->new->allow_nonref;
				$jdata = $j->decode( $ENV{ 'DB_OPT' } );
			}
		};
		if( $@ )
		{
			warn( "Found the database connection opt parameter provided in the envionment variable DB_OPT, but could not decode its json value: $@\n" );
		}
		$param->{opt} = $jdata if( scalar( keys( %$jdata ) ) );
	}
    return( $param );
}

sub _clean_statement
{
    my $self  = shift( @_ );
    my $data  = shift( @_ );
    my $query = ref( $data ) ? $data : \$data;
    $$query = CORE::join( "\n", map{ s/^\s+|\s+$//gs; $_ } split( /\n/, $$query ) );
    return( $$query ) if( !ref( $data ) );
}

sub _convert_datetime2object
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ && $self->_is_hash( $_[0] ) );
	return( $opts->{data} );
}

## Does nothing by default
## Must be superseded by the subclasses because we use the data types like PG_JSON, PG_JSONB
## and we don't have them at this top level
sub _convert_json2hash 
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ && $self->_is_hash( $_[0] ) );
	return( $opts->{data} );
}

sub _dbi_connect
{
	my $self = shift( @_ );
    my $dbh;
    my $dsn = $self->_dsn;
    # print( STDERR ref( $self ) . "::_dbi_connect() Options are: ", $self->dumper( $self->{opt} ), "\n" );
    if( $self->{ 'cache_connections' } )
    {
    	$self->messagef( 3, "Using DBI->connect_cached to connect with dsn '$dsn', login '$self->{login}', password of %d bytes long, and options: %s", CORE::length( $self->{passwd} ), $self->dumper( $self->{opt} ) );
    	$dbh = DBI->connect_cached(
			$dsn,
			$self->{ 'login' },
			$self->{ 'passwd' }, 
			$self->{ 'opt' },
			undef(),
			$CONNECT_VIA,
    	);
    }
    else
    {
    	$self->messagef( 3, "Using DBI->connect to connect with dsn '$dsn', login '$self->{login}', password of %d bytes long, and options: %s", CORE::length( $self->{passwd} ), $self->dumper( $self->{opt} ) );
    	$dbh = DBI->connect(
			$dsn,
			$self->{ 'login' },
			$self->{ 'passwd' }, 
			$self->{ 'opt' },
			undef(),
			$CONNECT_VIA,
    	);
    }
	$self->message( 3, "Database handler is '$dbh'." );
    return( $self->error( $DBI::errstr ) ) if( !$dbh );
    return( $dbh );
}

sub _decode_json
{
	my $self = shift( @_ );
	my $json = shift( @_ );
	return if( !CORE::length( $json ) );
	## $self->message( 3, "Decoding json '$json'." );
	my $j = JSON->new->allow_nonref;
	my $hash = eval
	{
		$j->decode( $json );
	};
	return if( $@ );
	return( $hash );
}

sub _dsn
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    die( "Method _dsn is not implemented in class $class\n" );
}

sub _encode_json
{
	my $self = shift( @_ );
	return if( !scalar( @_ ) || ( scalar( @_ ) == 1 && !defined( $_[0] ) ) );
	my $this = shift( @_ );
	return( $self->error( "Value provided is not a hash reference. I was expecting a hash reference to encode data into json." ) ) if( !$self->_is_hash( $this ) );
	my $j = JSON->new;
	my $json = eval
	{
		$j->encode( $this );
	};
	return( $self->error( "An error occurred while trying to encode hash reference provided: $@" ) ) if( $@ );
	return( $json );
}

sub _make_sth
{
    my $self = shift( @_ );
    my $pkg  = shift( @_ );
    my $data = shift( @_ ) || {};
    my $base_class = $self->base_class;
    ## $self->message( 3, "Debug is '$self->{debug}' and verbose is '$self->{verbose}'" );
#     map{ $data->{ $_ } = $self->{ $_ } } 
#     qw( 
#     dbh drh server login passwd database driver 
#     table verbose debug bind cache params selected_fields
#     local where limit group_by order_by reverse from_table left_join
#     tie tie_order
#     );
    map{ $data->{ $_ } = $self->{ $_ } } 
    qw( 
    table verbose debug bind cache params from_table left_join
    );
    $data->{dbh} = $self->{dbh};
    # $self->message( 3, "\$dbo value is '$self->{dbo}'." );
    $data->{dbo} = $self->{dbo} ? $self->{dbo} : ref( $self ) eq $self->base_class ? $self : '';
    ## $data->{ 'binded' } = $self->{ 'binded' } if( $self->{ 'binded' } && ref( $self ) ne $base_class );
    ## In any case suppress the binded parameter from our parent object to avoid polluting the next queries
    ## If needed, the binded parameter will be rebuilt using the data stored in 'where', 'group', 'order' and 'limit'
    ## CORE::delete( $self->{ 'binded' } );
    ## Binded parameters are now either in the DB::Object::Query package or one of its descendant OR passed as arguments to execute
    $data->{errstr} = '';
    CORE::delete( $data->{executed} );
    $data->{query_time} = time();
    $data->{selected_fields} = '' if( !exists( $data->{selected_fields} ) );
	$data->{table_object} = $self;
	my $this = bless( $data, $pkg );
	$this->debug( $self->debug );
    return( $this );
}

sub _param2hash
{
	my $self = shift( @_ );
	my $opts = {};
	if( scalar( @_ ) )
	{
		if( $self->_is_hash( $_[0] ) )
		{
			$opts = shift( @_ );
		}
		elsif( !( scalar( @_ ) % 2 ) )
		{
			$opts = { @_ };
		}
		else
		{
			return( $self->error( "Uneven number of parameters. I was expecting a hash or a hash reference." ) );
		}
	}
	return( $opts );
}

sub _process_limit
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->_process_limit( @_ ) );
}

sub _query_components_old
{
	my $self = shift( @_ );
	my $type = lc( shift( @_ ) ) || $self->_query_type() || return( $self->error( "You must specify a query type: select, insert, update or delete" ) );
	my( $where, $group, $sort, $order, $limit );
    $where  = $self->where();
    if( $type eq "select" )
    {
		$group  = $self->group();
    	$sort  = $self->reverse() ? 'DESC' : $self->sort() ? 'ASC' : '';
		$order  = $self->order();
    }
    $limit  = $self->limit();
    my @query = ();
	push( @query, $where ) if( $where );
	push( @query, $group ) if( $group );
	push( @query, $order ) if( $order );
	push( @query, $sort ) if( $sort && $order );
	push( @query, $limit ) if( $limit );
	return( \@query );
}

sub _query_object_add
{
	my $self = shift( @_ );
	my $obj  = shift( @_ ) || return( $self->error( "No query object was provided" ) );
	my $base = $self->base_class;
	return( $self->error( "Object provided is not a query object class" ) ) if( ref( $obj ) !~ /^${base}\::Query$/ );
	$self->{query_object} = $obj;
	return( $obj );
}

sub _query_object_create
{
	my $self = shift( @_ );
	my $base = $self->base_class;
	my $query_class = "${base}::Query";
	eval
	{
		$self->_load_class( $query_class );
	};
    return( $self->error( "Unable to load Query builder module $query_class: $@" ) ) if( $@ );
	my $o = $query_class->new;
	$o->debug( $self->debug );
	$o->verbose( $self->verbose );
	$o->table_object( $self );
	return( $o );
}

sub _query_object_current { return( shift->{ 'query_object' } ); }

## If the stack is empty, we create an object, add it and resend it
sub _query_object_get_or_create
{
	my $self = shift( @_ );
	my $obj  = $self->{query_object};
	if( !$obj )
	{
		$obj = $self->_query_object_create;
		require Devel::StackTrace;
# 		my $trace = Devel::StackTrace->new;
# 		$self->message( 3, "Query object created with stack trace: ", $trace->as_string );
		$self->{query_object} = $obj;
		my $s = Devel::StackTrace->new;
		## $self->message( 3, "Returning new query object '$obj' for table '", $self->name, "'. Stack trace: ", $s->as_string );
	}
	return( $obj );
}

sub _query_object_remove
{
	my $self = shift( @_ );
	my $obj  = shift( @_ ) || return( $self->error( "No query object was provided" ) );
	my $base = $self->base_class;
	## return( $self->error( "Object provided is not a query object class" ) ) if( ref( $obj ) !~ /^${base}\::Query$/ );
	return( $self->error( "Object provided is not a query object class" ) ) if( !$obj->isa( "DB::Object::Query" ) );
	$self->{query_object} = '';
	return( $obj );
}

sub _query_type_old
{
	my $self = shift( @_ );
	if( $self->{ 'query' } && length( $self->{ 'query' } ) )
	{
		return( lc( ( $self->{ 'query' } =~ /^[[:blank:]]*(ALTER|CREATE|DROP|GRANT|LISTEN|NOTIFY|INSERT|UPDATE|DELETE|SELECT|TRUNCATE)\b/i )[0] ) )
	}
	return( undef() );
}

sub _reset_query
{
    my $self  = shift( @_ );
    if( !$self->{query_reset} )
    {
        $self->{query_reset}++;
        $self->{enhance} = 1;
		my $obj = $self->{query_object};
		## $self->message( 3, "Removing existing query object '$obj'" );
    	$self->_query_object_remove( $obj ) if( $obj );
    	## $self->messagef( 3, "Query object ($obj) has %d joint table(s).", ( $obj ? $obj->join_tables->length : 'not defined' ) );
    	if( $obj && $obj->join_tables->length > 0 )
    	{
    		$obj->join_tables->foreach(sub{
    			my $tbl = shift( @_ );
    			return if( $tbl->name eq $self->name );
    			## $self->message( 3, "Cascading resetting query object for table \"", $tbl->name, "\"." );
    			my $this_query_object = $tbl->query_object;
    			$tbl->_query_object_remove( $this_query_object ) if( $this_query_object );
    			$tbl->use_bind( 0 ) unless( $tbl->use_bind > 1 );
    			$tbl->use_cache( 0 ) unless( $tbl->use_cache > 1 );
    			$tbl->query_reset( 1 );
    			return( $tbl->_query_object_get_or_create );
    		});
    	}
    	## $self->message( 3, "Query object for this table object is now \"$self->{query_object}\"." );
		$self->{bind} = 0 unless( $self->{bind} > 1 );
		$self->{cache} = 0 unless( $self->{cache} > 1 );
    	return( $self->_query_object_get_or_create );
    }
    return( $self->_query_object_current );
}

AUTOLOAD
{
    my $self;
    $self = shift( @_ ) if( blessed( $_[ 0 ] ) || index( $_[0], '::' ) != -1 );
    my( $class, $meth );
    if( $self )
    {
		$class = ref( $self ) || $self;
    }
    my $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }
    my @supported_class = DB::Object->supported_class;
    push( @supported_class, 'DB::Object' );
    my $ok_classes = join( '|', @supported_class );
    my $base_class = ( $class =~ /^($ok_classes)/ )[0];
    my( $call_pack, $call_file, $call_line, @other ) = caller;
    my $call_sub = ( caller( 1 ) )[3];
    $self->message( 3, "Called for method '$meth' with class '$class' and base class '$base_class' and arguments '", join( "', '", @_ ), "' from subroutine \"$call_sub\" in class \"$call_pack\" in file \"$call_file\" at line $call_line." );
	## print( STDERR "${class}::AUTOLOAD() [$AUTOLOAD]: Searching for routine '$meth' from package '$class' with \$self being '$self'.\n" ) if( $DEBUG );
    ## my( $pkg, $file, $line, $sub ) = caller( 1 );
    ## print( STDERR ref( $self ), ": method $meth() called with parameters: '", join( ', ', @_ ), "' within sub '$sub' at line '$line' in file '$file'.\n" );
    
    ## Is it a table object that is being requested?
    # if( $self && scalar( grep{ /^$meth$/ } @$tables ) )
    ## Getting table object take NO argument.
    ## If the user wants to access a method, and somehow the table name is identical to one of our methods, 
    ## it is likely it will take an argument
    if( $class eq $base_class && !scalar( @_ ) && $self->table_exists( $meth ) )
    {
        return( $self->table( $meth ) );
    }
    elsif( $self && $self->can( $meth ) && defined( &{ "$class\::$meth" } ) )
    {
        return( $self->$meth( @_ ) );
    }
    ## For imported subs
    elsif( defined( &$meth ) )
    {
        no strict 'refs';
        *{"${class}\::${meth}"} = \&$meth;
#         if( $self )
#         {
#         	print( STDERR "'can' I execute the method $meth in my own class $class now ? ", ( $self->can( $meth ) ? 'Yes' : 'No' ), "\n" ) if( $DEBUG );
#         }
        unshift( @_, $self ) if( $self );
#         print( STDERR "Calling method $meth with arguments: '", join( "', '", @_ ), "'\n" ) if( $DEBUG );
        return( &$meth( @_ ) );
    }
    ## Taken from AutoLoader.pm
    elsif( $class =~ /^(?:$ok_classes)$/ )
    {
        my $filename;
        my $pkg = $class;
        $pkg =~ s/::/\//g;
        if( defined( $filename = $INC{ "$pkg.pm" } ) )
        {
            $filename =~ s%^(.*)$pkg\.pm\z%$1auto/$pkg/$func.al%s;
            if( -r( $filename ) )
            {
                unless( $filename =~ m|^/|s )
                {
                    $filename = "./$filename";
                }
            }
            else
            {
                $filename = undef();
            }
        }
        if( !defined( $filename ) )
        {
            $filename = "auto/$sub.al";
            $filename =~ s/::/\//g;
        }
        my $save = $@;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $filename;
        };
        if( $@ )
        {
            if( substr( $sub, -9 ) eq '::DESTROY' )
            {
                *$sub = sub {};
            }
            else
            {
                # The load might just have failed because the filename was too
                # long for some old SVR3 systems which treat long names as errors.
                # If we can succesfully truncate a long name then it's worth a go.
                # There is a slight risk that we could pick up the wrong file here
                # but autosplit should have warned about that when splitting.
                if( $filename =~ s/(\w{12,})\.al$/substr( $1, 0, 11 ) . ".al"/e )
                {
                    eval
                    {
                        local $SIG{ '__DIE__' }  = sub{ };
						local $SIG{ '__WARN__' } = sub{ };
						require $filename
                    };
                }
            }
        }
        unless( $@ )
        {
            $@ = $save;
            unshift( @_, $self ) if( $self );
            goto &$sub;
        }
        $@ = $save;
    }
    
    if( $self && exists( $self->{ 'sth' } ) )
    {
    	## e.g. $sth->pg_server_prepare => $self->{sth}->{pg_server_prepare}
    	if( CORE::exists( $self->{sth}->{ $meth } ) )
    	{
    		$self->{sth}->{ $meth } = shift( @_ ) if( scalar( @_ ) );
    		return( $self->{sth}->{ $meth } );
    	}
        ## $self->message( "AUTOLOAD(): dynamic method $meth() called with argument '", join( ', ', @_ ), "'" );
        ## $self->message( "AUTOLOAD(): '$self->{ 'sth' }' is ", $self->{ 'executed' } ? '' : 'not ', "executed" );
        ## $self->message( "AUTOLOAD(): (counter checking) '$self->{ 'sth' }' is ", $self->executed() ? '' : 'not ', "executed" );
		if( !$self->executed() )
		{
			$self->message( "AUTOLOAD(): executing statement '$self->{ 'sth' }':\n$self->{ 'query' }\n" );
			$self->execute() || return( $self->error( $self->{ 'sth' }->errstr() ) );
		}
		## $self->_cleanup();
		## print( STDERR "Calling DBI method $meth with sth '$self->{sth}' arguments: '", join( "', '", @_ ), "'\n" ) if( $DEBUG );
		# *{ "${class}\::$meth" } = sub{ return( shift->{ 'sth' }->$meth( @_ ) ); };
		return( $self->{ 'sth' }->$meth( @_ ) );
    }
    ## e.g. $dbh->pg_notifies
    elsif( $self && ( ( $self->{ 'dbh' } && $self->{ 'dbh' }->can( $meth ) ) || defined( &{ "DBI::db::" . $meth } ) ) )
    {
        return( $self->{ 'dbh' }->$meth( @_ ) );
    }
    ## e.g. $dbh->pg_enable_utf8 becomes $self->{dbh}->{pg_enable_utf8]
    elsif( $self && $self->{dbh} && CORE::exists( $self->{dbh}->{ $meth } ) )
    {
    	$self->{dbh}->{ $meth } = shift( @_ ) if( scalar( @_ ) );
    	return( $self->{dbh}->{ $meth } );
    }
    elsif( defined( &{ "DBI::" . $meth } ) )
    {
        my $h = &{ "DBI::" . $meth }( @_ );
        if( defined( $h ) )
        {
            bless( $h, $class );
            return( $h );
        }
        else
        {
            return( undef() );
        }
    }
#     if( defined( &$meth ) ) 
#     {
#         no strict 'refs';
#         *$meth = \&{ $meth };
#         return( &{ $meth }( @_ ) );
#     }
    my $what = $self ? $self : $class;
    return( $what->error( "${class}::AUTOLOAD: Not defined in $class and not autoloadable (last try $meth)" ) );
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
    elsif( $self->{ 'dbh' } && $class =~ /^AI\:\:DB(?:\:\:(?:Postgres|Mysql|SQLite))?$/ )
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

package DB::Object::Operator;
BEGIN
{
	use strict;
};

sub new
{
	my $that = shift( @_ );
	my $val = [ @_ ];
	return( bless( { value => $val } => ( ref( $that ) || $that ) ) );
}

sub operator { return( '' ); }

sub value { return( wantarray() ? @{$_[0]->{value}} : $_[0]->{value} ); }

package DB::Object::AND;
BEGIN
{
	use strict;
	use parent -norequire, qw( DB::Object::Operator );
};

sub operator { return( 'AND' ); }

package DB::Object::NOT;
BEGIN
{
	use strict;
	use parent -norequire, qw( DB::Object::Operator );
};

sub operator { return( 'NOT' ); }

package DB::Object::OR;
BEGIN
{
	use strict;
	use parent -norequire, qw( DB::Object::Operator );
};

sub operator { return( 'OR' ); }

1;

__END__

=encoding utf8

=head1 NAME

DB::Object - SQL API

=head1 SYNOPSIS

    use DB::Object;

	my $dbh = DB::Object->connect({
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
    ## Get the last used insert id
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
	
    ## Lets' dump the result of our query
    ## First to STDERR
    $login->where( "login='jack'" );
    $login->select->dump();
    ## Now dump the result to a file
    $login->select->dump( "my_file.txt" );
    
=head1 VERSION

    v0.9.2

=head1 DESCRIPTION

L<DB::Object> is a SQL API much alike C<DBI>.
So why use a private module instead of using that great C<DBI> package?

At first, I started to inherit from C<DBI> to conform to C<perlmod> perl 
manual page and to general perl coding guidlines. It became very quickly a 
real hassle. Barely impossible to inherit, difficulty to handle error, too 
much dependent from an API that change its behaviour with new versions.
In short, I wanted a better, more accurate control over the SQL connection.

So, L<DB::Object> acts as a convenient, modifiable wrapper that provide the
programmer with an intuitive, user-friendly and hassle free interface.

=head1 CONSTRUCTOR

=over 4

=item B<new>()

Create a new instance of L<DB::Object>. Nothing much to say.

=item B<connect>( [ DATABASE, LOGIN, PASSWORD, SERVER[:PORT], DRIVER, SCHEMA ] | %PARAMETERS | \%PARAMETERS )

Create a new instance of L<DB::Object>, but also attempts a conection
to SQL server.

It can take either an array of value in the order database name, login, password, host, driver and optionally schema, or it can take a has or hash reference. The hash or hash reference attributes are as follow:

=over 8

=item I<database> or I<DB_NAME>

The database name you wish to connect to

=item I<login> or I<DB_LOGIN>

The login used to access that database

=item I<passwd> or I<DB_PASSWD>

The password that goes along

=item I<host> or I<DB_HOST>

The server, that is hostname of the machine serving a SQL server.

=item I<port> or I<DB_PORT>

The port to connect to

=item I<driver> or I<DB_DRIVER>

The driver you want to use. It needs to be of the same type than the server
you want to connect to. If you are connecting to a MySQL server, you would use
C<mysql>, if you would connecto to an Oracle server, you would use C<oracle>.

You need to make sure that those driver are properly installed in the system 
before attempting to connect.

To install the required driver, you could start with the command line:

    perl -MCPAN -e shell

which will provide you a special shell to install modules in a convenient way.

=item I<schema> or I<DB_SCHEMA>

The schema to use to access the tables. Currently only used by PostgreSQL

=item I<opt>

This takes a hash reference and contains the standard C<DBI> options such as I<PrintError>, I<RaiseError>, I<AutoCommit>, etc

=item I<conf_file> or I<DB_CON_FILE>

This is used to specify a json connection configuration file. It can also provided via the environment variable I<DB_CON_FILE>. It has the following structure:

	{
	"database": "some_database",
	"host": "db.example.com",
	"login": "sql_joe",
	"passwd": "some password",
	"driver": "Pg",
	"schema": "warehouse",
	"opt":
		{
		"RaiseError": false,
		"PrintError": true,
		"AutoCommit": true
		}
	}

Alternatively, it can contain connections parameters for multiple databases and drivers, such as:

	{
		"databases": [
			{
			"database": "some_database",
			"host": "db.example.com",
			"port": 5432,
			"login": "sql_joe",
			"passwd": "some password",
			"driver": "Pg",
			"schema": "warehouse",
			"opt":
				{
				"RaiseError": false,
				"PrintError": true,
				"AutoCommit": true
				}
			},
			{
			"database": "other_database",
			"host": "db.example2.com",
			"login": "sql_bob",
			"passwd": "other password",
			"driver": "mysql",
			},
			{
			"database": "/path/to/my/database.sqlite",
			"driver": "SQLite",
			}
		]
	}

=item I<uri> or I<DB_CON_URI>

This is used to specify an uri to contain all the connection parameters for one database connection. It can also provided via the environment variable I<DB_CON_URI>. For example:

	http://db.example.com:5432?database=some_database&login=sql_joe&passwd=some%020password&driver=Pg&schema=warehouse&&opt=%7B%22RaiseError%22%3A+false%2C+%22PrintError%22%3Atrue%2C+%22AutoCommit%22%3Atrue%7D
	
Here the I<opt> parameter is passed as a json string, for example:

    {"RaiseError": false, "PrintError":true, "AutoCommit":true}

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
  my $sth = $tbl->delete( "login" => "jack" );

=item B<disconnect>()

Disconnect from database. Returns the return code.

  my $rc = $dbh->disconnect;

=item B<do>( $sql_query, [ \%attributes, \@bind_values ] )

Execute a sql query directly passed with possible attributes and values to bind.

The attributes list will be used to B<prepare> the query and the bind values will be used when executing the query.

It returns the statement handler or the number of rows affected.

Example:

  $rc = $dbh->do( $statement ) || die( $dbh->errstr );
  $rc = $dbh->do( $statement, \%attr ) || die( $dbh->errstr );
  $rv = $dbh->do( $statement, \%attr, @bind_values ) || die( $dbh->errstr );
  my $rows_deleted = $dbh->do(
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

It returns a new L<DB::Object::Tables> object with all the data prepared within.

=item B<group>( @fields | \@fields )

Format the group by portion of the query.

It returns an empty list in list context of undef in scalar context if no group by clause was build.
Otherwise, it returns the value of the group by clause as a string in list context and the full group by clause in scalar context.

In list context, it returns: $group_by

In scalar context, it returns: GROUP BY $group_by

=item B<insert>( L<DB::Object::Statement> SELECT object, \%key_value | %key_value )

Prepares an INSERT query using the field-value pairs provided.

If a L<DB::Object::Statement> object is provided as first argument, it will considered as a SELECT query to be used in the INSERT query, as in: INSERT INTO my table SELECT FROM another_table

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

It returns a L<DB::Object::Statement> object upon success or undef if an error occurred. The error can then be retrieved using B<errstr> or B<error>.

=item B<prepare_cached>( $query, \%options )

Same as B<prepare> except the query is cached.

=item B<query>( $query, \%options )

It prepares and executes the given SQL query with the options provided and return undef() upon error or the statement handler upon success.

=item B<replace>( L>DB::Object::Statement> object, [ %data ] )

Just like for the INSERT query, B<replace> takes one optional argument representing a L<DB::Object::Statement> SELECT object or a list of field-value pairs.

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

Given a table name, B<table> will return a L<DB::Object::Tables> object. The object is cached for re-use.

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

=item B<use_cache>( [ 0 | 1 ] )

Sets or get the I<use_cache> parameter.

=item B<use_bind>( [ 0 | 1 ] )

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

It returns the cached statement as an L<DB::Object::Statement> object.

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

=head1 OPERATORS

=head2 AND( VALUES )

Given a value, this returns a L<DB::Object::AND> object. You can retrieve the value with B<value>

This is used by B<where>

    my $op = $dbh->AND( login => 'joe', status => 'active' );
    ## will produce:
    WHERE login = 'joe' AND status = 'active'

=head2 NOT( VALUES )

Given a value, this returns a L<DB::Object::NOT> object. You can retrieve the value with B<value>

This is used by B<where>

    my $op = $dbh->AND( login => 'joe', status => $dbh->NOT( 'active' ) );
    ## will produce:
    WHERE login = 'joe' AND status != 'active'

=head2 OR( VALUES )

Given a value, this returns a L<DB::Object::OR> object. You can retrieve the value with B<value>

This is used by B<where>

    my $op = $dbh->OR( login => 'joe', login => 'john' );
    ## will produce:
    WHERE login = 'joe' OR login = 'john'

=head1 COPYRIGHT

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

=head1 CREDITS

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DBI>, L<Apache::DBI>

=cut
