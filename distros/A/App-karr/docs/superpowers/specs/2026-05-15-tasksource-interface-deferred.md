# Design: TaskSource Interface — Deferred

## Status

Deferred

## Datum

2026-05-15

## Context

Candidate 5 proposed introducing a `TaskSource` interface with adapters (`RefTaskSource`, `FileTaskSource`) to make commands agnostic to storage backend.

## Decision

**Defer this refactoring.** The seam does not yet exist in practice.

### Reasoning

Currently there is only one adapter: the ref-based storage via `BoardStore`. Commands access tasks via `$store->load_tasks()`, `$store->save_task($task)`, etc. — which is already an interface in the meaningful sense (callers don't know the internal representation).

"One adapter = hypothetical seam. Two adapters = real seam." — LANGUAGE.md

Adding a formal `TaskSource` role now would be speculative abstraction. It adds indirection without immediate benefit. If a second adapter becomes necessary (e.g., direct `.md` file storage without Git, or an in-memory store for testing), the interface can be extracted then.

### When to revisit

- Evidence of multiple storage backends actually in use
- Commands needing to be testable without a Git repository (would justify `InMemoryTaskSource`)
- A concrete use case for `FileTaskSource` (e.g., importing from kanban-md)

### Files Affected

None — no changes to existing code.

### Task closed as "not now"