package DBIx::ProcedureCall::PostgreSQL;

use strict;
use warnings;

our $VERSION = '0.08';




sub __run_function{
	shift;
	my $dbh = shift;
	my $name = shift;
	my $attr = shift;
	my $params;
	
	# any fetch implies a table function)
	if ( $attr->{'fetch'}   ) {
		$attr->{'table'} = 1;
	}
	
	# if there is one more arg and it is a hashref , then we use with named parameters
	if (@_ == 1 and ref $_[0] eq 'HASH') {
		die "PostgreSQL does not support named parameters, use positional parameters in your call to '$name'. \n";
	}
	# otherwise they are positional parameters
	
	# table functions
	if ($attr->{table}){
		my $sql = "select * from $name(";
		if (@_){
			$sql .= join (',' , map ({ '?'} @_  ));
		}
		$sql .= ')';
		# prepare
		$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
		# bind
		DBIx::ProcedureCall::__bind_params($sql, 1, \@_);
		# execute
		$sql->execute;
		return $sql;
	}
	
	
	my $sql = "select $name";
	if (@_){
	$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
	}
	$sql .= ';';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	DBIx::ProcedureCall::__bind_params($sql, 1, \@_);
	
	#execute
	$sql->execute;
	my ($r) = $sql->fetchrow_array;
	return $r;
}

{
	no strict 'refs';
	# there are no procedures, only void functions
	*__run_procedure = \&__run_function;
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

DBIx::ProcedureCall::PostgreSQL - PostgreSQL driver for DBIx::ProcedureCall

=head1 DESCRIPTION

This is an internal module used by DBIx::ProcedureCall. You do not need
to access it directly.However, you should read the following
documentation, because it explains how to use DBIx::ProcedureCall
with PostgreSQL databases.

=head2 Only IN parameters

PostgreSQL stored procedures do not support OUT parameters.

=head2 No named parameters

PostgreSQL stored procedures do not support named parameters.
You will have to use positional parameters.

=head2 Returning result sets

You can use table functions to return result sets.


	CREATE FUNCTION test_table_func() RETURNS SETOF pg_user AS $$
		SELECT * FROM pg_user;
	$$ LANGUAGE SQL;

=head3 :table / :fetch

To access the function from Perl, you have to declare it
as a table function (using :table). It will then return a DBI
statement handle from which you can fetch (and then close
the result set).

You can also let DBIx::ProcedureCall fetch the data for you
by using one of the :fetch attributes:
	
	use DBIx::ProcedureCall qw( test_table_func:fetch[[]] )

If you specify a :fetch, this implies :table.


=head1 SEE ALSO

L<DBIx::ProcedureCall> for information about this
module that is not PostgreSQL-specific.

L<DBD::Pg>


=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


