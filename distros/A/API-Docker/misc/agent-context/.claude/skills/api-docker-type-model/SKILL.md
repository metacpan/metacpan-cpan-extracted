---
name: api-docker-type-model
description: "Use when working on API::Docker's typed object model — a class under API::Docker::Type::*, the API::Docker::Type DSL, maint/spec-to-type.pl, maint/spec-drift-check.pl, or anything under spec/. Also when a type class is wrong, out of date or missing, when a field's Perl name or =attr prose needs changing, when adding classes for a newer swagger, or when a drift-check or --verify run reports a difference."
---

# API::Docker::Type — the generated model over the Docker Engine API

Every class under `API::Docker::Type::*` mirrors one `definitions:` entry in
Docker's swagger. They are **generated** by `maint/spec-to-type.pl` out of
`spec/`, and `maint/spec-drift-check.pl` is what keeps them honest.

## The two rules that override everything else

**Never hand-edit a file under `lib/API/Docker/Type/`.** Not one character,
not a typo, not a comma. `t/spec_to_type.t` runs the generator and asserts
that every class is byte-identical to what it emits — a hand edit turns the
suite red, and the edit is lost the moment anyone regenerates. Change the
generator or its data files instead; the next section says which.

**The generator only ever creates.** It writes a file that does not exist and
refuses to overwrite one that does. There is no `--force` and no bulk
refresh, and the refusal is enforced against relative paths, absolute paths,
`maint/../lib`, symlinks and subdirectories. When a newer spec lands, the
drift checker reports the difference and a human decides field by field. A
generated class is one that someone has since read, corrected and
documented; a re-run would throw that away silently.

## Where a change belongs

| What you want to change | Where it goes |
|---|---|
| The prose of an `=attr`, a `# ABSTRACT`, a DESCRIPTION | `maint/spec-to-type-prose.yaml` |
| The Perl spelling of a field | `maint/spec-to-type-names.yaml` |
| The class name of an inline object | `inline_class_names` in `maint/spec-drift-exceptions.yaml` |
| A deliberate deviation from the spec | the other keys of that same exceptions file |
| How a swagger shape becomes a type | `maint/spec-common.pl` (shared by both scripts) |
| How a class is rendered | `maint/spec-to-type.pl` |
| What an attribute *does* at runtime | `lib/API/Docker/Type.pm`, `lib/API/Docker/Role/Type.pm` |

After any of these, `perl maint/spec-to-type.pl --verify DIR` must again say
the diff is empty for every class.

## What a generated class looks like

```perl
package API::Docker::Type::HostConfig;
# ABSTRACT: Container configuration that depends on the host
our $VERSION = '0.004';
use API::Docker::Type;

docker_extends 'Resources';

docker binds => [Str];

=attr binds

A list of volume bindings for this container. Serialised as C<Binds>.

=cut

docker port_bindings => { Str, ['PortBinding'] }, since => '1.41';
```

Every attribute carries a snake_case name, a type, its CamelCase wire name
(derived unless `wire => ...` says otherwise) and an `=attr` block taken from
the spec's own `description`. Docker's definitions are flat, so a quoted
class name is a short name under `API::Docker::Type::` — there is no prefix
map. `docker_extends` is how the swagger's `allOf` is expressed.

## The rules that are not obvious

**The Perl name is derived from the spec's spelling, never the reverse.**
`PortBindings` → `port_bindings` works; going back does not, for any name
with a run of capitals — `CPUShares`, `OOMKillDisable`, `ID`, `NanoCPUs`. So
those names live in `spec-to-type-names.yaml` as a curated map, and the
generator refuses to guess: an unlisted capital-run name stops the run. The
round-trip guard does not save you here, because `DeviceIDs → device_i_ds`
derives back correctly and still reads wrong.

**Some keys are the caller's data and must never be translated.** Where the
swagger says `additionalProperties`, the *keys* come from the user —
`Labels`, `Annotations`, `ExposedPorts`, `PortBindings`, `Volumes`,
`StorageOpt`, `Tmpfs`, `Sysctls`, `DriverOpts`, `Options` and a good many
more. Such a field is typed `{ Str, $value_type }` and the DSL passes its
keys through byte for byte. Getting this wrong turns a label
`com.example.Some-Label` into something the caller never wrote, and it is the
single most damaging mistake the model can make.

Find these by grepping the spec for `additionalProperties`, never by looking
for `type: object` — at least one field declares the keyword with no type
above it, and reading the spec by type alone quietly degrades that field to
untyped passthrough.

**An unknown field passes through unchanged.** A caller whose engine is newer
than the spec we generated from must still reach the daemon; the model
translates what it knows and forwards the rest verbatim. This is not
theoretical: a real Podman `/info` answers with fields the swagger does not
have, and `ImageSummary` still serves `VirtualSize`, which Docker dropped from
the spec after v1.41.

**A null is where that stops, and only for a field we know.** A known field an
engine sends as `null` is read as unset: the attribute stays `undef` and
`TO_JSON` writes no key for it. That is not a leak, it is the daemon's own
resolution â measured 2026-08-28 against Podman 5.8.4 (API 1.44), where
`POST /containers/create` answers `{}`, `{"Image":null}` and `{"Image":""}`
with byte-identical errors, because Go's `encoding/json` unmarshals a null
into the type's zero value and an absent field leaves that same zero value.
It holds outbound too, which is why `/images/{id}/history` answers
`"Tags": null` instead of omitting the field. An *unknown* field keeps its
null, because with no declared type there is no zero value to read it as, and
so does a null under a key the caller chose. Three shapes, three outcomes, on
purpose; the reasoning lives in `API::Docker::Role::Type`'s POD and
`t/type_fixture_passthrough.t` holds all three against the fixtures.

**`since` is documentation, never a check.** It records which API version
introduced a field, derived by diffing the specs in `spec/` against each
other — the swagger itself carries no per-field version. Nothing is
validated, warned about or dropped at runtime. Podman serves fields its
announced version does not promise and refuses ones it does; we are not the
authority on what an engine can do.

## Where the values come from

`spec/` holds the swagger verbatim as Docker publishes it, so a `curl | diff`
still checks out. Generate against the newest version present and keep the
older ones for the diff that produces `since`.

    https://docs.docker.com/reference/api/engine/version/v1.51.yaml

Parse it with `YAML::XS`, not `YAML::PP`: Docker's `example:` blocks are
multi-line flow maps whose closing brace is under-indented, and YAML::PP
refuses the file. Both maint scripts read the spec through
`maint/spec-common.pl` so field order comes from one place.

A field's `description` is its `=attr` text — rewrapped, its grammar
straightened, its meaning intact. Where the spec describes nothing, say it is
undocumented upstream rather than inventing a sentence. Where the spec
describes neither a definition nor its schema, the generator derives what it
is from `paths:` or from the definitions that reference it; that is a
measurement of the same file, not an invention.

## Completion criteria

- `perl maint/spec-to-type.pl --verify DIR` — every class compared, every one
  identical, the diff empty.
- `perl maint/spec-drift-check.pl --baseline …` — zero in all seven tiers.
- `prove -lr t/` green, and `dzil test` green so the POD is known to weave.

A class nobody can check against the spec is not done, however good it looks.

## Related

- `references/dsl.md` — the `docker` keyword, the registry, serialisation
- `references/types.md` — the type vocabulary and the data-key list in full
- `api-docker-core` — the transport and the resource classes these feed
- `getty-perl-moo` — Moo conventions this distribution follows
