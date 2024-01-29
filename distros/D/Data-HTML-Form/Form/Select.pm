package Data::HTML::Form::Select;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_array_object check_bool check_number);

our $VERSION = 0.07;

has autofocus => (
	is => 'ro',
);

has css_class => (
	is => 'ro',
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

has options => (
	default => [],
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

	# Check options.
	check_array_object($self, 'options', 'Data::HTML::Form::Select::Option', 'Option');

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
