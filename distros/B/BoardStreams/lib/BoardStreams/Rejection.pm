use v5.44;
use experimental 'class';

# Thrown by $ctx->reject to refuse a join or fail a request with a reason
# that is reported to the browser.
class BoardStreams::Rejection {
    our $VERSION = "v0.0.56";

    field $reason :param :reader;
    field $data :param :reader = undef;
}

1;
