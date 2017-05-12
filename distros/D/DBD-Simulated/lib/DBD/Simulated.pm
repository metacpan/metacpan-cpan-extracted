package DBD::Simulated;

=pod

=head1 NAME

DBD::Simulated - Fake DBI database driver simulating a database for testing error checks

=head1 SYNOPSIS

Do not use this directly without DBI. See L<DBI::DBD> for more information about using a DBD module.

=head1 DESCRIPTION

Every major project has it's own database access module, I never saw one directly using DBI all the time.

Custom source must be tested but it isn't easy to create predefined error cases using real databases for testing
your own database error handling source.

This fake database driver simulates a real database usable via DBI. It can neither store nor fetch data or run any
kind of real SQL queries but it could return any error state you want.

=head1 connect

Use DBI->connect as usual.

  my $dbh = DBI->connect('DBI:Simulated:database=success;simulated_error=256');

Only one dsn named argument is supported right now: I<simulated_error> expects a positive or negative number which is returned
as connect error code and no connection object is returned. All other arguments are simply ignored.

You may pass any real-life DSN string to get a simulated database handle and simply add the I<simulated_error> to get a simulated
error code.

=head1 prepare

Any query will be accepted by prepare, all arguments are ignored.

Add I<simulated_prepare_error=XXX> to your query to trigger a prepare-error. XXX must be a number.

  my $dbh = DBI->connect('DBI:Simulated:database=success');
  $dbh->prepare('SELECT * FROM MyTable WHERE simulated_prepare_error=1024');

=head1 execute

Prepare any statement containing I<simulated_execute_error=XXX> and execute it to trigger error code XXX (must be a number - as always).

  my $dbh = DBI->connect('DBI:Simulated:database=success');
  my $sth = $dbh->prepare('SELECT * FROM MyTable WHERE simulated_execute_error=1024');
  $sth->execute;

=head1 fetch*

Prepare any statement containing I<simulated_fetch_error=XXX> and to trigger error code XXX (must be a number - as always).

  my $dbh = DBI->connect('DBI:Simulated:database=success');
  my $sth = $dbh->prepare('SELECT * FROM MyTable WHERE simulated_fetch_error=65535');
  $sth->execute;
  $sth->fetchall_arrayref;

Notice that fetch always returns undef (looks like to data returned by the query) but also sets the error code if requested.

=head1 Other DBI methods

Other DBI methods like I<do> and I<prepare_cached> fall back to the default methods shown above. All error strings may be used when calling them.

=cut

use 5.010;
use strict;
use warnings;

use DBD::Simulated::dr;
use DBD::Simulated::db;
use DBD::Simulated::st;

our $VERSION = '0.01';
our $drh;

sub driver {
	return $drh if $drh;    # already created - return same one
	my ($class, $attr) = @_;

	$class .= "::dr";

	$drh = DBI::_new_drh(
		$class,
		{
			'Name'        => 'Simulated',
			'Version'     => $VERSION,
			'Attribution' => 'DBD::Simulated by Sebastian Willing',
		}
	) or return undef;

	return $drh;
}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2012 Sebastian Willing, eGENTIC Systems L<http://egentic-systems.com/karriere/>

=cut
