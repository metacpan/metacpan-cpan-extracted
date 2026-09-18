---
name: alien-tinycdb-core
description: "Use when working on Alien::TinyCDB — the alienfile build recipe, the Alien::Build probe/download/make pipeline, dist.ini's alien_build=1 config, lib/Alien/TinyCDB.pm, or the cflags/libs/dynamic_libs contract this Alien hands to XS or FFI consumers of Michael Tokarev's TinyCDB (corpit.ru cdb) C library. Covers the alienfile, share-vs-system probing, the shared library built for FFI, and that upstream is fetched (not vendored)."
---

# Alien::TinyCDB — what this distribution actually decides

`Alien::TinyCDB` is a thin `Alien::Base` wrapper whose whole job is to make the
**TinyCDB** C library (Michael Tokarev's public-domain implementation of djb's constant
database, `http://www.corpit.ru/mjt/tinycdb`) available to Perl consumers through the
standard `cflags`/`libs`/`dynamic_libs` methods — either by detecting a system install or
by building it from upstream source.

Generic Alien / consumer mechanics live in skill `perl-alien`; the XS/link side in skill
`perl-xs`. This skill is only the TinyCDB-specific invariants — read it before editing the
`alienfile` or reasoning about why a consumer's link broke.

## The build lives in the alienfile (Alien::Build path)

The build recipe is the `alienfile` in the distribution root, run by `Alien::Build`.
`[@Author::GETTY]` carries **`alien_build = 1`**, which wires in
`Dist::Zilla::Plugin::AlienBuild`: it generates a `Makefile.PL` driven by
`Alien::Build::MM`. MakeMaker **stays** — `Alien::Build::MM` munges that generated
`Makefile.PL`, so there is **no `Build.PL`**. `cpanfile` declares `Alien::Build`,
`Alien::Build::MM` and `ExtUtils::MakeMaker` under `configure`. To change build behaviour
you edit the `alienfile`, not `dist.ini`.

The `alienfile` is one probe/build chain:

```perl
plugin 'PkgConfig' => ( pkg_name => 'libcdb' );    # system probe: upstream ships libcdb.pc

share {
  start_url 'http://www.corpit.ru/mjt/tinycdb/';   # newest tinycdb-<version>.tar.gz, not pinned
  plugin 'Download' => (
    filter  => qr/^tinycdb-[0-9\.]+\.tar\.gz$/,
    version => qr/^tinycdb-([0-9\.]+)\.tar\.gz$/,
  );
  plugin 'Extract' => 'tar.gz';
  build [                                           # plain hand-written Makefile, no ./configure
    '%{make} prefix=%{.install.prefix} static sharedlib',
    '%{make} prefix=%{.install.prefix} install install-sharedlib',
  ];
  plugin 'Gather::IsolateDynamic';                  # move libcdb.so* into dynamic/
  gather sub {                                      # cflags -I<prefix>/include, libs -L<prefix>/lib -lcdb
    my ($build) = @_;
    my $prefix = $build->runtime_prop->{prefix};
    $build->runtime_prop->{cflags} = "-I$prefix/include";
    $build->runtime_prop->{libs}   = "-L$prefix/lib -lcdb";
  };
};
```

The load-bearing detail: TinyCDB's `Makefile` defaults to `all: static` — only `libcdb.a`
plus the `cdb` binary. The shared library lives behind the separate `sharedlib` /
`install-sharedlib` targets, which upstream marks GNU CC/LD specific (`-fPIC` / `-shared`).
This dist runs **both** the static and the shared targets, so `->libs` links `libcdb.a`
and `->dynamic_libs` finds `libcdb.so` — FFI works, not only XS. `%{.install.prefix}` is
the staging prefix Alien supplies; never replace it with a literal path.

## Upstream is fetched, not vendored

Unlike a dist that bundles a `share/*.tar.gz`, this one has **no tarball in the repo**.
The share build downloads from the `alienfile`'s `start_url` at install time and the
`Download` plugin matches the **newest** `tinycdb-<version>.tar.gz` the directory lists —
the version is **not pinned**, and the fetch is plain `http`. Consequences:

- The share-build path needs **network access, a C compiler, and `make`** at install
  time. An air-gapped host with no system TinyCDB cannot install.
- A new upstream release is picked up automatically. Pinning a version (and adding a
  digest — a future `Alien::Build` will require one for an insecure `http` fetch) is an
  `alienfile` change and a maintainer decision.

## share vs system

The `alienfile`'s `PkgConfig` plugin probes for a system `libcdb` first: if a usable one
is found it takes the **system** path and gathers flags from pkg-config; otherwise the
`share` block runs the download + `make` above into the Alien's own prefix. A machine that
has the library installed never exercises the share build — so a change to the build config
must be tested with `ALIEN_INSTALL_TYPE=share` forced, not just on the maintainer's box.

The two paths gather **different flags**, and both are correct:

- **system** — `cflags` can be legitimately empty (the header is on the default include
  path, so pkg-config emits no `-I`); `libs` is `-lcdb`; `dynamic_libs` is the system
  `libcdb.so`.
- **share** — `cflags` is `-I<prefix>/include`; `libs` is `-L<prefix>/lib -lcdb`;
  `dynamic_libs` is the built `libcdb.so`.

## The consumer contract

Everything downstream asks the class and never repeats the logic:

```perl
Alien::TinyCDB->cflags         # C compiler flags to compile against TinyCDB
Alien::TinyCDB->libs           # linker flags to link against it
Alien::TinyCDB->dynamic_libs   # dynamic library paths, for FFI::Platypus->lib(...)
```

An XS consumer feeds `cflags`/`libs` into `INC`/`LIBS` in its `Makefile.PL`; an FFI
consumer passes `dynamic_libs` to `FFI::Platypus->lib`. The Alien belongs in the
consumer's **`configure_requires`** — its flags are needed before the consumer's build
runs. **Consumers never hardcode a `-l`/`-I` string; they ask the Alien**, which is the
entire reason this distribution exists.

`lib/Alien/TinyCDB.pm` is `use parent 'Alien::Base';` plus POD — **no logic, do not add
any**. Every flag a consumer gets comes from `Alien::Base` reading what the build
gathered; nothing is computed in the `.pm`.

## The smoke test

`t/load.t` asserts the consumer contract per install type: `libs` always carries `-lcdb`;
`cflags` must carry a `-I` include path on the **share** path but may be empty on the
**system** path (header on the default include path); and `dynamic_libs` returns at least
one real shared object on **both** paths (the FFI contract). That is the reason the
distribution exists — a change that breaks compile/link or FFI breaks every consumer, so
keep those assertions meaningful and path-aware rather than loosening them to pass.
