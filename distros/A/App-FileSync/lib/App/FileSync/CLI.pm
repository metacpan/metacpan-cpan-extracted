package App::FileSync::CLI;

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use Sys::Hostname ();

use App::FileSync qw(json_encode format_utc);
use App::FileSync::Admin;
use App::FileSync::Client;
use App::FileSync::Config;
use App::FileSync::Protocol;
use App::FileSync::Server;
use App::FileSync::Settings;
use App::FileSync::Transport::SSH;

sub run_client {
	my (@args) = @_;

	my $code = eval { _client_dispatch(@args) };
	if (my $error = $@) {
		chomp $error;
		_report_error($error);
		return 1;
	}

	return $code;
}

sub _logger {
	my (%opts) = @_;
	return App::FileSync::Settings::logger(%opts);
}

# An unusable settings file must not hide the error that says so.
sub _report_error {
	my ($error) = @_;

    my $logger = eval { _logger() };
    if ($logger) {
        $logger->error($error);
        return 1;
    }

    print STDERR "$error\n";
    return 0;
}

sub run_admin {
    my (@args) = @_;

    my $code = eval { _admin_dispatch(@args) };
    if (my $error = $@) {
        chomp $error;
        _report_error($error);
        return 1;
    }

    return $code;
}

sub run_server {
    my (@args) = @_;

    my $code = eval { _server_main(@args) };
    if (my $error = $@) {
        chomp $error;
        _report_error($error);
        return 1;
    }

    return $code;
}

sub _server_main {
    my (@args) = @_;

    my ($root, $repo, $client, $role, $proto, $forced);
    GetOptionsFromArray(\@args,
        'root=s'   => \$root,
        'repo=s'   => \$repo,
        'client=s' => \$client,
        'role=s'   => \$role,
        'proto=i'  => \$proto,
        'forced'   => \$forced,
    ) or die "Usage: filesync-server [--root DIR] --repo NAME --client ID "
        . "--role client|replica [--proto 2]\n";

    die "filesync-server: unexpected arguments: @args\n" if @args;

    # Under sshd the root comes from the forced command (or FILESYNC_ROOT) and is
    # never taken from the client.
    $root = $ENV{FILESYNC_ROOT} if !defined($root) || !length($root);
    $root = '/srv/filesync'    if !defined($root) || !length($root);

    die "filesync-server: --repo is required\n"   unless defined $repo && length $repo;
    die "filesync-server: --client is required\n" unless defined $client && length $client;
    die "filesync-server: --role is required\n"   unless defined $role && length $role;
    die "filesync-server: bad role '$role'\n"     unless $role eq 'client' || $role eq 'replica';
    die "filesync-server: unsupported protocol '$proto'\n"
        if defined $proto && $proto != $App::FileSync::Server::PROTO;

    if (defined $ENV{SSH_ORIGINAL_COMMAND} && length $ENV{SSH_ORIGINAL_COMMAND}) {
        my ($ok, $reason) = App::FileSync::Server::validate_forced_command(
            $ENV{SSH_ORIGINAL_COMMAND},
            { repo => $repo, client => $client, role => $role,
              root => $root },
        );
        die "filesync-server: $reason\n" unless $ok;
    }

    if (-t STDIN && !$ENV{FILESYNC_ALLOW_TTY}) {
        die "filesync-server speaks the sync protocol on stdin and is not for interactive "
            . "use; it is the forced command in authorized_keys\n";
    }

    my $connection = App::FileSync::Protocol->new(in => \*STDIN, out => \*STDOUT);
    my $server = App::FileSync::Server->new(
        root       => $root,
        repo       => $repo,
        client     => $client,
        role       => $role,
        connection => $connection,
        logger     => _logger(),
    );

    return $server->run() ? 0 : 1;
}

sub _client_dispatch {
    my (@args) = @_;

    my $command = shift @args;
    $command = 'help' unless defined $command;

    return _client_help() if $command eq 'help' || $command eq '--help';
    return _client_version() if $command eq 'version';
    return _client_init(@args) if $command eq 'init';
    return _client_sync(@args) if $command eq 'sync';
    return _client_status(@args) if $command eq 'status';
    return _client_log(@args) if $command eq 'log';
    return _client_settings(@args) if $command eq 'settings';
    return _client_verify(@args) if $command eq 'verify';
    return _client_restore(@args) if $command eq 'restore';
    return _client_snapshot(@args) if $command eq 'snapshot';

    die "Unknown command '$command' (try: filesync help)\n";
}

sub _client_help {
    print <<'USAGE';
filesync - keep a directory in step with a master copy

    filesync init --repo NAME --root DIR --server USER@HOST [--remote-repo NAME]
                  [--id ID] [--role client|replica] [--port N] [--identity FILE]
                  [--accept-host-key] [--known-hosts FILE] [--server-command PATH]
                  [--snapshot-mode hardlink|copy]
    filesync init --repo NAME --root DIR --transport local --server-root DIR
                  [--remote-repo NAME] [--id ID] [--role client|replica]
    filesync sync   [--repo NAME]... [--dry-run] [--force] [--verbose] [--quiet]
                    [--json] [--no-prune] [--no-delta]
    filesync status [--repo NAME] [--json]
    filesync log    [--repo NAME] [-n N] [--since YYYY-MM-DD|EPOCH]
                    [--until YYYY-MM-DD|EPOCH] [--exit N]... [--warnings] [--json]
    filesync settings [--config FILE] [--json]
    filesync verify [--repo NAME] [--deep] [--json]
    filesync restore PATH [--repo NAME] [--to DIR] [--list]
    filesync snapshot [--repo NAME] [--keep N]
    filesync snapshot list [--repo NAME]
    filesync snapshot restore DATE [PATH] [--repo NAME] [--to DIR]
    filesync version

The sync root must contain the .filesync-root marker created by "filesync init".
Diagnostics go to stderr; settings are read from ~/.conf/app-filesync.json or
$FILESYNC_SETTINGS (log_level, log_format, log_file, ssh_identity,
ssh_known_hosts, server_command).  "filesync settings" prints the effective
values and where each came from.  Per-repo values from "filesync init" win;
port and host_key_checking exist per repo only and are marked [repo only].

Exit codes: 0 ok, 1 fatal, 2 another run holds the lock, 3 completed with
warnings, 4 verification found drift.
USAGE

    return 0;
}

sub _client_version {
    print "filesync $App::FileSync::VERSION (protocol 2)\n";
    return 0;
}

sub _client_init {
    my (@args) = @_;

    my ($repo, $root, $server, $remote, $id, $port, $identity, $role,
        $transport, $server_root, $config_path, $accept_host_key, $known_hosts,
        $server_command, $snapshot_mode);
    GetOptionsFromArray(\@args,
        'repo=s'          => \$repo,
        'root=s'          => \$root,
        'server=s'        => \$server,
        'remote-repo=s'   => \$remote,
        'id=s'            => \$id,
        'port=i'          => \$port,
        'identity=s'      => \$identity,
        'role=s'          => \$role,
        'transport=s'     => \$transport,
        'server-root=s'   => \$server_root,
        'config=s'        => \$config_path,
        'accept-host-key' => \$accept_host_key,
        'known-hosts=s'   => \$known_hosts,
        'server-command=s' => \$server_command,
        'snapshot-mode=s'  => \$snapshot_mode,
    ) or die "Usage: filesync init --repo NAME --root DIR ...\n";

    die "init: --repo is required\n" unless defined $repo && length $repo;
    die "init: --root is required\n" unless defined $root && length $root;
    die "init: bad repo name '$repo'\n"
        unless $repo =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;

    $role = 'client' unless defined $role;
    die "init: bad role '$role'\n" unless $role eq 'client' || $role eq 'replica';

    die "init: bad snapshot mode '$snapshot_mode' (want hardlink or copy)\n"
        if defined $snapshot_mode && length $snapshot_mode
            && $snapshot_mode ne 'hardlink' && $snapshot_mode ne 'copy';

    my $use = $transport || ($server_root ? 'local' : 'ssh');
    die "init: unknown transport '$use'\n" unless $use eq 'local' || $use eq 'ssh';
    die "init: the local transport needs --server-root\n"
        if $use eq 'local' && !(defined $server_root && length $server_root);
    die "init: the ssh transport needs --server\n"
        if $use eq 'ssh' && !(defined $server && length $server);

    if ($use eq 'ssh' && !App::FileSync::Transport::SSH::valid_server($server)) {
        die "init: bad server '$server' (want user\@host or host)\n";
    }

    die "init: --known-hosts does not exist: $known_hosts\n"
        if defined $known_hosts && length $known_hosts && !-f $known_hosts;

    die "init: --accept-host-key only applies to the ssh transport\n"
        if $accept_host_key && $use ne 'ssh';

    make_path($root) unless -d $root;
    die "init: cannot use $root as a sync root\n" unless -d $root;
    $root = abs_path($root);

    my $marker = File::Spec->catfile($root, '.filesync-root');
    unless (-e $marker) {
        open my $fh, '>', $marker or die "Cannot create $marker: $!\n";
        print {$fh} "This directory is a filesync root; do not delete this file.\n";
        close $fh;
    }

    if (defined $server_root) {
        make_path($server_root) unless -d $server_root;
        $server_root = abs_path($server_root);
    }

    my $config = App::FileSync::Config::load_client($config_path);

    unless (defined $config->{client_id} && length $config->{client_id}) {
        $config->{client_id} = _default_client_id();
    }
    $config->{client_id} = $id if defined $id && length $id;

    $config->{repos}{$repo} = {
        root             => $root,
        remote_repo      => defined $remote && length $remote ? $remote : $repo,
        role             => $role,
        transport        => $use,
        local_trash_days => 30,
        (defined $server_root ? (server_root => $server_root) : ()),
        (defined $server      ? (server      => $server)      : ()),
        (defined $port        ? (port        => $port)        : ()),
        (defined $identity    ? (identity    => $identity)    : ()),
        ($accept_host_key     ? (host_key_checking => 'accept-new') : ()),
        (defined $known_hosts ? (known_hosts => $known_hosts) : ()),
        (defined $server_command && length $server_command
            ? (server_command => $server_command) : ()),
        (defined $snapshot_mode && length $snapshot_mode
            ? (snapshot_mode => $snapshot_mode) : ()),
    };

    my $path = App::FileSync::Config::save_client($config, $config_path);

    print "Initialised repo '$repo'\n";
    print "  client id: $config->{client_id}\n";
    print "  root:      $root\n";
    print "  transport: $use\n";
    if ($use eq 'ssh') {
        print "  server:    $server\n";
        print '  host key:  ',
            $accept_host_key ? "accept-new (trusted on first use)\n" : "strict\n";
    }
    print "  config:    $path\n";

    return 0;
}

sub _client_sync {
    my (@args) = @_;

    my (@repos, $dry_run, $force, $verbose, $quiet, $json, $no_prune, $no_delta, $config_path);
    GetOptionsFromArray(\@args,
        'repo=s@'    => \@repos,
        'dry-run'    => \$dry_run,
        'force'      => \$force,
        'verbose'    => \$verbose,
        'quiet'      => \$quiet,
        'json'       => \$json,
        'no-prune'   => \$no_prune,
        'no-delta'   => \$no_delta,
        'config=s'   => \$config_path,
    ) or die "Usage: filesync sync [--repo NAME] [--dry-run] [--force]\n";

    my $config = App::FileSync::Config::load_client($config_path);

    die "No repos configured; run filesync init first\n"
        unless keys %{ $config->{repos} };

    @repos = sort keys %{ $config->{repos} } unless @repos;

    for my $name (@repos) {
        die "No repo '$name' in the configuration\n"
            unless $config->{repos}{$name};
    }

    my (@results, @errors);
    my $fatal = 0;
    my $warned = 0;
    my $locked = 0;

    my $logger = _logger(verbose => $verbose, quiet => $quiet);

    for my $name (@repos) {
        my $result = eval {
            App::FileSync::Client->new(
                config => $config,
                name   => $name,
                opts   => {
                    dry_run  => $dry_run,
                    force    => $force,
                    no_prune => $no_prune,
                    no_delta => $no_delta,
                    verbose  => $verbose,
                },
                logger => $logger,
            )->sync();
        };

        if (my $error = $@) {
            chomp $error;
            push @errors, { repo => $name, error => $error };
            $logger->error("$name: $error") unless $json;
            $fatal = 1;
            next;
        }

        push @results, $result;
        if (($result->{exit} || 0) == 2) {
            $locked = 1;
            $logger->warn("$name: $result->{error}")
                unless $json || $quiet;
            next;
        }
        $warned = 1 if ($result->{exit} || 0) == 3;

        next if $json;

        if ($dry_run) {
            for my $action (@{ $result->{actions} || [] }) {
                my $verb = $action->{a};
                $verb =~ s/_/ /g;
                print '  would ', $verb, ' ', $action->{p}, "\n";
            }
        }

        my $summary = $result->{summary} || {};
        printf "%s%s: pulled %d, pushed %d, deleted %d, conflicts %d\n",
            $name,
            $dry_run ? ' (dry run)' : '',
            $summary->{pulled}    || 0,
            $summary->{pushed}    || 0,
            $summary->{deleted}   || 0,
            $summary->{conflicts} || 0;

        # A dry run sends no file payloads, so it has nothing to account for.
        print '  transfer: ', _transfer_report($summary), "\n" unless $dry_run;

        next if $quiet;
        for my $warning (@{ $result->{warnings} || [] }) {
            print "  warning: $warning\n";
        }
    }

    if ($json) {
        print json_encode({
            results => \@results,
            errors  => \@errors,
        }), "\n";
    }

    return 1 if $fatal;
    return 3 if $warned;
    return 2 if $locked;
    return 0;
}

sub _client_status {
    my (@args) = @_;

    my (@repos, $json, $config_path);
    GetOptionsFromArray(\@args, 'repo=s@' => \@repos, 'json' => \$json, 'config=s' => \$config_path)
        or die "Usage: filesync status [--repo NAME] [--json]\n";

    my $config = App::FileSync::Config::load_client($config_path);
    @repos = sort keys %{ $config->{repos} } unless @repos;

    my @status;
    for my $name (@repos) {
        die "No repo '$name' in the configuration\n"
            unless $config->{repos}{$name};

        my $repo = $config->{repos}{$name};
        my $cache_path = File::Spec->catfile(
            App::FileSync::Config::home_dir(), 'cache', "$name.json"
        );

        my $cache;
        if (-e $cache_path) {
            $cache = eval { App::FileSync::json_decode(App::FileSync::read_text($cache_path)) };
        }

        my $last = $cache && ref($cache) eq 'HASH' ? $cache->{last_run} : undef;

        push @status, {
            repo       => $name,
            root       => $repo->{root},
            transport  => $repo->{transport} || 'ssh',
            last_run   => $last ? scalar(gmtime($last->{ts})) . ' UTC' : 'never',
            last_summary => $last ? $last->{summary} : undef,
            files      => $cache && $cache->{entries}
                ? scalar(grep { ($cache->{entries}{$_}{t} || 'f') eq 'f' } keys %{ $cache->{entries} })
                : 0,
        };
    }

    if ($json) {
        print json_encode({ repos => \@status }), "\n";
    } else {
        for my $entry (@status) {
            print "$entry->{repo}: $entry->{root}\n";
            print "  transport: $entry->{transport}\n";
            print "  last run:  $entry->{last_run}\n";

            # Caches written before the byte counters existed have no transfer
            # figures; skip the line rather than invent zeros.
            my $summary = $entry->{last_summary};
            if (ref($summary) eq 'HASH' && defined $summary->{bytes_sent}) {
                print '  transfer:  ', _transfer_report($summary), "\n";
            }

            print "  files:     $entry->{files}\n";
        }
    }

    return 0;
}

sub _client_log {
    my (@args) = @_;

    my (@repos, @exits, $limit, $since, $until, $json, $config_path, $warnings);
    GetOptionsFromArray(\@args,
        'repo=s@'  => \@repos,
        'n=i'      => \$limit,
        'since=s'  => \$since,
        'until=s'  => \$until,
        'exit=i@'  => \@exits,
        'warnings' => \$warnings,
        'json'     => \$json,
        'config=s' => \$config_path,
    ) or die "Usage: filesync log [--repo NAME] [-n N] [--since DATE] [--until DATE] "
        . "[--exit N] [--warnings] [--json]\n";
    die "log: unexpected arguments: @args\n" if @args;
    die "log: -n must be positive\n" if defined $limit && $limit < 1;
    die "log: --exit must be between 0 and 255\n"
        if grep { $_ < 0 || $_ > 255 } @exits;

    # Report a bad date before any repo is touched.
    App::FileSync::parse_since($since) if defined $since;
    App::FileSync::parse_until($until) if defined $until;

    my $config = App::FileSync::Config::load_client($config_path);
    die "No repos configured; run filesync init first\n"
        unless keys %{ $config->{repos} };

    @repos = sort keys %{ $config->{repos} } unless @repos;

    my @results;

    for my $name (@repos) {
        die "No repo '$name' in the configuration\n"
            unless $config->{repos}{$name};

        my $result = App::FileSync::Client->new(
            config => $config,
            name   => $name,
        )->log(limit => $limit, since => $since, until => $until,
            exits => \@exits, warnings => $warnings);

        push @results, $result;
        next if $json;

        if (!@{ $result->{runs} }) {
            print "$name: no runs recorded\n";
            next;
        }

        for my $run (@{ $result->{runs} }) {
            my $summary = $run->{summary} || {};

            # A failed or lock-refused attempt has no counts worth printing;
            # the message is what explains it.
            if (defined $run->{error} && length $run->{error}) {
                my $message = $run->{error};
                $message =~ s/\s+/ /g;
                printf "%s  %s  exit %d  %s\n",
                    $name, format_utc($run->{ts}), $run->{exit} || 0, $message;
                next;
            }

            # Older entries predate the byte counters; they keep the shorter line.
            my $transfer = !$run->{dry_run} && defined $summary->{bytes_sent}
                ? ', ' . _transfer_report($summary)
                : '';

            printf "%s  %s  exit %d  pulled %d, pushed %d, deleted %d, conflicts %d%s%s%s\n",
                $name,
                format_utc($run->{ts}),
                $run->{exit} || 0,
                $summary->{pulled}    || 0,
                $summary->{pushed}    || 0,
                $summary->{deleted}   || 0,
                $summary->{conflicts} || 0,
                $summary->{skipped} ? ", skipped $summary->{skipped}" : '',
                $transfer,
                $run->{dry_run} ? '  (dry run)' : '';

            for my $warning (@{ $run->{warnings} || [] }) {
                print "  warning: $warning\n";
            }
        }
    }

    if ($json) {
        print json_encode({ results => \@results }), "\n";
    }

    return 0;
}

sub _client_settings {
    my (@args) = @_;

    my ($json, $config_path);
    GetOptionsFromArray(\@args, 'json' => \$json, 'config=s' => \$config_path)
        or die "Usage: filesync settings [--config FILE] [--json]\n";
    die "settings: unexpected arguments: @args\n" if @args;

    my $report = App::FileSync::Settings::explain();
    my $file   = $report->{settings_file};

    my $client_config = App::FileSync::Config::load_client($config_path);
    my $client_file   = defined $config_path && length $config_path
        ? $config_path
        : App::FileSync::Config::client_config_path();

    $report->{config_file} = $client_file;
    $report->{repos} = App::FileSync::Settings::explain_repos(
        config      => $client_config,
        report      => $report,
        config_file => $client_file,
    );

    if ($json) {
        print json_encode($report), "\n";
        return 0;
    }

    print 'settings file: ', (defined $file && length $file ? $file : '(none)'), "\n\n";

    for my $row (@{ $report->{settings} }) {
        printf "  %-16s %-40s %s\n",
            $row->{key}, _display_setting($row->{key}, $row->{value}), _describe_source($row);
    }

    print "\nAn empty ssh_identity or ssh_known_hosts means ssh's own default; "
        . "an empty server_command means filesync-server.\n";
    print "In the repo sections, [repo only] marks port and host_key_checking, "
        . "which have no process-wide default.\n";

    if (my @repos = @{ $report->{repos} || [] }) {
        print "\nrepos:\n";
        for my $repo (@repos) {
            printf "  %s (%s%s)\n",
                $repo->{repo},
                $repo->{transport},
                defined $repo->{server} ? ", $repo->{server}" : '';

            if (!defined $repo->{ssh}) {
                print "    the local transport does not use the SSH settings\n";
                next;
            }

            for my $row (@{ $repo->{ssh} }) {
                printf "    %-18s %-38s %s\n",
                    $row->{key},
                    _display_setting($row->{key}, $row->{value}),
                    _describe_repo_source($row);
            }
        }
    }

    return 0;
}

sub _describe_repo_source {
    my ($row) = @_;

    my $description =
          $row->{source} eq 'repo'    ? "repo ($row->{label})"
        : $row->{source} eq 'process' ? "process ($row->{label})"
        :                               $row->{label};

    # Port and host-key checking have no process-wide fallback, so say so.
    return $row->{repo_only} ? "$description [repo only]" : $description;
}

# Blank means "use the transport default" for these, so name that explicitly
# rather than printing an empty column.
sub _display_setting {
    my ($key, $value) = @_;

    my $blank = !defined($value) || !length($value);

    return '(stderr)'        if $blank && $key eq 'log_file';
    return '(ssh default)'   if $blank && $key eq 'ssh_identity';
    return '(ssh default)'   if $blank && $key eq 'ssh_known_hosts';
    return 'filesync-server' if $blank && $key eq 'server_command';

    return defined $value ? $value : '';
}

sub _describe_source {
    my ($row) = @_;

    return $row->{label} if $row->{source} eq 'default';
    return "merged: $row->{label}" if $row->{source} eq 'merged';
    return "environment $row->{label}" if $row->{source} eq 'env';
    return "file $row->{label}";
}

sub _client_verify {
    my (@args) = @_;

    my (@repos, $deep, $json, $config_path);
    GetOptionsFromArray(\@args,
        'repo=s@'  => \@repos,
        'deep'     => \$deep,
        'json'     => \$json,
        'config=s' => \$config_path,
    ) or die "Usage: filesync verify [--repo NAME] [--deep] [--json]\n";
    die "verify: unexpected arguments: @args\n" if @args;

    my $config = App::FileSync::Config::load_client($config_path);
    die "No repos configured; run filesync init first\n"
        unless keys %{ $config->{repos} };

    @repos = sort keys %{ $config->{repos} } unless @repos;

    my @reports;
    for my $name (@repos) {
        die "No repo '$name' in the configuration\n"
            unless $config->{repos}{$name};

        push @reports, App::FileSync::Client->new(
            config => $config,
            name   => $name,
        )->verify(deep => $deep);
    }

    if ($json) {
        print json_encode({ results => \@reports }), "\n";
        return (grep { !$_->{ok} } @reports) ? 4 : 0;
    }

    for my $report (@reports) {
        printf "%s: %s (%s, %d rehashed, %d unchanged)\n",
            $report->{repo},
            $report->{ok} ? 'clean' : 'drift detected',
            _plural($report->{files}, 'file'),
            $report->{rehashed},
            $report->{trusted};

        print "  no cached base for this repo (it has not synced yet)\n"
            unless $report->{known};

        for my $entry (@{ $report->{modified} }) {
            print "  modified: $entry->{p}",
                (defined $entry->{reason} ? " ($entry->{reason})" : ''), "\n";
        }
        print "  missing:  $_->{p}\n" for @{ $report->{missing} };
        print "  extra:    $_->{p}\n" for @{ $report->{extra} };
    }

    return (grep { !$_->{ok} } @reports) ? 4 : 0;
}

sub _client_restore {
    my (@args) = @_;

    my ($repo_name, $to, $list, $config_path);
    GetOptionsFromArray(\@args,
        'repo=s'   => \$repo_name,
        'to=s'     => \$to,
        'list'     => \$list,
        'config=s' => \$config_path,
    ) or die "Usage: filesync restore PATH [--repo NAME] [--to DIR] [--list]\n";

    my $path = shift @args;
    die "restore: PATH is required\n" unless defined $path && length $path;
    die "restore: unexpected arguments: @args\n" if @args;

    my $config = App::FileSync::Config::load_client($config_path);
    my @names = sort keys %{ $config->{repos} };
    die "No repos configured; run filesync init first\n" unless @names;

    $repo_name = $names[0] if !defined $repo_name && @names == 1;
    die "restore: --repo is required when several repos are configured\n"
        unless defined $repo_name;
    die "No repo '$repo_name' in the configuration\n"
        unless $config->{repos}{$repo_name};

    my $result = App::FileSync::Client->new(
        config => $config,
        name   => $repo_name,
    )->restore(path => $path, to => $to, list => $list);

    if ($list) {
        if (!@{ $result->{versions} }) {
            print "No trashed versions of '$path'\n";
            return 0;
        }

        for my $version (@{ $result->{versions} }) {
            printf "%-12s %10s  %s  %s\n",
                (defined $version->{date} ? $version->{date} : '-'),
                (defined $version->{size} ? _format_bytes($version->{size}) : '-'),
                (defined $version->{mtime}
                    ? scalar(gmtime($version->{mtime})) . ' UTC'
                    : '-'),
                $version->{path};
        }

        return 0;
    }

    print "Restored $path to $result->{to}\n";
    return 0;
}

sub _client_snapshot {
    my (@args) = @_;

    my $verb = @args && $args[0] !~ /\A-/ ? shift @args : 'create';

    return _client_snapshot_create(@args) if $verb eq 'create' || $verb eq 'take';
    return _client_snapshot_list(@args)   if $verb eq 'list';
    return _client_snapshot_restore(@args) if $verb eq 'restore';

    die "Unknown snapshot command '$verb' (try: filesync help)\n";
}

sub _client_snapshot_create {
    my (@args) = @_;

    my ($repo_name, $keep, $config_path);
    GetOptionsFromArray(\@args,
        'repo=s'   => \$repo_name,
        'keep=i'   => \$keep,
        'config=s' => \$config_path,
    ) or die "Usage: filesync snapshot [--repo NAME] [--keep N]\n";
    die "snapshot: unexpected arguments: @args\n" if @args;

    die "snapshot: --keep must be positive\n" if defined $keep && $keep < 1;

    my $config = App::FileSync::Config::load_client($config_path);
    my @names = sort keys %{ $config->{repos} };
    die "No repos configured; run filesync init first\n" unless @names;

    $repo_name = $names[0] if !defined $repo_name && @names == 1;
    die "snapshot: --repo is required when several repos are configured\n"
        unless defined $repo_name;
    die "No repo '$repo_name' in the configuration\n"
        unless $config->{repos}{$repo_name};

    my $result = App::FileSync::Client->new(
        config => $config,
        name   => $repo_name,
    )->snapshot_create(keep => $keep);

    if (($result->{exit} || 0) == 2) {
        _logger()->warn("$repo_name: $result->{error}");
        return 2;
    }

    unless ($result->{created}) {
        print "$repo_name: snapshot $result->{date} already exists; left as it was\n";
        return 0;
    }

    printf "%s: snapshot %s taken (%s, %s) in %s\n",
        $repo_name,
        $result->{date},
        _plural($result->{files}, 'file'),
        _format_bytes($result->{bytes}),
        $result->{path};

    if (my @pruned = @{ $result->{pruned} || [] }) {
        printf "%s: pruned %d old snapshot%s (kept %d): %s\n",
            $repo_name, scalar @pruned, @pruned == 1 ? '' : 's',
            scalar @{ $result->{older} || [] }, join(' ', @pruned);
    }

    return 0;
}

sub _client_snapshot_list {
    my (@args) = @_;

    my ($repo_name, $config_path);
    GetOptionsFromArray(\@args, 'repo=s' => \$repo_name, 'config=s' => \$config_path)
        or die "Usage: filesync snapshot list [--repo NAME]\n";
    die "snapshot list: unexpected arguments: @args\n" if @args;

    my $config = App::FileSync::Config::load_client($config_path);
    my @names = sort keys %{ $config->{repos} };
    die "No repos configured; run filesync init first\n" unless @names;

    $repo_name = $names[0] if !defined $repo_name && @names == 1;
    die "snapshot list: --repo is required when several repos are configured\n"
        unless defined $repo_name;
    die "No repo '$repo_name' in the configuration\n"
        unless $config->{repos}{$repo_name};

    my $result = App::FileSync::Client->new(
        config => $config,
        name   => $repo_name,
    )->snapshot_list();

    my $snapshots = $result->{snapshots};
    if (!@{$snapshots}) {
        print "No snapshots for $repo_name\n";
        return 0;
    }

    printf "%-12s %8s %10s  %s\n", 'DATE', 'FILES', 'SIZE', 'PATH';
    for my $snapshot (@{$snapshots}) {
        printf "%-12s %8d %10s  %s\n",
            $snapshot->{date},
            $snapshot->{files},
            _format_bytes($snapshot->{bytes}),
            $snapshot->{path};
    }

    return 0;
}

sub _client_snapshot_restore {
    my (@args) = @_;

    my ($repo_name, $to, $config_path);
    GetOptionsFromArray(\@args,
        'repo=s'   => \$repo_name,
        'to=s'     => \$to,
        'config=s' => \$config_path,
    ) or die "Usage: filesync snapshot restore DATE [PATH] [--repo NAME] [--to DIR]\n";

    my $date = shift @args;
    my $path = shift @args;

    die "snapshot restore: DATE is required\n" unless defined $date && length $date;
    die "snapshot restore: unexpected arguments: @args\n" if @args;

    my $config = App::FileSync::Config::load_client($config_path);
    my @names = sort keys %{ $config->{repos} };
    die "No repos configured; run filesync init first\n" unless @names;

    $repo_name = $names[0] if !defined $repo_name && @names == 1;
    die "snapshot restore: --repo is required when several repos are configured\n"
        unless defined $repo_name;
    die "No repo '$repo_name' in the configuration\n"
        unless $config->{repos}{$repo_name};

    my $result = App::FileSync::Client->new(
        config => $config,
        name   => $repo_name,
    )->snapshot_restore(date => $date, path => $path, to => $to);

    if (($result->{exit} || 0) == 2) {
        _logger()->warn("$repo_name: $result->{error}");
        return 2;
    }

    printf "%s: restored %s from snapshot %s (%s, %s) to %s\n",
        $repo_name,
        @{ $result->{paths} } ? join(' ', @{ $result->{paths} }) : 'the whole tree',
        $result->{date},
        _plural($result->{files}, 'file'),
        _format_bytes($result->{bytes}),
        $result->{to};

    if ($result->{into_root}) {
        print "note: a replica mirrors the master again on the next sync; "
            . "use --to DIR to keep an exported copy\n";
    }

    return 0;
}

sub _plural {
    my ($count, $word) = @_;

    $count = 0 unless defined $count;
    return "$count $word" . ($count == 1 ? '' : 's');
}

sub _format_bytes {
    my ($bytes) = @_;

    $bytes = 0 unless defined $bytes;
    return "$bytes B" if $bytes < 1024;
    return sprintf('%.1f kB', $bytes / 1024) if $bytes < 1024 * 1024;
    return sprintf('%.1f MB', $bytes / (1024 * 1024)) if $bytes < 1024 * 1024 * 1024;
    return sprintf('%.1f GB', $bytes / (1024 * 1024 * 1024));
}

# Transfer accounting is exact: these bytes are what the peer actually read
# off the connection, so rounding them would defeat the purpose.
sub _bytes_exact {
    my ($bytes) = @_;

    $bytes = 0 unless defined $bytes && $bytes =~ /\A\d+\z/;
    1 while $bytes =~ s/(\d)(\d{3})\z/$1,$2/;

    return "$bytes B";
}

# One line of per-run accounting: payload bytes in each direction, then how many
# files moved as a delta rather than as a whole file.
sub _transfer_report {
    my ($summary) = @_;

    my $pulled = $summary->{delta_pulled} || 0;
    my $pushed = $summary->{delta_pushed} || 0;

    my @delta;
    push @delta, "$pulled pulled" if $pulled;
    push @delta, "$pushed pushed" if $pushed;

    return sprintf('sent %s, received %s, %s by delta%s',
        _bytes_exact($summary->{bytes_sent}),
        _bytes_exact($summary->{bytes_received}),
        _plural($pulled + $pushed, 'file'),
        @delta ? ' (' . join(', ', @delta) . ')' : '');
}

sub _admin_dispatch {
    my (@args) = @_;

    my $root = $ENV{FILESYNC_ROOT};
    $root = '/srv/filesync' unless defined $root && length $root;

    while (@args && $args[0] =~ /\A--root(?:=(.*))?\z/) {
        if (defined $1) {
            $root = $1;
            shift @args;
        } else {
            shift @args;
            $root = shift @args;
            die "filesync-admin: --root needs a value\n" unless defined $root;
        }
    }

    my $admin = App::FileSync::Admin->new(root => $root);

    my $group = shift @args;
    $group = 'help' unless defined $group;

    if ($group eq 'help' || $group eq '--help') {
        print <<'USAGE';
filesync-admin --root DIR <command>

    repo create NAME [--trash-days N] [--max-deletes N] [--max-delete-percent N]
                     [--ignore PATTERN]...
    repo list
    repo show NAME
    client allow ID --repo NAME [--role client|replica]
    client list --repo NAME
    client forget ID --repo NAME
    reindex NAME [--dry-run] [--json]
    verify NAME [--deep] [--sample N] [--json]
    restore NAME PATH [--to DIR] [--list] [--date YYYY-MM-DD]
    log NAME... [-n N] [--client ID] [--since YYYY-MM-DD|EPOCH]
                  [--until YYYY-MM-DD|EPOCH] [--exit N]... [--warnings] [--json]

Exit codes: 0 ok, 1 fatal, 4 verification found drift.
USAGE
        return 0;
    }

    if ($group eq 'repo') {
        my $verb = shift @args;
        $verb = '' unless defined $verb;

        return _admin_repo_create($admin, @args) if $verb eq 'create';
        return _admin_repo_list($admin) if $verb eq 'list';
        return _admin_repo_show($admin, @args) if $verb eq 'show';

        die "Unknown repo command '$verb'\n";
    }

    if ($group eq 'log') {
        return _admin_log($admin, @args);
    }

    if ($group eq 'verify') {
        return _admin_verify($admin, @args);
    }

    if ($group eq 'reindex') {
        return _admin_reindex($admin, @args);
    }

    if ($group eq 'restore') {
        return _admin_restore($admin, @args);
    }

    if ($group eq 'client') {
        my $verb = shift @args;
        $verb = '' unless defined $verb;

        return _admin_client_allow($admin, @args) if $verb eq 'allow';
        return _admin_client_list($admin, @args) if $verb eq 'list';
        return _admin_client_forget($admin, @args) if $verb eq 'forget';

        die "Unknown client command '$verb'\n";
    }

    die "Unknown command '$group' (try: filesync-admin help)\n";
}

sub _admin_repo_create {
    my ($admin, @args) = @_;

    my ($trash_days, $max_deletes, $max_delete_percent, @ignore);
    GetOptionsFromArray(\@args,
        'trash-days=i'         => \$trash_days,
        'max-deletes=i'        => \$max_deletes,
        'max-delete-percent=i' => \$max_delete_percent,
        'ignore=s'             => \@ignore,
    ) or die "Usage: filesync-admin repo create NAME [--trash-days N] ...\n";

    my $name = shift @args;
    die "repo create: NAME is required\n" unless defined $name && length $name;
    die "repo create: unexpected arguments: @args\n" if @args;

    my $result = $admin->repo_create(
        name               => $name,
        trash_days         => $trash_days,
        max_deletes        => $max_deletes,
        max_delete_percent => $max_delete_percent,
        ignore             => \@ignore,
    );

    print "Created repo '$result->{name}'\n";
    print "  master: $result->{master}\n";
    print "  config: $result->{config}\n";

    return 0;
}

sub _admin_repo_list {
    my ($admin) = @_;

    my $repos = $admin->repo_list();
    if (!@{$repos}) {
        print "No repos under $admin->{root}\n";
        return 0;
    }

    print "$_\n" for @{$repos};
    return 0;
}

sub _admin_repo_show {
    my ($admin, @args) = @_;

    my $name = shift @args;
    die "repo show: NAME is required\n" unless defined $name && length $name;

    my $info = $admin->repo_show($name);
    print "name:    $info->{config}{name}\n";
    print "master:  $info->{master}\n";
    print "meta:    $info->{meta}\n";
    print "trash:   $info->{config}{trash_days} days\n";
    print "limits:  $info->{config}{max_deletes} files / "
        . "$info->{config}{max_delete_percent}%\n";
    print "clients: " . (@{ $info->{clients} } ? join(', ', @{ $info->{clients} }) : '(none)') . "\n";

    return 0;
}

sub _admin_log {
    my ($admin, @args) = @_;

    my ($limit, $client, $since, $until, @exits, $json, $warnings);
    GetOptionsFromArray(\@args,
        'n=i'      => \$limit,
        'client=s' => \$client,
        'since=s'  => \$since,
        'until=s'  => \$until,
        'exit=i@'  => \@exits,
        'warnings' => \$warnings,
        'json'     => \$json,
    ) or die "Usage: filesync-admin log NAME... [-n N] [--client ID] [--since DATE] "
        . "[--until DATE] [--exit N] [--warnings] [--json]\n";

    die "log: --exit must be between 0 and 255\n"
        if grep { $_ < 0 || $_ > 255 } @exits;

    # Report a bad date before any repo is touched.
    App::FileSync::parse_since($since) if defined $since;
    App::FileSync::parse_until($until) if defined $until;

    my @names = @args;
    die "log: NAME is required\n" unless @names;
    die "log: NAME must not be empty\n"
        if grep { !defined $_ || !length $_ } @names;

    $limit = 20 unless defined $limit;

    # Check every name before printing, so text mode never shows a partial
    # answer before failing on a later repo.
    App::FileSync::Config::load_repo($admin->root, $_) for @names;

    my $multiple = @names > 1;
    my $indent   = $multiple ? '  ' : '';
    my @results;

    for my $name (@names) {
        my $events = $admin->journal_read(
            repo     => $name,
            limit    => $limit,
            client   => $client,
            since    => $since,
            until    => $until,
            exits    => \@exits,
            warnings => $warnings,
        );

        my %result = (
            repo   => $name,
            path   => $admin->journal_dir($name),
            events => $events,
        );
        $result{client} = $client if defined $client && length $client;
        $result{since}  = App::FileSync::parse_since($since) if defined $since;
        $result{until}  = App::FileSync::parse_until($until) if defined $until;
        $result{exits}  = [ map { $_ + 0 } @exits ] if @exits;
        $result{warnings} = 1 if $warnings;

        push @results, \%result;
        next if $json;

        # With one repo the lines stand alone; with several, head each group.
        print "$name:\n" if $multiple;

        if (!@{$events}) {
            print "No journal entries for $name\n";
            next;
        }

        for my $event (@{$events}) {
            my @detail;

            push @detail, $event->{path} if defined $event->{path};
            push @detail, 'from=' . $event->{from} if defined $event->{from};
            push @detail, 'winner=' . $event->{winner} if defined $event->{winner};
            push @detail, 'loser=' . $event->{loser_name} if defined $event->{loser_name};
            push @detail, 'exit=' . $event->{exit} if defined $event->{exit};
            push @detail, 'trash=' . $event->{trash} if defined $event->{trash};
            push @detail, 'sha256=' . $event->{sha256} if defined $event->{sha256};

            for my $counter (qw(actions deletions conflicts pulled pushed deleted)) {
                push @detail, "$counter=$event->{$counter}" if defined $event->{$counter};
            }

            push @detail, 'dry-run' if $event->{dry_run};
            push @detail, 'locked' if $event->{locked};

            if (defined $event->{error} && length $event->{error}) {
                my $message = $event->{error};
                $message =~ s/\s+/ /g;
                push @detail, $message;
            }

            printf "%s%s  %-12s %-12s %s\n",
                $indent,
                format_utc($event->{ts}),
                defined $event->{client} ? $event->{client} : '-',
                defined $event->{action} ? $event->{action} : '?',
                join(' ', @detail);
        }
    }

    print json_encode({ results => \@results }), "\n" if $json;

    return 0;
}

sub _admin_reindex {
    my ($admin, @args) = @_;

    my ($dry_run, $json);
    GetOptionsFromArray(\@args, 'dry-run' => \$dry_run, 'json' => \$json)
        or die "Usage: filesync-admin reindex NAME [--dry-run] [--json]\n";

    my $name = shift @args;
    die "reindex: NAME is required\n" unless defined $name && length $name;
    die "reindex: unexpected arguments: @args\n" if @args;

    my $result = $admin->reindex(repo => $name, dry_run => $dry_run);

    if ($json) {
        print json_encode($result), "\n";
        return 0;
    }

    printf "%s: %s %s, %s (%s)%s\n",
        $name,
        $dry_run ? 'would index' : 'indexed',
        _plural($result->{files}, 'file'),
        _plural($result->{dirs}, 'empty dir'),
        _format_bytes($result->{bytes}),
        $dry_run ? '; index unchanged' : '; master index written';

    for my $path (sort keys %{ $result->{skipped} || {} }) {
        print "  skipped: $path ($result->{skipped}{$path})\n";
    }

    return 0;
}

sub _admin_verify {
    my ($admin, @args) = @_;

    my ($deep, $sample, $json);
    GetOptionsFromArray(\@args,
        'deep'   => \$deep,
        'sample=i' => \$sample,
        'json'   => \$json,
    ) or die "Usage: filesync-admin verify NAME [--deep] [--sample N] [--json]\n";

    my $name = shift @args;
    die "verify: NAME is required\n" unless defined $name && length $name;
    die "verify: unexpected arguments: @args\n" if @args;
    die "verify: --sample must be positive\n" if defined $sample && $sample < 1;

    my $report = $admin->verify(repo => $name, deep => $deep, sample => $sample);

    if ($json) {
        print json_encode($report), "\n";
        return $report->{ok} ? 0 : 4;
    }

    printf "%s: %s (%s, %d rehashed, %d unchanged)\n",
        $name,
        $report->{ok} ? 'clean' : 'drift detected',
        _plural($report->{files}, 'file'),
        $report->{rehashed},
        $report->{trusted};

    for my $entry (@{ $report->{modified} }) {
        print "  modified: $entry->{p}",
            (defined $entry->{reason} ? " ($entry->{reason})" : ''), "\n";
    }
    print "  missing:  $_->{p}\n" for @{ $report->{missing} };
    print "  extra:    $_->{p}\n" for @{ $report->{extra} };

    return $report->{ok} ? 0 : 4;
}

sub _admin_restore {
    my ($admin, @args) = @_;

    my ($to, $list, $date);
    GetOptionsFromArray(\@args,
        'to=s'   => \$to,
        'list'   => \$list,
        'date=s' => \$date,
    ) or die "Usage: filesync-admin restore NAME PATH [--to DIR] [--list] "
        . "[--date YYYY-MM-DD]\n";

    my $name = shift @args;
    my $path = shift @args;

    die "restore: NAME and PATH are required\n"
        unless defined $name && length $name && defined $path && length $path;
    die "restore: unexpected arguments: @args\n" if @args;

    my $result = $admin->restore(
        repo => $name,
        path => $path,
        to   => $to,
        list => $list,
        date => $date,
    );

    if ($list) {
        if (!@{ $result->{versions} }) {
            print "No trashed versions of '$path' in $name\n";
            return 0;
        }

        for my $version (@{ $result->{versions} }) {
            printf "%-12s %10s  %s  %s\n",
                (defined $version->{date} ? $version->{date} : '-'),
                (defined $version->{size} ? _format_bytes($version->{size}) : '-'),
                (defined $version->{mtime}
                    ? scalar(gmtime($version->{mtime})) . ' UTC'
                    : '-'),
                $version->{path};
        }

        return 0;
    }

    printf "Restored %s:%s from %s to %s\n",
        $name,
        $path,
        (defined $result->{date} ? $result->{date} : 'the trash'),
        $result->{to};

    return 0;
}

sub _admin_client_allow {
    my ($admin, @args) = @_;

    my ($repo, $role);
    GetOptionsFromArray(\@args, 'repo=s' => \$repo, 'role=s' => \$role)
        or die "Usage: filesync-admin client allow ID --repo NAME [--role R]\n";

    my $client = shift @args;
    die "client allow: ID is required\n" unless defined $client && length $client;
    die "client allow: --repo is required\n" unless defined $repo && length $repo;

    my $result = $admin->client_allow(
        repo   => $repo,
        client => $client,
        role   => $role,
    );

    print "Allowed $result->{client} on $repo as $result->{role}\n";
    return 0;
}

sub _admin_client_list {
    my ($admin, @args) = @_;

    my $repo;
    GetOptionsFromArray(\@args, 'repo=s' => \$repo)
        or die "Usage: filesync-admin client list --repo NAME\n";
    die "client list: --repo is required\n" unless defined $repo && length $repo;

    my $clients = $admin->client_list($repo);
    if (!@{$clients}) {
        print "No clients registered for $repo\n";
        return 0;
    }

    for my $client (@{$clients}) {
        printf "%-24s %-8s %s\n", $client->{client}, $client->{role},
            $client->{base} ? 'has synced' : 'never synced';
    }

    return 0;
}

sub _admin_client_forget {
    my ($admin, @args) = @_;

    my $repo;
    GetOptionsFromArray(\@args, 'repo=s' => \$repo)
        or die "Usage: filesync-admin client forget ID --repo NAME\n";
    die "client forget: --repo is required\n" unless defined $repo && length $repo;

    my $client = shift @args;
    die "client forget: ID is required\n" unless defined $client && length $client;

    my $result = $admin->client_forget(repo => $repo, client => $client);
    print $result->{removed}
        ? "Forgot $client (removed $result->{path})\n"
        : "No stored state for $client\n";

    return 0;
}

sub _default_client_id {
    my $name = Sys::Hostname::hostname();
    $name =~ s/\..*//;
    $name = lc $name;
    $name =~ s/[^a-z0-9._-]+/-/g;
    $name =~ s/\A-+|-+\z//g;
    $name = 'client' unless length $name;

    return $name;
}

1;
