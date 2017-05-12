package DBD::Simulated::st;

=pod

=head1 NAME

DBD::Simulated::st - Statement part for DBD::Simulated

=head1 SYNOPSIS

Do not use this directly without DBI. See L<DBI::DBD> for more information about using a DBD module.

=head1 DESCRIPTION

see L<DBD::Simulated>.

=cut

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

$DBD::Simulated::st::imp_data_size = 0;

sub execute {
	my ($sth, @bind_values) = @_;

	return $sth->set_err($1, "Simulated execute error $1")
	  if $sth->{statement} =~ /simulated_execute_error=(\d+)/;

	return 1 || '0E0';
}

sub fetchrow_arrayref {
	my ($sth) = @_;

	return $sth->set_err($1, "Simulated fetch error $1")
	  if $sth->{statement} =~ /simulated_fetch_error=(\d+)/;

	return;
}
*fetch = \&fetchrow_arrayref;
1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2012 Sebastian Willing, eGENTIC Systems L<http://egentic-systems.com/karriere/>

=cut
