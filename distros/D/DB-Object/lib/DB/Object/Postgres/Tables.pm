# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres/Tables.pm
## Version v0.5.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2021/08/29
## All rights reserved
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
    use vars qw( $VERSION $VERBOSE $DEBUG $TYPE_TO_CONSTANT );
    $VERSION    = 'v0.5.0';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
    # the 'constant' property in the dictionary hash is added in structure()
    # <https://www.postgresql.org/docs/13/datatype.html>
    our $TYPE_TO_CONSTANT =
    {
    qr/^(bigint|int8)/                  => { constant => '', name => 'PG_INT8', type => 'int8' },
    qr/^(bigserial|serial8)/            => { constant => '', name => 'PG_INT8', type => 'int8' },
    qr/^bit(?!>\s+varying)/             => { constant => '', name => 'PG_BIT', type => 'bit' },
    qr/^(bit\s+varying|varbit)/         => { constant => '', name => 'PG_VARBIT', type => 'varbit' },
    qr/^(boolean|bool)/                 => { constant => '', name => 'PG_BOOL', type => 'bool' },
    qr/^box/                            => { constant => '', name => 'PG_BOX', type => 'box' },
    qr/^bytea/                          => { constant => '', name => 'PG_BYTEA', type => 'bytea' },
    qr/^(character|char)\b/             => { constant => '', name => 'PG_CHAR', type => 'char' },
    qr/^(character varying|varchar)/    => { constant => '', name => 'PG_VARCHAR', type => 'varchar' },
    qr/^cidr\b/                         => { constant => '', name => 'PG_CIDR', type => 'cidr' },
    qr/^circle/                         => { constant => '', name => 'PG_CIRCLE', type => 'circle' },
    qr/^date\b/                         => { constant => '', name => 'PG_DATE', type => 'date' },
    qr/^(double precision|float8)/      => { constant => '', name => 'PG_FLOAT8', type => 'float8' },
    qr/^inet/                           => { constant => '', name => 'PG_INET', type => 'inet' },
    qr/^(integer|int|int4)\b/           => { constant => '', name => 'PG_INT4', type => 'int4' },
    qr/^interval/                       => { constant => '', name => 'PG_INTERVAL', type => 'interval' },
    qr/^json\b/                         => { constant => '', name => 'PG_JSON', type => 'json' },
    qr/^jsonb\b/                        => { constant => '', name => 'PG_JSONB', type => 'jsonb' },
    qr/^line/                           => { constant => '', name => 'PG_LINE', type => 'line' },
    qr/^lseg/                           => { constant => '', name => 'PG_LSEG', type => 'lseg' },
    qr/^macaddr/                        => { constant => '', name => 'PG_MACADDR', type => 'macaddr' },
    qr/^macaddr8/                       => { constant => '', name => 'PG_MACADDR8', type => 'macaddr8' },
    qr/^money/                          => { constant => '', name => 'PG_MONEY', type => 'money' },
    qr/^(numeric|decimal)/              => { constant => '', name => 'PG_NUMERIC', type => 'numeric' },
    qr/^path/                           => { constant => '', name => 'PG_PATH', type => 'path' },
    qr/^pg_lsn/                         => { constant => '', name => 'PG_PG_LSN', type => 'pg_lsn' },
    qr/^point/                          => { constant => '', name => 'PG_POINT', type => 'point' },
    qr/^polygon/                        => { constant => '', name => 'PG_POLYGON', type => 'polygon' },
    qr/^(real|float4)/                  => { constant => '', name => 'PG_FLOAT4', type => 'float4' },
    qr/^(smallint|int2)/                => { constant => '', name => 'PG_INT2', type => 'int2' },
    qr/^(smallserial|serial2)/          => { constant => '', name => 'PG_INT2', type => 'int2' },
    qr/^(serial|serial4)/               => { constant => '', name => 'PG_INT4', type => 'int4' },
    qr/^text/                           => { constant => '', name => 'PG_TEXT', type => 'text' },
    qr/^time(\([^\)]+\))?\s+without\s+time\s+zone/          => { constant => '', name => 'PG_TIME', type => 'time' },
    qr/^(time(\([^\)]+\))?\s+with\s+time\s+zone)|timetz/    => { constant => '', name => 'PG_TIMETZ', type => 'timetz' },
    qr/^timestamp(\([^\)]+\))?\s+without\s+time\s+zone/     => { constant => '', name => 'PG_TIMESTAMP', type => 'timestamp' },
    qr/^(timestamp(\([^\)]+\))?\s+with\s+time\s+zone)|timestamptz/  => { constant => '', name => 'PG_TIMESTAMPTZ', type => 'timestamptz' },
    qr/^tsquery/                        => { constant => '', name => 'PG_TSQUERY', type => 'tsquery' },
    qr/^tsvector/                       => { constant => '', name => 'PG_TSVECTOR', type => 'tsvector' },
    qr/^txid_snapshot/                  => { constant => '', name => 'PG_TXID_SNAPSHOT', type => 'txid_snapshot' },
    qr/^uuid/                           => { constant => '', name => 'PG_UUID', type => 'uuid' },
    qr/^xml/                            => { constant => '', name => 'PG_XML', type => 'xml' },
    };
};

use strict;
use warnings;

sub init
{
    return( shift->DB::Object::Tables::init( @_ ) );
}

# Inherited from DB::Object::Tables
# sub alter

sub create
{
    my $self  = shift( @_ );
    ## $tbl->create( [ 'ROW 1', 'ROW 2'... ], { 'temporary' => 1, 'TYPE' => ISAM }, $obj );
    my $data  = shift( @_ ) || [];
    my $opt   = shift( @_ ) || {};
    my $sth   = shift( @_ );
    my $table = $self->{table};
    ## Set temporary in the object, so we can use it to recreate the table creation info as string:
    ## $table->create( [ ... ], { ... }, $obj )->as_string();
    my $temp  = $self->{temporary} = delete( $opt->{temporary} );
    ## Check possible options
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
    ## Avoid working for nothing, make this condition
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
    ## Check statement
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
        ## Structure of table if any - 
        ## structure may very well be provided using a select statement, such as:
        ## CREATE TEMPORARY TABLE ploppy TYPE=HEAP COMMENT='this is kewl' MAX_ROWS=10 SELECT * FROM some_table LIMIT 0,0
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
        ## Trick so other method may follow, such as as_string(), fetchrow(), rows()
        if( !defined( wantarray() ) )
        {
            # print( STDERR "create(): wantarrays in void context.\n" );
            $new->execute() ||
            return( $self->error( "Error while executing query to create table '$table':\n$query", $new->errstr() ) );
        }
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
    $self->structure();
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

# Inherited from DB::Object::Tables
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
    return( shift->table_exists( shift( @_ ) ) );
}

# Inherited from DB::Object::Tables
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

# Inherited from DB::Object::Tables
# sub name

# Inherited from DB::Object::Tables
# sub null

# Inherited from DB::Object::Tables
# sub primary

sub on_conflict
{
    my $self = shift( @_ );
    my $q = $self->_reset_query;
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
    return( $sth );
}

sub repair { return( shift->error( "repair() is not implemented PostgreSQL." ) ); }

sub stat { return( shift->error( "stat() is not implemented PostgreSQL." ) ); }

sub structure
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || $self->{table} ||
        return( $self->error( "No table provided to get its structure." ) );
    ## $self->_reset_query();
    ## delete( $self->{ 'query_reset' } );
    ## my $struct  = $self->{ '_structure_real' } || $self->{ 'struct' }->{ $table };
    my $struct  = $self->{structure};
    my $fields  = $self->{fields};
    my $default = $self->{default};
    my $null    = $self->{null};
    my $types   = $self->{types};
    # <https://www.postgresql.org/docs/10/datatype.html>
    my $const   = $self->{types_const};
    # If we have a cache, use it instead of reprocessing it.
    if( !%$fields || !%$struct || !%$default )
    {
        ## my $query = "SELECT * FROM information_schema.columns WHERE table_name = ?";
#         my $query = <<EOT;
# SELECT 
#      pg_tables.schemaname as "schema_name"
#     ,pg_tables.tablename as "table_name"
#     ,CASE pg_class.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'table' END as "table_type"
#     ,pg_attribute.attname AS field
#     ,pg_attribute.attnum as field_num
#     ,format_type(pg_attribute.atttypid, NULL) AS "type"
#     ,pg_attribute.atttypmod AS len
#     ,(SELECT col_description(pg_attribute.attrelid, pg_attribute.attnum)) AS comment
#     ,CASE pg_attribute.attnotnull WHEN false THEN 1  ELSE 0 END AS "is_nullable"
#     ,pg_constraint.conname AS "key"
#     ,pc2.conname AS foreign_key
#     ,(SELECT pg_attrdef.adsrc FROM pg_attrdef 
#         WHERE pg_attrdef.adrelid = pg_class.oid 
#         AND pg_attrdef.adnum = pg_attribute.attnum) AS "default" 
# FROM pg_tables, pg_class 
# JOIN pg_attribute ON pg_class.oid = pg_attribute.attrelid 
#     AND pg_attribute.attnum > 0 
# LEFT JOIN pg_constraint ON pg_constraint.contype = 'p'::"char" 
#     AND pg_constraint.conrelid = pg_class.oid AND
#     (pg_attribute.attnum = ANY (pg_constraint.conkey)) 
# LEFT JOIN pg_constraint AS pc2 ON pc2.contype = 'f'::"char" 
#     AND pc2.conrelid = pg_class.oid 
#     AND (pg_attribute.attnum = ANY (pc2.conkey)) 
# WHERE pg_class.relname = pg_tables.tablename  
#     AND pg_attribute.atttypid <> 0::oid  
#     AND tablename = ?
# ORDER BY field_num ASC
# EOT
        my $query;
        if( $self->database_object->version <= 10 )
        {
            $query = <<EOT;
SELECT 
     n.nspname AS "schema_name"
    ,c.relname AS "table_name"
    ,CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'table' END as "table_type"
    ,a.attname AS "field"
    ,a.attnum AS "field_num"
    ,pg_catalog.format_type(a.atttypid,a.atttypmod) AS "type"
    ,CASE a.attnotnull WHEN false THEN TRUE ELSE FALSE END AS "is_nullable"
    ,(SELECT pg_attrdef.adsrc FROM pg_attrdef 
        WHERE pg_attrdef.adrelid = c.oid 
        AND pg_attrdef.adnum = a.attnum) AS "default" 
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
WHERE c.relname = ? AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum
EOT
        }
        else
        {
            $query = <<EOT;
SELECT 
     n.nspname AS "schema_name"
    ,c.relname AS "table_name"
    ,CASE c.relkind WHEN 'r' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' WHEN 's' THEN 'special' WHEN 'f' THEN 'foreign table' WHEN 'p' THEN 'table' END as "table_type"
    ,a.attname AS "field"
    ,a.attnum AS "field_num"
    ,pg_catalog.format_type(a.atttypid,a.atttypmod) AS "type"
    ,CASE a.attnotnull WHEN false THEN TRUE ELSE FALSE END AS "is_nullable"
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
WHERE c.relname = ? AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum
EOT
        }
        ## http://www.postgresql.org/docs/9.3/interactive/infoschema-columns.html
        ## select * from information_schema.columns where table_name = 'address'
        my $sth = $self->database_object->prepare_cached( $query ) ||
        return( $self->error( "Error while preparing query to get table '$table' columns specification: ", $self->database_object->errstr() ) );
        $sth->execute( $table ) ||
        return( $self->error( "Error while executing query to get table '$table' columns specification: ", $sth->errstr() ) );
        my @primary = ();
        my $ref = '';
        my $c   = 0;
        my $type_convert =
        {
        'character varying' => 'varchar',
        'character'         => 'char',
        };
        # Mysql: field, type, null, key, default, extra
        # Postgres: tablename, field, field_num, type, len, comment, is_nullable, key, foreign_key, default 
        while( $ref = $sth->fetchrow_hashref() )
        {
            $self->{type} = $ref->{table_type} if( !$self->{type} );
            $self->{schema} = $ref->{schema_name} if( !$self->{schema} );
            my %data = map{ lc( $_ ) => $ref->{ $_ } } keys( %$ref );
            if( exists( $type_convert->{ $data{type} } ) )
            {
                $data{type} = $type_convert->{ $data{type} };
            }
            $data{default} = '' if( !defined( $data{default} ) );
            ## push( @order, $data{ 'field' } );
            $fields->{ $data{field} }  = ++$c;
            $types->{ $data{field} } = $data{type};
            $default->{ $data{field} } = '';
            if( CORE::length( $data{default} ) )
            {
                $default->{ $data{field} } = $data{default} if( $data{default} ne '' && !$data{is_nullable} );
            }
            $null->{ $data{field} } = $data{is_nullable} ? 1 : 0;
            # Get the constant
            DATA_TYPE_RE: foreach my $re ( keys( %$TYPE_TO_CONSTANT ) )
            {
                if( $data{type} =~ /$re/i )
                {
                    my $dict = \%{$TYPE_TO_CONSTANT->{ $re }};
                    $dict->{constant} = $self->database_object->get_sql_type( $dict->{type} );
                    $const->{ $data{field} } = $dict;
                    last DATA_TYPE_RE;
                }
            }
            my @define = ( $data{type} );
            push( @define, "DEFAULT '$data{default}'" ) if( $data{default} ne '' || !$data{is_nullable} );
            push( @define, "NOT NULL" ) if( !$data{is_nullable} );
            push( @primary, $data{field} ) if( $data{key} );
            $struct->{ $data{field} } = CORE::join( ' ', @define );
        }
        $sth->finish();
        if( @primary )
        {
            # $struct->{_primary} = \@primary;
            $self->{primary} = \@primary;
        }
    }
    return( wantarray() ? () : undef() ) if( !scalar( keys( %$struct ) ) );
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
    my $this = DB::Object::Postgres::Tables->new || die( DB::Object::Postgres::Tables->error, "\n" );

=head1 VERSION

    v0.5.0

=head1 DESCRIPTION

This is a PostgreSQL table object class.

=head1 METHODS

=head2 create

This creates a table.

It takes some array reference data containing the columns definitions, some optional parameters and a statement handler.

If a statement handler is provided, then no need to provide an array reference of columns definition. The columns definition will be taken from the statement handler. However, at least either one of them needs to be provided to set the columns definition.

Possible parameters are:

=over 4

=item I<comment>

=item I<inherits>

Takes the name of another table to inherit from

=item I<on commit>

=item I<tablespace>

=item I<temporary>

If provided, this will create a temporary table.

=item I<with oids>

If true, this will enable table oid

=item I<without oids>

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

=item I<all>

If true, this will disable all trigger on the table. Please note that, as per the L<PostgreSQL documentation|https://www.postgresql.org/docs/10/sql-altertable.html> this requires super user privilege.

If false, this will disable only the user triggers, i.e. not including the system ones.

=item I<name>

If a trigger name is provided, it will be used to specifically disable this trigger.

=back

=head2 drop

This will prepare a drop statement to drop the current table.

If it is called in void context, then the statement is executed immediately and returned, otherwise it is just returned.

It takes the following options:

=over 4

=item I<cascade>

If true, C<CASCADE> will be added to the C<DROP> query.

=item I<if_exists>

If true, this will add a C<IF EXISTS> to the C<DROP> query.

You can also use I<if-exists>

=item I<restrict>

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

=item I<all>

If true, this will enable all trigger on the table. Please note that, as per the L<PostgreSQL documentation|https://www.postgresql.org/docs/10/sql-altertable.html> this requires super user privilege.

If false, this will enable only the user triggers, i.e. not including the system ones.

=item I<name>

If a trigger name is provided, it will be used to specifically enable this trigger.

=back

=head2 exists

Returns true if the current table exists, or false otherwise.

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

This returns in list context an hash and in scalar context an hash reference of the table structure.

The hash, or hash reference returned contains the column name and its definition.

This method will also set the following object properties:

=over 4

=item L<DB::Object::Tables/type>

The table type.

=item L<DB::Object::Tables/schema>

The table schema.

=item I<default>

A column name to default value hash reference

=item I<fields>

A column name to field position (integer) hash reference

=item I<null>

A column name to a boolean representing whether the column is nullable or not.

=item L<DB::Object::Tables/primary>

An array reference of column names that are used as primary key for the table.

=item I<structure>

A column name to its sql definition

=item I<types>

A column name to column data type hash reference

=back

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
