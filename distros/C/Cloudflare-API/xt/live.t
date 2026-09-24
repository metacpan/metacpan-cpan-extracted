use strict;
use warnings;
use Test::More;
use Cloudflare::API;

if (!$ENV{'CLOUDFLARE_API_LIVE_TEST'} || !$ENV{'CLOUDFLARE_API_TOKEN'} ||
    !$ENV{'CLOUDFLARE_ACCOUNT_ID'}) {
    plan(skip_all => 'set CLOUDFLARE_API_LIVE_TEST, CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID');
}

my $api_or=Cloudflare::API->new();
my $suffix=sprintf('%x-%x-%x', time(), $$, int(rand(0x7fffffff)));
my $name='cfapi-test-'.$suffix;
my %created;

my $r2_result=eval { $api_or->r2()->create_bucket({ name => $name }) };
ok($r2_result, 'create disposable R2 bucket') || diag($@);
$created{'r2'}=$name if $r2_result;

my $kv_result=eval { $api_or->kv()->create_namespace({ title => $name }) };
ok($kv_result && $kv_result->{'id'}, 'create disposable KV namespace') || diag($@);
$created{'kv'}=$kv_result->{'id'} if $kv_result && $kv_result->{'id'};

my $d1_result=eval { $api_or->d1()->create_database({ name => $name }) };
ok($d1_result && $d1_result->{'uuid'}, 'create disposable D1 database') || diag($@);
$created{'d1'}=$d1_result->{'uuid'} if $d1_result && $d1_result->{'uuid'};

my $queue_result=eval { $api_or->queues()->create_queue({ queue_name => $name }) };
ok($queue_result && $queue_result->{'queue_id'}, 'create disposable queue') || diag($@);
$created{'queue'}=$queue_result->{'queue_id'}
    if $queue_result && $queue_result->{'queue_id'};

my $existing_ar=eval { $api_or->workers()->list_scripts() };
my $worker_result;
if (ref($existing_ar) eq 'ARRAY' &&
    !grep { ($_->{'id'} || '') eq $name } @$existing_ar) {
    $worker_result=eval {
        $api_or->workers()->upload_script($name,
            metadata => { main_module => 'worker.mjs', compatibility_date => '2026-09-22' },
            files => [{ name => 'worker.mjs', content =>
                'export default { fetch() { return new Response("ok") } };' }]
        );
    };
}
else {
    diag($@ || 'Worker list unavailable or generated name already exists');
}
ok($worker_result, 'upload disposable Worker') || diag($@);
$created{'worker'}=$name if $worker_result;

foreach my $resource (qw(worker queue d1 kv r2)) {
    next unless $created{$resource};
    my $ok=eval {
        if ($resource eq 'worker') { $api_or->workers()->delete_script($created{$resource}); }
        elsif ($resource eq 'queue') { $api_or->queues()->delete_queue($created{$resource}); }
        elsif ($resource eq 'd1') { $api_or->d1()->delete_database($created{$resource}); }
        elsif ($resource eq 'kv') { $api_or->kv()->delete_namespace($created{$resource}); }
        else { $api_or->r2()->delete_bucket($created{$resource}); }
        1;
    };
    ok($ok, "remove disposable $resource") || diag("$created{$resource}: $@");
}

done_testing();
