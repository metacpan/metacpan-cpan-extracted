use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# bulk_inserter response-surfacing: ->summary returns cumulative
# X-ClickHouse-Summary stats across batches; ->last_response is the
# raw HTTP::Tiny response from the most recent flush (with the parsed
# 'ch' slot attached). We unit-test by stubbing the inserter's http
# attribute with a captive object that returns a canned response.

# Capture & response shape mirrors HTTP::Tiny's: { success, status,
# content, headers }. Headers must be the lower-cased form HTTP::Tiny
# emits.
{
    package FakeHttp;
    sub new {
        my ($class, @resps) = @_;
        bless { responses => [@resps], calls => [] }, $class;
    }
    sub post {
        my ($self, $url, $req) = @_;
        push @{ $self->{calls} }, { url => $url, req => $req };
        # Return next canned response (clone so the caller can mutate it).
        return { %{ shift @{ $self->{responses} } } };
    }
}

my $fake = FakeHttp->new(
    {   success => 1,
        status  => 200,
        content => '',
        headers => {
            'x-clickhouse-query-id' => 'q1',
            'x-clickhouse-summary'  => '{"read_rows":"0","written_rows":"3","written_bytes":"120","elapsed_ns":"500000"}',
        },
    },
    {   success => 1,
        status  => 200,
        content => '',
        headers => {
            'x-clickhouse-query-id' => 'q2',
            'x-clickhouse-summary'  => '{"read_rows":"0","written_rows":"2","written_bytes":"80","elapsed_ns":"400000"}',
        },
    },
);

my $bi = ClickHouse::Encoder->bulk_inserter(
    table   => 'events',
    columns => [['id', 'UInt64'], ['v', 'Int32']],
    batch_size => 1000,
);
$bi->{http} = $fake;  # swap transport

$bi->push([1, 10]);
$bi->push([2, 20]);
$bi->push([3, 30]);
$bi->flush;

is_deeply($bi->summary,
          { read_rows => 0, written_rows => 3, written_bytes => 120,
            elapsed_ns => 500000 },
          'summary: rolls up from first flush');
is($bi->last_response->{ch}{'query-id'}, 'q1',
   'last_response: query-id surfaced on first flush');

$bi->push([4, 40]);
$bi->push([5, 50]);
$bi->flush;

is_deeply($bi->summary,
          { read_rows => 0, written_rows => 5, written_bytes => 200,
            elapsed_ns => 900000 },
          'summary: accumulates across flushes');
is($bi->last_response->{ch}{'query-id'}, 'q2',
   'last_response: refreshes to most-recent flush');

is(scalar @{ $fake->{calls} }, 2, 'fake transport: 2 POSTs issued');

done_testing();
