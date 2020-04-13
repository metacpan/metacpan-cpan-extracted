# -*- perl -*-
##----------------------------------------------------------------------------
## DB/Object/Postgres/Tables.pm
## Version 0.4.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/09/11
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to separate the object of the tables from the main
## DB::Object package so that when they get DESTROY'ed, it does not interrupt
## the SQL connection
##----------------------------------------------------------------------------
package DB::Object::Postgres::Tables;
BEGIN
{
    require 5.6.0;
    use strict;
    our( $VERSION, $VERBOSE, $DEBUG );
    use parent qw( DB::Object::Tables DB::Object::Postgres );
    $VERSION    = '0.4.1';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
};

sub init
{
	return( shift->DB::Object::Tables::init( @_ ) );
}

##----{ End of generic routines }----##
## Inherited from DB::Object::Tables
## sub alter

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
            $self->message( 3, "wantarray in void context" );
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

## Inherited from DB::Object::Tables
## sub default

sub drop
{
    my $self  = shift( @_ );
    my $table = $self->{table} || 
    return( $self->error( "No table was provided to drop." ) );
    my $opts  = @_ == 1 ? shift( @_ ) : { @_ };
    my $query = "DROP TABLE";
    $query   .= " IF EXISTS" if( $opts->{ 'if-exists' } );
    $query   .= " $table";
    if( $opts->{ 'cascade' } )
    {
    	$query .= " CASCADE";
    }
    ## Default Postgres behavior
    elsif( $opts->{restrict} )
    {
    	$query .= " RESTRICT";
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

sub exists
{
	return( shift->table_exists( shift( @_ ) ) );
}

## Inherited from DB::Object::Tables
## sub fields

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

## Inherited from DB::Object::Tables
## sub name

## Inherited from DB::Object::Tables
## sub null

## Inherited from DB::Object::Tables
## sub primary

sub qualified_name_v1
{
    my $self = shift( @_ );
    my $name = $self->name;
    my $schema = $self->schema;
    return( $name ) if( !$name || $name eq 'public' );
    my $path = $self->database_object->search_path || return( $name );
    if( scalar( grep( /^$schema$/, @$path ) ) )
    {
    	return( $name );
    }
    else
    {
    	return( "$schema.$name" );
    }
}

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

sub structure
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || $self->{ 'table' } ||
    do
    {
        $self->error( "No table provided to get its structure." );
        return( wantarray() ? () : undef() );
    };
    ## $self->message( 3, "Getting table $table structure." );
    ## $self->_reset_query();
    ## delete( $self->{ 'query_reset' } );
    ## my $struct  = $self->{ '_structure_real' } || $self->{ 'struct' }->{ $table };
    my $struct  = $self->{structure};
    my $fields  = $self->{fields};
    my $default = $self->{default};
    my $null    = $self->{null};
    my $types   = $self->{types};
    if( !%$fields || !%$struct || !%$default )
    {
    	$self->message( 3, "No structure, field, default values, null or types set yet for this table '$table' object. Populating." );
    	## my $query = "SELECT * FROM information_schema.columns WHERE table_name = ?";
#     	my $query = <<EOT;
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
        'character'			=> 'char',
        };
        ## Mysql: field, type, null, key, default, extra
        ## Postgres: tablename, field, field_num, type, len, comment, is_nullable, key, foreign_key, default 
        while( $ref = $sth->fetchrow_hashref() )
        {
        	$self->{ 'type' } = $ref->{ 'table_type' } if( !$self->{ 'type' } );
        	$self->{ 'schema' } = $ref->{ 'schema_name' } if( !$self->{ 'schema' } );
            my %data = map{ lc( $_ ) => $ref->{ $_ } } keys( %$ref );
            if( exists( $type_convert->{ $data{ 'type' } } ) )
            {
            	$data{ 'type' } = $type_convert->{ $data{ 'type' } };
            }
            $data{ 'default' } = '' if( !defined( $data{ 'default' } ) );
            ## push( @order, $data{ 'field' } );
            $fields->{ $data{ 'field' } }  = ++$c;
            $types->{ $data{ 'field' } } = $data{ 'type' };
            $default->{ $data{ 'field' } } = '';
            if( CORE::length( $data{default} ) )
            {
				$default->{ $data{ 'field' } } = $data{ 'default' } if( $data{ 'default' } ne '' && !$data{ 'is_nullable' } );
            }
            $null->{ $data{ 'field' } } = $data{ 'is_nullable' } ? 1 : 0;
            my @define = ( $data{ 'type' } );
            push( @define, "DEFAULT '$data{ 'default' }'" ) if( $data{ 'default' } ne '' || !$data{ 'is_nullable' } );
            push( @define, "NOT NULL" ) if( !$data{ 'is_nullable' } );
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
        $self->{ 'types' }	   = $types;
        ## $self->message( 3, "Fields found: ", sub{ $self->dumper( $fields ) } );
    }
    ## $self->messagef( 3, "struct ($struct) has %d keys:\n%s", scalar( keys( %$struct ) ), $self->printer( $struct ) );
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
    ## Do nothing
    ## DB::Object::Tables are never destroyed.
    ## They are just gateway to tables, and they are cached by DB::Object::Postgres::table()
    ## print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

__END__

