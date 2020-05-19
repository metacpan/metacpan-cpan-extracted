# -*- perl -*-
##----------------------------------------------------------------------------
## DB/Object/SQLite/Tables.pm
## Version 0.3
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/06/18
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to separate the object of the tables from the main
## DB::Object package so that when they get DESTROY'ed, it does not interrupt
## the SQL connection
##----------------------------------------------------------------------------
package DB::Object::SQLite::Tables;
BEGIN
{
    require 5.6.0;
    use strict;
    our( $VERSION, $VERBOSE, $DEBUG );
    use parent qw( DB::Object::SQLite DB::Object::Tables );
    $VERSION    = '0.3';
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
        $opt->{comment} = "'" . quotemeta( $opt->{comment} ) . "'" if( exists( $opt->{comment} ) );
        $opt->{password} = "'" . $opt->{password} . "'" if( exists( $opt->{password} ) );
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
            $self->message( "wantarray in void context" );
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
    push( @opt, "TYPE = $info->{type}" ) if( $info->{type} );
    my $addons = $info->{ 'create_options' };
    if( $addons )
    {
        $addons =~ s/(\A|\s+)([\w\_]+)\s*=\s*/$1\U$2\E=/g;
        push( @opt, $addons );
    }
    push( @opt, "COMMENT='" . quotemeta( $info->{comment} ) . "'" ) if( $info->{comment} );
    my $str = "CREATE TABLE $table (\n\t" . CORE::join( ",\n\t", @output ) . "\n)";
    $str   .= ' ' . CORE::join( ' ', @opt ) if( @opt );
    $str   .= ';';
    return( @output ? $str : undef() );
}

## Inherited from DB::Object::Tables
## sub default

## Inherited from DB::Object::Tables
## sub drop

sub exists
{
    return( shift->table_exists( shift( @_ ) ) );
}

sub lock { return( shift->error( "There is no table locking in SQLite." ) ); }

## Inherited from DB::Object::Tables
## sub name

## Inherited from DB::Object::Tables
## sub null

## Inherited from DB::Object::Tables
## sub primary

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
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to rename table '$table' into '$new':\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to rename table '$table' into '$new':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

## https://www.sqlite.org/pragma.html#pragma_table_info
sub structure
{
    my $self  = shift( @_ );
    my $table = shift( @_ ) || $self->{table} ||
    do
    {
        $self->error( "No table provided to get its structure." );
        return( wantarray() ? () : undef() );
    };
    my $sth1 = $self->prepare_cached( "SELECT * FROM sqlite_master WHERE name = ?" ) ||
    return( $self->error( "An error occured while preparing the sql query to get the details of table \"$table\": ", $self->errstr() ) );
    $sth1->execute( $table ) || return( $self->error( "An erro occured while executing the sql query to get the details of table \"$table\": ", $sth1->errstr() ) );
    my $def = $sth1->fetchrow_hashref;
    $sth1->finish;
    ## table or view
    $self->{type} = $def->{type};
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
        my $query = <<EOT;
PRAGMA table_info(${table})
EOT
        ## http://www.postgresql.org/docs/9.3/interactive/infoschema-columns.html
        ## select * from information_schema.columns where table_name = 'address'
        my $sth = $self->prepare_cached( $query ) ||
        return( $self->error( "Error while preparing query to get table '$table' columns specification: ", $self->errstr() ) );
        $sth->execute ||
        return( $self->error( "Error while executing query to get table '$table' columns specification: ", $sth->errstr() ) );
        my @primary = ();
        my $ref = '';
        my $c   = 0;
        my $type_convert =
        {
        'int' => 'integer',
        };
        ## Mysql: field, type, null, key, default, extra
        ## Postgres: tablename, field, field_num, type, len, comment, is_nullable, key, foreign_key, default 
        ## SQLite: cid, name, type, notnull, dflt_value, pk
        while( $ref = $sth->fetchrow_hashref() )
        {
            my %data = map{ lc( $_ ) => $ref->{ $_ } } keys( %$ref );
            $data{default} = CORE::delete( $data{dflt_value} );
            $data{field} = CORE::delete( $data{name} );
            $data{key} = CORE::delete( $data{pk} );
            if( exists( $type_convert->{ $data{type} } ) )
            {
                $data{type} = $type_convert->{ $data{type} };
            }
            $data{default} = '' if( !defined( $data{default} ) );
            ## push( @order, $data{ 'field' } );
            $fields->{ $data{field} }  = ++$c;
            $types->{ $data{field} } = $data{ 'type' };
            $default->{ $data{field} } = '';
            $default->{ $data{field} } = $data{ 'default' } if( $data{default} ne '' && $data{notnull} );
            $null->{ $data{field} } = $data{ 'notnull' } ? 0 : 1;
            my @define = ( $data{type} );
            push( @define, "DEFAULT '$data{default}'" ) if( $data{default} ne '' || $data{notnull} );
            push( @define, "NOT NULL" ) if( $data{notnull} );
            push( @primary, $data{field} ) if( $data{key} );
            $struct->{ $data{field} } = CORE::join( ' ', @define );
        }
        $sth->finish();
        if( @primary )
        {
            ## $struct->{ '_primary' } = \@primary;
            $self->{primary} = \@primary;
        }
        ## $self->{ '_structure_real' } = $struct;
        $self->{default}   = $default;
        $self->{fields}    = $fields;
        $self->{structure} = $struct;
        $self->{types}       = $types;
        $self->message( 3, "Fields found: ", sub{ $self->dumper( $fields ) } );
    }
#    $self->message( sprintf( "struct has %d keys", scalar( keys( %$struct ) ) ) );
    return( wantarray() ? () : undef() ) if( !scalar( keys( %$struct ) ) );
    return( wantarray() ? %$struct : \%$struct );
}

sub unlock { return( shift->error( "Locking and unlocking of tables is unsupportde in SQLite." ) ); }

## Inherited from DB::Object
## sub _simple_exist

DESTROY
{
    ## Do nothing
    ## DB::Object::Tables are never destroyed.
    ## They are just gateway to tables, and they are cached by DB::Object::table()
    ## print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

__END__

