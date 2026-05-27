use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# Lock the wire shape of dedup_token plumbing without needing a live
# server: the only place this token can affect behavior is by being
# stamped on the URL of the POST, so we capture the URL via the
# request-side helpers that all HTTP entry points share.

my ($url) = ClickHouse::Encoder::_http_url_headers(
    'insert into t format native',
    dedup_token => 'batch-42',
);
like($url, qr/insert_deduplication_token=batch-42/,
     '_http_url_headers: dedup_token appended once');

# A token must be URI-encoded so callers can pass an opaque blob
# (uuid, sha256, payload checksum) without risk of breaking the URL.
($url) = ClickHouse::Encoder::_http_url_headers(
    'insert into t format native',
    dedup_token => '2026-05-19T12:00:00+00:00 # comment & extra',
);
like($url, qr/insert_deduplication_token=2026-05-19T12%3A00%3A00%2B00%3A00%20%23%20comment%20%26%20extra/,
     'dedup_token: URI-encoded so embedded "&"/"=" cannot smuggle params');

# _build_insert_endpoint feeds %args verbatim to _http_url_headers, so
# dedup_token is honored on both insert_http and bulk_inserter paths.
my ($iurl) = ClickHouse::Encoder::_build_insert_endpoint(
    'my_table', 'raw',
    dedup_token => 'idem-key',
);
like($iurl, qr/insert_deduplication_token=idem-key/,
     '_build_insert_endpoint: dedup_token propagated');

# When dedup_token is undef, the param is omitted entirely - CH
# treats absence as "every batch is a fresh insert" which is the
# safe default.
my ($url_clean) = ClickHouse::Encoder::_http_url_headers(
    'insert into t format native',
);
unlike($url_clean, qr/insert_deduplication_token/,
       'dedup_token: omitted when not provided');

done_testing();
