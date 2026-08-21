---
name: getty-perl-core
description: "Load on any Perl edit in a Getty project — module loading, attributes, errors, strings, control flow, cpanfile, Changes, and the house choices that differ from Perl defaults."
---

# Perl Core — Getty House Rules

These rules override defaults. They are non-negotiable in Getty projects.
Object-system specifics live in `getty-perl-moo` / `getty-perl-moose`.

## Module loading

- **`use Module;` at the top.** Always. Every dependency loads at compile time.
- **`require` is forbidden as a "lazy optimization".** Never use it to shave startup. `require Foo;` inside a method body → hoist it to a top-level `use`.
- **`require` only for true runtime plugin loading** — the class comes from config/DB at runtime (`Module::Runtime::use_module($class_from_db)`). Known at write-time → `use` it.
- **`require` + `->new` in a controller action** is a red flag. Hoist to `use`.

## strict and warnings

Both are active in **every** file, without exception. How they get there differs:

- **Scripts, tests, plain modules:** `use strict; use warnings;` explicitly.
- **Classes:** `Moo`, `Moose`, `Catalyst` and anything derived from them enable both on import — do not repeat them there.

The rule is "always on", never "leave them out". Omitting them from a class is correct only because the object system already did it.

## Object system

- **One object system per distribution.** Pick Moo or Moose and use it everywhere; mixing is for boundaries a framework forces (e.g. RapidApp), not a choice.
- **`is => 'ro'` is the default.** `rw` is the exception and needs a reason.
- **`lazy_build => 1` + `sub _build_foo`** over `default => sub { ... }` for anything non-trivial.
- **`weak_ref => 1`** on attributes holding a reference back to a parent/owner — standard for nested object graphs, prevents circular refs.
- **`namespace::autoclean`** on every class file. Classes extending DBIx::Class (`MooseX::NonMoose`) use **`MooseX::MarkAsMethods autoclean => 1`** instead.
- **`no Moose;` + `__PACKAGE__->meta->make_immutable;`** at the bottom of every Moose class.
- **Types:** the tendency is to type what arrives from outside — Moose's own constraints where Moose is already there, `Types::Standard` where it is not. Not every distribution needs a type system, and none needs one for every field: `getty-perl-typing`.

## Singletons

- **`->instance`** for `MooseX::Singleton` / `MooX::Singleton` classes. Never `->new` on a singleton.
- **`->new`** for everything else.

## Subroutines

- **`my ( $self, $x ) = @_;`** as the first line — explicit destructure, spaces inside the parens. Never `my $self = shift;` as argument unpacking.
- **One-liners skip unpacking** and use `shift->` or `$_[0]->`: `sub trace { shift->_logger->trace(@_) }`. This is the one place `shift` is right.
- **A builder that ignores `$self` fits on one line:** `sub _build_readonly { 0 }`.
- **`_` prefix marks private** subs and attributes. Builders for private attributes double up: `sub _build__mp`.

### Methods, not bare subs

- **In a class, every helper is a method on `$self`** — not `sub _foo {...}` invoked as `_foo($self->config, $x)`.
- **Per-process caches go on the singleton as an attribute** (`has _cache => ( is => 'ro', default => sub { {} } )`), not a `my %CACHE` package variable.
- **No package-level state** unless it is a true constant (an `%ENGINE_CLASS` lookup table counts; a per-call cache does not).
- Bare subs are fine in **non-class utility modules** imported as functions. Once a file says `use Moose`/`use Moo`, every `sub` is a method.

Why: bare subs hide what the call needs, can't be overridden or mocked, and force every caller to thread state by hand.

## Errors

- **`croak`, never `die`.** Errors report the caller's line, not ours.
- **Import it:** `use Carp qw( croak );` and call `croak(...)` bare.
- **Name the origin in the message:** `croak __PACKAGE__."->state too many args"` — or whatever identifies the operation in that module's DSL.

## Strings

- **Concatenate, do not interpolate:** `'Adding '.$f.' with '.$length.' bytes'`. Interpolate only where concatenation would be unreadable.
- **Single quotes by default.** `'...'` and `"..."` are genuinely different in Perl — `"` interpolates and processes escapes, `'` does not. Reach for `"` when you need that, not by habit.
- **Import lists as `qw( croak confess )`** — spaces inside the parens. Never rely on default exports.

## Control flow

- **Postfix `if`/`unless`** for guards and short conditions: `croak(...) if $self->readonly;`
- **`unless $x`** instead of `if !$x`.
- **Guard clauses return bare:** `return unless $res->is_success;` — not `return undef;`.
- **Nested ternaries** for a return that picks between expressions, instead of an if/elsif chain.

## Data

- **`{ %hash }` and `\%hash` are different operations, not two styles.** `{ %h }` builds a new anonymous copy; `\%h` references the existing hash. Return a copy when the caller must not mutate your state; return the reference when sharing is the point. Choose deliberately.
- **`Path::Tiny`** for every file operation — not `File::Spec`, not bare `open`. `path(...)->child(...)->slurp_utf8`.
- **`JSON::MaybeXS`** always — never `JSON::PP`, `JSON::XS`, `Cpanel::JSON::XS` directly. Encoders get `canonical => 1, convert_blessed => 1`.
- **Every serialiser is deterministic.** MessagePack `->canonical`, DBIC `serializer_options => { canonical => 1 }`. Same rule, every format.
- **Booleans: `JSON->true` / `JSON->false`.** `use JSON::MaybeXS;` covers codec and booleans.
- `$YAML::XS::Boolean = 'JSON::PP'` is one of YAML::XS's fixed mode names, not a module choice — leave it alone.
- **Align `=>` in multi-line hash literals** when keys are of similar length.
- **Optional pairs inline:** `$cond ? ( experimental => 1 ) : (),`

## Configuration

Config comes from environment variables prefixed with the project name
(`$ENV{MYPROJECT_TIME_ZONE}`), each with a default in code. Where many
attributes share that shape, write a generator that wraps `has` rather than
repeating the declaration.

## DBIC-ish result classes

- Column defs via **`DBIx::Class::Candy`** or **`DBIO::Candy`** — `primary_column` / `column` macros, not `__PACKAGE__->add_column(...)`.
- **`keep_storage_value => 1`** on enum and integer columns that shouldn't be inflated/deflated.
- **`\'NOW()'`** (literal scalar ref) for DB-side timestamp defaults.

## Style, comments, structure

- **2-space indentation.** Not 4. Not tabs. Every Getty Perl file.
- **No trailing commas** at the end of multi-line lists (unlike Python).
- **Section long files with a figlet banner** as a comment block. Pick from `standard`, `slant`, `small`, `banner`. Where figlet is unavailable or the file is short, a `#### <Name>` rule does the job.
- **Commented-out debug lines stay** (`#use DDP; p($res);`). They mark where debugging was needed before — deleting them as dead code removes a warning sign, and sometimes the precaution it guards.

## cpanfile

- **A `cpanfile` carries the requirements** — that is the file, not `dist.ini` prereq blocks.
- **`requires 'Module::Name';`** — the version argument is optional, omit it when unpinned. Never write `'0'`.
- **A version means "or higher".** `requires 'Foo', '5.0';` already accepts 5.1 — never write `'>= 5.0'`.
- **Alphabetical order**, phase blocks (`on test => sub {...}`) at the end.

### Getty-authored dependencies — CRITICAL

Getty's `dist.ini` uses `[@Author::GETTY]`, which sets `$VERSION` in the repo to the **next, unreleased** version (`0.402` while CPAN is at `0.401`). The repo is ALWAYS one ahead of CPAN.

1. **NEVER copy a version number from a Getty repo into a `cpanfile`.** It is not released, `cpanm` cannot install it, the build breaks.
2. **Check `cpanm --info Module::Name`** for the actual released version.
3. **Pin every Getty-authored distribution to the latest release.** Not stale, not omitted — current.
4. **Re-check on upgrade.**

```bash
cpanm --info Module::Name | tail -1
# → GETTY/Module-Name-1.234.tar.gz  ← pin to 1.234
```

Getty-authored (non-exhaustive): `Langertha`, `IO::K8s`, `Kubernetes::REST`, `WWW::Crawl4AI`, `Net::Async::Crawl4AI`, `Net::Async::WebSearch`, `Catalyst::Plugin::ChainedURI`, `Locale::Simple`, `DBIO::*`, `WWW::Zitadel`, `WWW::PayPal`, `WWW::Chain`.

## Changelog (the Changes file)

Every distribution ships a `Changes` file with a `{{$NEXT}}` token at the top (Dist::Zilla's `[NextRelease]` fills it at release time).

- **Add a bullet under `{{$NEXT}}` in the SAME commit as any user-facing change** — new bindings, behaviour changes, bug fixes, deprecations. If a CPAN consumer would notice, it belongs there.
- **Match the existing style:** two-space indent, `  - ` bullets, wrap near 78 columns, present-tense imperative ("New binding X", "Fix Y on macOS").
- **Skip pure dev-tooling noise** — skill hardlinks, editor config, internal CI refactors. A CI fix that unbreaks the build for everyone IS worth a line.
- **Never hand-edit the version line or timestamp** — `[NextRelease]` owns those.

## Forbidden

❌ `require Foo` inside a method to "speed up startup" · ❌ a Getty repo's `$VERSION` as a cpanfile requirement · ❌ `'0'` or `'>= x'` as a version argument · ❌ `default => sub {...}` for a non-trivial attribute default · ❌ 4-space indent · ❌ `File::Spec` in new code · ❌ `JSON::PP::true` / `JSON::PP::false` as barewords · ❌ `Data::Dumper` in shipped code (use `DDP` / `Data::Printer` for debug, strip before commit) · ❌ `die` where `croak` belongs

## When in doubt

Grep hand-written Getty code for how the pattern is used there — the reference is an older repo with no AI commits in its history. Newer repos may show an agent's guess rather than the house rule.
