# NAME

Alien::Xrepo - Install libraries and third-party binaries for FFI, XS, and build systems

# SYNOPSIS

```perl
use v5.40;
use Alien::Xrepo;
use Path::Tiny;

# Initialize
my $repo = Alien::Xrepo->new();
# my $repo = Alien::Xrepo->new( cache => 0 );   # live resolution, skip the warmed cache

# Add a custom repository (optional)
# $repo->add_repo( 'my-repo', 'https://github.com/my/repo.git' );

# Install a shared lib with automatic configuration
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

- [xrepo](https://packages.xmake.io/)
- [vcpkg](https://vcpkg.io/en/packages)
- [conan](https://conan.io/center)
- [brew](https://brew.sh/) (Homebrew/Linuxbrew)
- [conda](https://anaconda.org/)
- [dub](https://dub.pm/) (Dlang libs)
- [apt](https://www.debian.org/distrib/packages) on Debian
- [pacman](https://wiki.archlinux.org/title/Pacman#Installing_packages) (if you use Arch, btw)
- [clib](https://github.com/clibs/clib/)
- [Cargo](https://crates.io/) for Rust crates
- [Portage](https://packages.gentoo.org/) on Gentoo
- [Nimble](https://nimpackages.com/) for Nimlang
- [NuGet](https://www.nuget.org/) for .NET
- [Zypper](https://documentation.suse.com/smart/systems-management/html/concept-zypper/index.html) on openSUSE
- ...and even your own custom repositories as local files or a remote Git repo

All with smart prerequisite management and dependency resolution.

With a single line, you can fetch or build static and shared libraries and install binary tools (interpreters, build systems, etc.) without touching the system package manager. `Alien::Xrepo` takes care of the most difficult parts of `Alien` management:

- **Provisioning**

    Downloads and installs libraries (`libpng`, `openssl`, ...) and binary tools (`ninja`, `python`, ...), handling version constraints and custom repository lookups.

- **Configuration**

    Ensures libraries are compiled as FFI-compatible shared objects or XS/Inline-ready static archives, and provides full support for cross-compilation parameters (platform, architecture, toolchains).

- **Introspection**

    Parses the build metadata to locate the exact, absolute paths to runtime binaries (`.dll`, `.so`, `.dylib`) and header files, the `bin_dir` of any installed tool, and the `-I` / `-L` / `-l` flags a compiler needs. This abstracts away operating system filesystem differences.

This eliminates manual compilation steps and hard-coded paths in your Perl scripts, making your FFI bindings or XS wrappers truly portable and reproducible.

# Methods

This class is object-oriented, so let's begin with the constructor.

## `new( [...] )`

```perl
my $repo = Alien::Xrepo->new( verbose => 1 );
```

Creates a new instance. All values are optional.

- **verbose**

    Boolean. If true, prints command output and status messages to `STDOUT`. Defaults to `0`.

- **root**

    Optional default installation root (package store) for this instance. Every store-touching method (`install`, `fetch`, `scan`, `uninstall`, ...) uses `installdir => $root` unless overridden per-call. This confines the instance to a project-local directory rather than the shared per-user store. Used by Alien consumers such as [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime) and the [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild) engine to keep a distribution's native dependencies inside its `share` directory.

- **theme**

    Optional `xmake` output theme, passed to `xmake` as `$ENV{XMAKE_THEME}`. Defaults to `plain`, which suppresses ANSI color codes from `xmake`/`xrepo` output (resulting in clean CPAN test reports, CI logs, and captures). Set `theme => 'default'` to restore `xmake`'s colored output. May be overridden per-call with `theme => ...` on any store-touching method.

- **yes**

    Boolean. Auto-confirms interactive `xmake`/`xrepo` prompts (e.g., "are you sure to install these packages?") by passing `-y`, ensuring an install never hangs waiting on `STDIN`. This is important when output is captured with [Capture::Tiny](https://metacpan.org/pod/Capture%3A%3ATiny), which would otherwise swallow the prompt. `confirm => ...` takes precedence when both are set.

- **confirm**

    Supplies an explicit answer (`yes`, `no`, or `def`) to any prompt, passed through as `--confirm=...`. Takes precedence over `yes => 1`. Both may be overridden per-call with `yes => ...` or `confirm => ...` on any store-touching method.

- **kind**

    Default package kind (`shared` or `static`) for every action this instance performs. A per-call `kind => ...` wins. If left unset (the default), `-k` is omitted entirely so installs behave exactly like a bare `xrepo install`. Useful when you know every package this repo builds should be a specific kind (e.g., `shared` for FFI consumers).

- **cache**

    Boolean, default on. `install` memorizes each successful fetch result on disk (see ["`install( ... )`"](#install) below) so a repeated launch resolves the package with zero `xrepo` spawns. Entries are LRU-bounded and validated against the recorded install dir, so an uninstalled package is automatically forgotten and rebuilt. Pass `cache => 0` for pure fetch-first behavior (one spawn per launch, none cached).

## `install( ... )`

```perl
my $pkg_info = $repo->install( $package_name, $version_constraint, %options );
```

Installs (if missing) and fetches the metadata for a package.

Resolution is staged so repeated calls avoid the `xmake` process startup cost entirely:

- 1. A warm cache hit replays the memorized fetch result without invoking `xrepo`. The entry is only trusted while its recorded install directory still exists on disk, and stale entries automatically prune themselves. (See the **cache** constructor option to disable.)
- 2. Otherwise, `fetch --json` is tried first: an already-installed package answers with real paths immediately and the mutating `xrepo install` is skipped. That single fetch is also memorized for next time.
- 3. Only when a package truly is missing does `xrepo install` run, followed by a mandatory fetch to learn where its output landed.

- `$package_name`

    The name of the package (e.g., `zlib`, `opencv`).

- **$version\_constraint**

    Optional semantic version string (`1.2.x`, `latest`). Pass `undef` or an empty string for the default.

- `%options`

    Optional configuration options passed to `xrepo` (shared by most other methods; missing options are filled in automatically):

    - `plat`

        Target platform (e.g., `windows`, `linux`, `macosx`, `android`, `iphoneos`, `wasm`).

    - `arch`

        Target architecture (e.g., `x86_64`, `arm64`, `riscv64`).

    - `mode`

        Build mode: `debug` or `release`.

    - `kind`

        Library kind: `shared` or `static`. If omitted entirely, the package's own default applies, so a bare install behaves exactly like `xrepo install`.

        _Note: For FFI, you almost always want `shared`, but `static` is available if you are linking archives with, say, an XS module._

    - `toolchain`

        Specify a toolchain (e.g., `llvm`, `zig`, `mingw`).

    - `toolchain_host`

        Specify the host toolchain for cross-compilation.

    - `vs`, `vs_toolset`, `vs_sdkver`

        Visual Studio toolset/SDK selection (e.g., `--vs=2017`, `--vs_toolset=14.0`).

    - `ndk`

        The Android NDK directory.

    - `sdk`

        The SDK directory of a cross-toolchain.

    - `mingw`

        The MinGW SDK directory.

    - `jobs`, **linkjobs**

        Parallel compilation/link job counts.

    - `force`

        _install/download_: force reinstall/redownload all packages. _remove_: force removal even when still depended on.

    - `shallow`

        Do not install/download dependent packages.

    - `build`

        Always build and install from source.

    - `debugdir`

        Source directory used for debugging; enables `force` and `shallow` by default.

    - `configs( ... )`

        A hashref or string of package-specific configurations.

        ```perl
        configs => { openssl => 'true', shared => 'true' }
        # becomes --configs='openssl=true,shared=true'
        ```

        Perl's built-in boolean scalars (`use feature 'true'/'false'`, enabled by `use v5.36+`) are normalized to the literal strings `'true'` / `'false'`, so `configs => { shared => true }` produces `--configs='shared=true'`.

    - `includes`

        A list or string of extra `rc` files to include in the environment.

        Each include is forwarded to `xmake` verbatim, so it must be a valid root-scope `xmake` configuration (e.g., `add_toolchains`); `xmake` textually prepends `rc` contents to the temporary project script. A vendored `package() {...}` recipe is NOT supported here: it is invalid in project scope and dies with e.g., `unknown interface: add_rules()`. The value is split/rejoined on the OS path separator (`$Config{path_sep}`), and each path is normalized to an absolute path before being passed on.

    - `installdir`, **cachedir**

        Root directories for the installed packages and the download/build cache, applied per-call via the `XMAKE_PKG_INSTALLDIR` / `XMAKE_PKG_CACHEDIR` environment variables. This lets each wrapper keep its libraries in a project-local directory instead of the shared per-user store, which gives reproducible builds and protects against an unrelated `xrepo` run upgrading or removing the packages your wrapper depends on. Pass the same values to `fetch`, `scan`, `uninstall`, and friends so they operate on the same store.

    - `theme`

        Per-call `xmake` output theme override. Defaults to the `theme` constructor value (`plain`). See ["new( ... )"](#new).

    - `yes`, `confirm`

        Per-call auto-confirmation overrides for the constructor `yes => ...` / `confirm => ...` options, applied as `-y` or `--confirm=...` to the underlying `xrepo` invocation. Defaults to the constructor values. See ["new( ... )"](#new).

    - `cache`

        Per-call override for the constructor `cache` option (default on). Pass `cache => 0` to skip the on-disk replay for this one resolution (still fetch-first). See ["new( ... )"](#new).

Returns an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo) object.

## `fetch( ..., [ ... ] )`

```perl
my $pkg_info = $repo->fetch( 'libpng' );
my $cflags   = $repo->fetch( 'zlib', undef, cflags => 1 );
```

Fetches metadata for an already-installed package without installing it again. Returns an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo) object, or a raw flag string when `cflags` or `ldflags` is requested.

- `cflags`

    Fetch `-I...` include flags as a string.

- `ldflags`

    Fetch `-L.../-l...` link flags as a string.

- `deps`

    Fetch packages together with their dependencies.

- `system`

    Only fetch the package on the current system.

- `external`

    Show `cflags` as external packages (with `-isystem`).

- `installdir`, `cachedir`

    Target the same isolated store used by `install( ... )` (see there).

## `info( ... )`

```perl
my $json = $repo->info( 'zlib', format => 'json' );
my $text = $repo->info( 'libpng' );
my $dot  = $repo->info( 'libpng', depgraph => 1, format => 'dot' );   # dependency graph (Graphviz)
```

Shows package information. Pass `format => 'json'` to receive the decoded data structure (array of hashes), `format => 'dot'` for a Graphviz DOT dependency graph, or `depgraph => 1` to include the package dependency tree. A DOT graph can be rendered with `dot -Tpng dep.dot -o dep.png`.

## `scan( [ ... ] )`

```perl
my @installed = $repo->scan( 'libpng' );
my @all       = $repo->scan();
```

Lists installed packages (optionally filtered by a Lua pattern). Returns the output lines as a list.

## `download( ... )`

```perl
$repo->download( 'zlib', undef, outputdir => './dl', shallow => 1 ); # Downloads the latest version
```

Only downloads the package source archives without building them. `outputdir` selects the destination directory (default `packages`). Supports `force`, `shallow`, and the standard `%options`.

## `import_pkg( ... )`

```perl
$repo->import_pkg( 'zlib', undef, packagedir => './packages' ); # Latest zlib version
$repo->import_pkg( 'libfake', '1.0.x' ); # A particular version of this fake lib
```

Imports pre-downloaded package archives into the local cache. `packagedir` selects the source directory.

## `export( ... )`

```perl
$repo->export( 'zlib', undef, packagedir => './packages', shallow => 1 ); # Export the latest version
```

Exports installed package files for offline use. `packagedir` selects the destination directory.

## `env( [ ..., [ ... ] ] )`

```perl
$repo->env( 'bash', bind => 'zlib' );   # run a program inside the package env
$repo->env( undef, show => 1 );         # only print the environment
```

Sets up the package environment and either prints it (`show`) or executes `$program` (default `shell`) inside it. `bind` selects which environment config or package to bind, `list` lists global configs, and `add`/`remove` manage global environment config files.

## `list_repo()`

```perl
my @repos = $repo->list_repo();
```

Lists all configured remote repositories (as output lines).

## `uninstall( ..., [ ... ] )`

```perl
$repo->uninstall( 'zlib' );
$repo->uninstall( 'zl*', all => 1 );
```

Removes the specified package from the local cache. Accepts the same `%options` as `install( ... )`. `all` removes all matching packages (ignoring extra configs, Lua patterns allowed) and `force` removes addon packages even when they are still depended upon.

## `search( ..., [ ... ] )`

```perl
$repo->search( $query );
$repo->search( $query, addon => 1 );
```

Runs `xrepo search` and returns the matching packages as a list of `name` or `name-version` tokens (in list context; the match count in scalar context). Name and version are returned together because a package name may itself contain `-`, so the boundary cannot be reliably recovered. You can pass a token directly back to `install()` since it is a valid (possibly versioned) spec. Whole tokens also work with `grep`, so callers can filter on plain names.

The output is captured, so nothing is printed to `STDOUT` by this method. On a failed run (nonzero exit, e.g., a missing `vcpkg::` namespace) it `warn`s and returns an empty list. `addon` searches the `addons/` sub-repository.

## `clean( [ ... ] )`

```perl
$repo->clean();
$repo->clean( installdir => './store' );   # clean an isolated store
```

Cleans the cached packages and downloads. Pass `installdir` and/or `cachedir` to target an isolated store.

## `add_repo( ... )`

```
$repo->add_repo( $name, $git_url, $branch );
```

Adds a custom `xmake` repository.

## `remove_repo( ... )`

```
$repo->remove_repo( $name );
```

Removes a custom repository.

## `update_repo( [...] )`

```
$repo->update_repo();        # Update all
$repo->update_repo( 'main' ); # Update specific repo
```

Updates the local package lists from the remote repositories.

# Cache System

`install` avoids paying `xmake`'s process-startup cost on every call. Each successful resolution is memorized as a small JSON record and replayed on the next launch, so a long-lived demo (e.g., ["webui.pl" in eg](https://metacpan.org/pod/eg#webui.pl)) or a build loop running against the same store starts instantly once a package is resolved.

- **What is stored**

    The raw `fetch --json` output plus the resolved install directory, keyed by a SHA-1 fingerprint of the package spec and every option that can move the installed layout (`kind`, `plat`, `arch`, `mode`, `configs`). Config values run through the same boolean stringifier as the CLI, so `configs => { shared => true }` and `configs => { shared => 'true' }` share a key.

- **Where it lives**

    A `cache.json` under `<store>/.alien-xmake/` when an instance or per-call store is set (`root` / `installdir`), otherwise under `<xmake global dir>/.alien-xmake/` (normally `~/.xmake`), honoring `XMAKE_GLOBALDIR`.

- **Validation**

    A hit is only trusted while its recorded install directory still exists on disk. An entry whose package was uninstalled, expired, or otherwise removed disqualifies itself and is pruned on the next save, after which the package is reinstalled normally.

- **Bounded**

    Entries are kept Least-Recently-Used with a fixed cap (64), so the file stays a few hundred KB no matter how many package/option combinations you touch.

- **Disabling**

    Pass `cache => 0` to the ["new( ... )"](#new) constructor, or as a per-call option to ["`install( ... )`"](#install), to force live resolution. [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime) and [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild) accept the same constructor flag and forward it to the engine they create.

# Package Info

Returned by `install( ... )` as `Alien::Xrepo::PackageInfo` objects that contain the results of the dependency resolution.

## Attributes

- **libpath**

    The absolute path to the main library file (`.dll`, `.dylib`, or `.so`). Returns `undef` if the package is header-only or the binary could not be identified.

- **includedirs**

    List of include paths.

- **installdir**

    The package install root. Packages that mostly exist as tools or runnable binaries (`ninja`, `python`, `cmake`, ...) put their executables under `installdir/bin`.

- **bin\_dir**

    List of directories holding executables. Comes from the `bindirs` fetch metadata, or falls back to `installdir/bin` when the package is a tool. You can run a freshly installed binary like so:

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

## Methods

### `find_header( ... )`

```perl
my $path = $info->find_header( 'png.h' );
```

Scans `includedirs` for the given filename and returns the absolute path if found. Returns `undef` otherwise.

# Examples

Documentation can be dense; let's look at some real-world demonstrations.

## Full Distributions

Complete, installable `Alien-*`-like examples are found in `eg/examples/`.

Each is a real dist and includes its `Build.PL` ([Alien::Xrepo::MB](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3AMB)) or `Makefile.PL` ([Alien::Xrepo::MM](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3AMM)), a complete recipe in the main module, unit tests, and examples.

### `Exotic::SDL3`

Demonstrates using `Build.PL` ([Module::Build](https://metacpan.org/pod/Module%3A%3ABuild)) to install multiple packages as a single family: the `libsdl3` core plus the `libsdl3_image`, `libsdl3_ttf`, and `libsdl3_mixer` extensions. Each one is built as a shared library for quick wrapping with `Affix` or [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus).

This dist also carries a local `recipes/` mini `xmake` repo (the `libsdl3_ttf` override) which is registered through `local_repos` to demonstrate how you can modify how prerequisites are handled; in this instance, we force `libfreetype` to be built as a shared lib for `libsdl3_ttf`.

### `Exotic::Ninja`

Another [Module::Build](https://metacpan.org/pod/Module%3A%3ABuild)-based example, but this time we install a binary tool: [ninja](https://ninja-build.org/).

### `Exotic::Zlib`

Also uses [Module::Build](https://metacpan.org/pod/Module%3A%3ABuild), but this time we build a **static** `zlib` to demonstrate setting up a toolchain for [Inline::C](https://metacpan.org/pod/Inline%3A%3AC) or even your XS-based modules.

### `Exotic::SQLite3`

This example demonstrates how you'd define per-package build options.

In this demo, we request a specific toolchain (in this case 'mingw') in the recipe.

### `Exotic::Zstandard`

Builds [Facebook's compression lib](https://facebook.github.io/zstd/), `zstd`, as a shared lib for FFI use.

### `Exotic::Lsquic`

Yet another simple recipe. This time, we build the [LiteSpeed QUIC and HTTP/3 Library](https://github.com/litespeedtech/lsquic).

### `Exotic::Raylib6`

This example demonstrates using [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils%3A%3AMakeMaker) to build the latest branch of raylib as a **shared** library for your favorite FFI. We also introduce the ability to pin to a specific package version rather than always installing the latest.

### `Exotic::Vcpkg::zlib`

A third-party package manager example that installs `zlib` from the `vcpkg` package repository rather than from the official `xmake` repo.

This recipe also shows how you'd install a tool that you require in order to build another target. See ["How third-party namespaces are installed"](#how-third-party-namespaces-are-installed).

Copy any of these as a starting point; rename the module, adjust `recipe()`, and your dist builds, installs, and consumes the same way.

## Standalone Scripts

The loose scripts found in `eg/` are runnable examples you can build on.

### `eg/alien_xrepo.pl`

The broadest walkthrough: list remote repositories, scan what is installed, install `libvorbis` (shared), install `libpng` with cross/optimization options (`kind`, `plat`, `arch`, `mode`, `configs`), then bind single functions with [Affix](https://metacpan.org/pod/Affix) (`zlib`, `sqlite3`) and [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus) (`lz4`).

### `eg/xrepo_binary.pl`

The binary-tool walkthrough: installs `ninja` and runs it two ways, straight from `bin_dir` or with `bin_dir` prepended to `PATH`.

### `eg/xrepo_inline_c.pl`

Installs `libpng` and `zlib` together, merges their include/link dirs, and binds them with [Inline::C](https://metacpan.org/pod/Inline%3A%3AC).

### `eg/xrepo_features.pl`

A feature tour with toggles: repositories/search, install plus `fetch` flags and `find_header`, the dependency graph as Graphviz `DOT`, a project-local isolated store (`installdir`) with `scan` and `fetch` against it, binary tools including the `python` interpreter, third-party managers (`vcpkg::`, `conan::`, `brew::`) gated behind `--third-party`, offline `download`, `env` with `show`, and `uninstall`/`clean` (gated behind `--clean`).

### `eg/xrepo_dependency_graph.pl`

A simple example to dump a Graphviz-ready dependency graph.

### `eg/webui.pl`

A complete object-oriented desktop-app demo. It installs the `webui` library and wraps it with [Affix](https://metacpan.org/pod/Affix). This also shows off this dist's cache system to avoid rebuilding packages.

## Recipes

If you just want to use a library, copy one of these. Each one installs whatever is missing on the first run and takes care of the rest. It's not a full cookbook, but these will get you started.

### Hello World (install then call)

`install( ... )` downloads and builds the library for you, then `libpath` points [Affix](https://metacpan.org/pod/Affix) or [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus) to the matching shared `.dll` / `.so` / `.dylib`.

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

And if you want the whole library wrapped (prototypes generated from the headers) instead of one function at a time, use [Affix::Wrap](https://metacpan.org/pod/Affix%3A%3AWrap):

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

### Link an XS extension with Inline::C (multiple libraries)

Same idea for an actual C extension, compiled with [Inline::C](https://metacpan.org/pod/Inline%3A%3AC). Install every library you want to link; merge their include and link directories, hand them to `Inline::C`, and write plain C that uses whichever header you need. Here we bind both `libpng` and `zlib` (installed together into one store) into a single XS function:

```perl
use v5.40;
use Alien::Xrepo;
use Config;

my $repo = Alien::Xrepo->new;
my $png  = $repo->install('libpng');       # shared lib
my $zlib = $repo->install('zlib');         # second shared lib

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

The _eg/xrepo\_inline\_c.pl_ script is the runnable copy of this example. `Inline::C` is not installed with this distribution. Install it once with `cpanm Inline::C`.

### Install and run a binary tool

`xrepo` does not build only shared libraries; it also ships ready-to-run binaries (`ninja`, `cmake`, `meson`, `node`, `python`, `go`, `rust`, ...). `install` returns the package `installdir`, and `bin_dir` tells you where the executables live. Run one directly, or stick `bin_dir` in front of `PATH` so all the children you spawn find the tool:

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

### Build a C program against a library

`install` builds the library once; `fetch` tells you the `-I...` and `-L.../-l...` flags if you are building with something other than `xmake` (e.g., MakeMaker or a plain `cc`):

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;
$repo->install( 'libpng' );                       # build it once
my $cflags  = $repo->fetch( 'libpng', undef, cflags  => 1 );
my $ldflags = $repo->fetch( 'libpng', undef, ldflags => 1 );
say "cc $cflags $ldflags pngprog.c -o pngprog";
```

### What can I install? What do I already have?

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

### Cross-compile without memorizing SDK paths

All of `xrepo`'s platform switches become named options. `ndk` is just one example, alongside `toolchain`, `sdk`, `mingw`, and the rest.

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

### Drop into a shell inside the library's environment

`env` sets up the environment for a package (PATH, etc.) and either runs `$program` inside it (default: the system shell) or just prints it with `show`.

```perl
use v5.40;
use Alien::Xrepo;
Alien::Xrepo->new->env( 'bash', bind => 'zlib' ); # or env( undef, bind => 'zlib' )
# Alien::Xrepo->new->env( undef, show => 1 );     # just print the environment
```

### Guard an install against a package that may not exist

`search` reports what the configured repositories actually provide. Check before you `install` so a spec that is absent (or renamed) in the active repos fails cleanly instead of erroring mid-way:

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

`search` returns whole tokens (`zlib-v1.3.2`, `zlib-ng-2.3.3`, ...), so `grep` narrows the list to plain-name matches even though `xrepo search` also lists packages whose description matches the query.

### Run a binary tool and check it worked

`env` wraps the given program with the package's environment (PATH already adjusted) and returns its exit status, so it doubles as a smoke test that the tool actually runs:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;
my $cmake = $repo->install('cmake');            # kind: binary
my $rc = $repo->env('cmake', '--version');      # runs cmake with its bin_dir on PATH
die "cmake failed to run" unless $rc == 0;
```

### Bundle a package for offline use

`download` fetches the source archives without building, `import_pkg` drops them into the local cache, and a subsequent `install` uses them even on a machine with no network. Handy for air-gapped CI or offline installs:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;

$repo->download( 'zlib', undef, outputdir => './dl', shallow => 1 );   # fetch sources (no build)
$repo->import_pkg( 'zlib', undef, packagedir => './dl' );              # load into the cache
my $zlib = $repo->install('zlib');                                     # install offline
say 'installed ' . $zlib->version;
```

### Render the dependency graph

`info( ... depgraph =` 1, format => 'dot')> emits a Graphviz `DOT` description of a package and everything it pulls in. Pipe it to `dot -Tpng dep.dot -o dep.png` to picture how a library's prerequisites resolve:

```perl
use v5.40;
use Alien::Xrepo;

my $dot = Alien::Xrepo->new->info( 'libpng', depgraph => 1, format => 'dot' );
say $dot;    # e.g.  dot -Tpng dep.dot -o dep.png
```

### Cross-compile a library, then read its compiler/link flags

Install a library for another platform/architecture (the same switches `xrepo` accepts become named options), then `fetch` the `-I...` / `-L.../-l...` flags you would pass to your own compiler:

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

### Remove a package from the cache

`uninstall` removes a package from the local store (the same one `install`/`fetch`/`scan` use, or an isolated `root` you installed into). It accepts the same options as `install`; `all` removes every stored variant, and `force` removes a package even when others still depend on it. It returns the underlying exit status, so check `$?`:

```perl
use v5.40;
use Alien::Xrepo;

my $repo = Alien::Xrepo->new;

$repo->uninstall('freetype');               # remove one package
$repo->uninstall('zl*', all => 1);          # every variant matching the pattern
$repo->uninstall('fontconfig', force => 1); # remove even if still depended upon
```

Note that this edits the shared store. Unlike a builder's prune, which slims the `share` directory a distribution ships, `uninstall` frees space in the store you manage yourself.

# Third-party Package Managers

`xrepo` can install from external package managers instead of (or alongside) the official `xmake-repo`. You select the manager with a package-spec namespace and every `Alien::Xrepo` method takes it verbatim:

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

The installed results (`libpath`, `includedirs`, `links`, ...) are decoded into an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo) exactly like any `xmake-repo` package, so your wrapper code does not care where the library came from.

See the `xmake-repo` [integration notes](https://github.com/xmake-io/xrepo-docs/blob/master/getting_started.md) for the corresponding `add_requires` syntax inside an `xmake` project.

## How third-party namespaces are installed

A package in a third-party namespace (`vcpkg::zlib`) is installed by the _external_ manager, and `xmake`'s integration does not bootstrap that manager for you: e.g., the `vcpkg` integration raises **`vcpkg not found!`** when it cannot locate the tool (`find_vcpkgdir` checks the `xmake g --vcpkg` global config, `$VCPKG_ROOT`, `$VCPKG_INSTALLATION_ROOT`, Homebrew, and the Windows `vcpkg.path.txt` lookup in that order). A recipe that installs from a third-party namespace therefore lists the **bare tool package** that owns the namespace as well:

```perl
packages => [ { name => 'vcpkg::zlib' }, { name => 'vcpkg' } ]
```

These two names mean different things, and their order in the recipe is not their install order:

- **Recipe order**: (`vcpkg::zlib` then `vcpkg`) is the _consumer_ order. [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime) resolves `libpath`, `find_header`, `cflags`, and `libs` against the _first_ package, so the library comes first and the bare tool package exists only to make the manager available. (If you list the tool first, the consumer targets the tool, which has neither headers nor linkable libraries.)
- **Install order**: (`vcpkg` then `vcpkg::zlib`) is computed by [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild)'s `_install_order()`: any bare package whose name is the namespace of a later `ns::pkg` entry is installed first, so its store path is known before the namespaced install runs regardless of the order they appear in the recipe.

Once the bare tool is installed, the engine copies its install dir into the environment of the next namespaced spawn: for `vcpkg` it sets `VCPKG_ROOT` (and prepends the tool dir to `PATH`), so `xmake`'s `vcpkg` integration finds the freshly built binary. `vcpkg` then installs the package into its own tree under the tool's install dir (`<vcpkg root>/installed/<triplet>/`), and the engine rebases those paths so the snapshot stays hermetic under the distribution's `share` directory exactly like any normal `xmake-repo` package.

Two implementation details make that work and are easy to get wrong (see [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild)):

- `_pkg_installdir` refuses _namespaced_ (`::`) packages. The external manager owns the on-disk layout, so a per-package store path such as `<share>/vcpkg::zlib` is meaningless and the store guard would reject a perfectly valid install. Leaving `installdir` unset for those packages lets the manager pick its own tree.
- Environment propagation uses a hash-slice `local`:

    ```
    local @ENV{ keys %env } = values %env if %env;
    ```

    The otherwise-obvious form `local $ENV{$_} = $env{$_} for keys %env` silently binds the _global_ `$_` (not the loop variable) in some builds of Perl, so the values never reach the child process.

Also note that the decoded `fetch --json` output for third-party packages is not always a tidy list: `libfiles`, `bindirs`, `includedirs`, and `linkdirs` may each arrive as a plain string when there is exactly one file or directory. The engine normalizes those scalars into one-element lists before use.

# SEE ALSO

[https://xrepo.xmake.io](https://xrepo.xmake.io), [https://packages.xmake.io/](https://packages.xmake.io/)

[Alien::Xmake](https://metacpan.org/pod/Alien%3A%3AXmake), [Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild), [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime)

[Alien::Xrepo::MB](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3AMB), [Alien::Xrepo::MM](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3AMM), [Alien::Xrepo::Build::Dist](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild%3A%3ADist)

[Affix](https://metacpan.org/pod/Affix), [Affix::Wrap](https://metacpan.org/pod/Affix%3A%3AWrap), [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus), [Inline::C](https://metacpan.org/pod/Inline%3A%3AC)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson [https://github.com/sanko](https://github.com/sanko)
