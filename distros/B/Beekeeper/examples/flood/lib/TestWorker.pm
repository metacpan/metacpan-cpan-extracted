package TestWorker;

use strict;
use warnings;

use Beekeeper::Worker;
use base 'Beekeeper::Worker';


sub on_startup {
    my $self = shift;

    $self->accept_remote_calls(
        'myapp.test.echo' => 'echo',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub echo {
    my ($self, $params) = @_;

    return $params;
}

1;
