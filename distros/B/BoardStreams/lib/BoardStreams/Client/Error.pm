use v5.44;
use experimental 'class';

# Why a join was refused or a request failed: what the promises of
# BoardStreams::Client reject with.
class BoardStreams::Client::Error {
    our $VERSION = "v0.0.60";

    use overload '""' => sub { $_[0]->message }, fallback => 1;

    field $reason :param :reader;
    field $data :param :reader = undef;

    method message { "BoardStreams: $reason" }
}

1;
