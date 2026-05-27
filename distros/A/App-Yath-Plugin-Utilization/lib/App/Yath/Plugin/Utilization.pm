package App::Yath::Plugin::Utilization;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use parent 'App::Yath::Plugin';
use App::Yath::Options;

# Fully-qualified resource class names this plugin ships.
use constant CPU_CLASS         => 'Test2::Harness::Resource::Utilization::CPU';
use constant MEMORY_CLASS      => 'Test2::Harness::Resource::Utilization::Memory';
use constant UNIXLIMITS_CLASS  => 'Test2::Harness::Resource::Utilization::UnixLimits';
use constant PIPELIMITS_CLASS  => 'Test2::Harness::Resource::Utilization::PipeLimits';
use constant THROTTLE_CLASS    => 'Test2::Harness::Resource::Utilization::Throttle';
use constant DISK_CLASS        => 'Test2::Harness::Resource::Utilization::Disk';

# Default Throttle spec applied by --utilization-auto-throttle / -Z.
use constant DEFAULT_THROTTLE_SPEC => '1/core,100mb/1s';

option_group {prefix => 'utilization', category => "Utilization Options"} => sub {
    option utilize => (
        short          => 'U',
        type           => 's',
        default        => 75,
        long_examples  => [' 80', ' 50'],
        short_examples => [' 80', ' 50'],
        description    => 'Percentage of system utilization (0 < pct < 100) at which utilization-aware resources (CPU, Memory, UnixLimits, PipeLimits) should signal temporarily-unavailable. Each resource applies this threshold to its own monitored subsystem.',
        action => sub {
            my ($prefix, $field, $raw, $norm, $slot) = @_;
            die "--utilization-utilize must be a number\n"
                unless defined $norm && $norm =~ m/^[0-9]+(?:\.[0-9]+)?\z/;
            die "--utilization-utilize must be greater than 0 and less than 100 (got '$norm')\n"
                unless $norm > 0 && $norm < 100;
            $$slot = $norm + 0;
        },
    );

    option memory_min_free => (
        type => 's',
        long_examples  => [' 20%', ' 512mb'],
        description => 'Memory resource: minimum free memory threshold; pct (20%) or absolute (512mb). Layered with --utilization-utilize; the more conservative wins. Default 5%.',
    );

    option disk_mounts => (
        name => 'disk_mount',
        type => 'm',
        long_examples => [' /tmp:25%', ' /var:1gb'],
        description => 'Disk resource: repeat to add tracked mount points and their min-free thresholds. Format: /path:THRESHOLD where THRESHOLD is 25% or 1gb. Bare numbers interpreted as percent.',
    );

    option pipes_per_test => (
        type => 's',
        default => 2,
        long_examples => [' 2'],
        description => 'PipeLimits: pipes each test consumes. Default 2.',
    );

    option pipes_per_service => (
        type => 's',
        default => 2,
        long_examples => [' 2'],
        description => 'PipeLimits: pipes each harness service consumes. Default 2.',
    );

    option pipe_service_count => (
        type => 's',
        default => 0,
        long_examples => [' 5'],
        description => 'PipeLimits: supervised harness services already running. Default 0.',
    );

    option pipe_headroom => (
        type => 's',
        long_examples => [' 10%', ' 1024'],
        description => 'PipeLimits: explicit pipe-page headroom; pct (10%) or count (1024). Default 10%. Layered with --utilization-utilize.',
    );

    option unixlimits_nproc => (
        type => 's',
        long_examples => [' 10%', ' 128'],
        description => 'UnixLimits: nproc soft-cap headroom; pct (10%) or count (128). Default 10%.',
    );

    option unixlimits_nofile => (
        type => 's',
        long_examples => [' 10%', ' 128'],
        description => 'UnixLimits: nofile soft-cap headroom; pct (10%) or count (128). Default 10%.',
    );

    option unixlimits_as => (
        type => 's',
        long_examples => [' 10%', ' 512mb'],
        description => 'UnixLimits: address-space (AS) soft-cap headroom; pct (10%) or absolute (512mb). Off by default.',
    );

    option throttle => (
        type => 's',
        long_examples => [' 5/2s', ' 5', ' 1/core,100mb/1s'],
        description => 'Throttle resource: spawn-rate gate. CAP, CAP/DURATION, or CAP/BASIS[,BASIS...]/DURATION. Bases: "core" or byte sizes (100mb, 1gb). See --utilization-auto-throttle for the sane default.',
    );

    option auto_throttle => (
        type => 'b',
        default => 0,
        long_examples => [''],
        description => 'Activate Throttle using the sane default spec "1/core,100mb/1s" (1 new test per core per second, also capped at 1 per 100mb free RAM, adaptive under memory pressure). Implies enabling the Throttle resource.',
    );

    option auto => (
        short => 'Z',
        type  => 'D',
        long_examples  => ['', '=85'],
        short_examples => ['', '=85', '85'],
        description => 'One-stop shortcut. Bare -Z enables the full utilizer stack (CPU, Memory, UnixLimits, PipeLimits, Throttle with sane defaults, and Disk when applicable). -Z=PCT also sets --utilization-utilize to PCT.',
        action => sub {
            my ($prefix, $field, $raw, $norm, $slot, $settings) = @_;

            my $util = $settings->utilization;

            if (defined $norm && $norm ne '1') {
                die "-Z must be a number (got '$norm')\n"
                    unless $norm =~ m/^[0-9]+(?:\.[0-9]+)?\z/;
                die "-Z must be greater than 0 and less than 100 (got '$norm')\n"
                    unless $norm > 0 && $norm < 100;
                $util->field(utilize => $norm + 0);
            }

            $util->field(auto_throttle => 1);

            $$slot = 1;    # marks $util->auto as on; post-process expands
        },
    );

    post 60 => \&inject_resources;
};

sub inject_resources {
    my %params   = @_;
    my $settings = $params{settings};

    return unless $settings && $settings->check_prefix('utilization');
    return unless $settings->check_prefix('runner');

    my $util   = $settings->utilization;
    my $runner = $settings->runner;

    apply_auto_throttle($util, $runner);
    expand_auto_resources($util, $runner) if $util->check_field('auto') && $util->auto;
}

sub apply_auto_throttle {
    my ($util, $runner) = @_;

    return unless $util->auto_throttle;

    my $existing = $util->throttle;
    $util->field(throttle => DEFAULT_THROTTLE_SPEC)
        unless defined $existing && length $existing;

    push @{$runner->resources} => THROTTLE_CLASS
        unless grep { $_ eq THROTTLE_CLASS } @{$runner->resources};
}

sub expand_auto_resources {
    my ($util, $runner) = @_;

    my @auto;
    if ($^O eq 'linux') {
        push @auto => (CPU_CLASS, MEMORY_CLASS, UNIXLIMITS_CLASS, PIPELIMITS_CLASS);
    }
    push @auto => THROTTLE_CLASS;

    if (eval { require Filesys::Df; 1 }) {
        seed_auto_disk_mounts($util);
        push @auto => DISK_CLASS if $util->disk_mounts && @{$util->disk_mounts};
    }

    my %present = map { $_ => 1 } @{$runner->resources};
    push @{$runner->resources} => grep { !$present{$_}++ } @auto;
}

sub seed_auto_disk_mounts {
    my ($util) = @_;

    my $mounts = $util->disk_mounts // [];

    my %have;
    for my $entry (@$mounts) {
        next unless defined $entry && $entry =~ m{^(/[^:]+):};
        $have{$1} = 1;
    }

    my $utilize = $util->utilize // 75;
    my $min_pct = 100 - $utilize;
    $min_pct = 1  if $min_pct < 1;
    $min_pct = 99 if $min_pct >= 100;

    my @candidates = ('/tmp', '/var/tmp');
    push @candidates => $ENV{TMPDIR} if defined $ENV{TMPDIR} && length $ENV{TMPDIR};

    my %seen;
    for my $path (@candidates) {
        next unless defined $path && length $path;
        next if $seen{$path}++;
        next if $have{$path};
        next unless -d $path;
        next unless _is_real_mount_point($path);
        push @$mounts => "$path:${min_pct}%";
        $have{$path} = 1;
    }

    $util->field(disk_mounts => $mounts);
}

sub _is_real_mount_point {
    my ($path) = @_;
    return 0 unless -d $path;
    return 1 if $path eq '/';
    my @s_self = stat($path)      or return 0;
    my @s_par  = stat("$path/..") or return 0;
    return $s_self[0] != $s_par[0] ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Plugin::Utilization - System-utilization gating for yath test runs.

=head1 SYNOPSIS

    # Enable the plugin (either via .yath.rc, or -pUtilization on the command line):
    $ yath test -pUtilization -Z=85

    # Or set it in .yath.rc:
    [test]
    -pUtilization

    $ yath test -Z=85
    $ yath test --utilization-utilize 80 -R +Test2::Harness::Resource::Utilization::CPU

=head1 DESCRIPTION

Adds resource modules that gate when new test launches are allowed,
based on CPU usage, free memory, free disk, per-user pipe budget,
process ulimits, and a spawn-rate window. All opt-in; combine freely.

The plugin registers the C<utilization> option group with these
flags:

=over 4

=item C<--utilization-utilize PCT> (also C<-U>)

Target saturation percentage for every utilizer (default 75). Each
resource applies this to its own monitored subsystem.

=item C<-Z>, C<-Z=PCT>

One-stop shortcut. Enables the full utilizer stack (CPU+Memory+
UnixLimits+PipeLimits+Throttle, plus Disk when L<Filesys::Df> is
installed and auto-seeded mount points exist). C<-Z=85> also sets
utilize to 85.

=item C<--utilization-throttle SPEC>

Spawn-rate window: CAP, CAP/DURATION, or
CAP/BASIS[,BASIS...]/DURATION. Bases C<core> or byte size (C<100mb>).

=item C<--utilization-auto-throttle>

Activate Throttle with the sane default spec C<1/core,100mb/1s>.

=item C<--utilization-memory-min-free THR>

C<20%> or C<512mb>. Default 5%.

=item C<--utilization-disk-mount /path:THR>

Repeatable. Gate when free space on the mount drops below threshold.

=item C<--utilization-pipe-{headroom,pipes-per-test,pipes-per-service,service-count}>

PipeLimits resource tuning.

=item C<--utilization-unixlimits-{nproc,nofile,as}>

UnixLimits resource tuning.

=back

Resources live under C<Test2::Harness::Resource::Utilization::*>.
Use the fully qualified form with C<-R>:

    -R +Test2::Harness::Resource::Utilization::CPU
    -R +Test2::Harness::Resource::Utilization::Memory

C<-Z> is the convenience shortcut that activates the full stack
without needing to type each one.

=head1 LIMITATIONS

CPU/Memory/UnixLimits/PipeLimits are Linux-only (they read /proc).
Disk works anywhere L<Filesys::Df> installs. Throttle has portable
fallbacks for core count via L<System::Info>.

=head1 SOURCE

L<https://github.com/Test-More/App-Yath-Plugin-Utilization>

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
