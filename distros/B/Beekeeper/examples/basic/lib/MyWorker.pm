package MyWorker;

use strict;
use warnings;

use Beekeeper::Worker;
use base 'Beekeeper::Worker';


sub on_startup {
    my $self = shift;

    $self->accept_remote_calls(
        'myapp.str.uc' => 'uppercase',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub uppercase {
    my ($self, $params) = @_;

    my $str = $params->{'string'};

    $str = uc($str);

    return $str;
}

1;
