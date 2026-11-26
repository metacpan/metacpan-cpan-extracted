use v5.44;
use experimental 'class';

# What join, action and request handlers receive as their first argument.
class BoardStreams::Context {
    our $VERSION = "v0.0.56";

    use BoardStreams::Rejection;

    field $hub :param :reader;
    field $c :param :reader;          # the WebSocket's Mojolicious controller
    field $channel :param :reader;
    field $connection :param = undef;
    field $user :param :reader = undef;    # what the plugin's "identify" option returned for this browser
    field $request_id :param = undef;
    field $seq :reader = 0;           # highest sequence number this handler produced
    field $guarded = 0;

    # Like $hub->update on this handler's channel. The first update made
    # while handling an action or request is tied to its unique id, so a
    # resent copy of the same message cannot apply it twice.
    method update ($cb) {
        my @guard = defined $request_id && !$guarded++ ? (request_id => $request_id) : ();
        return $hub->update($channel, $cb, @guard)->then(sub ($new_seq) {
            $seq = $new_seq if $new_seq > $seq;
            return $new_seq;
        });
    }

    method emit ($name, $payload = undef) {
        return $self->update(sub ($u) { $u->emit($name, $payload) });
    }

    # Ends this browser's membership of the channel, as $hub->kick does
    # for all of a user's browsers.
    method kick ($reason = 'kicked', $data = undef) {
        return $hub->kick_connection($connection, $channel, $reason, $data);
    }

    # Closes this browser's connection for good, as $hub->disconnect does
    # for all of a user's browsers.
    method disconnect ($reason = 'disconnected', $data = undef) {
        return $hub->disconnect_connection($connection, $reason, $data);
    }

    method reject ($reason, $data = undef) {
        die BoardStreams::Rejection->new(reason => $reason, data => $data);
    }
}

1;
