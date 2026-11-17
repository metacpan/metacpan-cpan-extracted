---
name: alien-gettext-core
description: Use when working on the Alien::gettext distribution — its [@Author::GETTY] alien config (the root alienfile), the system-vs-share probe, the GNU-FTP source download, the msgfmt/xgettext tool set it exposes, or the bin_dir contract its consumers rely on.
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
POD, nothing else. Every decision lives in the alienfile, not in Perl. Do not add methods there to "help" consumers — the contract is `bin_dir`
and the tools on it.

The lowercase module name (`Alien::gettext`, not `Alien::Gettext`) is
intentional and matches the tool-Alien convention — do not "correct" it.

## The build is the root alienfile

The build lives in the root `alienfile` (Alien::Build). `dist.ini` only says
`alien_build = 1`; `[@Author::GETTY]` then generates a `Makefile.PL` driven by
`Alien::Build::MM` at `dzil build`. The tool list is `@bins` in the alienfile;
`t/bin.t` runs `msgfmt` and `xgettext` from it.

## Two install paths

- **system** — the `probe` runs `msgfmt --version`; any `GNU gettext-tools` on `PATH`
  satisfies it (no version floor). Nothing is built; the tools resolve from `PATH` and
  `bin_dir` is empty.
- **share** — no system gettext (or `ALIEN_INSTALL_TYPE=share`): the newest
  `gettext-<version>.tar.gz` listed at `https://ftp.gnu.org/gnu/gettext/` is downloaded
  over https, then `configure --disable-shared && make && make install` (static internal
  libraries, so the tools run without a library search path). The last build command
  fails loudly if any tool in `@bins` was not built. The tools land in the share dir's
  `bin/`, which is what `bin_dir` returns.

**The share build needs the network** — no bundled tarball. No version is pinned and
there is no digest (GNU publishes none next to the tarball); https is the integrity
guard. A GNU mirror outage or a changed tarball name breaks the share build.

## `@bins` is the authoritative tool set

The eleven tools: `msgfmt msgfilter msgcmp msgcomm msgmerge xgettext msgexec msguniq
msginit msgunfmt msgconv`. The POD must agree with the list.

## Verification — both paths

`dzil test` covers only whichever path the local box lands on (a machine with
gettext installed never exercises the share build). Anything touching the alien
config runs both explicitly:

```bash
dzil test
env ALIEN_INSTALL_TYPE=share  dzil test    # forces the GNU download + build (needs network)
env ALIEN_INSTALL_TYPE=system dzil test    # forces the probe path; fails loudly with no system gettext
```

`t/load.t` only `use_ok`s the module; `t/bin.t` runs `msgfmt`/`xgettext --version` through
`bin_dir` and is the real check.
