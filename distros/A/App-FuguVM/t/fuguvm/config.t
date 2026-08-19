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
