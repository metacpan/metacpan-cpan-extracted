package App::FileSync::Config;

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();

use App::FileSync qw(json_encode json_decode read_text write_atomic);

# Patterns that must never enter a manifest; they are excluded on both sides.
our @DEFAULT_IGNORE = (
    '.filesync-root',
    '.filesync-tmp-*',
    '.filesync-snapshots',
    '*.swp',
    '*~',
    '.#*',
    '#*#',
    '.DS_Store',
    '._*',
    'Thumbs.db',
    'desktop.ini',
    '*.crdownload',
    '*.part',
);

sub home_dir {
    return $ENV{FILESYNC_HOME} if defined $ENV{FILESYNC_HOME} && length $ENV{FILESYNC_HOME};

    my $home = $ENV{HOME};
    $home = $ENV{USERPROFILE} if !defined($home) || !length($home);
    die "Cannot determine your home directory; set FILESYNC_HOME\n"
        unless defined $home && length $home;

    return File::Spec->catdir($home, '.filesync');
}

sub client_config_path {
    return $ENV{FILESYNC_CONFIG}
        if defined $ENV{FILESYNC_CONFIG} && length $ENV{FILESYNC_CONFIG};
    return File::Spec->catfile(home_dir(), 'config.json');
}

sub default_client_config {
    return {
        version => 1,
        ssh     => { command => 'ssh', extra_args => [] },
        repos   => {},
    };
}

sub load_client {
    my ($path) = @_;
    $path = client_config_path() unless defined $path && length $path;

    my $config;
    if (-e $path) {
        $config = eval { json_decode(read_text($path)) };
        die "Cannot parse $path: $@" if $@;
        die "$path is not a JSON object\n" unless ref($config) eq 'HASH';
    } else {
        $config = default_client_config();
    }

    $config->{repos} = {} unless ref($config->{repos}) eq 'HASH';
    $config->{ssh} = { command => 'ssh', extra_args => [] }
        unless ref($config->{ssh}) eq 'HASH';

    return $config;
}

sub save_client {
    my ($config, $path) = @_;
    $path = client_config_path() unless defined $path && length $path;
    write_atomic($path, json_encode($config) . "\n");
    return $path;
}

sub repo_meta_dir {
    my ($root, $repo) = @_;
    return File::Spec->catdir($root, '.filesync', 'repos', $repo);
}

sub repo_config_path {
    my ($root, $repo) = @_;
    return File::Spec->catfile(repo_meta_dir($root, $repo), 'config.json');
}

sub default_repo_config {
    my ($name) = @_;
    return {
        version            => 1,
        name               => $name,
        created            => scalar(gmtime()) . ' UTC',
        trash_days         => 30,
        max_deletes        => 200,
        max_delete_percent => 10,
        conflicts          => 'inline',
        preserve_mode      => JSON::PP::true,
        allow_symlinks     => JSON::PP::false,
        clients            => {},
        ignore             => [ @DEFAULT_IGNORE ],
    };
}

sub load_repo {
    my ($root, $repo) = @_;
    my $path = repo_config_path($root, $repo);
    die "No such repo '$repo' under $root (run filesync-admin repo create)\n"
        unless -e $path;

    my $config = eval { json_decode(read_text($path)) };
    die "Cannot parse $path: $@" if $@;
    die "$path is not a JSON object\n" unless ref($config) eq 'HASH';

    $config->{ignore} = [ @DEFAULT_IGNORE ] unless ref($config->{ignore}) eq 'ARRAY';
    $config->{clients} = {} unless ref($config->{clients}) eq 'HASH';

    return $config;
}

sub save_repo {
    my ($root, $repo, $config) = @_;
    my $path = repo_config_path($root, $repo);
    make_path(repo_meta_dir($root, $repo));
    write_atomic($path, json_encode($config) . "\n");
    return $path;
}

1;
