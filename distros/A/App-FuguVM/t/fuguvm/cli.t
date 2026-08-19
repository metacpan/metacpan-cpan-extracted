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
    $state->mark_installed;

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
    App::FuguVM::State->new("$project/.fuguvm/state", 'default')->mark_installed;

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
# never touch the developer's real ~/.cache/fuguvm.
sub _cache_project
{
    my $project = tempdir(CLEANUP => 1);
    make_path("$project/.fuguvm/vms", "$project/.fuguvm/state");

    open my $fh, '>', "$project/.fuguvmrc" or die $!;
    print $fh "cache_dir $project/cache\n";
    print $fh "state_dir .fuguvm/state\n";
    print $fh "default_vm default\n";
    print $fh "vm \"default\" {\n";
    print $fh "\tversion 7.8\n";
    print $fh "\tdisk_size 8G\n";
    print $fh "}\n";
    close $fh;

    return $project;
}

# Run a command and capture stdout. This separates the scriptable
# output from the logger's stderr.
sub _capture_stdout
{
    my ($project, @args) = @_;
    my $out = '';

    open my $saved, '>&', \*STDOUT or die $!;
    close STDOUT;
    open STDOUT, '>', \$out or die $!;

    App::FuguVM::CLI->run("--project=$project", '--quiet', @args);

    close STDOUT;
    open STDOUT, '>&', $saved or die $!;
    close $saved;

    return $out;
}

# The logger writes to stderr. Thus this helper captures the human
# listing apart from the scriptable output above.
sub _capture_stderr
{
    my ($project, @args) = @_;
    my $err = '';

    open my $saved, '>&', \*STDERR or die $!;
    close STDERR;
    open STDERR, '>', \$err or die $!;

    App::FuguVM::CLI->run("--project=$project", @args);

    close STDERR;
    open STDERR, '>&', $saved or die $!;
    close $saved;

    return $err;
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
