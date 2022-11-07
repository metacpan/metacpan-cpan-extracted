package Data::HTML::Form::Select::Option;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Mo qw(build is);
use Mo::utils qw(check_bool check_number);
use Readonly;

Readonly::Array our @DATA_TYPES => qw(plain tags);

our $VERSION = 0.06;

has css_class => (
	is => 'ro',
);

has data => (
	default => [],
	ro => 1,
);

has data_type => (
	ro => 1,
);

has disabled => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has label => (
	is => 'ro',
);

has selected => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check data type.
	if (! defined $self->{'data_type'}) {
		$self->{'data_type'} = 'plain';
	}
	if (none { $self->{'data_type'} eq $_ } @DATA_TYPES) {
		err "Parameter 'data_type' has bad value.";
	}

	# Check disabled.
	check_bool($self, 'disabled');

	# Check selected.
	check_bool($self, 'selected');

	return;
}

1;

__END__
