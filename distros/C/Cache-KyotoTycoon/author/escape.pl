use strict;
use warnings;
use Benchmark ':all';

use URI::Escape qw/uri_escape uri_unescape/;
use MIME::QuotedPrint qw/encode_qp decode_qp/;
use MIME::Base64 qw/encode_base64 decode_base64/;

my $x = "\x015\x000hgoehgoeふがふが" x 1_000_000;

cmpthese(
    -1 => {
        'u' => sub { uri_escape($x) },
        'q' => sub { encode_qp($x) },
        'b' => sub { encode_base64($x) },
    }
);
