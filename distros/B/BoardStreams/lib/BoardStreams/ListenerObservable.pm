package BoardStreams::ListenerObservable;

use Mojo::Base -strict, -signatures;

use BoardStreams::Registry;

use Mojo::JSON 'decode_json', 'encode_json';
use RxPerl::Mojo ':all';

use Exporter 'import';
our @EXPORT_OK = qw/ get_listener_observable /;

our $VERSION = "v0.0.23";

my %listener_observables;

sub get_listener_observable ($c, $channel_name, $bs_prefix) {
    return $listener_observables{$channel_name} //= rx_observable->new(sub ($subscriber) {
        my $accumulated;
        my $cb = $c->$bs_prefix->pubsub->listen($channel_name => sub ($pubsub, $payload) {
            $payload =~ s/^\:([^:]+)\: //;
            if (defined(my $prefix = $1)) {
                (my $event_id, $prefix) = $prefix =~ /^(\d+)\s(\S+)\z/;
                if ($prefix eq '0') {
                    $accumulated = $payload;
                } elsif ($prefix =~ /^\d+\z/) {
                    $accumulated .= $payload;
                } elsif ($prefix eq 'end') {
                    $accumulated .= $payload;
                    # next accepts character hashrefs
                    $subscriber->next(decode_json $accumulated);
                    undef $accumulated;
                }
            } else {
                # next accepts character hashrefs
                $subscriber->next(decode_json $payload);
                undef $accumulated;
            }
        });

        return sub {
            $c->$bs_prefix->pubsub->unlisten($channel_name => $cb);
            delete $listener_observables{$channel_name};
        };
    })->pipe(
        op_tap(sub ($payload) {
            my $channel_users = BoardStreams::Registry->query($channel_name);
            my $bytes = encode_json {
                type    => 'event_patch',
                channel => $channel_name,
                # payload is: {id, data:{event,patch}}
                %$payload,
            };
            foreach my $channel_user (@$channel_users) {
                $channel_user->$bs_prefix->send($bytes, "event_patch-$channel_name", binary => 1);
            }
        }),
        op_share(),
    );
}

1;