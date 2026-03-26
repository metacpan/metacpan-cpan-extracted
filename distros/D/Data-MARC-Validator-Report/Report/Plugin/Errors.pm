package Data::MARC::Validator::Report::Plugin::Errors;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_required);
use Mo::utils::Array qw(check_array check_array_object);

our $VERSION = 0.03;

has errors => (
	default => [],
	is => 'ro',
);

has filters => (
	default => [],
	is => 'ro',
);

has record_id => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'errors'.
	check_array_object($self, 'errors', 'Data::MARC::Validator::Report::Error');

	# Check 'filters'.
	check_array($self, 'filters');

	# Check 'record_id'.
	check_required($self, 'record_id');
	# TODO Check string.

	return;
}

1;

__END__
