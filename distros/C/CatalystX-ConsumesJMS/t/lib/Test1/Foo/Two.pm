package Test1::Foo::Two;
use Moose;
extends 'Test1::Base::Foo';

sub routes {
    return {
        base_url2 => {
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
