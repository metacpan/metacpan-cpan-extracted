package Example::Contract::BoundedQueueByExtension;

use Class::DbC
    extends => 'Example::Contract::Queue',

    invariant => {
        max_size_not_exceeded => sub {
            my ($self) = @_;
            $self->size <= $self->max_size;
        },
    },
;

1;
