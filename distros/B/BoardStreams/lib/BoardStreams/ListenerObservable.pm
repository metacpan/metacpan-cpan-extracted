package BoardStreams::ListenerObservable;

use Mojo::Base -strict, -signatures;

use BoardStreams::Registry;

use Mojo::JSON 'to_json';
use RxPerl::Mojo ':all';

use Exporter 'import';
our @EXPORT_OK = qw/ get_listener_observable /;

my %listener_observables;

sub get_listener_observable ($c, $channel_name) {
    return $listener_observables{$channel_name} //= rx_observable->new(sub ($subscriber) {
        my $cb = $c->bs->pubsub->json($channel_name)->listen($channel_name => sub ($pubsub, $payload) {
            $subscriber->next($payload);
        });

        return sub {
            $c->bs->pubsub->unlisten($channel_name => $cb);
            delete $listener_observables{$channel_name};
        };
    })->pipe(
        op_tap(sub ($payload) {
            my $channel_users = BoardStreams::Registry->query($channel_name);
            my $json_msg = to_json {
                type    => 'event_patch',
                channel => $channel_name,
                # payload is: {id, data:{event,patch}}
                %$payload,
            };
            $_->send({text => $json_msg}) foreach @$channel_users;
        }),
        op_share(),
    );
}

1;