package DBIx::ProcedureCall::Oracle;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.10';

our $ORA22905;

sub __run_procedure{
	shift;
	my $dbh = shift;
	my $name = shift;
	my $attr = shift;
	my $params;

	# if there is one more arg and it is a hashref, then we use named parameters
	if (@_ == 1 and ref $_[0] eq 'HASH') {
		return __run_procedure_named($dbh, $name, $attr, $_[0]);
	}
	# otherwise they are positional parameters
	my $sql = "begin $name";
	if (@_){
	$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
	}
	$sql .= '; end;';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	DBIx::ProcedureCall::__bind_params($sql, 1, \@_);
	# execute
	$sql->execute;
}

sub __run_procedure_named{
	my ($dbh, $name, $attr, $params) = @_;
	my $sql = "begin  $name";
	my @p = sort keys %$params;
	if (@p){
		@p = map { "$_ => :$_" } @p;
		$sql .= '(' . join (',', @p) . ')';
	}
	$sql .= '; end;';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	DBIx::ProcedureCall::__bind_params($sql, undef, $params);
	# execute
	$sql->execute;
}

sub __run_function{
	shift;
	my $dbh = shift;
	my $name = shift;
	my $attr = shift;
	my $params;
	
	# any fetch implies cursor (unless it is a table function)
	if ( $attr->{'fetch'} and not $attr->{'table'}  ) {
		$attr->{'cursor'} = 1;
	}
	# if there is one more arg and it is a hashref , then we use with named parameters
	if (@_ == 1 and ref $_[0] eq 'HASH') {
		return __run_function_named($dbh, $name, $attr, $_[0]);
	}
	# otherwise they are positional parameters
	
	# table functions
	if ($attr->{table}){
		# workaround for pre-9.2.0.5.0
		if (@_ and $ORA22905){
			my $sql = "select * from table( $name (";
			$sql .= join ',', map{$dbh->quote($_) } @_ ;
			$sql .= '))';
			# prepare
			$sql = $dbh->prepare($sql);
			# execute
			$sql->execute;
			return $sql;
		}
		my $sql = "select * from table( $name";
		if (@_){
			$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
		}
		$sql .= ')';
		eval{
			# prepare
			$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
			: $dbh->prepare($sql);
		};
		# error: if 22905 turn on workaround and try again
		if ($@ and $dbh->err == 22905 and not defined $ORA22905){
			$ORA22905 = 1;
			return __run_function(__PACKAGE__, $dbh, $name, $attr, @_);
		}
		# bind
		DBIx::ProcedureCall::__bind_params($sql, 1, \@_);
		# execute
		$sql->execute;
		return $sql ;
	}
	
	my $sql;
	
	# boolean function needs a conversion wrapper
	if ($attr->{boolean}){
		$sql = 'declare perl_oracle_procedures_b0 boolean; perl_oracle_procedures_n0 number; ';
		$sql .= "begin perl_oracle_procedures_b0 := $name";
		if (@_){
			$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
		}
		$sql .= '; if perl_oracle_procedures_b0 is null then perl_oracle_procedures_n0 := null;elsif perl_oracle_procedures_b0 then perl_oracle_procedures_n0 := 1;else perl_oracle_procedures_n0 := 0;end if; ? := perl_oracle_procedures_n0;end;';
	}
	else{
		$sql = "begin ? := $name";
		if (@_){
			$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
		}
		$sql .= '; end;';
	}
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
		
	# bind
	my $i = 1; 
	# boolean conversion wrapper requires the out value to be bound LAST
	if ($attr->{boolean}){
		DBIx::ProcedureCall::__bind_params($sql, $i, \@_);
		$i += @_;
	}
	my $r;
	
	if ($attr->{cursor}){
		$sql->bind_param_inout($i++, \$r,  0, {ora_type => DBD::Oracle::ORA_RSET()});
	}else{
		$sql->bind_param_inout($i++, \$r, 100);
	}
	
	unless ($attr->{boolean}){
		DBIx::ProcedureCall::__bind_params($sql, $i, \@_);
	}
	
	#execute
	$sql->execute;
	return $r;
}

sub __run_function_named{
	my ($dbh, $name, $attr, $params) = @_;
	# table functions
	if ($attr->{table}){
		croak "cannot execute the table function '$name' with named parameters: only positional parameters are supported.";
	}
	
	my $sql;
	my @p = sort keys %$params;
	# boolean function needs a conversion wrapper
	if ($attr->{boolean}){
		$sql = 'declare perl_oracle_procedures_b0 boolean; perl_oracle_procedures_n0 number; ';
		$sql .= "begin perl_oracle_procedures_b0 := $name";
		if (@p){
			@p = map { "$_ => :$_" } @p;
			$sql .= '(' . join (',', @p) . ')';
		}
		$sql .= '; if perl_oracle_procedures_b0 is null then perl_oracle_procedures_n0 := null;elsif perl_oracle_procedures_b0 then perl_oracle_procedures_n0 := 1;else perl_oracle_procedures_n0 := 0; end if; :perl_oracle_procedures_ret := perl_oracle_procedures_n0;end;';
	}
	else{
		$sql = "begin :perl_oracle_procedures_ret := $name";
		if (@p){
			@p = map { "$_ => :$_" } @p;
			$sql .= '(' . join (',', @p) . ')';
		}
		$sql .= '; end;';
	}
	
	
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	my $r;
	if ($attr->{cursor}){
		$sql->bind_param_inout(':perl_oracle_procedures_ret', \$r,  0, {ora_type => DBD::Oracle::ORA_RSET()});
	}else{
		$sql->bind_param_inout(':perl_oracle_procedures_ret', \$r, 100);
	}
	# bind
	DBIx::ProcedureCall::__bind_params($sql, undef, $params);
	
	# execute
	$sql->execute;
	return $r;
}

sub __close{
	shift;
	my $sth = shift;
	my $conn = $sth->{Database};
	my $sql = $conn->prepare('BEGIN   close :curref; END;');
	$sql->bind_param(":curref", $sth, {ora_type => DBD::Oracle::ORA_RSET()});
	$sql->execute;
}



1;
__END__


=head1 NAME

DBIx::ProcedureCall::Oracle - Oracle driver for DBIx::ProcedureCall

=head1 DESCRIPTION

This is an internal module used by DBIx::ProcedureCall. You do not need
to access it directly. However, you should read the following
documentation, because it explains how to use DBIx::ProcedureCall
with Oracle databases.

=head2 Procedures and functions

DBIx::ProcedureCall needs to know if you are about
to call a function or a procedure (because the SQL is different).
You have to make sure you call the wrapper subroutines
in the right context (or you can optionally declare
the correct type, see below)

You have to call procedures in void context.

	# works
	dbms_random_initialize($conn, 12345);
	# fails
	print dbms_random_initialize($conn, 12345);

You have to call functions in non-void context.

	# works
	print sysdate($conn);
	# fails
	sysdate($conn);

If you try to call a function as a procedure, you will get
a database error.

If you do not want to rely on this mechanism, you can
declare the correct type using the attributes :procedure
and :function:

	use DBIx::ProcedureCall qw[
		sysdate:function
		dbms_random.initialize:procedure
		];

If you use these attributes, the calling context will be
ignored and the call will be dispatched according to 
your declaration.

In addition to "normal" stored procedures and functions,
you can also use table functions, which again need a
different kind of SQL statement. You use table functions
with the :table attribute.

=head2 Returning result sets

There are two types of functions that return result sets,
table functions and ref cursors. To use either, you have to
use the special attributes :table or :cursor when declaring
the function to DBIx::ProcedureCall. The attributes are explained
in detail
below.


=head2 Oracle-specific attributes

Currently known attributes are:

=head3 :procedure / :function

Declares the stored procedure to be a function or a procedure,
so that the context in which you call the subroutine is of no importance
any more.

=head3 :packaged

Rather than importing the generated wrapper subroutine into
your own module's namespace, you can request to create it
in another package, whose name will be derived from the
name of the stored procedure by replacing any dots (".") with 
the Perl namespace seperator "::". 

	use DBIx::ProcedureCall qw[
		schema.package.procedure:packaged
		];

will create a subroutine called

	schema::package::procedure


=head3 :package

When working with PL/SQL packages, you can declare the whole
package instead of the individual procedures inside. This will
set up a Perl package with an AUTOLOAD function, which automatically
creates wrappers for the procedures in the package 
when you call them.

	use DBIx::ProcedureCall qw[
		schema.package:package
		];
	
	my $a = schema::package::a_function($conn, 1,2,3);
	schema::package::a_procedure($conn);

If you declare additional attributes, these attributes will 
be used for the AUTOLOADed wrappers.

If you need special attributes for individual parts of the package,
you can mix in the :packaged style explained above:

	# create a package of functions
	# with the odd procedure
	use DBIx::ProcedureCall qw[
		schema.package:package:function
		schema.package.a_procedure:packaged:procedure
		];		


=head3 :cursor 

This attribute declares a function (it includes an implicit :function)
that returns a refcursor, like this one:

	create function test_cursor 
		return sys_refcursor
		is
			c_result sys_refcursor;
		begin
			open c_result for
			select * from dual;
			return c_result;
		end;

Using :cursor, the wrapper function will give you that cursor. Check
the DBD::Oracle documentation about what you can do with that cursor.

Chances are that what you want to do with the cursor is fetch all its
data and then close it. You can use one of the various :fetch attributes
for just that. If you do, the wrapper function takes care of the cursor
and returns the data.

=head3 :table

A table function also returns a result set:

	create or replace type str2tblType as table of varchar2(100);
	/

	create or replace function str2tbl( p_str in varchar2, p_delim in varchar2 
	default ',' ) return str2tblType
	PIPELINED
	as
	    l_str      long default p_str || p_delim;
	    l_n        number;
	begin
	    loop
		l_n := instr( l_str, p_delim );
		exit when (nvl(l_n,0) = 0);
		pipe row( ltrim(rtrim(substr(l_str,1,l_n-1))) );
		l_str := substr( l_str, l_n+1 );
	    end loop;
	    return;
	end;
	/

	select * from str2tbl ('1,2,3');

Similar to :cursor, you can either fetch from that result set
yourself (by just declaring :table), or you can use
one of the fetch methods (by declaring :fetch IN ADDITION to :table).

	use DBIx::ProcedureCall	qw(
		str2tbl:table:fetch[[]]
		);
		
	my $data = str2tbl($conn, '1,2,3');
	
	# $data will be like [ [1], [2], [3] ]

=head4 No named parameters for table functions

The syntax to call table functions does not supported named
parameters. You have to use positional parameters.

=head4 Caveat ( ORA-22905 )

There seems to be a bug in Oracle that prevents the use of bind
variables for parameters to table functions
(it will fail with an ORA-22905 error -- "cannot access rows from a non-nested table item").
This appears to affect all versions prior to 9.2.0.5.0,
but has also been seen on later releases on some systems.

Therefore, on affected systems DBIx::ProcedureCall will pass in the parameters 
literally (not using bind variables) when connected to older Oracle
versions. This does not scale very well, so you should consider an 
upgrade. (Table functions without parameters are not affected).

A system is considered affected if a :table function
results in ORA-22905. From that point on, the workaround
described above is put in effect for all subsequent queries.


=head3 :fetch

Unless you also specify :table, :fetch assumes that
you return the result set using a refcursor (:cursor).


=head3 :boolean

Unfortunately, Oracle does not automatically convert from
BOOLEAN to strings. You can specify :boolean to declare
a function that returns a BOOLEAN. This will create wrapper
code to convert it to 1/0/undef for true/false/NULL.

BOOLEAN values as arguments to procedure calls are currently
not supported.

=head1 SEE ALSO

L<DBIx::ProcedureCall> for information about this
module that is not Oracle-specific.

L<DBD::Oracle>

L<DBIx::Procedures::Oracle> offers similar functionality.
Unlike DBIx::ProcedureCall, it takes the additional step of
checking in the data dictionary if the procedures you want
exist, and what parameters they need.



=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-06 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


