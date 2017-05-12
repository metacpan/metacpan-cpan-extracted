package DBIx::ProcedureCall;

use strict;
use warnings;

use Carp qw(croak);


our $VERSION = '0.11';

our %__loaded_drivers;

our %__known_attributes = qw~  
	procedure  1
	function 	1
	cached	1
	package	1
	packaged  1
	cursor	1
	fetch()	1
	fetch[]	1
	fetch{}	1
	fetch[[]]	1
	fetch[{}]	1
	table	1
	boolean 1
~;
	   
sub __run_procedure{
		my $dbh =$_[0];
		croak "expected a database handle as first parameter, but got nothing" unless $dbh;
		
		# determine database type
		my $dbtype = eval { $dbh->get_info(17); };  #  17 : SQL_DBMS_NAME  
		croak "could not determine the database type from $dbh: $@. Is that really a DBI database handle? " unless $dbtype;
		
		my $name = $_[1];
		croak "expected a procedure name to run against the database, but got nothing" unless $name;
		
		# delegate to the driver
		unless ($__loaded_drivers{$dbtype}){
			eval  "require DBIx::ProcedureCall::$dbtype; \$__loaded_drivers{$dbtype} = 1;" 
				or croak "failed to load driver for $dbtype database: $@";	
		}
		
		"DBIx::ProcedureCall::$dbtype"->__run_procedure(@_);
}

sub __run_function{
		my $dbh = $_[0];
		croak "expected a database handle as first parameter, but got nothing" unless $dbh;
		
		# determine database type
		my $dbtype = eval { $dbh->get_info(17); };  #  17 : SQL_DBMS_NAME  
		croak "could not determine the database type from $dbh: $@. Is that really a DBI database handle? " unless $dbtype;
		
		my $name = $_[1];
		croak "expected a function name to run against the database, but got nothing" unless $name;
		
		my $attr = $_[2];
		
		# delegate to the driver
		unless ($__loaded_drivers{$dbtype}){
			eval  "require DBIx::ProcedureCall::$dbtype; \$__loaded_drivers{$dbtype} = 1;" 
				or croak "failed to load driver for $dbtype database: $@";	
		}	
		my $r = "DBIx::ProcedureCall::$dbtype"->__run_function(@_);
		return $r unless $attr->{fetch};
		
		#fetch cursor
		return __fetch($r, $attr, $dbtype);
			
}

sub __fetch{
	my ($sth, $attr, $dbtype) = @_;
	my $data;
	if ($attr->{'fetch[[]]'} ) { $data = $sth->fetchall_arrayref; }
	elsif ($attr->{'fetch()'} ) { 
		my @data = $sth->fetchrow_array; 
		"DBIx::ProcedureCall::$dbtype"->__close($sth) if $attr->{cursor};
		return @data;
	}
	elsif ($attr->{'fetch[{}]'} ) { $data = $sth->fetchall_arrayref({ }); }
	elsif ($attr->{'fetch{}'} ) { $data = $sth->fetchrow_hashref; }
	elsif ($attr->{'fetch[]'} ) { $data = $sth->fetchrow_arrayref; }
	
	"DBIx::ProcedureCall::$dbtype"->__close($sth)
		if $attr->{cursor};
	
	return $data;
}

sub __bind_params{
	my ($sql, $start_index, $params) = @_;
	my @binder;
	if (ref $params eq 'ARRAY'){
		my $i = $start_index;
		foreach (@$params){
			# special bind options
			if (ref $_ eq 'ARRAY'){
				@binder = @$_;
			}
			else
			{
				@binder = ( $_ );
			}
			# INOUT parameters
			if (ref $binder[0]){
				# default MAXLEN 100
				$binder[1] = 100 unless exists $binder[1];
				$sql->bind_param_inout($i++, @binder);
			}
			else{
				$sql->bind_param($i++, @binder);
			}
		}
	}
	else{
		foreach (keys %$params){
			# special bind options
			my $p = $params->{$_};
			if (ref $p eq 'ARRAY'){
				@binder = @$p;
			}
			else
			{
				@binder = ( $p );
			}
			# INOUT parameters
			if (ref $binder[0]){
				# default MAXLEN 100
				$binder[1] = 100 unless exists $binder[1];
				$sql->bind_param_inout(":$_", @binder);
			}
			else{
				$sql->bind_param(":$_", @binder);
			}
		}
	}
}

sub __run{
	my $w = shift;
	my $name = shift;
	my $attr = shift;
	my $dbh = shift;
	# check function/procedure attribute
	$w = 0 if $attr->{function};
	$w = undef if $attr->{procedure};
	# in void context run a procedure
	return __run_procedure($dbh, $name, $attr, @_) unless defined $w;
	# in non-void context run a function
	return __run_function($dbh, $name, $attr, @_);
}

sub run{
	my $dbh = shift;
	my $n = shift;
	my ($name, @attr) = split ':', $n;
	my @err = grep { not exists $__known_attributes{lc $_} } @attr;
	croak "tried to set unknown attributes (@err) for stored procedure '$name' " if @err;
	
	my %attr = map { (lc($_) => 1) } @attr;
	
	# any fetch implies function
	if ( grep /^fetch/,  keys %attr ) {
		$attr{'function'} = 1;
		$attr{'fetch'} = 1;
	}
	
	# cursor implies function
	$attr{'function'} = 1 if $attr{'cursor'};
	
	# table implies function
	$attr{'function'} = 1 if $attr{'table'};
	
	
	return __run(wantarray, $name, \%attr, $dbh, @_);
}


sub import {
    my $class = shift;
    my $caller = (caller)[0];
    no strict 'refs';
    foreach (@_) {
	my ($name, @attr) = split ':';
	
	my @err = grep { not exists $__known_attributes{lc $_} } @attr;
	croak "tried to set unknown attributes (@err) for stored procedure '$name' " if @err;
	
	my %attr = map { (lc($_) => 1) } @attr;
	
	
	# any fetch implies function
	if ( grep /^fetch/,  keys %attr ) {
		$attr{'function'} = 1;
		$attr{'fetch'} = 1;
	}
	
	# cursor implies function
	$attr{'function'} = 1 if $attr{'cursor'};
	
	# table implies function
	$attr{'function'} = 1 if $attr{'table'};
	
	# boolean implies function
	$attr{'function'} = 1 if $attr{'boolean'};
	
	if ($attr{'package'}){
		delete $attr{'package'};
		my $pkgname = $name;
		$pkgname =~ s/\./::/g;
		$pkgname =~ s/[^:\w]/_/g;
		*{"${pkgname}::AUTOLOAD"} = sub {__pkg_autoload($name, \%attr, @_) };
		next;
	}
	if ($attr{'packaged'}){
		delete $attr{'packaged'};
		my @p = split '\.', $name;
		die "cannot create a package for unpackaged procedure $name (name contains no dots)"
			unless @p>1;
		my $subname = pop @p;
		my $pkgname = join '::', @p;
		$pkgname =~ s/[^:\w]/_/g;
		$subname =~ s/[^:\w]/_/g;
		*{"${pkgname}::$subname"} = sub {__run(wantarray,$name,\%attr, @_) };
		next;
	}
	
	my $subname = $name;
	$subname =~ s/\W/_/g;
        *{"${caller}::$subname"} = sub { 
			__run(wantarray,$name,\%attr, @_)
		};
    }
}

sub __pkg_autoload{
	my $name = shift;
	my $attr = shift;
	my $pkgname = $name;
	$pkgname =~ s/\./::/g;
	$pkgname =~ s/[^:\w]/_/g;
	our $AUTOLOAD;
	my @p = split '::', $AUTOLOAD;
	my $subname = $p[-1];
	$name = "$name.$subname";
	my $sub =  sub { 
			__run(wantarray,$name,$attr, @_);
		};
	no strict 'refs';
	*{"${pkgname}::$subname"} = $sub;
	$sub->(@_);
}


1;
__END__



=head1 NAME

DBIx::ProcedureCall - Perl extension to make database stored procedures look like Perl subroutines

=head1 SYNOPSIS

  use DBIx::ProcedureCall qw(sysdate);
  
  my $conn = DBI->connect(.....);
  
  print sysdate($conn);
  

=head1 DESCRIPTION

When developing applications for a database that supports
stored procedures, it is a good 
idea to put all your database access code right into the
database..

This module provides a convenient way to call stored
procedures from Perl by creating wrapper subroutines that
produce the necessary SQL statements, bind parameters and run
the query.

While this module's interface is database-independent,
only Oracle and PostgreSQL are currently supported.


=head2 EXPORT

DBIx::ProcedureCall exports subroutines for any stored procedures
(and functions) that you ask it to. You specify the list of
procedures that you want when using the module:

    use DBIx::ProcedureCall qw[ sysdate ]
    
    # gives you
    
    print sysdate($conn);
    

Calling such a subroutine will invoke the stored procedure.
The subroutines expect a DBI database handle as
their first parameter.

=head3 Subroutine names

The name of the subroutine is derived from the name
of the stored procedure. Because the procedure name can
contain characters that are not valid in a Perl procedure name,
it will be sanitized a little:

Everything that is not a letter or a number becomes underscores. 
This will happen for all
procedures that are part of a hierarchy (
such as an Oracle PL/SQL package or qualified with a schema),
where
the parts of the procedure name are divided by a dot.

	use DBIx::ProcedureCall qw( 
		sysdate
		dbms_random.random
		hh\$\$uu
		);
		
	# gives you
	
	sysdate();	                          # no change
	dbms_random_random();    # note the underscore
	hh__uu();                           # dollar signs removed


You can request stored procedures that do not exist.
This will not be detected by DBIx::ProcedureCall, but
results in a database error when you try to call them.


=head3 Parameters

You can pass parameters to the subroutines
You can use both positional and named parameters
(if the database you are using supports them),
but cannot mix the two styles in the same call.

Positional parameters are passed in after the 
database handle, which is always the first parameter:

	dbms_random_initialize($conn, 12345);

Named parameters are passed as a hash reference:

	dbms_random_initialize($conn, { val => 12345678 } );

The parameters you use have to match the parameters
defined (in the database) for the stored procedure. 
If they do not, you 
will get a database error at runtime.

=head4 OUT and INOUT parameters

You can also use OUT and INOUT parameters, which return
values from the stored procedure, by setting up a scalar variable
to receive the result and passing a reference to that variable:

	my ($line, $status);
	dbms_output.get_line( $conn, \$line, \$status);
	# $line and $status contain the results now

You might need to specify additional options for DBI to know
how to bind these variables. You can do so by wrapping the
variable reference and the options in an arrayref:

	dbms_output.get_line( $conn, [\$line, 1000], \$status);

The contents of this arrayref will be used in the bind_param_inout
method of the statement handle: Above code results in

	$sql->bind_param_inout(1, \$line, 1000);
	$sql->bind_param_inout(2, \$status, 100); # 100 byte default size

If you do not specify options, the parameters will be bound with
a default maximum size of 100 bytes.

You can also specify these bind options with IN parameters if
you need them.

Please refer to the DBI documentation for details on binding 
variables.


=head3 Attributes

When importing the subroutines, you can optionally specify
one or more attributes. 

	use DBIx::ProcedureCall qw[
		sysdate:cached
		];

A few attributes are independent of the database system that
you use, but most rely on specific functions of the DBMS
implemention. Please see the documentation about the
DBMS you are going to use:

L<DBIx::ProcedureCall::Oracle>

L<DBIx::ProcedureCall::PostgreSQL>

The generic attributes are:

=head4 :cached

Uses DBI's prepare_cached() instead of the default prepare() ,
which can increase database performance. See the DBI documentation 
on how this works.


=head4  :fetch

Some stored procedures can return a result set (this topic
is covered in the DBMS-specific documentation).
DBIx::ProcedureCall provides five :fetch attributes that 
let you control how this result set is transformed
into a Perl data structure, each using a different DBI fetch
method. Check the DBI documents for details.

	:fetch()	does  fetchrow_array and returns the first row
			as a list
	:fetch{}	does fetchrow_hashref and returns the first row
			as a hashref
	:fetch[]  	does fetchrow_arrayref and returns the first row
			as an arrayref
	:fetch[[]]	does fetchall_arrayref and returns all rows
			as an arrayref of arrayrefs
	:fetch[{}]  	does fetchall_arrayref({}) and returns all 
			rows as an arrayref of hashrefs

Example:

	use DBIx::ProcedureCall
		qw(  some_query_function:fetch[{}] );
	
	my $data = some_query_function($conn, @params);
	# $data will look like this
	# [  { column_one => 'data', column_two => 'data' },
	#    { column_one => 'data', column_two => 'data' },
	#    .... more rows ....
	#   { column_one => 'data', column_two => 'data' } ]	


=head2 ALTERNATIVE WAYS TO PASS IN THE DATABASE HANDLE


	my $result = sysdate($conn);

Having to pass in the database handle as a parameter
is a little ugly. If you put your wrapper subroutines
into a package you can use the following syntax

	{
		package MyDB;
		use DBIx::ProcedureCall qw( sysdate );
	}
	
	my $result = $conn->MyDB::sysdate()

You are still passing the handle around, but it 
is visually separated from the "real" parameters.


=head2 ALTERNATIVE INTERFACE

If you do not want to import wrapper functions, you can still
use the SQL generation and parameter binding mechanism
of DBIx::ProcedureCall:

	DBIx::ProcedureCall::run($conn, 'dbms_random.initialize', 12345);

	print DBIx::ProcedureCall::run($conn, 'sysdate');

This can be useful if you do not know the names of the 
stored procedures at compilation time.

You can also use attributes (except for :package[d], which does not make
sense here), with the same syntax as usual:

	DBIx::ProcedureCall::run($conn, 'some_select:fetch[[]]');

=head2 COMMAND LINE INTERFACE

There is also a command line interface:

	 perl -MDBIx::ProcedureCall::CLI -e function sysdate

See L<DBIx::ProcedureCall::CLI>

=head1 SEE ALSO

This module is built on top of L<DBI>, and
you need to use that module (and the appropriate DBD::xx drivers)
to establish a database connection.

You have to read the DBIx::ProcedureCall documentation for the database system
that you are using:

L<DBIx::ProcedureCall::Oracle>

L<DBIx::ProcedureCall::PostgreSQL>

=head1 LIMITATIONS

The module wants to provide an extremely simple interface to the most common forms of stored procedures.
It will not be able to handle very complex cases.
That is not the goal, if it can eliminate 90% of hand-written SQL 
and bind calls, I am happy.


Only Oracle and Postgres are supported now. 
If you want to implement a driver for another data base system,
have a look at the source code for the current implementation,
and see if you can adapt it.
If this leads to working code, let me know, so that I can bundle it.


You cannot mix named and positional parameters


LOB (except for small ones probably) do not work now.
Or maybe they do. I have not tried.

You cannot specify a bind buffer size for function return
values, and thus cannot get return values that do not fit
into the default 100 bytes. A work-around is to use an OUT-parameter
(for which you can set a buffer size).



=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-06 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
