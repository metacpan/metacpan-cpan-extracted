package Example::BoundedQueue;

use parent 'Example::BoundedQueueBase';

sub new {
	my( $class, $size ) = @_;

	bless {
		max_size => $size,
		items => [],
	}, $class;
}

1;
