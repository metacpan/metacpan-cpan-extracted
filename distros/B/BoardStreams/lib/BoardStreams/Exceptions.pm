package BoardStreams::Exceptions;

use Mojo::Base -strict, -signatures;

use BoardStreams::Error::DB;
use BoardStreams::Error::DB::Duplicate;
use BoardStreams::Error::JSONRPC;

use Exporter 'import';
our @EXPORT_OK = qw/ db_error db_duplicate_error jsonrpc_error /;

our $VERSION = "v0.0.31";

sub db_error {
    my ($code, $data) = @_;
    BoardStreams::Error::DB->new(
        defined $code ? (code => $code) : (),
        scalar(@_) >= 2 ? (data => $data) : (),
    );
}

sub db_duplicate_error ($key_name = undef) {
    BoardStreams::Error::DB::Duplicate->new(
        data => {
            key_name => $key_name,
        },
    );
}

sub jsonrpc_error {
    my ($code_num, $message, $data) = @_;
    BoardStreams::Error::JSONRPC->new(
        code_num => $code_num,
        message  => $message,
        scalar(@_) >= 3 ? (data => $data) : (),
    );
}

1;
