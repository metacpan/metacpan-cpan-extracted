use v5.44;
use experimental 'class';

# Passed to the callback of BoardStreams::Hub->update. The callback changes
# the channel's state through it and queues events; both are committed
# together under one sequence number.
class BoardStreams::Update {
    our $VERSION = "v0.0.56";

    field $state :param;
    field @events;

    # With no argument returns the state (change it in place);
    # with an argument replaces it.
    method state (@new) {
        $state = $new[0] if @new;
        return $state;
    }

    method emit ($name, $payload = undef) {
        push @events, { name => $name, payload => $payload };
        return $self;
    }

    method events { @events }
}

1;
