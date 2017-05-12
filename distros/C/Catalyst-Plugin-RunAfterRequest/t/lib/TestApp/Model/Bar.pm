package TestApp::Model::Bar;

use Moose;

our @data;

extends 'Catalyst::Model';

with 'Catalyst::Model::Role::RunAfterRequest';

our $BPCI_GOT_RUN;

sub build_per_context_instance {
    my $self=shift;

    $BPCI_GOT_RUN = 1;

    return $self;
}


sub demonstrate {
    my $self = shift;
    $self->_run_after_request(
        sub { push( @data, "one" ); },
        sub { push( @data, "two" ); },
        sub { push @data, ref shift },
    );
}

1;
