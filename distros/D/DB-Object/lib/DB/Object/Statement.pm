# -*- perl -*-
##----------------------------------------------------------------------------
## DB/Object/Statement.pm
## Version 0.3.4
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2019/08/25
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to automatically terminate the statement object and
## separate them from the connection object (DB::Object).
## Connection object last longer than statement objects
##----------------------------------------------------------------------------
package DB::Object::Statement;
BEGIN
{
    require 5.6.0;
    use strict;
    use parent qw( DB::Object );
	use Class::Struct qw( struct );
	use IO::File;
	use DateTime;
    our( $VERSION, $VERBOSE, $DEBUG );
    $VERSION    = '0.3.4';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
};

sub as_string
{
    my $self = shift( @_ );
    ## my $q = $self->_query_object_current;
    ## used by select, insert, update, delete to flag that we need to reformat the query
    $self->{as_string}++;
    if( my $qo = $self->query_object )
    {
    	$qo->final( 1 );
    }
    ## return( $self->{ 'sth' }->{ 'Statement' } );
    ## Same:
    ## return( $q->as_string );
    return( $self->{query} );
}

sub bind_param
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller();
    my $sub = ( caller( 1 ) )[ 3 ];
    $self->{ 'pack' } = $pack;
    $self->{ 'file' } = $file;
    $self->{ 'line' } = $line;
    $self->{ 'sub' }  = $sub;
    my $rc = 
    eval
    {
        $self->{ 'sth' }->bind_param( @_ );
    };
    if( $@ )
    {
        my $err = $self->errstr();
        $err =~ s/ at line \d+.*$//;
        printf( STDERR "%s in %s at line %d within sub '%s'.\n", $err, $self->{ 'file' }, $self->{ 'line' }, $self->{ 'sub' } );
        ## return( undef() );
        exit( 1 );
    }
    elsif( $rc )
    {
        return( $rc );
    }
    else
    {
        my $err = $@ = $self->{ 'sth' }->errstr() || "Unknown error while binding parameters to query.";
        return( $self->error( $err ) );
    }
}

sub commit
{
    my $self = shift( @_ );
    if( $self->{ 'sth' } && $self->param( 'autocommit' ) )
    {
        my $sth = $self->prepare( "COMMIT" ) ||
        return();
        $sth->execute();
        $sth->finish();
    }
    return( $self );
}

sub database_object { return( shift->_set_get_object( 'dbo', 'DB::Object', @_ ) ); }

sub distinct
{
    my $self = shift( @_ );
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    ## ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( SELECT );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be distinct:\n$query" ) );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DISTINCT|DISTINCTROW|ALL)\s+/i );
    
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 DISTINCT /;
    ## my $sth = $self->prepare( $query ) ||
    ## $self->{ 'query' } = $query;
    ## saving parameters to bind later on must have been done previously
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
        ## Used to be handled by SQL server
        ## my $query = $self->as_string();
        ## $query    =~ s/(\s+FROM\s+)/ INTO OUTFILE '$file'$1/;
        ## my $sth   = $self->prepare( $query ) ||
        ## return( $self->error( "Error while preparing query to dump result on select:\n$query" ) );
        ## $sth->execute() ||
        ## return( $self->error( "Error while executing query to dump result on select:\n$query" ) );
        my $fields = $self->{ '_fields' };
        my @header = sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields );
        my $io = IO::File->new( ">$file" ) ||
        return( $self->error( "Unable to open file '$file' in write mode: $!" ) );
        my $date = DateTime->now;
        my $table = $self->{ 'table' };
        printf( $io "## Generated on %s for table $table\n", $date->strftime( '%c' ) );
        print( $io "## ", CORE::join( "\t", @header ), "\n" );
        my @data = ();
        while( @data = $self->fetchrow() )
        {
            print( $io CORE::join( "\t", @data ), "\n" );
        }
        close( $io );
        $self->finish();
        return( $self );
    }
    elsif( exists( $self->{ 'sth' } ) )
    {
        ## my $fields = $self->{ '_fields' };
        my @fields = @{ $self->{ 'sth' }->FETCH( 'NAME' ) };
        my $max    = 0;
        ## foreach my $field ( keys( %$fields ) )
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
        $self->finish();
        return( $self );
    }
    else
    {
        return( $self->error( "No query to dump." ) );
    }
}

*exec = \&execute;

sub execute
{
    my $self = shift( @_ );
    ## XXX
    ## print( STDERR "Debug value for class '", ref( $self ), "' is $self->{debug}\n" );
    my( $pack, $file, $line ) = caller();
    my $sub = ( caller(1) )[3];
    ## What we want is to get the point from where we were originatly called
    if( $pack =~ /^DB::Object/ )
    {
        for( my $i = 1; $i < 5; $i++ )
        {
            ( $pack, $file, $line ) = caller( $i );
            $sub = ( caller( $i + 1 ) )[3];
            last if( $pack !~ /^DB::Object/ );
        }
    }
    ## my $sub = ( caller( 1 ) )[ 3 ];
    $self->{pack} = $pack;
    $self->{file} = $file;
    $self->{line} = $line;
    $self->{sub}  = $sub;
    $self->{executed}++;
    my $q = $self->query_object;
    $q->final( 1 ) if( $q );
    my @binded = ();
    my @binded_types = ();
    if( $q && $self->{bind} )
    {
    	my $types = $q->binded_types_as_param;
    	@binded_types = @$types;
    	if( @_ && ( $self->_is_hash( $_[0] ) ) )
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
    		## This is the list of fields as they appear in the order in insert or update query
    		## Knowing their order of appearance is key so we can bind follow-on values to them
    		my $sorted = $q->sorted;
    		foreach my $f ( @$sorted )
    		{
    			if( !CORE::exists( $vals->{ $f } ) )
    			{
    				push( @binded, undef() );
    			}
    			## The value may be defined or not, or may be zero length long
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
    
    @binded    = @_ if( ( !@binded && @_ ) || @_ );
    @binded    = () if( !@binded );
    if( scalar( @binded ) != scalar( @binded_types ) )
    {
    	$self->messagef( 3, "Warning: the total binded values (%d) does not match the total binded types (%d)! Check the code...", scalar( @binded ), scalar( @binded_types ) );
    	## Cancel it, because it will create problems
    	@binded_types = ();
    }
    $self->message( 3, "Binding '", join( ', ', @binded ), "' parameters for query: '$self->{query}'." );
    ## debugh( 'binded', $binded ) if( $self->{ 'query' } =~ /^\s*SELECT/ );
    my $rv = 
    eval
    {
        local( $SIG{ '__DIE__' } )  = sub{ };
        local( $SIG{ '__WARN__' } ) = sub{ };
        local( $SIG{ 'ALRM' } )     = sub{ die( "Timeout while processing query $self->{sth}->{Statement}\n" ) };
        ## print( STDERR ref( $self ) . "::execute(): binding parameters '", join( ', ', @$binded ), "' to query:\n$self->{ 'query' }\n" );
        $self->message( 3, "Executing query '$self->{sth}->{Statement}' with handler '$self->{sth}'." );
        $self->message( 3, "Is database handler active? ", ( $self->ping ? 'Yes' : 'No' ) );
        $self->message( 3, "Statement handler contains the following data: ", $self->dumper( $self->{ 'sth' } ) );
        ## $self->{ 'sth' }->execute( @binded );
        for( my $i = 0; $i < scalar( @binded ); $i++ )
        {
        	my $data_type = $binded_types[ $i ];
        	if( CORE::length( $data_type ) && $self->_is_hash( $data_type ) )
        	{
        		$self->message( 3, "Found binded param for binded value No $i (starting from 0): ", sub{ $self->dumper( $data_type ) } );
        		$self->{sth}->bind_param( $i + 1, $binded[ $i ], $data_type );
        	}
        	else
        	{
				$self->{sth}->bind_param( $i + 1, $binded[ $i ] );
        	}
        }
        $self->{sth}->execute();
    };
    if( $q )
    {
    	if( $q->join_tables->length > 0 )
    	{
    		$q->join_tables->foreach(sub{
    			my $tbl = shift( @_ );
    			return if( !$tbl || !ref( $tbl ) );
    			$self->message( 3, "Resetting table \"", $tbl->name, "\"." );
    			$tbl->reset;
    		});
    	}
    	$q->table_object->reset;
    }
    my $tie = $self->{tie} || {};
    ## Maybe it is time to bind SQL result to possible provided perl variables?
    if( !$@ && %$tie )
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
    if( $@ )
    {
        my $err = $@;
        $err =~ s/ at (\S+\s)?line \d+.*$//s;
        ## $err .= ":\n\"$self->{ 'query' }\"";
        $err .= ":\n\"$self->{sth}->{Statement}\"";
        $err = "Error while trying to execute query $self->{sth}->{Statement}: $err";
        if( $self->fatal() )
        {
            die( "$err in $self->{file} at line $self->{line} within sub $self->{sub}\n" );
        }
        else
        {
            ## return( $self->error( "$err in $self->{ 'file' } at line $self->{ 'line' } within sub $self->{ 'sub' }" ) );
            return( $self->error( $err ) );
        }
    }
    elsif( $rv )
    {
        return( $rv );
    }
    elsif( $self->{sth}->errstr() )
    {
        return( $self->error( $self->{sth}->errstr() ) );
    }
    else
    {
        return( 1 );
    }
}

sub executed
{
    my $self = shift( @_ );
    ## For hand made query to avoid clash when executing generic routine such as fetchall_arrayref...
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
        $self->execute() || return( undef() );
    }
    ## $self->_cleanup();
    my $mode  = ref( $slice );
    my @rows;
    my $row;
    if( $mode eq 'ARRAY' )
    {
        if( @{ $slice } )
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
        my @o_keys = keys( %{ $slice } );
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
	$self->messagef( 3, "Calling _convert_json2hash for %d rows of data with auto_decode_json '%s' and auto_convert_datetime_to_object '%s'.", scalar( @$data ), $dbo->auto_decode_json, $dbo->auto_convert_datetime_to_object );
	$data = $self->_convert_json2hash({ statement => $sth, data => $data }) if( $dbo->auto_decode_json );
	## $self->message( 3, "Resulting data is: ", sub{ $self->dumper( $data ) } );
	$data = $self->_convert_datetime2object({ statement => $sth, data => $data }) if( $dbo->auto_convert_datetime_to_object );
	return( $data );
}

sub fetchcol($;$)
{
    my $self = shift( @_ );
    ## @arr = $sth->fetchcol( $col_number );
    my $col_num = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( undef() );
    }
    ## $self->_cleanup();
    ## return( $h->fetchcol( $COL_NUM ) );
    my @col;
    ## $self->dataseek( 0 );
    my $ref;
    while( $ref = $self->{ 'sth' }->fetchrow_arrayref() )
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
        $self->execute() || return( undef() );
    }
    ## $self->_cleanup();
    ## %hash = $sth->fetchhash;
    ## return( $h->fetchhash );
    my $ref = $self->{ 'sth' }->fetchrow_hashref();
    if( $ref ) 
    {
        return( %$ref );
    }
    else
    {
        return( () );
        ## return( undef() );
    }
}

sub fetchrow(@)
{
    my $self = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( undef() );
    }
    ## $self->_cleanup();
    ## @arr = $sth->fetchrow;        # Array context
    ## $firstcol = $sth->fetchrow;   # Scalar context
    ## return( $h->fetchrow );
    ## my $ref = $self->fetchrow_arrayref();
    my $ref = $self->{ 'sth' }->fetchrow_arrayref();
    ## my $ref = $self->{ 'sth' }->fetch();
    if( $ref ) 
    {
        return( wantarray ? @$ref : $ref->[ 0 ] );
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
	# $self->message( 3, "Statement object contains: ", $self->printer( $deb ) );
	my $sth = $self->{sth};
    if( !$self->executed() )
    {
        $self->execute() || return( undef() );
    }
	return( $sth->fetchrow_hashref ) if( !$dbo->auto_decode_json && !$dbo->auto_convert_datetime_to_object );
	my $ref = $sth->fetchrow_hashref;
	## $self->message( 3, "Decoding json to perl. Before decoding: ", sub{ $self->dumper( $ref ) } );
	## Convert json to hash for the relevant fields
	# return( $self->_convert_json2hash( $ref ) );
	$ref = $self->_convert_json2hash({ statement => $sth, data => $ref }) if( $dbo->auto_decode_json );
	$ref = $self->_convert_datetime2object({ statement => $sth, data => $ref }) if( $dbo->auto_convert_datetime_to_object );
	## $self->message( 3, "Resulting data is: ", sub{ $self->dumper( $ref ) } );
	return( $ref );
}

sub fetchrow_object
{
	my $self = shift( @_ );
	## This should give us something like Postgres or Mysql or SQLite
	my $basePack = ( ref( $self ) =~ /^DB::Object::([^\:]+)/ )[0];
    if( !$self->executed() )
    {
        $self->execute() || return( undef() );
    }
    ## $self->_cleanup();
    my $rows = $self->{ 'sth' }->rows;
    $self->message( 3, "$rows found" );
    my $ref = $self->{ 'sth' }->fetchrow_hashref();
    $self->message( 3, "Found result data : ", sub{ $self->dumper( $ref ) } );
    if( $ref && scalar( keys( %$ref ) ) ) 
    {
    	my $struct = { map{ $_ => '$' } keys( %$ref ) };
    	my $table  = $self->table;
    	my $class  = "DB::Object::${basePack}::Result::${table}";
    	$self->message( 3, "Building class '$class' with '", scalar( keys( %$ref ) ), "' keys." );
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
    my $rc   = $self->{ 'sth' }->finish();
    if( !$rc )
    {
        return( $self->error( $self->{ 'sth' }->errstr() ) );
    }
    else
    {
        return( $rc );
    }
}

sub ignore
{
    my $self = shift( @_ );
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    ## ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( INSERT UPDATE ALTER );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be ignored:\n$query" ) );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    return( $self ) if( $type eq 'ALTER' && $query !~ /^\s*$type\s+TABLE\s+/i );
    
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 IGNORE /;
    ## my $sth = $self->prepare( $query ) ||
    ## $self->{ 'query' } = $query;
    ## saving parameters to bind later on must have been done previously
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
    my $on   = ( scalar( @_ ) == 1 && ref( $_[0] ) ) ? shift( @_ ) : [ @_ ];
    my $q    = $self->query_object || return( $self->error( "No query formatter object was set" ) );
    my $tbl_o = $q->table_object || return( $self->error( "No table object is set in query object." ) );
    my $query = $q->query ||
    return( $self->error( "No query prepared for join with another table." ) );
    if( $query !~ /^[[:blank:]]*SELECT[[:blank:]]+/i )
    {
        return( $self->error( "You may not perform a join on a query other than select." ) );
    }
    my $constant = $q->constant;
    ## Constant is set and query object marked as final, which means this statement has already been processed as a join and so we skip all further processing.
    if( scalar( keys( %$constant ) ) && $q->final )
    {
    	return( $self );
    }
    my $table      = $tbl_o->table;
    my $db         = $tbl_o->database();
    ## my $multi_db   = $tbl_o->param( 'multi_db' );
    my $multi_db   = $tbl_o->prefix_database;
    # $self->message( 3, "Table object is '$tbl_o', original table is '$table' and database '$db'." ); exit;
    my $new_fields = '';
    my $new_table  = '';
    my $new_db     = '';
    my $class      = ref( $self );
    my $q2 = $q->clone;
    ## $self->message( 3, "Clone main object is: '$q2'." );
    my $q1;
    $q2->join_tables( $tbl_o ) if( !$q2->join_tables->length );
    ## $data is a DB::Object::Postgres::Statement object - we get all its parameter and merge them with ours
    if( ref( $data ) && ref( $data ) eq $class )
    {
        ## $new_fields = $data->format_statement();
        $q1 = $data->query_object;
#         $new_fields = $q1->selected_fields;
#         $new_table  = $q1->table_object->name;
#         $new_db     = $q1->database_object->database;
    
        ## We need to protect the previous WHERE clause that may contain complex condition, so we use parenthesis.
        ## $q2->_set_get( where => \( join( ' AND ', ( $q->where(), "( " . ${$q1->where} . " )" ) ) ) ) if( $q1->where );
    }
    ## $data is the table name
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
    	my $sth_tmp = $join_tbl->prefixed( $db ne $join_tbl->database_object->database ? 3 : 1 )->select || return( $self->pass_error( $join_tbl->error ) );
    	$self->message( 3, "sql query is: ", $sth_tmp->as_string );
    	$q1 = $sth_tmp->query_object || return( $self->error( "Could not get a query object out of the dummy select query I made from table \"$data\"." ) );
    	$new_fields = $q1->selected_fields;
    	$self->message( 3, "Got the table object, and group by is? ", $q1->group );
    	$join_tbl->reset;
    	
        $new_table  = $data;
        ## We assume this table is part of our same database
        $new_db     = $db;
        ## my $db_data = $self->getdefault( $new_table );
        ## $new_fields = $db_data->format_statement();
        $new_fields = '';
    }
	$new_fields = $q1->selected_fields;
	$new_table  = $q1->table_object->name;
	$new_db     = $q1->database_object->database;
	$q2->join_tables->push( $q1->table_object );
	if( CORE::length( $q->where ) )
	{
		$self->message( 3, "Combining previous where condition (", $q->where, ") with new one (", $q1->where, ")." );
		$q2->where( $self->AND( ( $q->where ), $q1->new_clause({ value => '( ' . ( $q1->where ) . ' )' }) ) ) if( CORE::length( $q1->where ) );
	}
	elsif( CORE::length( $q1->where ) )
	{
		$q2->where( $q1->where );
	}
# 	$self->message( 3, "Where clause is no: ", $q2->where );
# 	$self->message( 3, "Group clause is: ", $q2->group, "\n and with \$q1 maybe? ", $q1->group );
	## $self->{ 'group_by' } = \( join( ', ', ( $q->group(), $q1->group() ) ) );
	$q2->group( $q->group, $q1->group ) if( $q1->group->value->length );
	## $self->{ 'order_by' } = \( join( ', ', ( $q->order(), $q1->order() ) ) );
	$q2->order( $q->order, $q1->order ) if( $q1->order->value->length );
	## push( @{ $self->{ 'binded_where' } }, @{$q1->binded_where} );
	## push( @{ $self->{ 'binded_group' } }, @{$q1->binded_group} );
	## push( @{ $self->{ 'binded_order' } }, @{$q1->binded_order} );
	## push( @{ $self->{ 'binded' } }, @{ $data->{ 'binded' } } );
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
    ## Regular express to prepend previous fields by their table name if that's not the case already
    ## my $prev_prefix = $new_db ? "$db.$table" : $table;
    my $prev_prefix = $tbl_o->prefixed( $db ne $new_db ? 3 : 1 )->prefix;
    my $prev_fields_hash = $q->table_object->fields;
    my $prev_fields_list = join( '|', sort( keys( %$prev_fields_hash ) ) );
    # my $re = qr/(?<!\.)\b($prev_fields_list)\b/;
    # $self->message( 3, "Executing regular expression: $re on $prev_fields" );
    $prev_fields =~ s/(?<!\.)\b($prev_fields_list)\b/${prev_prefix}.$1/gs;
#     $self->message( 3, "Fields now are: '$prev_fields'." );
    my $fields      = $new_fields ? CORE::join( ', ', $prev_fields, $new_fields ) : $prev_fields;
    $q2->join_fields( $fields );
    #my $from_table = $q2->from_table;
    #$from_table = $multi_db ? [ "$db.$table" ] : [ $table ] if( !scalar( @$from_table ) );
    $q2->from_table( $multi_db ? "$db.$table" : $table ) if( !$q2->from_table->length );
    # $q2->left_join( {} ) if( !$q2->left_join );
    my $left_join = '';
    my $condition = '';
#     $self->message( 3, "Processing join condiction with '$on'." );
	local $format_condition = sub
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
# 				$self->message( 3, "Next value is another operator object, drilling down." );
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
				my( $f1, $f2 ) = ( shift( @$vals ), shift( @$vals ) );
# 				$self->message( 3, "Value 1 is '$f1' and value 2 is '$f2'." );
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
				if( $self->_is_object( $f1 ) && $f1->isa( 'DB::Object::Fields::Field' ) )
				{
					$f2->prefixed( $multi_db ? 3 : 1 );
					$field2 = $f2->name;
					$fields_tables->{ $f2->table }++ if( !$fields_tables->{ $f2->table } );
				}
				else
				{
					$field2 = $multi_db ? "$new_db.$new_table.$f2" : "$new_table.$f2";
				}
# 				$self->message( 3, "Fields to be used are: '$field1' and '$field2'." );
				CORE::push( @res, $i_am_negative ? "$field1 != $field2" : "$field1 = $field2" );
			}
		}
		return({
			clause => CORE::join( $op, @res ),
			fields_tables => $fields_tables,
		});
    };
    ## $on is either a $dbh->AND, or $dbh->OR
    if( $on && $self->_is_object( $on ) && $on->isa( 'DB::Object::Operator' ) )
    {
#     	$self->message( 3, "The join condition is defined by a DB::Object::Operator" );
		my $op = $on->operator;
# 		$self->message( 3, "Operator is '$op'." );
		my( @vals ) = $on->value;
    	my $ret = $format_condition->( \@vals, $op );
    	$left_join = "LEFT JOIN $new_table ON $ret->{clause}";
#     	$self->message( 3, "\$left_join is: '$left_join'." );
    }
    elsif( $self->_is_array( $on ) )
    {
    	my $ret = $format_condition->( $on, 'AND' );
    	$left_join = "LEFT JOIN $new_table ON $ret->{clause}";
#     	$self->message( 3, "\$left_join is: '$left_join'." );
    }
    ## There is a second parameter - if so this is the condition of the 'LEFT JOIN'
    elsif( defined( $on ) && $self->_is_hash( $on ) )
    {
#     	$self->message( 3, "Join condition is made from an hash reference." );
        ## Previous join
        my $join_ref = $q2->left_join;
        ## Add the current one
        if( $multi_db )
        {
            $join_ref->{ "$new_db.$new_table" } = $on;
        }
        else
        {
            $join_ref->{ $new_table } = $on;
        }
        ## (Re)build the LEFT JOIN ... ON ... definition
        my @join_data = ();
        foreach my $joined ( keys( %$join_ref ) )
        {
            ## push( @join_data, "LEFT JOIN $joined ON " . CORE::join( ' AND ', map{ "$_=$on->{ $_ }" } keys( %$on ) ) );
            my $condition = $join_ref->{ $joined };
            push( @join_data, "LEFT JOIN $joined ON " . CORE::join( ' AND ', map{ "$_=$condition->{ $_ }" } keys( %$condition ) ) );
        }
        $left_join = CORE::join( ' ', @join_data );
    }
    ## Otherwise, this is a straight JOIN
    else
    {
#     	$self->message( 3, "Dealing with a straight join." );
        ## push( @$from_table, $multi_db ? "$new_db.$new_table" : $new_table );
        $q2->from_table->push( $multi_db ? "$new_db.$new_table" : $new_table );
    }
#     $self->message( 3, "Left join formatted is: '$left_join'." );
    ## $from = CORE::join( ',', @$from_table );
    $from = $q2->from_table->join( ',' );
    ## $q2->from_table( $from_table );
    my $clause = $q2->_query_components( 'select' );
    ## You may not sort if there is no order clause
    my @query = ( "SELECT $fields FROM $from $left_join" );
    push( @query, @$clause ) if( @$clause );
    my $statement = CORE::join( ' ', @query );
    $q2->query( $statement );
#     $self->messagef( 3, "Join tables are %d: %s.", $q2->join_tables->length, CORE::join( "', '", map( $_->name, @{$q2->join_tables} ) ) );
    ## my $sth = $self->prepare( $self->{ 'query' } ) ||
    my $sth = $tbl_o->_cache_this( $q2 ) ||
    return( $self->error( "Error while preparing query to select:\n", $q2->as_string(), $tbl_o->error ) );
    ## Routines such as as_string() expect an array on pupose so we do not have to commit the action
    ## but rather get the statement string. At the end, we write:
    ## $obj->select() to really select
    ## $obj->select->as_string() to ONLY get the formatted statement
    ## wantarray() returns the undefined value in void context, which is typical use of a real select command
    ## i.e. $obj->select();
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
    ## This is intended for statement to fetched their object:
    ## my $obj = $table->select( '*' )->object();
    ## my $obj = $table->select( '*' )
    ## would merly execute the statement before returning its object, but there are conditions
    ## such like using a SELECT to create a table where we do not want the statement to be executed already
    return( $self->{ 'sth' } ? $self->{ 'sth' } : undef() );
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
    
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set priority for was provided." ) );
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    my @allowed = qw( DELETE INSERT REPLACE SELECT UPDATE );
    my $allowed = CORE::join( '|', @allowed );
    ## Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not set priority on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    ## SELECT with something else than HIGH_PRIORITY is incompatible, so do not bother to go further
    return( $self ) if( $prio != 1 && $type =~ /^(?:SELECT)$/i );
    return( $self ) if( $prio != 0 && $type =~ /^(?:DELETE|INSERT|REPLACE|UPDATE)$/i );
    
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 $map->{ $prio } /i;
    ## $self->{ 'query' } = $query;
    ## my $sth = $self->prepare( $query ) ||
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new low priority query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new low priority query:\n$query" ) );
    }
    return( $sth );
}

sub query { return( shift->_set_get_scalar( 'query', @_ ) ); }

sub query_object { return( shift->_set_get( 'query_object', @_ ) ); }

sub query_time { return( shift->_set_get_datetime( 'query_time', @_ ) ); }

sub rollback
{
    my $self = shift( @_ );
    if( $self->{ 'sth' } && $self->param( 'autocommit' ) )
    {
        my $sth = $self->prepare( "ROLLBACK" ) ||
        return();
        $sth->execute();
        $sth->finish();
    }
    return( $self );
}

sub rows(@)
{
    my $self = shift( @_ );
    if( !$self->executed() )
    {
        $self->execute() || return( undef() );
    }
    ## $self->_cleanup();
    ## $rv = $sth->rows;
    if( !ref( $self ) )
    {
        return( $DBI::rows );
    }
    else
    {
        return( $self->{ 'sth' }->rows() );
    }
}

## A DBI::sth object. This should rather be a _set_get_object helper method, but I am not 100% sure if this is really a DBI::sth
sub sth { return( shift->_set_get_scalar( 'sth', @_ ) ); }

sub table { return( shift->{ 'table' } ); }

sub table_object { return( shift->_set_get_object( 'table_object', 'DB::Object::Tables', @_ ) ); }

sub undo
{
    goto( &rollback );
}

sub wait
{
    my $self = shift( @_ );
    my $query = $self->{ 'query' } ||
    return( $self->error( "No query to set as to be delayed." ) );
    my $type = ( $query =~ /^\s*(\S+)\s+/ )[ 0 ];
    my @allowed = qw( INSERT REPLACE );
    my $allowed = CORE::join( '|', @allowed );
    ## Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not use wait (delayed query) on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    ## Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    $query =~ s/^(\s*)($allowed)(\s+)/$1$2 DELAYED /i;
    ## $self->{ 'query' } = $query;
    ## my $sth = $self->prepare( $query ) ||
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new delayed query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new delayed query:\n$query" ) );
    }
    return( $sth );
}

sub _convert_datetime2object { return( shift->database_object->_convert_datetime2object( @_ ) ); }

sub _convert_json2hash { return( shift->database_object->_convert_json2hash( @_ ) ); }

DESTROY
{
    ## Do nothing but existing so it is handled by this package
    ## print( STDERR "DESTROY'ing statement $self ($self->{ 'query' })\n" );
};

1;

__END__

