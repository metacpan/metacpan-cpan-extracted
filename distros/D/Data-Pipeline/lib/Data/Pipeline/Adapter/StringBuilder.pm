package Data::Pipeline::Adapter::StringBuilder;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Iterator::ArrayOptions;
use URI;

has pattern => (
    isa => 'ArrayRef',
    is => 'rw',
    required => 1,
);

has '+source' => (
    default => sub {
        my $self = shift;

        return Data::Pipeline::Iterator::ArrayOptions -> new(
            params => $self -> pattern
        ) -> source;
    }
);

1;

__END__
