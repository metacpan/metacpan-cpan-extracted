package Data::HTML::Form::Input;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Mo qw(build is);
use Mo::utils qw(check_bool check_number);
use Readonly;

Readonly::Array our @TYPES => qw(button checkbox color date datetime-local
	email file hidden image month number password radio range reset search
	submit tel text time url week);

our $VERSION = 0.04;

has checked => (
	is => 'ro',
);

has css_class => (
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

has max => (
	is => 'ro',
);

has min => (
	is => 'ro',
);

has placeholder => (
	is => 'ro',
);

has readonly => (
	is => 'ro',
);

has required => (
	is => 'ro',
);

has size => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

has type => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check checked.
	check_bool($self, 'checked');

	# Check disabled.
	check_bool($self, 'disabled');

	# Check max.
	check_number($self, 'max');

	# Check min.
	check_number($self, 'min');

	# Check readonly.
	check_bool($self, 'readonly');

	# Check required.
	check_bool($self, 'required');

	# Check size.
	check_number($self, 'size');

	# Check type.
	if (! defined $self->{'type'}) {
		$self->{'type'} = 'text';
	}
	if (none { $self->{'type'} eq $_ } @TYPES) {
		err "Parameter 'type' has bad value.";
	}

	return;
}

1;

__END__
