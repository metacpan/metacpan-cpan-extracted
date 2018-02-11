package Example::BoundedQueueWithBadPush;

use parent 'Example::BoundedQueue';


sub push {
	my( $self, $item ) = @_;

	push @{ $self->{ items } }, $item;
}

1;
