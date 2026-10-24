use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

use App::FileSync::Config;
use App::FileSync::Lock;
use App::FileSync::Store;

my $env   = TestSync->new_env();
my $perl  = $^X;
my $base  = $env->{base};
my $fake_script = File::Spec->catfile($base, 'fake-ssh.pl');
my $fake  = $^O eq 'MSWin32'
    ? File::Spec->catfile($base, 'fake-ssh.cmd')
    : File::Spec->catfile($base, 'fake-ssh');
my $log   = File::Spec->catfile($base, 'ssh.log');
my $server_bin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-server');

# A stand-in for ssh: parse the options the transport builds, record the argv,
# then run the real filesync-server in place of the remote command.
my $script = <<'FAKE';
#!/usr/bin/env perl
use strict;
use warnings;

if ($ENV{FAKE_SSH_LOG}) {
    open my $fh, '>>', $ENV{FAKE_SSH_LOG} or die "log: $!";
    print {$fh} join("\n", @ARGV), "\n---\n";
    close $fh;
}

my ($host, $command);
while (@ARGV) {
    my $arg = shift @ARGV;

    if ($arg eq '--') {
        $host = shift @ARGV;
        last;
    }
    if ($arg !~ /\A-/) {
        $host = $arg;
        last;
    }
    if ($arg =~ /\A-[oipFl]\z/) {
        shift @ARGV;
        next;
    }
    next;
}

$command = join ' ', @ARGV;

if ($ENV{FAKE_SSH_FAIL}) {
    print STDERR $ENV{FAKE_SSH_FAIL}, "\n";
    exit 255;
}

$ENV{SSH_ORIGINAL_COMMAND} = defined $ENV{FAKE_SSH_ORIGINAL}
    ? $ENV{FAKE_SSH_ORIGINAL}
    : $command;
$command = $ENV{FAKE_SSH_FORCED} if defined $ENV{FAKE_SSH_FORCED};

my @tokens = split ' ', $command;
shift @tokens;
unshift @tokens, $ENV{FILESYNC_SERVER_BIN};
push @tokens, '--root', $ENV{FAKE_SSH_ROOT};

exec $^X, @tokens;
die "exec failed: $!\n";
FAKE

open my $fh, '>', $fake_script or die $!;
print {$fh} $script;
close $fh;

if ($^O eq 'MSWin32') {
    # CreateProcess cannot start a .cmd itself, so Perl routes a batch
    # command through cmd.exe; the wrapper only restores the interpreter and
    # hands every ssh argument on.  @echo off keeps cmd's echoing out of the
    # protocol pipe on stdout.
    # :raw keeps Perl's text layer from turning the CRLF endings into
    # CRCRLF on Windows.
    open my $wrapper, '>:raw', $fake or die $!;
    print {$wrapper} "\@echo off\r\n";
    print {$wrapper} '"', $perl, '" "', $fake_script, '" %*', "\r\n";
    close $wrapper;
} else {
    rename $fake_script, $fake
        or die "Cannot rename $fake_script to $fake: $!";
    chmod 0755, $fake or die $!;
}

$ENV{FAKE_SSH_LOG}        = $log;
$ENV{FAKE_SSH_ROOT}       = $env->{server};
$ENV{FILESYNC_SERVER_BIN} = $server_bin;

sub use_ssh {
    my (%overrides) = @_;

    my $config = App::FileSync::Config::load_client($env->{config_path});
    $config->{ssh}{command} = $fake;
    $config->{repos}{docs} = {
        %{ $config->{repos}{docs} },
        transport        => 'ssh',
        server           => 'filesync@example.test',
        remote_repo      => 'docs',
        local_trash_days => 30,
        %overrides,
    };
    delete $config->{repos}{docs}{server_root};

    App::FileSync::Config::save_client($config, $env->{config_path});
    return $config;
}

sub last_argv {
    return () unless -e $log;

    open my $handle, '<', $log or return ();
    local $/;
    my $text = <$handle>;
    close $handle;

    my @blocks = split /^---$/m, $text;
    my $last = $blocks[-1];
    $last = $blocks[-2] if defined $last && $last =~ /\A\s*\z/ && @blocks > 1;

    return grep { length } split /\n/, ($last || '');
}

sub has_pair {
    my ($argv, $flag, $value) = @_;
    for my $index (0 .. $#{$argv} - 1) {
        return 1 if $argv->[$index] eq $flag && $argv->[$index + 1] eq $value;
    }
    return 0;
}

# --- a real session over the transport -----------------------------------

use_ssh();
$env->write_file('client', 'notes/ssh.txt', "over ssh\n", 1_700_000_000);

my $result = $env->sync();
is($result->{exit}, 0, 'sync over ssh succeeds');
is($result->{summary}{pushed}, 1, 'the file was pushed');
is($env->read_file('server', 'notes/ssh.txt'), "over ssh\n",
    'the master received the file');

my @argv = last_argv();
ok(@argv, 'the fake ssh recorded its arguments');

ok((grep { $_ eq '-T' } @argv), 'ssh runs without a pty');
ok(has_pair(\@argv, '-o', 'BatchMode=yes'), 'BatchMode=yes: cron never prompts');
ok(has_pair(\@argv, '-o', 'StrictHostKeyChecking=yes'),
    'host keys are checked strictly by default');
ok((grep { $_ eq 'filesync@example.test' } @argv), 'the configured server is used');
ok((grep { $_ eq 'filesync-server' } @argv), 'the remote command is filesync-server');
ok(has_pair(\@argv, '--repo', 'docs'), 'the repo is passed to the server');
ok(has_pair(\@argv, '--client', 'test-1'), 'the client id is passed to the server');
ok(has_pair(\@argv, '--role', 'client'), 'the role is passed to the server');
ok(has_pair(\@argv, '--proto', '2'), 'the protocol version is passed to the server');

# --- options from the repo configuration ---------------------------------

$env->write_file('client', 'notes/ssh2.txt', "second\n", 1_700_000_100);
use_ssh(
    port              => 2222,
    identity          => '/home/test/.ssh/id_ed25519',
    host_key_checking => 'accept-new',
);
$result = $env->sync();
is($result->{exit}, 0, 'a second session with more options succeeds');

@argv = last_argv();
ok(has_pair(\@argv, '-p', '2222'), 'the port is passed to ssh');
ok(has_pair(\@argv, '-i', '/home/test/.ssh/id_ed25519'), 'the identity is passed to ssh');
ok(has_pair(\@argv, '-o', 'StrictHostKeyChecking=accept-new'),
    'accept-new is only used when it was asked for');
unlike(join("\n", @argv), qr/StrictHostKeyChecking=no/,
    'host key checking is never turned off');

# --- a transport that cannot connect -------------------------------------

local $ENV{FAKE_SSH_FAIL} = 'Permission denied (publickey).';
my $error = '';
eval { $env->sync(); 1 } or $error = $@;
ok($error, 'a failed ssh connection is fatal');
like($error, qr/Permission denied \(publickey\)/,
    'the ssh diagnostic is reported, not a protocol error');
like($error, qr/publickey/, 'the error survives the protocol teardown');

delete $ENV{FAKE_SSH_FAIL};

# --- locking -------------------------------------------------------------

my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
my $server_lock = App::FileSync::Lock::acquire(
    path => $store->lock_path(), nonblock => 1,
);
ok($server_lock, 'the test holds the server lock');

$result = $env->sync();
is($result->{exit}, 2, 'a held server lock exits 2');
like($result->{error}, qr/holds the lock/, 'the lock refusal is reported');
ok(!$result->{ok}, 'the run is not reported as successful');

close $server_lock;

$result = $env->sync();
is($result->{exit}, 0, 'the next run succeeds once the lock is released');

my $client_lock = App::FileSync::Lock::acquire(
    path => File::Spec->catfile($env->{home}, 'locks', 'docs.lock'),
    nonblock => 1,
);
ok($client_lock, 'the test holds the client lock');

$result = $env->sync();
is($result->{exit}, 2, 'a held client lock exits 2');
like($result->{error}, qr/Another filesync run holds the lock/,
    'the client lock refusal is reported');

close $client_lock;

# --- the server refuses a session that disagrees with its pinning --------

{
    local $ENV{FAKE_SSH_ORIGINAL} =
        'filesync-server --repo other --client test-1 --role client';
    my $refusal = '';
    eval { $env->sync(); 1 } or $refusal = $@;
    like($refusal, qr/pinned to 'docs'/,
        'a session asking for another repo is refused by the pinned command');
    like($refusal, qr/asks for repo 'other'/,
        'the refusal names what the client asked for');
}

{
    local $ENV{FAKE_SSH_FORCED} =
        'filesync-server --repo docs --client test-1 --role client --proto 2';
    $env->write_file('client', 'notes/forced.txt', "forced\n", 1_700_000_500);
    my $forced = eval { $env->sync() };
    ok($forced, 'a forced command that agrees with the hello still syncs')
        or diag($@);
    is($forced->{exit}, 0, 'the forced-command run exits 0');
    is($env->read_file('server', 'notes/forced.txt'), "forced\n",
        'the pushed file arrived');
}

# --- defaults from the process settings ----------------------------------
{
    my $settings_path = $ENV{FILESYNC_SETTINGS};
    open my $settings_fh, '>', $settings_path or die "Cannot write $settings_path: $!";
    print {$settings_fh} <<'SETTINGS';
{"App__FileSync":{
    "ssh_identity": "/home/test/.ssh/filesync_key",
    "ssh_known_hosts": "/home/test/.ssh/filesync_known_hosts",
    "server_command": "/opt/filesync/bin/filesync-server"
}}
SETTINGS
    close $settings_fh;

    # Drop the per-repo values an earlier block recorded, so these come from
    # the settings file alone.
    use_ssh(identity => undef, known_hosts => undef, server_command => undef);
    $env->write_file('client', 'notes/settings.txt', "from settings\n", 1_700_000_600);
    my $settings_run = $env->sync();
    is($settings_run->{exit}, 0, 'options from the settings file still sync');
    is($env->read_file('server', 'notes/settings.txt'), "from settings\n",
        'the file arrived over the settings-provided options');

    @argv = last_argv();
    ok(has_pair(\@argv, '-i', '/home/test/.ssh/filesync_key'),
        'the identity comes from the process settings');
    ok(has_pair(\@argv, '-o', 'UserKnownHostsFile=/home/test/.ssh/filesync_known_hosts'),
        'the known-hosts file comes from the process settings');
    ok((grep { $_ eq '/opt/filesync/bin/filesync-server' } @argv),
        'the remote command comes from the process settings');

    use_ssh(
        identity       => '/home/test/.ssh/repo_key',
        known_hosts    => '/home/test/.ssh/repo_known_hosts',
        server_command => '/usr/local/bin/filesync-server',
    );
    $env->write_file('client', 'notes/override.txt', "override\n", 1_700_000_700);
    $settings_run = $env->sync();
    is($settings_run->{exit}, 0, 'a repo that overrides the settings still syncs');

    @argv = last_argv();
    ok(has_pair(\@argv, '-i', '/home/test/.ssh/repo_key'),
        'a repo identity beats the process setting');
    ok(has_pair(\@argv, '-o', 'UserKnownHostsFile=/home/test/.ssh/repo_known_hosts'),
        'a repo known-hosts file beats the process setting');
    ok((grep { $_ eq '/usr/local/bin/filesync-server' } @argv),
        'a repo server command beats the process setting');
    ok(!(grep { $_ eq '/opt/filesync/bin/filesync-server' } @argv),
        'the settings server command is not used when the repo has its own');
    ok(!(grep { $_ eq '/home/test/.ssh/filesync_key' } @argv),
        'the settings identity is not passed when the repo has its own');

    open my $reset, '>', $settings_path or die "Cannot write $settings_path: $!";
    print {$reset} "{}\n";
    close $reset;
}

done_testing();
