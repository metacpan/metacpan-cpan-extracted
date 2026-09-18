---
name: perl-alien
description: "Use when a distribution provides a C library or tool through Alien::Build — writing or debugging an alienfile, probe/system/share builds, pkg-config detection, bundling a source tarball, or consuming cflags and libs from Alien::Base in an XS or FFI module."
---

# Alien — providing a C library to CPAN

An `Alien::Foo` distribution answers one question at install time: **is a usable
libfoo already here, and if not, how is one built?** Everything downstream — the XS
module that links against it, the FFI module that dlopens it — asks the resulting
class for flags and never repeats that logic.

Two halves, both small:

- The **`alienfile`** in the distribution root describes probing and building.
- **`lib/Alien/Foo.pm`** is `use parent 'Alien::Base';` plus POD. There is no logic
  to write there — `Alien::Base` supplies `cflags`, `libs`, `dynamic_libs`,
  `bin_dir`, `version`, `runtime_prop`.

Build details, properties and the plugin catalogue:
[references/alienfile.md](references/alienfile.md).
The XS/FFI side, `cpanfile`, and `Test::Alien`:
[references/consuming-and-testing.md](references/consuming-and-testing.md).

## The shape

```perl
use alienfile;
use Path::Tiny;

plugin 'PkgConfig' => (
  pkg_name        => 'libssh',
  minimum_version => '0.9',
);

share {
  start_url 'file://' . path('share/libssh-0.10.6.tar.xz')->absolute->stringify;
  plugin 'Fetch::Local';
  plugin 'Extract' => 'tar.xz';
  plugin 'Build::CMake';

  build [
    [ '%{cmake}', '-DCMAKE_INSTALL_PREFIX=%{.install.prefix}',
      '-DCMAKE_BUILD_TYPE=Release', '%{.install.extract}' ],
    '%{make}',
    '%{make} install',
  ];
};
```

| Block | Runs when | Holds |
|---|---|---|
| `probe` | always, first | the test for a usable system library |
| `sys` | probe said `system` | how to gather flags from what is installed |
| `share` | probe said `share` | fetch, extract, build into the Alien's own prefix |

## Let the PkgConfig plugin write the probe

`plugin 'PkgConfig'` covers probe and `sys` in one line: it tests with pkg-config,
gathers `cflags`/`libs`/`version` from it, and leaves only `share` to write. A
hand-rolled `probe [ 'pkg-config --exists libfoo' ]` plus a `sys { gather sub { … } }`
that shells out to pkg-config is the same thing with more places to be wrong — and
it quietly has no version check.

For a library with no stable system packaging, skip the probe entirely:

```perl
probe sub { 'share' };
```

## minimum_version earns its keep

A system library that is present but too old is worse than none: it links, it runs,
and it misbehaves. State the floor in the probe, and **say in a comment what the
floor is for** — an API that appeared, or a bug that was fixed, with the measurement
if there was one. Without that sentence the number becomes unfalsifiable, and nobody
dares raise or lower it later.

Pin it where the behaviour you depend on actually landed. The floor decides how many
users get a share build instead of their distribution's patched package.

## Bundle the tarball, or fetch it

`start_url` pointing at a `file://` path in `share/` with `plugin 'Fetch::Local'`
makes the install work with no network — the requirement for air-gapped and
firewalled build hosts, and one less thing between a user and a successful install.
The cost is distribution size and a manual bump when upstream releases. Fetching
from upstream instead trades that for a download in everyone's install path.

Build the URL with `Path::Tiny`, absolute: a relative path in a `file://` URL fails
to fetch without saying why.

## Never hardcode a path

`%{.install.prefix}` is a **staging** directory that gets rewritten at install time.
A literal path baked into `build` survives testing on the machine that built it and
breaks everywhere else. Same for the tools: `%{cmake}`, `%{make}`, `%{perl}`.

## Consuming it

```perl
use Alien::libssh;                       # in the consumer's Makefile.PL
WriteMakefile(
  LIBS => [ Alien::libssh->libs ],
  INC  => Alien::libssh->cflags,
);
```

The Alien goes in **`configure_requires`** — its flags are needed before the
consumer's `Makefile.PL` runs, so a plain `requires` is too late.

## Prove both paths

```bash
env ALIEN_INSTALL_TYPE=share  perl Makefile.PL   # force the build-from-source path
env ALIEN_INSTALL_TYPE=system perl Makefile.PL   # force the system path
```

An Alien developed on a machine that has the library has never run its own share
build. Run both in CI, and let `Test::Alien`'s `xs_ok` compile a real snippet
against the flags — that is the only test covering probe, build, gather and flags as
one chain.

Build logs and the gathered `alien.json` land in `_alien/`. Read that file first
when a consumer gets flags it did not expect.
