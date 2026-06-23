---
name: dbio-moo-moose
description: "Minimal reference for DBIO's optional Moo/Moose bridges and the Moo/Moose code generators. Use only when wiring DBIO::Moo/DBIO::Moose into a result class, or when emitting Moo/Moose result classes via DBIO::Generate."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO Moo / Moose — Minimal

DBIO core is **CAG, never Moo/Moose** (see [[dbio-perl-class-patterns]]). Moo/Moose
appear in exactly two narrow places, both optional. This skill is deliberately
minimal — you rarely need it.

## 1. Bridges — using Moo/Moose in a *result* class

`DBIO::Moo` / `DBIO::Moose` let a **result class** declare `has` attributes
alongside DBIO columns. They are thin `import`-time bridges over `DBIO::Core`.

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moo;     # activates Moo + extends DBIO::Core + FOREIGNBUILDARGS
use DBIO::Cake;    # optional DDL sugar

table 'artists';
col id   => serial;
col name => varchar(100);
primary_key 'id';

has score => (is => 'rw', lazy => 1, default => sub { 0 });
```

Two rules that matter — everything else is detail in `lib/DBIO/Moo.pm` POD:

- **`FOREIGNBUILDARGS` is mandatory.** Moo/Moose's generated `new()` does NOT call
  the non-Moo parent (`DBIO::Row::new`) without it. The bridge installs one that
  forwards only DBIO-known keys (columns, relationships, `-`-prefixed) so unknown
  Moo attributes don't make `store_column` die.
- **Defaults MUST be `lazy => 1`.** Rows from the DB are built via
  `inflate_result` (blesses a hash, `new()` never runs), so non-lazy defaults are
  never applied. `lazy => 1` computes on first access → works on both paths.
  `is => 'lazy'` (builder) is inherently fine.

`DBIO::Moose` is the same, over `Moose` + `MooseX::NonMoose`, and must register
`FOREIGNBUILDARGS` via the metaclass so `make_immutable`'s inlined constructor
sees it.

## 2. Generators — emitting Moo/Moose result classes

`DBIO::Generate::Style::Moo` / `::Moose` are **text emitters** for `DBIO::Generate`.
Key fact: **they write `use Moo;` as a string — they do NOT load Moo at generation
time.** Moo/Moose is only needed if you later load the *generated* class.

Emitted Moo header shape:

```perl
use Moo;
use MooX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIO::Core';
```

Same `emit($class, $spec)` contract as `DBIO::Generate::Style::Vanilla`. Pick the
style via the generator's style arg; keep the emitter free of a runtime Moo dep.

## Boundaries

- ❌ Don't use Moo/Moose for core/storage/broker classes → CAG, [[dbio-perl-class-patterns]].
- ✅ Cpanfile: Moo/Moose/MooX::NonMoose/MooseX::* are `suggests`, never `requires`.
- Pure-Perl/style rules still apply → [[dbio-perl-syntax]].

Source of truth: `lib/DBIO/Moo.pm`, `lib/DBIO/Moose.pm`,
`lib/DBIO/Generate/Style/Moo.pm`, `lib/DBIO/Generate/Style/Moose.pm`.
