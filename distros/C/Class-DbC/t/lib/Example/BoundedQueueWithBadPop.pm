package Example::BoundedQueueWithBadPop;

use parent 'Example::BoundedQueue';

sub pop {
	my $self = shift;

	pop @{ $self->{ items } };
}

1;
