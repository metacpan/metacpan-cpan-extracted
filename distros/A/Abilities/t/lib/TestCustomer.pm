package TestCustomer;

use Moo;
use namespace::autoclean;

has 'name' => (
	is => 'ro',
	required => 1
);

has 'features' => (
	is => 'ro',
	default => sub { [] }
);

has 'plans' => (
	is => 'ro',
	default => sub { [] }
);

has 'mg' => (
	is => 'ro',
	required => 1,
);

with 'Abilities::Features';

sub get_plan {
	my ($self, $plan) = @_;

	return $self->mg->{$plan};
}

around qw/features plans/ => sub {
	my ($orig, $self) = @_;

	return @{$self->$orig || []};
};

1;
