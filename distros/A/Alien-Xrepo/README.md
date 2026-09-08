# NAME

Alien::Xrepo - Install shared libraries and third-party binaries (tools, interpreters) for FFI, XS, and build systems

# SYNOPSIS

```perl
use v5.40;
use Alien::Xrepo;
use Path::Tiny;

# Initialize
my $repo = Alien::Xrepo->new( );
# my $repo = Alien::Xrepo->new( cache => 0 );   # live resolution, skip the warmed cache

# Add a custom repository (optional)
# $repo->add_repo( 'my-repo', 'https://github.com/my/repo.git' );
# Install a shared lib with an automatic configuration
my $ogg = $repo->install('libvorbis');

# Install a library with specific configuration
# equivalent to: xrepo install -p windows -a x86_64 -m debug --configs='shared=true,vs_runtime=MD' libpng
my $pkg = $repo->install(
    'libpng', '1.6.x',
    plat    => 'windows',
    arch    => 'x64',
    mode    => 'debug',
    configs => { vs_runtime => 'MD' }
);
die 'Install failed' unless $pkg;

# Or install a binary tool and run it (ninja, cmake, python, node, ...)
my $ninja = $repo->install('ninja');
my ($ninja_exe) = map { path($_)->child($^O eq 'MSWin32' ? 'ninja.exe' : 'ninja') } $ninja->bin_dir;
system $ninja_exe, '--version';

# Wrap a single function from sqlite3 with Affix
use Affix;
my $sqlite3 = $repo->install('sqlite3');
affix $sqlite3->libpath, 'sqlite3_libversion', [], String;
say 'SQLite version: ' . sqlite3_libversion();
```

# DESCRIPTION

This module acts as an intelligent bridge between Perl and a wide range of package systems:
[xrepo](https://packages.xmake.io/), [vcpkg](https://vcpkg.io/en/packages), [conan](https://conan.io/center),
[brew](https://brew.sh/) (homebrew/linuxbrew), [conda](https://anaconda.org/), [dub](https://dub.pm/) (Dlang libs),
[apt](https://www.debian.org/distrib/packages) on Debian,
[pacman](https://wiki.archlinux.org/title/Pacman#Installing_packages) (if you use arch, btw),
[clib](https://github.com/clibs/clib/), [Cargo](https://crates.io/) for Rust crates,
[Portage](https://packages.gentoo.org/) on Gentoo, [Nimble](https://nimpackages.com/) for nimlang,
[NuGet](https://www.nuget.org/) for .NET,
[Zypper](https://documentation.suse.com/smart/systems-management/html/concept-zypper/index.html) on openSUSE, and even
your own custom repositories with smart prerequisite management.

With a single line, you can fetch **shared libraries** as well as **binary tools and interpreters** without touching a
system package manager:

- **Libraries** (`zlib`, `libpng`, `sqlite3`, ...) to bind with FFI or link from XS.
- **Tools and interpreters** (`ninja`, `cmake`, `meson`, `python`, `node`, `go`, `rust`, ...) to run from
your Perl code or to drive your build.

You are free to install **both kinds into the same store**: `ninja` next to `libpng`. Use [Affix](https://metacpan.org/pod/Affix), [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus),
[Inline](https://metacpan.org/pod/Inline), or plain XS to bind the libraries, and `bin_dir`/`installdir` to locate and run the binaries.

While FFI or XS can handle the binding or linking to native functions, Alien::Xrepo handles the **acquisition** of the
libraries and binaries. It automates the entire dependency lifecycle:

- 1. Provisioning:

    Downloads and installs both libraries (`libpng`, `openssl`, ...) and binary tools (`ninja`, `python`, ...) via
    `xrepo`, handling version constraints and custom repository lookups.

- 2. Configuration:

    Ensures libraries are compiled with FFI compatible flags (forcing `shared` libraries instead of static archives) and
    supports cross-compilation parameters (platform, architecture, toolchains).

- 3. Introspection:

    Parses the build metadata to locate the exact absolute paths to the runtime binaries (`.dll`, `.so`, `.dylib`) and
    header files, the `bin_dir` of any installed tool, and the `-I` / `-L` / `-l` flags a compiler needs, abstracting
    away operating system filesystem differences.

This eliminates the need for manual compilation steps or hard coding paths in your Perl scripts, making your FFI
bindings or XS wrappers portable and reproducible.

# THIRD-PARTY PACKAGE MANAGERS

xrepo can install from external C/C++ package managers instead of (or alongside) the official xmake-repo. You select
the manager with a package-spec namespace and every Alien::Xrepo method takes it verbatim:

```perl
# Vcpkg, Homebrew/Linuxbrew, Conan
my $zlib = $repo->install( 'vcpkg::zlib' );
my $zlib = $repo->install( 'brew::zlib'  );
my $zlib = $repo->install( 'conan::zlib/1.2.11' );

# Pacman (archlinux/msys2), Clib, Dub, Cargo, Conda, apt
$repo->install( 'pacman::libcurl' );
$repo->install( 'dub::log 0.4.3' );
```

Searching and flag fetching work against them too:

```perl
$repo->search( 'vcpkg::pcre' );          # search the vcpkg namespace
my $flags = $repo->fetch( 'conan::zlib/1.2.11', undef, cflags => 1, ldflags => 1 );
```

The installed results (`libpath`, `includedirs`, `links`, ...) are decoded into an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo)
exactly like any xmake-repo package, so your wrapper code does not care where the library came from.

See the `xmake-repo` integration notes at [https://github.com/xmake-io/xrepo-docs/blob/master/getting\_started.md](https://github.com/xmake-io/xrepo-docs/blob/master/getting_started.md) for
the corresponding `add_requires` syntax inside an xmake project.

# CONSTRUCTOR

## `new( ... )`

```perl
my $repo = Alien::Xrepo->new( verbose => 1 );
```

Creates a new instance.

- **verbose**

    Boolean. If true, prints command output and status messages to `STDOUT`. Defaults to `0`.

- **root**

    Optional default installation root (package store) for this instance. Every store-touching method (`install`,
    `fetch`, `scan`, `uninstall`, ...) uses `installdir => $root` unless a per-call `installdir` is given, so the
    instance is confined to its own project-local directory instead of the shared per-user store. Used by alien consumers
    such as [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime) and the [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild) engine to keep a distribution's native dependencies
    inside its `share` directory.

- **theme**

    Optional xmake output theme, passed to xmake as `$ENV{XMAKE_THEME}`. Defaults to `plain`, which suppresses ANSI color
    codes from xmake/xrepo output (clean CPAN test reports, CI logs, and captures). Set `theme => 'default'` to
    restore xmake's colored output. May be overridden per-call with `theme => ...` on any store-touching method.

- **yes**

    Boolean. Auto-confirms interactive xmake/xrepo prompts (e.g. "are you sure to install these packages?") by passing
    `-y`, so an install never hangs waiting on `STDIN`. This is important when output is captured with [Capture::Tiny](https://metacpan.org/pod/Capture%3A%3ATiny),
    which would otherwise swallow the prompt. `confirm => ...` takes precedence when both are set.

- **confirm**

    Supplies an explicit answer (`yes`, `no`, or `def`) to any prompt, passed through as `--confirm=...`. Takes
    precedence over `yes => 1`. Both may be overridden per-call with `yes => ...` or `confirm => ...` on any
    store-touching method.

- **kind**

    Default package kind (`shared` or `static`) for every action this instance performs. A per-call `kind => ...`
    wins. Left unset (the default), `-k` is omitted entirely so installs behave exactly like a bare `xrepo install`.
    Useful when you know every package this repo builds should be one kind (e.g. `shared` for FFI consumers).

- **cache**

    Boolean, default on. `install` memorizes each successful fetch result on disk (see ["`install( ... )`"](#install) below) so a
    repeat launch resolves the package with zero xrepo spawns. Entries are LRU-bounded and validated against the recorded
    install dir, so an uninstalled package is automatically forgotten and rebuilt. Pass `cache => 0` for pure
    fetch-first behavior (one spawn per launch, none cached).

# METHODS

## `install( ... )`

```perl
my $pkg_info = $repo->install( $package_name, $version_constraint, %options );
```

Installs (if missing) and fetches the metadata for a package.

Resolution is staged so repeat calls avoid the xmake process startup cost entirely:

- 1. A warm cache hit replays the memorized fetch result with no `xrepo` invocation. The entry is only trusted while its recorded install directory still exists on disk, and stale entries prune themselves. (See the **cache** constructor option to disable.)
- 2. Otherwise `fetch --json` is tried first: an already-installed package answers with real paths immediately and the mutating `xrepo install` is skipped. That single fetch is also memorized for next time.
- 3. Only when a package truly is missing does `xrepo install` run, followed by a mandatory fetch to learn where its output landed.

- **$package\_name**

    The name of the package (e.g., `zlib`, `opencv`).

- **$version\_constraint**

    Optional semantic version string (`1.2.x`, `latest`). Pass `undef` or an empty string for default.

- **%options**

    Optional configuration options passed to `xrepo` (shared by most other methods and missing options are filled in
    automatically):

    - **plat**

        Target platform (e.g., `windows`, `linux`, `macosx`, `android`, `iphoneos`, `wasm`).

    - **arch**

        Target architecture (e.g., `x86_64`, `arm64`, `riscv64`).

    - **mode**

        Build mode: `debug` or `release`.

    - **kind**

        Library kind: `shared` or `static`. Omitted entirely, the package's own default applies, so a bare install behaves
        exactly like `xrepo install`.

        _Note: For FFI, you almost always want `shared`, but `static` is available if you are linking archives with, say, an
        XS module._

    - **toolchain**

        Specify a toolchain (e.g., `llvm`, `zig`, `mingw`).

    - **toolchain\_host**

        Specify the host toolchain for cross compilation.

    - **vs**, **vs\_toolset**, **vs\_sdkver**

        Visual Studio toolset/sdk selection (e.g., `--vs=2017`, `--vs_toolset=14.0`).

    - **ndk**

        The Android NDK directory.

    - **sdk**

        The SDK directory of a cross toolchain.

    - **mingw**

        The MinGW SDK directory.

    - **jobs**, **linkjobs**

        Parallel compilation/link job counts.

    - **force**

        _install/download_: force reinstall/redownload all packages. _remove_: force removal even when still depended on.

    - **shallow**

        Do not install/download dependent packages.

    - **build**

        Always build and install from source.

    - **debugdir**

        Source directory used for debugging; enables `force` and `shallow` by default.

    - **configs( ... )**

        A hashref or string of package-specific configurations.

        ```perl
        configs => { openssl => 'true', shared => 'true' }
        # becomes --configs='openssl=true,shared=true'
        ```

        Perl's built-in boolean scalars (`use feature 'true'/'false'`, enabled by `use v5.36+`) are normalized to the literal
        strings `'true'` / `'false'`, so `configs => { shared => true }` produces `--configs='shared=true'`.

    - **includes**

        A list or string of extra rc files to include in the environment.

        Each include is forwarded to xmake verbatim, so it must be genuine root-scope xmake config (e.g. `add_toolchains`);
        xmake textually prepends rc contents to the temporary project script. A vendored `package() {...}` recipe is NOT
        supported here: it is invalid in project scope and dies with e.g. `unknown interface: add_rules()`. The value is
        split/rejoined on the OS path separator (`$Config{path_sep}`), and each path is normalized to an absolute path before
        being passed on.

    - **installdir**, **cachedir**

        Root directories for the installed packages and the download/build cache, applied per-call via the
        `XMAKE_PKG_INSTALLDIR` / `XMAKE_PKG_CACHEDIR` environment variables. This lets each wrapper keep its libraries in a
        project-local directory instead of the shared per-user store, which gives reproducible builds and protects against an
        unrelated `xrepo` run upgrading or removing the packages your wrapper depends on. Pass the same values to `fetch`,
        `scan`, `uninstall`, and friends so they operate on the same store.

    - **theme**

        Per-call xmake output theme override. Defaults to the `theme` constructor value (`plain`). See ["new( ... )"](#new).

    - **yes**, **confirm**

        Per-call auto-confirmation overrides for the constructor `yes => ...` / `confirm => ...` options, applied as
        `-y` or `--confirm=...` to the underlying `xrepo` invocation. Defaults to the constructor values. See ["new( ...
        )"](#new).

    - **cache**

        Per-call override for the constructor `cache` option (default on). Pass `cache => 0` to skip the on-disk replay
        for this one resolution (still fetch-first). See ["new( ... )"](#new).

Returns an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo) object.

## `fetch( $pkg, $version, %options )`

```perl
my $pkg_info = $repo->fetch( 'libpng' );
my $cflags   = $repo->fetch( 'zlib', undef, cflags => 1 );
```

Fetches metadata for an already-installed package without installing it again. Returns an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo)
object, or a raw flag string when `cflags` or `ldflags` is requested.

- **cflags**

    Fetch `-I...` include flags as a string.

- **ldflags**

    Fetch `-L.../-l...` link flags as a string.

- **deps**

    Fetch packages together with their dependencies.

- **system**

    Only fetch the package on the current system.

- **external**

    Show `cflags` as external packages (with `-isystem`).

- **installdir**, **cachedir**

    Target the same isolated store used by `install( ... )` (see there).

## `info( $pkg, %options )`

```perl
my $json = $repo->info( 'zlib', format => 'json' );
my $text = $repo->info( 'libpng' );
my $dot  = $repo->info( 'libpng', depgraph => 1, format => 'dot' );   # dependency graph (Graphviz)
```

Shows package information. Pass `format => 'json'` to receive the decoded data structure (array of hashes),
`format => 'dot'` for a Graphviz DOT dependency graph, or `depgraph => 1` to include the package dependency
tree. A DOT graph can be rendered with `dot -Tpng dep.dot -o dep.png`.

## `scan( [$pkg], %options )`

```perl
my @installed = $repo->scan( 'libpng' );
my @all       = $repo->scan( );
```

Lists installed packages (optionally filtered by a lua pattern). Returns the output lines as a list.

## `download( $pkg, $version, %options )`

```perl
$repo->download( 'zlib', undef, outputdir => './dl', shallow => 1 );
```

Only downloads the package source archives without building them. `outputdir` selects the destination directory
(default `packages`). Supports `force`, `shallow` and the standard `%options`.

## `import_pkg( $pkg, $version, %options )`

```perl
$repo->import_pkg( 'zlib', undef, packagedir => './packages' );
```

Imports pre-downloaded package archives into the local cache. `packagedir` selects the source directory.

## `export( $pkg, $version, %options )`

```perl
$repo->export( 'zlib', undef, packagedir => './packages', shallow => 1 );
```

Exports installed package files for offline use. `packagedir` selects the destination directory.

## `env( [$program], %options )`

```perl
$repo->env( 'bash', bind => 'zlib' );   # run a program inside the package env
$repo->env( undef, show => 1 );         # only print the environment
```

Sets up the package environment and either prints it (`show`) or executes `$program` (default `shell`) inside it.
`bind` selects which environment config or package to bind, `list` lists global configs, and `add`/`remove` manage
global environment config files.

## `list_repo( )`

```perl
my @repos = $repo->list_repo( );
```

Lists all configured remote repositories (output lines).

## `uninstall( $lib, %options )`

```perl
$repo->uninstall( 'zlib' );
$repo->uninstall( 'zl*', all => 1 );
```

Removes the specified package from the local cache. Accepts the same `%options` as `install( ... )`. `all` removes
all matching packages (ignoring extra configs, lua patterns allowed) and `force` removes addon packages even when they
are still depended upon.

## `search( $query, %options )`

```perl
$repo->search( $query );
$repo->search( $query, addon => 1 );
```

Runs `xrepo search` and returns the matching packages as a list of `name` or `name-version` tokens (in list context;
the match count in scalar context). Name and version are returned together because a package name may itself contain
`-`, so the boundary cannot be recovered reliably — pass a token straight back to `install()`: it is a valid
(possibly versioned) spec. Whole tokens also work with `grep`, so callers can filter on plain names.

The output is captured, so nothing is printed to STDOUT by this method. On a failed run (nonzero exit, e.g. a missing
`vcpkg::` namespace) it `warn`s and returns an empty list. `addon` searches the `addons/` sub-repository.

## `clean( %options )`

```perl
$repo->clean( );
$repo->clean( installdir => './store' );   # clean an isolated store
```

Cleans the cached packages and downloads. Pass `installdir` and/or `cachedir` to target an isolated store.

## `add_repo( ... )`

```
$repo->add_repo( $name, $git_url, $branch );
```

Adds a custom xmake repository.

## `remove_repo( ... )`

```
$repo->remove_repo( $name );
```

Removes a custom repository.

## `update_repo( [$repo] )`

```
$repo->update_repo( );        # Update all
$repo->update_repo( 'main' ); # Update specific repo
```

Updates the local package lists from the remote repositories.

# Cache System

`install` avoids paying xmake's process-startup cost on every call. Each successful resolution is memorized as a small
JSON record and replayed on the next launch, so a long-lived demo (e.g. ["webui.pl" in eg](https://metacpan.org/pod/eg#webui.pl)) or a build loop that re-runs
against the same store starts instantly once a package is resolved.

- **What is stored**

    The raw `fetch --json` output plus the resolved install directory, keyed by a SHA-1 fingerprint of the package spec
    and every option that can move the installed layout (`kind`, `plat`, `arch`, `mode`, `configs`). Config values run
    through the same boolean stringifier as the CLI, so `configs => { shared => true }` and `configs =>
    { shared => 'true' }` share a key.

- **Where it lives**

    A `cache.json` under `<store>/.alien-xmake/` when an instance or per-call store is set (`root` / `installdir`),
    otherwise under `<xmake global dir>/.alien-xmake/` (normally `~/.xmake`), honoring `XMAKE_GLOBALDIR`.

- **Validation**

    A hit is only trusted while its recorded install directory still exists on disk. An entry whose package was
    uninstalled, expired, or otherwise removed disqualifies itself and is pruned on the next save, after which the package
    is reinstalled normally.

- **Bounded**

    Entries are kept Least-Recently-Used with a fixed cap (64), so the file stays a few hundred KB no matter how many
    package/option combinations you touch.

- **Disabling**

    Pass `cache => 0` to the ["new( ... )"](#new) constructor, or as a per-call option to ["`install( ... )`"](#install), to
    force live resolution -- fetch-first, one xmake spawn per launch, nothing persisted. [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime) and
    [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild) accept the same constructor flag and forward it to the engine they create.

# Alien::Xrepo::PackageInfo

Returned by `install( ... )`, this object contains the results of the dependency resolution.

### Attributes

- **libpath**

    The absolute path to the main library file (`.dll`, `.dylib`, or `.so`). Returns `undef` if the package is
    header-only or the binary could not be identified.

- **includedirs**

    List of include paths.

- **installdir**

    The package install root. Packages that mostly exist as tools or runnable binaries (`ninja`, `python`, `cmake`, ...)
    put their executables under `installdir/bin`.

- **bin\_dir**

    List of directories holding executables. Comes from the `bindirs` fetch metadata, or falls back to `installdir/bin` when the package is a tool. Run a freshly installed binary like so:

    ```perl
    my $ninja = $repo->install('ninja');
    my ($exe) = grep { -e $_ } map { path($_)->child($^O eq 'MSWin32' ? 'ninja.exe' : 'ninja') } $ninja->bin_dir;
    system $exe, '--version';
    ```

- **libfiles**

    List of all library files associated with the package (may include import libs, static archives, etc.).

- **license**

    The license identifier.

- **version**

    The installed version.

### Methods

#### `find_header( ... )`

```perl
my $path = $info->find_header( 'png.h' );
```

Scans `includedirs` for the given filename and returns the absolute path if found. Returns `undef` otherwise.

# Examples

If you just want to use a library, copy one of these. Each one installs whatever is missing on the first run and takes
care of the rest.

## Hello World (install then call)

`install( ... )` downloads and builds the library for you, then `libpath` points [Affix](https://metacpan.org/pod/Affix) or [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus) to the
matching shared `.dll` / `.so` / `.dylib`.

Affix first:

```perl
use v5.40;
use Alien::Xrepo;
use Affix;

my $zlib = Alien::Xrepo->new->install('zlib');
affix $zlib->libpath, 'zlibVersion', [], String;
say 'zlib ' . zlibVersion();
```

The same simple demo with FFI::Platypus:

```perl
use v5.40;
use Alien::Xrepo;
use FFI::Platypus;

my $zlib = Alien::Xrepo->new->install('zlib');

my $ffi = FFI::Platypus->new;
$ffi->lib( $zlib->libpath );
$ffi->attach( zlibVersion => [] => 'string' );
say 'zlib ' . zlibVersion();
```

And if you want the whole library wrapped (prototypes generated from the headers) instead of one function at a time,
use [Affix::Wrap](https://metacpan.org/pod/Affix%3A%3AWrap):

```perl
use v5.40;
use Alien::Xrepo;
use Affix::Wrap;

my $zlib = Alien::Xrepo->new->install('zlib');
Affix::Wrap->new(
    project_files => [ $zlib->find_header('zlib.h') ],
    include_dirs  => [ $zlib->includedirs ],
    types         => { gzFile_s => Pointer [Void] }
)->wrap( $zlib->libpath );
say 'zlib ' . zlibVersion();
```

## Link an XS extension with Inline::C (multiple libraries)

Same idea for an actual C extension, compiled with [Inline::C](https://metacpan.org/pod/Inline%3A%3AC). Install every library you want to link; merge their
include and link directories, hand them to Inline::C, and write plain C that uses whichever header you need. Here we
bind both `libpng` and `zlib` (installed together into one store) into a single XS function:

```perl
use v5.40;
use Alien::Xrepo;
use Config;

my $repo = Alien::Xrepo->new;
my $png   = $repo->install('libpng');       # shared lib
my $zlib  = $repo->install('zlib');         # second shared lib

# The compiled XS loads png.dll / libpng.so at runtime, so put both native
# "bin" dirs on PATH before calling into it (Windows especially).
my @png_bins  = $png->bin_dir;
my @zlib_bins = $zlib->bin_dir;
local $ENV{PATH} = join $Config{path_sep}, (@png_bins, @zlib_bins, $ENV{PATH});

# Merge include and link directories into plain flag strings.
my $incs = join ' ', map { "-I$_" } (@{ $png->includedirs }, @{ $zlib->includedirs });
my $libs = join ' ',
    map { "-L$_" } (@{ $png->linkdirs }, @{ $zlib->linkdirs }),
    map { "-l$_" } (@{ $png->links },    @{ $zlib->links });

use Inline ();
Inline->bind(
    'C',
    <<'C',
#include <png.h>
#include <zlib.h>
const char *versions () {
    return "libpng " PNG_LIBPNG_VER_STRING ", zlib " ZLIB_VERSION;
}
C
    INC  => $incs,
    LIBS => $libs,
);
say versions();
```

The _eg/xrepo\_inline\_c.pl_ script is the runnable copy of this example. `Inline::C` is not installed with this
distribution. Install it once with `cpanm Inline::C`.

## Install and run a binary tool

`xrepo` does not build only shared libraries, it also ships ready-to-run binaries (`ninja`, `cmake`, `meson`,
`node`, `python`, `go`, `rust`, ...). `install` returns the package `installdir`, and `bin_dir` tells you where
the executables live. Run one directly, or stick `bin_dir` in front of `PATH` so all the children you spawn find the
tool:

```perl
use v5.40;
use Alien::Xrepo;
use Path::Tiny;
use Config;

my $repo    = Alien::Xrepo->new;
my $ninja   = $repo->install('ninja');
my @bins    = $ninja->bin_dir;

# Option A: run a single binary from bin_dir
my ($ninja_exe) = map { path($_)->child($^O eq 'MSWin32' ? 'ninja.exe' : 'ninja') } @bins;
system $ninja_exe, '--version';

# Option B: put bin_dir first on PATH, then plain 'ninja' resolves
local $ENV{PATH} = join $Config{path_sep}, (@bins, $ENV{PATH});
system 'ninja', '--version';
```

Use `installdir` for everything the tool ships, not just `bin`:

```
say 'ninja install root: ' . $ninja->installdir;
```

## Build a C program against a library

`install` builds the library once; `fetch` tells you the `-I...` and `-L.../-l...` flags if you are building with
something other than xmake (e.g. MakeMaker or a plain `cc`):

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;
$repo->install( 'libpng' );                       # build it once
my $cflags  = $repo->fetch( 'libpng', undef, cflags  => 1 );
my $ldflags = $repo->fetch( 'libpng', undef, ldflags => 1 );
say "cc $cflags $ldflags pngprog.c -o pngprog";
```

## What can I install? What do I already have?

```perl
use v5.40;
use Alien::Xrepo;
my $repo = Alien::Xrepo->new;

say '[What is available?]';
$repo->search('sqlite');

say '[Already installed:]';
say for $repo->scan;
```

`search` prints matching packages from every configured repository and `scan` lists everything already on disk.

## Cross-compile without memorizing SDK paths

All of xrepo's platform switches become named options. `ndk` is just one example, alongside `toolchain`, `sdk`,
`mingw` and the rest.

```perl
use v5.40;
use Alien::Xrepo;

my $pkg = Alien::Xrepo->new->install(
    'zlib', '1.3.x',
    plat => 'android',
    arch => 'arm64',
    ndk  => 'C:/Android/Sdk/ndk/26.1.10909125'  # adapt to your NDK
);
say $pkg->libpath;
```

## Drop into a shell inside the library's environment

`env` sets up the environment for a package (PATH, etc.) and either runs `$program` inside it (default: the system
shell) or just prints it with `show`.

```perl
use v5.40;
use Alien::Xrepo;
Alien::Xrepo->new->env( 'bash', bind => 'zlib' ); # or env( undef, bind => 'zlib' )
# Alien::Xrepo->new->env( undef, show => 1 );     # just print the environment
```

## Guard an install against a package that may not exist

`search` reports what the configured repositories actually provide. Check before you `install` so a spec that is
absent (or renamed) in the active repos fails cleanly instead of erroring mid-way:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;
if ( grep {/zlib/} $repo->search('zlib') ) {
    my $zlib = $repo->install('zlib');
    say 'zlib at ' . $zlib->libpath;
}
else {
    warn "zlib is unavailable in the configured repositories\n";
}
```

`search` returns whole tokens (`zlib-v1.3.2`, `zlib-ng-2.3.3`, ...), so `grep` narrows the list to plain-name
matches even though `xrepo search` also lists packages whose description matches the query.

## Run a binary tool and check it worked

`env` wraps the given program with the package's environment (PATH already adjusted) and returns its exit status, so
it doubles as a smoke test that the tool actually runs:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;
my $cmake = $repo->install('cmake');            # kind: binary
my $rc = $repo->env('cmake', '--version');      # runs cmake with its bin_dir on PATH
die "cmake failed to run" unless $rc == 0;
```

## Bundle a package for offline use

`download` fetches the source archives without building, `import_pkg` drops them into the local cache, and a
subsequent `install` uses them even on a machine with no network. Handy for air-gapped CI or offline installs:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;

$repo->download( 'zlib', undef, outputdir => './dl', shallow => 1 );   # fetch sources (no build)
$repo->import_pkg( 'zlib', undef, packagedir => './dl' );              # load into the cache
my $zlib = $repo->install('zlib');                                     # install offline
say 'installed ' . $zlib->version;
```

## Render the dependency graph

`info( ... depgraph =` 1, format => 'dot')> emits a Graphviz `DOT` description of a package and everything it pulls
in. Pipe it to `dot -Tpng dep.dot -o dep.png` to picture how a library's prerequisites resolve:

```perl
use v5.40;
use Alien::Xrepo;

my $dot = Alien::Xrepo->new->info( 'libpng', depgraph => 1, format => 'dot' );
say $dot;    # e.g.  dot -Tpng dep.dot -o dep.png
```

## Cross-compile a library, then read its compiler/link flags

Install a library for another platform/architecture (the same switches `xrepo` accepts become named options), then
`fetch` the `-I...` / `-L.../-l...` flags you would pass to your own compiler:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;
$repo->install(
    'libpng', '1.6.x',
    plat => 'windows',
    arch => 'x64',
    mode => 'debug',
    kind => 'shared'
);

my $cflags  = $repo->fetch( 'libpng', undef, cflags  => 1 );   # "-Ic:/.../include ..."
my $ldflags = $repo->fetch( 'libpng', undef, ldflags => 1 );   # "-Lc:/.../lib -l... .."
say "CFLAGS:  $cflags";
say "LDFLAGS: $ldflags";
```

## Remove a package from the cache

`uninstall` removes a package from the local store (the same one `install`/`fetch`/`scan` use, or an isolated
`root` you installed into). It accepts the same options as `install`; `all` removes every stored variant, `force`
removes a package even when others still depend on it. It returns the underlying exit status, so check `$?`:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;

$repo->uninstall('freetype');               # remove one package
$repo->uninstall('zl*', all => 1);          # every variant matching the pattern
$repo->uninstall('fontconfig', force => 1); # remove even if still depended upon
```

Note that this edits the shared store unlike a builder's prune, which slims the `share` dir a distribution ships,
`uninstall` frees space in the store you manage yourself.

# SEE ALSO

[https://xrepo.xmake.io](https://xrepo.xmake.io), [https://packages.xmake.io/](https://packages.xmake.io/)

[Affix](https://metacpan.org/pod/Affix), [Affix::Wrap](https://metacpan.org/pod/Affix%3A%3AWrap), [Alien::Xmake](https://metacpan.org/pod/Alien%3A%3AXmake), [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild), [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime), [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus),
[Inline::C](https://metacpan.org/pod/Inline%3A%3AC)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson [https://github.com/sanko](https://github.com/sanko)
