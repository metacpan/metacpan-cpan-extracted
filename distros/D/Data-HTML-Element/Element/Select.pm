package Data::HTML::Element::Select;

use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data check_data_type);
use Mo qw(build default is);
use Mo::utils qw(check_bool check_number);
use Mo::utils::CSS qw(check_css_class);

our $VERSION = 0.11;

has autofocus => (
	is => 'ro',
);

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

has form => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has label => (
	is => 'ro',
);

has multiple => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has required => (
	is => 'ro',
);

has size => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check autofocus.
	if (! defined $self->{'autofocus'}) {
		$self->{'autofocus'} = 0;
	}
	check_bool($self, 'autofocus');

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

	# Check multiple.
	if (! defined $self->{'multiple'}) {
		$self->{'multiple'} = 0;
	}
	check_bool($self, 'multiple');

	# Check required.
	if (! defined $self->{'required'}) {
		$self->{'required'} = 0;
	}
	check_bool($self, 'required');

	# Check size.
	check_number($self, 'size');

	return;
}

1;

__END__
