# DBIx-QuickDB developer/agent notes

## Comments and documentation

Comments are for what the code cannot say. Most code needs none.

- **Only if it adds value.** Delete anything that restates the code
  (`# return 1`), and anything already said elsewhere. A comment that
  only paraphrases the line under it is noise.
- **As brief as the point allows.** `# Do X because Z breaks without X`
  is usually the whole comment. Prefer one line; two or three when the
  reason genuinely needs them. If a comment wants to be a paragraph,
  that is the signal to cut it or move it to POD.
- **Write the reason, not the story.** Why the code is this way, not
  the investigation that led there. That belongs in the commit
  message, which is where someone looks when they want the history.
- **No comment may reference another comment.** Each one stands alone.
  Nothing like "for the same reason as above" or "see the note below" —
  they are read with code between them, not as one essay.
- **`Agent Note:` prefix** for context aimed at a future agent rather
  than a human reader. Still brief.

Prefer POD on the sub over a comment block whenever you are explaining
what something is *for*. POD covers what it does, how to call it, and
its inputs and outputs. Keep implementation detail out of it, except
brief notes where a caller would be surprised — side effects
especially. Implementation reasoning stays in a short comment inside
the sub.

## Decision discussion mode

Any time one or more decisions are needed from the user — deferred
review findings, design questions, API-shape choices, anything an
agent cannot rule on itself — walk them in **discussion mode**:

- **One item per message.** Never advance until the user says "next"
  (or equivalent). The user may ask questions, request probes or code
  reading, or change direction mid-item; answer within the current
  item until told to move on.
- **Progress indicator first.** Every item starts with a header like
  `Item 3 of 10` so the user always knows position and remaining
  count. Follow-up answers within the same item repeat the indicator.
- **Grouping.** Items sharing one root cause may be presented
  together as a single combined item (say so, and count them
  accordingly, e.g. `Items 5+9+10 of 10`). Do not group items that
  merely resemble each other.
- **Format per item**, terse wording, bullet lists preferred over
  prose paragraphs:
  - What the issue is (one or two sentences).
  - Full context: where it lives (`file:line`), how it arises,
    measured behavior, prior rulings that bear on it.
  - Code examples where they clarify (current behavior, or the shapes
    a fix would take).
  - Options, when obvious ones exist, each with its cost/consequence.
  - A recommendation, with the reason.
- **Plain conversation, not a selector.** Never present the decision
  through a menu/choice UI; the user decides in free-form discussion.
- **Record the ruling** where the work is being tracked (the issue or
  analysis document the decisions belong to) before presenting the
  next item. Do not implement anything mid-walk unless the user says
  to; collect rulings and implement when asked.

## Running tests

ALWAYS set `AUTHOR_TESTING=1` when running tests in this repo, use `-j16`
concurrency, and wrap in a timeout so a hung server cannot stall a run
(the full suite finishes in ~5 minutes at `-j16`):

    timeout 600 env AUTHOR_TESTING=1 prove -Ilib -r t -j16

Before handing back anything that touches how modules are LOADED -- `@INC`,
`%INC`, `require`, re-exec, or a test that asserts on a module's path -- also
run the release path once:

    perl Makefile.PL && make && timeout 900 env AUTHOR_TESTING=1 make test

`prove -Ilib` puts `./lib` first in `@INC`; `make test` loads from `blib/lib`,
which is what CPAN clients, CPAN Testers and `dzil release` do. A test that
hardcodes `lib` passes the first and fails the second, so the dev command
structurally cannot see that class of bug. This has bitten once already: a test
asserting `abs_path('lib')` was green through nine review rounds and would have
failed every CPAN Testers report.

**Run the two paths one at a time, never concurrently.** Each fans out to
roughly `-j` × `QDB_INSTALL_JOBS` database servers, so two full suites at once
is ~128 servers, and that is what OOM'd this machine. Sequencing them is the
whole mitigation. On a loaded box lower the fan-out (`QDB_INSTALL_JOBS=2` with
`-j4` costs ~103s against ~46s at `-j16`).

**Data dirs live in `/tmp`, which is tmpfs -- RAM, deliberately, because it is
what makes the suite fast.** Two consequences:

- **Do not move `TMPDIR` off tmpfs.** Measured: on disk the suite went from
  ~103s to past a 900s timeout. Do not hammer the disk to save memory that is
  not actually scarce.
- **Do not wrap runs in a memory cgroup cap.** `MemoryMax` counts tmpfs pages,
  so it caps the tests' *storage*, not their processes. `MemoryMax=12G` was
  tried and the kernel OOM-killed `mysqld` mid-run; it presents as an ordinary
  test failure, and only `journalctl --user | grep oom-kill` identifies it.

**After any crashed or killed run, sweep the debris.** That is the real memory
sink: a run that dies never cleans up, and its data dirs stay resident in RAM
for every later run to work around. 644 abandoned dirs holding 19G were found
after one crash -- an otherwise-healthy suite peaks around 16G and returns
`/tmp` to a few hundred MB when it exits normally. Look for QuickDB fingerprints
(`server-exit-status`, `*.READY`, `my.cfg`, `data/`, `cmd-log-*`, `DB-QUICK*`)
before deleting, and check `df -h /tmp` when a run behaves strangely.

**Only whoever is making the change runs the suite.** Reviewers assume it
passes — the implementer verifies before handing work over. A reviewer who
believes a change breaks the suite reports that as a finding rather than
running it. Review rounds otherwise multiply full suites across agents, which
is how the machine got OOM'd.

If a run is killed part way, its watchers can be left holding live servers.
Signal the **watcher** (`kill -TERM <db-quick-watcher pid>`), not the server:
the watcher then stops the server and removes the data dir the normal way.
`ps -eo args | grep '^db-quick-watcher'` finds them -- note `pgrep -f` matches
its own command line.

Without `AUTHOR_TESTING` the suite only exercises the system-installed
database servers. With it, the test helpers also scan `~/dbs/*/bin` for
developer installs of MariaDB/MySQL/Percona/PostgreSQL and run every
applicable test once per install, each in an isolated subprocess with that
install's bin dir prepended to `$PATH`. Unix uses real forks; MSWin32 launches
a fresh Perl process because Test2 does not support Windows' thread-based
pseudo-fork. The scan is live: drop a new install under `~/dbs/<name>/bin` and
it is picked up automatically; delete one and it disappears. Nothing is
hardcoded.

Nothing in `lib/` knows about `~/dbs` — it is a developer-only convention that
must never leak into shipped code.

Concurrency math on Unix: each test file runs up to `QDB_INSTALL_JOBS`
(default 4) install subprocesses at once, and `prove -j16` runs 16 files at
once, so the worst-case fan-out is ~64 install children (each with its own db
server and watcher). That is measured-fine on the primary dev box (~2.5 min
suite); on a smaller machine lower one or both knobs (e.g.
`QDB_INSTALL_JOBS=2` and/or `-j8`) — System V IPC (PostgreSQL semaphores) and
RAM are the limits that bite first. The MSWin32 external-process path runs a
test file's installs sequentially and ignores `QDB_INSTALL_JOBS`; `prove`
still runs separate test files concurrently.

To exercise the MSWin32 process path on Unix, use the test-only
`QDB_INSTALL_NO_FORK` switch. This is a slower verification run, not the
routine suite command:

    timeout 600 env AUTHOR_TESTING=1 QDB_INSTALL_NO_FORK=1 prove -Ilib -r t -j16

## Editing the per-install test machinery

The parent process of a per-install test file must NEVER load `DBIx::QuickDB`,
its drivers, or `Test2::Tools::QuickDB`. The drivers capture `$PATH` at load
time (BEGIN blocks in the PostgreSQL driver) and in private lexical caches
(`%PROVIDER_CACHE` in the MySQL driver) that a forked child inherits, which
silently defeats the per-install `$PATH`. All DBIx::QuickDB code loads inside
the isolated children only, after their `$PATH` is set. Read the comments in
`t/lib/QDB/Installs.pm` before touching the test wrappers.
