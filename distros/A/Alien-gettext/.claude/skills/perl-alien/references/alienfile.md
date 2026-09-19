# The alienfile in detail

## Interpolation

`%{…}` is expanded by Alien::Build against helpers and install properties:

| Token | Is |
|---|---|
| `%{cmake}`, `%{make}`, `%{perl}` | the tool as this build should invoke it |
| `%{.install.prefix}` | the staging prefix the built library must land in |
| `%{.install.extract}` | the extracted source directory |
| `%{.install.download}` | the downloaded file, before extraction |
| `%{.install.stage}` | the staging directory the build installs into |
| `%{.runtime.prefix}` | the final prefix, at runtime |

`%{.install.X}` and `%{.runtime.X}` reach **any** key of `install_prop` /
`runtime_prop`, including ones the alienfile sets itself — the rows above are the
ones Alien::Build fills in for you.

A helper can be defined in the alienfile and then used in any command string:

```perl
meta->interpolator->add_helper(foo_config => sub { 'foo-config' });
```

## Command lists

`build` takes an arrayref of commands. A plain string is interpolated and run
through the shell; a nested arrayref is `system()`-style, argument by argument, and
is what to use as soon as any argument can contain a space:

```perl
build [
  [ '%{cmake}', '-DCMAKE_INSTALL_PREFIX=%{.install.prefix}', '%{.install.extract}' ],
  '%{make}',
  '%{make} install',
];
```

`build sub { … }` replaces the list with Perl when the build is not a sequence of
commands — compiling a single amalgamation file, say:

```perl
build sub {
  my ($build) = @_;
  require Config;
  my $cc     = $Config::Config{cc};
  my $dlext  = $Config::Config{dlext};
  my $shared = $^O eq 'darwin' ? '-dynamiclib' : '-shared';
  my $stage  = $build->install_prop->{stage};

  my @cmd = ($cc, '-O2', '-fPIC', $shared, 'foo.c', '-o', "$stage/dynamic/libfoo.$dlext");
  $build->log("Compiling: @cmd");
  system(@cmd) == 0 or die "compilation of foo failed";

  $build->runtime_prop->{ffi_name} = 'foo';
};
```

`$build->log` is how build output reaches the install log — a `print` there is
invisible in the failure report a user sends you.

## install_prop vs runtime_prop

- **`install_prop`** — valid only during the build: `prefix` (staging), `stage`,
  `extract`, `download`. Meaningless afterwards.
- **`runtime_prop`** — serialised into `_alien/alien.json` and readable forever
  through `Alien::Foo->runtime_prop`. `cflags`, `libs`, `version` live here, and so
  does anything custom: an FFI library name, a data directory, a feature flag the
  consumer needs to branch on.

```perl
sys {
  gather sub {
    my ($build) = @_;
    chomp( my $cflags = `pkg-config --cflags libssh` );
    $build->runtime_prop->{cflags} = $cflags;
  };
};
```

Writing that `sys` block by hand is only worth it when `plugin 'PkgConfig'` cannot
do the job — a library that ships a `foo-config` script instead of a `.pc` file, for
instance.

## Hooking gather

For a share build with a real build system, the properties are gathered
automatically. Builds that just copy files into place have nothing to gather from,
and must fill the properties **before** Alien::Build's own gather step writes
`alien.json` and rewrites the staging prefix:

```perl
meta->before_hook(gather_share => sub {
  my ($build) = @_;
  my $stage   = $build->install_prop->{stage};
  my $extract = $build->install_prop->{extract};

  for my $rel (qw( include src )) {
    my $src = path("$extract/$rel");
    next unless -d $src;
    path("$stage/$rel")->mkpath;
    Alien::Build::Util::_mirror($src, path("$stage/$rel"));
  }
});
```

The ordering is the whole point: after the core gather hook has run, the prefix in
anything you write is the staging path, and it will not be rewritten.

## Plugin catalogue

Install-time negotiation picks a concrete implementation for most of these — name
the family (`Fetch`, `Extract`) and let it choose, unless the choice matters.

| Family | Plugins | Notes |
|---|---|---|
| Probe | `CBuilder`, `CommandLine`, `Vcpkg` | `CBuilder` compiles a test program — the honest probe when there is no pkg-config |
| PkgConfig | `PkgConfig` (negotiate), `CommandLine`, `LibPkgConf`, `PP`, `MakeStatic` | the negotiating form is what an alienfile should name |
| Download | `Download` (negotiate), `GitHub` | `GitHub` resolves releases and tags from the API |
| Fetch | `HTTPTiny`, `CurlCommand`, `Wget`, `LWP`, `NetFTP`, `Local`, `LocalDir` | `Local` is the bundled-tarball case |
| Decode | `HTML`, `DirListing`, `DirListingFtpcopy`, `Mojo` | parsing an index page to find the newest release |
| Prefer | `SortVersions`, `GoodVersion`, `BadVersion` | choosing among the versions found; `BadVersion` blacklists known-broken ones |
| Extract | `ArchiveTar`, `ArchiveZip`, `CommandLine`, `Directory`, `File` | `plugin 'Extract' => 'tar.xz'` negotiates from the suffix |
| Build | `CMake`, `Autoconf`, `Make`, `Copy`, `MSYS`, `SearchDep` | `MSYS` for Windows; `SearchDep` pulls in another Alien's libs |
| Digest | `SHA`, `SHAPP` | checksum verification of the download |
| Gather | `IsolateDynamic` | keeps `.so` files out of the static link |
| Test | `Mock` | for testing the alienfile itself |

`Build::CMake` and `Build::Autoconf` do more than name the tool: they set the flags
that make a build relocatable and provide `%{cmake}` / `%{configure}` with the right
arguments for the platform. Use them rather than invoking the tool directly.
