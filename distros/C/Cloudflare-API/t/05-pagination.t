use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json);
use Cloudflare::API;

my @request;
my $api_or=Cloudflare::API->new(
    token => 'test-token', account_id => 'acct',
    transport => sub {
        my ($method, $url)=@_;
        push(@request, [@_]);
        my $body_hr;
        if ($url=~m{/zones\?page=1&per_page=2\z}) {
            $body_hr={ success => JSON::PP::true,
                result => [{id => 'one'}, {id => 'two'}],
                result_info => {page => 1, per_page => 2, total_pages => 2} };
        }
        elsif ($url=~m{/zones\?page=2&per_page=2\z}) {
            $body_hr={ success => JSON::PP::true,
                result => [{id => 'three'}],
                result_info => {page => 2, per_page => 2, total_pages => 2} };
        }
        elsif ($url=~m{/r2/buckets\?per_page=1\z}) {
            $body_hr={ success => JSON::PP::true,
                result => {buckets => [{name => 'first'}]},
                result_info => {cursor => 'next', per_page => 1} };
        }
        elsif ($url=~m{/r2/buckets\?cursor=next&per_page=1\z}) {
            $body_hr={ success => JSON::PP::true,
                result => {buckets => [{name => 'second'}]},
                result_info => {per_page => 1} };
        }
        elsif ($url=~m{/workers/scripts/test/versions\?page=1\z}) {
            $body_hr={ success => JSON::PP::true,
                result => {items => [{id => 'version'}]} };
        }
        elsif ($url=~m{/workers/scripts/test/versions\?page=2\z}) {
            $body_hr={ success => JSON::PP::true, result => {items => []} };
        }
        elsif ($url=~m{/workers/scripts\z}) {
            $body_hr={ success => JSON::PP::true, result => [{id => 'worker'}] };
        }
        elsif ($url=~m{/failure\?page=1\z}) {
            $body_hr={ success => JSON::PP::false,
                errors => [{code => 1000, message => 'failed'}] };
        }
        else {
            die "unexpected test request: $method $url\n";
        }
        return {status => 200, headers => {'content-type' => 'application/json'},
            content => encode_json($body_hr)};
    }
);

my $request_no=@request;
my $page_or=$api_or->zones()->list_page(per_page => 2);
isa_ok($page_or, 'HTTP::API::Core::Pagination');
is(scalar(@request), $request_no, 'list_page is lazy');
is_deeply(scalar($page_or->all()), [{id => 'one'}, {id => 'two'}, {id => 'three'}],
    'page-number pagination returns every item');

is_deeply($api_or->r2()->list_buckets(per_page => 1),
    [{name => 'first'}, {name => 'second'}],
    'cursor pagination extracts and combines nested bucket results');

is_deeply($api_or->workers()->list_versions('test'), [{id => 'version'}],
    'nested items paginate until an empty page when no result_info is supplied');

$request_no=@request;
is_deeply($api_or->workers()->list_scripts(), [{id => 'worker'}],
    'single-page list returns its complete result');
is(scalar(@request), $request_no+1, 'single-page endpoint is requested once');

my $response_hr=$api_or->zones()->list_page_response(page => 2, per_page => 2);
is_deeply($response_hr->{'result'}, [{id => 'three'}],
    'list_page_response returns one decoded Cloudflare response');

my $response_or=$api_or->response('GET', '/workers/scripts');
isa_ok($response_or, 'HTTP::API::Core::Response');

my $ok=eval { $api_or->zones()->list(full_response => 1); 1 };
ok(!$ok, 'full_response is rejected by list methods');
like($@, qr/use the page response method/, 'list error names the page response method');

my $failure_or=$api_or->pagination('/failure', mode => 'page', items => 'result');
$ok=eval { $failure_or->next(); 1 };
ok(!$ok, 'paginator checks Cloudflare success');
isa_ok($@, 'Cloudflare::API::Error');

done_testing();
