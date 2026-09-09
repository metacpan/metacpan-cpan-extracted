#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The mirror of one guest: the URLs, the key resolution and the
# verification. The signify(1) subtests generate their own key pair,
# and each one skips when the command is absent.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Digest::SHA ();
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Fugu::TestLog;

use_ok('App::FuguVM::Mirror');
use_ok('App::FuguVM::Proxy');

my $MIRROR_DIR = 'cdn.openbsd.org/pub/OpenBSD';

# The mirror facts have one home
{
    my $mirror = _mirror(tempdir(CLEANUP => 1));

    is($mirror->version, '7.8', 'version returns the mirror version');
    is($mirror->url('base78.tgz'),
	'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz',
	'url builds the URL of the architecture directory');
    is($mirror->source_url('ports.tar.gz'),
	'https://cdn.openbsd.org/pub/OpenBSD/7.8/ports.tar.gz',
	'source_url builds the URL of the version directory');
}

# A construction without a necessary argument is a programming error
{
    my $cache = App::FuguVM::Proxy::Cache->new(tempdir(CLEANUP => 1));
    my %full = (cache => $cache, version => '7.8', arch => 'arm64');

    for my $absent (qw(cache version arch)) {
	my %args = %full;
	delete $args{$absent};
	ok(!eval { App::FuguVM::Mirror->new(%args); 1 },
	    "new without $absent dies");
	like($@, qr/$absent/, 'and the death names the argument');
    }
}

# The key resolution: the version names the file, and keys_dir wins
# over every other directory
{
    my $keys_dir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$keys_dir/openbsd-78-base.pub" or die $!;
    print $fh "untrusted comment: a stand-in key\nRWTteststring\n";
    close $fh;

    my $mirror = _mirror(tempdir(CLEANUP => 1), keys_dir => $keys_dir);
    is($mirror->key_path, "$keys_dir/openbsd-78-base.pub",
	'key_path maps 7.8 to openbsd-78-base.pub in keys_dir');

    # The share tree of this checkout also holds the 7.8 key, so the
    # answer above proves that keys_dir wins over it.
    ok(-f "$RealBin/../../share/fuguvm/signify/openbsd-78-base.pub",
	'the share tree holds the shipped key');
}

# The shipped key of the default release resolves from the share tree
{
    my $mirror = _mirror(tempdir(CLEANUP => 1));
    like($mirror->key_path, qr{share/fuguvm/signify/openbsd-78-base\.pub$},
	'key_path falls back to the share tree');
}

# An absent key is a diagnosed miss that names the file and each
# directory. Version 9.9 has no key in any directory.
{
    my $keys_dir = tempdir(CLEANUP => 1);
    my $cache_dir = tempdir(CLEANUP => 1);
    my $mirror = _mirror($cache_dir,
	version => '9.9', keys_dir => $keys_dir);

    is($mirror->key_path, undef, 'key_path returns undef without a key');
    like($mirror->error, qr/openbsd-99-base\.pub/, 'error names the file');
    like($mirror->error, qr/\Q$keys_dir\E/, 'error names keys_dir');
    like($mirror->error, qr{share/fuguvm/signify},
	'error names the share directory');

    # manifest stops on the key, before any fetch
    is($mirror->manifest('release'), undef,
	'manifest returns undef when the key does not resolve');
    like($mirror->error, qr/openbsd-99-base\.pub/,
	'and the reason is the key');
    is(scalar @{ _cache($cache_dir)->list }, 0, 'and it fetched nothing');
}

# ensure returns the cached path with no fetch when the cache holds
# the file. The verification runs on the way into the cache, not on
# every read.
{
    my $cache_dir = tempdir(CLEANUP => 1);
    my $seeded = _seed($cache_dir, '7.8/arm64/base78.tgz', 'set bytes');

    my $mirror = _mirror($cache_dir);
    is($mirror->ensure('release', 'base78.tgz'), $seeded,
	'ensure returns the cached path with no fetch');
}

# With verify set to 0, ensure stores the file and logs one warning,
# and the proof methods refuse: a method must not report a proof that
# it did not make.
{
    my $cache_dir = tempdir(CLEANUP => 1);
    my $mirror = _mirror($cache_dir, verify => 0);

    my $warned = _capture_stderr(sub {
	no warnings 'redefine';
	local *App::FuguVM::Mirror::fetch =
	    sub ($, $) { _temp_file('unproven bytes') };
	is($mirror->ensure('release', 'base78.tgz'),
	    _cache($cache_dir)->cache_path(
		'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz'),
	    'ensure with verify 0 stores the file');
    });
    like($warned, qr/unproven/i, 'and it logs one warning');

    is($mirror->verify_file('release', 'base78.tgz', '/tmp/x'), undef,
	'verify_file with verify 0 returns undef');
    like($mirror->error, qr/verification is off/, 'with a reason');
    is($mirror->manifest('release'), undef,
	'manifest with verify 0 returns undef');
    like($mirror->error, qr/verification is off/, 'with the same reason');
}

# The signify(1) subtests. Each one generates its own key pair, writes
# a manifest in the sha256(1) line form, signs it, and seeds the
# cache at the mirror paths. The manifests are then local, so the
# module fetches nothing.
my $SIGNIFY = _find_signify();

subtest 'the release manifest and the file proofs' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    my ($cache_dir, $keys_dir) = _signed_fixture(
	release => { 'base78.tgz' => 'good bytes' });
    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);

    my $manifest = $mirror->manifest('release');
    ok(defined $manifest, 'manifest returns the path for a good signature');
    is($manifest, _cache($cache_dir)->cache_path(
	    'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/SHA256'),
	'and the path is the cached manifest');
    is_deeply($mirror->manifest_names('release'), ['base78.tgz'],
	'manifest_names lists the named files');

    my $good = _write_file($cache_dir, 'good.local', 'good bytes');
    is($mirror->verify_file('release', 'base78.tgz', $good), 1,
	'verify_file returns 1 for a matching digest');

    my $bad = _write_file($cache_dir, 'bad.local', 'other bytes');
    is($mirror->verify_file('release', 'base78.tgz', $bad), undef,
	'verify_file returns undef for a digest that does not match');
    like($mirror->error, qr/base78\.tgz/, 'and the reason names the file');

    is($mirror->verify_file('release', 'absent.tgz', $good), undef,
	'verify_file returns undef for a name the manifest does not hold');
};

subtest 'a repeated identical manifest line changes nothing' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    # The real SHA256 of the OpenBSD 7.8 amd64 directory repeats the
    # install image lines. The digest check must accept a duplicate
    # whose digest is identical, and it must refuse a duplicate name
    # with two digests.
    my $work = tempdir(CLEANUP => 1);
    my $keys_dir = tempdir(CLEANUP => 1);
    my $cache_dir = tempdir(CLEANUP => 1);

    system($SIGNIFY, '-G', '-n',
	'-p', "$work/key.pub", '-s', "$work/key.sec") == 0
	or die "signify -G failed\n";
    require File::Copy;
    File::Copy::copy("$work/key.pub", "$keys_dir/openbsd-78-base.pub")
	or die "cannot copy the public key: $!\n";

    my $digest = Digest::SHA->new(256);
    $digest->add('good bytes');
    my $line = sprintf "SHA256 (base78.tgz) = %s\n", $digest->hexdigest;

    my $local = "$work/SHA256";
    open my $fh, '>', $local or die $!;
    print $fh $line, $line;
    close $fh;
    system($SIGNIFY, '-S', '-s', "$work/key.sec",
	'-m', $local, '-x', "$local.sig") == 0
	or die "signify -S failed\n";

    _seed($cache_dir, '7.8/arm64/SHA256', $line . $line);
    _seed($cache_dir, '7.8/arm64/SHA256.sig', _slurp("$local.sig"));

    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);
    is_deeply($mirror->manifest_names('release'), ['base78.tgz'],
	'the duplicate identical line reads as one name');

    my $good = _write_file($cache_dir, 'good.local', 'good bytes');
    is($mirror->verify_file('release', 'base78.tgz', $good), 1,
	'and the file verifies against it');

    # A duplicate name with two digests is a broken manifest
    my $other = Digest::SHA->new(256);
    $other->add('other bytes');
    my $conflict =
	$line . sprintf "SHA256 (base78.tgz) = %s\n", $other->hexdigest;
    open $fh, '>', $local or die $!;
    print $fh $conflict;
    close $fh;
    system($SIGNIFY, '-S', '-s', "$work/key.sec",
	'-m', $local, '-x', "$local.sig") == 0
	or die "signify -S failed\n";
    _seed($cache_dir, '7.8/SHA256', $conflict);
    _seed($cache_dir, '7.8/SHA256.sig', _slurp("$local.sig"));

    is($mirror->verify_file('source', 'base78.tgz', $good), undef,
	'a duplicate name with two digests is a refusal');
    like($mirror->error, qr/two digests/, 'and the reason says so');
};

subtest 'a tampered manifest fails its signature' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    my ($cache_dir, $keys_dir) = _signed_fixture(
	release => { 'base78.tgz' => 'good bytes' });

    my $manifest = "$cache_dir/proxy/$MIRROR_DIR/7.8/arm64/SHA256";
    open my $fh, '>>', $manifest or die $!;
    print $fh "# one changed byte\n";
    close $fh;

    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);
    is($mirror->manifest('release'), undef,
	'manifest returns undef for a tampered manifest');
    like($mirror->error, qr/SHA256/, 'and error names the file');
};

subtest 'ensure verifies before it stores' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    my ($cache_dir, $keys_dir) = _signed_fixture(
	release => { 'base78.tgz' => 'good bytes' });
    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);

    {
	no warnings 'redefine';
	local *App::FuguVM::Mirror::fetch =
	    sub ($, $) { _temp_file('tampered bytes') };
	is($mirror->ensure('release', 'base78.tgz'), undef,
	    'ensure refuses a file that fails its digest');
	like($mirror->error, qr/base78\.tgz/, 'and names the file');
	is(_cache($cache_dir)->lookup(
		'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz'),
	    undef, 'and the cache holds no such file');
    }

    {
	no warnings 'redefine';
	local *App::FuguVM::Mirror::fetch =
	    sub ($, $) { _temp_file('good bytes') };
	my $path = $mirror->ensure('release', 'base78.tgz');
	ok(defined $path, 'ensure stores a file that verifies');
	ok(-f $path, 'and the cached file exists');
    }
};

subtest 'verify_cache classifies every cached file' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    my ($cache_dir, $keys_dir) = _signed_fixture(release => {
	'base78.tgz' => 'good bytes',
	'comp78.tgz' => 'other good bytes',
    });

    _seed($cache_dir, '7.8/arm64/base78.tgz', 'good bytes');
    _seed($cache_dir, '7.8/arm64/comp78.tgz', 'tampered bytes');
    _seed($cache_dir, '7.8/arm64/index.txt', 'a listing');

    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);
    my $report = $mirror->verify_cache;

    ok(defined $report, 'verify_cache returns a report');
    is_deeply($report->{ok}, [ { scope => 'release', name => 'base78.tgz' } ],
	'a good file is ok');
    is_deeply($report->{failed},
	[ { scope => 'release', name => 'comp78.tgz' } ],
	'a bad file is failed, with its scope');
    is_deeply($report->{unknown},
	[ { scope => 'release', name => 'index.txt' } ],
	'a file that no manifest names is unknown');
};

subtest 'verify_cache never skips a cached file' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    # A scope whose files are cached with no manifest is what a
    # 'verify no' run produces. The files read as unknown, never as
    # a silent pass: fetching the manifest here fails, because the
    # URL of this test resolves nowhere.
    my $cache_dir = tempdir(CLEANUP => 1);
    my $keys_dir = tempdir(CLEANUP => 1);
    _seed($cache_dir, '7.8/arm64/base78.tgz', 'unproven bytes');

    open my $fh, '>', "$keys_dir/openbsd-78-base.pub" or die $!;
    print $fh "untrusted comment: a stand-in key\nRWTteststring\n";
    close $fh;

    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);
    {
	no warnings 'redefine';
	local *App::FuguVM::Mirror::fetch = sub ($self, $) {
	    $self->{error} = 'download failed in this test';
	    return;
	};
	my $report = $mirror->verify_cache;
	ok(defined $report, 'verify_cache still returns a report');
	is_deeply($report->{unknown},
	    [ { scope => 'release', name => 'base78.tgz' } ],
	    'the unproven file reads as unknown, not as a pass');
	is_deeply($report->{ok}, [], 'and nothing reads as ok');
    }
};

subtest 'a failed manifest pair leaves the cache' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    my ($cache_dir, $keys_dir) = _signed_fixture(
	release => { 'base78.tgz' => 'good bytes' });
    _seed($cache_dir, '7.8/arm64/base78.tgz', 'good bytes');

    # Tamper the cached manifest, so its signature fails.
    my $manifest = "$cache_dir/proxy/$MIRROR_DIR/7.8/arm64/SHA256";
    open my $fh, '>>', $manifest or die $!;
    print $fh "# one changed byte\n";
    close $fh;

    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);
    my $report = $mirror->verify_cache;

    ok(defined $report, 'verify_cache returns a report');
    is_deeply($report->{failed},
	[ { scope => 'release', name => 'SHA256' } ],
	'the failed manifest reads as failed');
    is_deeply($report->{unknown},
	[ { scope => 'release', name => 'base78.tgz' } ],
	'and its files read as unknown');
    ok(!-f $manifest, 'the poisoned manifest left the cache');
    ok(!-f "$manifest.sig", 'with its signature');
};

subtest 'the source manifest verifies the version directory' => sub {
    plan skip_all => 'signify(1) not available' if !defined $SIGNIFY;

    my ($cache_dir, $keys_dir) = _signed_fixture(
	source => { 'ports.tar.gz' => 'the ports tree' });
    _seed($cache_dir, '7.8/ports.tar.gz', 'the ports tree');

    my $mirror = _mirror($cache_dir, keys_dir => $keys_dir);
    ok(defined $mirror->manifest('source'),
	'manifest(source) verifies the manifest of the version directory');

    my $report = $mirror->verify_cache;
    is_deeply($report->{ok}, [ { scope => 'source', name => 'ports.tar.gz' } ],
	'and verify_cache proves the source tarball');
};

done_testing();

# _mirror($cache_dir, %args):
#	A mirror over a fresh cache, with the test defaults.
sub _mirror
{
    my ($cache_dir, %args) = @_;

    return App::FuguVM::Mirror->new(
	cache   => _cache($cache_dir),
	version => '7.8',
	arch    => 'arm64',
	%args,
    );
}

# _cache($cache_dir):
#	The proxy cache over a directory.
sub _cache
{
    my ($cache_dir) = @_;

    return App::FuguVM::Proxy::Cache->new($cache_dir);
}

# _seed($cache_dir, $relative, $bytes):
#	Write one cached file at its mirror path.
sub _seed
{
    my ($cache_dir, $rel, $bytes) = @_;
    my $path = "$cache_dir/proxy/$MIRROR_DIR/$rel";

    $path =~ m{\A(.*)/} and make_path($1);
    open my $fh, '>', $path or die "open $path: $!";
    print $fh $bytes;
    close $fh;

    return $path;
}

# _write_file($dir, $name, $bytes):
#	Write one plain file outside the cache.
sub _write_file
{
    my ($dir, $name, $bytes) = @_;
    my $path = "$dir/$name";

    open my $fh, '>', $path or die "open $path: $!";
    print $fh $bytes;
    close $fh;

    return $path;
}

# _temp_file($bytes):
#	A File::Temp that holds the bytes, as fetch would return.
sub _temp_file
{
    my ($bytes) = @_;

    require File::Temp;
    my $tmp = File::Temp->new;
    print $tmp $bytes;
    $tmp->flush;

    return $tmp;
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

# _signed_fixture(%scopes):
#	A cache directory and a keys directory. Each scope maps file
#	names to contents; the fixture writes the manifest of the
#	scope, signs it under a fresh key pair, and seeds both into
#	the cache at their mirror paths. The public key lands in the
#	keys directory under the name of the 7.8 release.
sub _signed_fixture
{
    my (%scopes) = @_;

    my $cache_dir = tempdir(CLEANUP => 1);
    my $keys_dir = tempdir(CLEANUP => 1);
    my $work = tempdir(CLEANUP => 1);

    # signify -G wants one basename for the pair, so the pair lands
    # in the work directory and the public half moves to the release
    # name.
    system($SIGNIFY, '-G', '-n',
	'-p', "$work/key.pub", '-s', "$work/key.sec") == 0
	or die "signify -G failed\n";
    require File::Copy;
    File::Copy::copy("$work/key.pub", "$keys_dir/openbsd-78-base.pub")
	or die "cannot copy the public key: $!\n";

    for my $scope (sort keys %scopes) {
	my $files = $scopes{$scope};
	my $dir = $scope eq 'release' ? '7.8/arm64' : '7.8';

	my $manifest = '';
	for my $name (sort keys %$files) {
	    my $digest = Digest::SHA->new(256);
	    $digest->add($files->{$name});
	    $manifest .= sprintf "SHA256 (%s) = %s\n",
		$name, $digest->hexdigest;
	}

	my $local = "$work/SHA256.$scope";
	open my $fh, '>', $local or die $!;
	print $fh $manifest;
	close $fh;

	system($SIGNIFY, '-S', '-s', "$work/key.sec",
	    '-m', $local, '-x', "$local.sig") == 0
	    or die "signify -S failed\n";

	_seed($cache_dir, "$dir/SHA256", $manifest);
	_seed($cache_dir, "$dir/SHA256.sig", _slurp("$local.sig"));
    }

    return ($cache_dir, $keys_dir);
}

# _slurp($path):
#	The whole file as bytes.
sub _slurp
{
    my ($path) = @_;

    open my $fh, '<', $path or die "read $path: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;

    return $bytes;
}

# _capture_stderr($code):
#	Run the code with the process default logger on standard
#	error, capture the stream, and put the quiet default back.
sub _capture_stderr
{
    my ($code) = @_;
    my $dir = tempdir(CLEANUP => 1);

    Fugu::TestLog->stderr;
    open my $saved, '>&', \*STDERR or die $!;
    open STDERR, '>', "$dir/err" or die $!;

    $code->();

    open STDERR, '>&', $saved or die $!;
    close $saved;
    Fugu::TestLog->quiet;

    return _slurp("$dir/err");
}
