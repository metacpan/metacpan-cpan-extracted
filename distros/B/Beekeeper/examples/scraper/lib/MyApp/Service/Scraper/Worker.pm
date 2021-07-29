package MyApp::Service::Scraper::Worker;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use AnyEvent::HTTP;


sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my $self = shift;

    $self->accept_remote_calls(
        'myapp.scraper.get_title' => 'get_title',
    );

    log_info "Ready";
}

sub on_shutdown {
    my $self = shift;

    log_info "Stopped";
}


sub get_title {
    my ($self, $params, $request) = @_;

    my $url = $params->{'url'};

    unless (defined $url && $url =~ m|^https?://[a-zA-Z0-9/.]+$|) {

        die Beekeeper::JSONRPC::Error->invalid_params( message => "Invalid url" );
    }

    # The response for this request will not be sent at the end of this method.
    # It will be sent when http_get finishes using $request->send_response
    $request->async_response;

    http_get $url, sub {
        my ($body, $headers) = @_;

        if ($headers->{Status} =~ m/^2/) {

            my ($title) = $body =~ m|<title>(.*?)</title>|i;

            $request->send_response( $title );
        }
        else {

            log_error "$url - $headers->{Status} $headers->{Reason}";

            my $response = Beekeeper::JSONRPC::Error->new(
                code    => $headers->{Status},
                message => $headers->{Reason},
            );

            $request->send_response( $response );
        }
    };

    # The worker is now ready to process other requests concurrently.
    # Any value returned here will be ignored
    undef;
}

1;
