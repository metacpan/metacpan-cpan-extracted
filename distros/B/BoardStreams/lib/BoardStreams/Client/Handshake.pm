use v5.44;
use experimental 'class';

# The answer to one WebSocket handshake, as BoardStreams::Client shows it
# to the on_handshake callback. See the POD of BoardStreams::Client.
class BoardStreams::Client::Handshake {
    our $VERSION = "v0.0.60";

    field $code :param :reader;        # the HTTP status of the answer; 101 when the server accepted
    field $accepted :param :reader;    # true if the answer opened a WebSocket connection
    field $headers :param :reader;     # the answer's headers, a Mojo::Headers object
    field $body :param :reader;        # the answer's body: what a refusal says, empty otherwise
    field $sent :param :reader;        # the headers that the client's headers option added to the request

    # One header of the answer, whatever the case of its name.
    method header ($name) { $headers->header($name) }
}

1;
