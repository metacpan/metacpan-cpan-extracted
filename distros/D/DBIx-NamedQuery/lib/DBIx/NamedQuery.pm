package DBIx::NamedQuery;
# $Id: NamedQuery.pm 23 2006-06-14 13:21:39Z BoleslavB $

use 5.006;
use strict;
use warnings;

use Carp ();
use Exporter ();
use FileHandle ();


################################################################################


# History
# 0.10 (2006-06-14) - Initial internal release
# 0.11 (2006-06-26) - Fixes in code and in documentation


################################################################################
# Global variables

our @EXPORT_OK = qw(load_named_queries load_named_queries_from_file
		get_named_query set_named_query prepare_named_query
		execute_named_query select_row_from_named_query
		);

our $VERSION = '0.11';

our %NAMED_QUERY = ();


################################################################################
# Named query manipulation

sub load_named_queries
{
	my ($stream_handle) = (@_);
	if (not defined $stream_handle) {
		# By default use DATA stream from main program
		$stream_handle = \*main::DATA;
	} elsif (eof($stream_handle)) {
		Carp::carp("Not an open filehandle: <$stream_handle>");
		return undef;
	}
	# Load complete contents of the stream and preprocess it
	my $stream_contents;
	eval {
		no warnings;
		local $/ = undef;
		$stream_contents = <$stream_handle>;
		close($stream_handle);
	};
	if (not defined $stream_contents) {
		return undef;
	}
	# Preprocess the loaded text
	$stream_contents =~ s/^\s*#.*?\n//gm;
	$stream_contents =~ s/\s+\n/\n/gm;
	# Divide stream into headers and bodies
	my @parts = split(/^(--\[.*?\])\s*$/m, $stream_contents);
	undef($stream_contents);
	my $actual_label = undef;
	foreach my $part (@parts) {
		if ($part =~ /^--\[\s*(.*?)\s*\]\s*$/) {
			# Header part found, begin a new named query
			$actual_label = $1;
			next;
		}
		next unless defined $actual_label;
		# Process body part following the header
		$part =~ s/(?:\A\s*)|(?:\s*\z)//g;
		$NAMED_QUERY{$actual_label} = $part;
		undef($actual_label);
	}
	my $query_count = scalar keys %NAMED_QUERY;
	return $query_count;
}


sub load_named_queries_from_file
{
	my ($filename) = @_;
	my $stream = FileHandle->new($filename, '<');
	if (not defined $stream) {
		return undef;
	}
	return load_named_queries($stream);
}


sub get_named_query
{
	my ($query_name) = @_;
	if (not exists $NAMED_QUERY{$query_name}) {
		return undef;
	}
	return $NAMED_QUERY{$query_name};
}


sub set_named_query
{
	while (my @pair = splice(@_, 0, 2)) {
		last if 2 != scalar @pair;
		my ($query_name, $query_text) = @pair;
		$NAMED_QUERY{$query_name} = $query_text;
	}
}


################################################################################
# Initialization operations

sub import
{
	my ($package, @params) = @_;
	my @new_params = ();
	foreach my $param (@params) {
		if ($param eq 'EXTEND_DBI') {
			extend_DBI_interface();
			next;
		}
		push(@new_params, $param);
	}
	Exporter::import($package, @new_params);
}


sub extend_DBI_interface
{
	# DBI database class infiltration (inserts new methods), but without
	# direct namespace changes
	push(@DBI::db::ISA, 'DBIx::NamedQuery::db');
}


################################################################################
# Named query usage

package DBIx::NamedQuery::db;

sub prepare_named_query
{
	my $db_handle = shift;
	my ($query_name, $prepare_attr) = @_;
	if (not exists $DBIx::NamedQuery::NAMED_QUERY{$query_name}) {
		$db_handle->set_err(1, "Named query '$query_name' has not "
				. 'been defined'
				);
		return undef;
	}
	my $query_text = $DBIx::NamedQuery::NAMED_QUERY{$query_name};
	my $query_handle = $db_handle->prepare($query_text, $prepare_attr);
	if (not defined $query_handle) {
		return undef;
	}
	return $query_handle;
}


sub execute_named_query
{
	my $db_handle = shift;
	my ($query_name, @bind_values) = @_;
	my $statement = $db_handle->prepare_named_query($query_name);
	if (not defined $statement) {
		return undef;
	}
	my $executed = $statement->execute(@bind_values);
	if (not $executed) {
		return undef;
	}
	return $statement;
}


sub select_row_from_named_query
{
	my $db_handle = shift;
	my ($query_name, @bind_values) = @_;
	my $statement = $db_handle->prepare_named_query($query_name);
	if (not defined $statement) {
		return undef;
	}
	my $executed = $statement->execute(@bind_values);
	if (not $executed) {
		return undef;
	}
	my $first_row_arrayref = $statement->fetchrow_arrayref();
	$statement->finish();
	return $first_row_arrayref;
}


################################################################################

1;

__END__

=head1 NAME

DBIx::NamedQuery - Utilities for decoupling of Perl code and SQL statements

=head1 SYNOPSIS

  use DBIx::NamedQuery qw(EXTEND_DBI);

  DBIx::NamedQuery::load_named_queries(*DATA);
  DBIx::NamedQuery::load_named_queries_from_file('customers.sql');
  
  $DBI_statement = $DBI_database_handle->prepare_named_query('invoice');
  
  $DBI_statement = $DBI_database_handle->execute_named_query(
                        'customer_address', $customer_id
                        );

=head1 DESCRIPTION

DBIx::NamedQuery decouples the logic of Perl program and SQL queries. Perl
program references only symbolic names (labels) of queries. The SQL source
can be a separate file or embedded in the program under DATA section.

To reduce the amount of coding, the library can (on demand via import flag
C<EXTEND_DBI>) extend the interface of DBI library, namely the methods of
database object.

=head1 QUERY SOURCE FORMAT

The format of SQL source is suitable for editing in database administration
tools, such as TOAD. The label is (from the SQL point of view) just a
comment.

  --[invoice]
  SELECT * FROM invoice WHERE invoice_id=?
  
  --[customer_address]
  SELECT cust_name, cust_street, cust_street_no, cust_city
  FROM customers
  WHERE cust_id = ?

=head1 STANDARD FUNCTIONS

=over 4

=item load_named_queries (HANDLE)

Loads a set of named queries from open filehandle. Returns number of loaded
queries or C<undef> in case of error.

=item load_named_queries_from_file (FILENAME)

Loads a set of named queries from a file. Returns number of loaded queries or
C<undef> in case of error.

=item get_named_query (LABEL)

Returns a SQL query associated with a given label. If there is no such label,
returns C<undef>.

=item set_named_query (LABEL1 =E<gt> SQL1, ...)

Allows to add/replace one or more named queries in the current set.

=back

=head1 DBI EXTENSION (DATABASE HANDLE METHODS)

=over 4

=item $DB-E<gt>execute_named_query (LABEL [, BIND_VALUES])

Prepares and executes SQL query associated with the label. Placeholders in
SQL are bound with remaining parameters. Returns DBI statement handle or
C<undef> in case of error.

=item $DB-E<gt>select_row_from_named_query (LABEL [, BIND_VALUES])

Executes (most likely C<SELECT>) SQL statement identified by the label
and returns the first row of data as an array reference. In case of error,
C<undef> is returned instead.

=item $DB-E<gt>prepare_named_query (LABEL [, PREPARE_OPTIONS])

Prepares SQL statement identified by the label. Prepare options are passed
to standard DBI method C<$DB-E<gt>prepare()> as additional parameters.

=back

=head1 SEE ALSO

L<DBI>

=head1 AUTHOR

Boleslav Bobcik, E<lt>boleslav.bobcik@ys.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Boleslav Bobcik

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
