package Data::MARC::Validator::Report::Error;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_required);
use Mo::utils::Hash qw(check_hash);

our $VERSION = 0.03;

has error => (
	is => 'ro',
);

has params => (
	default => {},
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'error'.
	check_required($self, 'error');

	# Check 'params'.
	check_hash($self, 'params');

	return;
}

1;

__END__
