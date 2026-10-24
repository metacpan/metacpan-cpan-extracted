use strict;
use warnings;
use Test::Most;
use Test::Exception;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync;
use App::FileSync::Config;
use App::FileSync::Settings;
use Log::Abstraction;

my $filesync = File::Spec->catfile($Bin, '..', 'bin', 'filesync');

sub write_json {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $text;
    close $fh;
    return $path;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

# Windows environment variables are case-insensitive, so the name that comes
# back from the environment is upper-cased there.
sub env_name {
    my ($name) = @_;
    return $^O eq 'MSWin32' ? uc $name : $name;
}

# --------------------------------------------------------------- settings
{
    my $dir = tempdir(CLEANUP => 1);
    my $empty = write_json(File::Spec->catfile($dir, 'empty.json'), "{}\n");

    my $defaults = App::FileSync::Settings::load(config_file => $empty);
    is($defaults->{log_level}, 'warning', 'the default level is warning');
    is($defaults->{log_format}, '%level%: %message%', 'the default format is compact');
    is($defaults->{log_file}, '', 'the default destination is standard error');
    is($defaults->{ssh_identity}, '', 'no identity is imposed on ssh by default');
    is($defaults->{ssh_known_hosts}, '', 'no known-hosts file is imposed by default');
    is($defaults->{server_command}, 'filesync-server',
        'the remote program defaults to filesync-server');

    my $config = write_json(
        File::Spec->catfile($dir, 'configured.json'),
        qq({"App__FileSync":{"log_level":"debug","log_format":"[%level%] %message%","log_file":"/tmp/x.log","ssh_identity":"/home/me/.ssh/id_filesync","ssh_known_hosts":"/home/me/.ssh/known_hosts_filesync"}}\n),
    );

    my $settings = App::FileSync::Settings::load(config_file => $config);
    is($settings->{log_level}, 'debug', 'the file sets the level');
    is($settings->{log_format}, '[%level%] %message%', 'the file sets the format');
    is($settings->{log_file}, '/tmp/x.log', 'the file sets the destination');
    is($settings->{ssh_identity}, '/home/me/.ssh/id_filesync', 'the file sets the identity');
    is($settings->{ssh_known_hosts}, '/home/me/.ssh/known_hosts_filesync',
        'the file sets the known-hosts file');

    local $ENV{App__FileSync__log_level} = 'error';
    my $overridden = App::FileSync::Settings::load(config_file => $config);
    is($overridden->{log_level}, 'error', 'an environment variable beats the file');
    delete $ENV{App__FileSync__log_level};

    local $ENV{App__FileSync__server_command} = '/opt/fs/filesync-server';
    is(App::FileSync::Settings::load(config_file => $config)->{server_command},
        '/opt/fs/filesync-server', 'the environment sets the remote program');

    my $bad = write_json(
        File::Spec->catfile($dir, 'bad.json'),
        qq({"App__FileSync":{"log_level":"loud"}}\n),
    );
    throws_ok { App::FileSync::Settings::logger(config_file => $bad) }
        qr/Invalid log_level 'loud'/, 'an unknown level is rejected';

    is(App::FileSync::Settings::config_file($config), $config, 'an explicit file is used');

    throws_ok { App::FileSync::Settings::load(config_file => '/nonexistent/nope.json') }
        qr/No such file or directory/, 'a missing explicit settings file is reported';

    local $ENV{FILESYNC_SETTINGS} = '/nonexistent/nope.json';
    is(App::FileSync::Settings::config_file(), undef,
        'a settings path from the environment is only used when it exists');
    is(App::FileSync::Settings::load()->{log_level}, 'warning',
        'so a stale environment path falls back to the defaults');
}

# ----------------------------------------------------- where values came from
{
    my $dir = tempdir(CLEANUP => 1);
    my $empty = write_json(File::Spec->catfile($dir, 'empty.json'), "{}\n");

    my $defaults = App::FileSync::Settings::explain(config_file => $empty);
    is($defaults->{settings_file}, $empty, 'the report names the settings file');
    is_deeply(
        [ map { $_->{key} } @{ $defaults->{settings} } ],
        [ qw(log_level log_format log_file ssh_identity ssh_known_hosts server_command) ],
        'every process setting is reported, in a stable order',
    );
    is($_->{source}, 'default', "$_->{key} says it is a built-in default")
        for @{ $defaults->{settings} };
    is($_->{label}, 'built-in default', "$_->{key} names the built-in default")
        for @{ $defaults->{settings} };

    my $config = write_json(
        File::Spec->catfile($dir, 'app-filesync.json'),
        qq({"App__FileSync":{"log_level":"debug","ssh_identity":"/home/me/.ssh/id_filesync"}}\n),
    );
    write_json(
        File::Spec->catfile($dir, 'universal.json'),
        qq({"UNIVERSAL":{"ssh_known_hosts":"/home/me/.ssh/known_hosts_filesync"}}\n),
    );

    my %reported = map { $_->{key} => $_ }
        @{ App::FileSync::Settings::explain(config_file => $config)->{settings} };

    is($reported{log_level}{value}, 'debug', 'the report carries the effective value');
    is($reported{log_level}{source}, 'file', 'a settings-file value is reported as a file');
    like($reported{log_level}{label}, qr/\Qapp-filesync.json\E \[App__FileSync\]/,
        'the file label names the section');

    is($reported{ssh_known_hosts}{source}, 'file', 'the UNIVERSAL section is reported');
    like($reported{ssh_known_hosts}{label}, qr/\Quniversal.json\E \[UNIVERSAL\]/,
        'and distinguished from the class section');
    is($reported{log_format}{source}, 'default', 'an unset key is still the default');
    is($reported{server_command}{value}, 'filesync-server',
        'the default remote program is reported as effective');

    # Every reported value must be what the sync would actually use.
    my $loaded = App::FileSync::Settings::load(config_file => $config);
    is($reported{$_}{value}, $loaded->{$_}, "$_ matches what load() returns")
        for keys %reported;

    local $ENV{App__FileSync__log_level} = 'error';
    my ($level_row) = grep { $_->{key} eq 'log_level' }
        @{ App::FileSync::Settings::explain(config_file => $config)->{settings} };
    is($level_row->{value}, 'error', 'the report shows the environment override');
    is($level_row->{source}, 'env', 'and says it came from the environment');
    is($level_row->{label}, env_name('App__FileSync__log_level'),
        'naming the variable');

    # With no settings file the only source is the environment.
    local $ENV{FILESYNC_SETTINGS} = File::Spec->catfile($dir, 'absent.json');
    local $ENV{App__FileSync__ssh_identity} = '/tmp/from-env';
    my $no_file = App::FileSync::Settings::explain();
    is($no_file->{settings_file}, undef, 'no settings file is reported');
    my ($identity) = grep { $_->{key} eq 'ssh_identity' } @{ $no_file->{settings} };
    is($identity->{value}, '/tmp/from-env', 'an environment-only setting is effective');
    is($identity->{source}, 'env', 'and is attributed to the environment');
    is($identity->{label}, env_name('App__FileSync__ssh_identity'),
        'naming the variable');

    # Config::Abstraction matches an env_prefix case-insensitively, so the
    # report names the variable the way the environment spells it: Windows
    # upper-cases the name whatever case it was set in.
    delete local $ENV{App__FileSync__ssh_identity};
    local $ENV{APP__FILESYNC__SSH_IDENTITY} = '/tmp/from-upper-env';
    my $upper = App::FileSync::Settings::explain();
    my ($upper_identity) = grep { $_->{key} eq 'ssh_identity' }
        @{ $upper->{settings} };
    is($upper_identity->{value}, '/tmp/from-upper-env',
        'a name in a different case is still effective');
    is($upper_identity->{source}, 'env', 'and is attributed to the environment');
    is($upper_identity->{label}, 'APP__FILESYNC__SSH_IDENTITY',
        'the report uses the spelling the environment uses');
}

# ------------------------------------------------- per-repo SSH settings
{
    my $dir = tempdir(CLEANUP => 1);
    my $empty = write_json(File::Spec->catfile($dir, 'empty.json'), "{}\n");

    my $repos = App::FileSync::Settings::explain_repos(
        report      => App::FileSync::Settings::explain(config_file => $empty),
        config_file => '/home/me/.filesync/config.json',
        config      => { repos => {
            docs   => { transport => 'ssh', server => 'srv', identity => '/repo/key',
                        port => 2222, host_key_checking => 'accept-new' },
            local  => { transport => 'local', server_root => '/srv/filesync' },
            mirror => { transport => 'ssh', server => 'srv' },
        } },
    );

    is(scalar @{$repos}, 3, 'every repo is reported');
    is($repos->[0]{repo}, 'docs', 'in name order');
    is($repos->[0]{server}, 'srv', 'the server is named');

    my %ssh = map { $_->{key} => $_ } @{ $repos->[0]{ssh} };
    is($ssh{ssh_identity}{value}, '/repo/key', 'a repo identity is effective');
    is($ssh{ssh_identity}{source}, 'repo', 'and attributed to the repo');
    is($ssh{ssh_identity}{label}, '/home/me/.filesync/config.json [docs]',
        'naming the client config and repo');

    is($ssh{ssh_known_hosts}{value}, '', 'an unset known-hosts file is empty');
    is($ssh{ssh_known_hosts}{source}, 'default', 'and attributed to ssh');
    is($ssh{ssh_known_hosts}{label}, 'ssh default', 'naming ssh\'s default');

    is($ssh{server_command}{value}, 'filesync-server', 'the process default applies');
    is($ssh{server_command}{source}, 'process', 'attributed to the process settings');
    is($ssh{server_command}{label}, 'built-in default', 'naming the default');

    is($ssh{port}{value}, 2222, 'a repo port is effective');
    is($ssh{port}{source}, 'repo', 'and attributed to the repo');
    ok($ssh{port}{repo_only}, 'the port is marked repo only');
    is($ssh{host_key_checking}{value}, 'accept-new',
        'a repo host-key policy is effective');
    is($ssh{host_key_checking}{source}, 'repo', 'and attributed to the repo');
    ok($ssh{host_key_checking}{repo_only},
        'the host-key policy is marked repo only');

    is($repos->[1]{repo}, 'local', 'the local repo is reported');
    is($repos->[1]{ssh}, undef, 'with no SSH settings to resolve');

    my %inherited = map { $_->{key} => $_ } @{ $repos->[2]{ssh} };
    is($inherited{port}{value}, 22, 'an unset port falls back to ssh');
    is($inherited{port}{source}, 'default', 'attributed to ssh');
    ok($inherited{port}{repo_only}, 'and says the key has no other source');
    is($inherited{host_key_checking}{value}, 'yes',
        'an unset host-key policy falls back to ssh');
    ok($inherited{host_key_checking}{repo_only},
        'and says the key has no other source');
}

# ---------------------------------------------------------------- logger
{
    my $dir = tempdir(CLEANUP => 1);
    my $log = File::Spec->catfile($dir, 'run.log');
    # Encode rather than interpolate: a Windows log path contains backslashes
    # that are not valid JSON escapes.
    my $config = write_json(
        File::Spec->catfile($dir, 'settings.json'),
        App::FileSync::json_encode({
            App__FileSync => { log_level => 'debug', log_file => $log },
        }) . "\n",
    );

    my $logger = App::FileSync::Settings::logger(config_file => $config);
    lives_ok { $logger->error('kept going') } 'error() logs instead of dying';
    $logger->info('an info line');
    $logger->warn('a warning line');

    my $text = slurp($log);
    like($text, qr/^INFO: an info line$/m, 'info reaches the configured file');
    like($text, qr/^WARN: a warning line$/m, 'warnings reach the configured file');
    like($text, qr/^ERROR: kept going$/m, 'errors reach the configured file');

    # --verbose beats a quieter file; --quiet beats a louder one.
    my $quiet_config = write_json(
        File::Spec->catfile($dir, 'quiet.json'),
        App::FileSync::json_encode({
            App__FileSync => { log_level => 'warning', log_file => $log },
        }) . "\n",
    );

    my $verbose = App::FileSync::Settings::logger(config_file => $quiet_config, verbose => 1);
    $verbose->info('verbose info');

    my $silent = App::FileSync::Settings::logger(config_file => $config, quiet => 1);
    $silent->info('quiet info');
    $silent->warn('quiet warning');
    $silent->error('quiet error');

    my $after = slurp($log);
    like($after, qr/^INFO: verbose info$/m, '--verbose logs info');
    unlike($after, qr/quiet info/, '--quiet suppresses info');
    unlike($after, qr/quiet warning/, '--quiet suppresses warnings');
    like($after, qr/^ERROR: quiet error$/m, '--quiet keeps errors');
}

# ------------------------------------------------ the client uses the logger
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);

    my @captured;
    my $logger = Log::Abstraction->new(level => 'debug', logger => \@captured);

    my $config = App::FileSync::Config::load_client($env->{config_path});
    my $result = App::FileSync::Client->new(
        config => $config,
        name   => 'docs',
        logger => $logger,
    )->sync();

    is($result->{summary}{pushed}, 1, 'the sync still works with an injected logger');

    my @messages = map { $_->{message} } @captured;
    ok((grep { $_ eq 'plan received' } @messages), 'the plan is logged');
    ok((grep { $_ eq 'sync finished' } @messages), 'the completed run is logged');

    my ($finished) = grep { $_->{message} eq 'sync finished' } @captured;
    is($finished->{level}, 'info', 'a completed run is logged at info');
    is($finished->{fields}{repo}, 'docs', 'the log entry names the repo');
    is($finished->{fields}{pushed}, 1, 'the log entry carries the counts');

    my ($plan) = grep { $_->{message} eq 'plan received' } @captured;
    is($plan->{level}, 'debug', 'the plan is logged at debug');
    is($plan->{fields}{actions}, 1, 'the plan entry counts the actions');
}

# ----------------------------------- the settings command
{
    my $dir = tempdir(CLEANUP => 1);
    my $settings = write_json(
        File::Spec->catfile($dir, 'app-filesync.json'),
        qq({"App__FileSync":{"ssh_identity":"/home/me/.ssh/id_filesync"}}\n),
    );

    local $ENV{FILESYNC_SETTINGS} = $settings;

    # The repos come from the client config: one overrides the identity, one
    # inherits everything, one uses the local transport.
    my $client_config = write_json(
        File::Spec->catfile($dir, 'config.json'),
        qq({"repos":{"docs":{"transport":"ssh","server":"srv","identity":"/home/me/.ssh/docs_key"},"mirror":{"transport":"ssh","server":"srv","port":2222,"host_key_checking":"accept-new"},"localdocs":{"transport":"local","server_root":"/srv/filesync"}}}\n),
    );
    local $ENV{FILESYNC_CONFIG} = $client_config;

    my $output = `$^X $filesync settings 2>&1`;
    is($?, 0, 'filesync settings exits 0');
    like($output, qr/^settings file: \Q$settings\E$/m, 'it names the settings file');
    like($output, qr/^\s+ssh_identity\s+\/home\/me\/\.ssh\/id_filesync\s+file \Q$settings\E \[App__FileSync\]$/m,
        'it shows an SSH default and where it came from');
    like($output, qr/^\s+server_command\s+filesync-server\s+built-in default$/m,
        'it shows the transport default for the remote program');
    like($output, qr/^\s+log_file\s+\(stderr\)/m, 'an empty log_file is shown as stderr');

    like($output, qr/^repos:$/m, 'the repos are listed');
    like($output, qr/^  docs \(ssh, srv\)$/m, 'a repo names its transport and server');
    like($output, qr/^    ssh_identity\s+\/home\/me\/\.ssh\/docs_key\s+repo \(\Q$client_config\E \[docs\]\)$/m,
        'a repo value says the repo supplied it');
    like($output, qr/^    ssh_known_hosts\s+\(ssh default\)\s+ssh default$/m,
        'an unset value says ssh supplied it');
    like($output, qr/^    server_command\s+filesync-server\s+process \(built-in default\)$/m,
        'an inherited value says the process settings supplied it');
    like($output, qr/^    port\s+22\s+ssh default \[repo only\]$/m,
        'an unset port still says the key is repo only');
    like($output, qr/^  mirror \(ssh, srv\)$/m, 'the second SSH repo is listed');
    like($output, qr/^    port\s+2222\s+repo \(\Q$client_config\E \[mirror\]\) \[repo only\]$/m,
        'a repo port is marked repo only');
    like($output, qr/^    host_key_checking\s+accept-new\s+repo \(\Q$client_config\E \[mirror\]\) \[repo only\]$/m,
        'a repo host-key policy is marked repo only');
    like($output, qr/local transport does not use the SSH settings/,
        'a local repo has no SSH rows');

    $output = `$^X $filesync settings --json 2>&1`;
    is($?, 0, 'filesync settings --json exits 0');
    my $decoded = eval { App::FileSync::json_decode($output) };
    ok(ref($decoded) eq 'HASH', 'the JSON parses');
    is($decoded->{settings_file}, $settings, 'the JSON names the settings file');
    is(scalar @{ $decoded->{settings} }, 6, 'the JSON has a row per setting');
    my ($identity_row) = grep { $_->{key} eq 'ssh_identity' } @{ $decoded->{settings} };
    is($identity_row->{value}, '/home/me/.ssh/id_filesync', 'the JSON carries the value');
    is($identity_row->{source}, 'file', 'the JSON carries the source kind');

    is($decoded->{config_file}, $client_config, 'the JSON names the client config');
    is(scalar @{ $decoded->{repos} }, 3, 'the JSON has a row per repo');
    my ($docs) = grep { $_->{repo} eq 'docs' } @{ $decoded->{repos} };
    my %repo_ssh = map { $_->{key} => $_ } @{ $docs->{ssh} };
    is($repo_ssh{ssh_identity}{value}, '/home/me/.ssh/docs_key',
        'the JSON carries the repo override');
    is($repo_ssh{ssh_identity}{source}, 'repo', 'with its source');
    is($repo_ssh{ssh_identity}{label}, "$client_config [docs]", 'and label');
    is($repo_ssh{ssh_known_hosts}{source}, 'default',
        'an unset key is a transport default in the JSON');
    is($repo_ssh{server_command}{value}, 'filesync-server',
        'the inherited remote program is effective');
    is($repo_ssh{server_command}{source}, 'process', 'and attributed to the settings');
    is($repo_ssh{port}{value}, 22, 'an unset port is effective in the JSON');
    ok($repo_ssh{port}{repo_only}, 'and still marks the key repo only');

    my ($mirror) = grep { $_->{repo} eq 'mirror' } @{ $decoded->{repos} };
    my %mirror_ssh = map { $_->{key} => $_ } @{ $mirror->{ssh} };
    is($mirror_ssh{port}{value}, 2222, 'the JSON carries the repo port');
    ok($mirror_ssh{port}{repo_only}, 'marked repo only');
    is($mirror_ssh{host_key_checking}{value}, 'accept-new',
        'the JSON carries the repo host-key policy');
    ok($mirror_ssh{host_key_checking}{repo_only}, 'marked repo only');

    my ($local) = grep { $_->{repo} eq 'localdocs' } @{ $decoded->{repos} };
    is($local->{ssh}, undef, 'the local repo has no SSH rows in the JSON');

    $output = `$^X $filesync settings extra 2>&1`;
    isnt($?, 0, 'a stray argument is an error');
    like($output, qr/settings: unexpected arguments: extra/, 'and names it');
}

# --------------------------------------------------------------- the CLI
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);
    $env->sync();

    my $output = `$^X $filesync sync --repo docs --verbose 2>&1`;
    is($?, 0, 'sync --verbose exits 0');
    like($output, qr/DEBUG: plan received/, '--verbose shows debug logging');
    like($output, qr/INFO: sync finished/, '--verbose shows the run summary in the log');

    $output = `$^X $filesync sync --repo nosuch 2>&1`;
    is($? >> 8, 1, 'a fatal error exits 1');
    like($output, qr/ERROR: No repo 'nosuch'/, 'fatal errors go through the logger');

    my $dir = tempdir(CLEANUP => 1);
    my $settings = write_json(
        File::Spec->catfile($dir, 'settings.json'),
        qq({"App__FileSync":{"log_level":"debug"}}\n),
    );

    local $ENV{FILESYNC_SETTINGS} = $settings;
    $env->write_file('client', 'a.txt', "changed\n", 1_700_000_100);

    $output = `$^X $filesync sync --repo docs 2>&1`;
    is($?, 0, 'a configured debug level still exits 0');
    like($output, qr/INFO: sync finished/, 'the settings file raises the log level');

    $output = `$^X $filesync sync --repo docs --quiet 2>&1`;
    is($?, 0, '--quiet exits 0');
    unlike($output, qr/INFO: sync finished/, '--quiet wins over the settings file');
}

done_testing();
