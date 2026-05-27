# NAME

App::Yath::Plugin::Utilization - System-utilization gating for yath test runs.

# SYNOPSIS

    # Enable the plugin (either via .yath.rc, or -pUtilization on the command line):
    $ yath test -pUtilization -Z=85

    # Or set it in .yath.rc:
    [test]
    -pUtilization

    $ yath test -Z=85
    $ yath test --utilization-utilize 80 -R +Test2::Harness::Resource::Utilization::CPU

# DESCRIPTION

Adds resource modules that gate when new test launches are allowed,
based on CPU usage, free memory, free disk, per-user pipe budget,
process ulimits, and a spawn-rate window. All opt-in; combine freely.

The plugin registers the `utilization` option group with these
flags:

- `--utilization-utilize PCT` (also `-U`)

    Target saturation percentage for every utilizer (default 75). Each
    resource applies this to its own monitored subsystem.

- `-Z`, `-Z=PCT`

    One-stop shortcut. Enables the full utilizer stack (CPU+Memory+
    UnixLimits+PipeLimits+Throttle, plus Disk when [Filesys::Df](https://metacpan.org/pod/Filesys%3A%3ADf) is
    installed and auto-seeded mount points exist). `-Z=85` also sets
    utilize to 85.

- `--utilization-throttle SPEC`

    Spawn-rate window: CAP, CAP/DURATION, or
    CAP/BASIS\[,BASIS...\]/DURATION. Bases `core` or byte size (`100mb`).

- `--utilization-auto-throttle`

    Activate Throttle with the sane default spec `1/core,100mb/1s`.

- `--utilization-memory-min-free THR`

    `20%` or `512mb`. Default 5%.

- `--utilization-disk-mount /path:THR`

    Repeatable. Gate when free space on the mount drops below threshold.

- `--utilization-pipe-{headroom,pipes-per-test,pipes-per-service,service-count}`

    PipeLimits resource tuning.

- `--utilization-unixlimits-{nproc,nofile,as}`

    UnixLimits resource tuning.

Resources live under `Test2::Harness::Resource::Utilization::*`.
Use the fully qualified form with `-R`:

    -R +Test2::Harness::Resource::Utilization::CPU
    -R +Test2::Harness::Resource::Utilization::Memory

`-Z` is the convenience shortcut that activates the full stack
without needing to type each one.

# LIMITATIONS

CPU/Memory/UnixLimits/PipeLimits are Linux-only (they read /proc).
Disk works anywhere [Filesys::Df](https://metacpan.org/pod/Filesys%3A%3ADf) installs. Throttle has portable
fallbacks for core count via [System::Info](https://metacpan.org/pod/System%3A%3AInfo).

# SOURCE

[https://github.com/Test-More/App-Yath-Plugin-Utilization](https://github.com/Test-More/App-Yath-Plugin-Utilization)

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/)
