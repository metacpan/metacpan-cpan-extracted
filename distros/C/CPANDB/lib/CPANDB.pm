package CPANDB; # git description: af7547f

use 5.008005;
use strict;
use warnings;
use IO::File             ();
use DateTime        0.55 ();
use Params::Util    1.00 ();
use ORLite          1.51 ();
use ORLite::Mirror  1.20 ();

our $VERSION = '0.19';
our @LOCATION = (
	locale    => 'C',
	time_zone => 'UTC',
);

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://svn.ali.as/db/cpandb.bz2';
	$params->{maxage} ||= 24 * 60 * 60; # One day

	# Always turn on string eval debugging if Perl is new enough
	if ( $^V > 5.008008 ) {
		$^P = $^P | 0x800;
	}

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

sub latest {
	my $class = shift;

	# Find the distribution most recently uploaded
	my @latest = CPANDB::Distribution->select(
		'ORDER BY uploaded DESC LIMIT 1',
	);
	unless ( @latest == 1 ) {
		die "Unexpected number of uploads";
	}

	# When was it?
	return $latest[0]->uploaded;
}

sub latest_datetime {
	my $class  = shift;
	my @latest = split /\D+/, $class->latest;
	return DateTime->new(
		year  => $latest[0],
		month => $latest[1],
		day   => $latest[2],
		@LOCATION,
	);
}

sub age {
	my $class    = shift;
	my $latest   = $class->latest_datetime;
	my $today    = DateTime->today( @LOCATION );
	my $duration = $today - $latest;
	return $duration->in_units('days');
}

sub distribution {
	my $self = shift;
	my @dist = CPANDB::Distribution->select(
		'where distribution = ?', $_[0],
	);
	unless ( @dist ) {
		die("Distribution '$_[0]' does not exist");
	}
	return $dist[0];
}

sub graph {
	require Graph;
	require Graph::Directed;
	my $class = shift;
	my $graph = Graph::Directed->new;
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	return $graph;
}

sub easy {
	require Graph::Easy;
	my $class = shift;
	my $graph = Graph::Easy->new;
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	return $graph;	
}

sub xgmml {
	require Graph::XGMML;
	my $class = shift;
	my @param = ( @_ == 1 ) ? ( OUTPUT => IO::File->new( shift, 'w' ) ) : ( @_ );
	my $graph = Graph::XGMML->new( directed => 1, @param );
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	$graph->end;
	return 1;
}

sub csv {
	my $class = shift;
	my $file  = shift;
	my $csv   = IO::File->new($file, 'w');
	foreach my $edge ( CPANDB::Dependency->select ) {
		$csv->print( $edge->distribution . "\t" . $edge->dependency . "\n" );
	}
	$csv->close;
}

1;
__END__

=pod

=head1 NAME

CPANDB - A unified database of CPAN metadata information

=head1 DESCRIPTION

B<CPANDB> is an module for accessing CPAN metadata merged from many different
CPAN websites into a single object model, downloaded automatically and without
the need for any configuration.

=head1 METHODS

=head2 dsn

  my $string = CPANDB->dsn;

The C<dsn> accessor returns the L<DBI> connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = CPANDB->dbh;

To reliably prevent potential L<SQLite> deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with connection management in
L<ORLite>.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond your immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 begin

  CPANDB->begin;

The C<begin> method indicates the start of a transaction.

In the same way that ORLite allows only a single connection, likewise
it allows only a single application-wide transaction.

No indication is given as to whether you are currently in a transaction
or not, all code should be written neutrally so that it works either way
or doesn't need to care.

Returns true or throws an exception on error.

=head2 rollback

The C<rollback> method rolls back the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the rollback has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

If a transaction exists at END-time as the process exits, it will be
automatically rolled back.

Returns true or throws an exception on error.

=head2 do

  CPANDB->do(
      'insert into table ( foo, bar ) values ( ?, ? )', {},
      \$foo_value,
      \$bar_value,
  );

The C<do> method is a direct wrapper around the equivalent L<DBI> method,
but applied to the appropriate locally-provided connection or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = CPANDB->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a database. See the L<SQLite> documentation for more details.

=head1 SUPPORT

B<CPANDB> is based on L<ORLite>.

Documentation created by L<ORLite::Pod> 0.10.

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANDB>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
