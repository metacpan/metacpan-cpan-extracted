# Alien::gettext House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; when uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code or
   formatting. Match existing style.
3. **Read before you write** — Before changing the build, read `dist.ini` and know that
   the `alienfile`/`Build.PL` are *generated* from it, not checked in.
4. **Fail loud** — "Done" is wrong if anything was skipped silently; "tests pass" is
   wrong if a path was never exercised. Surface uncertainty, don't hide it.

## Delegation — the lock

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch
  behavior-relevant code yourself — delegate to `alien-gettext-worker`. Your lane:
  coordinate, inspect, plan, review diffs, run tests, manage git, edit non-behavioral
  docs. When in doubt, delegate. Why: only the `alien-gettext-*` agents get their skills
  force-loaded via `briefing.skills`; you get no briefing and would touch internals with
  too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug the alien config, `lib/Alien/`, `t/`, POD, tool set | `alien-gettext-worker` (default) |
  | Pre-release audit before a CPAN release | `alien-gettext-release-checker` |

- **You cannot spawn subagents** (you ARE an `alien-gettext-*` agent): the lock does not
  apply — implement, refactor, debug and test per these rules.

Behavior-relevant = the `alien_repo`/`alien_bins` (and any `alien_*`) config in
`dist.ini`, the install-time probe and share build, the tool set, `lib/Alien/gettext.pm`,
and `t/`. Pure prose docs and changelog notes are not.

## Coordination — karr board (always in scope)

`karr` is always in scope — don't invoke the `kanban-issues-karr-cli` skill first, just
use it. Git-native kanban; state lives in `refs/karr/*`; this repo has its own board.

- `karr board` / `karr list --compact` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME` — to review

**Serialize board mutations when fanning out.** Keep implementation parallel if you like,
but collect results and then loop `karr move`/`handoff`/`sync` sequentially — N landing at
once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any upload to CPAN are
STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan or STATUS
note lists "release" as the next step. For anything heading toward release: stop and ask.

**CPAN state is never a blocker and never a ticket.** The published-on-CPAN version being
behind the local tree is expected — nothing waits on it and everything is released
together. Do not open a ticket, raise a finding, or block work on "not yet on CPAN".

## Project-specific hazards

- **The build is generated from `dist.ini`.** There is no `alienfile`/`Build.PL` to edit
  in the tree; a change to the build is a change to `alien_repo` / `alien_bins` / other
  `alien_*` keys. Editing a non-existent root build file, or expecting `Alien::Build`
  `alienfile` semantics, is a category error — this dist is on the classic
  `Alien::Base::ModuleBuild` path.
- **The share build downloads from `ftp.gnu.org` at install time** — no bundled tarball,
  so it needs the network and tracks the newest GNU release (no version floor). A single
  unforced `dzil test` proves only the path this box lands on; run the forced
  `ALIEN_INSTALL_TYPE=share` / `=system` pair before calling a build change verified.

## Perl / Alien specifics — reference, don't restate

House Perl conventions, the `[@Author::GETTY]`/`dist.ini` bundle, Alien probe/share
mechanics and this distribution's tool set live in the briefed skills (`getty-perl-core`,
`getty-perl-release-author-getty`, `perl-release-dist-ini`, `perl-alien`,
`alien-gettext-core`). Do not duplicate that content here.
