package Example::BoundedQueueWithBadNewInv;

use strict;
use parent 'Example::BoundedQueue';

sub new {
	my( $class, $size ) = @_;

	my $self = $class->SUPER::new($size);

	$self->{items} = [(0) x ($size + 1)];
    $self;
}

1;
