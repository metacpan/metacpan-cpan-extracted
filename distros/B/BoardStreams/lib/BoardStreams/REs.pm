package BoardStreams::REs;

use Mojo::Base -strict;

our $VERSION = "v0.0.36";

our $STREAM_SEGMENT = qr/^[a-z0-9_-]+\z/;
our $STREAM_NAME = qr/^([a-z0-9_-]+\:)*[a-z0-9_-]+\z/;
our $ANY_STREAM_NAME = qr/^\!?([a-z0-9_-]+\:)*[a-z0-9_-]+\z/;

1;
