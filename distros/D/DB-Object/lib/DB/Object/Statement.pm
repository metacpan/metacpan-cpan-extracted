# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Statement.pm
## Version v0.4.2
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2023/03/24
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to automatically terminate the statement object and
## separate them from the connection object (DB::Object).
## Connection object last longer than statement objects
##----------------------------------------------------------------------------
package DB::Object::Statement;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object );
    use vars qw( $VERSION $VERBOSE $DEBUG );
    use Class::Struct qw( struct );
    use Want;
    $VERSION    = 'v0.4.2';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
};

use strict;
use warnings;

sub as_string
{
    my $self = shift( @_ );
    # my $q = $self->_query_object_current;
    # used by select, insert, update, delete to flag that we need to reformat the query
    $self->{as_string}++;
    if( my $qo = $self->query_object )
    {
        $qo->final(1);
    }
    # return( $self->{sth}->{Statement} );
    # Same:
    # return( $q->as_string );
    return( $self->{query} );
}

sub bind_param
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller();
    my $sub = ( caller(1) )[3];
    $self->{pack} = $pack;
    $self->{file} = $file;
    $self->{line} = $line;
    $self->{sub}  = $sub;
    my $rc = 
    eval
    {
        $self->{sth}->bind_param( @_ );
    };
    if( $@ )
    {
        my $err = $self->errstr();
        $err =~ s/ at line \d+.*$//;
        # printf( STDERR "%s in %s at line %d within sub '%s'.\n", $err, $self->{file}, $self->{line}, $self->{sub} );
        # exit(1);
        return( $self->error( $err ) );
    }
    elsif( $rc )
    {
        return( $rc );
    }
    else
    {
        my $err = $@ = $self->{sth}->errstr() || "Unknown error while binding parameters to query.";
        return( $self->error( $err ) );
    }
}

sub commit
{
    my $self = shift( @_ );
    if( $self->{sth} && $self->param( 'autocommit' ) )
    {
        my $sth = $self->prepare( 'COMMIT' ) || return( $self->pass_error );
        $sth->execute() || return( $self->error( "An error occurred while executing query: ", $sth->error ) );
        $sth->finish();
    }
    return( $self );
}

sub database_object { return( shift->_set_get_object_without_init( 'dbo', 'DB::Object', @_ ) ); }

sub distinct
{
    my $self = shift( @_ );
    my $query = $self->{query} ||
        return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[0] );
    # ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( SELECT );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be distinct:\n$query" ) );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DISTINCT|DISTINCTROW|ALL)\s+/i );
    
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 DISTINCT /;
    # my $sth = $self->prepare( $query ) ||
    # $self->{ 'query' } = $query;
    # saving parameters to bind later on must have been done previously
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

sub dump
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    if( $file )
    {
        # Used to be handled by SQL server
        # my $query = $self->as_string();
        # $query    =~ s/(\s+FROM\s+)/ INTO OUTFILE '$file'$1/;
        # my $sth   = $self->prepare( $query ) ||
        # return( $self->error( "Error while preparing query to dump result on select:\n$query" ) );
        # $sth->execute() ||
        # return( $self->error( "Error while executing query to dump result on select:\n$query" ) );
        $self->_load_class( 'DateTime' ) || return( $self->pass_error );
        my $fields = $self->{_fields};
        my @header = sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields );
        # new_file is inherited from Module::Generic
        $file = $self->new_file( $file );
        my $io = $file->open( '>', { binmode => 'utf8' }) ||
            return( $self->error( "Unable to open file '$file' in write mode: ", $file->error ) );
        my $date = DateTime->now;
        my $table = $self->{table};
        $io->printf( "## Generated on %s for table $table\n", $date->strftime( '%c' ) );
        $io->print( "## ", CORE::join( "\t", @header ), "\n" );
        my @data = ();
        while( @data = $self->fetchrow() )
        {
            print( $io CORE::join( "\t", @data ), "\n" );
        }
        $io->close;
        $self->finish;
        return( $self );
    }
    elsif( exists( $self->{sth} ) )
    {
        # my $fields = $self->{ '_fields' };
        my @fields = @{ $self->{sth}->FETCH( 'NAME' ) };
        my $max    = 0;
        # foreach my $field ( keys( %$fields ) )
        foreach my $field ( @fields )
        {
            $max = length( $field ) if( length( $field ) > $max );
        }
        my $template = '';
        ## foreach my $field ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
        foreach my $field ( @fields )
        {
            $template .= "$field" . ( '.' x ( $max - length( $field ) ) ) . ": %s\n";
        }
        $template .= "\n";
        my @data = ();
        while( @data = $self->fetchrow() )
        {
            printf( STDERR $template, @data );
        }
        $self->finish;
        return( $self );
    }
    else
    {
        return( $self->error( "No query to dump." ) );
    }
}

sub exec { return( shift->execute( @_ ) ); }

sub execute
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller();
    my $sub = ( caller(1) )[3];
    # What we want is to get the point from where we were originatly called
    if( $pack =~ /^DB::Object/ )
    {
        for( my $i = 1; $i < 5; $i++ )
        {
            ( $pack, $file, $line ) = caller( $i );
            $sub = ( caller( $i + 1 ) )[3];
            last if( $pack !~ /^DB::Object/ );
        }
    }
    # my $sub = ( caller( 1 ) )[ 3 ];
    $self->{pack} = $pack;
    $self->{file} = $file;
    $self->{line} = $line;
    $self->{sub}  = $sub;
    $self->{executed}++;
    my $q = $self->query_object;
    $q->final(1) if( $q );
    my @binded = ();
    my @binded_types = ();
    if( $q && $q->binded_types->length )
    {
        my $types = $q->binded_types_as_param;
        @binded_types = @$types;
    }
    
#     if( $q && ( $self->{bind} || 
#         ( 
#             ( $q->_query_type eq 'insert' || $q->_query_type eq 'update' ) && 
#             $q->binded_types->length ) 
#         ) )
    if( $q && $self->{bind} )
    {
        # if( @_ && ( $self->_is_hash( $_[0] ) ) )
        if( @_ && 
            (
                # hash reference
                ( @_ == 1 && $self->_is_hash( $_[0] ) ) ||
                # key => value pairs
                ( !( @_ % 2 ) && ref( $_[0] ) ne 'HASH' )
            )
          )
        {
            my $vals = {};
            if( $self->_is_hash( $_[0] ) )
            {
                $vals = shift( @_ );
            }
            else
            {
                $vals = { @_ };
            }
            # This is the list of fields as they appear in the order in insert or update query
            # Knowing their order of appearance is key so we can bind follow-on values to them
            my $sorted = $q->sorted;
            foreach my $f ( @$sorted )
            {
                if( !CORE::exists( $vals->{ $f } ) )
                {
                    push( @binded, undef() );
                }
                # The value may be defined or not, or may be zero length long
                else
                {
                    push( @binded, $vals->{ $f } );
                }
            }
        }
        elsif( @_ )
        {
            push( @binded, @_ );
        }
        else
        {
            my $binded_values = $q->binded;
            push( @binded, @$binded_values ) if( scalar( @$binded_values ) );
        }
    }
    
    @binded = @_ if( ( !@binded && @_ ) || @_ );
    @binded = () if( !@binded );
    if( $q && $q->is_upsert )
    {
        if( scalar( @binded_types ) > scalar( @binded ) )
        {
            CORE::push( @binded, @binded );
        }
    }
    
    if( scalar( @_ ) )
    {
        my $temp = {};
        for( my $i = 0; $i < scalar( @_ ); $i++ )
        {
            # { $some_value => 'varchar' }
            if( ref( $_[$i] ) eq 'HASH' && 
                scalar( keys( %{$_[$i]} ) ) == 1 &&
                # e.g. DBI::SQL_VARCHAR or DBI::SQL_INTEGER
                DBI->can( "SQL_" . uc( [values( %{$_[$i]} )]->[0] ) ) )
            {
                my $constant = DBI->can( "SQL_" . uc( [values( %{$_[$i]} )]->[0] ) );
                $temp->{$i} = { type => $constant->(), value => [keys( %{$_[$i]} )]->[0] };
            }
        }
    
        # The user has chosen to override any datatype computed and be explicit.
        if( scalar( keys( %$temp ) ) == scalar( @_ ) )
        {
            @binded = @_;
        }
        elsif( scalar( keys( %$temp ) ) )
        {
            foreach my $i ( sort( keys( %$temp ) ) )
            {
                CORE::splice( @binded_types, $i, 0, $temp->{ $i }->{type} );
                $binded[$i] = $temp->{ $i }->{value};
            }
        }
    }
    
    # $sth->exec({ $my_value => DBI::SQL_VARCHAR });
#     for( my $i = 0; $i < scalar( @binded ); $i++ )
#     {
#         # { $some_value => 'varchar' }
#         if( ref( $binded[$i] ) eq 'HASH' && 
#             scalar( keys( %{$binded[$i]} ) ) == 1 &&
#             # e.g. DBI::SQL_VARCHAR or DBI::SQL_INTEGER
#             DBI->can( "SQL_" . uc( [values( %{$binded[$i]} )]->[0] ) ) )
#         {
#             my $constant = DBI->can( "SQL_" . uc( [values( %{$binded[$i]} )]->[0] ) );
#             # Get the DBI SQL contant value and add it as a type
#             CORE::splice( @binded_types, $i, 0, $constant->() );
#             # Replace our current value with the actual value
#             $binded[$i] = [keys( %{$binded[$i]} )]->[0];
#         }
#     }
    
    if( $q && scalar( @binded ) != scalar( @binded_types ) )
    {
        warn( sprintf( "Warning: total %d bound values does not match the total %d bound types ('%s')! Check the code for query $self->{sth}->{Statement}...\n", scalar( @binded ), scalar( @binded_types ), CORE::join( "','", @binded_types ) ) );
        # Cancel it, because it will create problems
        @binded_types = ();
    }
    
    # If there are any array object of some sort provided, make sure they are transformed into a regular array so DBD::Ph can then transform it into a Postgres array.
    for( my $i = 0; $i < scalar( @binded ); $i++ )
    {
        next if( !defined( $binded[$i] ) );
        if( $self->_is_array( $binded[$i] ) && 
            ref( $binded[$i] ) ne 'ARRAY' )
        {
            $binded[$i] = [@{$binded[$i]}];
        }
        elsif( $self->_is_object( $binded[$i] ) && 
               overload::Overloaded( $binded[$i] ) && 
               overload::Method( $binded[$i], '""' ) )
        {
            no warnings 'uninitialized';
            my $v = "$binded[$i]";
            $binded[$i] = defined( $v ) ? $v : undef;
        }
        # Will work well with Module::Generic::Hash
        elsif( $self->_is_hash( $binded[$i] ) && 
               $self->_can( $binded[$i], 'as_json' ) )
        {
            $binded[$i] = $binded[$i]->as_json;
        }
    }
    
    local $_;
    my $rv = 
    eval
    {
        #local( $SIG{__DIE__} )  = sub{ };
        #local( $SIG{__WARN__} ) = sub{ };
        local( $SIG{ALRM} )     = sub{ die( "Timeout while processing query $self->{sth}->{Statement}\n" ) };
        # print( STDERR ref( $self ) . "::execute(): binding parameters '", join( ', ', @$binded ), "' to query:\n$self->{ 'query' }\n" );
        # $self->{ 'sth' }->execute( @binded );
        for( my $i = 0; $i < scalar( @binded ); $i++ )
        {
            # Stringify the binded value if it is a stringifyable object.
            if( ref( $binded[$i] ) && 
                $self->_is_object( $binded[$i] ) &&
                overload::Overloaded( $binded[$i] ) &&
                overload::Method( $binded[$i], '""' ) )
            {
                $binded[$i] .= '';
            }
            
            my $data_type = $binded_types[ $i ];
            if( CORE::length( $data_type ) && $self->_is_hash( $data_type ) )
            {
                $self->{sth}->bind_param( $i + 1, $binded[ $i ], $data_type );
            }
            else
            {
                $self->{sth}->bind_param( $i + 1, $binded[ $i ] );
            }
        }
        $self->{sth}->execute();
    };
    my $error = $@;
    $error ||= $self->{sth}->errstr if( !$rv );
    if( $q )
    {
        if( $q->join_tables->length > 0 )
        {
            $q->join_tables->foreach(sub{
                my $tbl = shift( @_ );
                return if( !$tbl || !ref( $tbl ) );
                $tbl->reset;
            });
        }
        $q->table_object->reset;
    }
    my $tie = $self->{tie} || {};
    # Maybe it is time to bind SQL result to possible provided perl variables?
    if( !$error && %$tie )
    {
        my $order = $self->{tie_order};
        my $sth   = $self->{sth};
        for( my $i = 0; $i < @$order; $i++ )
        {
            my $pos = $i + 1;
            my $val = $order->[ $i ];
            if( exists( $tie->{ $val } ) && ref( $tie->{ $val } ) eq 'SCALAR' )
            {
                $sth->bind_col( $pos, $tie->{ $val } );
            }
        }
    }
    if( $error )
    {
        $error =~ s/ at (\S+\s)?line \d+.*$//s;
        # $err .= ":\n\"$self->{ 'query' }\"";
        $error .= ":\n\"$self->{sth}->{Statement}\"";
        $error = "Error while trying to execute query $self->{sth}->{Statement}: $error";
        if( $self->fatal() )
        {
            die( "$error in $self->{file} at line $self->{line} within sub $self->{sub}\n" );
        }
        else
        {
            # return( $self->error( "$err in $self->{ 'file' } at line $self->{ 'line' } within sub $self->{ 'sub' }" ) );
            return( $self->error( $error ) );
        }
    }
    elsif( $self->{sth}->errstr() )
    {
        return( $self->error( "Error while trying to execute query $self->{sth}->{Statement}: ", $self->{sth}->errstr ) );
    }
    # User wants an object for chaining like:
    # $sth->exec( 'some value' )->fetchrow;
    elsif( want( 'OBJECT' ) )
    {
        return( $self );
    }
    elsif( $rv )
    {
        return( $rv );
    }
    # For void context too
    else
    {
        return(1);
    }
}

sub executed
{
    my $self = shift( @_ );
    # For hand made query to avoid clash when executing generic routine such as fetchall_arrayref...
    return( 1 ) if( !exists( $self->{query} ) );
    return( exists( $self->{executed} ) && $self->{executed} );
}

sub fetchall_arrayref($@)
{
    my $self  = shift( @_ );
    my $slice = shift( @_ ) || [];
    my $dbo   = $self->database_object;
    my $sth   = $self->{sth};
    if( !$self->executed() )
    {
        $self->execute() || return;
    }
    # $self->_cleanup();
    my $mode  = ref( $slice );
    my @rows;
    my $row;
    if( $mode eq 'ARRAY' )
    {
        if( @$slice )
        {
            push( @rows, [ @{ $row }[ @{ $slice } ] ] ) while( $row = $self->{sth}->fetch() );
        }
        else
        {
            push( @rows, [ @{ $row } ] ) while( $row = $self->{sth}->fetch );
        }
    }
    elsif( $mode eq 'HASH' )
    {
        my @o_keys = keys( %$slice );
        if( @o_keys )
        {
            my %i_names = map{  ( lc( $_ ) => $_ ) } @{ $self->{sth}->FETCH( 'NAME' ) };
            my @i_keys  = map{ $i_names{ lc( $_ ) } } @o_keys;
            while( $row = $self->{sth}->fetchrow_hashref() )
            {
                my %hash;
                @hash{ @o_keys } = @{ $row }{ @i_keys };
                push( @rows, \%hash );
            }
        }
        else
        {
            push( @rows, $row ) while( $row = $self->{sth}->fetchrow_hashref() );
        }
    }
    else
    {
        warn( "fetchall_arrayref($mode) invalid" );
    }
    # return( \@rows );
    return( \@rows ) if( !$dbo->auto_decode_json && !$dbo->auto_convert_datetime_to_object );
    my $data = \@rows;
    $data = $self->_convert_json2hash({ statement => $sth, data => $data }) if( $dbo->auto_decode_json );
    $data = $self->_convert_datetime2object({ statement => $sth, data => $data }) if( $dbo->auto_convert_datetime_to_object );
    return( $data );
}

sub fetchcol($;$)
{
    my $self = shift( @_ );
    # @arr = $sth->fetchcol( $col_number );
    my $col_num = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( $self->pass_error );
    }
    # $self->_cleanup();
    # return( $h->fetchcol( $COL_NUM ) );
    my @col;
    # $self->dataseek( 0 );
    my $ref;
    while( $ref = $self->{sth}->fetchrow_arrayref() )
    {
        push( @col, $ref->[ $col_num ] );
    }
    return( @col );
}

sub fetchhash(@)
{
    my $self = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( $self->pass_error );
    }
    # $self->_cleanup();
    # %hash = $sth->fetchhash;
    # return( $h->fetchhash );
    my $ref = $self->{sth}->fetchrow_hashref();
    if( $ref ) 
    {
        return( %$ref );
    }
    else
    {
        return( () );
    }
}

sub fetchrow(@)
{
    my $self = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( $self->pass_error );
    }
    # $self->_cleanup();
    # @arr = $sth->fetchrow;        # Array context
    # $firstcol = $sth->fetchrow;   # Scalar context
    # return( $h->fetchrow );
    # my $ref = $self->fetchrow_arrayref();
    my $ref = $self->{sth}->fetchrow_arrayref();
    # my $ref = $self->{sth}->fetch();
    if( $ref ) 
    {
        return( wantarray ? @$ref : $ref->[0] );
    }
    else
    {
        return( () );
    }
}

# sub fetchrow_hashref(@) is inherited from DBI
sub fetchrow_hashref
{
    my $self = shift( @_ );
    my $dbo  = $self->database_object;
    my $deb = {};
    %$deb = %$self;
    my $sth = $self->{sth};
    if( !$self->executed() )
    {
        $self->execute() || return( $self->pass_error );
    }
    return( $sth->fetchrow_hashref ) if( !$dbo->auto_decode_json && !$dbo->auto_convert_datetime_to_object );
    my $ref = $sth->fetchrow_hashref;
    # Convert json to hash for the relevant fields
    # return( $self->_convert_json2hash( $ref ) );
    $ref = $self->_convert_json2hash({ statement => $sth, data => $ref }) if( $dbo->auto_decode_json );
    $ref = $self->_convert_datetime2object({ statement => $sth, data => $ref }) if( $dbo->auto_convert_datetime_to_object );
    return( $ref );
}

sub fetchrow_object
{
    my $self = shift( @_ );
    # This should give us something like Postgres or Mysql or SQLite
    my $basePack = ( ref( $self ) =~ /^DB::Object::([^\:]+)/ )[0];
    if( !$self->executed() )
    {
        $self->execute() || return( $self->pass_error );
    }
    # $self->_cleanup();
    my $rows = $self->{sth}->rows;
    my $ref = $self->{sth}->fetchrow_hashref();
    if( $ref && scalar( keys( %$ref ) ) ) 
    {
        my $struct = { map{ $_ => '$' } keys( %$ref ) };
        my $table  = $self->table;
        my $class  = "DB::Object::${basePack}::Result::${table}";
        if( !defined( &{ $class . '::new' } ) )
        {
            struct $class => $struct;
        }
        my $obj = $class->new( %$ref );
        return( $obj );
    }
    else
    {
        return( () );
    }
}

sub finish
{
    my $self = shift( @_ );
    my $rc   = $self->{sth}->finish();
    if( !$rc )
    {
        return( $self->error( $self->{sth}->errstr() ) );
    }
    else
    {
        return( $rc );
    }
}

sub ignore
{
    my $self = shift( @_ );
    my $query = $self->{query} ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[0] );
    # ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( INSERT UPDATE ALTER );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be ignored:\n$query" ) );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    return( $self ) if( $type eq 'ALTER' && $query !~ /^\s*$type\s+TABLE\s+/i );
    
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 IGNORE /;
    # my $sth = $self->prepare( $query ) ||
    # $self->{ 'query' } = $query;
    # saving parameters to bind later on must have been done previously
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

sub join
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $on;
    if( @_ )
    {
        $on = ( scalar( @_ ) == 1 && ref( $_[0] ) ) ? shift( @_ ) : [ @_ ];
    }
    my $q = $self->query_object || return( $self->error( "No query formatter object was set" ) );
    my $tbl_o = $q->table_object || return( $self->error( "No table object is set in query object." ) );
    my $query = $q->query ||
    return( $self->error( "No query prepared for join with another table." ) );
    if( $query !~ /^[[:blank:]]*SELECT[[:blank:]]+/i )
    {
        return( $self->error( "You may not perform a join on a query other than select." ) );
    }
    my $constant = $q->constant;
    # Constant is set and query object marked as final, which means this statement has already been processed as a join and so we skip all further processing.
    if( scalar( keys( %$constant ) ) && $q->final )
    {
        return( $self );
    }
    my $table      = $tbl_o->table;
    my $db         = $tbl_o->database();
    my $multi_db   = $tbl_o->prefix_database;
    my $alias      = $tbl_o->as;
    my $new_fields = '';
    my $new_table  = '';
    my $new_db     = '';
    my $class      = ref( $self );
    my $q2 = $q->clone;
    my $q1;
    $q2->join_tables( $tbl_o ) if( !$q2->join_tables->length );
    # $data is a DB::Object::Postgres::Statement object - we get all its parameter and merge them with ours
    # if( ref( $data ) && ref( $data ) eq $class )
    if( ref( $data ) && $self->_is_a( $data, $class ) )
    {
        $q1 = $data->query_object;
    }
    # $data is the table name
    else
    {
        my $join_tbl;
        if( $self->_is_object( $data ) && $data->isa( 'DB::Object::Tables' ) )
        {
            $join_tbl = $data;
        }
        elsif( $self->_is_object( $data ) )
        {
            return( $self->error( "I was expecting either a table name as a scalar or a table object, but instead got \"$data\" (", ref( $data ), ")." ) );
        }
        else
        {
            return( $self->error( "No such table \"$data\" exists in database \"$db\"." ) ) if( !$self->database_object->table_exists( $data ) );
            $join_tbl = $self->database_object->table( $data );
            return( $self->error( "Could not get a table object from \"$data\"." ) ) if( !$join_tbl );
        }
        $join_tbl->prefixed( $db ne $join_tbl->database_object->database ? 3 : 1 );
        my $sth_tmp = $join_tbl->select || return( $self->pass_error( $join_tbl->error ) );
        $q1 = $sth_tmp->query_object || return( $self->error( "Could not get a query object out of the dummy select query I made from table \"$data\"." ) );
        $new_fields = $q1->selected_fields;
        # NOTE: 2021-08-22: If we reset it here, we lose the table aliasing
        # $join_tbl->reset;
        
        # $join_tbl->prefixed( $db ne $join_tbl->database_object->database ? 3 : 1 ) unless( $join_tbl->prefixed );
        $new_table = $join_tbl->prefix;
        $join_tbl->reset;
        # We assume this table is part of our same database
        $new_db     = $db;
        # my $db_data = $self->getdefault( $new_table );
        # $new_fields = $db_data->format_statement();
        $new_fields = '';
    }
    # TODO: check this or remove it
    # $q1->table_object->prefixed( $db ne $q1->database_object->database ? 3 : 1 );
    $new_fields = $q1->selected_fields;
    $new_table  = $q1->table_object->name;
    # $new_table  = $q1->table_object->prefix;
    $new_db     = $q1->database_object->database;
    $q2->join_tables->push( $q1->table_object );
    if( CORE::length( $q->where ) )
    {
        $q2->where( $self->AND( ( $q->where ), $q1->new_clause({ value => '( ' . ( $q1->where ) . ' )' }) ) ) if( CORE::length( $q1->where ) );
    }
    elsif( CORE::length( $q1->where ) )
    {
        $q2->where( $q1->where );
    }
    $q2->group( $q->group, $q1->group ) if( $q1->group->value->length );
    $q2->order( $q->order, $q1->order ) if( $q1->order->value->length );
    $q2->binded_where->push( @{$q1->binded_where} );
    $q2->binded_group->push( @{$q1->binded_group} );
    $q2->binded_order->push( @{$q1->binded_order} );
    $q2->binded( @{$q1->binded} );
    if( ( !$q->limit || !$q->_limit->length ) && $q2->_limit->length )
    {
        $q2->_limit( $q1->_limit );
        $q2->binded_limit( $q1->binded_limit );
    }
    my $prev_fields = length( $q->join_fields ) ? $q->join_fields : $q->selected_fields;
    # Regular express to prepend previous fields by their table name if that's not the case already
    # my $prev_prefix = $new_db ? "$db.$table" : $table;
    # my $prev_prefix = $tbl_o->query_object->table_alias ? $tbl_o->query_object->table_alias : $tbl_o->prefixed( $db ne $new_db ? 3 : 1 )->prefix;
#     unless( $tbl_o->query_object->table_alias )
#     {
#         $tbl_o->prefixed( $db ne $new_db ? 3 : 1 )
#     }
    $tbl_o->prefixed( $db ne $new_db ? 3 : 1 );
    # Prefix for previous fields list
    my $prev_prefix = $tbl_o->prefix;
    my $prev_fields_hash = $q->table_object->fields;
    my $prev_fields_list = CORE::join( '|', sort( keys( %$prev_fields_hash ) ) );
    my $re = qr/(?<![\.\"])\b($prev_fields_list)\b/;
    $prev_fields =~ s/(?<![\.\"])\b($prev_fields_list)\b/${prev_prefix}.$1/gs;
    my $fields = $new_fields ? CORE::join( ', ', $prev_fields, $new_fields ) : $prev_fields;
    $q2->join_fields( $fields );
    #my $from_table = $q2->from_table;
    #$from_table = $multi_db ? [ "$db.$table" ] : [ $table ] if( !scalar( @$from_table ) );
    # $q2->from_table( $multi_db ? "$db.$table" : $table ) if( !$q2->from_table->length );
    $q2->from_table->push(
        $q2->table_alias
            ? sprintf( '%s AS %s', $q2->table_object->name, $q2->table_alias )
            : ( $q2->table_object->prefixed ? $q2->table_object->prefix : $q2->table_object->name )
    ) if( !$q2->from_table->length );
    # $q2->left_join( {} ) if( !$q2->left_join );
    my $left_join = '';
    my $condition = '';
    my $format_condition;
    $format_condition = sub
    {
        my @vals = ();
        my $vals = shift( @_ );
        my $op   = shift( @_ );
        my @res  = ();
        my $fields_tables = {};
        while( scalar( @$vals ) )
        {
            if( $self->_is_object( $vals->[0] ) && $vals->[0]->isa( 'DB::Object::Operator' ) )
            {
                my $sub_obj = shift( @$vals );
                my $sub_op = $sub_obj->operator;
                my( @sub_vals ) = $sub_obj->value;
                my $this_ref = $format_condition->( \@sub_vals, $sub_op );
                CORE::push( @res, $this_ref->{clause} ) if( length( $this_ref->{clause} ) );
                my $tmp = $this_ref->{fields_tables};
                my @those_table_names = keys( %$tmp );
                @$fields_tables{ @those_table_names } = @$tmp{ @those_table_names };
            }
            else
            {
                if( $self->_is_object( $vals->[0] ) && $vals->[0]->isa( 'DB::Object::Fields::Field::Overloaded' ) )
                {
                    my $f1 = shift( @$vals );
                    $f1->field->prefixed( $multi_db ? 3 : 1 );
                    CORE::push( @res, "$f1" );
                    $fields_tables->{ $f1->field->table }++ if( !$fields_tables->{ $f1->field->table } );
                    next;
                }
                
                my( $f1, $f2 ) = ( shift( @$vals ), shift( @$vals ) );
                my $i_am_negative = 0;
                if( $self->_is_object( $f2 ) && $f2->isa( 'DB::Object::NOT' ) )
                {
                    ( $f2 ) = $f2->value;
                    $i_am_negative++;
                }
                
                my( $field1, $field2 );
                if( $self->_is_object( $f1 ) && $f1->isa( 'DB::Object::Fields::Field' ) )
                {
                    $f1->prefixed( $multi_db ? 3 : 1 );
                    $field1 = $f1->name;
                    $fields_tables->{ $f1->table }++ if( !$fields_tables->{ $f1->table } );
                }
                else
                {
                    $field1 = $multi_db ? "$new_db.$new_table.$f1" : "$new_table.$f1";
                }
                if( $self->_is_object( $f2 ) && $f2->isa( 'DB::Object::Fields::Field' ) )
                {
                    $f2->prefixed( $multi_db ? 3 : 1 );
                    $field2 = $f2->name;
                    $fields_tables->{ $f2->table }++ if( !$fields_tables->{ $f2->table } );
                }
                else
                {
                    $field2 = $multi_db ? "$new_db.$new_table.$f2" : "$new_table.$f2";
                }
                CORE::push( @res, $i_am_negative ? "$field1 != $field2" : "$field1 = $field2" );
            }
        }
        return({
            clause => CORE::join( $op, @res ),
            fields_tables => $fields_tables,
        });
    };
    
    # $on is either a $dbh->AND, or $dbh->OR
    if( defined( $on ) )
    {
        if( $self->_is_object( $on ) && $on->isa( 'DB::Object::Operator' ) )
        {
            my $op = $on->operator;
            my( @vals ) = $on->value;
            my $ret = $format_condition->( \@vals, $op );
            my $as = $q1->table_alias ? sprintf( ' AS %s', $q1->table_alias ) : '';
            $left_join = "LEFT JOIN ${new_table}${as} ON $ret->{clause}";
        }
        elsif( $self->_is_object( $on ) && $on->isa( 'DB::Object::Fields::Field::Overloaded' ) )
        {
            my $as = $q1->table_alias ? sprintf( ' AS %s', $q1->table_alias ) : '';
            $left_join = "LEFT JOIN ${new_table}${as} ON ${on}";
        }
        elsif( $self->_is_array( $on ) )
        {
            my $ret = $format_condition->( $on, 'AND' );
            my $as = $q1->table_alias ? sprintf( ' AS %s', $q1->table_alias ) : '';
            $left_join = "LEFT JOIN ${new_table}${as} ON $ret->{clause}";
        }
        # There is a second parameter - if so this is the condition of the 'LEFT JOIN'
        elsif( $self->_is_hash( $on ) )
        {
            # Previous join
            my $join_ref = $q2->left_join;
            my $def = { on => $on, table_object => $q1->table_object, query_object => $q1 };
            ## Add the current one
            if( $multi_db )
            {
                $join_ref->{ "$new_db.$new_table" } = $def;
            }
            else
            {
                $join_ref->{ $new_table } = $def;
            }
            # (Re)build the LEFT JOIN ... ON ... definition
            my @join_data = ();
            foreach my $joined ( keys( %$join_ref ) )
            {
                my $condition = $join_ref->{ $joined }->{on};
                my $to = $join_ref->{ $joined }->{table_object};
                my $qo = $join_ref->{ $joined }->{query_object};
                my $join_table_name = $to->prefix;
                my $join_table_alias = '';
                if( length( $join_table_alias = $qo->table_alias ) )
                {
                    $join_table_alias = " AS $join_table_alias";
                }
                push( @join_data, "LEFT JOIN ${join_table_name}${join_table_alias} ON " . CORE::join( ' AND ', map{ "$_=$condition->{ $_ }" } keys( %$condition ) ) );
            }
            $left_join = CORE::join( ' ', @join_data );
        }
        else
        {
            warn( "Warning: I have no clue what to do with '$on' (", overload::StrVal( $on ), ") in this join for table \"", $q->table_object->name, "\"\n" );
        }
    }
    # Otherwise, this is a straight JOIN
    else
    {
        # $q2->from_table->push( $multi_db ? "$new_db.$new_table" : $new_table );
        $q2->from_table->push(
            $q1->table_alias
                ? sprintf( '%s AS %s', $q1->table_object->name, $q1->table_alias )
                : ( $q1->table_object->prefixed ? $q1->table_object->prefix : $q1->table_object->name )
        );
    }
    my $from = $q2->from_table->join( ', ' );
    # $q2->from_table( $from_table );
    my $clause = $q2->_query_components( 'select', { no_bind_copy => 1 } );
    # You may not sort if there is no order clause
#     my $table_alias = '';
#     if( length( $table_alias = $q2->table_alias ) )
#     {
#         $table_alias = " AS ${table_alias}";
#     }
    # my @query = ( "SELECT ${fields} FROM ${from}${table_alias} ${left_join}" );
    my @query = ( "SELECT ${fields} FROM ${from} ${left_join}" );
    push( @query, @$clause ) if( @$clause );
    my $statement = CORE::join( ' ', @query );
    $q2->query( $statement );
    # my $sth = $self->prepare( $self->{ 'query' } ) ||
    my $sth = $tbl_o->_cache_this( $q2 ) ||
    return( $self->error( "Error while preparing query to select:\n", $q2->as_string(), $tbl_o->error ) );
    # Routines such as as_string() expect an array on pupose so we do not have to commit the action
    # but rather get the statement string. At the end, we write:
    # $obj->select() to really select
    # $obj->select->as_string() to ONLY get the formatted statement
    # wantarray() returns the undefined value in void context, which is typical use of a real select command
    # i.e. $obj->select();
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to select:\n", $q2->as_string(), "\nError: ", $sth->error() ) );
    }
    return( $sth );
}

sub object
{
    my $self = shift( @_ );
    # This is intended for statement to fetched their object:
    # my $obj = $table->select( '*' )->object();
    # my $obj = $table->select( '*' )
    # would merly execute the statement before returning its object, but there are conditions
    # such like using a SELECT to create a table where we do not want the statement to be executed already
    return( $self->{sth} ) if( $self->{sth} );
    # More sensible approach will return a special Module::Generic::Null object to avoid perl complaining of 'called on undef value' if this is used in chaining
    return( Module::Generic::Null->new ) if( want( 'OBJECT' ) );
    return;
}

sub priority
{
    my $self = shift( @_ );
    my $prio = shift( @_ );
    my $map  =
    {
    0    => 'LOW_PRIORITY',
    1    => 'HIGH_PRIORITY',
    };
    ## Bad argument. Do not bother
    return( $self ) if( !exists( $map->{ $prio } ) );
    
    my $query = $self->{query} ||
    return( $self->error( "No query to set priority for was provided." ) );
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    my @allowed = qw( DELETE INSERT REPLACE SELECT UPDATE );
    my $allowed = CORE::join( '|', @allowed );
    # Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not set priority on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    # SELECT with something else than HIGH_PRIORITY is incompatible, so do not bother to go further
    return( $self ) if( $prio != 1 && $type =~ /^(?:SELECT)$/i );
    return( $self ) if( $prio != 0 && $type =~ /^(?:DELETE|INSERT|REPLACE|UPDATE)$/i );
    
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 $map->{ $prio } /i;
    # $self->{ 'query' } = $query;
    # my $sth = $self->prepare( $query ) ||
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new low priority query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new low priority query:\n$query" ) );
    }
    return( $sth );
}

sub promise
{
    my $self = shift( @_ );
    $self->_load_class( 'Promise::Me' ) || return( $self->pass_error );
    return( Promise::Me->new(sub
    {
        return( $self->execute( @_ ) );
    }) );
}

sub query { return( shift->_set_get_scalar( 'query', @_ ) ); }

sub query_object { return( shift->_set_get_object_without_init( 'query_object', 'DB::Object::Query', @_ ) ); }

sub query_time { return( shift->_set_get_datetime( 'query_time', @_ ) ); }

sub rollback
{
    my $self = shift( @_ );
    if( $self->{sth} && $self->param( 'autocommit' ) )
    {
        my $sth = $self->prepare( "ROLLBACK" ) || return( $self->error( "An error occurred while preparing query to rollback: ", $self->error ) );
        $sth->execute() || return( $self->error( "Error occurred while executing query to rollback: ", $sth->error ) );
        $sth->finish();
    }
    return( $self );
}

sub rows(@)
{
    my $self = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( $self->pass_error );
    }
    # $self->_cleanup();
    # $rv = $sth->rows;
    if( !ref( $self ) )
    {
        return( $DBI::rows );
    }
    else
    {
        return( $self->{sth}->rows() );
    }
}

# A DBI::sth object. This should rather be a _set_get_object helper method, but I am not 100% sure if this is really a DBI::sth
sub sth { return( shift->_set_get_scalar( 'sth', @_ ) ); }

sub table { return( shift->{table} ); }

sub table_object { return( shift->_set_get_object_without_init( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub undo
{
    goto( &rollback );
}

sub wait { return( shift->error( "Method wait() is not implemented by this driver." ) ); }

sub _convert_datetime2object { return( shift->database_object->_convert_datetime2object( @_ ) ); }

sub _convert_json2hash { return( shift->database_object->_convert_json2hash( @_ ) ); }

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

DB::Object::Statement - Statement Object

=head1 SYNOPSIS

    say $sth->as_string;
    $sth->bind_param( 2, $binded_value );
    $sth->bind_param( 2, $binded_value, $binded_type );
    $sth->commit;
    my $dbh = $sth->database_object;
    $sth->distinct;
    say $sth->dump;
    say $sth->execute;
    $sth->execute( $val1, $val2 ) || die( $sth->error );
    # explicitly specify types
    # Here in this mixed example, $val1 and $val3 have known types
    $tbl->where( $dbh->AND(
        $tbl->fo->name == '?',
        $tbl->fo>city == '?',
        '?' == ANY( $tbl->fo->alias )
    ) );
    my $sth = $tbl->select || die( $tbl->error );
    $sth->execute( $val1, $val2, { $val3 => 'varchar' } ) || die( $sth->error );
    my $ref = $sth->fetchall_arrayref;
    my $val = $sth->fetchcol;
    my %hash = $sth->fetchhash;
    my @values = $sth->fetchrow;
    my $ref = $sth->fetchrow_hashref;
    my $obj = $sth->fetchrow_object;
    $sth->finish;
    $sth->ignore;
    $sth->join( $join_condition );
    my $qo = $sth->query_object;
    $sth->rollback;
    my $rows = $sth->rows;
    my $dbi_sth = $sth->sth;
    my $tbl = $sth->table_object;

=head1 VERSION

v0.4.2

=head1 DESCRIPTION

This is the statement object package from which other driver specific packages inherit from.

=head1 METHODS

=head2 as_string

Returns the current statement object as a string.

=head2 bind_param

Provided with a list of arguments and they will be passed to L<DBI/bind_param>

If an error occurred, an error is returned, otherwise the return value of calling C<bind_param> is returned.

=head2 commit

If the statement parameter I<autocommit> is true, a C<COMMIT> statement will be prepared and executed.

The current object is returned.

=head2 database_object

Sets or gets the current database object.

=head2 distinct

Assuming a I<query> object property has already been set previously, this will add the C<DISTINCT> keyword to it if not already set.

If L</distinct> is called in void context, the query is executed immediately.

The query statement is returned.

=head2 dump

Provided with a file and this will print on STDOUT the columns used, separated by a tab and then will process each rows fetched with L<DBI::fetchrow> and will join the column valus with a tab before printing it out to STDOUT.

It returns the current object for chaining.

=head2 exec

This is an alias for L</execute>

=head2 execute

    $sth->execute || die( $sth->error );
    $sth->execute( $val1, $val2 ) || die( $sth->error );
    # explicitly specify types
    # Here in this mixed example, $val1 and $val3 have known types
    $tbl->where( $dbh->AND(
        $tbl->fo->name == '?',
        $tbl->fo>city == '?',
        '?' == ANY( $tbl->fo->alias )
    ) );
    my $sth = $tbl->select || die( $tbl->error );
    $sth->execute( $val1, $val2, { $val3 => 'varchar' } ) || die( $sth->error );

If binded values have been prepared, they are applied here before executing the query.

Sometime, you need to clearly specify what the datatype are for the value provided with C<execute>, because L<DB::Object::Query> could not figure it out.

Thus, if you do:

    $tbl->where(
        $tbl->fo->name == '?'
    );

L<DB::Object::Query> knows the datatype, because you are using a field object (C<fo>), but if you were doing:

    $tbl->where(
        '?' == ANY( $tbl->fo->alias )
    );

In this scenario, L<DB::Object::Query> does not know what the bind value would be, although we could venture a guess by looking at the right-hand side, but this is a bit hazardous. So you are left with a placeholder, but no datatype. So you would execute like:

    $sth->execute({ $val => 'varchar' });

If the total number of binded values does not match the total number of binded type, this will trigger a warning.

L<DBI/execute> will be called with the binded values and if this method was called in an object context, the current object is returned, otherwise the returned value from L<DBI/execute> is returned.

=head2 executed

Returns true if this statement has already been executed, and false otherwise.

=head2 fetchall_arrayref

Similar to L<DBI/fetchall_arrayref>, this will execute the query and return an array reference of data.

=head2 fetchcol

Provided with an integer that represents a column number, starting from 0, and this will get each row of results and add the value for the column at the given offset.

it returns a list of those column value fetched.

=head2 fetchhash

This will retrieve an hash reference for the given row and return it as a regular hash.

=head2 fetchrow

This will retrieve the data from database using L</fetchrow_arrayref> and return the list of data as array in list context, or the first entry of the array in scalar context.

=head2 fetchrow_hashref

This will retrieve the data from the database as an hash reference.

It will convert any data from json to hash reference if L<DB::Object/auto_decode_json> is set to true.

it will also convert any datetime data into a L<DateTime> object if L<DB::Object/auto_convert_datetime_to_object> is true.

It returns the hash reference retrieved.

=head2 fetchrow_object

This will create dynamically a package named C<DB::Object::Postgres::Result::SomeTable> for example and load the hash reference retrieved from the database into this dynamically created packackage.

It returns the object thus created.

=head2 finish

Calls L<DBI/finish> and return the returned value, or an error if an error occurred.

=head2 ignore

This will change the query prepared and add the keyword C<IGNORE>.

If called in void context, this will execute the resulting statement handler immediately.

=head2 join

Provided with a target and an hash reference, or list or array reference of condition for the join and this will prepare the join statement.

If the original query is not of type C<select>, this will trigger an error.

The target mentioned above can be either a L<DB::Object::Statement> object, or a table object (L<DB::Object::Tables>), or even just a string representing the name of a table.

    $tbl->select->join( $sth );
    $tbl->select->join( $other_tbl );
    $tbl->select->join( 'table_name' );

The condition mentioned above can be a L<DB::Object::Operator> (C<AND>, C<OR> or C<NOT>), in which case the actual condition will be taken from that operator embedded value.

The condition can also be a L<DB::Object::Fields::Field::Overloaded> object, which implies a table field with some operator and some value.

    $tbl->select->join( $other_tbl, $other_tbl->fo->id == 2 );

Here C<$other_tbl->fo->id == 2> will become a L<DB::Object::Fields::Field::Overloaded> object.

The condition can also be an array reference or array object of conditions and implicitly the array entry will be joined with C<AND>:

    $tbl->select->join( $other_tbl, ["user = 'joe'", $other_tbl->fo->id == 2] );

The condition can also be an hash reference with each key being a table name to join and each value an hash reference of condition for that particular join with each key being a column name and each value the value of the join for that column.

    my $tbl = $dbh->first_table;
    $tbl->select->join({
        other_table =>
        {
            id => 'first_table.id',
            user => 'first_table.user',
        },
        yet_another_table =>
        {
            id => 'other_table.id',
        },
    });

would become something like:

    SELECT *
    FROM first_table
    LEFT JOIN other_table ON
        first_table.id = id AND
        first_table.user = user
    LEFT JOIN yet_another_table ON
        other_table.id = id

Each condition will be formatted assuming an C<AND> expression, so this is less flexible than using operator objects and table field objects.

If no condition is provided, this is taken to be a straight join.

    $tbl->where( $tbl->fo->id == 2 );
    $other_tbl->where( $other_tbl->fo->user 'john' );
    $tbl->select->join( $other_tbl );

Would become something like:

    SELECT *
    FROM first_table, other_table
    WHERE id = 2 AND user = 'john'

If called in void context, this will execute the resulting statement handler immediately.

It returns the resulting statement handler.

It returns the statement handler.

=head2 object

Returns the statement object explicitly.

    my $sth = $tbl->select->object;

which is really equivalent to:

    my $sth = $tbl->select;

=head2 priority

Provided with a priority integer that can be 0 or 1 with 0 being C<LOW_PRIORITY> and 1 being C<HIGH_PRIORITY> and this will adjust the query formatted to add the priority. This works only on Mysql drive though.

If used on queries other than C<DELETE>, C<INSERT>, C<REPLACE>, C<SELECT>, C<UPDATE> an error will be returned.

If called in void context, this will execute the newly create statement handler immediately.

It returns the newly create statement handler.

=head2 promise

This the same as calling L</execute>, except that the query will be executed asynchronously and a L<Promise::Me> object will be returned, so you can do asynchronous queries like this:

    my $sth = $dbh->prepare( "SELECT some_slow_function(?)" ) || die( $dbh->error );
    my $p = $sth->promise(10)->then(sub
    {
        my $st = shift( @_ );
        my $ref = $st->fetchrow_hashref;
        my $obj = My::Module->new( %$ref );
    })->catch(sub
    {
        $log->warn( "Failed to execute query: ", @_ );
    });
    my( $obj ) = await( $p );

=head2 query

Sets or gets the previously formatted query as a regular string.

=head2 query_object

Sets or gets the query object used in this query.

=head2 query_time

Sets or gets the query time as a L<DateTime> object.

=head2 rollback

If there is a statement handler and the database parameter C<autocommit> is set to true, this will prepare a C<ROLLBACK> query and execute it.

=head2 rows

Returns the number of rows affected by the last query.

=head2 sth

Sets or gets the L<DBI> statement handler.

=head2 table

Sets or gets the table object (L<DB::Object::Tables>) for this query.

=head2 table_object

Sets or get the table object (L<DB::Object::Tables>)

=head2 undo

This is an alias for L</rollback>

=head2 wait

The implementation is driver dependent, and in this case, this is implemented only in L<DB::Object::Mysql>

=head2 _convert_datetime2object

A convenient short to enable or disable L<DB::Object/_convert_datetime2object>

=head2 _convert_json2hash

A convenient short to enable or disable L<DB::Object/_convert_json2hash>

=head1 SEE ALSO

L<DB::Object::Query>, L<DB::Object::Mysql::Query>, L<DB::Object::Postgres::Query>, L<DB::Object::SQLite::Query>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
