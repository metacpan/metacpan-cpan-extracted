package Data::Pipeline::Iterator::Output;

use Moose;

use Data::Pipeline::Types qw( Iterator Adapter );
use Data::Pipeline::Machine;

has iterator => (
    is => 'ro',
    isa => Iterator,
    required => 1
);

has serializer => (
    is => 'ro',
    isa => Adapter,
    required => 1
);

sub to {
    my($self, $target, @options) = @_;

    $self -> serializer -> serialize( $self -> iterator, $target );
}

1;

__END__
