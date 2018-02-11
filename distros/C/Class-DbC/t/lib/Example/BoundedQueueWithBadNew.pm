package Example::BoundedQueueWithBadNew;

use parent 'Example::BoundedQueue';

sub new {
	my( $class, $size ) = @_;

	my $self = $class->SUPER::new($size);

	$self->{items} = [undef];
    $self;
}

1;
