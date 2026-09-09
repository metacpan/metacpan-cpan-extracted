#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

# The CLI depends on SSH, which requires Net::SSH2
BEGIN {
    eval { require Net::SSH2 };
    if ($@) {
	plan skip_all => 'Net::SSH2 not available';
    }
}

use_ok('App::FuguVM::CLI');
use_ok('App::FuguVM::Proxy');

# Test help command returns success

# Test help command returns success (exit code 0)
{
    my $result = App::FuguVM::CLI->run('help');
    is($result, 0, 'help command returns success');
}

# Test unknown command returns error (exit code 2 = invalid args)
{
    # Suppress the warning
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('unknown_command');
    is($result, 2, 'unknown command returns invalid args exit code');
}

# ============================================================
# Robustness tests (from ROBUSTNESS-REPORT.md)
# ============================================================

# Issue 2: Permission denied during init (readonly directory)
SKIP: {
    skip "Cannot test permission issues as root", 2 if $< == 0;
    
    my $tmpdir = tempdir(CLEANUP => 1);
    my $readonly = "$tmpdir/readonly";
    mkdir $readonly;
    chmod 0555, $readonly;
    
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('init', $readonly);
    
    chmod 0755, $readonly;  # cleanup
    
    is($result, 1, 'init on readonly dir returns EXIT_ERROR');
}

# Init creates an absent target directory (mkdir -p semantics)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $result = App::FuguVM::CLI->run('init', "$tmpdir/nested/project");
    is($result, 0, 'init creates an absent directory');
    ok(-f "$tmpdir/nested/project/.fuguvmrc", 'and writes the config there');
}

# A target that exists as a file is a diagnosed error, not a crash:
# Fugu::File refuses to create a directory through it.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$tmpdir/occupied" or die $!;
    close $fh;

    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('init', "$tmpdir/occupied");
    is($result, 1, 'init on a non-directory returns EXIT_ERROR');
}

# Issue 5: Non-existent project path
{
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('--project=/nonexistent/path', 'status');
    is($result, 3, 'non-existent project path returns EXIT_CONFIG_ERROR');
}

# Issue 6: Non-numeric timeout value
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $orig_dir = getcwd();
    chdir $tmpdir;
    
    # Initialize the project first
    App::FuguVM::CLI->run('init');
    
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('wait', '--timeout=abc');
    
    chdir $orig_dir;
    
    is($result, 2, 'non-numeric timeout returns EXIT_INVALID_ARGS');
}

# Issue 6: Zero timeout value
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $orig_dir = getcwd();
    chdir $tmpdir;
    
    # Initialize the project first
    App::FuguVM::CLI->run('init');
    
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('wait', '--timeout=0');
    
    chdir $orig_dir;
    
    is($result, 2, 'zero timeout returns EXIT_INVALID_ARGS');
}

# Issue 6: Negative timeout value (as string)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $orig_dir = getcwd();
    chdir $tmpdir;
    
    # Initialize the project first
    App::FuguVM::CLI->run('init');
    
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('wait', '--timeout=-10');
    
    chdir $orig_dir;
    
    is($result, 2, 'negative timeout returns EXIT_INVALID_ARGS');
}

# Issue 1: A long VM name from the CLI
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $orig_dir = getcwd();
    chdir $tmpdir;
    
    # Initialize the project first
    App::FuguVM::CLI->run('init');
    
    my $long_name = 'x' x 10000;
    local $SIG{__WARN__} = sub {};
    my $result = App::FuguVM::CLI->run('--vm', $long_name, 'status');
    
    chdir $orig_dir;
    
    is($result, 1, 'extremely long VM name returns EXIT_ERROR');
}

# Init command is idempotent
{
    my $tmpdir = tempdir(CLEANUP => 1);

    my $result1 = App::FuguVM::CLI->run('init', $tmpdir);
    is($result1, 0, 'first init returns success');

    my $result2 = App::FuguVM::CLI->run('init', $tmpdir);
    is($result2, 0, 'second init (idempotent) returns success');
}

# Init writes the arch directive beside the other defaults
{
    my $tmpdir = tempdir(CLEANUP => 1);
    App::FuguVM::CLI->run('init', $tmpdir);

    open my $fh, '<', "$tmpdir/.fuguvm/vms/default.conf" or die $!;
    my $conf = do { local $/; <$fh> };
    close $fh;
    like($conf, qr/^arch = arm64$/m, 'init writes arch = arm64');
}

# An unknown arch value is a configuration error, exit code 3. A VM
# that no file declares still gives 4.
{
    my $project = tempdir(CLEANUP => 1);
    make_path("$project/.fuguvm/vms", "$project/.fuguvm/state");

    open my $fh, '>', "$project/.fuguvmrc" or die $!;
    print $fh "state_dir .fuguvm/state\n";
    print $fh "vm \"default\" {\n";
    print $fh "\tarch riscv64\n";
    print $fh "}\n";
    print $fh "vm \"good\" {\n";
    print $fh "\tarch amd64\n";
    print $fh "}\n";
    close $fh;

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'status'),
	3, 'an unknown arch value exits with EXIT_CONFIG_ERROR');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    '--vm', 'undeclared', 'status'),
	4, 'an undeclared VM name still exits with EXIT_VM_NOT_FOUND');
    my ($good) = _run_captured("--project=$project", '--quiet',
	'--vm', 'good', 'status');
    is($good, 0, 'a valid arch value loads');
}

# ============================================================
# The status report
# ============================================================

# The report is data: one 'key: value' line per key on standard
# output, whatever --quiet says, with nothing on standard error for
# a healthy project. HOME is empty, so no real ~/.fuguvmrc can shape
# the asserted values.
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $project = _cache_project();

    my ($code, $out, $err) = _run_captured("--project=$project", 'status');
    is($code, 0, 'status succeeds');
    isnt($out, '', 'status writes to standard output');
    is($err, '', 'and writes nothing to standard error');

    my @lines = split /\n/, $out;
    is(scalar(grep { !/^\w+: / } @lines), 0, 'each line matches ^\w+: ');

    for my $key (qw(accel arch bind_address console_port disk_exists
	installed name pid proxy_url ssh_port state)) {
	is(scalar(grep { /^$key: / } @lines), 1, "the report holds $key");
    }

    like($out, qr/^proxy_url: $/m,
	'proxy_url is empty while the proxy does not run');

    like($out, qr/^bind_address: 127\.0\.0\.1$/m,
	'the report holds the default bind address');
    like($out, qr/^ssh_port: 2222$/m,
	'the report holds the configured SSH port');
    like($out, qr/^accel: (hvf|kvm|tcg)$/m,
	'the report holds a known accelerator');
    like($out, qr/^pid: $/m,
	'an empty value ends with the colon and one space');

    my (undef, $quiet_out) =
	_run_captured("--project=$project", '--quiet', 'status');
    is($quiet_out, $out, '--quiet writes the same lines');
}

# One optional key argument selects one bare value. An unknown key
# gives exit code 2 and names every valid key.
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $project = _cache_project();

    my ($code, $out, $err) =
	_run_captured("--project=$project", '--quiet', 'status', 'ssh_port');
    is($code, 0, 'status with a key succeeds');
    is($out, "2222\n", 'one bare value, with no key name and no colon');

    ($code) = _run_captured("--project=$project",
	'status', 'ssh_port', 'extra');
    is($code, 2, 'a second argument returns EXIT_INVALID_ARGS');

    ($code, $out, $err) =
	_run_captured("--project=$project", 'status', 'nonsense');
    is($code, 2, 'an unknown key returns EXIT_INVALID_ARGS');
    is($out, '', 'and writes no data');
    like($err, qr/nonsense/, 'the diagnostic names the unknown key');
    like($err, qr/ssh_port/, 'and the valid keys');
    like($err, qr/bind_address/, 'all of them');
}

# A connection command against a stopped guest with a directive of
# 'auto' fails with a diagnostic. A connection with an undef port
# would reach the default port of the protocol on the host itself.
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $project = _cache_project();
    open my $fh, '>>', "$project/.fuguvmrc" or die $!;
    print $fh "vm \"fleet\" {\n";
    print $fh "\tssh_port auto\n";
    print $fh "\tconsole_port auto\n";
    print $fh "}\n";
    close $fh;

    # ssh and console check the running state first, so their
    # diagnostic names the guest, not the port
    for my $command (['ssh', 'true'], ['console']) {
	my ($code, $out, $err) = _run_captured("--project=$project",
	    '--vm', 'fleet', @$command);
	is($code, 1, "@$command fails on a stopped auto guest");
	like($err, qr/VM 'fleet' does not run/,
	    'and the diagnostic names the stopped guest');
    }
    for my $command (['expect', 'x.exp'], ['wait']) {
	my ($code, $out, $err) = _run_captured("--project=$project",
	    '--vm', 'fleet', @$command);
	is($code, 1, "@$command fails on a stopped auto guest");
	like($err, qr/has no (ssh|console)_port now/,
	    'and the diagnostic names the missing port');
    }

    my ($code, $out) = _run_captured("--project=$project", '--quiet',
	'--vm', 'fleet', 'status', 'ssh_port');
    is($code, 0, 'status still answers for the stopped auto guest');
    is($out, "\n", 'and the bare value is empty');
}

# 'disk info' shares the printer, so its report is data on standard
# output too
SKIP: {
    my $has_qemu = `which qemu-img 2>/dev/null`;
    skip 'qemu-img not installed', 3 unless $has_qemu;

    my $project = _cache_project();
    App::FuguVM::Disk->new("$project/.fuguvm/state")
	->create('default', '16M')
	or skip 'cannot create a test disk image', 3;

    my ($code, $out, $err) =
	_run_captured("--project=$project", 'disk', 'info');
    is($code, 0, 'disk info succeeds');
    isnt($out, '', 'disk info writes to standard output');
    like($out, qr/^virtual-size: /m, 'as key: value lines');
}

# ============================================================
# The file transfer and the argument vector
# ============================================================

# The command table declares the two verbs, so the help names them
{
    my ($code, $out) = _run_captured('help');
    is($code, 0, 'help succeeds');
    like($out, qr/^\s*put\b/m, 'the help names put');
    like($out, qr/^\s*get\b/m, 'the help names get');
}

# The argument refusals of put, each with exit code 2
{
    my $project = _cache_project();
    open my $fh, '>', "$project/payload" or die $!;
    print $fh "payload\n";
    close $fh;

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'put', "$project/payload"),
	2, 'put with one argument exits 2');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'put', "$project/payload", 'relative/dst'),
	2, 'put with a relative <remote> exits 2');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'put', "$project/absent", '/root/dst'),
	2, 'put with a <local> that does not exist exits 2');

    my ($code, $out, $err) = _run_captured("--project=$project",
	'put', '--mode=8888', "$project/payload", '/root/dst');
    is($code, 2, 'put --mode=8888 exits 2');
    like($err, qr/octal digits/, 'and the diagnostic states the rule');

    # A valid mode passes the validation. The guest does not run,
    # so the verb then fails with 1, past the argument checks.
    for my $mode (qw(0755 755)) {
	($code, $out, $err) = _run_captured("--project=$project",
	    'put', "--mode=$mode", "$project/payload", '/root/dst');
	is($code, 1, "put --mode=$mode passes the validation");
	like($err, qr/does not run/, 'and stops at the running check');
    }
}

# The argument refusals of get, each with exit code 2
{
    my $project = _cache_project();

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'get', '/root/a', "$project/a", 'extra'),
	2, 'get with three arguments exits 2');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'get', 'relative/a', "$project/a"),
	2, 'get with a relative <remote> exits 2');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'get', '/root/a', $project),
	2, 'get with an existing directory as <local> exits 2');
}

# The four verbs share the VM checks: exit 4 for a VM that the
# configuration does not declare, and exit 1 for a declared VM that
# does not run, with the VM name in the message
{
    my $project = _cache_project();
    open my $fh, '>', "$project/payload" or die $!;
    print $fh "payload\n";
    close $fh;

    my @verbs = (
	['ssh', '--', 'true'],
	['put', "$project/payload", '/root/dst'],
	['get', '/root/a', "$project/out"],
	['console'],
    );

    local $SIG{__WARN__} = sub {};
    for my $verb (@verbs) {
	is(App::FuguVM::CLI->run("--project=$project", '--quiet',
		'--vm', 'undeclared', @$verb),
	    4, "$verb->[0] exits 4 for an undeclared VM");

	my ($code, $out, $err) =
	    _run_captured("--project=$project", @$verb);
	is($code, 1, "$verb->[0] exits 1 for a stopped VM");
	like($err, qr/VM 'default' does not run/,
	    'and the message names the VM');
    }
}

# The parser rule: a bare hyphen word is an option of the tool, and
# the -- separator carries the vector through unchanged
{
    my $project = _cache_project();

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'ssh', 'uname', '-m'),
	2, 'a bare fuguvm ssh uname -m exits 2');

    my @seen;
    {
	no warnings 'redefine';
	local *App::FuguVM::CLI::cmd_ssh = sub ($self, $cli, @args) {
	    @seen = @args;
	    return 0;
	};
	is(App::FuguVM::CLI->run("--project=$project", '--quiet',
		'ssh', '--', 'uname', '-m'),
	    0, 'fuguvm ssh -- uname -m dispatches');
    }
    is_deeply(\@seen, ['uname', '-m'],
	'and the two words reach the command body');

    is(App::FuguVM::CLI->run('ssh', '--help'), 0, 'ssh --help exits 0');
}

# ============================================================
# Installed-image cache subcommand
# ============================================================

# Usage errors match the style of the other subcommands
{
    my $project = _cache_project();

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", 'cache', 'frobnicate'), 2,
	'unknown cache action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", 'cache'), 2,
	'cache without an action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", 'cache', 'clear', '--bogus'),
	2, 'unknown cache clear option returns EXIT_INVALID_ARGS');
}

# A 'cache list' on an empty cache still succeeds
{
    my $project = _cache_project();
    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'cache', 'list'),
	0, 'cache list on an empty cache succeeds');
}

# clear removes everything. clear --stale keeps the invoked VM's key.
{
    my $project = _cache_project();
    my $cache = App::FuguVM::DiskCache->new("$project/cache");
    my $current = $cache->key(
	App::FuguVM::Config->new($project)->load_vm('default'));
    ok(defined $current, 'the configured VM derives a cache key');

    _fake_entry($cache, $current);
    _fake_entry($cache, '7.7-arm64-00000000');
    make_path($cache->installed_dir . '/.tmp.999.abcdef');

    is(scalar @{ $cache->list }, 2, 'two entries before pruning');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'cache', 'clear', '--stale'),
	0, 'cache clear --stale succeeds');

    my $left = $cache->list;
    is(scalar @$left, 1, '--stale keeps exactly one entry');
    is($left->[0]{key}, $current, 'and it is the invoked VM\'s key');
    ok(!-e $cache->installed_dir . '/.tmp.999.abcdef',
	'--stale also sweeps interrupted store trees');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'cache', 'clear'),
	0, 'bare cache clear succeeds');
    is(scalar @{ $cache->list }, 0, 'bare clear removes everything');
}

# The proxy's downloads share cache_dir with the images, and nothing
# else bounds them. Thus the same command prunes both. --stale keeps the
# OpenBSD version the invoked VM installs. A bare clear keeps nothing.
{
    my $project = _cache_project();
    my $proxy = App::FuguVM::Proxy::Cache->new("$project/cache");

    _fake_download($project, '7.8/arm64/base78.tgz');
    _fake_download($project, '7.7/arm64/base77.tgz');
    is(scalar @{ $proxy->list }, 2, 'two cached downloads before pruning');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'cache', 'clear', '--stale'),
	0, 'cache clear --stale succeeds');

    is_deeply([map { $_->{url} } @{ $proxy->list }],
	['http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz'],
	'--stale keeps the version the configured VM installs');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'cache', 'clear'),
	0, 'bare cache clear succeeds');
    is(scalar @{ $proxy->list }, 0, 'bare clear empties the proxy too');
}

# The listing also reports the proxy. Thus a user who decides on a
# prune sees both halves of cache_dir.
{
    my $project = _cache_project();
    _fake_download($project, '7.7/arm64/base77.tgz');

    my $err = _capture_stderr($project, 'cache', 'list');
    like($err, qr/Proxy downloads/, 'cache list reports the proxy store');
    like($err, qr/OpenBSD 7\.7/, 'broken down by version');
    like($err, qr/No cached images/,
	'and still says the images are empty');
    unlike($err, qr/Distfiles/, 'an empty distfile tree has no line');
}

# The distfile line of cache list: the size against the cap, or the
# size with a note that the cap is off. A distfile never joins the
# per-version grouping, because it carries no version.
{
    my $project = _cache_project("distfile_cache 4G\n");
    _fake_download($project, '7.8/arm64/base78.tgz');
    _fake_distfile($project, 'gmake-4.4.1.tar.gz');

    my $err = _capture_stderr($project, 'cache', 'list');
    like($err, qr/Distfiles: \d+B of 4\.0G/,
	'cache list reports the distfile size and the cap');
    is(scalar(grep { /OpenBSD -/ } split /\n/, $err), 0,
	'no distfile lands in the version grouping');

    my $off = _cache_project();
    _fake_distfile($off, 'gmake-4.4.1.tar.gz');
    $err = _capture_stderr($off, 'cache', 'list');
    like($err, qr/Distfiles: \d+B, caching off/,
	'a tree with a cap of 0 reads as caching off');
}

# cache clear --stale keeps the distfile tree and re-applies the cap;
# a bare clear removes the tree with everything else
{
    my $project = _cache_project("distfile_cache 4G\n");
    _fake_download($project, '7.7/arm64/base77.tgz');
    my $distfile = _fake_distfile($project, 'gmake-4.4.1.tar.gz');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'cache', 'clear', '--stale'),
	0, 'cache clear --stale succeeds');
    ok(-f $distfile, '--stale keeps the distfile tree');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'cache', 'clear'),
	0, 'bare cache clear succeeds');
    ok(!-e $distfile, 'and it removes the distfile tree with the rest');
}

# With a cap of 0 no cap applies to --stale, so the flag keeps the
# whole tree: 0 turns the cache off for new stores, and it must not
# read as "keep nothing" here.
{
    my $project = _cache_project();
    my $distfile = _fake_distfile($project, 'gmake-4.4.1.tar.gz');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'cache', 'clear', '--stale'),
	0, 'cache clear --stale succeeds with a cap of 0');
    ok(-f $distfile, 'and it keeps the distfile tree');
}

# ============================================================
# The mirror subcommand
# ============================================================

# The argument refusals, each with exit code 2
{
    my $project = _cache_project();

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'mirror'), 2,
	'mirror without an action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'mirror', 'frobnicate'),
	2, 'an unknown mirror action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'mirror', 'fetch'),
	2, 'mirror fetch without a file returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'mirror', 'verify', 'extra'),
	2, 'mirror verify with an argument returns EXIT_INVALID_ARGS');
}

# mirror verify over an empty cache exits 0: no manifest is cached,
# so nothing needs a proof, and the verb is idempotent
{
    my $project = _cache_project();
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'mirror', 'verify'),
	0, 'mirror verify over an empty cache exits 0');
}

# An absent public key for the version is a configuration error. The
# share tree holds no key of version 6.0.
{
    my $project = _cache_project();
    open my $fh, '>>', "$project/.fuguvmrc" or die $!;
    print $fh "vm \"old\" {\n";
    print $fh "\tversion 6.0\n";
    print $fh "}\n";
    close $fh;

    my ($code, $out, $err) = _run_captured("--project=$project",
	'--vm', 'old', 'mirror', 'verify');
    is($code, 3, 'an absent release key exits with EXIT_CONFIG_ERROR');
    like($err, qr/openbsd-60-base\.pub/, 'and the diagnostic names the key');
}

# The routing, the removal, and the forced proof, over a signed
# fixture in the project cache
SKIP: {
    my $signify = _find_signify();
    skip 'signify(1) not available', 15 if !defined $signify;

    # fetch routes by the manifests and never guesses: a file of the
    # release manifest reads from the release scope, a file of the
    # source manifest reads from the source scope, and a name that
    # neither holds is a refusal. Every file is cached, so no fetch
    # reaches the network.
    my $project = _signed_project($signify);
    _fake_mirror_file($project, '7.8/arm64/base78.tgz', 'set bytes');
    _fake_mirror_file($project, '7.8/ports.tar.gz', 'tree bytes');

    my ($code, $out, $err) = _run_captured("--project=$project",
	'--quiet', 'mirror', 'fetch', 'base78.tgz');
    is($code, 0, 'fetch resolves a file of the release manifest');
    like($out, qr{7\.8/arm64/base78\.tgz\n$}, 'from the release scope');

    ($code, $out) = _run_captured("--project=$project",
	'--quiet', 'mirror', 'fetch', 'ports.tar.gz');
    is($code, 0, 'fetch resolves a file of the source manifest');
    like($out, qr{7\.8/ports\.tar\.gz\n$}, 'from the source scope');

    ($code, $out, $err) = _run_captured("--project=$project",
	'mirror', 'fetch', 'nonsense.tgz');
    is($code, 1, 'a name that no manifest holds is a refusal');
    like($err, qr/nonsense\.tgz/, 'and the diagnostic names it');
    is($out, '', 'and no path reaches standard output');

    # verify removes a failed file in its own scope only, and it
    # keeps an unknown file. The two scopes share the name
    # base78.tgz: good in the release scope, tampered in the source
    # scope.
    $project = _signed_project($signify, 'base78.tgz');
    my $good = _fake_mirror_file($project, '7.8/arm64/base78.tgz',
	'set bytes');
    my $bad = _fake_mirror_file($project, '7.8/base78.tgz',
	'tampered bytes');
    my $unknown = _fake_mirror_file($project, '7.8/arm64/index.txt',
	'a listing');

    ($code, $out, $err) = _run_captured("--project=$project",
	'mirror', 'verify');
    is($code, 1, 'verify exits 1 when one file failed');
    like($err, qr{source/base78\.tgz}, 'the failed line carries the scope');
    ok(!-f $bad, 'verify removes the failed file');
    ok(-f $good, 'and keeps the same-named file that verified');
    ok(-f $unknown, 'and keeps an unknown file');

    ($code) = _run_captured("--project=$project", 'mirror', 'verify');
    is($code, 0, 'a second run over the healed cache exits 0');

    # The verify verb proves, whatever the verify directive says: a
    # tampered manifest under 'verify no' still fails and leaves the
    # cache.
    $project = _signed_project($signify, undef, "verify no\n");
    my $manifest =
	"$project/cache/proxy/cdn.openbsd.org/pub/OpenBSD/7.8/arm64/SHA256";
    open my $mh, '>>', $manifest or die $!;
    print $mh "# one changed byte\n";
    close $mh;

    ($code, $out, $err) = _run_captured("--project=$project",
	'mirror', 'verify');
    is($code, 1, 'verify proves under a verify no directive');
    like($err, qr{release/SHA256}, 'and reports the failed manifest');
    ok(!-f $manifest, 'and the poisoned manifest left the cache');
}

# clear refuses while a VM runs on a disk that the entry backs
SKIP: {
    my $has_qemu = `which qemu-img 2>/dev/null`;
    skip 'qemu-img not installed', 4 unless $has_qemu;

    my $project = _cache_project();
    my $cache = App::FuguVM::DiskCache->new("$project/cache");
    my $key = '7.8-arm64-cafebabe';

    my $source = "$project/source.qcow2";
    system('qemu-img', 'create', '-f', 'qcow2', $source, '16M') == 0
	or skip 'cannot create a test disk image', 4;
    my $base = $cache->store($key, $source, { root_password => 'pw' });

    # A working disk in this checkout, backed by the cached entry
    my $state_dir = "$project/.fuguvm/state";
    App::FuguVM::Disk->new($state_dir)->create('default', undef, $base);

    # This test process stands in for a live QEMU
    make_path("$state_dir/default");
    open my $pidfh, '>', "$state_dir/default/vm.pid" or die $!;
    print $pidfh "$$\n";
    close $pidfh;

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'cache', 'clear'),
	5, 'clear refuses with EXIT_VM_RUNNING while the VM runs');
    ok(defined $cache->lookup($key), 'the entry survives the refusal');

    # Once the VM stops, removal proceeds. A warning reports the orphan.
    unlink "$state_dir/default/vm.pid";
    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'cache', 'clear'),
	0, 'clear proceeds once the VM is stopped');
    is($cache->lookup($key), undef, 'the entry is gone');
}

# ============================================================
# Snapshot subcommand
# ============================================================

# Usage and name validation
{
    my $project = _cache_project();

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", 'snapshot'), 2,
	'snapshot without an action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", 'snapshot', 'frobnicate'), 2,
	'unknown snapshot action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", 'snapshot', 'save'), 2,
	'snapshot save without a name returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", 'snapshot', 'save', '../x'),
	2, 'a name with a path separator is rejected');
}

# Missing snapshots report a distinct, scriptable exit code. Thus
# callers can do 'snapshot restore || provision-from-scratch'.
{
    my $project = _cache_project();
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'restore', 'deps'),
	11, 'restoring a missing snapshot returns EXIT_SNAPSHOT_NOT_FOUND');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'rm', 'deps'),
	11, 'removing a missing snapshot returns the same code');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'list'),
	0, 'listing with nothing cached still succeeds');
}

# Save, restore, and the refusals, over a real backing chain
SKIP: {
    my $has_qemu = `which qemu-img 2>/dev/null`;
    skip 'qemu-img not installed', 12 unless $has_qemu;

    my $project = _cache_project();
    my $state_dir = "$project/.fuguvm/state";
    my $cache = App::FuguVM::DiskCache->new("$project/cache");
    my $key = $cache->key(App::FuguVM::Config->new($project)->load_vm('default'));

    my $source = "$project/source.qcow2";
    system('qemu-img', 'create', '-f', 'qcow2', $source, '16M') == 0
	or skip 'cannot create a test disk image', 12;

    # A snapshot of a standalone disk is not possible. Say so. Do
    # not crash.
    my $disk = App::FuguVM::Disk->new($state_dir);
    $disk->create('default', '16M');
    my $state = App::FuguVM::State->new($state_dir, 'default');
    $state->mark_installed('arm64');

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'save', 'deps'),
	1, 'a standalone disk is a diagnosed error, not a crash');

    # Rebuild the disk as an overlay on a cached base
    my $base = $cache->store($key, $source, { root_password => 'pw' });
    unlink $disk->path('default');
    $disk->create('default', undef, $base);

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'save', 'deps'),
	0, 'save succeeds on a disk backed by a cached image');
    ok(defined $cache->snapshot_lookup($key, 'deps'), 'the snapshot exists');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'list'),
	0, 'list succeeds');

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'restore', 'deps'),
	0, 'restore succeeds');
    is($disk->backing_file('default'),
	$cache->snapshot_path($key, 'deps'),
	'restore actually replaced the disk with an overlay on the snapshot');

    # Restore from nothing. No disk and no state exist, as in a
    # fresh checkout.
    unlink $disk->path('default');
    unlink "$state_dir/default/status";
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'restore', 'deps'),
	0, 'restore works with no disk and no state');

    my $reseeded = App::FuguVM::State->new($state_dir, 'default');
    ok($reseeded->is_installed, 'restore reseeds installed state');
    is($reseeded->get_root_password, 'pw',
	'restore reseeds the root password from the base');

    # A running VM refuses both save and restore
    open my $pidfh, '>', "$state_dir/default/vm.pid" or die $!;
    print $pidfh "$$\n";
    close $pidfh;

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'save', 'deps'),
	5, 'save refuses while the VM is running');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'restore', 'deps'),
	5, 'restore refuses while the VM is running');
    unlink "$state_dir/default/vm.pid";

    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'rm', 'deps'),
	0, 'rm succeeds');
}

# --names is the scriptable listing. It writes bare names on stdout,
# where a shell can read them. It does not go through the stderr logger.
SKIP: {
    my $has_qemu = `which qemu-img 2>/dev/null`;
    skip 'qemu-img not installed', 4 unless $has_qemu;

    my $project = _cache_project();
    my $cache = App::FuguVM::DiskCache->new("$project/cache");
    my $key = $cache->key(App::FuguVM::Config->new($project)->load_vm('default'));

    my $source = "$project/source.qcow2";
    system('qemu-img', 'create', '-f', 'qcow2', $source, '16M') == 0
	or skip 'cannot create a test disk image', 4;
    my $base = $cache->store($key, $source, { root_password => 'pw' });
    App::FuguVM::Disk->new("$project/.fuguvm/state")
	->create('default', undef, $base);
    App::FuguVM::State->new("$project/.fuguvm/state", 'default')->mark_installed('arm64');

    is(_capture_stdout($project, 'snapshot', 'list', '--names'), '',
	'nothing on stdout when there are no snapshots');

    App::FuguVM::CLI->run("--project=$project", '--quiet',
	'snapshot', 'save', 'deps-aaa');
    App::FuguVM::CLI->run("--project=$project", '--quiet',
	'snapshot', 'save', 'deps-bbb');

    is(_capture_stdout($project, 'snapshot', 'list', '--names'),
	"deps-aaa\ndeps-bbb\n", 'one bare name per line, sorted');
    is(_capture_stdout($project, 'snapshot', 'list'), '',
	'the human listing writes nothing to stdout');

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'snapshot', 'list', '--bogus'),
	2, 'an unknown list option returns EXIT_INVALID_ARGS');
}

# ============================================================
# Image export
# ============================================================

# Usage errors match the style of the other subcommands
{
    my $project = _cache_project();

    local $SIG{__WARN__} = sub {};
    is(App::FuguVM::CLI->run("--project=$project", '--quiet', 'image'), 2,
	'image without an action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'image', 'frobnicate'), 2,
	'an unknown image action returns EXIT_INVALID_ARGS');
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'image', 'export'), 2,
	'image export without a path returns EXIT_INVALID_ARGS');

    my ($code, $out, $err) = _run_captured("--project=$project",
	'image', 'export', "$project/out.qcow2", '--format=vmdk');
    is($code, 2, 'an unknown --format value returns EXIT_INVALID_ARGS');
    like($err, qr/qcow2.*raw/, 'and the diagnostic names both formats');
}

# The refusals and the export itself, over a real backing chain
SKIP: {
    my $has_qemu = `which qemu-img 2>/dev/null`;
    skip 'qemu-img not installed', 15 unless $has_qemu;

    my $project = _cache_project();
    my $state_dir = "$project/.fuguvm/state";
    my $target = "$project/out.qcow2";

    local $SIG{__WARN__} = sub {};

    # A guest with no disk
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'image', 'export', $target),
	1, 'a guest with no disk exits 1');

    # A working disk on a cached base
    my $cache = App::FuguVM::DiskCache->new("$project/cache");
    my $key = $cache->key(
	App::FuguVM::Config->new($project)->load_vm('default'));
    my $source = "$project/source.qcow2";
    system('qemu-img', 'create', '-f', 'qcow2', $source, '16M') == 0
	or skip 'cannot create a test disk image', 14;
    my $base = $cache->store($key, $source, { root_password => 'pw' });
    App::FuguVM::Disk->new($state_dir)->create('default', undef, $base);
    App::FuguVM::State->new($state_dir, 'default')->mark_installed('arm64');

    # A running guest refuses with 5. The test writes its own
    # process ID, so Fugu::Process->is_alive reports a live guest.
    make_path("$state_dir/default");
    open my $pidfh, '>', "$state_dir/default/vm.pid" or die $!;
    print $pidfh "$$\n";
    close $pidfh;
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'image', 'export', $target),
	5, 'an export of a running guest exits 5');
    unlink "$state_dir/default/vm.pid";

    # The tool creates no directory for the operator
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'image', 'export', "$project/absent/out.qcow2"),
	1, 'an absent parent directory exits 1');

    # The export writes the base image and reports it
    my ($code, $out) = _run_captured("--project=$project", '--quiet',
	'image', 'export', $target);
    is($code, 0, 'the export succeeds');
    ok(-f $target, 'and the file exists');
    like($out, qr/^bytes: [0-9]+$/m, 'the report holds the byte count');
    like($out, qr/^format: qcow2$/m, 'and the default format');
    like($out, qr/^key: \Q$key\E$/m, 'and the cache key of the source');
    like($out, qr/^path: .*out\.qcow2$/m, 'and the written path');
    like($out, qr/^source: \Q$base\E$/m, 'and the source image');
    like(`qemu-img info "$target"`, qr/file format: qcow2/,
	'the written file is a qcow2');
    unlike(`qemu-img info "$target"`, qr/backing file/,
	'with no backing file');

    # An existing target stays unchanged
    my $before = -s $target;
    is(App::FuguVM::CLI->run("--project=$project", '--quiet',
	    'image', 'export', $target),
	1, 'a second export onto the same path exits 1');
    is(-s $target, $before, 'and the file stays unchanged');

    # The raw form
    ($code) = _run_captured("--project=$project", '--quiet',
	'image', 'export', "$project/out.raw", '--format=raw');
    is($code, 0, 'a raw export succeeds');
    like(`qemu-img info "$project/out.raw"`, qr/file format: raw/,
	'and writes the raw format');
}

# A byte count for a person to read is presentation, so the CLI owns
# it. The cases came with the function from Fugu::Timeout.
subtest '_format_size' => sub {
	my $f = \&App::FuguVM::CLI::_format_size;

	is( $f->(0),       '0B',    'zero' );
	is( $f->(512),     '512B',  'bytes' );
	is( $f->(1023),    '1023B', 'just under 1K' );
	is( $f->(1024),    '1.0K',  'one kilobyte' );
	is( $f->(1536),    '1.5K',  'one and a half' );
	is( $f->(1024**2), '1.0M',  'one megabyte' );
	is( $f->(1024**3), '1.0G',  'one gigabyte' );
	is( $f->(1024**4), '1.0T',  'one terabyte' );
	is( $f->(1024**5), '1024.0T',
		'past the largest unit it keeps counting' );
	is( $f->(undef), '?',
		'a size nobody could measure is not a size of zero' );
};

done_testing();

# A project whose cache_dir points inside the project. Thus the tests
# never touch the developer's real ~/.cache/fuguvm. The optional
# argument appends top-level configuration lines.
sub _cache_project
{
    my ($extra) = @_;
    my $project = tempdir(CLEANUP => 1);
    make_path("$project/.fuguvm/vms", "$project/.fuguvm/state");

    open my $fh, '>', "$project/.fuguvmrc" or die $!;
    print $fh "cache_dir $project/cache\n";
    print $fh "state_dir .fuguvm/state\n";
    print $fh "default_vm default\n";
    print $fh $extra if defined $extra;
    print $fh "vm \"default\" {\n";
    print $fh "\tversion 7.8\n";
    print $fh "\tdisk_size 8G\n";
    print $fh "}\n";
    close $fh;

    return $project;
}

# Run a command with both streams captured, and return the exit
# code, the stdout text and the stderr text. Thus scriptable output
# cannot mix with the TAP stream of this test. The capture goes
# through real files, never through an in-memory scalar: a scalar
# handle has no file descriptor, and the output of a child process
# would then land wherever descriptor 1 points at that moment.
sub _run_captured
{
    my (@args) = @_;
    my $dir = tempdir(CLEANUP => 1);

    open my $saved_out, '>&', \*STDOUT or die $!;
    open STDOUT, '>', "$dir/out" or die $!;
    open my $saved_err, '>&', \*STDERR or die $!;
    open STDERR, '>', "$dir/err" or die $!;

    my $code = App::FuguVM::CLI->run(@args);

    open STDOUT, '>&', $saved_out or die $!;
    close $saved_out;
    open STDERR, '>&', $saved_err or die $!;
    close $saved_err;

    return ($code, _slurp("$dir/out"), _slurp("$dir/err"));
}

# Run a command and capture stdout. This separates the scriptable
# output from the logger's stderr.
sub _capture_stdout
{
    my ($project, @args) = @_;
    my (undef, $out) =
	_run_captured("--project=$project", '--quiet', @args);

    return $out;
}

# The logger writes to stderr. Thus this helper captures the human
# listing apart from the scriptable output above.
sub _capture_stderr
{
    my ($project, @args) = @_;
    my (undef, undef, $err) = _run_captured("--project=$project", @args);

    return $err;
}

# _slurp($path):
#	The whole file as text.
sub _slurp
{
    my ($path) = @_;

    open my $fh, '<', $path or die "Cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh;

    return $text;
}

# A cached proxy download, seeded on disk and not through store().
# store() uses cache_path(), which wants URI, a develop dependency.
sub _fake_download
{
    my ($project, $rel) = @_;
    my $dir = "$project/cache/proxy/cdn.openbsd.org/pub/OpenBSD/$rel";

    $dir =~ m{\A(.*)/} and make_path($1);
    open my $fh, '>', $dir or die $!;
    print $fh 'not a real file set';
    close $fh;

    return $dir;
}

# _find_signify():
#	The signify command on PATH, in the search order of
#	Fugu::Signify, or undef.
sub _find_signify
{
    for my $name (qw(signify-openbsd signify)) {
	for my $dir (split /:/, $ENV{PATH} // '') {
	    next unless length $dir;
	    my $path = "$dir/$name";
	    return $path if -f $path && -x $path;
	}
    }

    return undef;
}

# _fake_mirror_file($project, $relative, $bytes):
#	One cached mirror file, seeded on disk at its mirror path.
sub _fake_mirror_file
{
    my ($project, $rel, $bytes) = @_;
    my $path = "$project/cache/proxy/cdn.openbsd.org/pub/OpenBSD/$rel";

    $path =~ m{\A(.*)/} and make_path($1);
    open my $fh, '>', $path or die $!;
    print $fh $bytes;
    close $fh;

    return $path;
}

# _signed_project($signify, $source_extra, $extra_config):
#	A cache project whose signify_dir holds a fresh key pair under
#	the 7.8 release name, with a signed manifest seeded in each
#	scope. The release manifest names base78.tgz with the digest
#	of 'set bytes'. The source manifest names ports.tar.gz with
#	the digest of 'tree bytes', and $source_extra, when given,
#	with the digest of 'set bytes'.
sub _signed_project
{
    my ($signify, $source_extra, $extra_config) = @_;

    require Digest::SHA;

    my $project = _cache_project(($extra_config // '')
	. "signify_dir keys\n");
    make_path("$project/keys");

    system($signify, '-G', '-n',
	'-p', "$project/keys/key.pub",
	'-s', "$project/keys/key.sec") == 0
	or die "signify -G failed\n";
    rename "$project/keys/key.pub", "$project/keys/openbsd-78-base.pub"
	or die "cannot rename the public key: $!\n";

    my %manifest = (
	'arm64/SHA256' => { 'base78.tgz' => 'set bytes' },
	'SHA256'       => {
	    'ports.tar.gz' => 'tree bytes',
	    (defined $source_extra ? ($source_extra => 'set bytes') : ()),
	},
    );
    for my $rel (sort keys %manifest) {
	my $lines = '';
	my $files = $manifest{$rel};
	for my $name (sort keys %$files) {
	    my $digest = Digest::SHA->new(256);
	    $digest->add($files->{$name});
	    $lines .= sprintf "SHA256 (%s) = %s\n", $name,
		$digest->hexdigest;
	}

	my $path = _fake_mirror_file($project, "7.8/$rel", $lines);
	system($signify, '-S', '-s', "$project/keys/key.sec",
	    '-m', $path, '-x', "$path.sig") == 0
	    or die "signify -S failed\n";
    }

    return $project;
}

# A cached distfile, seeded on disk like _fake_download
sub _fake_distfile
{
    my ($project, $name) = @_;

    my $path =
	"$project/cache/proxy/cdn.openbsd.org/pub/OpenBSD/distfiles/$name";
    $path =~ m{\A(.*)/} and make_path($1);
    open my $fh, '>', $path or die $!;
    print $fh 'not a real distfile';
    close $fh;

    return $path;
}

# A complete-looking cache entry without the cost of a real image
sub _fake_entry
{
    my ($cache, $key) = @_;
    my $dir = $cache->entry_dir($key);
    make_path($dir);

    open my $bh, '>', "$dir/base.qcow2" or die $!;
    print $bh 'not a real image';
    close $bh;

    open my $mh, '>', "$dir/meta.json" or die $!;
    print $mh qq({"key":"$key","created_at":1,"root_password":"pw"});
    close $mh;

    return $dir;
}
