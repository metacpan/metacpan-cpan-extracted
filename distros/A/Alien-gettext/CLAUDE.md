# Alien::gettext

Provides the [GNU gettext](https://www.gnu.org/software/gettext/) command-line utilities
(`msgfmt`, `xgettext`, …) to CPAN via [Alien::Base](https://metacpan.org/pod/Alien::Base).
This is a **tools Alien**: consumers reach the utilities through
`Alien::gettext->bin_dir` (prepended to `PATH`) and shell out to them — there is no
linkable library, no `cflags`/`libs`, no XS or FFI.

Two install paths, decided at install time: a **system** gettext found by the probe (no
version floor), or a **share** build that downloads the newest source tarball from
`ftp.gnu.org` and compiles it (needs network — no bundled tarball). Mechanism, the tool
set, and the generated-build details: skill `alien-gettext-core`.

## Layout

| Path | Holds |
|---|---|
| `dist.ini` | every build decision: `[@Author::GETTY]` with `alien_repo` + `alien_bins` |
| `lib/Alien/gettext.pm` | `use parent 'Alien::Base'` + POD, no logic |
| `t/load.t` | `use_ok` of the module (does not exercise either install path) |

There is **no `alienfile` and no `Build.PL` in the tree** — the `[@Author::GETTY]` bundle
generates the build from `dist.ini` at `dzil build`. `dzil test` covers whichever path
the box lands on, so anything touching the build runs both explicitly:

```bash
env ALIEN_INSTALL_TYPE=share  dzil test
env ALIEN_INSTALL_TYPE=system dzil test
```

## Delegation

Delegate behavior-relevant work to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/alien-gettext-rules.md`.

| Task | Agent |
|---|---|
| Alien config in `dist.ini`, the probe/share build, tool set, `lib/Alien/`, `t/`, POD | `alien-gettext-worker` (default) |
| Pre-release audit before a CPAN release | `alien-gettext-release-checker` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Tickets live on the repo's `karr` board.

## Skills

`alien-gettext-core` is project-owned; every other skill under `.claude/skills/` is a
hardlink into the shared library — `manage-skills sync` re-establishes the links after a
fresh clone, and a hardlinked `SKILL.md` is edited in place, never with `Edit`/`Write`.

| Skill | Covers |
|---|---|
| `alien-gettext-core` | this distribution: the two paths, the generated build, the tool set, the `bin_dir` contract |
| `perl-alien` | Alien itself: probe/system/share, `install_prop` vs `runtime_prop`, `Test::Alien` |
| `getty-perl-core` | house Perl conventions |
| `getty-perl-release-author-getty`, `perl-release-dist-ini` | the `[@Author::GETTY]` bundle and `dist.ini` |
| `kanban-issues-karr-cli` | the karr board |

`perl-xs` is deliberately **not** linked: this distribution provides executables through
`bin_dir` and has no Perl/C boundary — no library, no XS, no FFI. Link it only if this
dist ever grows an XS consumer surface.
