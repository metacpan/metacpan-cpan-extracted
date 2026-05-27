use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# Exercise the private _http_url_headers / _decorate_response helpers
# directly: they're the glue between Perl-side option keys and the wire
# request that every HTTP entry point composes. Spelling drift here is
# silent (the server ignores unknown params) so we lock URL composition
# in unit tests rather than waiting for a live-CH integration test to
# notice.

my ($url, $hdr) = ClickHouse::Encoder::_http_url_headers(
    'select 1',
    host     => 'ch.example',
    port     => 8443,
    scheme   => 'https',
    database => 'analytics',
    user     => 'reader',
    password => 'secret',
);
like($url, qr{^https://ch\.example:8443/}, 'https scheme honored');
like($url, qr/database=analytics/,        'database parameter');
like($url, qr/query=select%201/,          'query is URI-encoded');
is($hdr->{'X-ClickHouse-User'}, 'reader', 'user header');
is($hdr->{'X-ClickHouse-Key'},  'secret', 'password header');

# settings (hashref) -> ordered url params.
($url) = ClickHouse::Encoder::_http_url_headers(
    'select 1',
    settings => {
        max_execution_time => 30,
        max_memory_usage   => '10000000000',
    },
);
like($url, qr/max_execution_time=30/,                'settings: int passthrough');
like($url, qr/max_memory_usage=10000000000/,         'settings: large int as string');

# dedup_token -> insert_deduplication_token.
($url) = ClickHouse::Encoder::_http_url_headers(
    'insert into t format native',
    dedup_token => 'batch-2026-05-19-001',
);
like($url, qr/insert_deduplication_token=batch-2026-05-19-001/,
     'dedup_token: token under the documented param name');

# Empty-SQL form: select_blocks POSTs the SQL as body, so the URL must
# not contain '&query=' when sql is empty.
($url) = ClickHouse::Encoder::_http_url_headers('');
unlike($url, qr/&?query=/, 'empty SQL omits query param entirely');

# Special chars: settings keys/values are URI-encoded so injection of
# raw '&' or '=' can't smuggle additional params.
($url) = ClickHouse::Encoder::_http_url_headers(
    'select 1',
    settings => { 'foo&bar' => 'a=b&c=d' },
);
like($url, qr/foo%26bar=a%3Db%26c%3Dd/,
     'settings: key+value URI-escaped (no smuggling)');

# _decorate_response: surfaces query-id and parses the summary header.
{
    my $resp = {
        success => 1,
        status  => 200,
        headers => {
            'x-clickhouse-query-id' => 'qid-123',
            'x-clickhouse-server'   => '54429',
            'x-clickhouse-summary'  => '{"read_rows":"42","written_rows":"0","elapsed_ns":"1500"}',
        },
    };
    ClickHouse::Encoder::_decorate_response($resp);
    is($resp->{ch}{'query-id'},          'qid-123', 'query-id surfaced');
    is($resp->{ch}{server},              '54429',   'server revision surfaced');
    is($resp->{ch}{summary}{read_rows},  42,        'summary: read_rows parsed');
    is($resp->{ch}{summary}{elapsed_ns}, 1500,      'summary: elapsed_ns parsed');
}

# A response without any X-ClickHouse-* headers must not add a ch slot.
{
    my $resp = { success => 1, status => 200, headers => {} };
    ClickHouse::Encoder::_decorate_response($resp);
    ok(!exists $resp->{ch}, 'no ch slot when no CH headers present');
}

# X-ClickHouse-Progress repeats during a streaming query;
# HTTP::Tiny collapses repeated headers into an arrayref. The last
# snapshot is the final one - the most complete - so _decorate_response
# parses that one as $resp->{ch}{progress}.
{
    my $resp = {
        success => 1, status => 200,
        headers => {
            'x-clickhouse-progress' => [
                '{"read_rows":"100","total_rows_to_read":"1000"}',
                '{"read_rows":"500","total_rows_to_read":"1000"}',
                '{"read_rows":"1000","total_rows_to_read":"1000"}',
            ],
        },
    };
    ClickHouse::Encoder::_decorate_response($resp);
    is($resp->{ch}{progress}{read_rows}, 1000,
       'progress: arrayref of repeated headers -> last snapshot parsed');
    is($resp->{ch}{progress}{total_rows_to_read}, 1000,
       'progress: total_rows_to_read from the final snapshot');
}

# Single-string progress header also works (server sent only one).
{
    my $resp = {
        success => 1, status => 200,
        headers => {
            'x-clickhouse-progress' => '{"read_rows":"7"}',
        },
    };
    ClickHouse::Encoder::_decorate_response($resp);
    is($resp->{ch}{progress}{read_rows}, 7,
       'progress: single-string header is parsed verbatim');
}

# Endpoint guard: scheme/host/port are interpolated into URLs, so they
# must be validated before any HTTP request is built. Reject anything
# that could smuggle path or query material into the URL.
for my $bad (
    [ { scheme => 'file' },           qr/scheme.+http/,   'scheme: file rejected' ],
    [ { scheme => 'gopher' },         qr/scheme.+http/,   'scheme: gopher rejected' ],
    [ { host => 'a/b' },              qr/host/,           'host: slash rejected' ],
    [ { host => 'a:b' },              qr/host/,           'host: colon rejected' ],
    [ { host => 'a?b' },              qr/host/,           'host: query rejected' ],
    [ { host => '' },                 qr/host/,           'host: empty rejected' ],
    [ { port => 'abc' },              qr/port/,           'port: non-numeric rejected' ],
    [ { port => 0 },                  qr/port/,           'port: zero rejected' ],
    [ { port => -1 },                 qr/port/,           'port: negative rejected' ],
    [ { port => 70000 },              qr/port/,           'port: > 65535 rejected' ],
) {
    my ($opts, $re, $name) = @$bad;
    local $@;
    eval { ClickHouse::Encoder::_http_url_headers('select 1', %$opts) };
    like($@, $re, $name);
}

# Valid cases: http + https, default localhost:8123, integer string port.
for my $good (
    [ {},                            'default localhost:8123 accepted' ],
    [ { scheme => 'https' },         'https accepted' ],
    [ { port => '8443' },            'port as string-of-digits accepted' ],
    [ { host => '127.0.0.1' },       'IPv4 literal accepted' ],
    [ { host => 'ch.example.com' },  'hostname accepted' ],
) {
    my ($opts, $name) = @$good;
    eval { ClickHouse::Encoder::_http_url_headers('select 1', %$opts) };
    is($@, '', $name);
}

done_testing();
