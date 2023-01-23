package BoardStreams::Error::DB;

use Moo;
extends 'BoardStreams::Error';

our $VERSION = "v0.0.31";

has '+code' => (
    default => 'db_error',
);

1;
