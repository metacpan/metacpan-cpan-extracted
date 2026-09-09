#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use_ok('App::FuguVM::Config');

# Test constants
is(App::FuguVM::Config::DEFAULT_MEMORY(), 2048, 'DEFAULT_MEMORY is 2048');
is(App::FuguVM::Config::DEFAULT_SSH_PORT(), 2222, 'DEFAULT_SSH_PORT is 2222');
is(App::FuguVM::Config::DEFAULT_VERSION(), '7.8', 'DEFAULT_VERSION is 7.8');

# Test find_project_root returns undef when not in project
{
    my $tmpdir = tempdir(CLEANUP => 1);
    chdir $tmpdir;
    my $root = App::FuguVM::Config->find_project_root;
    is($root, undef, 'find_project_root returns undef outside project');
}

# Test find_project_root finds .fuguvmrc file
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    # Create .fuguvmrc at the project root
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    close $fh;
    chdir $tmpdir;
    my $root = App::FuguVM::Config->find_project_root;
    # Resolve symlinks for comparison (macOS /var -> /private/var)
    use Cwd qw(realpath);
    my $expected = realpath($tmpdir);
    my $actual = realpath($root);
    is($actual, $expected, 'find_project_root finds project root');
}

# Test config parsing
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # Create the config file at the project root
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "cache_dir /tmp/test\n";
    print $fh "default_vm test\n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->default_vm, 'test', 'default_vm parsed correctly');
}

# Test VM config loading from block in .fuguvmrc
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # Create a project config with a VM block
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "default_vm test\n";
    print $fh "\n";
    print $fh "vm \"test\" {\n";
    print $fh "    memory 4096\n";
    print $fh "    ssh_port 3333\n";
    print $fh "}\n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('test');
    
    ok(defined $vm, 'VM config loaded from block');
    is($vm->{name}, 'test', 'VM name set from block name');
    is($vm->{memory}, 4096, 'VM memory parsed');
    is($vm->{ssh_port}, 3333, 'VM ssh_port parsed');
    is($vm->{version}, '7.8', 'VM version has default');
}

# Test VM config loading from a file of its own under vms/, the layout
# that 'fuguvm init' writes
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");

    # Create a separate VM config file
    open my $fh, '>', "$tmpdir/.fuguvm/vms/spare.conf";
    print $fh "name spare-vm\n";
    print $fh "memory 2048\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('spare');

    ok(defined $vm, 'VM config loaded from separate file');
    is($vm->{name}, 'spare-vm', 'VM name parsed from file');
    is($vm->{memory}, 2048, 'VM memory parsed from file');
}

# Test load_vm returns undef for missing VM
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");

    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('nonexistent');
    is($vm, undef, 'load_vm returns undef for missing VM');
    is($config->error, undef, 'a missing VM is not a validation error');
}

# The arch directive: the default, both values, both spellings, and
# the validation at the configuration boundary
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"plain\" {\n";
    print $fh "    memory 2048\n";
    print $fh "}\n";
    print $fh "vm \"intel\" {\n";
    print $fh "    arch amd64\n";
    print $fh "}\n";
    print $fh "vm \"arm\" {\n";
    print $fh "    arch = arm64\n";
    print $fh "}\n";
    print $fh "vm \"broken\" {\n";
    print $fh "    arch riscv64\n";
    print $fh "}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);

    is(App::FuguVM::Config::DEFAULT_ARCH(), 'arm64',
	'DEFAULT_ARCH is arm64');
    is($config->load_vm('plain')->{arch}, 'arm64',
	'arch defaults to arm64 when the block omits it');
    is($config->load_vm('intel')->{arch}, 'amd64',
	'arch amd64 loads in the key value form');
    is($config->load_vm('arm')->{arch}, 'arm64',
	'arch arm64 loads in the key = value form');

    is($config->load_vm('broken'), undef,
	'an unknown arch value makes load_vm return undef');
    like($config->error, qr/riscv64/, 'error names the value');
    like($config->error, qr/amd64.*arm64/,
	'error names the two accepted values');

    ok(defined $config->load_vm('plain'), 'a later load succeeds');
    is($config->error, undef, 'and error returns undef after it');
}

# The resolved cache_dir reaches the per-VM config. Thus `fuguvm up`
# writes its image cache where the cache subcommands look for it.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "cache_dir /var/cache/fuguvm\n";
    print $fh "vm \"test\" {\n";
    print $fh "    memory 4096\n";
    print $fh "}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('test');

    is($vm->{cache_dir}, '/var/cache/fuguvm',
	'load_vm injects the configured cache_dir');
    is($vm->{cache_dir}, $config->cache_dir,
	'and it is the same value cache_dir reports');
}

# image_cache: the default is on. The project setting overrides the
# global setting. The test covers every spelling an OpenBSD-style
# switch accepts.
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm test {\n}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->image_cache, 1, 'image_cache defaults to on');
    is($config->load_vm('test')->{image_cache}, 1,
	'and the default reaches the per-VM config');

    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "image_cache no\n";
    close $gh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->image_cache, 0, 'global image_cache no switches it off');

    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "image_cache yes\n";
    print $fh "vm test {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->image_cache, 1, 'project image_cache wins over global');
    is($config->load_vm('test')->{image_cache}, 1,
	'and reaches the per-VM config');

    for my $off (qw(no false off 0)) {
	open $fh, '>', "$tmpdir/.fuguvmrc";
	print $fh "image_cache $off\n";
	close $fh;
	is(App::FuguVM::Config->new($tmpdir)->image_cache, 0,
	    "image_cache $off is off");
    }

    for my $on (qw(yes true on 1 YES)) {
	open $fh, '>', "$tmpdir/.fuguvmrc";
	print $fh "image_cache $on\n";
	close $fh;
	is(App::FuguVM::Config->new($tmpdir)->image_cache, 1,
	    "image_cache $on is on");
    }

    # An unrecognized value must not silently mean its opposite
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "image_cache maybe\n";
    close $fh;
    my $diagnostic = '';
    my $result;
    {
	local *STDERR;
	open STDERR, '>', \$diagnostic or die "capture stderr: $!";
	$result = App::FuguVM::Config->new($tmpdir)->image_cache;
    }
    is($result, 1, 'an unparseable image_cache falls back to the default');
    like($diagnostic, qr/not a yes\/no value: maybe/,
	'and it says so instead of meaning the opposite');
}

# The distfile_cache directive: the size grammar, the default, the
# refusal, and the merge
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    my $write = sub ($body) {
	open my $fh, '>', "$tmpdir/.fuguvmrc" or die $!;
	print $fh $body;
	close $fh;
	return App::FuguVM::Config->new($tmpdir);
    };

    my %sizes = (
	'4G'   => 4 * 1024**3,
	'512M' => 512 * 1024**2,
	'64K'  => 64 * 1024,
	'1024' => 1024,
	'2g'   => 2 * 1024**3,
	'8m'   => 8 * 1024**2,
    );
    for my $value (sort keys %sizes) {
	is($write->("distfile_cache $value\n")->distfile_cache,
	    $sizes{$value}, "distfile_cache parses $value");
    }

    is($write->("distfile_cache 0\n")->distfile_cache, 0,
	'distfile_cache 0 is off');
    is($write->("cache_dir /tmp\n")->distfile_cache, 0,
	'an absent directive is off');

    # An unparsable value warns and reads as off: an unrecognized
    # spelling must not silently mean its opposite, and off is the
    # closed state for a cache.
    my $diagnostic = '';
    my $result;
    {
	local *STDERR;
	open STDERR, '>', \$diagnostic or die "capture stderr: $!";
	$result = $write->("distfile_cache lots\n")->distfile_cache;
    }
    is($result, 0, 'an unparsable distfile_cache is off');
    like($diagnostic, qr/lots/, 'and the warning names the value');

    # The project file wins over the global file, for each of the
    # three directives of the mirror work
    open my $gh, '>', "$homedir/.fuguvmrc" or die $!;
    print $gh "distfile_cache 1K\n";
    print $gh "verify yes\n";
    print $gh "signify_dir /global/keys\n";
    close $gh;

    my $config = $write->("distfile_cache 2K\n"
	. "verify no\n"
	. "signify_dir /project/keys\n");
    is($config->distfile_cache, 2048,
	'the project distfile_cache wins over the global one');
    is($config->verify, 0, 'the project verify wins over the global one');
    is($config->signify_dir, '/project/keys',
	'the project signify_dir wins over the global one');

    # The global file serves without a project value
    $config = $write->("cache_dir /tmp\n");
    is($config->distfile_cache, 1024, 'the global distfile_cache serves');
    is($config->verify, 1, 'the global verify serves');
    is($config->signify_dir, '/global/keys', 'the global signify_dir serves');
}

# The verify directive: the default is on, and it reads the yes/no
# spellings like image_cache
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm test {\n}\n";
    close $fh;
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->verify, 1, 'verify defaults to 1');
    is($config->load_vm('test')->{verify}, 1,
	'and the default reaches the VM hash');

    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "verify no\n";
    print $fh "vm test {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->verify, 0, 'verify no reads as 0');
    is($config->load_vm('test')->{verify}, 0, 'and reaches the VM hash');
}

# The signify_dir directive: the tilde, the project-relative path,
# the VM hash, and the refusal of a value that is not a directory
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms", "$tmpdir/keys", "$homedir/keys");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "signify_dir ~/keys\n";
    print $fh "vm test {\n}\n";
    close $fh;
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->signify_dir, "$homedir/keys", 'signify_dir expands a tilde');
    is($config->load_vm('test')->{signify_dir}, "$homedir/keys",
	'and load_vm carries it into the VM hash');

    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "signify_dir keys\n";
    print $fh "vm test {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    like($config->signify_dir, qr{\Q/keys\E$},
	'a relative path resolves against the project root');
    like($config->signify_dir, qr{^/}, 'and the result is absolute');

    # A value that is not a directory is a refusal at the boundary
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm test {\n";
    print $fh "    signify_dir absent-keys\n";
    print $fh "}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('test'), undef,
	'an absent signify_dir makes load_vm return undef');
    like($config->error, qr/absent-keys/, 'and error names the path');

    # The distfile cap is a project fact, and load_vm injects it
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "distfile_cache 4G\n";
    print $fh "vm test {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('test')->{distfile_cache}, 4 * 1024**3,
	'load_vm injects the distfile cap of the project');

    # A cap in a VM block does not apply, and the operator hears
    # about it
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "distfile_cache 4G\n";
    print $fh "vm test {\n";
    print $fh "    distfile_cache 8G\n";
    print $fh "}\n";
    close $fh;
    my $warning = '';
    my $loaded;
    {
	local *STDERR;
	open STDERR, '>', \$warning or die "capture stderr: $!";
	$loaded = App::FuguVM::Config->new($tmpdir)->load_vm('test');
    }
    is($loaded->{distfile_cache}, 4 * 1024**3,
	'the project cap wins over a cap in a VM block');
    like($warning, qr/distfile_cache/,
	'and the loader warns about the block value');
}

# The parser normalizes image_cache inside a vm block like the global
# directive
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "image_cache yes\n";
    print $fh "vm test {\n";
    print $fh "    image_cache no\n";
    print $fh "}\n";
    close $fh;

    my $vm = App::FuguVM::Config->new($tmpdir)->load_vm('test');
    is($vm->{image_cache}, 0,
	'a VM block switches its own image cache off, as a number');
}

# A VM without any cache_dir configured still gets the default
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm test {\n}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('test');

    is($vm->{cache_dir}, "$homedir/.cache/fuguvm",
	'default cache_dir is injected and tilde-expanded');
}

# Test ssh_pubkey from project config
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # Create a config with ssh_pubkey at the project root
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "ssh_pubkey ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI test\@example\n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    like($config->ssh_pubkey, qr/^ssh-ed25519/, 'ssh_pubkey parsed from project config');
}

# Test ssh_pubkey from global config fallback
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # No ssh_pubkey in project config
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "default_vm test\n";
    close $fh;
    
    # Create a global config with ssh_pubkey
    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "ssh_pubkey ssh-rsa AAAAB3NzaC1 global\@test\n";
    close $gh;
    
    local $ENV{HOME} = $homedir;
    my $config = App::FuguVM::Config->new($tmpdir);
    like($config->ssh_pubkey, qr/^ssh-rsa/, 'ssh_pubkey falls back to global config');
}

# Test ssh_pubkey included in VM config
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "ssh_pubkey ssh-ed25519 TESTKEY test\@vm\n";
    print $fh "\n";
    print $fh "vm \"test\" {\n";
    print $fh "    memory 2048\n";
    print $fh "}\n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('test');
    is($vm->{ssh_pubkey}, 'ssh-ed25519 TESTKEY test@vm', 'ssh_pubkey included in VM config');
}

# Test project config overrides global config
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # Global config
    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "default_vm global-vm\n";
    print $gh "cache_dir /global/cache\n";
    print $gh "ssh_pubkey ssh-rsa GLOBAL global\@test\n";
    close $gh;
    
    # The project config overrides some values
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "default_vm project-vm\n";
    close $fh;
    
    local $ENV{HOME} = $homedir;
    my $config = App::FuguVM::Config->new($tmpdir);
    
    is($config->default_vm, 'project-vm', 'project config overrides global default_vm');
    is($config->cache_dir, '/global/cache', 'global cache_dir used when not in project');
    like($config->ssh_pubkey, qr/^ssh-rsa GLOBAL/, 'global ssh_pubkey used when not in project');
}

# Test find_project_root walks up directory tree
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/subdir/deep/nested");
    
    # Create .fuguvmrc at the project root
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    close $fh;
    
    # Save the cwd. Change to the nested directory.
    use Cwd qw(getcwd realpath);
    my $orig_cwd = getcwd();
    chdir "$tmpdir/subdir/deep/nested";
    my $root = App::FuguVM::Config->find_project_root;
    chdir $orig_cwd;  # Restore the cwd before cleanup
    
    my $expected = realpath($tmpdir);
    my $actual = realpath($root);
    is($actual, $expected, 'find_project_root walks up directory tree');
}

# Test config with comments and whitespace
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "# This is a comment\n";
    print $fh "   \n";
    print $fh "default_vm test  # inline comment\n";
    print $fh "  cache_dir   /path/with/spaces   \n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->default_vm, 'test', 'inline comments stripped');
    is($config->cache_dir, '/path/with/spaces', 'whitespace trimmed');
}

# Test data_dir accessor
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->{data_dir}, "$tmpdir/.fuguvm", 'data_dir set correctly');
}

# Test state_dir default
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->state_dir, "$tmpdir/.fuguvm/state", 'state_dir defaults to .fuguvm/state');
}

# Test state_dir from config
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "state_dir /custom/state\n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->state_dir, '/custom/state', 'state_dir from config');
}

# Test cache_dir tilde expansion
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "cache_dir ~/cache/fuguvm\n";
    close $fh;
    
    local $ENV{HOME} = $homedir;
    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->cache_dir, "$homedir/cache/fuguvm", 'cache_dir expands tilde');
}

# Test VM block in global config
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # VM defined in global config
    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "vm \"shared\" {\n";
    print $gh "    memory 1024\n";
    print $gh "    version 7.8\n";
    print $gh "}\n";
    close $gh;
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    close $fh;
    
    local $ENV{HOME} = $homedir;
    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('shared');
    
    ok(defined $vm, 'VM loaded from global config');
    is($vm->{memory}, 1024, 'VM memory from global config');
}

# Test project VM overrides global VM
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    # VM in global config
    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "vm \"test\" {\n";
    print $gh "    memory 1024\n";
    print $gh "}\n";
    close $gh;
    
    # Same VM name in project config with different settings
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"test\" {\n";
    print $fh "    memory 4096\n";
    print $fh "}\n";
    close $fh;
    
    local $ENV{HOME} = $homedir;
    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('test');
    
    is($vm->{memory}, 4096, 'project VM config overrides global');
}

# The bind_address directive: the merge, the fallback chain, the
# default, and the validation at the configuration boundary
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "bind_address 10.0.0.1\n";
    close $gh;

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"plain\" {\n}\n";
    print $fh "vm \"pinned\" {\n";
    print $fh "    bind_address 0.0.0.0\n";
    print $fh "}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);

    is(App::FuguVM::Config::DEFAULT_BIND_ADDRESS(), '127.0.0.1',
	'DEFAULT_BIND_ADDRESS is 127.0.0.1');
    is($config->load_vm('pinned')->{bind_address}, '0.0.0.0',
	'bind_address in a vm block reaches the merged configuration');
    is($config->load_vm('plain')->{bind_address}, '10.0.0.1',
	'the enclosing file serves a vm block that omits it');

    # The project file wins over the global file
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "bind_address 192.168.1.1\n";
    print $fh "vm \"plain\" {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('plain')->{bind_address}, '192.168.1.1',
	'the project file wins over the global file');

    # The default is loopback
    open $gh, '>', "$homedir/.fuguvmrc";
    close $gh;
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"plain\" {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('plain')->{bind_address}, '127.0.0.1',
	'the default is 127.0.0.1');

    # An invalid value fails, and error names the value. A component
    # with a leading zero reads as octal in inet_aton, so it fails
    # too.
    for my $bad ('10.0.0.256', 'vm.example.org', '1.2.3', '1.2.3.4.5',
	'010.0.0.1') {
	open $fh, '>', "$tmpdir/.fuguvmrc";
	print $fh "vm \"plain\" {\n";
	print $fh "    bind_address $bad\n";
	print $fh "}\n";
	close $fh;
	$config = App::FuguVM::Config->new($tmpdir);
	is($config->load_vm('plain'), undef,
	    "bind_address $bad makes load_vm return undef");
	like($config->error, qr/\Q$bad\E/, 'and error names the value');
    }
}

# The two port directives: the word auto survives the merge, and an
# other value fails with a message that names the directive
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"fleet\" {\n";
    print $fh "    ssh_port     auto\n";
    print $fh "    console_port auto\n";
    print $fh "}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('fleet');

    is(App::FuguVM::Config::AUTO_PORT(), 'auto', 'AUTO_PORT is auto');
    is(App::FuguVM::Config::AUTO_PORT_COUNT(), 100,
	'AUTO_PORT_COUNT is 100');
    is($vm->{ssh_port}, 'auto', 'ssh_port auto survives the merge');
    is($vm->{console_port}, 'auto', 'console_port auto survives the merge');

    for my $bad (0, 65536, 'yes', '02222') {
	open $fh, '>', "$tmpdir/.fuguvmrc";
	print $fh "vm \"fleet\" {\n";
	print $fh "    ssh_port $bad\n";
	print $fh "}\n";
	close $fh;
	$config = App::FuguVM::Config->new($tmpdir);
	is($config->load_vm('fleet'), undef,
	    "ssh_port $bad makes load_vm return undef");
	like($config->error, qr/ssh_port/, 'and error names the directive');
    }

    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"fleet\" {\n";
    print $fh "    console_port never\n";
    print $fh "}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('fleet'), undef,
	'an invalid console_port makes load_vm return undef');
    like($config->error, qr/console_port/, 'and error names the directive');
}

# The qemu_version directive: the project value, the global value,
# undef, and the validation of the value
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"plain\" {\n}\n";
    close $fh;

    my $config = App::FuguVM::Config->new($tmpdir);
    is($config->qemu_version, undef,
	'qemu_version returns undef with no directive');
    is($config->load_vm('plain')->{qemu_version}, undef,
	'and the per-VM config carries no value');

    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "qemu_version 8.2\n";
    close $gh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->qemu_version, '8.2', 'the global value serves');

    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "qemu_version 9.0.4\n";
    print $fh "vm \"plain\" {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->qemu_version, '9.0.4', 'the project value wins');
    is($config->load_vm('plain')->{qemu_version}, '9.0.4',
	'and it reaches the per-VM config');

    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "qemu_version banana\n";
    print $fh "vm \"plain\" {\n}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('plain'), undef,
	'an invalid qemu_version makes load_vm return undef');
    like($config->error, qr/banana/, 'and error names the value');

    # A pin inside a VM declaration would silently not apply, so it
    # is an error and not a merge
    open $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"plain\" {\n";
    print $fh "    qemu_version 9.0\n";
    print $fh "}\n";
    close $fh;
    $config = App::FuguVM::Config->new($tmpdir);
    is($config->load_vm('plain'), undef,
	'qemu_version in a vm block makes load_vm return undef');
    like($config->error, qr/qemu_version/, 'and error names the directive');
}

# The fixed ports of every VM declaration, for the port probe
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    open my $gh, '>', "$homedir/.fuguvmrc";
    print $gh "vm \"global\" {\n";
    print $gh "    ssh_port     2400\n";
    print $gh "    console_port 4600\n";
    print $gh "}\n";
    close $gh;

    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm \"pinned\" {\n";
    print $fh "    ssh_port     2300\n";
    print $fh "    console_port 4500\n";
    print $fh "}\n";
    print $fh "vm \"bare\" {\n}\n";
    print $fh "vm \"fleet\" {\n";
    print $fh "    ssh_port     auto\n";
    print $fh "    console_port auto\n";
    print $fh "}\n";
    close $fh;

    open my $vh, '>', "$tmpdir/.fuguvm/vms/filed.conf";
    print $vh "ssh_port = 2500\n";
    close $vh;

    my $config = App::FuguVM::Config->new($tmpdir);
    my $ports = $config->declared_ports;

    ok($ports->{2300} && $ports->{4500},
	'declared_ports holds the fixed ports of a project block');
    ok($ports->{2400} && $ports->{4600},
	'and the fixed ports of a global block');
    ok($ports->{2222} && $ports->{4444},
	'a declaration that omits a directive holds the default port');
    ok($ports->{2500}, 'a vms/ file counts too');
    ok(!$ports->{auto}, 'the word auto is not a port');

    is_deeply($config->load_vm('fleet')->{declared_ports}, $ports,
	'load_vm folds the set into the per-VM configuration');
}

# The three image-lifecycle directives: the resolution, the derived
# install_mode, and each refusal at the configuration boundary
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $homedir = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $homedir;
    make_path("$tmpdir/.fuguvm/vms");

    # The files that the directives point at
    for my $seed (["$tmpdir/install.conf", "System hostname = image\n"],
	["$tmpdir/base.qcow2", 'not a real image'],
	["$homedir/password", "secret\n"]) {
	open my $fh, '>', $seed->[0] or die $!;
	print $fh $seed->[1];
	close $fh;
    }

    my $write = sub ($body) {
	open my $fh, '>', "$tmpdir/.fuguvmrc" or die $!;
	print $fh $body;
	close $fh;
	return App::FuguVM::Config->new($tmpdir);
    };

    # install_mode derives from the directives; there is no
    # install_mode directive
    my $config = $write->("vm \"plain\" {\n}\n");
    is($config->load_vm('plain')->{install_mode}, 'expect',
	'no directive derives the expect mode');

    $config = $write->("vm \"auto\" {\n    autoinstall install.conf\n}\n");
    my $vm = $config->load_vm('auto');
    is($vm->{install_mode}, 'autoinstall',
	'autoinstall derives the autoinstall mode');
    is($vm->{autoinstall}, "$tmpdir/install.conf",
	'a relative path resolves against the project root');

    $config = $write->("vm \"import\" {\n    base_disk base.qcow2\n}\n");
    $vm = $config->load_vm('import');
    is($vm->{install_mode}, 'import', 'base_disk derives the import mode');
    is($vm->{base_disk}, "$tmpdir/base.qcow2",
	'and its path resolves the same way');

    $config = $write->(
	"vm \"tilde\" {\n    root_password_file ~/password\n}\n");
    is($config->load_vm('tilde')->{root_password_file},
	"$homedir/password", 'a leading tilde expands');

    # An absent file is a refusal that names the resolved path
    $config = $write->("vm \"gone\" {\n    autoinstall absent.conf\n}\n");
    is($config->load_vm('gone'), undef,
	'an absent autoinstall file makes load_vm return undef');
    like($config->error, qr{\Q$tmpdir/absent.conf\E},
	'and error names the resolved path');

    $config = $write->("vm \"gone\" {\n    base_disk absent.qcow2\n}\n");
    is($config->load_vm('gone'), undef,
	'an absent base_disk file behaves the same way');
    like($config->error, qr{\Q$tmpdir/absent.qcow2\E},
	'and error names the resolved path');

    # Two origins contradict each other
    $config = $write->("vm \"both\" {\n"
	. "    autoinstall install.conf\n"
	. "    base_disk base.qcow2\n"
	. "}\n");
    is($config->load_vm('both'), undef,
	'autoinstall with base_disk makes load_vm return undef');
    like($config->error, qr/autoinstall/, 'error names one directive');
    like($config->error, qr/base_disk/, 'and the other');

    # An imported base lives in the cache, so the cache must be on
    $config = $write->("vm \"import\" {\n"
	. "    base_disk base.qcow2\n"
	. "    image_cache no\n"
	. "}\n");
    is($config->load_vm('import'), undef,
	'base_disk with image_cache no makes load_vm return undef');
    like($config->error, qr/image cache/, 'and error names the cause');

    # ssh_pubkey without root_password_file refuses outside the
    # expect mode, because the tool cannot authenticate
    for my $origin ('autoinstall install.conf', 'base_disk base.qcow2') {
	$config = $write->("ssh_pubkey ssh-ed25519 KEY test\@host\n"
	    . "vm \"keyed\" {\n    $origin\n}\n");
	is($config->load_vm('keyed'), undef,
	    "ssh_pubkey with no root_password_file refuses ($origin)");
	like($config->error, qr/root_password_file/,
	    'and error names one remedy');
	like($config->error, qr/ssh_pubkey/, 'and the other');
    }

    $config = $write->("ssh_pubkey ssh-ed25519 KEY test\@host\n"
	. "vm \"keyed\" {\n"
	. "    autoinstall install.conf\n"
	. "    root_password_file ~/password\n"
	. "}\n");
    ok(defined $config->load_vm('keyed'),
	'root_password_file satisfies the refusal');

    $config = $write->("ssh_pubkey ssh-ed25519 KEY test\@host\n"
	. "vm \"keyed\" {\n}\n");
    ok(defined $config->load_vm('keyed'),
	'the expect mode needs no password file');
    is($config->error, undef, 'and error returns undef after it');
}

# Test VM block with unquoted name
{
    my $tmpdir = tempdir(CLEANUP => 1);
    make_path("$tmpdir/.fuguvm/vms");
    
    open my $fh, '>', "$tmpdir/.fuguvmrc";
    print $fh "vm simple {\n";
    print $fh "    memory 512\n";
    print $fh "    version 7.8\n";
    print $fh "}\n";
    close $fh;
    
    my $config = App::FuguVM::Config->new($tmpdir);
    my $vm = $config->load_vm('simple');
    
    ok(defined $vm, 'VM with unquoted name loaded');
    is($vm->{memory}, 512, 'VM memory correct');
    is($vm->{name}, 'simple', 'VM name set from unquoted block name');
}

done_testing();
