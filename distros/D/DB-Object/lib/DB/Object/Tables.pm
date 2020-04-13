# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Tables.pm
## Version 0.4.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2020/01/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## This package's purpose is to separate the object of the tables from the main
## DB::Object package so that when they get DESTROY'ed, it does not interrupt
## the SQL connection
##----------------------------------------------------------------------------
package DB::Object::Tables;
BEGIN
{
    require 5.6.0;
    use strict;
    use DB::Object::Fields;
    our( $VERSION, $VERBOSE, $DEBUG, @ISA );
    @ISA    = qw( DB::Object );
    $VERSION    = '0.4.1';
    $VERBOSE    = 0;
    $DEBUG      = 0;
    use Devel::Confess;
};

sub init
{
    my $self  = shift( @_ );
    my $table = '';
    $table    = shift( @_ ) if( @_ && @_ % 2 );
    my %arg   = ( @_ );
    return( $self->error( "You must provide a table name to create a table object." ) ) if( !$table && !$arg{table} );
    $table ||= CORE::delete( $arg{table} );
    foreach my $k ( keys( %arg ) )
    {
    	$self->{ $k } = $arg{ $k };
    }
    $self->{ 'table' }       = $table if( $table );
    $self->{ 'structure' } ||= {};
    $self->{ 'fields' }    ||= {};
    $self->{ 'default' }   ||= {};
    $self->{ 'null' }      ||= {};
    $self->{ 'types' }       = {};
    $self->{ 'alias' }       = {};
    $self->{ 'avoid' }       = [];
    ## The table type. It could be table or view
    $self->{ 'type' }		 = '';
    ## The schema name, if any
    $self->{ 'schema' }		 = '';
    $self->{ 'bind' }		 = '';
    $self->{ 'cache' }		 = '';
    $self->{ 'enhance' }	 = '';
    ## Load table default, fields, structure informations
    ## my $db = $self->database();
    my $ref = $self->structure();
    return( $self->error( "There is no table by the name of $table" ) ) if( !%$ref );
    return( $self );
}

##----{ End of generic routines }----##
sub alter
{
    my $self  = shift( @_ );
    ## Expecting a reference to an array
    my $spec  = '';
    $spec     = shift( @_ ) if( @_ == 1 && ref( $_[ 0 ] ) );
    $spec     = [ @_ ] if( @_ && !$ref );
    my $table = $self->{ 'table' } ||
    return( $self->error( "No table was provided." ) );
    return( $self->error( "No proper ALTER specification was provided." ) ) if( !$spec || !ref( $spec ) || !@$spec );
    my $query = "ALTER TABLE $table " . CORE::join( ', ', @$spec );
    my $sth   = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing ALTER query to modify table '$table':\n", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to ALTER table '$table':\n", $self->as_string(), $sth->errstr() ) );
    }
    return( $sth );
}

sub constant
{
	my $self = shift( @_ );
	my( $pack, $file, $line ) = caller;
	## $self->message( 3, "Called from package '$pack' in file '$file' at line '$line'." );
	my $base_class = $self->database_object->base_class;
	## This does not work for calls made internally
	return( $self ) if( $pack =~ /^${base_class}\b/ );
	my $sth = $self->database_object->constant_queries_cache_get({
		pack => $pack,
		file => $file,
		line => $line,
	});
	## $self->message( 3, "Statement handler returned is: '$sth'." );
	## $sth returned may be void if no cache was found or if the caller's file mod time has changed
	my $q;
	if( $sth )
	{
		$q = $sth->query_object;
		$self->query_object( $q );
	}
	else
	{
		$q = $self->_reset_query;
	}
	$q->constant({
		sth => $sth,
		pack => $pack,
		file => $file,
		line => $line,
	});
	return( $self );
}

## sub create must be superseded by sub classes
sub create
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "create() is not implemented by $class." ) );
}

sub create_info
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "create_info() is not implemented by $class." ) );
}

sub database { return( shift->database_object->database ); }

sub database_object { return( shift->{ 'dbo' } ); }

sub dbh { return( shift->_set_get( 'dbh', @_ ) ); }

sub default
{
    my $self = shift( @_ );
    $self->structure();
    my $default = $self->{ 'default' };
    return( wantarray() ? () : undef() ) if( !%$default );
    return( wantarray() ? %$default : \%$default );
}

sub drop
{
    my $self  = shift( @_ );
    my $table = $self->{ 'table' } || 
    return( $self->error( "No table was provided to drop." ) );
    my $query = "DROP TABLE $table";
    my $sth = $self->prepare( $query ) ||
    return( $self->error( "Error while preparing query to drop table '$table':\n$query", $self->errstr() ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing query to drop table '$table':\n$query", $sth->errstr() ) );
    }
    return( $sth );
}

sub exists
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "exists() is not implemented by $class." ) );
}

sub fields
{
    my $self = shift( @_ );
    $self->structure();
    my $fields = $self->{fields};
    return( wantarray() ? () : undef() ) if( !%$fields );
    return( wantarray() ? %$fields : \%$fields );
}

sub fields_object
{
    my $self = shift( @_ );
    my $o = $self->{fields_object};
    return( $o ) if( $o && $self->_is_object( $o ) );
    my $db_name = $self->database_object->database;
	$db_name =~ tr/-/_/;
	$db_name =~ s/\_{2,}/_/g;
	$db_name = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $db_name ) ) );
    my $name = $self->name;
	my $new_class = $name;
	$new_class =~ tr/-/_/;
	$new_class =~ s/\_{2,}/_/g;
	$new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
	$class = ref( $self ) . "\::${db_name}\::${new_class}";
    unless( $self->_is_class_loaded( $class ) )
    {
		my $perl = <<EOT;
package $class;
BEGIN
{
	use strict;
	use parent qw( DB::Object::Fields );
};

1;

EOT
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
		my $rc = eval( $perl );
		# print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
		die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    $o = $class->new({
		table_object => $self,
		debug => $self->debug,
    });
    $o->prefixed( $self->{prefixed} );
    $self->{fields_object} = $o;
    return( $o );
}

sub fo { return( shift->fields_object( @_ ) ); }

sub lock
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "lock() is not implemented by $class." ) );
}

sub name
{
    ## Read-only
    return( shift->{table} );
}

sub null
{
    my $self = shift( @_ );
    $self->structure();
    my $null = $self->{ 'null' };
    return( wantarray() ? () : undef() ) if( !%$null );
    return( wantarray() ? %$null : $null );
}

sub optimize
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "optimize() is not implemented by $class." ) );
}

sub prefix
{
	my $self = shift( @_ );
	my @val = ();
	CORE::push( @val, $self->database_object->database ) if( $self->{prefixed} > 2 );
	CORE::push( @val, $self->schema ) if( $self->{prefixed} > 1 && $self->schema );
	CORE::push( @val, $self->name ) if( $self->{prefixed} > 0 );
	return( '' ) if( !scalar( @val ) );
	return( CORE::join( '.', @val ) );
}

sub prefix_database { return( shift->{prefixed} > 2 ); }

sub prefix_schema { return( shift->{prefixed} > 1 ); }

sub prefix_table { return( shift->{prefixed} > 0 ); }

## This the prefix intended for field in query
sub prefixed
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->{prefixed} = ( $_[0] =~ /^\d+$/ ? $_[0] : ( $_[0] ? 1 : 0 ) );
	}
	else
	{
		$self->{prefixed} = 1;
	}
	my $fo = $self->{fields_object};
	$fo->prefixed( $self->{prefixed} ) if( $fo );
	return( $self );
}

sub primary
{
    my $self = shift( @_ );
    $self->structure();
    my $primary = $self->{primary};
    return( wantarray() ? () : undef() ) if( !$primary || !@$primary );
    return( wantarray() ? @$primary : \@$primary );
}

## In PostgreSQL, Oracle, SQL server this would be schema_name.table_name
sub qualified_name { return( shift->name ); }

sub query_object { return( shift->_set_get_object( 'query_object', 'DB::Object::Query', @_ ) ); }

sub query_reset { return( shift->_set_get_scalar( 'query_reset', @_ ) ); }

sub rename
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "rename() is not implemented by $class." ) );
}

sub repair
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "repair() is not implemented by $class." ) );
}

sub schema { return( shift->_set_get_scalar( 'schema', @_ ) ); }

sub stat
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "stat() is not implemented by $class." ) );
}

sub table { return( shift->{table} ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub types
{
	my $self = shift( @_ );
    $self->structure();
    my $types = $self->{types};
    return( wantarray() ? () : undef() ) if( !%$types );
    return( wantarray() ? %$types : $types );
}

## sub structure must be superseded by sub classes
sub structure
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "structure() is not implemented by $class." ) );
}

sub unlock
{
	my $self = shift( @_ );
	my $class = ref( $self );
	return( $self->error( "unlock() is not implemented by $class." ) );
}

DESTROY
{
    ## Do nothing
    ## DB::Object::Tables are never destroyed.
    ## They are just gateway to tables, and they are cached by DB::Object::table()
    ## print( STDERR "DESTROY'ing table $self ($self->{ 'table' })\n" );
};

1;

__END__

=encoding utf8

=head1 NAME

DB::Object::Tables - Database Object Interface

=head1 SYNOPSIS

=head1 VERSION

    0.4.1

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over 4

=item B<new>( %arg )

Creates a new L<DB::Object::Tables> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<alter>()

=item B<create>()

=item B<create_info>()

=item B<database_object>()

=item B<dbh>()

=item B<default>()

=item B<drop>()

=item B<exists>()

=item B<fields>()

=item B<fields_object>()

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


