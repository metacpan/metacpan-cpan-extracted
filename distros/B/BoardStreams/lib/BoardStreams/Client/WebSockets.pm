package BoardStreams::Client::WebSockets;

use Mojo::Base -strict, -signatures;

use BoardStreams::Client::Util 'debug';

use Mojo::UserAgent;
use RxPerl::Mojo ':all';

use Exporter 'import';
our @EXPORT_OK = qw/ make_websockets_observable /;

our $VERSION = "v0.0.31";

sub make_websocket_observable ($url, $ua) {
    return rx_observable->new(sub ($subscriber) {
        my $_tx;

        my $tx_has_finished;
        $ua->websocket($url, sub ($, $tx) {
            $_tx = $tx;
            if (! $tx->is_websocket) {
                debug("WebSocket connection failed, or handshake failed!");
                $tx->res->error({message => "Didn't upgrade connection, cancelling it"}) if $tx->res;
                $tx_has_finished = 1;
                $subscriber->complete();
                return;
            }

            # on close
            $tx->on(finish => sub {
                $tx_has_finished = 1;
                debug("WebSocket connection closed");
                $subscriber->complete();
            });

            # on open
            debug("WebSocket connection opened");
            $subscriber->next($tx);
        });

        return sub { $_tx->finish if $_tx->is_websocket and ! $tx_has_finished };
    });
}

sub make_websockets_observable ($url, $manager) {
    return rx_observable->new(sub ($subscriber) {
        my @delays = (0, 1, 2, 3, 4, 5);
        my $num_failures = 0;

        my $s = rx_defer(sub {
            rx_concat(
                make_websocket_observable($url, $manager->ua),
                rx_of(undef),
                rx_defer(sub {
                    my $delay = $delays[$num_failures++] // $delays[-1];
                    return rx_timer($delay)->pipe(op_ignore_elements());
                }),
            );
        })->pipe(
            op_tap(sub ($x) { $num_failures = 0 if $x }),
            op_repeat(),
            op_start_with(undef),
            op_distinct_until_changed(),
        )->subscribe($subscriber);

        return $s;
    });
}

1;
