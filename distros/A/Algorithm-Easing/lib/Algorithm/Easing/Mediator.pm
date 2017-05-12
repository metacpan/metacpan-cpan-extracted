package Algorithm::Easing::Mediator;

use Moose;

use Algorithm::Easing::Ease;
use Math::Trig qw(:pi);

use namespace::clean;

has 'kind' => (
    is => 'ro', 
    required => 1,
);

sub ease_none {
	my $self = shift;
	return($self->kind->ease_none(shift,shift,shift,shift));
}

sub ease_in {
	my $self = shift;
	return($self->kind->ease_in(shift,shift,shift,shift));
}

sub ease_out {
	my $self = shift;
	return($self->kind->ease_out(shift,shift,shift,shift));
}

sub ease_both {
	my $self = shift;
	return($self->kind->ease_both(shift,shift,shift,shift));
}

1;