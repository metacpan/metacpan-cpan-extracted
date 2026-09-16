---
name: beepack-core
description: Load before editing lib/BeePack.pm or bin/bee — the CDB_File+MsgPack file model, the readonly/tempfile open modes, the in-memory buffer, nil_exists semantics, and the type-setter surface.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# BeePack — Distribution Internals

BeePack is a **primitive key-value store**: a CDB (constant database) file whose values
are MsgPack-encoded. It exists to pack small key-values *and* large binary blobs into one
compact file that a microcontroller with very little memory can read and update — a Linux
x86 host writes it, an ARM microcontroller reads it, MsgPack keeps the values portable.
A C implementation is planned and will be stricter than this Perl one; keep the on-wire
format decisions defensible from both sides.

Consumer-facing usage lives in the module's own POD (`=synopsis`/`=description`) and in
`bin/bee`. This skill is about *changing* the distribution — one Moo class
(`lib/BeePack.pm`) plus the `bee` CLI (`bin/bee`).

## The file model: CDB values, MsgPack payloads

- The container is **CDB** via `CDB_File`, whose XS carries its own constant-database
  implementation — there is **no system `libcdb` dependency**; a plain `cpanm` install works.
  CDB is a read-optimised on-disk hash. BeePack **deliberately stores exactly one value
  per key** — CDB supports several values per key, and BeePack does not use that. Do not
  add multi-value behaviour without treating it as a format change.
- Each value is **MsgPack** via a single `Data::MessagePack->new->canonical->utf8`
  instance (`data_messagepack`, `init_arg => undef`). `canonical` makes the byte output
  deterministic (reproducible files, stable diffs); `utf8` decodes strings. Do not create
  ad-hoc MsgPack objects with different flags — everything must round-trip through this
  one instance or files stop being reproducible.
- BeePack intentionally **does not emit the MsgPack types Perl's `Data::MessagePack`
  cannot produce anyway** (ext types, etc.). Reads stay lenient (it will still unpack what
  it's given); writes stay within the producible subset. The planned C implementation is
  where strictness on this lands.

## Two open modes, decided by the tempfile

`open($class, $filename, $tempfile, %attr)` is the front door; `new` takes
`filename`/`tempfile`/`%attr` directly.

- **Read-only** (no tempfile): `BeePack->open('my.bee')`. `readonly` is lazy and derives
  to **true** when there is no tempfile. Opening a non-existent file read-only croaks.
- **Read/write** (a tempfile): `BeePack->open('my.bee', 'my.bee.'.$$)`. `readonly` derives
  to **false**. `CDB_File` has no in-place update, so the source of truth is an in-memory
  buffer (`_data`, key → raw MsgPack bytes) seeded from the existing file on open (an absent
  file starts empty), and `save` writes it back out. `BUILD` croaks *"Read/Write opening
  requires tempfile"* if `readonly` is false but no tempfile is present — keep that guard.
- Every setter calls `readonly_check` first and croaks on a read-only pack. The tempfile,
  not a mode flag, is the source of truth for writability — don't add a separate writable
  boolean that can disagree with it.

## nil_exists — the one behavioural quirk that surprises people

By default **a key whose value is nil (`undef`) is reported as not existing.** `exists`:
returns 0 if the key is absent from the buffer; if present *and* `nil_exists` is set, returns
true; otherwise it unpacks the value and returns 1 only if it is defined.
`get` returns `undef` for a key that does not "exist" under this rule.

Opening with `nil_exists => 1` flips this: a nil-valued key then counts as existing. This
is a documented, tested behaviour (`t/simple.t` asserts both directions) — never "clean it
up" into plain key existence.

## The setter surface

- `set($key,$value)` — MsgPack-packs whatever it's given and writes it into the in-memory
  buffer (`_data`), overwriting any prior value.
- `set_integer` (`0 + $value`), `set_string` (`"$value"`), `set_bool` (MsgPack
  `true`/`false`), `set_nil` (`undef`). The forcing is the point: it pins the MsgPack type
  regardless of how Perl currently sees the scalar.
- `set_type($key,$type,$value)` dispatches on the **first character** of `$type`:
  `i`→integer, `b`→bool, `s`→string, `n`→nil, `a`→array (`set` an arrayref), `h`→hash
  (`set` a hashref), empty→plain `set`. `bin/bee` mirrors this same first-char dispatch on
  the command line — a new type must be added in **both** places to stay consistent.
- `BeePack->true` / `BeePack->false` expose the MsgPack boolean singletons so callers can
  build the right booleans inside arrays/hashes passed to `set`.
- `get` unpacks; `get_raw` returns the **raw MsgPack bytes** unchanged (used e.g. to pipe a
  gzipped blob straight out). `keys` lists the keys of the in-memory buffer.

## save() rebuilds the file from the buffer

```perl
my $cdb = CDB_File->new($self->filename,$self->tempfile) or croak(...);
$cdb->insert($_, $self->_data->{$_}) for sort CORE::keys %{$self->_data};
$cdb->finish;   # atomic rename of the tempfile onto filename
```

`CDB_File` builds a fresh cdb and renames it into place atomically via the tempfile — there
is no in-place update and no reopen. The in-memory `_data` buffer stays the source of truth,
so the pack is immediately usable for further reads and writes after `save`. Keys are
inserted in `sort` order, so the on-disk file is deterministic regardless of hash ordering
(only the *content* is guaranteed identical across cdb implementations, not the exact byte
layout). `save` croaks on a read-only pack.

## Changing the distribution — checklist

1. `lib/BeePack.pm` and `bin/bee` each carry `# ABSTRACT:` and `our $VERSION` (release
   skill: the version in the tree is the *next* release, set on every file under `lib/`
   and `bin/`). Keep the two versions identical.
2. A new value type is two edits that travel together: the `set_*`/`set_type` branch in
   `lib/BeePack.pm` and the matching first-char branch in `bin/bee`.
3. Any change to how a value is packed or to `nil_exists`/readonly behaviour is a
   round-trip change — a value written by the new code must read back equal, and the
   read-only/read-write and `nil_exists` paths must all still hold.
4. `dzil test`, or `prove -lr t/` while iterating. The suite (`t/load.t`, `t/simple.t`,
   `t/integer.t`) is network-free; `t/simple.t` and `t/integer.t` can regenerate a fixture
   `.bee` via `BEEPACK_GENERATE_SIMPLE_TESTDB` / `BEEPACK_GENERATE_INTEGER_TESTDB`.
5. User-facing change → a bullet under `{{$NEXT}}` in `Changes`.

## POD is auto-woven — do not hand-write generated sections

This is an `[@Author::GETTY]` distribution: PodWeaver generates NAME, VERSION, AUTHOR,
SUPPORT, CONTRIBUTING and COPYRIGHT from `# ABSTRACT:` and `dist.ini`. Never hand-write a
`=head1 SUPPORT`/`AUTHOR`/`COPYRIGHT`; use `=synopsis`/`=description`/`=seealso` and inline
`=attr`/`=method`. (Details: skill `getty-perl-release-author-getty`.)
