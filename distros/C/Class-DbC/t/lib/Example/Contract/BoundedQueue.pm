package Example::Contract::BoundedQueue;

use Class::DbC
    interface => {
        new => {
            precond => {
                positive_int_size => sub {
                    my (undef, $size) = @_;
                    $size =~ /^\d+$/ && $size > 0;
                },
            },
            postcond => {
                zero_sized => sub {
                    my ($obj) = @_;
                    $obj->size == 0;
                },
            }
        },
        head => {},
        tail => {},
        size => {},
        max_size => {},

        push => {
            postcond => {
                size_increased => sub {
                    my ($self, $old) = @_;

                    return $self->size < $self->max_size
                        ? $self->size == $old->size + 1
                        : 1;
                },
                tail_updated => sub {
                    my ($self, $old, $results, $item) = @_;
                    $self->tail == $item;
                },
            }
        },

        pop => {
            precond => {
                not_empty => sub {
                    my ($self) = @_;
                    $self->size > 0;
                },
            },
            postcond => {
                returns_old_head => sub {
                    my ($self, $old, $results) = @_;
                    $results->[0] == $old->head;
                },
            }
        },
    },
    invariant => {
        max_size_not_exceeded => sub {
            my ($self) = @_;
            $self->size <= $self->max_size;
        },
    },
;

1;
