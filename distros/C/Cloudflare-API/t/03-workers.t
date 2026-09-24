use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json decode_json);
use File::Temp qw(tempfile tempdir);
use File::Path qw(make_path);
use MIME::Base64 qw(encode_base64);
use Digest::SHA qw(sha256_hex);
use Cloudflare::API;

my @request;
my $api_or=Cloudflare::API->new(
    token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@request, [@_]);
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true, result => { id => 'worker' }
        }) };
    }
);

my ($file_fh, $file_fn)=tempfile();
binmode($file_fh);
print($file_fh "export default { fetch() { return new Response('ok') } };\n");
close($file_fh);

is_deeply($api_or->workers()->upload_script('test-worker',
    metadata => { main_module => 'worker.mjs', compatibility_date => '2026-09-22' },
    files => [{ name => 'worker.mjs', path => $file_fn }]),
    { id => 'worker' }, 'Worker upload returns result');
is($request[-1][0], 'PUT', 'Worker upload uses PUT');
like($request[-1][1], qr{/workers/scripts/test-worker\z}, 'Worker upload path');
like($request[-1][2]{'headers'}{'Content-Type'}, qr{^multipart/form-data; boundary=},
    'multipart content type contains boundary');
like($request[-1][2]{'content'}, qr/name="metadata"/, 'metadata part present');
like($request[-1][2]{'content'}, qr/"main_module":"worker\.mjs"/, 'metadata JSON present');
like($request[-1][2]{'content'}, qr/name="worker\.mjs"; filename="worker\.mjs"/,
    'module part present');
like($request[-1][2]{'content'}, qr/export default/, 'module content present');

$api_or->workers()->upload_script('nested-worker',
    metadata => { main_module => 'src/worker.mjs' },
    files => [{ name => 'src/worker.mjs', content => 'export default {};' }]);
like($request[-1][2]{'content'}, qr/name="src\/worker\.mjs"/, 'nested module name accepted');

is_deeply($api_or->workers()->upload_version('test-worker',
    metadata => { main_module => 'worker.mjs' },
    files => [{ name => 'worker.mjs', content => 'export default {};' }],
    bindings_inherit => 'strict'), { id => 'worker' }, 'version upload returns result');
is($request[-1][0], 'POST', 'version upload uses POST');
like($request[-1][1], qr{/workers/scripts/test-worker/versions\?bindings_inherit=strict\z},
    'version upload path and strict binding inheritance query');
like($request[-1][2]{'content'}, qr/name="worker\.mjs"/, 'version uses multipart file');
$api_or->workers()->list_versions('test-worker', page => 2);
is($request[-1][0], 'GET', 'list versions uses GET');
like($request[-1][1], qr{/workers/scripts/test-worker/versions\?page=2\z},
    'version list query');
$api_or->workers()->get_version('test-worker', 'version');
like($request[-1][1], qr{/workers/scripts/test-worker/versions/version\z},
    'get version path');

$api_or->workers()->create_deployment('test-worker', {
    strategy => 'percentage', versions => [{ percentage => 100, version_id => 'version' }]
});
like($request[-1][1], qr{/workers/scripts/test-worker/deployments\z}, 'deployment path');
$api_or->workers()->add_secret('test-worker', {
    name => 'API_KEY', text => 'redacted', type => 'secret_text'
});
like($request[-1][1], qr{/workers/scripts/test-worker/secrets\z}, 'secret path');
$api_or->workers()->list_secrets('test-worker');
is($request[-1][0], 'GET', 'list secrets uses GET');
$api_or->workers()->delete_secret('test-worker', 'API_KEY');
like($request[-1][1], qr{/workers/scripts/test-worker/secrets/API_KEY\z}, 'delete secret path');
$api_or->workers()->get_deployment('test-worker', 'deployment');
like($request[-1][1], qr{/workers/scripts/test-worker/deployments/deployment\z},
    'get deployment path');
$api_or->workers()->set_subdomain('test-worker', { enabled => JSON::PP::true });
like($request[-1][1], qr{/workers/scripts/test-worker/subdomain\z}, 'subdomain path');
$api_or->workers()->create_route('zone', { pattern => 'example.com/*', script => 'test-worker' });
like($request[-1][1], qr{/zones/zone/workers/routes\z}, 'route path');
$api_or->workers()->update_route('zone', 'route', { pattern => 'example.org/*' });
is($request[-1][0], 'PUT', 'route update uses PUT');

my @inspect_request;
my $inspect_api_or=Cloudflare::API->new(
    token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@inspect_request, [@_]);
        my $path=$_[1];
        my $result;
        if ($path=~m{/workers/scripts-search}) {
            $result=[{ id => 'tag-alpha', script_name => 'alpha' }];
        }
        elsif ($path=~m{/workers/scripts/alpha/script-settings}) {
            $result={ tags => ['production'], logpush => JSON::PP::false };
        }
        elsif ($path=~m{/workers/scripts/alpha/settings}) {
            $result={ bindings => [{ name => 'DATA', type => 'kv_namespace' }] };
        }
        else {
            $result=[
                { id => 'alpha', tag => 'tag-alpha', etag => 'etag-alpha' },
                { id => 'beta', tag => 'tag-beta', etag => 'etag-shared' },
                { id => 'gamma', tag => 'tag-gamma', etag => 'etag-shared' }
            ];
        }
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true, result => $result
        }) };
    }
);
my $inspect_workers_or=$inspect_api_or->workers();
is_deeply($inspect_workers_or->search_scripts(name => 'alp'),
    [{ id => 'tag-alpha', script_name => 'alpha' }], 'Worker search returns matches');
like($inspect_request[-1][1], qr{/workers/scripts-search\?name=alp\z},
    'Worker search uses discovery endpoint');
is_deeply($inspect_workers_or->get_settings('alpha'),
    { bindings => [{ name => 'DATA', type => 'kv_namespace' }] },
    'Worker combined settings returned');
like($inspect_request[-1][1], qr{/workers/scripts/alpha/settings\z},
    'Worker combined settings path');
is_deeply($inspect_workers_or->get_script_settings('alpha'),
    { tags => ['production'], logpush => JSON::PP::false },
    'Worker script settings returned');
like($inspect_request[-1][1], qr{/workers/scripts/alpha/script-settings\z},
    'Worker script settings path');

my $inspect_request_no=@inspect_request;
my $inspection_hr=$inspect_workers_or->inspect_script(name => 'alpha');
is(@inspect_request-$inspect_request_no, 3, 'inspection makes three read requests');
is($inspection_hr->{'script'}{'tag'}, 'tag-alpha', 'inspection resolves script name');
is_deeply($inspection_hr->{'settings'}{'bindings'},
    [{ name => 'DATA', type => 'kv_namespace' }], 'inspection includes combined settings');
is_deeply($inspection_hr->{'script_settings'}{'tags'}, ['production'],
    'inspection includes script settings');
is($inspect_workers_or->inspect_script(tag => 'tag-alpha')->{'script'}{'id'},
    'alpha', 'inspection resolves immutable tag');
is($inspect_workers_or->inspect_script(etag => 'etag-alpha')->{'script'}{'id'},
    'alpha', 'inspection resolves etag');

my $inspect_error=eval { $inspect_workers_or->inspect_script(); 1 };
ok(!$inspect_error&&$@=~/exactly one/, 'inspection requires a selector');
$inspect_error=eval { $inspect_workers_or->inspect_script('name'); 1 };
ok(!$inspect_error&&$@=~/name\/value pairs/, 'inspection rejects an odd selector list');
$inspect_error=eval { $inspect_workers_or->inspect_script(name => 'alpha', tag => 'tag-alpha'); 1 };
ok(!$inspect_error&&$@=~/exactly one/, 'inspection rejects multiple selectors');
$inspect_error=eval { $inspect_workers_or->inspect_script(id => 'alpha'); 1 };
ok(!$inspect_error&&$@=~/unknown inspect selector/, 'inspection rejects unknown selector');
$inspect_error=eval { $inspect_workers_or->inspect_script(name => 'missing'); 1 };
ok(!$inspect_error&&$@=~/no Worker script matches name 'missing'/,
    'inspection reports no match');
$inspect_error=eval { $inspect_workers_or->inspect_script(etag => 'etag-shared'); 1 };
ok(!$inspect_error&&$@=~/multiple Worker scripts match etag 'etag-shared'/,
    'inspection rejects ambiguous etag');
$inspect_error=eval { $inspect_workers_or->inspect_script(name => 'alpha', full_response => 1); 1 };
ok(!$inspect_error&&$@=~/full_response is unavailable/,
    'inspection rejects full response mode');

eval { $api_or->workers()->upload_script('worker',
    metadata => { main_module => 'missing.mjs' },
    files => [{ name => 'worker.mjs', content => 'x' }]) };
like($@, qr/main_module must match/, 'upload rejects mismatched main module');

eval { $api_or->workers()->upload_script('worker',
    metadata => { main_module => 'worker.mjs' },
    files => [{ name => "worker.mjs\r\nX: evil", content => 'x' }]) };
like($@, qr/invalid file name/, 'upload rejects multipart header injection');

eval { $api_or->workers()->upload_version('worker',
    metadata => { main_module => 'worker.mjs' },
    files => [{ name => 'worker.mjs', content => 'x' }], bindings_inherit => 'loose') };
like($@, qr/bindings_inherit must be strict/, 'invalid binding inheritance rejected');

my @asset_request;
my $hash=substr(sha256_hex(encode_base64('<h1>Hi</h1>', '').'html'), 0, 32);
my $asset_api_or=Cloudflare::API->new(token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@asset_request, [@_]);
        my $result=$_[1]=~/assets-upload-session/ ?
            { jwt => 'upload-token', buckets => [[$hash]] } : { jwt => 'completion-token' };
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true, result => $result }) };
    });
my $asset_hr=$asset_api_or->workers()->upload_assets('test-worker',
    { '/index.html' => '<h1>Hi</h1>' });
is($asset_hr->{'jwt'}, 'completion-token', 'asset upload returns completion token');
is($asset_hr->{'manifest'}{'/index.html'}{'hash'}, $hash, 'asset hash matches Cloudflare scheme');
like($asset_request[0][1], qr{/assets-upload-session\z}, 'asset session path');
like($asset_request[1][1], qr{/workers/assets/upload\?base64=true\z}, 'asset upload path');
is($asset_request[1][2]{'headers'}{'Authorization'}, 'Bearer upload-token',
    'asset upload uses session token');
like($asset_request[1][2]{'content'}, qr/name="$hash"/, 'asset upload uses hash field');
like($asset_request[1][2]{'content'}, qr/Content-Type: text\/html\r\n/, 'HTML MIME type sent');

my ($image_fh, $image_fn)=tempfile();
binmode($image_fh);
print($image_fh "\x89PNG\r\n\x1a\n");
close($image_fh);
my @mixed_request;
my $mixed_api_or=Cloudflare::API->new(token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@mixed_request, [@_]);
        my $result;
        if ($_[1]=~/assets-upload-session/) {
            my $manifest_hr=decode_json($_[2]{'content'})->{'manifest'};
            $result={ jwt => 'upload-token',
                buckets => [[map { $manifest_hr->{$_}{'hash'} } sort(keys(%$manifest_hr))]] };
        }
        else { $result={ jwt => 'completion-token' }; }
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true, result => $result }) };
    });
my $mixed_hr=$mixed_api_or->workers()->upload_assets('test-worker', {
    '/index.html' => '<html>ok</html>',
    '/style.css' => 'body { color: red }',
    '/app.js' => 'document.body.dataset.ok = 1;',
    '/pixel.png' => { path => $image_fn },
    '/logo.svg' => '<svg xmlns="http://www.w3.org/2000/svg"/>',
    '/photo.jxl' => { path => $image_fn, content_type => 'image/jxl' }
});
is(scalar(keys(%{$mixed_hr->{'manifest'}})), 6, 'mixed asset manifest includes every file');
my $mixed_body=$mixed_request[1][2]{'content'};
foreach my $type (qw(text/html text/css text/javascript image/png image/svg+xml image/jxl)) {
    like($mixed_body, qr/Content-Type: \Q$type\E\r\n/, "$type supplied on asset part");
}
eval { $mixed_api_or->workers()->upload_assets('test-worker', {
    '/bad.html' => { path => $image_fn, content_type => "text/html\r\nX-Evil: yes" }
}) };
like($@, qr/invalid asset content type/, 'asset content type rejects header injection');
is(scalar(@mixed_request), 2, 'invalid type rejected before upload session');

my $asset_dir=tempdir(CLEANUP => 1);
make_path("$asset_dir/css", "$asset_dir/.well-known");
foreach my $file_hr (
    { path => "$asset_dir/index.html", content => '<h1>Directory</h1>' },
    { path => "$asset_dir/css/site.css", content => 'body {}' },
    { path => "$asset_dir/.well-known/info.txt", content => 'hello' }
) {
    open(my $asset_fh, '>', $file_hr->{'path'}) || die $!;
    print($asset_fh $file_hr->{'content'});
    close($asset_fh) || die $!;
}
my @bulk_request;
my $bulk_api_or=Cloudflare::API->new(token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@bulk_request, [@_]);
        my $result;
        if ($_[1]=~/assets-upload-session/) {
            my $manifest_hr=decode_json($_[2]{'content'})->{'manifest'};
            $result={ jwt => 'upload-token',
                buckets => [[map { $manifest_hr->{$_}{'hash'} } sort(keys(%$manifest_hr))]] };
        }
        else { $result={ jwt => 'completion-token' }; }
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true, result => $result }) };
    });
my $directory_hr=$bulk_api_or->workers()->upload_assets('test-worker', $asset_dir,
    prefix => '/docs/');
is_deeply([sort(keys(%{$directory_hr->{'manifest'}}))],
    ['/docs/.well-known/info.txt', '/docs/css/site.css', '/docs/index.html'],
    'directory upload preserves recursive layout beneath prefix');
like($bulk_request[1][2]{'content'}, qr/Content-Type: text\/css\r\n/,
    'directory upload supplies CSS MIME type');

@bulk_request=();
my $list_hr=$bulk_api_or->workers()->upload_assets('test-worker', [
    "$asset_dir/index.html",
    { path => "$asset_dir/css/site.css", name => 'styles/main.css',
        content_type => 'text/css' }
], prefix => 'site');
is_deeply([sort(keys(%{$list_hr->{'manifest'}}))],
    ['/site/index.html', '/site/styles/main.css'],
    'array upload uses basenames and explicit relative URL names');

@bulk_request=();
my $mapped_hr=$bulk_api_or->workers()->upload_assets('test-worker',
    { '/index.html' => '<h1>Map</h1>' }, prefix => '/docs');
is_deeply([keys(%{$mapped_hr->{'manifest'}})], ['/docs/index.html'],
    'prefix also applies to existing path map');

@bulk_request=();
eval { $bulk_api_or->workers()->upload_assets('test-worker', [
    "$asset_dir/index.html", "$asset_dir/index.html"
]) };
like($@, qr/duplicate asset path/, 'duplicate array URL paths rejected');
is(scalar(@bulk_request), 0, 'duplicate paths rejected before API request');
eval { $bulk_api_or->workers()->upload_assets('test-worker', $asset_dir,
    prefix => '../bad') };
like($@, qr/invalid asset prefix/, 'path traversal in prefix rejected');
eval { $bulk_api_or->workers()->upload_assets('test-worker', [], prefix => '/') };
like($@, qr/assets must not be empty/, 'empty file list rejected');
is(scalar(@bulk_request), 0, 'invalid bulk inputs make no API request');

my $symlink_fn="$asset_dir/linked.css";
if (eval { symlink("$asset_dir/css/site.css", $symlink_fn) }) {
    eval { $bulk_api_or->workers()->upload_assets('test-worker', $asset_dir) };
    like($@, qr/contains a symlink/, 'directory upload rejects symlinks');
    unlink($symlink_fn);
}

my @unchanged_request;
my $unchanged_api_or=Cloudflare::API->new(token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@unchanged_request, [@_]);
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true,
            result => { jwt => 'already-complete', buckets => [] } }) };
    });
my $unchanged_hr=$unchanged_api_or->workers()->upload_assets('test-worker',
    { '/index.html' => '<html>ok</html>' });
is($unchanged_hr->{'jwt'}, 'already-complete', 'unchanged assets use session completion token');
is(scalar(@unchanged_request), 1, 'unchanged assets need no upload request');
unlink($image_fn);

unlink($file_fn);
done_testing();
