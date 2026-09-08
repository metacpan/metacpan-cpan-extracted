# NAME

Alien::Build::Plugin::Build::Xrepo - Build and Gather xrepo Packages in an alienfile

# SYNOPSIS

```perl
use alienfile;

plugin 'Build::Xrepo' => (
    packages => [ 'zstd' ]
);

# or, multiple packages at once with per-package options and FFI:

plugin 'Build::Xrepo' => (
    packages => [
        'zstd',
        { name => 'libsdl3', version => '3.4.12', kind => 'shared' }
    ],
    ffi  => 1
);
```

# DESCRIPTION

This plugin lets an [alienfile](https://metacpan.org/pod/alienfile)-based [Alien](https://metacpan.org/pod/Alien) distribution install its packages through
[xrepo](https://packages.xmake.io/), [vcpkg](https://vcpkg.io/en/packages), [conan](https://conan.io/center),
[brew](https://brew.sh/) (homebrew/linuxbrew), [conda](https://anaconda.org/), [dub](https://dub.pm/) (Dlang libs),
[apt](https://www.debian.org/distrib/packages) on Debian,
[pacman](https://wiki.archlinux.org/title/Pacman#Installing_packages) (if you use arch, btw),
[clib](https://github.com/clibs/clib/), [Cargo](https://crates.io/) for Rust crates,
[Portage](https://packages.gentoo.org/) on Gentoo, [Nimble](https://nimpackages.com/) for nimlang,
[NuGet](https://www.nuget.org/) for .NET,
[Zypper](https://documentation.suse.com/smart/systems-management/html/concept-zypper/index.html) on openSUSE, instead
of downloading, extracting and compiling source archives. It is the [Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild) mirror of the
[Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild) engine: the `download` stage asks xrepo for the packages (through [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo)), the
`build` stage assembles the exported package trees into the staging prefix, and the `gather` stages translate them
into the standard [Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild) runtime properties (`cflags`, `libs`, `version`, `bin_dir`, plus `alt` for
multi-package recipes).

The `download` stage writes the exported package trees and a `xrepo.manifest` into its working directory (a fresh
[Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild) temp dir), so `download_detail` records that local tree as a `file`-protocol source. The `extract`
stage then copies that tree into the current working directory, which is exactly the staging scaffold [Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild)
prepares for every extract hook (see ["extract hook" in Alien::Build::Manual::PluginAuthor](https://metacpan.org/pod/Alien%3A%3ABuild%3A%3AManual%3A%3APluginAuthor#extract-hook)): unlike the built-in archive
extractors the `dest` argument is the download location, not a destination, so content lands correctly in the cwd
scaffold and the following `build`/`gather` phases see it.

The plugin always returns `share` from the `probe` stage: xrepo is the installer. Constructing the engine during
probe fails fast with a clear error (so a broken engine is reported at probe, not as a confusing later failure). The
xrepo executable is located during the `download` stage and a missing executable aborts that stage with a clear error
instead of guessing.

A failed package never sinks its siblings: per-package install/export failures are isolated, the surviving packages
still build, and the expected output of the `download` stage is a partial success - but it is never silent. Failures
are recorded in `install_prop->{xrepo}{errors}` and mirrored into `runtime_prop->{errors}` (keyed by package
name), a `xrepo.manifest` is written listing only the packages that actually installed and exported, and a warning is
emitted naming the failed packages. Consumers can check `runtime_prop->{errors}` to see exactly what is missing.
The build only aborts when no package installed at all.

# PROPERTIES

## `packages`

The packages to install, in recipe order. Each entry is a package name or a hashref of per-package options, the same
keys the [Alien::Xrepo::Build::Recipe](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild%3A%3ARecipe) understands (name, version, kind, plat, arch, toolchain, configs, etc.). The
first entry is the primary package.

## `version`

An ambient version constraint (e.g. `1.5.6`) folded into every package that does not pin its own `version`.

## `kind`

An ambient package kind (`shared` or `static`) folded into every package that does not pin its own `kind`.

## `root`

An optional xrepo store root (`XMAKE_PKG_INSTALLDIR`). Defaults to whatever the system xrepo configuration uses.

## `ffi`

When true, a `gather_ffi` hook is registered that populates `%{.runtime.ffi_name}` and `%{.runtime.dynamic_libs}`
from the installed packages, for use by `build_ffi` consumers.

## `verbose`

Echo xrepo commands as they run (passed through to [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo)).

## `repo`

An optional [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo)-compatible engine (an object, a class name, or a code ref that returns one). Mainly useful
for testing the plugin against a spy without a real xrepo install. When unset, the plugin builds an [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo)
with `root` and `verbose`.

## `local_repos`

An optional arrayref of directory paths pointing to local xmake-repo trees (each containing a `packages/`
subdirectory). These are registered with the engine before installation, allowing patched or private package recipes to
override the upstream xrepo store.

# HELPERS

- `%{xrepo}`

    The resolved path to the `xrepo` executable.

- `%{xmake}`

    The resolved path to the `xmake` executable.

- `%{xrepo_cflags}`

    The gathered include flags for the primary package.

- `%{xrepo_libs}`

    The gathered link flags for the primary package.

- `%{xrepo_version}`

    The gathered version of the primary package.

- `%{xrepo_dynamic_libs}`

    The gathered dynamic library paths (when the `ffi` property is enabled).

# SEE ALSO

[Alien::Build](https://metacpan.org/pod/Alien%3A%3ABuild), [alienfile](https://metacpan.org/pod/alienfile), [Alien::Build::Plugin](https://metacpan.org/pod/Alien%3A%3ABuild%3A%3APlugin), [Alien::Build::Manual::PluginAuthor](https://metacpan.org/pod/Alien%3A%3ABuild%3A%3AManual%3A%3APluginAuthor), [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo),
[Alien::Xrepo::Build](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild), [Alien::Xrepo::Build::Recipe](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABuild%3A%3ARecipe), [Alien::Xrepo::Runtime](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ARuntime)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson [https://github.com/sanko](https://github.com/sanko)
