# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/SQLite/Tables.pm
## Version v1.0.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2023/11/17
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This package's purpose is to separate the object of the tables from the main
# DB::Object package so that when they get DESTROY'ed, it does not interrupt
# the SQL connection
##----------------------------------------------------------------------------
package DB::Object::SQLite::Tables;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::SQLite DB::Object::Tables );
    use vars qw( $VERSION $DEBUG $TYPE_TO_CONSTANT );
    # <https://metacpan.org/pod/DBD::SQLite::Constants>
    # <https://www.sqlite.org/datatype3.html>
    # <https://metacpan.org/pod/DBD::SQLite::Constants#datatypes-(fundamental_datatypes)>
    # NULL, INTEGER, REAL, TEXT, BLOB
    our $TYPE_TO_CONSTANT =
    {
    qr/^(INT|INTEGER|TINYINT|SMALLINT|MEDIUMINT|BIGINT|UNSIGNED\s+BIG\s+INT|INT2|INT8)/ => { constant => '', name => 'SQLITE_INTEGER', type => 'integer' },
    qr/^(CHARACTER\(\d+\)|VARCHAR\(\d+\)|VARYING\s+CHARACTER\(\d+\)|NCHAR\(\d+\)|NATIVE\s+CHARACTER\(\d+\)|NVARCHAR\(\d+\)|TEXT|CLOB)/  => { constant => '', name => 'SQLITE_TEXT', type => 'text' },
    qr/^BLOB/                                               => { constant => '', name => 'SQLITE_BLOB', type => 'blob' },
    qr/^(REAL|DOUBLE\s+DOUBLE\s+PRECISION|FLOAT)/           => { constant => '', name => 'SQLITE_FLOAT', type => 'float' },
    qr/^(NUMERIC|DECIMAL\(\d+,\d+\)|BOOLEAN|DATETIME|DATE)/ => { constant => '', name => 'SQLITE_NULL', type => 'bool' },
    };
    our $DEBUG = 0;
    our $VERSION = 'v1.0.0';
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
    type            => qr/^(ISAM|MYISAM|HEAP)$/i,
    auto_increment  => qr/^(1|0)$/,
    avg_row_length  => qr/^\d+$/,
    checksum        => qr/^(1|0)$/,
    comment         => qr//,
    max_rows        => qr/^\d+$/,
    min_rows        => qr/^\d+$/,
    pack_keys       => qr/^(1|0)$/,
    password        => qr//,
    delay_key_write => qr/^\d+$/,
    row_format      => qr/^(default|dynamic|static|compressed)$/i,
    raid_type       => qr/^(?:1|STRIPED|RAID0|RAID_CHUNKS\s*=\s*\d+|RAID_CHUNKSIZE\s*=\s*\d+)$/,
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
    # Check statement
    my $select = '';
    if( $sth && ref( $sth ) && ( $sth->isa( 'DB::Object::Statement' ) || $sth->can( 'as_string' ) ) )
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
        my $tdef   = CORE::join( ' ', map{ "\U$_\E = $opt->{ $_ }" } @options );
        if( !$def && !$select )
        {
            return( $self->error( "Lacking table '$table' structure information to create it." ) );
        }
        $query .= join( ' ', $def, $tdef, $select );
        my $new = $self->prepare( $query ) ||
            return( $self->error( "Error while preparing query to create table '$table':\n$query", $self->errstr() ) );
        # Trick so other method may follow, such as as_string(), fetchrow(), rows()
        if( !defined( wantarray() ) )
        {
            $new->execute ||
                return( $self->error( "Error while executing query to create table '$table':\n$query", $new->errstr() ) );
        }
        $self->reset_structure;
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
    push( @opt, "TYPE = $info->{type}" ) if( $info->{type} );
    my $addons = $info->{create_options};
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

# NOTE: sub default is inherited from DB::Object::Tables
# sub default

# NOTE: sub drop is inherited from DB::Object::Tables
# sub drop

sub exists { return( shift->table_exists( shift( @_ ) ) ); }

sub lock { return( shift->error( "There is no table locking in SQLite." ) ); }

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
    return( $q->on_conflict( @_ ) ) if( !defined( wantarray() ) );
    if( wantarray() )
    {
        my( @val ) = $q->on_conflict( @_ ) || return( $self->pass_error( $q->error ) );
        return( @val );
    }
    else
    {
        my $val = $q->on_conflict( @_ ) || return( $self->pass_error( $q->error ) );
        return( $val );
    }
}

sub rename
{
    my $self  = shift( @_ );
    my $table = $self->{table} ||
        return( $self->error( 'No table was provided to rename' ) );
    my $new   = shift( @_ ) ||
        return( $self->error( "No new table name was provided to rename table '$table'." ) );
    if( $new !~ /^[a-zA-Z][\w\_]+$/ )
    {
        return( $self->error( "Bad new table name '$new'." ) );
    }
    my $query = "ALTER TABLE $table RENAME TO $new";
    my $sth   = $self->prepare( $query ) ||
        return( $self->error( "Error while preparing query to rename table '$table' into '$new':\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute ||
            return( $self->error( "Error while executing query to rename table '$table' into '$new':\n$query", $sth->errstr() ) );
    }
    $self->reset_structure;
    return( $sth );
}

# TODO: Must implement a cache mechanism for DB::Object::SQLite::structure()
# <https://www.sqlite.org/pragma.html#pragma_table_info>
sub structure
{
    my $self  = shift( @_ );
    return( $self->_clone( $self->{_cache_structure} ) ) if( $self->{_cache_structure} && !CORE::length( $self->{_reset_structure} // '' ) );
    my $table = $self->{table} ||
        return( $self->error( "No table provided to get its structure." ) );
    my $sth1 = $self->prepare_cached( "SELECT * FROM sqlite_master WHERE name = ?" ) ||
        return( $self->error( "An error occured while preparing the sql query to get the details of table \"$table\": ", $self->errstr() ) );
    $sth1->execute( $table ) ||
        return( $self->error( "An error occured while executing the sql query to get the details of table \"$table\": ", $sth1->errstr ) );
    my $def = $sth1->fetchrow_hashref;
    $sth1->finish;
    # table or view
    $self->{type} = $def->{type};
    my $struct  = $self->{structure};
    my $fields  = $self->{fields};
    my $types_dict = $self->database_object->datatype_dict;
    $self->_load_class( 'DB::Object::Fields::Field' ) || return( $self->pass_error );
    my $q = $self->_reset_query;
    # .header on
    # PRAGMA table_info('dummy');
    # cid|name|type|notnull|dflt_value|pk
    my $query = "PRAGMA table_info(${table})";
    # <https://www.sqlite.org/pragma.html>
    my $sth = $self->database_object->prepare_cached( $query ) ||
        return( $self->error( "Error while preparing query to get table '$table' columns specification: ", $self->errstr() ) );
    $sth->execute ||
        return( $self->error( "Error while executing query to get table '$table' columns specification: ", $sth->errstr() ) );
    my @primary = ();
    my $ref = '';
    my $c   = 0;
    # Mysql: field, type, null, key, default, extra
    # Postgres: tablename, field, field_num, type, len, comment, is_nullable, key, foreign_key, default 
    # SQLite: cid, name, type, notnull, dflt_value, pk
    while( $ref = $sth->fetchrow_hashref() )
    {
        $self->messagec( 6, "Checking table ${table} field {green}", $ref->{name}, "{/} with type {green}", $ref->{type}, "{/} -> ", sub{ $self->Module::Generic::dump( $ref ) } );
        my $def =
        {
        name            => $ref->{name},
        default         => $ref->{dflt_value},
        is_nullable     => ( $ref->{notnull} ? 0 : 1 ),
        is_primary      => ( $ref->{is_primary} ? 1 : 0 ),
        pos             => ++$c,
        #query_object    => $q,
        size            => undef,
        type            => $ref->{type},
        #table_object    => $self,
        };
        if( $def->{type} =~ /^([^\(]+)\(([^\)]+)\)$/ )
        {
            @$def{qw( type size )} = ( $1, $2 );
        }

        my( $const_def, $dict );
        if( CORE::exists( $types_dict->{ $def->{type} } ) )
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
        }
        $self->messagec( 6, "\tField {green}", $def->{name}, "{/} has type {green}", $def->{type}, "{/}, not null is {green}", $ref->{notnull}, "{/} and dictionary -> ", sub{ $self->Module::Generic::dump( $def ) } );
        $def->{query_object} = $q;
        $def->{table_object} = $self;
        my @define = ( $def->{type} );
        push( @define, "DEFAULT '$def->{default}'" ) if( defined( $def->{default} ) && length( $def->{default} // '' ) );
        push( @define, "NOT NULL" ) if( $ref->{notnull} );
        push( @primary, $def->{name} ) if( $ref->{pk} );
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
    $self->{fields} = $fields;
    $self->{_cache_structure} = $struct;
    return( $self->_clone( $struct ) );
}

sub unlock { return( shift->error( "Locking and unlocking of tables is unsupportde in SQLite." ) ); }

# NOTE: sub _simple_exist is inherited from DB::Object
# sub _simple_exist

DESTROY
{
    # Do nothing
    # DB::Object::Tables are never destroyed.
    # They are just gateway to tables, and they are cached by DB::Object::table()
    # print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::SQLite::Tables - SQLite Table Object

=head1 SYNOPSIS

    use DB::Object::SQLite::Tables;
    my $this = DB::Object::SQLite::Tables->new || die( DB::Object::SQLite::Tables->error, "\n" );

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

This is a SQLite table object class.

=head1 METHODS

=head2 create

This creates a table.

It takes some array reference data containing the columns definitions, some optional parameters and a statement handler.

If a statement handler is provided, then no need to provide an array reference of columns definition. The columns definition will be taken from the statement handler. However, at least either one of them needs to be provided to set the columns definition.

Possible parameters are:

=over 4

=item * C<comment>

=item * C<password>

=item * C<temporary>

If provided, this will create a temporary table.

=back

This will return an error if the table already exists, so best to check beforehand with L</exists>.

Upon success, it will return the new statement to create the table. However, if L</create> is called in void context, then the statement is executed right away and returned.

=head2 create_info

This returns the create info for the current table object as a string representing the sql script necessary to recreate the table.

=head2 exists

Returns true if the current table exists, or false otherwise.

=head2 lock

Table lock is unsupported in SQLite and this will return an error.

=head2 on_conflict

A convenient wrapper to L<DB::Object::Postgres::Query/on_conflict>

This feature is available in SQLite since version 3.35.0 released on 2021-03-12. If your version of SQLIte is anterior, this will return an error.

=head2 rename

Provided with a new table name, and this will prepare the necessary query to rename the table and return the statement handler.

If it is called in void context, the statement handler is executed immediately.

    # Get the prefs table object
    my $tbl = $dbh->pref;
    $tbl->rename( 'prefs' );
    # Would issue a statement handler for the query: ALTER TABLE pref RENAME TO prefs

See L<SQLite documentation for more information|https://www.sqlite.org/lang_altertable.html>

=head2 structure

This returns in list context an hash and in scalar context an hash reference of the table structure.

The hash, or hash reference returned contains the column name and its definition.

This method will also set the following object properties:

=over 4

=item * L<DB::Object::Tables/type>

The table type.

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

=head2 unlock

This returns an error as C<unlock> is unsupported in SQLite

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
