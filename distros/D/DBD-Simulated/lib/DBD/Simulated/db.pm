package DBD::Simulated::db;

=pod

=head1 NAME

DBD::Simulated::db - Database part for DBD::Simulated

=head1 SYNOPSIS

Do not use this directly without DBI. See L<DBI::DBD> for more information about using a DBD module.

=head1 DESCRIPTION

see L<DBD::Simulated>.

=cut

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

$DBD::Simulated::db::imp_data_size = 0;

sub prepare {
	my ($dbh, $statement, @attribs) = @_;

	# create a 'blank' sth
	my ($outer, $sth) = DBI::_new_sth($dbh, {Statement => $statement});

	return $dbh->set_err($1, "Simulated prepare error $1")
	  if $statement =~ /simulated_prepare_error=(\d+)/;

	$sth->{statement} = $statement;

	return $outer;
}

sub STORE {
	my ($dbh, $attr, $val) = @_;
	if ($attr eq 'AutoCommit') {

		# AutoCommit is currently the only standard attribute we have
		# to consider.
		if (!$val) {die "Can't disable AutoCommit";}
		return 1;
	}
	$dbh->SUPER::STORE($attr, $val);
}

sub FETCH {
	my ($dbh, $attr) = @_;
	if ($attr eq 'AutoCommit') {return 1;}
	$dbh->SUPER::FETCH($attr);
}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2012 Sebastian Willing, eGENTIC Systems L<http://egentic-systems.com/karriere/>

=cut
