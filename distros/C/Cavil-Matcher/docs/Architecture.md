# Cavil::Matcher Architecture

This document explains how the matcher works and, more importantly, *why* it is built the way it is. It is
meant to be read start to finish by someone new to the project, before they open the source. It talks about
concepts, not functions or line numbers.

## Why this exists

Cavil reviews the licensing of software by scanning source code for the text of known licenses. The scanning
is done by matching every file against a large, ever-growing collection of *patterns* — normalized fragments
of license text. The previous engine did this well and fast, and this one keeps its core idea unchanged. What
it changes is everything around that core, because the old design had three operational problems that grow
worse over time:

- **Every change rebuilt the world.** Adding or editing a single pattern threw away the entire compiled
  collection, and the next scan had to recompile all of it from scratch. Patterns are added every day, so
  this cost was paid constantly.
- **Every worker kept its own copy.** Cavil scans in parallel with many worker processes, and each one loaded
  its own full copy of the compiled patterns into private memory. The more patterns, the more this multiplied.
- **The on-disk form was fragile.** The compiled file had no header, version, or checksum; it was trusted
  blindly. A format change or a truncated file could be silently misread.

The goal of this engine is to fix those three things — cheap incremental updates, one shared copy per machine,
and a safe, versioned on-disk format — while keeping matching itself bit-for-bit identical, so switching to it
requires no re-processing of existing data.

## The Perl/native split, and why

Only one thing in a license scan is genuinely performance-critical: walking every word of every file through
the pattern collection. That inner loop, and the hashing that feeds it, is where nearly all the time goes, and
it is written in a small, carefully-frozen C++ core.

Everything else — deciding which patterns are active, recording that a pattern was removed, choosing when to
compact, reading and writing the little file that describes the collection — happens rarely and on small data.
All of that is plain Perl, because that is where the team is strongest, because it is where a newcomer can
follow the logic without a debugger, and because none of it is on the hot path, so nothing is lost by keeping
it in Perl. The native side is deliberately dumb: it is handed a list of things to search and simply searches
them. Every *decision* is made in Perl.

The native core is C++ rather than a rewrite in another language for a simple reason: the matching algorithm
and its hashing are already proven on a legal tool, where a subtle behavioural change is the worst kind of
bug. Reusing that code unchanged is the safest possible choice, so the core stays in the language it is
already written in. The genuinely new native code — the reader for the on-disk format — is small and only ever
reads files this same software wrote, and it validates everything it reads, which removes the one real
weakness the old format had.

## How matching works

A pattern is neither a regular expression nor a literal string. Before anything is compared, both the patterns
and the files being scanned are put through the same normalization: text is lower-cased and split into words,
punctuation and common comment or markup noise is discarded, and each surviving word is reduced to a number.
Only those numbers are ever compared. This is what lets a match survive reformatting, rewrapping, and
different comment styles — the layout simply disappears during normalization.

One wildcard exists. A pattern may say "skip one to N words here" (at least one word, at most N - it does not
match a zero-word gap), which lets a single pattern absorb the parts of a license that legitimately vary, such
as a copyright holder or a year. A pattern must begin and end on real words, never on a skip, so that every
match is anchored at both ends.

All of a collection's patterns are arranged into a shared prefix tree keyed on those word-numbers. Patterns
that start with the same words share the same branch and only diverge where the words diverge. Scanning a file
means walking its words down this tree and noting wherever a complete pattern is reached. The important
consequence is that scanning speed barely depends on how many patterns there are: shared beginnings are walked
once, and only branches that actually occur in the file are ever explored.

When several patterns match overlapping parts of a file, the longest match wins; an exact tie is resolved in
favour of the higher pattern identifier, on the assumption that newer patterns are the more specific ones.
This "higher id means newer" rule holds because identifiers are assigned monotonically as patterns are
created (Cavil uses a database sequence), which is a required invariant of any caller: the resolver only ever
sees identifiers, not creation timestamps or segment order, so if identifiers were reused or assigned
non-monotonically the tie-break would no longer prefer the genuinely newer pattern. This resolution is a pure
function of the set of raw matches, which is what makes the segmented design below safe: it does not matter
how the raw matches were gathered, only what they are.

## Segments, tombstones, and the manifest

Instead of one monolithic compiled file, a collection is stored as a set of **segments**. A segment is a
compiled prefix tree for one batch of patterns, and once written it is never modified. Alongside the segments
lives a small, human-readable **manifest**: it lists the active segments, the pattern identifiers that have
been removed (**tombstones**), and a **generation** number that increases on every change.

This is the whole point of the design, and it follows the model search engines have used for decades:

- **Adding patterns compiles one small new segment** and appends it to the manifest. The existing segments are
  not touched. Absorbing a new pattern is therefore cheap and local, no matter how large the collection has
  grown.
- **Removing a pattern writes a tombstone** in the manifest and nothing else. At scan time, matches belonging
  to a tombstoned pattern are dropped before overlap resolution — so removing a pattern correctly reveals any
  smaller matches it had been hiding, exactly as if it had never existed. No segment is recompiled.
- **A query searches all active segments at once**, gathers their matches, discards the tombstoned ones, and
  then applies the ordinary overlap resolution to the combined set. The result is identical to what a single
  combined collection would have produced.

Because deltas and tombstones accumulate, an occasional **compaction** folds the current pattern set back into
a single fresh base segment and clears the tombstones. This is the one operation that reads the full pattern
set from the database — Cavil's source of truth — and it is rare and runs in the background, off the scanning
path. It exists only to keep the number of segments and the length of the tombstone list bounded over time.

## Shared memory and reproducibility

Segments are mapped into memory read-only and searched in place, rather than being read and rebuilt in each
worker's private memory. When many workers on the same machine use the same collection, the operating system
keeps a single physical copy of each segment and shares it across all of them. The practical effect is
dramatic: attaching a large index to dozens of workers costs kilobytes of private memory per worker instead of
a full duplicate each. This is what lifts the memory ceiling that limited the previous design.

The generation number in the manifest gives reproducibility. A scan pins the generation it ran against, and a
report can record it, so re-running an old report can use exactly the same patterns it originally saw. Updates
are published atomically — a new segment and an updated manifest are written to the side and swapped into place
in one step — so a reader never observes a half-written collection.

## The on-disk format

Each segment file begins with a header identifying it, stating its format version, and carrying a checksum of
everything that follows. When a segment is opened, all of this is verified, and every internal reference in the
file is bounds-checked before it is ever used. A file that is truncated, corrupted, of the wrong version, or
simply not a segment at all is rejected cleanly; it is never partially trusted and never able to send the
scanner off the end of the data. The manifest additionally records a checksum for each segment, so a segment
that has been damaged or swapped underneath a running system is detected and skipped rather than used. This
validated, versioned format is the deliberate replacement for the old engine's headerless, unchecked file.

## Robustness

Scanning a whole distribution means feeding the matcher every kind of file that exists, including binaries,
deliberately malformed samples that security tools ship as test data, files full of null bytes, and enormous
single-line files with no structure at all. The matcher treats all of this as ordinary input: it reads files
in bounded chunks, stops cleanly at the end of usable data, and bounds the amount of a file it holds in memory
at once. Unreadable paths and missing files produce empty results rather than errors. The guiding rule is
simple and absolute — no input, however hostile or malformed, may crash the scan.

## What deliberately stays the same

Some things are intentionally unchanged from the previous engine, because they were already right:

- **The database remains the source of truth** for patterns. The compiled segments are a derived cache that
  can always be rebuilt from it.
- **The prefix tree remains the authoritative matcher.** Similarity scoring and closest-match are useful for
  suggestions, never for the authoritative yes/no of whether a license is present.
- **The tokenizer and the hashing are frozen** and produce exactly the same numbers as before. Because the
  stored checksums of patterns and text fragments depend on those numbers, keeping them identical means the
  new engine can replace the old one without recomputing or migrating any stored data.

## Scaling characteristics and limits

The two costs that grew worst in the old design are gone: a change no longer recompiles the whole collection,
and workers no longer each hold a private copy of it. Matching speed was already largely independent of the
number of patterns, and remains so.

The new costs to watch are different and milder. Every active segment adds a little fixed overhead to each
scan, so a collection that accumulates a great many un-compacted delta segments will slow down gradually;
compaction is the remedy, and how often to run it is the main tuning knob. A single pathologically long
pattern still widens the scanning window for every file, and patterns built from many skips still make the
tree branch more, so the *shape* of new patterns is worth watching, not only their number.

## How to work on it

The behaviour of the matcher is pinned by a self-contained test suite that needs no external engine: it
asserts exact matches on a set of curated license fixtures, exercises the segment lifecycle (incremental add,
tombstone, compaction, atomic update), checks that a damaged segment or manifest is handled gracefully, and
throws a barrage of hostile inputs at the scanner to confirm it never crashes. That suite is the contract; if
you change behaviour, it should tell you.

While this engine and its predecessor coexist, a separate developer-only set of tests cross-checks that the
two produce byte-for-byte identical results across the whole real pattern corpus and a large sample of real
snippets. Those tests are how equivalence is proven during the transition; once the old engine is retired they
can simply be deleted, and the self-contained suite stands on its own.

A change to the pattern set flows through the system in the obvious way: adding patterns writes a new segment,
removing one writes a tombstone, and compaction periodically rewrites a single clean base — none of which
disturbs the data an in-flight scan is already using.
