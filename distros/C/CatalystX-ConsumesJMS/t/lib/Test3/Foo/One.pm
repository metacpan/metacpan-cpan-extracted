package Test3::Foo::One;
use Moose;
extends 'Test3::Base::Foo';

sub routes {
    return {
        input_queue => {
            my_type => {
                code => \&consume_it,
            }
        },
    };
}

has messages => (
    isa => 'ArrayRef',
    is => 'rw',
    default => sub { [ ] },
);

sub consume_it {
    my ($self,$message,$headers) = @_;

    push @{$self->messages},[$headers,$message];

    return;
}

1;
