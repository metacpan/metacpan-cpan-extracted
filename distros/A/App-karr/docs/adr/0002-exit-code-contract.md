# 2. Exit-code contract: 0 / 1 / 2

Date: 2026-07-02

## Status

Accepted

## Context

karr's primary callers are agents scripting the CLI, for whom `$?` is API.
Historically three regimes coexisted by accident: uncaught `die` yielded 255
(most not-found paths), the archive batch loop deliberately exited 1
(kanban-md `runBatch` parity), and usage-type rejections (unknown command,
surplus positionals) surfaced as 2, unknown options as 1. Nothing was
decided; scripts could not distinguish "you called this wrong" from "the
operation failed".

kanban-md itself (cobra) exits 1 for everything, so strict reference parity
was a real alternative.

## Decision

karr commits to the Unix convention:

- **0** — success (including no-ops like re-archiving an archived task)
- **1** — runtime failure: task not found, partial batch failure, Git/sync
  errors, board missing
- **2** — usage error: unknown command, unknown option, surplus or missing
  positional arguments, invalid option values

A central handler at the `bin/karr` entry point catches uncaught exceptions
and exits 1 (message on STDERR), so plain `die "...\n"` in commands keeps
working but never leaks 255 again. Usage-error paths exit 2 explicitly.

This deliberately deviates from kanban-md's all-1 convention: the 1-vs-2
distinction is what makes misuse detectable for scripting agents, and 0/1/2
is the established Unix idiom.

## Consequences

- The exit-code table is documented in the karr POD as a contract.
- Existing tests pinning 255 (t/41 not-found matrix, parts of t/43/t/45/t/46)
  encode the old accident and are updated deliberately with this change.
- Batch semantics stay: partial success is committed, the exit code reports
  the failure (1).
- Any future error path must map to this table; new codes need a new ADR.
