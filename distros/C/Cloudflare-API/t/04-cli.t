use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use IPC::Open3 qw(open3);
use Config;
use JSON::PP;

sub run_cli {
    my ($input, @arg)=@_;
    my ($stdout_fh)=tempfile(UNLINK => 1);
    my ($stderr_fh)=tempfile(UNLINK => 1);
    my $stdout_fd='>&'.fileno($stdout_fh);
    my $stderr_fd='>&'.fileno($stderr_fh);
    my $pid=open3(my $stdin_fh, $stdout_fd, $stderr_fd,
        $^X, '-Ilib', File::Spec->catfile('bin', 'cloudflare-api'), @arg);
    print($stdin_fh $input) if defined($input);
    close($stdin_fh);
    waitpid($pid, 0);
    my $exit=$? >> 8;
    seek($stdout_fh, 0, 0) || die "unable to rewind CLI output: $!";
    seek($stderr_fh, 0, 0) || die "unable to rewind CLI errors: $!";
    local $/;
    my $output=(<$stdout_fh> || '').(<$stderr_fh> || '');
    return ($exit, $output);
}

my $loaded=do './bin/cloudflare-api';
ok($loaded, 'CLI functions load');

is(typed_value('string', 'hello'), 'hello', 'string input');
ok(typed_value('bool', 'true'), 'boolean true');
ok(!typed_value('bool', 'false'), 'boolean false');
is_deeply(typed_value('array', '[1,2]'), [1,2], 'array input');
is_deeply(typed_value('hash', '{"a":1}'), {a => 1}, 'hash input');
is_deeply(typed_value('json', '{"a":[1]}'), {a => [1]}, 'JSON input');

my ($fh, $path)=tempfile();
print $fh '{"name":"from file"}';
close($fh);
is_deeply(typed_value('json-file', $path), {name => 'from file'}, 'JSON file input');

my ($dump_fh, $dump_path)=tempfile();
print $dump_fh "\$VAR1 = { 'name' => 'trusted' };\n";
close($dump_fh);
is_deeply(typed_value('dumper-file', $dump_path), {name => 'trusted'},
    'trusted Data::Dumper file input');

my ($key, $value)=parse_named('json', 'binding={"type":"plain_text"}');
is($key, 'binding', 'named parameter key');
is_deeply($value, {type => 'plain_text'}, 'named parameter JSON value');

my %seen;
is_deeply(next_query({per_page => 2}, {result_info => {page => 1,
    per_page => 2, total_count => 5}}, 1, \%seen),
    {per_page => 2, page => 2}, 'count-based pagination');
is_deeply(next_query({per_page => 2}, {result_info => {page => 1,
    total_pages => 3}}, 1, \%seen),
    {per_page => 2, page => 2}, 'page-based pagination');
is_deeply(next_query({}, {result_info => {cursor => 'abc'}}, 1, \%seen),
    {cursor => 'abc'}, 'cursor pagination');
is(next_query({}, {result_info => {page => 2, total_pages => 2}}, 2, \%seen),
    undef, 'pagination ends');

my $error=eval { typed_value('bool', 'maybe'); 1 };
ok(!$error && $@=~/boolean must be true or false/, 'invalid boolean rejected');
$error=eval { typed_value('array', '{}'); 1 };
ok(!$error && $@=~/requires a JSON array/, 'wrong JSON type rejected');
$error=eval { next_query({}, {result_info => {cursor => 'abc'}}, 2, \%seen); 1 };
ok(!$error && $@=~/cursor repeated/, 'repeated cursor rejected');

my ($exit, $output)=run_cli(undef, qw(--resource kv --action list_namespaces
    --paginate --max-pages 2 --per-page 5 --dump-opt));
is($exit, 0, 'CLI options accepted');
like($output, qr/'max-pages' => 2/, 'page limit in parsed options');
like($output, qr/'per_page' => 5/, 'page size in parsed parameters');

($exit, $output)=run_cli(undef,
    qw(--resource kv --action list_namespaces --dump_opt));
is($exit, 0, 'WebDyne-style dump_opt alias accepted');
like($output, qr/'dump_opt' => 1/, 'dump_opt uses the canonical option key');

($exit, $output)=run_cli(undef, qw(zones list --param status=active --dump-opt));
is($exit, 0, 'resource and action accepted as positional operands');
like($output, qr/'resource' => 'zones'/, 'positional resource recorded');
like($output, qr/'action' => 'list'/, 'positional action recorded');

($exit, $output)=run_cli(undef, qw(--resource zones list --dump-opt));
is($exit, 0, 'positional action accepted with named resource');
($exit, $output)=run_cli(undef, qw(zones --action list --dump-opt));
is($exit, 0, 'positional resource accepted with named action');

($exit, $output)=run_cli(undef,
    qw(workers list_deployments my-worker --dump-opt));
is($exit, 0, 'bare method argument accepted after resource and action');
like($output, qr/'arguments' => \[\s*'my-worker'/,
    'bare method argument becomes a string argument');

{
    local $ENV{'POSIXLY_CORRECT'}=1;
    ($exit, $output)=run_cli(undef,
        qw(workers list_deployments my-worker --dump-opt));
    is($exit, 0, 'positional form permits later options in POSIX environments');
}

($exit, $output)=run_cli(undef,
    qw(--resource workers list_deployments my-worker --dump-opt));
is($exit, 0, 'bare action and method argument accepted with named resource');

($exit, $output)=run_cli(undef,
    qw(kv put_value namespace --arg key value --dump-opt));
is($exit, 0, 'bare and explicit method arguments may be mixed');
like($output, qr/'arguments' => \[\s*'namespace',\s*'key',\s*'value'/s,
    'mixed method arguments preserve command-line order');

($exit, $output)=run_cli(undef, 'd1', 'query_sql', 'database', 'SELECT ?',
    '--arg-array', '[7]', '--dump-opt');
is($exit, 0, 'typed argument accepted after bare method arguments');
like($output, qr/'database'.*'SELECT \?'.*\[\s*7\s*\]/s,
    'typed and bare arguments preserve command-line order');

($exit, $output)=run_cli(undef,
    qw(workers list_deployments --dump-opt -- --leading-dash));
is($exit, 0, 'post-separator bare argument accepted');
like($output, qr/'arguments' => \[\s*'--leading-dash'/,
    'post-separator argument retains its leading dash');

($exit, $output)=run_cli(undef,
    qw(--method GET --path /accounts body --dump-opt));
isnt($exit, 0, 'bare argument remains unavailable in raw request mode');
like($output, qr/unexpected positional arguments/,
    'raw request bare argument error is unchanged');

($exit, $output)=run_cli(undef, qw(--dump-opt));
isnt($exit, 0, 'missing resource rejected');
like($output, qr/resource is required; valid resources: .*zones/,
    'missing resource lists valid resources');

($exit, $output)=run_cli(undef, qw(--resource zones --dump-opt));
isnt($exit, 0, 'missing action rejected');
like($output, qr/action is required for resource 'zones'; valid actions: get, list/,
    'missing action lists resource actions');

($exit, $output)=run_cli(undef, qw(--resource unknown --action list --dump-opt));
isnt($exit, 0, 'unknown resource rejected');
like($output, qr/unknown resource 'unknown'; valid resources: .*zones/,
    'unknown resource lists valid resources');

($exit, $output)=run_cli(undef, qw(--resource zones --action unknown --dump-opt));
isnt($exit, 0, 'unknown action rejected');
like($output, qr/unknown action 'unknown' for resource 'zones'; valid actions: get, list/,
    'unknown action lists resource actions');

($exit, $output)=run_cli(undef,
    qw(--auth=wrangler --resource workers --action list_deployments));
isnt($exit, 0, 'missing method argument rejected');
like($output, qr/list_deployments.*requires at least 1 --arg value; 0 supplied/,
    'missing method argument is explained before authentication');

($exit, $output)=run_cli(undef,
    qw(zones get --arg one --arg two --dump-opt));
isnt($exit, 0, 'excess method argument rejected');
like($output, qr/get.*accepts at most 1 --arg value; 2 supplied/,
    'excess method argument is explained');

($exit, $output)=run_cli(undef,
    qw(workers inspect_script --param name=alpha --dump-opt));
is($exit, 0, 'Worker inspection selector accepted');
like($output, qr/'name' => 'alpha'/, 'Worker inspection selector passed by name');

($exit, $output)=run_cli(undef, qw(workers inspect_script --dump-opt));
isnt($exit, 0, 'missing Worker inspection selector rejected');
like($output, qr/inspect_script requires exactly one of name, tag, or etag/,
    'missing Worker inspection selector is explained');

($exit, $output)=run_cli(undef,
    qw(workers inspect_script --param name=alpha --param tag=worker-tag --dump-opt));
isnt($exit, 0, 'multiple Worker inspection selectors rejected');
like($output, qr/inspect_script requires exactly one/, 'multiple selectors are explained');

($exit, $output)=run_cli(undef,
    qw(workers inspect_script --param id=alpha --dump-opt));
isnt($exit, 0, 'unknown Worker inspection selector rejected');
like($output, qr/unknown inspect selector: id/, 'unknown inspection selector is identified');

($exit, $output)=run_cli(undef,
    qw(workers inspect_script --param name=alpha --full-response --dump-opt));
isnt($exit, 0, 'Worker inspection full response rejected');
like($output, qr/full_response is unavailable/, 'inspection full response error is clear');

($exit, $output)=run_cli(undef,
    qw(workers search_scripts --param name=alpha --paginate --dump-opt));
is($exit, 0, 'Worker search accepts pagination');

my ($asset_json_fh, $asset_json_fn)=tempfile();
print($asset_json_fh '["from-json.html",{"path":"local/site.css","name":"css/site.css"}]');
close($asset_json_fh);
my ($asset_text_fh, $asset_text_fn)=tempfile();
print($asset_text_fh "text file.css\n\nsecond.txt\r\n");
close($asset_text_fh);
my ($asset_stdin_fh, $asset_stdin_fn)=tempfile();
my $asset_stdin="from stdin.html\n\nlast.png\n";
print($asset_stdin_fh $asset_stdin);
close($asset_stdin_fh);

($exit, $output)=run_cli($asset_stdin, '--resource', 'workers', '--action',
    'upload_assets', '--arg', 'worker', '--asset', 'first.html',
    '--asset-list-json', $asset_json_fn, '--asset-list-text', $asset_text_fn,
    '--asset', 'final.js', '--asset-list-stdin', '--param', 'prefix=/docs',
    '--dump-opt');
is($exit, 0, 'asset sources combine for Worker asset upload');
like($output, qr/'first\.html'.*'from-json\.html'.*'text file\.css'.*'second\.txt'.*'final\.js'.*'from stdin\.html'.*'last\.png'/s,
    'asset sources retain option and line order, including spaces in filenames');
like($output, qr/'name' => 'css\/site\.css'/, 'JSON asset entry retains URL name');
like($output, qr/'prefix' => '\/docs'/, 'asset prefix is passed as named option');

($exit, $output)=run_cli(undef, qw(--resource workers --action upload_assets
    --arg worker --arg dist --asset first.html --dump-opt));
isnt($exit, 0, 'asset list cannot mix with directory source argument');
like($output, qr/require one Worker name and no other source argument/,
    'mixed source error explains the accepted form');

($exit, $output)=run_cli(undef, qw(--resource kv --action list_namespaces
    --asset first.html --dump-opt));
isnt($exit, 0, 'asset options rejected for another action');
like($output, qr/require --resource workers --action upload_assets/,
    'asset options error identifies the Worker action');

($exit, $output)=run_cli(undef, qw(--resource workers --action upload_assets
    --arg worker --asset-list-stdin --asset-list-stdin --dump-opt));
isnt($exit, 0, 'repeated stdin source rejected before reading stdin');
like($output, qr/--asset-list-stdin may be used only once/,
    'repeated stdin source error is clear');

($exit, $output)=run_cli(undef, '--resource', 'workers', '--action',
    'upload_assets', '--arg', 'worker', '--asset-list-text', $asset_stdin_fn,
    '--dump-opt');
is($exit, 0, 'line-based asset file accepted on its own');
like($output, qr/'from stdin\.html'.*'last\.png'/s,
    'line-based asset file ignores blank lines');

ok(!exists($INC{'Cloudflare/API/CLI/Completion.pm'}),
    'completion renderer is not loaded with CLI functions');
foreach my $shell (qw(bash zsh fish)) {
    ($exit, $output)=run_cli(undef, "--generate-completion=$shell");
    is($exit, 0, "$shell completion generated without request arguments");
    like($output, qr/cloudflare-api/, "$shell completion names the command");
    like($output, qr/workers/, "$shell completion includes resources");
    like($output, qr/list_deployments/, "$shell completion includes actions");
    like($output, qr/arg-json-file/, "$shell completion includes options");
}

($exit, $output)=run_cli(undef, '--generate-completion=powershell');
isnt($exit, 0, 'unsupported completion shell rejected');
like($output, qr/valid shells: bash, fish, zsh/,
    'completion error lists supported shells');

($exit, $output)=run_cli(undef, '--version');
is($exit, 0, 'version option accepted');
is($output, "cloudflare-api $Cloudflare::API::VERSION\n", 'version output unchanged');

my $wrangler_dn=tempdir(CLEANUP => 1);
my $wrangler_source=<<'MOCK';
#!/usr/bin/env perl
use strict;
use warnings;
exit(1) if $ENV{'MOCK_WRANGLER_FAIL'};
if (join(' ', @ARGV) eq 'auth token --json') {
    print $ENV{'MOCK_WRANGLER_JSON'};
}
elsif (join(' ', @ARGV) eq 'whoami --json') {
    print $ENV{'MOCK_WRANGLER_WHOAMI_JSON'};
}
else {
    exit(2);
}
MOCK
my $wrangler_fn;
if ($^O eq 'MSWin32') {
    my $wrangler_perl_fn=File::Spec->catfile($wrangler_dn, 'wrangler-mock.pl');
    open(my $wrangler_perl_fh, '>', $wrangler_perl_fn) ||
        die "unable to create mock Wrangler script: $!";
    print($wrangler_perl_fh $wrangler_source);
    close($wrangler_perl_fh) || die "unable to close mock Wrangler script: $!";
    $wrangler_fn=File::Spec->catfile($wrangler_dn, 'wrangler.bat');
    open(my $wrangler_fh, '>', $wrangler_fn) ||
        die "unable to create mock Wrangler launcher: $!";
    my $perl=$^X;
    $perl=~s/%/%%/g;
    print($wrangler_fh qq{\@"$perl" "%~dp0wrangler-mock.pl" %*\r\n});
    close($wrangler_fh) || die "unable to close mock Wrangler launcher: $!";
}
else {
    $wrangler_fn=File::Spec->catfile($wrangler_dn, 'wrangler');
    open(my $wrangler_fh, '>', $wrangler_fn) ||
        die "unable to create mock Wrangler: $!";
    print($wrangler_fh $wrangler_source);
    close($wrangler_fh) || die "unable to close mock Wrangler: $!";
    chmod(0755, $wrangler_fn) || die "unable to make mock Wrangler executable: $!";
}
{
    local $ENV{'PATH'}=$wrangler_dn.$Config{'path_sep'}.$ENV{'PATH'};
    local $ENV{'MOCK_WRANGLER_JSON'}='{"type":"oauth","token":"oauth-test-token"}';
    local $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}=
        '{"loggedIn":true,"accounts":[{"id":"account-id","name":"Example"}]}';
    is(wrangler_token(), 'oauth-test-token', 'Wrangler OAuth token accepted');
    is(wrangler_account_id(), 'account-id', 'sole Wrangler account ID accepted');
    $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}=
        '{"loggedIn":true,"accounts":[{"id":"one"},{"id":"two"}]}';
    $error=eval { wrangler_account_id(); 1 };
    ok(!$error && $@=~/multiple accounts.*--account-id/, 'multiple Wrangler accounts rejected');
    $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}='{"loggedIn":true,"accounts":[]}';
    $error=eval { wrangler_account_id(); 1 };
    ok(!$error && $@=~/no available accounts/, 'empty Wrangler account list rejected');
    $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}='{"loggedIn":true}';
    $error=eval { wrangler_account_id(); 1 };
    ok(!$error && $@=~/no account list/, 'missing Wrangler account list rejected');
    $ENV{'MOCK_WRANGLER_JSON'}='{"type":"api_token","token":"api-test-token"}';
    is(wrangler_token(), 'api-test-token', 'Wrangler API token accepted');
    $ENV{'MOCK_WRANGLER_JSON'}='{"type":"api_key","key":"secret-key","email":"x@example.test"}';
    $error=eval { wrangler_token(); 1 };
    ok(!$error && $@=~/unsupported credential type/, 'API key credentials rejected');
    unlike($@, qr/secret-key/, 'API key is absent from error');
    $ENV{'MOCK_WRANGLER_JSON'}='secret-output';
    $error=eval { wrangler_token(); 1 };
    ok(!$error && $@=~/invalid JSON/, 'invalid Wrangler output rejected');
    unlike($@, qr/secret-output/, 'invalid output is absent from error');
    $ENV{'MOCK_WRANGLER_JSON'}='{"type":"oauth","token":"bad\\nheader"}';
    $error=eval { wrangler_token(); 1 };
    ok(!$error && $@=~/no usable token/, 'token containing a control character rejected');
    local $ENV{'MOCK_WRANGLER_FAIL'}=1;
    $error=eval { wrangler_token(); 1 };
    ok(!$error && $@=~/check Wrangler login/, 'Wrangler failure explains login');
}

{
    local $ENV{'PATH'}=$wrangler_dn.$Config{'path_sep'}.$ENV{'PATH'};
    local $ENV{'MOCK_WRANGLER_JSON'}='{"type":"oauth","token":"oauth-test-token"}';
    local $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}=
        '{"loggedIn":true,"accounts":[{"id":"account-id","name":"Example"}]}';
    local $ENV{'CLOUDFLARE_ACCOUNT_ID'};
    my %client_opt;
    no warnings qw(redefine once);
    local *Cloudflare::API::new=sub {
        my $class=shift();
        %client_opt=@_;
        return bless({}, $class);
    };
    local *Cloudflare::API::r2=sub { return bless({}, 'Cloudflare::API::R2') };
    local *Cloudflare::API::R2::list_buckets=sub { die "stop after client creation\n" };
    local *Cloudflare::API::workers=sub { return bless({}, 'Cloudflare::API::Workers') };
    local *Cloudflare::API::Workers::list_routes=sub { die "stop after client creation\n" };
    {
        local @ARGV=qw(--auth=wrangler --resource r2 --action list_buckets);
        $error=eval { main(\@ARGV); 1 };
    }
    ok(!$error && $@=~/stop after client creation/,
        'Wrangler authentication reaches an account-scoped request');
    is($client_opt{'token'}, 'oauth-test-token', 'Wrangler token passed to client');
    is($client_opt{'account_id'}, 'account-id', 'Wrangler account ID passed to client');

    $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}='invalid';
    %client_opt=();
    {
        local @ARGV=qw(--auth=wrangler --account-id explicit-id --resource r2 --action list_buckets);
        $error=eval { main(\@ARGV); 1 };
    }
    ok(!$error && $@=~/stop after client creation/,
        'explicit account ID skips Wrangler account discovery');
    is($client_opt{'account_id'}, 'explicit-id', 'explicit account ID takes precedence');

    $ENV{'MOCK_WRANGLER_WHOAMI_JSON'}='invalid';
    %client_opt=();
    {
        local @ARGV=qw(--auth=wrangler --resource workers --action list_routes --arg zone-id);
        $error=eval { main(\@ARGV); 1 };
    }
    ok(!$error && $@=~/stop after client creation/,
        'zone-scoped Worker route action skips Wrangler account discovery');
    ok(!exists($client_opt{'account_id'}), 'zone-scoped action needs no account ID');
}

($exit, $output)=run_cli(undef, qw(--auth=other --resource accounts --action
    list --dump-opt));
isnt($exit, 0, 'unknown authentication source rejected');
like($output, qr/auth must be wrangler/, 'authentication source error is clear');

($exit, $output)=run_cli(undef, qw(--auth=wrangler --resource accounts --action
    list --dump-opt));
is($exit, 0, 'Wrangler option accepted without fetching credentials in dump mode');

($exit, $output)=run_cli(undef, qw(--resource r2 --action delete_bucket --arg x
    --paginate --dump-opt));
isnt($exit, 0, 'pagination rejected for non-list action');
like($output, qr/--paginate requires a list or search action/, 'pagination error is clear');

($exit, $output)=run_cli(undef, '--resource', 'secrets_store', '--action',
    'create_secret', '--arg', 'store', '--arg-json',
    '[{"name":"x","value":"secret","scopes":["workers"]}]', '--dump-opt');
isnt($exit, 0, 'secret-bearing action cannot dump parsed options');
unlike($output, qr/secret\"/, 'secret value not dumped');

done_testing();
