package MyApp::Service::Scraper;

use strict;
use warnings;

use Beekeeper::Client;


# These two implementations call exactly the same remote method

sub get_title {
    my ($self, $url) = @_;

    # This will block until a response is received

    my $client = Beekeeper::Client->instance;

    my $response = $client->call_remote(
        method      => 'myapp.scraper.get_title',
        params      => { url => $url },
        raise_error => 0,
    );

    return $response;
}

sub get_title_async {
    my ($self, $url, $on_complete) = @_;

    # This will return immediately. The response will be received asynchronously

    my $client = Beekeeper::Client->instance;

    my $request = $client->call_remote_async(
        method     => 'myapp.scraper.get_title',
        params     => { url => $url },
        on_success => $on_complete,
        on_error   => $on_complete,
    );

    return $request;
}

1;
