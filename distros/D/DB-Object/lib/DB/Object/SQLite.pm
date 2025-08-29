# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/SQLite.pm
## Version v1.2.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2025/07/30
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This is the subclassable module for driver specific ones.
package DB::Object::SQLite;
BEGIN
{
    use strict;
    use warnings;
    use vars qw(
        $VERSION $CACHE_SIZE $CONNECT_VIA $ERROR $DEBUG
        $USE_BIND $USE_CACHE $MOD_PERL
        $PLACEHOLDER_REGEXP $DATATYPES_DICT
    );
    use DBI qw( :sql_types );
    eval { require DBD::SQLite; };
    die( $@ ) if( $@ );
    use parent qw( DB::Object );
    use POSIX ();
    use DateTime;
    use DateTime::TimeZone;
    use DateTime::Format::Strptime;
    use Module::Generic::File qw( sys_tmpdir );
    # <https://metacpan.org/pod/DBD::SQLite::Constants>
    # <https://www.sqlite.org/datatype3.html>
    # <https://metacpan.org/pod/DBD::SQLite::Constants#datatypes-(fundamental_datatypes)>
    # NULL, INTEGER, REAL, TEXT, BLOB
    # Check DBD::SQLite::Constants
    our $DATATYPES_DICT =
    {
        blob => {
            constant => '',
            name => 'SQLITE_BLOB',
            re => qr/^BLOB/,
            type => 'blob'
        },
        bool => {
            alias => [qw( boolean date datetime decimal numeric )],
            constant => '',
            name => 'SQLITE_NULL',
            re => qr/^(NUMERIC|DECIMAL\(\d+,\d+\)|BOOLEAN|DATETIME|DATE)/,
            type => 'bool'
        },
        float => {
            alias => [qw( double real ), 'double precision', ],
            constant => '',
            name => 'SQLITE_FLOAT',
            re => qr/^(REAL|DOUBLE|DOUBLE\s+PRECISION|FLOAT)/,
            type => 'float'
        },
        integer => {
            alias => [qw( int tinyint smallint mediumint bigint int2 int8 ), 'unsigned big int' ],
            constant => '',
            name => 'SQLITE_INTEGER',
            re => qr/^(INT|INTEGER|TINYINT|SMALLINT|MEDIUMINT|BIGINT|UNSIGNED\s+BIG\s+INT|INT2|INT8)/,
            type => 'integer',
        },
        # Data type text is only available from version 1.71 onward
    };
    if( $DBD::SQLite::VERSION >= 1.071 )
    {
        $DATATYPES_DICT->{text} =
        {
            alias => [qw( character clob nchar nvarchar varchar ), 'native character', 'varying character' ],
            constant => '',
            name => 'SQLITE_TEXT',
            re => qr/^(CHARACTER\(\d+\)|VARCHAR\(\d+\)|VARYING\s+CHARACTER\(\d+\)|NCHAR\(\d+\)|NATIVE\s+CHARACTER\(\d+\)|NVARCHAR\(\d+\)|TEXT|CLOB)/,
            type => 'text'
        };
    }
    our $PLACEHOLDER_REGEXP = qr/\?(?<index>\d+)/;
    our $VERSION = 'v1.2.0';
};

use strict;
use warnings;
# require DB::Object::SQLite::Statement;
# require DB::Object::SQLite::Tables;
our $DEBUG         = 0;
our $CACHE_SIZE    = 10;
our $USE_BIND      = 0;
our $USE_CACHE     = 0;
our $MOD_PERL      = 0;
if( $INC{ 'Apache/DBI.pm' } && 
    substr( $ENV{GATEWAY_INTERFACE}|| '', 0, 8 ) eq 'CGI-Perl' )
{
    $CONNECT_VIA = "Apache::DBI::connect";
    $MOD_PERL++;
}

# Actually the one in DB::Object is used, because DBD::SQLite has no datatype constants of its own
# our $DATATYPES = {};

our $PRIVATE_FUNCTIONS =
{
    ceiling         =>[1, \&_ceiling],
    concat          =>[-1, \&_concat],
    curdate         =>[0, \&_curdate],
    curtime         =>[0, \&_curtime],
    dayname         =>[1, \&_dayname],
    dayofmonth      =>[1, \&_dayofmonth],
    dayofweek       =>[1, \&_dayofweek],
    dayofyear       =>[1, \&_dayofyear],
    distance_miles  =>[4, \&_distance_miles],
    # from_days     =>[-1, \&_from_days],
    from_unixtime   =>[1, \&_from_unixtime],
    hour            =>[1, \&_hour],
    lcase           =>[1, \&_lcase],
    left            =>[2, \&_left],
    locate          =>[2, \&_locate],
    log10           =>[1, \&_log10],
    minute          =>[1, \&_minute],
    month           =>[1, \&_month],
    monthname       =>[1, \&_monthname],
    number_format   =>[4, \&_number_format],
    power           =>[2, \&_power],
    quarter         =>[1, \&_quarter],
    rand            =>[0, \&_rand],
    regexp          =>[2, \&_regexp],
    replace         =>[3, \&_replace],
    right           =>[2, \&_right],
    second          =>[1, \&_second],
    space           =>[1, \&_space],
    sprintf         =>[-1, \&_sprintf],
    to_days         =>[1, \&_to_days],
    # truncate      =>[-1, \&_truncate],
    ucase           =>[1, \&_ucase],
    unix_timestamp  =>[1, \&_unix_timestamp],
    week            =>[1, \&_week],
    weekday         =>[1, \&_weekday],
    year            =>[1, \&_year],
};
# See compile_options method
# This is very useful to know which features can be used
our $COMPILE_OPTIONS = [];

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

foreach my $type ( keys( %$DATATYPES_DICT ) )
{
    my $c = $DATATYPES_DICT->{ $type }->{name};
    my $code = \&{"DBD::SQLite::Constants::${c}"};
    my $val = eval
    {
        $code->();
    };
    if( $@ )
    {
        warn( "Datatype \"DBD::SQLite::Constants::${c}\" is not defined in DBD::SQLite version $DBD::SQLite::VERSION: $@" );
        delete( $DATATYPES_DICT->{ $type } );
    }
    else
    {
        $DATATYPES_DICT->{ $type }->{constant} = $val;
    }
}

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ );
    $self->{driver} = 'SQLite';
    $self->{_func} = {};
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
        ActiveKids                       => 0,
        AutoCommit                       => 1,
        AutoInactiveDestroy              => 1,
        CachedKids                       => 0,
        ChildHandles                     => 0,
        ChopBlanks                       => 1,
        CursorName                       => 0,
        Driver                           => 0,
        ErrCount                         => 1,
        Executed                         => 0,
        FetchHashKeyName                 => 1,
        HandleError                      => 1,
        HandleSetErr                     => 1,
        InactiveDestroy                  => 1,
        Kids                             => 0,
        NAME                             => 0,
        NULLABLE                         => 0,
        NUM_OF_FIELDS                    => 0,
        NUM_OF_PARAMS                    => 0,
        # Current database name
        Name                             => 0,
        PRECISION                        => 0,
        PrintError                       => 1,
        PrintWarn                        => 1,
        Profile                          => 1,
        RaiseError                       => 1,
        RowCacheSize                     => 0,
        RowsInCache                      => 0,
        SCALE                            => 0,
        ShowErrorStatement               => 1,
        Statement                        => 0,
        TYPE                             => 0,
        Taint                            => 1,
        TaintIn                          => 1,
        TaintOut                         => 1,
        TraceLevel                       => 1,
        Type                             => 1,
        Username                         => 0,
        Warn                             => 1,
        # Not used
        # LongReadLen                   => 1,
        # LongTruncOk                   => 1,
        # CompatMode                    => 1,
        # If you set this to true, "do" method will process multiple statements at one go.
        # This may be handy, but with performance penalty. See above for details.
        sqlite_allow_multiple_statements => 1,
        # If you set this to true, DBD::SQLite tries to see if the bind values are number or
        # not, and does not quote if they are numbers.
        sqlite_see_if_its_a_number       => 1,
        sqlite_unicode                   => 1,
        # Returns an unprepared part of the statement you pass to "prepare".  Typically this
        # contains nothing but white spaces after a semicolon. 
        sqlite_unprepared_statements     => 0,
        # If you set this to true, DBD::SQLite tries to issue a "begin immediate transaction"
        # (instead of "begin transaction") when necessary.
        sqlite_use_immediate_transaction => 1,
        sqlite_version                   => 0,
    );
    # Only those attribute exist
    # Using an a non existing attribute produce an exception, so we better avoid
    if( $name )
    {
        return( $self->{dbh}->{ $name } ) if( exists( $attr{ $name } ) );
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
                $self->{dbh}->{ $name } = $value;
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

sub can_update_delete_limit { return( shift->has_compile_option( 'ENABLE_UPDATE_DELETE_LIMIT' ) ); }

# sub check_driver(@;$@)

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
    my $system_tmpdir = sys_tmpdir();
    my $compile_options_cache_file = $system_tmpdir->join( 'sql_sqlite_compile_options.cfg' );
    my @options = ();
    # if( -e( $compile_options_cache_file ) && !-z( $compile_options_cache_file ) )
    if( $compile_options_cache_file->exists && !$compile_options_cache_file->is_empty )
    {
        # my $fh = IO::File->new( "<$compile_options_cache_file" ) || return( $self->error( "Unable to read the sqlite compile options cache file \"$compile_options_cache_file\": $!" ) );
        my $fh = $compile_options_cache_file->open( '<' ) || return( $self->error( "Unable to read the sqlite compile options cache file \"$compile_options_cache_file\": ", $compile_options_cache_file->error ) );
        my @all = $fh->getlines;
        # Remove any comments
        @options = grep( !/^#/, @all );
        $fh->close;
        if( scalar( @options ) )
        {
            $COMPILE_OPTIONS = \@options;
            # Return a copy only to be safe
            return( [ @options ] );
        }
    }
    # If the cache file does not yet exists or there is no options, we do the query
    my $dbh = $self->{dbh} || return( $self->error( "No active database handler available. You can only call this method once a database connection has been made." ) );
    my $all = $self->do( "PRAGMA compile_options" )->fetchall_arrayref;
    @options = map( $_->[0], @$all );
    # my $fh = IO::File->new( ">$compile_options_cache_file" ) || return( $self->error( "Unable to write to sqlite compile options cache file \"$compile_options_cache_file\": $!" ) );
    my $fh = $compile_options_cache_file->open( '>' ) || return( $self->error( "Unable to write to sqlite compile options cache file \"$compile_options_cache_file\": ", $compile_options_cache_file->error ) );
    $fh->autoflush(1);
    $fh->print( join( "\n", @options ), "\n" ) || return( $self->error( "Unable to write to the sqlite compile options cache file \"$compile_options_cache_file\": $!" ) );
    $fh->close;
    $COMPILE_OPTIONS = \@options;
    return( \@options );
}

# Inherited by DB::Object, however, DB::Object::connect() will call our subroutine 
# _dbi_connect which format in a particular way the dsn.
sub connect
{
    my $that  = shift( @_ );
    my $param = $that->_connection_params2hash( @_ ) || return;
    $param->{driver} = 'SQLite';
    $param->{sqlite_unicode} = 1;
    return( $that->SUPER::connect( $param ) );
}

# NOTE: sub constant_to_datatype is inherited

# sub copy

# sub create_table($;%)

# See DB::Object
# sub data_sources($;\%)

# sub data_type

# sub database

sub database_file
{
    return( shift->{database_file} );
}

sub databases
{
    my $self = shift( @_ );
    # return( $self->error( "Not connected to PostgreSQL server yet. Issue $dbh->connect first." ) ) if( !$self->{dbh} );
    my $dbh;
    # If there is no connection yet, then create one using the postgres login.
    # There should not be a live user and database just to check what databases there are.
    if( !$self->{dbh} )
    {
        # try-catch
        local $@;
        $dbh = eval
        {
            $self->connect( @_ );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to connect to the SQLite database file: $@" ) );
        }
        $dbh or return( $self->pass_error );
    }
    else
    {
        $dbh = $self;
    }
    my $temp = $dbh->do( 'PRAGMA database_list' )->fetchall_arrayref( {} );
    my @dbases = map( $_->{name}, @$temp );
    return( @dbases );
}

# NOTE: sub datatype_dict is inherited

# NOTE: sub datatype_to_constant is inherited

# NOTE: sub datatypes is in inherited

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
    return( $self->{dbh}->func( $table, $func_name ) );
}

# <https://metacpan.org/pod/DBD::SQLite::Constants#datatypes-(fundamental_datatypes)>
# <https://www.sqlite.org/datatype3.html>
# In SQLite, there are only 4 types:
# SQLITE_INTEGER
# SQLITE_FLOAT
# SQLITE_BLOB
# SQLITE_NULL
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
    if( substr( $type, 0, 7 ) eq 'sqlite_' )
    {
        $const = $self->{dbh}->can( "DBD::SQLite::\U${type}\E" );
    }
    else
    {
        $const = $self->{dbh}->can( "DBD::SQLite::SQLITE_\U${type}\E" );
    }
    return( '' ) if( !defined( $const ) );
    return( $const->() );
}

sub having
{
    my $self  = shift( @_ );
    my $q = $self->_reset_query;
    return( $q->having( @_ ) );
}

# https://www.sqlite.org/compile.html
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

sub last_insert_id
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || $self->{table};
    return( $self->{dbh}->last_insert_id( undef, undef, $table, undef ) );
}

sub lock { return( shift->error( "Table lock is unsupported in SQLite." ) ); }

sub pragma
{
    my $self = shfit( @_ );
    my $key2val =
    {
    foreign_keys                      => [ qw( ON OFF ) ],
    journal_mode                      => [ qw( DELETE TRUNCATE ) ],
    legacy_file_format                => [ qw( ON OFF ) ],
    reverse_unordered_selects         => [ qw( ON OFF ) ],
    synchronous                       => [ qw( ON OFF ) ],
    # To avoid corruption after BEGIN starts, DBD uses BEGIN IMMEDIATE. Default is TRUE
    sqlite_use_immediate_transaction  => [ qw( 1 0 ) ],
    cache_size                        => qr/^\d+$/
    };
}

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::SQLite::Query', @_ ) ); }

# https://www.sqlite.org/lang_replace.html
# https://www.sqlite.org/lang_conflict.html
# REPLACE is an alias for INSERT OR REPLACE
# https://www.sqlite.org/lang_insert.html
sub replace
{
    my $self = shift( @_ );
    my $data = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    my @arg  = @_;
    my %arg  = ();
    my $select = '';
    if( !%arg && $data && $self->_is_hash( $data => 'strict' ) )
    {
        %arg = %$data;
    }
    elsif( $data && ref( $data ) eq 'DB::Object::Statement' )
    {
        $select = $data->as_string();
    }
    %arg = @arg if( @arg );
    my $table   = $self->{table} ||
    return( $self->error( "No table was provided to replace data." ) );
    my $structure = $self->structure || return( $self->pass_error );
    my $null      = $self->null();
    my @avoid     = ();
    foreach my $field ( keys( %$structure ) )
    {
        # It is useless to insert a blank data in a field whose default value is NULL.
        # Especially since a test on a NULL field may be made specifically.
        push( @avoid, $field ) if( !CORE::exists( $arg{ $field } ) && $null->{ $field } );
    }
    my $db_data = $self->getdefault({
        table => $table,
        arg => \@arg,
        avoid => \@avoid
    });
    my( $fields, $values ) = $db_data->format_statement();
    $self->_reset_query();
    delete( $self->{query_reset} );
    $self->{binded_values} = $db_data->{binded_values};
    my $query = $self->{query} = $select ? "REPLACE INTO $table $select" : "REPLACE INTO $table ($fields) VALUES($values)";
    # Everything meaningfull lies within the object
    # If no bind should be done _save_bind does nothing
    $self->_save_bind();
    # Query string should lie within the object
    # _cache_this sends back an object no matter what or unde() if an error occurs
    my $sth = $self->_cache_this();
    # STOP! No need to go further
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
    return( $self->error( "I was expecting an hash reference of parameters as only argument." ) ) if( !$self->_is_hash( $_[0] => 'strict' ) );
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

sub sql_function_register
{
    my $self = shift( @_ );
    my $opts = shift( @_ ) || return( $self->error( "No private function hash reference provided." ) );
    my $dbh = $self->{dbh} || return( $self->error( "No active database handler available." ) );
    $opts->{flags} = [] if( !exists( $opts->{flags} ) || ref( $opts->{flags} ) ne 'ARRAY' );
    my $flag;
    my $eval = join( '|', @{$opts->{flags}} );
    $flag = eval( $eval );
    my $code = $opts->{code};
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

# http://www.sqlite.org/c3ref/c_status_malloc_count.html
sub stat
{
    my $self = shift( @_ );
    my $opt  = $self->_get_args_as_hash( @_ );
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
#     my $table = shift( @_ ) || 
#     return( $self->error( "You must provide a table name to access the table methods." ) );
#     my $cache_tables = $self->cache_tables;
#     my $tables_in_cache = $cache_tables->get({
#         host => 'localhost',
#         driver => $self->driver,
#         port => 0,
#         database => $self->database,
#     });
#     foreach my $ref ( @$tables_in_cache )
#     {
#         return( 1 ) if( $ref->{name} eq $table );
#     }
#     # We did not find it, so let's try by checking directly the database
#     my $def = $self->table_info( $table ) || return;
#     return(0) if( !scalar( @$def ) );
#     return(1);
# }

sub table_info
{
    my $self = shift( @_ );
    my $table = shift( @_ ) || 
    return( $self->error( "You must provide a table name to access the table methods." ) );
    my $opts = $self->_get_args_as_hash( @_ );
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
    return( {} ) if( !scalar( @$all ) );
    return( $all->[0] );
}

sub tables
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{database};
    my $all  = $self->tables_info || return;
    my @tables = map( $_->{name}, @$all );
#     return( wantarray() ? () : undef() ) if( !@tables );
#     return( wantarray() ? @tables : \@tables );
    return( \@tables );
}

sub tables_info
{
    my $self = shift( @_ );
    my $db   = shift( @_ ) || $self->{database};
    # Parameters are: ?, schema, table, and type
    # my $sth  =  $self->{dbh}->table_info( undef, undef, $table, "TABLE,VIEW" );
    # The original query was fetched by connecting to Postgres with psql -E and executing the command \z
    # This revised query will fetch only tables, views, materialised view and foreign tables, but will avoid the mysterious view called sequence_setvals
    # https://stackoverflow.com/questions/82875/how-to-list-the-tables-in-a-sqlite-database-file-that-was-opened-with-attach
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

# https://www.sqlite.org/versionnumbers.html
sub version
{
    my $self  = shift( @_ );
    # If we already have the information, let's use our cache instead of making a query
    return( $self->{_db_version} ) if( length( $self->{_db_version} ) );
    my $sql = 'SELECT sqlite_version()';
    my $sth = $self->do( $sql ) || return( $self->error( "Unable to issue the sql statement '$sql' to get the server version: ", $self->errstr ) );
    my $ver = $sth->fetchrow;
    $sth->finish;
    # We cache it
    $self->{_db_version} = version->parse( $ver );
    return( $ver );
}

sub _check_connect_param
{
    my $self  = shift( @_ );
    my $param = $self->SUPER::_check_connect_param( @_ );
    if( !$param->{database_file} && $param->{database} )
    {
        my( $filename, $path, $ext );
        my $uri = CORE::exists( $param->{uri} ) ? $param->{uri} : '';
        my $db = $param->{database} ? $param->{database} : ( $uri->path_segments )[-1];
        $path = $uri ? $uri->path : $db;
        # $db = Cwd::abs_path( $uri ? $uri->path : $db );
        # $db = File::Spec->rel2abs( $path );
        $db = $self->new_file( $path );
        # If we cannot find the file and it does not end with .sqlite, let's add the extension
        # So the user can provide the database parameter just like database => 'test' or database => './test'
        $db = "$db.sqlite" if( !-e( $db ) && $db !~ /\.sqlite$/i );
        # ( $filename, $path, $ext ) = File::Basename::fileparse( $db, qr/\.[^\.]+$/ );
        ( $filename, $path, $ext ) = $db->baseinfo( qr/\.[^\.]+$/ );
        $param->{database} = $filename;
        $param->{database_file} = $self->{database_file} = $db;
    }
    $param->{host} = 'localhost' if( !length( $param->{host} ) );
    $param->{port} = 0 if( !length( $param->{port} ) );
    return( $param );
}

sub _check_default_option
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Provided option is not a hash reference." ) ) if( !$self->_is_hash( $opts => 'strict' ) );
    $opts->{sqlite_unicode} = 1 if( !CORE::exists( $opts->{sqlite_unicode} ) );
    return( $opts );
}

sub _connection_options
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    my @sqlite_params = grep( /^sqlite_/, keys( %$param ) );
    my $opt = $self->SUPER::_connection_options( $param );
    @$opt{ @sqlite_params } = @$param{ @sqlite_params };
    return( $opt );
}

sub _connection_parameters
{
    my $self  = shift( @_ );
    my $param = shift( @_ );
    # Even though login, password, server, host are not used, I was hesitating, but decided to leave them as ok, and ignore them
    # Or maybe should I issue an error when they are provided?
    my $core = [qw( db login passwd host port driver database server opt uri debug cache_connections cache_table unknown_field )];
    my @sqlite_params = grep( /^sqlite_/, keys( %$param ) );
    # See DBD::SQLite for the list of valid parameters
    # E.g.: sqlite_open_flags sqlite_busy_timeout sqlite_use_immediate_transaction sqlite_see_if_its_a_number sqlite_allow_multiple_statements sqlite_unprepared_statements sqlite_unicode sqlite_allow_multiple_statements sqlite_use_immediate_transaction
    push( @$core, @sqlite_params );
    return( $core );
}

sub _dbi_connect
{
    my $self = shift( @_ );
    my $dbh  = $self->{dbh} = $self->SUPER::_dbi_connect( @_ );
    # my $func = $self->{_func};
    my $func = $self->{_func};
    foreach my $k ( sort( keys( %$PRIVATE_FUNCTIONS ) ) )
    {
        my $this = $PRIVATE_FUNCTIONS->{ $k };
        my $ref =
        {
        name => $k,
        argc => $this->[0],
        code => $this->[1],
        };
        $func->{ $k } = $ref;
    }
    foreach my $name ( sort( keys( %$func ) ) )
    {
        my $ref = $func->{ $name };
        if( $ref->{_registered_on} )
        {
            next;
        }
        $self->sql_function_register( $ref );
        $ref->{_registered_on} = time();
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
    # No value was actually provided
    return if( !length( $str ) );
    # try-catch
    local $@;
    my $tz = eval
    {
        return( DateTime::TimeZone->new( name => 'local' ) );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $error = 0;
    my $opt = 
    {
        pattern     => '%Y-%m-%d %T',
        locale      => 'en_GB',
        time_zone   => $tz->name,
        on_error    => sub{ $error++ },
    };
    # 2019-06-19 23:23:57.000000000+0900
    # From PostgreSQL: 2019-06-20 11:02:36.306917+09
    # ISO 8601: 2019-06-20T11:08:27
    if( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})(?:\.\d+)?((?:\+|\-)\d{2,4})?/ )
    {
        my( $date, $time, $zone ) = ( "$1-$2-$3", $4, $5 );
        if( !length( $zone ) )
        {
            my $dt = DateTime->now( time_zone => $tz );
            my $offset = $dt->offset;
            # e.g. 9 or possibly 9.5
            my $offset_hour = ( $offset / 3600 );
            # e.g. 9.5 => 0.5 * 60 = 30
            my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
            $zone  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
        }
        $date =~ tr/\//-/;
        $zone .= '00' if( length( $zone ) == 3 );
        $str = "$date $time$zone";
        $opt->{pattern} = '%Y-%m-%d %T%z';
    }
    # From SQLite: 2019-06-20 02:03:14
    # From MySQL: 2019-06-20 11:04:01
    elsif( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})/ )
    {
        my( $date, $time ) = ( "$1-$2-$3", $4 );
        my $dt = DateTime->now( time_zone => $tz );
        my $offset = $dt->offset;
        # e.g. 9 or possibly 9.5
        my $offset_hour = ( $offset / 3600 );
        # e.g. 9.5 => 0.5 * 60 = 30
        my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
        my $offset_str  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
        $date =~ tr/\//-/;
        $str = "$date $time$offset_str";
        $opt->{pattern} = '%Y-%m-%d %T%z';
    }
    elsif( $str =~ /^(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})$/ )
    {
        $str = "$1-$2-$3";
        $opt->{pattern} = '%Y-%m-%d';
    }
    my $strp = DateTime::Format::Strptime->new( %$opt );
    my $dt = $strp->parse_datetime( $str );
    return( $dt );
}

# Private function
sub _ceiling
{
    my $self = shift( @_ );
    my @args = @_;
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

    # try-catch
    local $@;
    my $tz = eval
    {
        return( DateTime::TimeZone->new( name => 'local' ) );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $d = DateTime->from_epoch( epoch => time(), time_zone => $tz->name );
    return( $d->ymd( '-' ) );
}

sub _curtime
{
    my $self = shift( @_ );
    my @args = @_;
    # try-catch
    local $@;
    my $tz = eval
    {
        return( DateTime::TimeZone->new( name => 'local' ) );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $d = DateTime->now( time_zone => $tz->name );
    return( $d->hms( ':' ) );
}

# e.g. Monday
sub _dayname
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_name );
}

# E.g.: 17
sub _dayofmonth
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day );
}

# timestamp, [integer] 1 to 7
sub _dayofweek
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_of_week );
}

# E.g.: 170
sub _dayofyear
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    return( $dt->day_of_year );
}

# http://stackoverflow.com/questions/10034636/postgres-longitude-longitude-query
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
    # try-catch
    local $@;
    my $tz = eval
    {
        return( DateTime::TimeZone->new( name => 'local' ) );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $origin = DateTime->new(
        year       => 0,
        month      => 1,
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 0,
        time_zone => $tz,
    );
    my $epoch = DateTime->from_epoch( epoch => 0, time_zone => $tz );
    # https://stackoverflow.com/questions/821423/how-can-i-calculate-the-number-of-days-between-two-dates-in-perl#7111718
    my $epoch_days = $epoch->delta_days( $origin )->delta_days();
    my $days_since_epoch = $from_days - int( $epoch_days );
    my $dt = DateTime->from_epoch( epoch => ( $days_since_epoch * 86400 ), time_zone => $tz );
    return( $dt );
}

sub _from_unixtime
{
    my $self = shift( @_ );
    my @args = @_;
    return if( $args[0] !~ /^\d+$/ );
    # try-catch
    local $@;
    my $tz = eval
    {
        return( DateTime::TimeZone->new( name => 'local' ) );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $dt = DateTime->from_epoch( epoch => $args[0], time_zone => $tz->name );
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
    $self->_load_class( 'Module::Generic::Number' ) || return( $self->pass_error );
    my $fmt = Module::Generic::Number->new( $num );
    # 1 means with trailing zeros
    return( $fmt->format(
        thousand => $tho,
        decimal  => $dec,
        precision => $prec,
        decimal_fill => 1,
    ));
}

sub _placeholder_regexp { return( $PLACEHOLDER_REGEXP ) }

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
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        $args[$i] =~ s/'/\\'/g;
    }
    my $eval = "CORE::sprintf( '" . join( "', '", @args ) . "' )";
    my $res = eval( $eval );
    # return( CORE::sprintf( @args ) );
    return( $res );
}

sub _to_days
{
    my $self = shift( @_ );
    my @args = @_;
    my $dt = $self->_parse_timestamp( $args[0] ) || return;
    # try-catch
    local $@;
    my $tz = eval
    {
        return( DateTime::TimeZone->new( name => 'local' ) );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $origin = DateTime->new(
        year       => 0,
        month      => 1,
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 0,
        time_zone => $tz->name,
    );
    # https://stackoverflow.com/questions/821423/how-can-i-calculate-the-number-of-days-between-two-dates-in-perl#7111718
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
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    my $self = CORE::shift( @_ );
    CORE::return if( !CORE::defined( $self ) );
    my $class = ref( $self ) || $self;
    if( $self->{sth} )
    {
        # print( STDERR "DESTROY(): Terminating sth '$self' for query:\n$self->{ 'query' }\n" ) if( $DEBUG );
        $self->{sth}->finish();
    }
    elsif( $self->{dbh} && $class =~ /^AI\:\:DB\:\:Postgres$/ )
    {
        local( $SIG{__WARN__} ) = sub { };
        # $self->{dbh}->disconnect();
#         if( $DEBUG )
#         {
#             my( $pack, $file, $line, $sub ) = ( caller( 0 ) )[ 0, 1, 2, 3 ];
#             my( $pack2, $file2, $line2, $sub2 ) = ( caller( 1 ) ) [ 0, 1, 2, 3 ];
#             print( STDERR "DESTROY database handle ($self) [$self->{ 'query' }]\ncalled within sub '$sub' ($sub2) from package '$pack' ($pack2) in file '$file' ($file2) at line '$line' ($line2).\n" );
#         }
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

1;

# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DB::Object::SQLite - DB Object SQLite Driver

=head1 SYNOPSIS

    use DB::Object;

    my $dbh = DB::Object->connect({
        driver => 'SQLite',
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

    v1.2.0

=head1 DESCRIPTION

This package inherits from L<DB::Object>, so any method not here, but there you can use.

L<DB::Object::SQLite> is a SQL API much alike L<DBD::SQLite>.
So why use a private module instead of using that great L<DBD::SQLite> package?

At first, I started to inherit from C<DBI> to conform to C<perlmod> perl 
manual page and to general perl coding guidlines. It became very quickly a 
real hassle. Barely impossible to inherit, difficulty to handle error, too 
much dependent from an API that change its behaviour with new versions.
In short, I wanted a better, more accurate control over the SQL connection.

So, L<DB::Object::SQLite> acts as a convenient, modifiable wrapper that provide the
programmer with an intuitive, user-friendly and hassle free interface.

=head1 CONSTRUCTOR

=head2 new

Create a new instance of L<DB::Object::SQLite>. Nothing much to say.

=head2 connect

Same as L<DB::Object/connect>, only specific to SQLite.

See L</_connection_params2hash>

=head1 METHODS

=head2 alias

This is inherited from L<DB::Object/alias>

=head2 as_string

This is inherited from L<DB::Object/as_string>

=head2 avoid

This is inherited from L<DB::Object/avoid>

=head2 attribute

Sets or get the value of database connection parameters.

If only one argument is provided, returns its value.
If multiple arguments in a form of pair => value are provided, it sets the corresponding database parameters.

The authorised parameters are:

=over 4

=item * C<ActiveKids>

Is read-only.

=item * C<AutoCommit>

Can be changed.

=item * C<AutoInactiveDestroy>

Can be changed.

=item * C<CachedKids>

Is read-only.

=item * C<ChildHandles>

Is read-only.

=item * C<ChopBlanks>

Can be changed.

=item * C<CursorName>

Is read-only.

=item * C<Driver>

Is read-only.

=item * C<ErrCount>

Can be changed.

=item * C<Executed>

Is read-only.

=item * C<FetchHashKeyName>

Can be changed.

=item * C<HandleError>

Can be changed.

=item * C<HandleSetErr>

Can be changed.

=item * C<InactiveDestroy>

Can be changed.

=item * C<Kids>

Is read-only.

=item * C<NAME>

Is read-only.

=item * C<NULLABLE>

Is read-only.

=item * C<NUM_OF_FIELDS>

Is read-only.

=item * C<NUM_OF_PARAMS>

Is read-only.

=item * C<Name>

Is read-only.

=item * C<PRECISION>

Is read-only.

=item * C<PrintError>

Can be changed.

=item * C<PrintWarn>

Can be changed.

=item * C<Profile>

Can be changed.

=item * C<RaiseError>

Can be changed.

=item * C<RowCacheSize>

Is read-only.

=item * C<RowsInCache>

Is read-only.

=item * C<SCALE>

Is read-only.

=item * C<ShowErrorStatement>

Can be changed.

=item * C<Statement>

Is read-only.

=item * C<TYPE>

Is read-only.

=item * C<Taint>

Can be changed.

=item * C<TaintIn>

Can be changed.

=item * C<TaintOut>

Can be changed.

=item * C<TraceLevel>

Can be changed.

=item * C<Type>

Can be changed.

=item * C<Username>

Is read-only.

=item * C<Warn>

Can be changed.

=item * C<sqlite_allow_multiple_statements>

Can be changed.

=item * C<sqlite_see_if_its_a_number>

Can be changed.

=item * C<sqlite_unicode>

Can be changed.

=item * C<sqlite_unprepared_statements>

Is read-only.

=item * C<sqlite_use_immediate_transaction>

Can be changed.

=item * C<sqlite_version>

Is read-only.

=back

=head2 available_drivers

Return the list of available drivers.

This is an inherited method from L<DB::Object/available_drivers>

=head2 begin_work

Mark the beginning of a transaction.

Any arguments provided are passed along to L<DBD::SQLite/begin_work>

=head2 bind

This is an inherited method from L<DB::Object/bind>

=head2 cache

This is an inherited method from L<DB::Object/cache>

=head2 can_update_delete_limit

Returns the boolean value for the SQLite compiled option C<ENABLE_UPDATE_DELETE_LIMIT> by calling L</has_compile_option>

=head2 check_driver

This is an inherited method from L<DB::Object/check_driver>

=head2 commit

Make any change to the database irreversible.

This must be used only after having called L</begin_work>

Any arguments provided are passed along to L<DBD::SQLite/commit>

=head2 compile_options

Returns the cached list of SQLite compiled options. The cached file is in the file C<sql_sqlite_compile_options.cfg> in the sytem directory.

=head2 connect

Same as L<DB::Object/connect>, only specific to SQLite.

It sets C<sqlite_unicode> to a true value in the connection parameters returned by L</_connection_params2hash>

See L</_connection_params2hash>

=head2 copy

This is an inherited method from L<DB::Object/copy>

=head2 create_table

This is an inherited method from L<DB::Object/create_table>

=head2 data_sources

This is an inherited method from L<DB::Object/data_sources>

=head2 data_type

This is an inherited method from L<DB::Object/data_type>

=head2 database

This is an inherited method from L<DB::Object/database>

=head2 database_file

Returns the file path to the database file.

=head2 databases

Returns a list of databases, which in SQLite, means a list of opened sqlite database files.

=head2 datatype_dict

Returns an hash reference of each data type with their equivalent C<constant>, regular expression (C<re>), constant C<name> and C<type> name.

Each data type is an hash with the following properties for each type: C<constant>, C<name>, C<re>, C<type>

=head2 delete

This is an inherited method from L<DB::Object/database>

=head2 disconnect

This is an inherited method from L<DB::Object/disconnect>

=head2 do

This is an inherited method from L<DB::Object/do>

=head2 enhance

This is an inherited method from L<DB::Object/enhance>

=head2 func

Provided with a table name and a function name and this will call L<DB::SQLite> passing it the table name and the function name.

It returns the value received from the function call.

=head2 get_sql_type

Provided with a data type as a string and this returns a SQLite constant suitable to be passed to L<DBI/bind_param>

=head2 having

A convenient wrapper to L<DB::Object::SQLite::Query/having>

=head2 has_compile_option

Provided with a compile option (the character case is irrelevant) and this will check if it exists or not.

=head2 last_insert_id

=head2 lock

This is an unsupported feature in SQLIte

=head2 on_conflict

See L<DB::Object::SQLite::Tables/on_conflict>

=head2 pragma

This is still a work in progress.

=head2 replace

Just like for the INSERT query, L</replace> takes one optional argument representing a L<DB::Object::SQLite::Statement> SELECT object or a list of field-value pairs.

If a SELECT statement is provided, it will be used to construct a query of the type of REPLACE INTO mytable SELECT FROM other_table

Otherwise the query will be REPLACE INTO mytable (fields) VALUES(values)

In scalar context, it execute the query and in list context it simply returns the statement handler.

=head2 register_function

This takes an hash reference of parameters and will register a new function by calling L<DBD::SQLite/sql_function_register>

Possible options are:

=over 4

=item * C<code>

Anonymous code to be executed when the function is called.

=item * C<func>

This is an hash reference representing registry of functions. The value for each key is the option hash reference.

=item * C<flags>

An array reference of flags

=item * C<name>

The function name

=back

=head2 remove_function

Provided with a function name and this will remove it.

It returns false if there is no function, or returns the options hash reference originally set for the function removed.

=head2 returning

A convenient wrapper to L<DB::Object::Postgres::Query/returning>

=head2 rollback

Will roll back any changes made to the database since the last transaction point marked with L</begin_work>

=head2 sql_function_register

Provided with an hash reference of options and this will register a sql function by calling L<DBD::SQLite/sqlite_create_function>

Possible options are:

=over 4

=item * C<argc>

The function arguments

=item * C<code>

Anonymous perl code to be executed when the function is called

=item * C<flags>

An array reference of flags. Those flags are joined with C<|> and L<perlfunc/eval>'ed

=item * C<name>

The function name

=back

=head2 stat

Provided with an hash or hash reference of parameters and this will call L<DBD::SQLite/sqlite_status> and get the hash reference of values returned.

If the option I<reset> is set, then this will call L<DBD::SQLite/sqlite_status> passing it 0 to reset it instead.

If the option I<type> is specified, this will return the equivalent property from the stat hash reference returned by L<DBD::SQLite/sqlite_status>, otherwise, it will return the hash in list context and the hash reference of stat properties in scalar context.

=head2 table_info

Provided with a table name and this will retrieve the table information as an hash reference.

Otherwise, if nothing can be found, it returns an empty hash reference.

It takes no optional parameters.

Information retrieved are:

=over 4

=item * C<name>

The table name

=item * C<type>

The object type, which may be one of: C<table>, C<view>, C<materialized view>, C<special>, C<foreign table>

=back

=head2 tables

Connects to the database and finds out the list of all available tables.

Returns undef or empty list in scalar or list context respectively if no table found.

Otherwise, it returns the list of table in list context or a reference of it in scalar context.

=head2 tables_info

Provided with a database or using by default the current database and this will issue a query to get an array reference of all tables.

It returns the array reference.

=head2 trace

Trace is unsupported on SQLite.

=head2 unlock

Unlock is unsupported on SQLite.

=head2 variables

Variables are unsupported on SQLite.

=head2 version

This returns the, possibly cached, SQLite server version as a L<version> object.

=head2 _check_connect_param

This returns an hash reference of connection parameters.

If there is no L</database_file> currently set, it will use the property I<uri>.

The database is taken from the property I<database>, or derived from the last path segment of the I<uri>.

The database file is made absolute and is et as the I<database_file> property

The database is name, if not set, is derived from the base path of the I<database_file>

The I<host> property is set to C<localhost> and I<port> property to C<0>

It returns the hash reference of parameters thus processed.

=head2 _check_default_option

Provided with an hash or hash reference of options and this will check it and set some default value.

The only default property this sets is C<sqlite_unicode> to true.

It returns the hash reference of options.

=head2 _connection_options

Provided with an hash reference of parameters and this will check them and returns an hash reference of options who name start with C<sqlite_>

=head2 _connection_parameters

Provided with an hash or hash reference of connection parameters and this will extra all the properties that start with C<sqlite_/> and add them to an array of core properties: db login passwd host port driver database server opt uri debug

It returns those properties as an array reference.

=head2 _dbi_connect

This calls L<DB::Connect/_dbi_connect> and do more driver specific processing.

It will register all the functions set in the global hash reference C<$PRIVATE_FUNCTIONS> which is a function name to code reference pairs. For each of those function, they will be added by calling L</sql_function_register>

It returns the database handler object (L<DBD::Object::SQLite>)

=head2 _dsn

Using the L</database_file> set and this will issue a connection to the SQLite database file.

If the file does not exist or is not writable, this will return an error, otherwise this will return the string representing the dsn, which are connection parameters separated by C<;>

=head2 _parse_timestamp

Provided a string and this will parse it to return a L<DateTime> object.

=head1 SQLITE FUNCTIONS AVAILABLE

=head2 ceiling

This is a sql function to be registered automatically upon connection to the SQLite database file.

It leverages L<POSIX/ceil>

=head2 concat

This returns the arguments provided concatenated as a string.

=head2 curdate

Returns a string representing the year, month and date separated by a C<->

This is computed using L<DateTime>

=head2 curtime

Returns a string representing the hours, minutes and seconds separated by a C<:>

This is computed using L<DateTime>

=head2 dayname

Based on a datetime that is parsed using L</_parse_timestamp>, this returns the day name of the week, such as C<Monday>

=head2 dayofmonth

Based on a datetime that is parsed using L</_parse_timestamp>, this returns the day of the month, such as 17.

=head2 dayofweek

Based on a datetime that is parsed using L</_parse_timestamp>, this returns the day of the week as a number from 1 to 7 with 1 being Monday

=head2 dayofyear

Based on a datetime that is parsed using L</_parse_timestamp>, this returns the day of the year, such as a number from 1 to 365, or possibly 366 depending on the year.

=head2 distance_miles

Provided with an original latitude, longitude and a target latitude and longitude and this will calculate the distance between the 2.

See the source L<StackOverflow post on which this function is based|http://stackoverflow.com/questions/10034636/postgres-longitude-longitude-query>.

=head2 from_days

Calculate the number of days since January 1st of year 0 and returns a L<DateTime> object.

=head2 from_unixtime

Provided with a unix timestamp, and this will return a datetime string such as C<YYYY-mm-dd HH:MM:SS>

=head2 hour

Provided with a date time, and this will parse it and return the hour.

=head2 lcase

Provided with a string and this returns its lower case value.

=head2 left

Provided with a string and an integer C<n> and this will return a substring capturing the nth first characters.

=head2 locate

This essentially does the same as L<perlfunc/index>

=head2 log10

Provided with a number and this returns its logarithm base 10.

=head2 minute

Provided with a date time, and this will parse it and return the minutes.

=head2 month

Provided with a date time, and this will parse it and return the month.

=head2 monthname

Provided with a date time, and this will parse it and return the month name.

=head2 number_format

Provided with a number, a thousand separator, a decimal separator and a decimal precision and this will format the number accordingly and return it as a string.

=head2 power

Provided with a number and a power, and this will return the number powered

=head2 quarter

Provided with a date time, and this will parse it and return the quarter.

=head2 query_object

Set or gets the SQLite query object (L<DB::Object::SQLite::Query>) used to process and format queries.

=head2 rand

This takes no argument and simply returns a random number using L<perlfunc/rand>

=head2 regexp

Provided with a regular expression and the string to test, and this will test the regular expression and return true if it matches or false otherwise.

=head2 replace

Provided with a string, some term to replace and a replacement string and this will do a perl substitution and return the resulting string.

=head2 right

Provided with a string and an integer n and this will return the nth right most characters.

=head2 second

Provided with a date time, and this will parse it and return the seconds.

=head2 space

Provided with an integer and this will return as much spaces.

=head2 sprintf

This behaves like L<perlfunc/sprintf> and provided with a template and some arguments, it will return a formatted string.

=head2 to_days

Provided with a date time, and this will return the number of days since January 1st of year 0.

=head2 ucase

This returns the string provided with all its characters in upper case.

=head2 unix_timestamp

Provided with a date time and this will returns its unix timestamp representation.

=head2 week

Provided with a date time, and this will parse it and return the week.

=head2 weekday

Provided with a date time, and this will parse it and return the day of the week.

=head2 year

Provided with a date time, and this will parse it and return the day of the year.

=head1 SEE ALSO

L<DBI>, L<Apache::DBI>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
