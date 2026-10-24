package App::FileSync::Settings;

use strict;
use warnings;

use Config::Abstraction;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use Log::Abstraction;
use Object::Configure;

# Process-wide settings live in Object::Configure; the repos themselves stay in
# ~/.filesync/config.json, which "filesync init" writes and the admin tool edits.
our $DEFAULT_FORMAT  = '%level%: %message%';
our $DEFAULT_LEVEL   = 'warning';
our $CONFIG_BASENAME = 'app-filesync.json';

# Defaults for every SSH repo.  A repo's own config still wins, so one machine
# can point at another identity without repeating the common settings.
our $DEFAULT_SERVER_COMMAND = 'filesync-server';

our @VALID_LEVELS = qw(
    trace debug info informational notice warn warning error err
    crit critical fatal alert emerg emergency panic
);

# The process-wide settings, in the order "filesync settings" prints them.
our @SETTING_KEYS = qw(
    log_level log_format log_file
    ssh_identity ssh_known_hosts server_command
);

# How each repo-level SSH key corresponds to the process setting it falls back
# to.  The names differ only because the repo config uses shorter keys.
our %REPO_SSH_KEYS = (
    ssh_identity    => 'identity',
    ssh_known_hosts => 'known_hosts',
    server_command  => 'server_command',
);
our @REPO_SSH_SETTINGS = qw(ssh_identity ssh_known_hosts server_command);

sub _default_config_path {
    my $path = $ENV{FILESYNC_SETTINGS};
    return $path if defined $path && length $path;

    my $home = $ENV{HOME};
    $home = $ENV{USERPROFILE} if !defined $home || !length $home;
    return undef unless defined $home && length $home;

    return File::Spec->catfile($home, '.conf', $CONFIG_BASENAME);
}

sub config_file {
    my ($given) = @_;

    return $given if defined $given && length $given;

    my $path = _default_config_path();
    return undef unless defined $path && length $path;
    return -e $path ? $path : undef;
}

# Merge the settings file (if any), the UNIVERSAL section and the
# App__FileSync__* environment variables over the built-in defaults.
sub load {
    my (%args) = @_;

    my $config_file = exists $args{config_file}
        ? config_file($args{config_file})
        : config_file();

    my %params = (
        log_level       => $DEFAULT_LEVEL,
        log_format      => $DEFAULT_FORMAT,
        log_file        => '',
        ssh_identity    => '',
        ssh_known_hosts => '',
        server_command  => $DEFAULT_SERVER_COMMAND,
        # We build the logger ourselves; this keeps Object::Configure from
        # constructing its default Log::Log4perl backend as a side effect.
        logger     => [],
    );

    $params{config_file} = $config_file if defined $config_file && length $config_file;
    $params{config_dirs} = $args{config_dirs} if ref($args{config_dirs}) eq 'ARRAY';

    my $settings = Object::Configure::configure('App::FileSync', \%params);
    delete $settings->{logger};

    return $settings;
}

sub _defaults {
    return {
        log_level       => $DEFAULT_LEVEL,
        log_format      => $DEFAULT_FORMAT,
        log_file        => '',
        ssh_identity    => '',
        ssh_known_hosts => '',
        server_command  => $DEFAULT_SERVER_COMMAND,
    };
}

# Where each effective setting came from, for "filesync settings".  The values
# are whatever load() returns; the provenance is reconstructed from the same
# layers Object::Configure merges: the class section of the settings file, the
# UNIVERSAL section beside it, and App__FileSync__* environment variables.
sub explain {
    my (%args) = @_;

    my $config_file = exists $args{config_file}
        ? config_file($args{config_file})
        : config_file();

    my $settings = load(%args);
    my $defaults = _defaults();

    my $class_explanation = {};
    my $universal_file;
    my $universal_explanation = {};
    if (defined $config_file && length $config_file) {
        $class_explanation = _explanation($config_file, 'App__FileSync');
        $universal_file = _universal_file($config_file);
        $universal_explanation = _explanation($universal_file, 'UNIVERSAL')
            if defined $universal_file;
    }

    my @rows;
    for my $key (@SETTING_KEYS) {
        my %row = (
            key    => $key,
            value  => $settings->{$key},
            source => 'default',
            label  => 'built-in default',
        );
        my $winner_value = $defaults->{$key};

        if (defined $config_file && length $config_file) {
            if (my $entry = _pick($universal_explanation, 'UNIVERSAL', $key)) {
                $row{source} = $entry->{type};
                $row{label}  = $entry->{type} eq 'env'
                    ? $entry->{label}
                    : "$universal_file [UNIVERSAL]";
                $winner_value = $entry->{value};
            }
            if (my $entry = _pick($class_explanation, 'App__FileSync', $key)) {
                $row{source} = $entry->{type};
                $row{label}  = $entry->{type} eq 'env'
                    ? $entry->{label}
                    : "$config_file [App__FileSync]";
                $winner_value = $entry->{value};
            }
        } else {
            # No settings file: Object::Configure falls back to environment
            # variables only, universal ones first and class ones last.
            for my $prefix (qw(UNIVERSAL App__FileSync)) {
                my $name = _env_key("${prefix}__$key");
                next unless defined $name;
                $row{source}  = 'env';
                $row{label}   = $name;
                $winner_value = $ENV{$name};
            }
        }

        # A value that no modelled layer accounts for came from somewhere else
        # (a "global" section, say); say so instead of claiming a default.
        if (_differs($settings->{$key}, $winner_value)) {
            $row{source} = 'merged';
            $row{label}  = join(' + ', _labels_for($key, $universal_explanation, $class_explanation))
                || 'unknown source';
        }

        push @rows, \%row;
    }

    return {
        settings_file => $config_file,
        settings      => \@rows,
    };
}

# How the SSH settings resolve for every repo in a client config, for
# "filesync settings".  Each row reports the value the transport will use and
# whether the repo, the process settings or ssh's own default supplied it.
sub explain_repos {
    my (%args) = @_;

    my $config      = ref($args{config}) eq 'HASH' ? $args{config} : {};
    my $report      = ref($args{report}) eq 'HASH' ? $args{report} : {};
    my $config_file = $args{config_file};

    my %process = map { $_->{key} => $_ } @{ $report->{settings} || [] };

    my @repos;
    for my $name (sort keys %{ $config->{repos} || {} }) {
        my $repo = $config->{repos}{$name};
        $repo = {} unless ref($repo) eq 'HASH';

        my $transport = $repo->{transport} || 'ssh';
        my $entry = {
            repo      => $name,
            transport => $transport,
        };
        $entry->{server} = $repo->{server}
            if defined $repo->{server} && length $repo->{server};

        # The local transport never runs ssh, so there is nothing to resolve.
        if ($transport eq 'ssh') {
            my @rows;
            for my $key (@REPO_SSH_SETTINGS) {
                my $value = $repo->{ $REPO_SSH_KEYS{$key} };
                my %row = (key => $key, value => '');

                my $setting = $process{$key};

                if (defined $value && length $value) {
                    $row{value}  = $value;
                    $row{source} = 'repo';
                    $row{label}  = defined $config_file && length $config_file
                        ? "$config_file [$name]"
                        : "[$name]";
                } elsif ($setting && defined $setting->{value} && length $setting->{value}) {
                    $row{value}  = $setting->{value};
                    $row{source} = 'process';
                    $row{label}  = $setting->{label};
                } else {
                    $row{source} = 'default';
                    $row{label}  = 'ssh default';
                }

                push @rows, \%row;
            }

            # These two are recorded per repo only: there is no process-wide
            # default to fall back to, so the marker is always set.
            push @rows,
                _repo_only_row($repo, $name, $config_file, 'port', '22'),
                _repo_only_row($repo, $name, $config_file, 'host_key_checking', 'yes');

            $entry->{ssh} = \@rows;
        } else {
            $entry->{ssh} = undef;
        }

        push @repos, $entry;
    }

    return \@repos;
}

sub _repo_only_row {
    my ($repo, $name, $config_file, $key, $default) = @_;

    my %row = (key => $key, repo_only => 1, value => $default);

    if (defined $repo->{$key} && length $repo->{$key}) {
        $row{value}  = $repo->{$key};
        $row{source} = 'repo';
        $row{label}  = defined $config_file && length $config_file
            ? "$config_file [$name]"
            : "[$name]";
    } else {
        # The transport omits -p and StrictHostKeyChecking defaults to yes.
        $row{source} = 'default';
        $row{label}  = 'ssh default';
    }

    return \%row;
}

sub _differs {
    my ($left, $right) = @_;

    return 0 if !defined $left && !defined $right;
    return 1 if !defined $left || !defined $right;
    return "$left" ne "$right" ? 1 : 0;
}

sub _explanation {
    my ($file, $section) = @_;

    my $reader = Config::Abstraction->new(
        config_file => $file,
        env_prefix  => "${section}__",
    );
    return {} unless $reader;

    my $explanation = $reader->explain_sources();
    return ref($explanation) eq 'HASH' ? $explanation : {};
}

# The name the environment actually uses, matched the way Config::Abstraction
# matches an env_prefix: case-insensitively.  Windows reports environment
# names upper-cased, so building one from "prefix__key" is not enough; the
# report would then name a variable that does not exist in the same spelling
# as the one that supplied the value.
sub _env_key {
    my ($name) = @_;

    return $name if grep { $_ eq $name } keys %ENV;

    my $wanted = lc $name;
    for my $key (keys %ENV) {
        return $key if lc $key eq $wanted;
    }

    return undef;
}

# The last source that set a key in a section wins, which is how
# Config::Abstraction layers a file under its environment variables.
sub _pick {
    my ($explanation, $section, $key) = @_;

    for my $full ("$section.$key", "global.$key", $key) {
        my $entry = $explanation->{$full};
        next unless ref($entry) eq 'HASH' && ref($entry->{sources}) eq 'ARRAY';
        my @sources = @{ $entry->{sources} };
        next unless @sources;

        my $winner = $sources[-1];
        return {
            type  => $winner->{type},
            label => $winner->{label},
            value => $winner->{value},
        };
    }

    return undef;
}

sub _labels_for {
    my ($key, @explanations) = @_;

    my (%seen, @labels);
    for my $explanation (@explanations) {
        for my $full (sort keys %{$explanation}) {
            next unless $full eq $key || $full =~ /\.\Q$key\E\z/;
            for my $source (@{ $explanation->{$full}{sources} || [] }) {
                my $label = $source->{label};
                next unless defined $label && length $label;
                push @labels, $label unless $seen{$label}++;
            }
        }
    }

    return @labels;
}

# Object::Configure looks for universal<ext> beside the settings file, then the
# other config-file extensions; mirror its search so the report matches.
sub _universal_file {
    my ($config_file) = @_;

    my ($volume, $directory) = File::Spec->splitpath($config_file);
    my $base_directory = File::Spec->catpath($volume, $directory, '');
    my $ext = $config_file =~ /(\.[^.\/\\]+)\z/ ? $1 : '';

    my %seen;
    for my $candidate (grep { !$seen{$_}++ } (
        File::Spec->catfile($base_directory, "universal$ext"),
        File::Spec->catfile($base_directory, 'universal.conf'),
        File::Spec->catfile($base_directory, 'universal.yml'),
        File::Spec->catfile($base_directory, 'universal.yaml'),
        File::Spec->catfile($base_directory, 'universal.json'),
    )) {
        return $candidate if -f $candidate && -r $candidate;
    }

    return undef;
}

sub logger {
    my (%args) = @_;

    my $settings = load(%args);

    my $level = defined $args{level} && length $args{level}
        ? $args{level}
        : (defined $settings->{log_level} && length $settings->{log_level}
            ? $settings->{log_level}
            : $DEFAULT_LEVEL);

    die "Invalid log_level '$level' (want " . join(', ', @VALID_LEVELS) . ")\n"
        unless grep { lc($_) eq lc($level) } @VALID_LEVELS;

    my $format = defined $settings->{log_format} && length $settings->{log_format}
        ? $settings->{log_format}
        : $DEFAULT_FORMAT;

    my $destination;
    if (defined $settings->{log_file} && length $settings->{log_file}) {
        my $path = $settings->{log_file};
        my $directory = dirname($path);
        make_path($directory) unless -d $directory;
        $destination = { file => $path };
    } else {
        $destination = { fd => \*STDERR };
    }

    my $logger = Log::Abstraction->new(
        level          => $level,
        format         => $format,
        # Logging must never turn a handled error into a second, uncaught one.
        croak_on_error => 0,
        logger         => $destination,
    );

    # A command-line flag describes this run, so it beats the settings file.
    $logger = $logger->new(level => 'debug') if $args{verbose};
    $logger = $logger->new(level => 'error') if $args{quiet};

    return $logger;
}

1;

__END__

=head1 NAME

App::FileSync::Settings - process-wide settings and logging for App::FileSync

=head1 SYNOPSIS

    use App::FileSync::Settings;

    my $logger = App::FileSync::Settings::logger(verbose => 1);
    $logger->error('...');

    my $settings = App::FileSync::Settings::load();
    my $level = $settings->{log_level};

    my $report = App::FileSync::Settings::explain();
    printf "%s = %s (%s)\n", $_->{key}, $_->{value}, $_->{label}
        for @{ $report->{settings} };

=head1 DESCRIPTION

Settings that apply to the process rather than to one repo - the log level,
format and destination, plus the SSH identity, known-hosts file and remote
server command - are read through L<Object::Configure>.  The repos themselves
remain in F<~/.filesync/config.json>, which C<filesync init> writes; this
module does not replace that store.

The settings file is F<~/.conf/app-filesync.json> when it exists, or the path in
C<FILESYNC_SETTINGS>.  The section key is C<App__FileSync>, and a C<UNIVERSAL>
section in the same directory applies to every class that uses
Object::Configure.  Environment variables named C<App__FileSync__I<key>>
override the file:

    # ~/.conf/app-filesync.json
    { "App__FileSync": { "log_level": "debug", "log_format": "%level%: %message%" } }

    # or
    export App__FileSync__log_level=debug

C<log_file> sends the log to a file instead of standard error; leading
directories are created.  C<log_format> is a L<Log::Abstraction> format string.

C<ssh_identity>, C<ssh_known_hosts> and C<server_command> are the defaults for
every SSH repo, so a per-repo C<identity>, C<known_hosts> or C<server_command>
(written by C<filesync init --identity> and friends) only has to be set when it
differs.  C<server_command> defaults to C<filesync-server>:

    { "App__FileSync": {
        "ssh_identity"    : "~/.ssh/filesync_ed25519",
        "ssh_known_hosts" : "~/.ssh/filesync_known_hosts",
        "server_command"  : "/usr/local/bin/filesync-server"
    } }

Command output (sync summaries, plans, C<--json>) is written to standard output
by the commands themselves; the logger carries diagnostics on standard error,
so a cron job can separate the two.  C<--verbose> raises the level to C<debug>
and C<--quiet> lowers it to C<error> for that run, overriding the file.

=head1 FUNCTIONS

=head2 logger

    my $logger = App::FileSync::Settings::logger(%args);

Returns a L<Log::Abstraction> writing to standard error (or C<log_file>).
C<config_file>, C<config_dirs>, C<level>, C<verbose> and C<quiet> may be passed.

=head2 load

Returns the merged settings hashref (without the Object::Configure logger).

=head2 config_file

Returns the settings file that would be used, or C<undef>.

=head2 explain

    my $report = App::FileSync::Settings::explain(%args);

Returns C<{ settings_file =E<gt> $path_or_undef, settings =E<gt> \@rows }>, with
one row per key in C<@App::FileSync::Settings::SETTING_KEYS>.  Each row has the
effective C<value>, a C<source> of C<default>, C<file>, C<env> or C<merged>, anda human-readable C<label> naming the file section, environment variable or
built-in default that supplied it.  C<config_file> and C<config_dirs> may be
passed, as for C<load>.

=head2 explain_repos

    my $repos = App::FileSync::Settings::explain_repos(%args);

Resolves C<ssh_identity>, C<ssh_known_hosts> and C<server_command> for every
repo in a client config.  C<config> is the hashref from
C<App::FileSync::Config::load_client>, C<report> is the result of C<explain>,
and C<config_file> is the client config path used in labels.

Each entry has C<repo>, C<transport>, C<server> (when the repo records one) and
C<ssh>: one C<{key, value, source, label}> row per setting, where C<source> is
C<repo> (the repo's own entry), C<process> (the settings reported by C<explain>)
or C<default> (ssh's own default, when nothing sets a value).  C<ssh> is
C<undef> for the local transport, which never runs ssh.


=head1 LICENCE

GPL v2 for personal single-user, single-computer use.  All other users must
apply in writing to the author.

=cut
