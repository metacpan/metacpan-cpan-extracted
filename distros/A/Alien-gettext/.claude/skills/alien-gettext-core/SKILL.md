---
name: alien-gettext-core
description: Use when working on the Alien::gettext distribution — its [@Author::GETTY] alien config (alien_repo + alien_bins), the system-vs-share probe, the GNU-FTP source download, the msgfmt/xgettext tool set it exposes, or the bin_dir contract its consumers rely on.
metadata:
  type: project
---

# Alien::gettext — core

Force-loaded into every `alien-gettext-*` agent before its first turn; do not
restate it in an agent body. Generic Alien mechanics (probe/system/share,
`install_prop` vs `runtime_prop`, `Test::Alien`) live in skill `perl-alien` —
this file holds only what is true about *this* distribution.

## What the distribution is

One job: make the **GNU gettext command-line utilities** available to Perl, over
two install paths decided at install time.

This is a **tools Alien**, not a library Alien. It exposes executables
(`msgfmt`, `xgettext`, …) through `Alien::gettext->bin_dir` — there is **no
linkable library, no `cflags`/`libs`, no XS, no FFI, no Perl/C boundary**.
Consumers prepend `bin_dir` to `PATH` and shell out to the tools:

```perl
use Alien::gettext;
use Env qw( @PATH );
unshift @PATH, Alien::gettext->bin_dir;
# now `msgfmt`, `xgettext`, … resolve as external commands
```

`lib/Alien/gettext.pm` is deliberately logic-free: `use parent 'Alien::Base'` +
POD, nothing else. Every decision lives in the generated build config, not in
Perl. Do not add methods there to "help" consumers — the contract is `bin_dir`
and the tools on it.

The lowercase module name (`Alien::gettext`, not `Alien::Gettext`) is
intentional and matches the tool-Alien convention — do not "correct" it.

## The build is generated, not checked in — it lives in dist.ini

There is **no `alienfile` and no `Build.PL` in the tree**. Both are produced at
`dzil build` from two keys in `dist.ini`:

```ini
[@Author::GETTY]
alien_repo = http://ftp.gnu.org/pub/gnu/gettext
alien_bins = msgfmt msgfilter msgcmp msgcomm xgettext msgexec msguniq msginit msgunfmt msgconv
```

`alien_repo` (any non-empty value) is what flips the bundle into Alien mode; it
emits `[Alien]` (`Dist::Zilla::Plugin::Alien`), which builds a `Build.PL` on top
of **`Alien::Base::ModuleBuild`** — the classic Module-Build path, *not*
`Alien::Build`/`alienfile`. So the mental model here is Alien::Base::ModuleBuild,
and `perl-alien`'s `alienfile` recipes do **not** apply verbatim. To change the
build you edit `dist.ini` (or the bundle / the `Dist::Zilla::Plugin::Alien`
knobs — `alien_pattern*`, `alien_version_check`, `alien_build_command`, …), never
a file in the repo root.

## Two install paths

Alien::Base::ModuleBuild probes at install time and picks one:

- **system** — a usable gettext is already on the box; the Alien points at it and
  builds nothing. There is **no version floor set** (`alien_version_check` is
  unset), so *any* system gettext satisfies the probe. The generated per-tool
  wrappers exist only for share installs; on a system install the tools resolve
  from the system location.
- **share** — no system gettext (or the probe is forced off); the newest source
  tarball matching the pattern is **downloaded from `ftp.gnu.org`**, then
  `./configure && make && make install` into the `File::ShareDir` share dir. For
  each name in `alien_bins` a `bin/<tool>` wrapper is generated that `exec`s the
  freshly built tool out of the share dir.

**The share build needs the network** — unlike a bundled-tarball Alien, this one
has no source in `share/` and fetches from GNU at install time. A GNU mirror
outage, or the newest tarball changing name/shape, breaks the share build. If an
offline/pinned install is ever required, that is a real design change (bundle a
tarball or set `alien_exact_filename`), not a tweak.

## The pattern picks "newest on the mirror"

`Dist::Zilla::Plugin::Alien` defaults the download pattern to
`^gettext-([\d\.]+)\.tar\.gz$` (prefix = module name minus `Alien-`, i.e.
`gettext-`; version `([\d\.]+)`; suffix `\.tar\.gz`). It selects the
highest-versioned match in `alien_repo`. Nothing pins a version — a new GNU
release is picked up automatically on the next share install. Set
`alien_pattern*` / `alien_exact_filename` in `dist.ini` if that ever needs
constraining.

## `alien_bins` is the authoritative tool set

The ten tools this distribution promises: `msgfmt msgfilter msgcmp msgcomm
xgettext msgexec msguniq msginit msgunfmt msgconv`. This list — not the POD — is
the contract; each name becomes a share-install wrapper. Note the POD synopsis in
`lib/Alien/gettext.pm` mentions `msgmerge`, which is **not** in `alien_bins`;
either the tool is added to the list or the POD example is corrected — they must
agree, and the list is the source of truth.

## Verification — both paths

`dzil test` covers only whichever path the local box lands on (a machine with
gettext installed never exercises the share build). Anything touching the alien
config runs both explicitly:

```bash
dzil test
env ALIEN_INSTALL_TYPE=share  dzil test    # forces the GNU download + build (needs network)
env ALIEN_INSTALL_TYPE=system dzil test    # forces the probe path; fails loudly with no system gettext
```

`t/load.t` only `use_ok`s the module — it does not prove either path works, so it
is not verification for a build change.
