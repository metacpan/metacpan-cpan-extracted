package Test2::Foo::One;
use Moose;
extends 'Test2::Base::Foo';

sub routes {
    return {
        base_url => {
            my_action => {
                code => \&do_it,
            }
        },
    };
}

has calls => (
    isa => 'ArrayRef',
    is => 'rw',
    default => sub { [ ] },
);

sub do_it {
    my ($self,$body,$headers) = @_;

    push @{$self->calls},[$headers,$body];

    return;
}

1;
