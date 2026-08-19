#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Path qw(make_path);
use File::Temp qw(tempdir);

BEGIN {
	eval { require JSON::XS; 1 }
	    or plan skip_all => 'JSON::XS not available';
}

use_ok('App::FuguVM::DiskCache');

my $HAS_QEMU_IMG = defined qx{sh -c 'command -v qemu-img 2>/dev/null'}
    && $? == 0
    && qx{sh -c 'command -v qemu-img 2>/dev/null'} ne '';

my %CONFIG = (
	name         => 'default',
	version      => '7.8',
	disk_size    => '8G',
	memory       => 2048,
	ssh_port     => 2222,
	console_port => 4444,
);

# Construction and layout
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	is( $cache->installed_dir, "$tmp/installed",
		'entries live under installed/ in the configured path' );
	is( $cache->entry_dir('k'), "$tmp/installed/k", 'entry_dir' );
	is( $cache->base_path('k'), "$tmp/installed/k/base.qcow2",
		'base_path' );
}

# Tilde expansion, like App::FuguVM::Miniroot
{
	local $ENV{HOME} = '/home/somebody';
	my $cache = App::FuguVM::DiskCache->new('~/.cache/fuguvm');
	is( $cache->installed_dir, '/home/somebody/.cache/fuguvm/installed',
		'leading ~ is expanded' );
}

# Key derivation: shape, stability, and what does and does not rotate it
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	my $key = $cache->key( \%CONFIG );
	ok( defined $key, 'key derived from a VM configuration' );
	like( $key, qr/^7\.8-arm64-[0-9a-f]{8}$/,
		'key is <version>-<arch>-<hash8>' );

	is( $cache->key( \%CONFIG ), $key, 'key is stable across calls' );

	my %same = ( %CONFIG, memory => 8192, ssh_port => 3333 );
	is( $cache->key( \%same ), $key,
		'memory and ports do not shape the disk, so the key holds' );

	my %bigger = ( %CONFIG, disk_size => '16G' );
	isnt( $cache->key( \%bigger ), $key, 'disk_size rotates the key' );

	my %older = ( %CONFIG, version => '7.7' );
	isnt( $cache->key( \%older ), $key, 'version rotates the key' );
}

# The installer script and the generation counter rotate the key.
# The test points both inputs at synthetic files and does not edit
# the checkout. Thus an aborted test cannot leave the tree modified.
{
	my $tmp = tempdir( CLEANUP => 1 );
	_spit( "$tmp/install.exp", "#!/usr/bin/expect\n" );
	_spit( "$tmp/cache-generation", "1\n" );

	my $cache = TestInputs->new( "$tmp/cache", $tmp );
	my $key   = $cache->key( \%CONFIG );
	ok( defined $key, 'key derived from synthetic inputs' );

	_spit( "$tmp/install.exp", "#!/usr/bin/expect\n# one more step\n" );
	isnt( $cache->key( \%CONFIG ), $key,
		'a changed install.exp rotates the key' );

	_spit( "$tmp/install.exp", "#!/usr/bin/expect\n" );
	is( $cache->key( \%CONFIG ), $key,
		'restoring the installer restores the key' );

	_spit( "$tmp/cache-generation", "2\n" );
	isnt( $cache->key( \%CONFIG ), $key,
		'a bumped generation counter rotates the key' );

	# An unreadable input means no key at all, and therefore no
	# caching. The code never derives a key from partial inputs.
	unlink "$tmp/cache-generation";
	my $missing = do {
		local $SIG{__WARN__} = sub { };
		$cache->key( \%CONFIG );
	};
	is( $missing, undef, 'a missing generation file yields no key' );
}

# The real checkout resolves both key inputs
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	ok( defined $cache->_install_script,
		'install.exp resolves in this checkout' );
	ok( defined $cache->_generation_file,
		'cache-generation resolves in this checkout' );
}

# Lookup misses: nothing cached, empty entry, base without metadata
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	is( $cache->lookup('7.8-arm64-deadbeef'),
		undef, 'lookup misses when nothing is cached' );
	is( $cache->lookup(undef), undef, 'lookup of an undef key misses' );

	make_path( $cache->entry_dir('empty') );
	is( $cache->lookup('empty'), undef, 'an empty entry is a miss' );

	my $partial = $cache->entry_dir('partial');
	make_path($partial);
	_spit( "$partial/base.qcow2", 'not really an image' );
	is( $cache->lookup('partial'),
		undef, 'a base image without metadata is a miss' );

	_spit( "$partial/meta.json", 'this is not json' );
	is( $cache->lookup('partial'),
		undef, 'unparseable metadata is a miss, not a crash' );

	is_deeply( $cache->list, [], 'list skips incomplete entries' );
}

# sweep_temp removes temporary trees, whatever left them behind
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	make_path( $cache->installed_dir . '/.tmp.12345.abcdef' );
	_spit( $cache->installed_dir . '/.tmp.12345.abcdef/base.qcow2', 'x' );

	is( $cache->sweep_temp, 1, 'sweep_temp removes an orphaned tree' );
	ok( !-e $cache->installed_dir . '/.tmp.12345.abcdef',
		'the orphaned tree is gone' );
	is( $cache->sweep_temp, 0, 'sweep_temp is idempotent' );
}

# Removal
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	ok( $cache->remove('never-existed'),
		'removing an absent entry succeeds' );

	my $dir = $cache->entry_dir('gone');
	make_path("$dir/snapshots");
	_spit( "$dir/base.qcow2", 'x' );
	chmod 0400, "$dir/base.qcow2";

	ok( $cache->remove('gone'), 'remove reports success' );
	ok( !-e $dir, 'the entry tree is gone, read-only base included' );
}

# Everything below needs a real qcow2 toolchain
SKIP: {
	skip 'qemu-img not installed', 19 if !$HAS_QEMU_IMG;

	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new("$tmp/cache");
	my $key   = '7.8-arm64-abcd1234';

	my $disk = "$tmp/disk.qcow2";
	system( 'qemu-img', 'create', '-f', 'qcow2', $disk, '64M' )
	    == 0
	    or skip 'cannot create a test disk image', 19;

	# Store an entry. Look it up again.
	my $base = $cache->store( $key, $disk,
		{ root_password => 's3cret', version => '7.8' } );
	ok( defined $base, 'store returns the published base image path' );
	is( $base, $cache->base_path($key), 'stored at the expected path' );
	ok( -f $base, 'base image exists' );

	is( sprintf( '%04o', ( stat $base )[2] & 07777 ),
		'0400', 'base image is read-only' );
	is(
		sprintf( '%04o',
			( stat $cache->entry_dir($key) . '/meta.json' )[2]
			    & 07777 ),
		'0600',
		'metadata is owner-only: it holds the root password'
	);

	my $hit = $cache->lookup($key);
	ok( defined $hit, 'lookup hits after store' );
	is( $hit->{meta}{root_password},
		's3cret', 'the root password round-trips' );
	is( $hit->{meta}{key}, $key, 'metadata echoes the key' );
	ok( $hit->{meta}{created_at} > 0, 'metadata records a creation time' );

	# The base is a real, self-standing qcow2
	my $out = qx{qemu-img info --output=json "$base" 2>/dev/null};
	my $info = eval { JSON::XS::decode_json($out) };
	is( $info->{format}, 'qcow2', 'the base is a qcow2 image' );
	ok( !defined $info->{'backing-filename'},
		'the base stands alone: no backing file of its own' );

	# Listing
	my $entries = $cache->list;
	is( scalar @$entries, 1, 'list finds the entry' );
	is( $entries->[0]{key}, $key, 'list reports the key' );
	ok( $entries->[0]{size} > 0, 'list reports a size' );
	is_deeply( $entries->[0]{snapshots}, [], 'no snapshots yet' );

	# Write-once: a second store must not replace a populated entry
	my $again = do {
		local $SIG{__WARN__} = sub { };
		$cache->store( $key, $disk, { root_password => 'other' } );
	};
	is( $again, undef, 'store refuses to overwrite a populated key' );
	is( $cache->lookup($key)->{meta}{root_password},
		's3cret', 'the original entry survives the refusal' );

	# A failed store leaves no temporary tree behind
	my $failed = do {
		local $SIG{__WARN__} = sub { };
		$cache->store( 'other-key', "$tmp/no-such-disk.qcow2", {} );
	};
	is( $failed, undef, 'store of a missing disk fails' );

	my $orphans = _temp_trees( $cache->installed_dir );
	is( $orphans, 0, 'no temporary tree survives a failed store' );
}

# Overlays on a cached base, the shape VM::up creates
SKIP: {
	skip 'qemu-img not installed', 5 if !$HAS_QEMU_IMG;

	require App::FuguVM::Disk;

	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new("$tmp/cache");
	my $key   = '7.8-arm64-0f0f0f0f';

	my $source = "$tmp/source.qcow2";
	system( 'qemu-img', 'create', '-f', 'qcow2', $source, '64M' ) == 0
	    or skip 'cannot create a test disk image', 5;

	my $base = $cache->store( $key, $source, { root_password => 'pw' } );
	ok( defined $base, 'base image published' );

	my $disk = App::FuguVM::Disk->new("$tmp/state");
	my $path = $disk->create( 'default', undef, $base );
	ok( defined $path, 'overlay created without an explicit size' );

	is( $disk->backing_file('default'),
		$base, 'the overlay is backed by the cached base' );

	my $info = $disk->info('default');
	is( $info->{'backing-filename-format'},
		'qcow2', 'the backing format is qcow2, not raw' );
	is( $info->{'virtual-size'},
		64 * 1024 * 1024,
		'the overlay inherits the base virtual size' );
}

# Snapshot names become file names inside the cache
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	ok( $cache->valid_snapshot_name('deps-abc123'), 'a plain name' );
	ok( $cache->valid_snapshot_name('s1'),          'short names' );
	ok( $cache->valid_snapshot_name('a.b_c-1'),
		'dots, underscores and dashes' );

	ok( !$cache->valid_snapshot_name(undef),      'undef' );
	ok( !$cache->valid_snapshot_name(''),         'empty' );
	ok( !$cache->valid_snapshot_name('a/b'),      'no path separator' );
	ok( !$cache->valid_snapshot_name("a\0b"),     'no NUL' );
	ok( !$cache->valid_snapshot_name('.hidden'),  'no leading dot' );
	ok( !$cache->valid_snapshot_name('-dash'),    'no leading dash' );
	ok( !$cache->valid_snapshot_name( 'x' x 200 ), 'bounded length' );
}

# Which cache entry a path belongs to
{
	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new($tmp);

	is( $cache->key_for_path( $cache->base_path('k1') ),
		'k1', 'a base image resolves to its key' );
	is( $cache->key_for_path( $cache->snapshot_path( 'k1', 's1' ) ),
		'k1', 'a snapshot resolves to the same key' );
	is( $cache->key_for_path('/elsewhere/disk.qcow2'),
		undef, 'a path outside the cache resolves to nothing' );
	is( $cache->key_for_path(undef), undef, 'undef resolves to nothing' );
}

# Snapshot round-trips over a real base image
SKIP: {
	skip 'qemu-img not installed', 16 if !$HAS_QEMU_IMG;

	require App::FuguVM::Disk;

	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new("$tmp/cache");
	my $key   = '7.8-arm64-5a5a5a5a';

	my $source = "$tmp/source.qcow2";
	system( 'qemu-img', 'create', '-f', 'qcow2', $source, '64M' ) == 0
	    or skip 'cannot create a test disk image', 16;
	my $base = $cache->store( $key, $source, { root_password => 'pw' } );

	# A working overlay, the shape a snapshot comes from
	my $disk = App::FuguVM::Disk->new("$tmp/state");
	$disk->create( 'default', undef, $base );
	my $disk_path = $disk->path('default');

	is( $cache->snapshot_lookup( $key, 'deps' ),
		undef, 'no snapshot before one is saved' );
	is_deeply( $cache->snapshot_list($key), [], 'and none listed' );

	my $path = $cache->snapshot_store( $key, 'deps', $disk_path,
		{ installed => 1, installed_ssh_pubkey => 'ssh-ed25519 AAA' } );
	ok( defined $path, 'snapshot_store publishes a layer' );
	is( sprintf( '%04o', ( stat $path )[2] & 07777 ),
		'0400', 'the snapshot image is read-only' );

	my $found = $cache->snapshot_lookup( $key, 'deps' );
	ok( defined $found, 'snapshot_lookup hits' );
	is( $found->{meta}{installed_ssh_pubkey},
		'ssh-ed25519 AAA', 'state fields round-trip' );
	is( $found->{meta}{root_password},
		'pw', 'the root password is taken from the base, not the caller' );

	is( _backing($path), $base, 'the snapshot hangs off base.qcow2' );

	is( scalar @{ $cache->snapshot_list($key) }, 1, 'snapshot_list finds it' );
	is_deeply( $cache->list->[0]{snapshots},
		['deps'], 'cache listing counts it' );

	# A re-save from a disk restored FROM the snapshot must not
	# make the snapshot its own parent. It must not stack chains
	# without bound.
	unlink $disk_path;
	$disk->create( 'default', undef, $path );
	is( $disk->backing_file('default'),
		$path, 'the working disk now hangs off the snapshot' );

	ok( defined $cache->snapshot_store( $key, 'deps', $disk_path, {} ),
		're-saving the same name succeeds' );
	is( _backing($path), $base,
		'and the re-saved snapshot still hangs off base.qcow2' );
	is( system("qemu-img check '$disk_path' >/dev/null 2>&1"),
		0, 'the working disk chain still resolves' );

	# Removal
	ok( $cache->snapshot_remove( $key, 'deps' ), 'snapshot_remove' );
	is( $cache->snapshot_lookup( $key, 'deps' ),
		undef, 'the snapshot is gone' );
}

# A snapshot whose base is gone reads as a miss. Thus callers can
# fall back to provisioning instead of a hard failure.
SKIP: {
	skip 'qemu-img not installed', 3 if !$HAS_QEMU_IMG;

	my $tmp   = tempdir( CLEANUP => 1 );
	my $cache = App::FuguVM::DiskCache->new("$tmp/cache");
	my $key   = '7.8-arm64-6b6b6b6b';

	my $source = "$tmp/source.qcow2";
	system( 'qemu-img', 'create', '-f', 'qcow2', $source, '64M' ) == 0
	    or skip 'cannot create a test disk image', 3;
	my $base = $cache->store( $key, $source, { root_password => 'pw' } );

	ok( defined $cache->snapshot_store( $key, 'layer', $source, {} ),
		'a snapshot exists' );

	unlink $base;
	is( $cache->snapshot_lookup( $key, 'layer' ),
		undef, 'it reads as a miss once its base is gone' );

	my $orphan = do {
		local $SIG{__WARN__} = sub { };
		$cache->snapshot_store( $key, 'another', $source, {} );
	};
	is( $orphan, undef, 'and no new snapshot can be added to it' );
}

done_testing();

sub _backing ($path)
{
	my $out = qx{qemu-img info --output=json "$path" 2>/dev/null};
	my $info = eval { JSON::XS::decode_json($out) };
	return $info->{'full-backing-filename'} // $info->{'backing-filename'};
}

sub _spit ( $path, $content )
{
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print $fh $content;
	close $fh;
	return;
}

sub _temp_trees ($dir)
{
	return 0 if !-d $dir;
	opendir my $dh, $dir or return 0;
	my @tmp = grep { index( $_, '.tmp.' ) == 0 } readdir $dh;
	closedir $dh;
	return scalar @tmp;
}

# A cache whose two file-backed key inputs live in a scratch
# directory. Thus tests can rotate them and never touch the checkout.
package TestInputs;

# The inheritance must be in place before the tests above run
BEGIN { our @ISA = ('App::FuguVM::DiskCache'); }

sub new ( $class, $cache_dir, $input_dir )
{
	my $self = $class->SUPER::new($cache_dir);
	$self->{input_dir} = $input_dir;
	return $self;
}

sub _install_script ($self)
{
	my $path = "$self->{input_dir}/install.exp";
	return -f $path ? $path : undef;
}

sub _generation_file ($self)
{
	my $path = "$self->{input_dir}/cache-generation";
	return -f $path ? $path : undef;
}
