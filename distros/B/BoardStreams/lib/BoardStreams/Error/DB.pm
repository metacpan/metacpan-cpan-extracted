package BoardStreams::Error::DB;

use Moo;
extends 'BoardStreams::Error';

our $VERSION = "v0.0.34";

has '+code' => (
    default => 'db_error',
);

1;
