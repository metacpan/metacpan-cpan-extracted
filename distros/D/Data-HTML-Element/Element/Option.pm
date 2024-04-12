package Data::HTML::Element::Option;

use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data check_data_type);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build is);
use Mo::utils qw(check_array check_bool check_number);
use Mo::utils::CSS qw(check_css_class);

our $VERSION = 0.13;

has css_class => (
	is => 'ro',
);

has data => (
	default => [],
	is => 'ro',
);

has data_type => (
	is => 'ro',
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

	# Check CSS class.
	check_css_class($self, 'css_class');

	# Check data type.
	check_data_type($self);

	# Check data based on type.
	check_data($self);

	# Check disabled.
	if (! defined $self->{'disabled'}) {
		$self->{'disabled'} = 0;
	}
	check_bool($self, 'disabled');

	# Check selected.
	if (! defined $self->{'selected'}) {
		$self->{'selected'} = 0;
	}
	check_bool($self, 'selected');

	return;
}

1;

__END__
