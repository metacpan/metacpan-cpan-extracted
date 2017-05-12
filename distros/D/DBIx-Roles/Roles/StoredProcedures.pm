# $Id: StoredProcedures.pm,v 1.1.1.1 2005/11/20 18:01:06 dk Exp $

package DBIx::Roles::StoredProcedures;

use strict;
use vars qw($VERSION);

$VERSION = '1.00';

sub initialize
{
	return undef, undef, qw(call_function);
}

sub call_function
{
	my ( $self, $storage, $function, @params) = @_;
	
	return $self-> selectrow_array(
		"SELECT $function (".
			join(',', map { '?' } @params) .
		")", 
		{},
		@params
	);
}

# XXX any() is greedy here, but checking whether there is a corresponding stored procedure
# takes intimate knowledge about the particular DBD driver, so we leave that for now
sub any
{
	my ( $self, $storage, $method, @params) = @_;

	return call_function( $self, $storage, $method, @params);
}

1;

__DATA__

=head1 NAME

DBIx::Roles::StoredProcedures - Treats any method reached AUTOLOAD as a call to a 
stored procedure.

=head1 DESCRIPTION

Useful when database contains many stored procedures.

=head1 SYNOPSIS

     use DBIx::Roles qw(StoredProcedures);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
     );

     print $dbh-> pg_backend_pid(), "\n";

=head1 SEE ALSO

L<DBIx::Roles>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut

