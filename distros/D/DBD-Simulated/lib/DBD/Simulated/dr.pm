package DBD::Simulated::dr;

=pod

=head1 NAME

DBD::Simulated::dr - Driver part for DBD::Simulated

=head1 SYNOPSIS

Do not use this directly without DBI. See L<DBI::DBD> for more information about using a DBD module.

=head1 DESCRIPTION

see L<DBD::Simulated>.

=cut

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

$DBD::Simulated::dr::imp_data_size = 0;

sub connect {
	my ($drh, $dr_dsn, $user, $auth, $attr) = @_;

	my $driver_prefix = "simulated_";    # the assigned prefix for this driver

	# Process attributes from the DSN; we assume ODBC syntax
	# here, that is, the DSN looks like var1=val1;...;varN=valN
	foreach my $var (split /;/, $dr_dsn) {
		my ($attr_name, $attr_value) = split /=/, $var, 2;
		return $drh->set_err($DBI::stderr, "Can't parse DSN part '$var'")
		  unless defined $attr_value;

		# add driver prefix to attribute name if it doesn't have it already
		next unless $attr_name =~ /^$driver_prefix/o;

		# Store attribute into %$attr, replacing any existing value.
		# The DBI will STORE() these into $dbh after we've connected
		$attr->{$attr_name} = $attr_value;
	}

	# Simulated connect error
	return $drh->set_err($attr->{simulated_error}, 'Simulated error #' . $attr->{simulated_error})
	  if $attr->{simulated_error};

	# create a 'blank' dbh (call superclass constructor)
	my ($outer, $dbh) = DBI::_new_dbh($drh, {Name => $dr_dsn});

	# STORE = visible within the "public" $dbh returned by DBI->connect
	#      $dbh->STORE('Active', 1 );
	#      $dbh->{drv_connection} = $connection;

	return $outer;
}

sub data_sources {
	return 'dbi:simulated:simulated_error';
}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2012 Sebastian Willing, eGENTIC Systems L<http://egentic-systems.com/karriere/>

=cut
