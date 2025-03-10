# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Postgres/Statement.pm
## Version v0.302.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2023/11/07
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This package's purpose is to automatically terminate the statement object and
# separate them from the connection object (DB::Object).
# Connection object last longer than statement objects
##----------------------------------------------------------------------------
package DB::Object::Postgres::Statement;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Statement DB::Object::Postgres );
    use vars qw( $VERSION $DEBUG );
    use DBD::Pg ':pg_types';
    our $DEBUG = 0;
    our $VERSION = 'v0.302.0';
};

use strict;
use warnings;

# NOTE: sub bind_param is inherited from DB::Object::Statement
# sub bind_param

# sub commit is called by dbh, so it is in DB::Object::Postgres

sub disable_trigger
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{all} //= 0;
    $opts->{name} //= '';
    my $query = $self->{query} ||
        return( $self->error( "No query found to temporarily disable trigger." ) );
    my $q = $self->query_object;
    my $tables = $q->join_tables->length ? $q->join_tables : $self->new_array( $q->table_object );
    my( $before, $after );
    if( $tables->length > 1 )
    {
        $before = $tables->map(sub
        {
            my $tbl = shift( @_ );
            return( 'ALTER TABLE ' . $tbl->name . ' DISABLE TRIGGER ' . ( $opts->{all} ? 'ALL' : 'USER' ) . ';' );
        })->join( ' ' );
        $after = $tables->map(sub
        {
            my $tbl = shift( @_ );
            return( 'ALTER TABLE ' . $tbl->name . ' ENABLE TRIGGER ' . ( $opts->{all} ? 'ALL' : 'USER' ) . ';' );
        })->join( ' ' );
    }
    else
    {
        my $tbl = $q->table_object;
        $before = 'ALTER TABLE ' . $tbl->name . ' DISABLE TRIGGER ' . ( $opts->{name} ? $opts->{name} : $opts->{all} ? 'ALL' : 'USER' ) . ';';
        $after  = 'ALTER TABLE ' . $tbl->name . ' ENABLE TRIGGER ' . ( $opts->{name} ? $opts->{name} : $opts->{all} ? 'ALL' : 'USER' ) . ';';
    }
    my $new = "${before} ${query}; ${after}";
    $q->query( $new );
    my $sth = $self->table_object->_cache_this( $q ) ||
        return( $self->error( "Error while preparing new query temporarily disabling triggers:\n$new" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new query temporarily disabling triggers:\n$new" ) );
    }
    return( $sth );
}

# Customised for Postgres
sub distinct
{
    my $self = shift( @_ );
    my $what = @_ > 1 ? join( ', ', @_ ) : shift( @_ );
    my $query = $self->{query} ||
        return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    # ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( SELECT );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be distinct:\n$query" ) );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DISTINCT|ALL)[[:blank:]]+/i );
    my $clause = defined( $what ) ? "DISTINCT ON ($what)" : "DISTINCT";
    
    $query =~ s/^([[:blank:]]*)($allowed)([[blank:]]+)/$1$2 $clause /;
    # my $sth = $self->prepare( $query ) ||
    # $self->{ 'query' } = $query;
    # saving parameters to bind later on must have been done previously
    my $sth = $self->_cache_this( $query ) ||
        return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute ||
            return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

# Customised for Postgres
sub dump
{
    my $self  = shift( @_ );
    my $args  = $self->_get_args_as_hash( @_ );
    my $vsep  = ",";
    my $hsep  = "\n";
    my $width = 35;
    $self->_load_class( 'IO::File' ) || return( $self->pass_error );
    my $fh    = IO::File->new;
    $fh->fdopen( fileno( STDOUT ), "w" );
    $vsep  = $args->{vsep} if( exists( $args->{vsep} ) );
    $hsep  = $args->{hsep} if( exists( $args->{hsep} ) );
    $width = $args->{width} if( exists( $args->{width} ) );
    my @fields = ();
    # my $fields_ref = $self->{sth}->FETCH( 'NAME' );
    my $fields_ref = $self->{sth}->{NAME};
    if( defined( $fields_ref ) && ref( $fields_ref ) eq 'ARRAY' )
    {
        @fields = @$fields_ref;
    }
    else
    {
        return( $self->error( "No array reference of fields could be retrieved from statement '$self->{sth}'." ) );
    }
    return( $self->error( "No query to dump." ) ) if( !exists( $self->{sth} ) );
    if( exists( $args->{file} ) )
    {
        $self->_load_class( 'DateTime' ) || return( $self->pass_error );
        # new_file is inherited from Module::Generic and calls Module::Generic::File
        my $file = $self->new_file( $args->{file} );
        $fh = $file->open( '>', { binmode => 'utf8' }) ||
            return( $self->error( "Unable to open file $file in write mode: ", $file->error ) );
        # my @header = sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields );
        my @header = sort{ $a <=> $b } @fields;
        my $date = DateTime->now;
        my $table = $self->{table};
        $fh->printf( "# Generated on %s for table $table\n", $date->strftime( '%c' ) );
        $fh->print( "# ", CORE::join( "\t", @header ), "\n" );
        my @data = ();
        while( @data = $self->fetchrow() )
        {
            $fh->print( CORE::join( "\t", @data ), "\n" );
        }
        $fh->close();
        $self->finish();
        return( $self );
    }
    elsif( exists( $args->{fh} ) )
    {
        if( !fileno( $args->{fh} ) )
        {
            return( $self->error( "The file descriptor provided does not seem to be valid (not open)" ) );
        }
        $fh = IO::File->new_from_fd( $args->{fh}, 'w' ) || return( $self->error( $! ) );
    }
    my $max = 0;
    # foreach my $field ( keys( %$fields ) )
    foreach my $field ( @fields )
    {
        $max = length( $field ) if( length( $field ) > $max );
    }
    my $template = '';
    # foreach my $field ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
    foreach my $field ( @fields )
    {
        $template .= "$field" . ( '.' x ( $max - length( $field ) ) ) . ": %s\n";
    }
    $template .= "\n";
    my @data = ();
    while( @data = $self->fetchrow )
    {
        $fh->printf( $template, @data );
    }
    $self->finish;
    return( $self );
}

# NOTE: sub execute is inherited from DB::Object::Statement
# sub execute

# NOTE: sub executed is inherited from DB::Object::Statement
# sub executed

# NOTE: sub fetchall_arrayref is inherited from DB::Object::Statement
# sub fetchall_arrayref($@)

# NOTE: sub fetchcol is inherited from DB::Object::Statement
# sub fetchcol($;$)

# NOTE: sub fetchhash is inherited from DB::Object::Statement
# sub fetchhash(@)

# NOTE: sub fetchrow is inherited from DB::Object::Statement
# sub fetchrow(@)

# NOTE: field_types -> TYPE
# <https://metacpan.org/pod/DBI#TYPE>
sub field_types { return( shift->_get_statement_attribute( 'pg_type' ) ); }

# NOTE: sub finish is inherited from DB::Object::Statement
# sub finish

sub ignore
{
    return( shift->error( "INSERT | UPDATE | ALTER IGNORE is not supported by Postgres." ) );
}

# NOTE: sub join is inherited from DB::Object::Statement
# sub join

# NOTE: sub object is inherited from DB::Object::Statement
# sub object

sub last_insert_id
{
    my $self = shift( @_ );
    return( $self->database_object->last_insert_id( undef(), undef(), $self->table_object->name, undef() ) );
}

sub name
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{sth}->{pg_prepare_name} = shift( @_ );
    }
    return( $self->{sth}->{pg_prepare_name} );
}

sub only
{
    my $self     = shift( @_ );
    my $table    = $self->{table} ||
        return( $self->error( "No table provided to perform select statement." ) );
    my $q        = $self->query_object || return( $self->error( "No query formatter object was set" ) );
    my $tbl_o    = $q->table_object || $self->{table_object} || return( $self->error( "No table object is set." ) );
    my $db       = $tbl_o->database();
    my $multi_db = $tbl_o->param( 'multi_db' );
    my $type = uc( ( $self->{query} =~ /^(SELECT|DELETE|INSERT|UPDATE)\b/i )[0] );
    my @query = ();
    if( $type eq 'SELECT' )
    {
        my $fields = $q->selected_fields;
        @query = $multi_db ? ( "SELECT $fields FROM ONLY $db.$table" ) : ( "SELECT $fields FROM ONLY $table" );
    }
    elsif( $type eq 'DELETE' )
    {
        @query = $multi_db ? ( "DELETE FROM ONLY $db.$table" ) : ( "DELETE FROM ONLY $table" );
    }
    elsif( $type eq 'UPDATE' )
    {
        my $qv = $q->query_values || 
            return( $self->error( "Something went wrong. No query values found. Please investigate." ) );
        return( $self->error( "I was expecting a scalar reference for uery values, but got instead '$qv'." ) ) if( !$self->_is_scalar( $qv ) );
        my $values = $$qv;
        @query = ( "UPDATE ONLY $table SET $values" );
    }
    # Other type such as INSERT or TRUNCATE are not applicable, so we just ignore if we were ever called by mistake.
    else
    {
        return( $self );
    }
    my $clauses = $q->_query_components;
    push( @query, @$clauses ) if( @$clauses );
    my $query = $q->{query} = CORE::join( ' ', @query );
    my $sth = $tbl_o->_cache_this( $q );
    if( !defined( $sth ) )
    {
        return( $self->error( "Error while preparing query to select on table '$self->{table}':\n$query", $self->errstr() ) );
    }
    if( !defined( wantarray() ) )
    {
        $sth->execute ||
            return( $self->error( "Error while executing query to select:\n", $self->as_string(), $sth->errstr() ) );
    }
    return( $sth );
}

sub priority
{
    return( shift->error( "Priority is not supported in Postgres." ) );
}

# rollback is called using the dbh handler and is located in DB::Object::Postgres

# NOTE: sub rows is inherited from DB::Object::Statement
# sub rows(@)

# NOTE: sub undo is inherited from DB::Object::Statement
# sub undo

# Does nothing in Postgres. This is a Mysql feature
sub wait
{
    return( shift( @_ ) );
}

sub _convert_datetime2object
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $sth = $opts->{statement} || return( $self->error( "No statement handler was provided to convert data from json to perl." ) );
    # my $data = $opts->{data} || return( $self->error( "No data was provided to convert from json to perl." ) );
    return( $opts->{data} ) if( !CORE::length( $opts->{data} ) );
    return( $opts->{data} ) if( !$sth->rows );
    my $data  = $opts->{data};
    # my $names = $sth->FETCH('NAME');
    # my $types = $sth->FETCH('pg_type');
    # Get the cached field names and types that we stored after executing the query, but before we finished reading the statement
    my $names = $self->_cache_field_names;
    my $types = $self->_cache_field_types;
    my $mode = ref( $data );

    for( my $i = 0; $i < scalar( @$names ); $i++ )
    {
        if( $types->[$i] eq PG_DATE || 
            $types->[$i] eq PG_TIMESTAMP || 
            $types->[$i] eq 'date' || 
            $types->[$i] eq 'timestamp' )
        {
            if( $mode eq 'ARRAY' )
            {
                for( my $j = 0; $j < scalar( @$data ); $j++ )
                {
                    next if( !$data->[ $j ]->{ $names->[ $i ] } );
                    my $dt = $self->_convert_string2datetime( $data->[ $j ]->{ $names->[ $i ] } );
                    if( !defined( $dt ) )
                    {
                        warn( $self->error );
                    }
                    $data->[ $j ]->{ $names->[ $i ] } = $dt;
                }
            }
            elsif( $mode eq 'HASH' )
            {
                next if( !$data->{ $names->[ $i ] } );
                my $dt = $self->_convert_string2datetime( $data->{ $names->[ $i ] } );
                if( !defined( $dt ) )
                {
                    warn( $self->error );
                }
                $data->{ $names->[ $i ] } = $dt;
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
    # $data can be either hash pr array
    my $sth = $opts->{statement} || return( $self->error( "No statement handler was provided to convert data from json to perl." ) );
    # my $data = $opts->{data} || return( $self->error( "No data was provided to convert from json to perl." ) );
    return( $opts->{data} ) if( !CORE::length( $opts->{data} ) );
    my $data = $opts->{data};
    # my $names = $sth->FETCH('NAME');
    # my $types = $sth->FETCH('pg_type');
    my $names = $self->_cache_field_names;
    my $types = $self->_cache_field_types;
    my $mode = ref( $data );
    for( my $i = 0; $i < scalar( @$names ); $i++ )
    {
        if( $types->[$i] eq PG_JSON || $types->[$i] eq PG_JSONB || $types->[$i] eq 'json' || $types->[$i] eq 'jsonb' )
        {
            if( $self->_is_array( $data ) )
            {
                for( my $j = 0; $j < scalar( @$data ); $j++ )
                {
                    next if( !$data->[ $j ]->{ $names->[ $i ] } );
                    my $ref = $self->_decode_json( $data->[ $j ]->{ $names->[ $i ] } );
                    $data->[ $j ]->{ $names->[ $i ] } = $ref if( $ref );
                }
            }
            elsif( $self->_is_hash( $data => 'strict' ) )
            {
                my $ref = $self->_decode_json( $data->{ $names->[ $i ] } );
                $data->{ $names->[ $i ] } = $ref if( $ref );
            }
        }
    }
    return( $data );
}

# NOTE: DESTROY
DESTROY
{
    # Do nothing but existing so it is handled by this package
    # print( STDERR "DESTROY'ing statement $self ($self->{ 'query' })\n" );
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Postgres::Statement - PostgreSQL Statement Object

=head1 SYNOPSIS

    use DB::Object::Postgres::Statement;
    my $this = DB::Object::Postgres::Statement->new || 
        die( DB::Object::Postgres::Statement->error, "\n" );

=head1 VERSION

    v0.302.0

=head1 DESCRIPTION

This is a PostgreSQL specific statement object class. It inherits from L<DB::Object::Statement>

=head1 METHODS

=head2 disable_trigger

Provided some hash or hash reference of options and this will modify the current query to temporarily disable trigger and return a new statement handler object.

If it is called in void context, then the statement is executed immediately and returned, otherwise it is just returned.

For example, let's say you have a table C<properties> and you do not want properties to be removed, but instead marked as C<deleted> and to achieve that you create a table trigger that is triggered B<before> the C<delete> query is executed and does instead an C<update> setting the property C<status> to C<deleted>.

    CREATE TABLE properties (
         id     SERIAL NOT NULL
        ,name   VARCHAR(255) NOT NULL
        ,status VARCHAR(12) NOT NULL DEFAULT 'active'
        ,CONSTRAINT pk_properties PRIMARY KEY(id)
        ,CONSTRAINT idx_properties UNIQUE(name)
    );

    CREATE OR REPLACE FUNCTION f_properties_table() RETURNS TRIGGER AS $$
        BEGIN
            UPDATE properties SET status = 'deleted' WHERE name = OLD.name;
            -- To prevent the original query from being executed
            RETURN NULL;
        END;
    $$ LANGUAGE 'plpgsql';

    DROP TRIGGER IF EXISTS t_properties_table ON properties;
    CREATE TRIGGER t_properties_table
    BEFORE DELETE ON properties
    FOR EACH ROW EXECUTE PROCEDURE f_properties_table();

If you issued a query like:

    $tbl->insert( name => 'max_connections', status => 'active' );

And then, to remove it:

    $tbl->where( $tbl->fo->name == 'max_connections' );
    $tbl->delete;

The trigger will prevent that property from being removed and instead the row's status will be changed to C<deleted>, but if you B<really> wanted to force remove that property, you would do:

    $tbl->where( $tbl->fo->name == 'max_connections' );
    $tbl->delete->disable_trigger;

And this would execute the following query:

    ALTER TABLE properties DISABLE TRIGGER USER; DELETE FROM properties WHERE name = 'max_connections'; ALTER TABLE properties ENABLE TRIGGER USER;

=head2 distinct

Provided with an optional column and called upon a C<SELECT> query and this will modify the query to add the keyword C<DISTINCT>

    $sth->distinct;
    # produces SELECT DISTINCT....
    $sth->distinct( 'name' );
    # produces SELECT DISTINCT ON (name)....

=head2 dump

This will dump the result of the query to STDOUT or to a file if I<file> argument is provided, or if a filehandle is provided with I<fh>, it will be used to print out the data.

It takes also a I<vsep>, which defaults to a command and a I<hsep> which defaults to a new line.

It returns the current object.

=for Pod::Coverage field_types

=head2 ignore

This returns an error as C<INSERT> | C<UPDATE> | C<ALTER IGNORE> is not supported by PostgreSQL.

=head2 last_insert_id

Will call L<DB::Object/last_insert_id> with the necessary parameters to get the last inserted table id.

=head2 name

Sets or gets the name of the prepared statement. The name set will show up in the PostgreSQL server log.

See L<DBD::Pg/prepare>

=head2 only

Upon being called, this will add the keyword C<ONLY> to the query.

If the original query type is C<SELECT>, this will become something like:

    SELECT some_columns, other FROM ONLY some_table

For C<DELETE> query it would be like:

    DELETE FROM ONLY some_table

For C<UPDATE> query, it would look like:

    UPDATE ONLY some_table 

It returns the current statement object.

See L<PostgreSQL documentation for more information|https://www.postgresql.org/docs/9.5/sql-select.html>

=head2 priority

This is unsupported under PostgreSQL and if used returns an error.

=head2 wait

This is unsupported under PostgreSQL and it will be silently ignore, returning the current object.

=head1 SEE ALSO

L<DB::Object::Statement>, L<DB::Object>, L<DB::Object::Postgres::Query>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
