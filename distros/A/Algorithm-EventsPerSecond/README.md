# Algorithm::EventsPerSecond

A sliding-window events-per-second rate counter for Perl, with an optional
C/SIMD-accelerated backend and an automatic pure-Perl fallback.

`Algorithm::EventsPerSecond` keeps per-second counts in a fixed-size ring
buffer and reports the average event rate over the most recent N seconds
(the "window"). Memory use is constant regardless of event volume, and both
`mark` and `rate` are O(1) averaged out over time.

For extra zoomies XS acceleration is available and SIMD if available.

## Synopsis

```perl
use Algorithm::EventsPerSecond;

my $meter = Algorithm::EventsPerSecond->new( window => 10 );  # 10-second window

while (my $event = get_next_event()) {
    # record one event
    $meter->mark;

	# or record several at once
    #$meter->mark(5);

    printf "current rate: %.2f events/sec\n", $meter->rate;
}

print "events seen in window: ", $meter->count, "\n";
print "lifetime total:        ", $meter->total, "\n";
```

## Installation

The module builds with the standard Perl toolchain. The XS backend is optional:
without a working compiler (or with `PUREPERL_ONLY=1`) it installs as pure Perl
and falls back automatically.

### From source

```sh
perl Makefile.PL
make
make test
make install        # may need sudo, depending on your Perl
```

#### Build-time controls

The XS backend is compiled during `perl Makefile.PL && make`, so these take
effect at install time:

| Control                        | Effect                                                                                                                                                                                   |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `IF_OPT`                       | The `-O` optimization level for the XS backend. `IF_OPT=2` (or `IF_OPT=-O2`) compiles with `-O2`. Default is `-O3`.                                                                      |
| `IF_ARCH`                      | Target architecture. `IF_ARCH=native` (or `IF_ARCH=-march=native`) compiles with `-march=native`, unlocking whatever SIMD the build host supports. Unset leaves the compiler's baseline. |
| `PUREPERL_ONLY=1`              | Passed to `Makefile.PL`; skips building the XS backend entirely.                                                                                                                         |
| `ALGORITHM_EVENTSPERSECOND_PP` | Runtime environment variable; when true, skips the XS backend and uses pure Perl.                                                                                                        |

Example — build a machine-tuned SIMD backend:

```sh
IF_ARCH=native IF_OPT=3 perl Makefile.PL
make && make test && make install
```

Example — force a pure-Perl install (no compiler needed):

```sh
perl Makefile.PL PUREPERL_ONLY=1
make && make test && make install
```

### Debian

Install a compiler and the Perl build tools, then build as above:

```sh
sudo apt-get update
sudo apt-get install build-essential perl cpanminus
cpanm Algorithm::EventsPerSecond
```

To build and install a native `.deb` instead (so the module is tracked by
`dpkg`), use `dh-make-perl`:

```sh
sudo apt-get install dh-make-perl fakeroot
dh-make-perl make --build --version 0.0.1 ./Algorithm-EventsPerSecond
sudo dpkg -i libalgorithm-eventspersecond-perl_0.0.1-1_*.deb
```

### FreeBSD

Install Perl and a CPAN client from packages, then build from source:

```sh
pkg install perl5 p5-App-cpanminus
cpanm Algorithm-EventsPerSecond-0.0.1.tar.gz
```

Or use the plain toolchain directly:

```sh
perl Makefile.PL
make
make test
make install
```

## Acceleration

If a working C compiler is available at install time, the XS backend
(`Algorithm::EventsPerSecond::XS`) is built and loaded automatically. It keeps
the ring buffer in packed `int64_t` buffers and scans the window in C, using
SIMD (AVX2 or SSE4.2) when the compiler targets a CPU that has it. When the
backend cannot be loaded for any reason, the pure-Perl implementation is used
instead.

Which backend is active, and its SIMD flavor, can be checked at runtime:

```perl
use Algorithm::EventsPerSecond;
print Algorithm::EventsPerSecond->backend, "\n";   # XS or PP
print Algorithm::EventsPerSecond->new->simd, "\n"; # AVX2 / SSE4.2 / scalar
```

For comparing the two, see `benchmark.pl`.

