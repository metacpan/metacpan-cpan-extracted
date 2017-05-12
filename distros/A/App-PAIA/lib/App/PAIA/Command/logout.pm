package App::PAIA::Command::logout;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

use App::PAIA::JSON;

sub _execute {
    my ($self, $opt, $args) = @_;

    if ($self->expired) {
        $self->logger("session expired, skip logout"); # TODO: force on request
    } else {
        my $auth = $self->auth // $self->usage_error("missing PAIA auth URL");
        my $response = $self->request( 
            "POST", "$auth/logout", { patron => $self->patron }
        );
        print encode_json($response);
    }

    $self->session->purge && $self->logger->("deleted session file");

    return;
}

1;
__END__

=head1 NAME

App::PAIA::Command::logout - invalidate an access token

=cut
