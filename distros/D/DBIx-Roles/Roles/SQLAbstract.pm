# $Id: SQLAbstract.pm,v 1.2 2005/11/29 11:55:01 dk Exp $

package DBIx::Roles::SQLAbstract;
use strict;
use vars qw(%defaults $VERSION);
use SQL::Abstract;

$VERSION = '1.00';

# SQL::Abstract parameters to new()
%defaults = (
	case		=> 'textbook',
	cmp		=> '=',
	logic		=> 'or',
	convert		=> 0,
	bindtype	=> 'normal',
	quote_char	=> '',
	name_sep 	=> undef,
);

sub initialize
{
	return [], \%defaults, qw(insert select update delete);
}

sub insert 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('insert', @_);
	$self-> do( $query, {}, @bindval);
}

sub select 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('select', @_);
	my $sth = $self-> prepare( $query);
	$sth-> execute( @bindval) if $sth;
	return $sth;
}

sub update 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('update', @_);
	$self-> do( $query, {}, @bindval);
}

sub delete 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('delete', @_);
	$self-> do( $query, {}, @bindval);
}

sub abstract
{
	my ( $method, $self, $sql, @params) = @_;

	# auto-instantiate, if any
	$sql->[0] = SQL::Abstract-> new( 
		map { $_ => $self->{attr}->{$_} } keys %defaults)
			unless $sql->[0];
 	$sql = $sql->[0];

	return $sql-> $method( @params);
}

sub STORE
{
	my ( $self, $sql, $key, $val) = @_;

	# delete the SQL::Abstract object if settings have changed
	undef $sql->[0] if exists $defaults{$key};

	return $self-> super( $key, $val);
}

1;

__DATA__

=head1 NAME

DBIx::Roles::SQLAbstract - Exports SQL commands C<insert>, C<select> etc as methods.

=head1 DESCRIPTION

The role exports SQL commands C<insert>, C<select>, C<update>, C<delete> after 
L<SQL::Abstract> fashion. See L<SQL::Abstract> for syntax of these methods.

=head1 SYNOPSIS

     use DBIx::Roles qw(SQLAbstract);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
     );

     $dbh-> select( $table, \@fields, \%where, \@order);
     $dbh-> insert( $table, \%fieldvals || \@values);
     $dbh-> update( $table, \%fieldvals, \%where);
     $dbh-> delete( $table, \%where);

=head1 API

Mostly all of the text below is copy-pasted from L<SQL::Abstract> (c) 2001-2005 Nathan Wiger

=over

=item insert( $table, \%fieldvals || \@values);

This is the simplest function. You simply give it a table name and either an
arrayref of values or hashref of field/value pairs.

=item select ($table, \@fields, \%where, \@order)

This takes a table, arrayref of fields (or '*'), optional hashref WHERE clause,
and optional arrayref order by.

Prepares and executes a query, and returns the statement handle, if successful.

=item update( $table, \%fieldvals, \%where);

This takes a table, hashref of field/value pairs, and an optional hashref WHERE clause.

=item delete( $table, \%where);

This takes a table name and optional hashref WHERE clause.

=back

=head1 SEE ALSO

L<DBIx::Roles>, L<SQL::Abstract>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
