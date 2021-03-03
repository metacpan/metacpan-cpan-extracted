package BoardStreams::Client::WebSocket;

use Mojo::Base -strict, -signatures;

use Mojo::UserAgent;
use RxPerl::Mojo ':all';

use Exporter 'import';
our @EXPORT_OK = qw/ make_websocket_observable /;

our $VERSION = "v0.0.22";

sub _ua {
    state $ua = Mojo::UserAgent->new;
}

sub make_websocket_observable ($url) {
    return rx_observable->new(sub ($subscriber) {
        _ua->websocket($url, sub ($ua, $tx) {
            if ($tx->is_websocket) {
                say "Websocket connection opened";
                $tx->on(finish => sub {
                    say "Websocket connection closed";
                    $subscriber->complete;
                });
                $subscriber->next($tx);
            } else {
                say "Websocket connection emitted an error",
                    $tx->error ? ': ' . $tx->error->{message} : '';
                $subscriber->complete;
            }
        });
    });
}

1;
