package BoardStreams::Error::DB::Duplicate;

use Moo;
extends 'BoardStreams::Error::DB';

use experimental 'signatures';

our $VERSION = "v0.0.30";

has '+code' => (
    default => 'duplicate_key',
);

has '+data' => (
    required => 1,
    isa      => sub ($data) {
        die "data does not contain a 'key_name' field that has length" if !eval {length $data->{key_name}};
    },
);

1;
