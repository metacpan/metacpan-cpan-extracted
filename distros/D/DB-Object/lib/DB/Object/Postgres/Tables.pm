# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres/Tables.pm
## Version v1.0.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2024/09/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to separate the object of the tables from the main
## DB::Object package so that when they get DESTROY'ed, it does not interrupt
## the SQL connection
##----------------------------------------------------------------------------
package DB::Object::Postgres::Tables;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Tables DB::Object::Postgres );
    use vars qw( $VERSION $DEBUG );
    our $DEBUG = 0;
    our $VERSION = 'v1.0.1';
};

use strict;
use warnings;

sub init
{
    # return( shift->DB::Object::Tables::init( @_ ) );
    my $self = shift( @_ );
    $self->{_init_params_order} = [qw( dbo query_object )];
    $self->{_init_strict_use_sub} = 1;
    $self->DB::Object::Tables::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Inherited from DB::Object::Tables
# sub alter

sub create
{
    my $self  = shift( @_ );
    # $tbl->create( [ 'ROW 1', 'ROW 2'... ], { 'temporary' => 1, 'TYPE' => ISAM }, $obj );
    my $data  = shift( @_ ) || [];
    my $opt   = shift( @_ ) || {};
    my $sth   = shift( @_ );
    my $table = $self->{table};
    # Set temporary in the object, so we can use it to recreate the table creation info as string:
    # $table->create( [ ... ], { ... }, $obj )->as_string();
    my $temp  = $self->{temporary} = delete( $opt->{temporary} );
    # Check possible options
    my $allowed = 
    {
    'inherits'     => qr/^\w+$/i,
    'with oids'    => qr//,
    'without oids' => qr//,
    'on commit'    => qr/^(PRESERVE ROWS|DELETE ROWS|DROP)$/,
    'comment'      => qr//,
    'tablespace'   => qr/^\w+$/,
    };
    my @options = ();
    my @errors  = ();
    # Avoid working for nothing, make this condition
    if( %$opt )
    {
        my %lc_opt  = map{ lc( $_ ) => $opt->{ $_ } } keys( %$opt );
        $opt = \%lc_opt;
        foreach my $key ( keys( %$opt ) )
        {
            next if( $opt->{ $key } =~ /^\s*$/ || !exists( $allowed->{ $key } ) || $key eq "inherits" );
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
    }
    if( @errors )
    {
        warn( "The options '", join( ', ', @errors ), "' were either not recognized or malformed and thus were ignored.\n" );
    }
    # Check statement
    my $select = '';
    if( $sth && ref( $sth ) && ( $sth->isa( "DB::Object::Postgres::Statement" ) || $sth->can( 'as_string' ) ) )
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
        # Structure of table if any - 
        # structure may very well be provided using a select statement, such as:
        # CREATE TEMPORARY TABLE ploppy TYPE=HEAP COMMENT='this is kewl' MAX_ROWS=10 SELECT * FROM some_table LIMIT 0,0
        my $def    = "(\n" . CORE::join( ",\n", @$data ) . "\n)" if( $data && ref( $data ) && @$data );
        $def      .= " INHERITS (" . $opt->{ 'inherits' } . ")" if( $opt->{ 'inherits' } );
        my $tdef   = CORE::join( ' ', map{ "\U$_\E = $opt->{ $_ }" } @options );
        if( !$def && !$select )
        {
            return( $self->error( "Lacking table '$table' structure information to create it." ) );
        }
        $query .= join( ' ', $def, $tdef, $select );
        my $new = $self->database_object->prepare( $query ) ||
        return( $self->error( "Error while preparing query to create table '$table':\n$query", $self->database_object->errstr() ) );
        # Trick so other method may follow, such as as_string(), fetchrow(), rows()
        if( !defined( wantarray() ) )
        {
            # print( STDERR "create(): wantarrays in void context.\n" );
            $new->execute() ||
            return( $self->error( "Error while executing query to create table '$table':\n$query", $new->errstr() ) );
        }
        $self->reset_structure;
        $self->database_object->table_push( $table );
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
    my $table   = $self->{table};
    $self->structure || return( $self->pass_error );
    my $struct  = $self->{structure};
    my $fields  = $self->{fields};
    my $default = $self->{default};
    my $primary = $self->{primary};
    my @output = ();
    foreach my $field ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
    {
        push( @output, "$field $struct->{ $field }" );
    }
    push( @output, "PRIMARY KEY(" . CORE::join( ',', @$primary ) . ")" ) if( $primary && @$primary );
    my $info = $self->stat( $table );
    my @opt  = ();
    my $addons = $info->{create_options};
    if( $addons )
    {
        $addons =~ s/(\A|\s+)([\w\_]+)\s*=\s*/$1\U$2\E=/g;
        push( @opt, $addons );
    }
    push( @opt, "COMMENT='" . quotemeta( $info->{ 'comment' } ) . "'" ) if( $info->{comment} );
    my $str = "CREATE TABLE $table (\n\t" . CORE::join( ",\n\t", @output ) . "\n)";
    $str   .= ' ' . CORE::join( ' ', @opt ) if( @opt );
    $str   .= ';';
    return( @output ? $str : undef() );
}

# NOTE: sub default is inherited from DB::Object::Tables
# sub default

# <https://www.postgresql.org/docs/10/sql-altertable.html>
sub disable_trigger
{
    my $self  = shift( @_ );
    my $table = $self->{table} || 
        return( $self->error( "No table was provided to disable trigger." ) );
    my $opts  = $self->_get_args_as_hash( @_ );
    $opts->{all} //= 0;
    # This feature exists only since version 8.1
    unless( $self->database_object->version >= version->declare( '8.1' ) )
    {
        return( $self->error( "Disabling trigger on a table requires PostgreSQL version 8.1 or higher." ) );
    }
    my $query = 'ALTER TABLE ' . $table . ' DISABLE TRIGGER ';
    if( defined( $opts->{name} ) && length( $opts->{name} ) )
    {
        $query .= $opts->{name};
    }
    else
    {
        $query .= $opts->{all} ? 'ALL' : 'USER';
    }
    my $sth = $self->database_object->prepare( $query ) ||
        return( $self->error( "Error while preparing query to disable trigger for table '$table':\n$query", $self->database_object->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to disable trigger for table '$table':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub drop
{
    my $self  = shift( @_ );
    my $table = $self->{table} || 
    return( $self->error( "No table was provided to drop." ) );
    my $opts  = $self->_get_args_as_hash( @_ );
    my $query = 'DROP TABLE';
    $query   .= ' IF EXISTS' if( $opts->{ 'if-exists' } || $opts->{if_exists} );
    $query   .= " $table";
    if( $opts->{cascade} )
    {
        $query .= ' CASCADE';
    }
    ## Default Postgres behavior
    elsif( $opts->{restrict} )
    {
        $query .= ' RESTRICT';
    }
    my $sth = $self->database_object->prepare( $query ) ||
    return( $self->error( "Error while preparing query to drop table '$table':\n$query", $self->database_object->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to drop table '$table':\n$query", $sth->errstr() ) );
    }
    $self->reset_structure;
    return( $sth );
}

# <https://www.postgresql.org/docs/10/sql-altertable.html>
sub enable_trigger
{
    my $self  = shift( @_ );
    my $table = $self->{table} || 
    return( $self->error( "No table was provided to enable trigger." ) );
    my $opts  = $self->_get_args_as_hash( @_ );
    $opts->{all} //= 0;
    # This feature exists only since version 8.1
    unless( $self->database_object->version >= version->declare( '8.1' ) )
    {
        return( $self->error( "Enabling trigger on a table requires PostgreSQL version 8.1 or higher." ) );
    }
    my $query = 'ALTER TABLE ' . $table . ' ENABLE TRIGGER ';
    if( defined( $opts->{name} ) && length( $opts->{name} ) )
    {
        $query .= $opts->{name};
    }
    else
    {
        $query .= $opts->{all} ? 'ALL' : 'USER';
    }
    my $sth = $self->database_object->prepare( $query ) ||
    return( $self->error( "Error while preparing query to disable trigger for table '$table':\n$query", $self->database_object->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to disable trigger for table '$table':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub exists
{
    my $self = shift( @_ );
    return( $self->table_exists( @_ ? shift( @_ ) : $self->name ) );
}

# NOTE: sub fields is inherited from DB::Object::Tables
# sub fields

sub lock
{
    my $self   = shift( @_ );
    my $table  = $self->{table};
    my $opt    = shift( @_ ) || 'SHARE';
    my $nowait = shift( @_ ) || undef();
    if( $opt !~ /^(ACCESS SHARE|ROW SHARE|ROW EXCLUSIVE|SHARE UPDATE EXCLUSIVE|SHARE|SHARE ROW EXCLUSIVE|EXCLUSIVE|ACCESS EXCLUSIVE)$/i )
    {
        return( $self->error( "Bad table '$table' locking option '$opt'." ) );
    }
    my $query = sprintf( 'LOCK TABLE %s IN %s MODE', $table, $opt );
    $query   .= " NOWAIT" if( $nowait );
    my $sth   = $self->database_object->prepare( $query ) ||
    return( $self->error( "Error while preparing query to do tables locking:\n$query", $self->database_object->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to do tables locking:\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

# NOTE: sub name is inherited from DB::Object::Tables
# sub name

# NOTE: sub null is inherited from DB::Object::Tables
# sub null

# NOTE: sub primary is inherited from DB::Object::Tables
# sub primary

sub on_conflict
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
    # Void
    return( $q->on_conflict( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
        my( @val ) = $q->on_conflict( @_ ) || return( $self->pass_error( $q->error ) );
        return( @val );
    }
    else
    {
        my $val = $q->on_conflict( @_ );
        return( $self->pass_error( $q->error ) ) if( !defined( $val ) );
        return( $val );
    }
}

sub optimize { return( shift->error( "optimize() is not implemented PostgreSQL." ) ); }

sub parent { return( shift->_set_get_scalar( 'parent', @_ ) ); }

sub qualified_name
{
    my $self = shift( @_ );
    my @val = ();
    CORE::push( @val, $self->database_object->database ) if( $self->{prefixed} > 2 );
    CORE::push( @val, $self->schema ) if( $self->{prefixed} > 1 && $self->schema );
    CORE::push( @val, $self->name );
    return( CORE::join( '.', @val ) );
}

sub rename
{
    my $self  = shift( @_ );
    my $table = $self->{table} ||
        return( $self->error( 'No table was provided to rename' ) );
    my $new   = shift( @_ ) ||
        return( $self->error( "No new table name was provided to rename table '$table'." ) );
    if( $new !~ /^[\w\_]+$/ )
    {
        return( $self->error( "Bad new table name '$new'." ) );
    }
    my $query = "ALTER TABLE $table RENAME TO $new";
    my $sth   = $self->database_object->prepare( $query ) ||
        return( $self->error( "Error while preparing query to rename table '$table' into '$new':\n$query", $self->database_object->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
            return( $self->error( "Error while executing query to rename table '$table' into '$new':\n$query", $sth->errstr() ) );
    }
    $self->reset_structure;
    return( $sth );
}

sub repair { return( shift->error( "repair() is not implemented PostgreSQL." ) ); }

sub stat { return( shift->error( "stat() is not implemented PostgreSQL." ) ); }

sub structure
{
    my $self  = shift( @_ );
    return( $self->_clone( $self->{_cache_structure} ) ) if( $self->{_cache_structure} && !CORE::length( $self->{_reset_structure} // '' ) );
    my $table = $self->{table} ||
        return( $self->error( "No table provided to get its structure." ) );
    my $struct  = $self->{structure} // {};
    my $fields  = $self->{fields} // {};
    my $types_dict = $self->database_object->datatype_dict;
    $self->_load_class( 'DB::Object::Fields::Field' ) || return( $self->pass_error );
    my $q = $self->_reset_query;
    # <https://stackoverflow.com/questions/6777456/list-all-index-names-column-names-and-its-table-name-of-a-postgresql-database>

    # If we have a cache, use it instead of reprocessing it.
    # <https://stackoverflow.com/questions/52376045/why-does-atttypmod-differ-from-character-maximum-length>
#     my $query = <<EOT;
# SELECT
#      a.table_schema AS "schema_name"
#     ,CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'table' END as "table_type"
#     ,a.column_name AS "field"
#     ,a.ordinal_position AS "field_num"
#     ,a.column_default AS "default"
#     ,a.*
# FROM information_schema.columns a
# LEFT JOIN pg_catalog.pg_class c ON c.relname = a.table_name
# WHERE a.table_name = ?
# ORDER BY a.ordinal_position
# EOT
    # <https://www.postgresql.org/docs/14/catalog-pg-attrdef.html>
    # We could use:
    # generate_subscripts(i.indkey, 1)
    # instead of:
    # generate_series(1,array_upper(string_to_array(i.indkey::text, ' ' )::int2[],1))
    # but this is not supported by PostgreSQL v8.0; only from v8.4 onward
    my $query = <<EOT;
SELECT 
     n.nspname AS "schema_name"
    ,c.relname AS "table_name"
    ,CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized view'
        WHEN 's' THEN 'special'
        WHEN 'f' THEN 'foreign table'
        WHEN 'p' THEN 'table'
     END as "table_type"
    ,a.attname AS "field"
    ,a.attnum AS "field_num"
    ,CASE
        WHEN a.atttypmod = -1 THEN null
        WHEN t.oid IN (1042, 1043) THEN a.atttypmod - 4
        WHEN t.oid IN (1560, 1562) THEN a.atttypmod
        ELSE NULL
     END AS "character_maximum_length"
    ,CASE SUBSTRING(t.typname,1,1)
        WHEN '_' THEN SUBSTRING(t.typname,2)
        ELSE t.typname
     END AS "data_type"
    ,pg_catalog.format_type(a.atttypid,a.atttypmod) AS "format_type"
    ,a.attndims > 0 AS "is_array"
    ,CASE a.attnotnull
        WHEN FALSE THEN TRUE
        ELSE FALSE
     END AS "is_nullable"
    ,COALESCE(i.indisprimary,false) AS "is_primary"
    ,COALESCE(i.indisunique,false) AS "is_unique"
    ,r.oid IS NOT NULL AS "is_foreign"
    ,r2.oid IS NOT NULL AS "is_check"
    ,(SELECT pg_get_expr(pg_attrdef.adbin, pg_attrdef.adrelid) FROM pg_attrdef 
        WHERE pg_attrdef.adrelid = c.oid 
        AND pg_attrdef.adnum = a.attnum) AS "default"
    ,(SELECT pg_description.description FROM pg_description
        WHERE pg_description.objoid = c.oid AND pg_description.objsubid = a.attnum) AS "comment"
    ,(SELECT c2.relname FROM pg_inherits LEFT JOIN pg_class c2 ON c2.oid = pg_inherits.inhparent
        WHERE pg_inherits.inhrelid = c.oid) AS "table_parent"
    ,c2.relname AS "index_name"
    ,i.indnatts AS "index_n_columns"
    ,i.indkey AS "index_columns"
    ,ARRAY(
        SELECT pg_get_indexdef(i.indexrelid, k, TRUE)
        FROM generate_series(1,array_upper(string_to_array(i.indkey::text, ' ' )::int2[],1)) AS s(k)
        ORDER BY k
    ) AS "index_keys"
    ,r.conname AS "foreign_name"
    ,CASE
        WHEN r.conindid > 0 THEN (SELECT c3.relname FROM pg_catalog.pg_class c3 WHERE c3.oid = r.conindid)
        ELSE NULL
     END AS "foreign_index_name"
    ,CASE
        WHEN r.confrelid > 0 THEN (SELECT c4.relname FROM pg_catalog.pg_class c4 WHERE c4.oid = r.confrelid)
        ELSE NULL
     END AS "foreign_table"
    ,CASE r.confupdtype
        WHEN 'a' THEN 'nothing'
        WHEN 'r' THEN 'restrict'
        WHEN 'c' THEN 'cascade'
        WHEN 'n' THEN 'null'
        WHEN 'd' THEN 'default'
        ELSE NULL
     END AS "foreign_update_action"
    ,CASE r.confdeltype
        WHEN 'a' THEN 'nothing'
        WHEN 'r' THEN 'restrict'
        WHEN 'c' THEN 'cascade'
        WHEN 'n' THEN 'null'
        WHEN 'd' THEN 'default'
        ELSE NULL
     END AS "foreign_delete_action"
    ,CASE r.confmatchtype
        WHEN 'f' THEN 'full'
        WHEN 'p' THEN 'partial'
        WHEN 's' THEN 'simple'
        ELSE NULL
     END AS "foreign_match"
    ,r.conkey AS "foreign_columns"
    ,ARRAY(
        SELECT a2.attname
        FROM generate_series(1,array_upper(r.conkey,1)) AS z(j), pg_catalog.pg_attribute a2
        WHERE a2.attrelid = c.oid AND a2.attnum = r.conkey[j]
    ) AS "foreign_keys"
    ,CASE
        WHEN r.oid IS NOT NULL THEN pg_get_constraintdef(r.oid,TRUE)
        ELSE NULL
     END AS "foreign_expression"
    ,r2.conname AS "check_name"
    ,CASE
        WHEN r2.conindid > 0 THEN (SELECT c3.relname FROM pg_catalog.pg_class c3 WHERE c3.oid = r2.conindid)
        ELSE NULL
     END AS "check_index_name"
    ,r2.conkey AS "check_columns"
    ,ARRAY(
        SELECT a2.attname
        FROM generate_series(1,array_upper(r2.conkey,1)) AS z(j), pg_catalog.pg_attribute a2
        WHERE a2.attrelid = c.oid AND a2.attnum = r2.conkey[j]
    ) AS "check_keys"
    ,CASE
        WHEN r2.oid IS NOT NULL THEN pg_get_constraintdef(r2.oid,TRUE)
        ELSE NULL
     END AS "check_expression"
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
LEFT JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
LEFT JOIN pg_catalog.pg_index i ON i.indrelid = c.oid AND a.attnum = ANY (i.indkey::int[])
LEFT JOIN pg_catalog.pg_class c2 ON c2.oid = i.indexrelid
LEFT JOIN pg_catalog.pg_constraint r ON r.conrelid = c.oid AND r.contype = 'f' AND a.attnum = ANY (r.conkey)
LEFT JOIN pg_catalog.pg_constraint r2 ON r2.conrelid = c.oid AND r2.contype = 'c' AND a.attnum = ANY (r2.conkey)
WHERE
    c.relname = ? AND
    a.attnum > 0 AND
    NOT a.attisdropped
ORDER BY a.attnum
EOT
    # http://www.postgresql.org/docs/9.3/interactive/infoschema-columns.html
    # select * from information_schema.columns where table_name = 'address'
    $self->messagec( 5, "Executing SQL query to get the table structure for table {green}${table}{/}" );
    my $sth = $self->database_object->prepare_cached( $query ) ||
        return( $self->error( "Error while preparing query to get table '$table' columns specification: ", $self->database_object->errstr ) );
    $sth->execute( $table ) ||
        return( $self->error( "Error while executing query to get table '$table' columns specification: ", $sth->errstr ) );
    my $check = {};
    my $foreign = {};
    my $index = {};
    my @primary = ();
    my $ref = '';
    my $c   = 0;
    # Mysql: field, type, null, key, default, extra
    # Postgres: tablename, field, field_num, type, len, comment, is_nullable, key, foreign_key, default 
    while( $ref = $sth->fetchrow_hashref() )
    {
        $self->messagec( 6, "Checking table ${table} field {green}", $ref->{field}, "{/} with type {green}", $ref->{data_type}, "{/} -> ", sub{ $self->Module::Generic::dump( $ref ) } );
        my $def =
        {
        name            => $ref->{field},
        comment         => $ref->{comment},
        default         => $ref->{default},
        ( $ref->{check_name} ? ( check_name => $ref->{check_name} ) : () ),
        ( $ref->{foreign_name} ? ( foreign_name => $ref->{foreign_name} ) : () ),
        ( $ref->{index_name} ? ( index_name => $ref->{index_name} ) : () ),
        is_array        => ( $ref->{is_array} ? 1 : 0 ),
        is_check        => ( $ref->{is_check} ? 1 : 0 ),
        is_foreign      => ( $ref->{is_foreign} ? 1 : 0 ),
        is_nullable     => ( $ref->{is_nullable} ? 1 : 0 ),
        is_primary      => ( $ref->{is_primary} ? 1 : 0 ),
        is_unique       => ( $ref->{is_unique} ? 1 : 0 ),
        pos             => $ref->{field_num},
        # query_object    => $q,
        size            => $ref->{character_maximum_length},
        # When the field is an array, the data type will start with an underscore
        type            => ( substr( $ref->{data_type}, 0, 1 ) eq '_' ? substr( $ref->{data_type}, 1 ) : $ref->{data_type} ),
        # table_object    => $self,
        };
        $self->{type} = $ref->{table_type} if( !$self->{type} );
        $self->{schema} = $ref->{schema_name} if( !$self->{schema} );
        $self->{parent} = $ref->{table_parent} if( !$self->{table_parent} );
        if( $ref->{index_name} &&
            !CORE::exists( $index->{ $ref->{index_name} } ) )
        {
            my $constraint = $self->new_index(
                is_primary  => $ref->{is_primary},
                is_unique   => $ref->{is_unique},
                fields      => $ref->{index_keys},
                name        => $ref->{index_name},
            ) || return( $self->pass_error );
            $index->{ $ref->{index_name} } = $constraint;
        }
        if( $ref->{check_name} &&
            !CORE::exists( $check->{ $ref->{check_name} } ) )
        {
            my $constraint = $self->new_check(
                expr    => $ref->{check_expression},
                fields  => $ref->{check_keys},
                name    => $ref->{check_name},
            ) || return( $self->pass_error );
            $check->{ $ref->{check_name} } = $constraint;
        }
        if( $ref->{foreign_name} &&
            !CORE::exists( $foreign->{ $ref->{foreign_name} } ) )
        {
            my $constraint = $self->new_foreign(
                expr        => $ref->{foreign_expression},
                match       => $ref->{foreign_match},
                on_delete   => $ref->{foreign_delete_action},
                on_update   => $ref->{foreign_update_action},
                table       => $ref->{foreign_table},
                fields      => $ref->{foreign_keys},
                name        => $ref->{foreign_name},
            ) || return( $self->pass_error );
            $foreign->{ $ref->{foreign_name} } = $constraint;
        }

        my( $const_def, $dict );
        if( $def->{is_array} &&
            CORE::exists( $types_dict->{ "$def->{type}array" } ) )
        {
            $const_def = $types_dict->{ "$def->{type}array" };
        }
        elsif( CORE::exists( $types_dict->{ $def->{type} } ) )
        {
            $const_def = $types_dict->{ $def->{type} };
        }
        else
        {
            # Get the constant
            DATA_TYPE_RE: foreach my $type ( keys( %$types_dict ) )
            {
                if( $def->{type} =~ /$types_dict->{ $type }->{re}/i )
                {
                    $const_def = $types_dict->{ $type };
                    last DATA_TYPE_RE;
                }
            }
        }
        if( defined( $const_def ) )
        {
            my $const_keys = [keys( %$const_def )];
            my $dict = {};
            @$dict{ @$const_keys } = @$const_def{ @$const_keys };
            $def->{datatype} = $dict;
            # $def->{type} = $dict->{type};
        }
        $self->messagec( 6, "\tField {green}", $def->{name}, "{/} has type {green}", $def->{type}, "{/} and dictionary -> ", sub{ $self->Module::Generic::dump( $def ) } );
        $def->{query_object} = $q;
        $def->{table_object} = $self;
        my @define = ( $def->{type} );
        push( @define, "DEFAULT '$def->{default}'" ) if( defined( $def->{default} ) && length( $def->{default} // '' ) );
        push( @define, "NOT NULL" ) if( !$def->{is_nullable} );
        push( @primary, $def->{name} ) if( $ref->{key} );
        $struct->{ $def->{name} } = CORE::join( ' ', @define );
        my $field = DB::Object::Fields::Field->new( %$def, debug => $self->debug ) ||
            return( $self->pass_error( DB::Object::Fields::Field->error ) );
        $fields->{ $def->{name} } = $field;
    }
    $sth->finish;
    if( @primary )
    {
        $self->{primary} = \@primary;
    }
    $self->{check}   = $check;
    $self->{fields}  = $fields;
    $self->{foreign} = $foreign;
    $self->{indexes} = $index;
    $self->{_cache_structure} = $struct;
    return( $self->_clone( $struct ) );
}

sub table_info { return( shift->database_object->table_info( @_ ) ); }

sub unlock
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->CORE::unlock( @_ ) );
    }
    my $query = 'UNLOCK TABLES';
    my $sth   = $self->database_object->prepare( $query ) ||
    return( $self->error( "Error while preparing query to unlock tables:\n$query", $self->database_object->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to unlock tables:\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

DESTROY
{
    # Do nothing
    # DB::Object::Tables are never destroyed.
    # They are just gateway to tables, and they are cached by DB::Object::Postgres::table()
    # print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Postgres::Tables - PostgreSQL Table Object

=head1 SYNOPSIS

    use DB::Object::Postgres::Tables;
    my $this = DB::Object::Postgres::Tables->new || 
        die( DB::Object::Postgres::Tables->error, "\n" );

=head1 VERSION

    v1.0.1

=head1 DESCRIPTION

This is a PostgreSQL table object class. It inherits from L<DB::Object::Tables>

=head1 METHODS

=head2 check

Sets or gets an hash reference of check constraint name to an hash of properties for that constraint.

See each driver for the value provided, but available properties typically are:

=over 4

=item * C<expr>

The check constraint expression

=item * C<fields>

The L<array object|Module::Generic::Array> of table columns associated with this check constraint.

=item * C<name>

The check constraint name.

=back

=head2 create

This creates a table.

It takes some array reference data containing the columns definitions, some optional parameters and a statement handler.

If a statement handler is provided, then no need to provide an array reference of columns definition. The columns definition will be taken from the statement handler. However, at least either one of them needs to be provided to set the columns definition.

Possible parameters are:

=over 4

=item * C<comment>

=item * C<inherits>

Takes the name of another table to inherit from

=item * C<on commit>

=item * C<tablespace>

=item * C<temporary>

If provided, this will create a temporary table.

=item * C<with oids>

If true, this will enable table oid

=item * C<without oids>

If true, this will disable table oid

=back

This will return an error if the table already exists, so best to check beforehand with L</exists>.

Upon success, it will return the new statement to create the table. However, if L</create> is called in void context, then the statement is executed right away and returned.

=head2 create_info

This returns the create info for the current table object as a string representing the sql script necessary to recreate the table.

=head2 disable_trigger

    my $sth = $tbl->disable_trigger;
    my $sth = $tbl->disable_trigger( all => 1 );
    my $sth = $tbl->disable_trigger( name => 'my_trigger' );

Provided with some optional parameters and this will return a statement handler to disable all triggers or a given trigger on the table.

If it is called in void context, then the statement is executed immediately and returned, otherwise it is just returned.

    $tbl->disable_trigger;
    # would issue immediately the following query:
    ALTER TABLE my_table DISABLE TRIGGER USER

It takes the following options:

=over 4

=item * C<all>

If true, this will disable all trigger on the table. Please note that, as per the L<PostgreSQL documentation|https://www.postgresql.org/docs/10/sql-altertable.html> this requires super user privilege.

If false, this will disable only the user triggers, i.e. not including the system ones.

=item * C<name>

If a trigger name is provided, it will be used to specifically disable this trigger.

=back

=head2 drop

This will prepare a drop statement to drop the current table.

If it is called in void context, then the statement is executed immediately and returned, otherwise it is just returned.

It takes the following options:

=over 4

=item * C<cascade>

If true, C<CASCADE> will be added to the C<DROP> query.

=item * C<if_exists>

If true, this will add a C<IF EXISTS> to the C<DROP> query.

You can also use I<if-exists>

=item * C<restrict>

If true, C<RESTRICT> will be added to the C<DROP> query.

=back

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/sql-droptable.html>

=head2 enable_trigger

    my $sth = $tbl->enable_trigger;
    my $sth = $tbl->enable_trigger( all => 1 );
    my $sth = $tbl->enable_trigger( name => 'my_trigger' );

Provided with some optional parameters and this will return a statement handler to enable all triggers or a given trigger on the table.

If it is called in void context, then the statement is executed immediately and returned, otherwise it is just returned.

    $tbl->enable_trigger;
    # would issue immediately the following query:
    ALTER TABLE my_table ENABLE TRIGGER USER

It takes the following options:

=over 4

=item * C<all>

If true, this will enable all trigger on the table. Please note that, as per the L<PostgreSQL documentation|https://www.postgresql.org/docs/10/sql-altertable.html> this requires super user privilege.

If false, this will enable only the user triggers, i.e. not including the system ones.

=item * C<name>

If a trigger name is provided, it will be used to specifically enable this trigger.

=back

=head2 exists

Returns true if the current table exists, or false otherwise.

=head2 foreign

Sets or gets an hash reference of foreign key constraint name to an hash of properties for that constraint.

Available properties are:

=over 4

=item * C<expr>

The foreign key expression used when creating the table schema.

=item * C<match>

Typical value is C<full>, C<partial> and C<simple>

=item * C<on_delete>

The action the database is to take upon deletion. For example: C<nothing>, C<restrict>, C<cascade>, C<null> or C<default>

=item * C<on_update>

The action the database is to take upon update. For example: C<nothing>, C<restrict>, C<cascade>, C<null> or C<default>

=item * C<table>

The table name of the foreign key.

=item * C<fields>

The associated table column names for this foreign key constraint.

=item * C<name>

The foreign key constraint name.

=back

=head2 lock

This will prepare a query to lock the table and return the statement handler. If it is called in void context, the statement handler returned is executed immediately.

It takes an optional lock type and an optional C<NOWAIT> parameter.

Supported lock types are:

=over 4

=item C<ACCESS SHARE>

=item C<ROW SHARE>

=item C<ROW EXCLUSIVE>

=item C<SHARE UPDATE EXCLUSIVE>

=item C<SHARE>

=item C<SHARE ROW EXCLUSIVE>

=item C<EXCLUSIVE>

=item C<ACCESS EXCLUSIVE>

=back

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/explicit-locking.html>

=head2 on_conflict

A convenient wrapper to L<DB::Object::Postgres::Query/on_conflict>

=head2 optimize

Not implemented in PostgreSQL.

=head2 parent

This will return the parent table if the current table inherits from another table.

=head2 qualified_name

This return a fully qualified name to be used as a prefix to columns in queries.

If L<DB::Object::Tables/prefixed> is greater than 2, the database name will be added.

If there is a schema defined and the L<DB::Object::Tables/prefixed> is greater than 1, the schema will be added.

At minimum, the table name is added.

    $tbl->prefixed(2);
    $tbl->qualified_name;
    # Would return something like: mydb.my_schema.my_table

    $tbl->prefixed(1);
    $tbl->qualified_name;
    # Would return only: my_table

=head2 rename

Provided with a new table name, and this will prepare the necessary query to rename the table and return the statement handler.

If it is called in void context, the statement handler is executed immediately.

    # Get the prefs table object
    my $tbl = $dbh->pref;
    $tbl->rename( 'prefs' );
    # Would issue a statement handler for the query: ALTER TABLE pref RENAME TO prefs

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/sql-altertable.html>

=head2 repair

Not implemented in PostgreSQL.

=head2 stat

Not implemented in PostgreSQL.

=head2 structure

This returns, in list context, an hash and, in scalar context, an hash reference of the table structure.

The hash, or hash reference returned contains the column name and its definition.

The data returned is cached, so it fetches the information from PostgreSQL only once.

This method will also set the following object properties:

=over 4

=item * L<DB::Object::Tables/type>

The table type.

=item * L<DB::Object::Tables/schema>

The table schema.

=item * C<default>

A column name to default value hash reference

=item * C<fields>

A column name to field position (integer) hash reference

=item * C<null>

A column name to a boolean representing whether the column is nullable or not.

=item * L<DB::Object::Tables/primary>

An array reference of column names that are used as primary key for the table.

=item * C<structure>

A column name to its sql definition

=item * C<types>

A column name to column data type hash reference

=back

=head2 table_info

This is an alias for L<DB::Object::Postgres/table_info>

=head2 unlock

This will unlock a previously locked table.

If an argument is provided, this calls instead C<CORE::unlock> passing it whatever parameters provided.

Otherwise, it will prepare a query C<UNLOCK TABLES> and returns the statement handler.

If it is called in void context, this will execute the statement handler immediately.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
