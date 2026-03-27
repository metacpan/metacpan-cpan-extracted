# Apophis Implementation Plan

Content-addressable storage with deterministic UUID v5 identifiers, powered by the Horus C library. **100% XS** — all logic in C, no Perl.

## Overview

Apophis generates deterministic UUID v5 identifiers for arbitrary content using SHA-1 namespace hashing (RFC 9562). Same content always produces the same UUID. Different namespaces produce different UUIDs for the same content. Stored objects are sharded across a 2-level hex directory tree for efficient filesystem access at scale.

## Architecture

```
                    +--------------------------+
                    |       Apophis.pm         |
                    |  XSLoader only, no logic |
                    +-----------+--------------+
                                |
                    +-----------+--------------+
                    |       Apophis.xs         |
                    |  ALL logic in C/XS:      |
                    |  - new() constructor     |
                    |  - identify / identify_  |
                    |    file (streaming)      |
                    |  - store / fetch /       |
                    |    exists / remove       |
                    |  - path_for / verify     |
                    |  - store_many /          |
                    |    find_missing          |
                    |  - metadata (JSON in C)  |
                    +-----------+--------------+
                                |
                    +-----------+--------------+
                    |     Horus (C headers)     |
                    |  horus_uuid_v5()          |
                    |  horus_sha1_*() streaming |
                    |  horus_parse_uuid()       |
                    |  horus_format_uuid()      |
                    +--------------------------+
```

## File Layout

```
Apophis/
  Makefile.PL
  ppport.h
  MANIFEST
  Changes
  README
  PLAN.md
  lib/
    Apophis.pm          # XSLoader + POD only
    Apophis.xs          # ALL logic: OO interface, file I/O, hashing, storage
  t/
    00-load.t
    01-identify.t       # determinism, format, different content
    02-namespace.t      # namespace isolation
    03-store-fetch.t    # round-trip, dedup, atomic write
    04-sharding.t       # path_for correctness
    05-exists-remove.t  # existence check, removal + .meta cleanup
    06-verify.t         # integrity verification
    07-streaming.t      # identify_file matches identify for same content
    08-bulk.t           # store_many, find_missing
    09-metadata.t       # metadata write/read
    10-edge-cases.t     # empty content, binary with nulls, unicode
```

## XS Internal C Functions

### `apophis_parse_ns_uuid(ns_hex) -> 16 bytes`
Uses `horus_parse_uuid()` to convert a 36-char namespace UUID string back to 16 raw bytes.

### `apophis_generate_namespace(name, name_len) -> 16 bytes`
Calls `horus_uuid_v5(out, HORUS_NS_DNS, name, name_len)` to derive a proper namespace UUID from a human-readable string.

### `apophis_identify(ns_bytes, content, content_len) -> UUID string`
Calls `horus_uuid_v5()` with the namespace bytes and content. Formats via `horus_format_uuid()`.

### `apophis_identify_stream(ns_bytes, PerlIO *fh) -> UUID string`
Streaming variant — O(1) memory:
```c
horus_sha1_ctx ctx;
horus_sha1_init(&ctx);
horus_sha1_update(&ctx, ns_bytes, 16);
while ((nread = PerlIO_read(fh, buf, 65536)) > 0)
    horus_sha1_update(&ctx, buf, nread);
horus_sha1_final(digest, &ctx);
memcpy(uuid, digest, 16);
horus_stamp_version_variant(uuid, 5);
```

### `apophis_path_for(store_dir, id) -> path string`
2-level hex sharding: `a3bb189e-...` → `store/a3/bb/a3bb189e-...`

### `apophis_mkdir_p(path)`
Recursive directory creation in C using `mkdir()`.

### `apophis_store_file(path, content, content_len)`
Atomic write: write to `path.tmp.$$`, then `rename()`.

### `apophis_meta_write(path, meta_hv)`
Simple key=value sidecar format (no JSON dependency). Writes `path.meta`.

### `apophis_meta_read(path) -> HV*`
Reads `.meta` sidecar back into a hash.

## XSUBs (Perl-visible API)

### `Apophis->new(namespace => $ns, store_dir => $dir)`
Creates blessed HV with `_ns_bytes` (16-byte binary SV) and `store_dir`.

### `$obj->identify(\$content)`
Returns UUID v5 string for in-memory content.

### `$obj->identify_file($path)`
Opens file, streams through SHA-1, returns UUID v5. O(1) memory.

### `$obj->store(\$content, %opts)`
identify + atomic write to sharded path. Returns UUID. Skips if already exists (CAS dedup).

### `$obj->fetch($id, %opts)`
Reads content from sharded path. Returns scalar ref.

### `$obj->exists($id, %opts)`
Returns true if sharded path exists.

### `$obj->remove($id, %opts)`
Unlinks content + `.meta` sidecar.

### `$obj->path_for($id, %opts)`
Returns the 2-level sharded filesystem path.

### `$obj->verify($id, %opts)`
Re-identifies stored content, compares UUID. Returns true if match.

### `$obj->store_many(\@refs, %opts)`
Maps store over array. Returns list of UUIDs.

### `$obj->find_missing(\@ids, %opts)`
Returns list of IDs not in store.

### `$obj->namespace()`
Returns the namespace UUID string.

## Storage Design

### 2-Level Hex Sharding
```
/store/a3/bb/a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a
```
256 x 256 = 65,536 shard directories. ~15 entries per leaf at 1M objects.

### Atomic Writes
```
write to: /store/a3/bb/a3bb189e-...tmp.PID
rename:   /store/a3/bb/a3bb189e-...
```

### Metadata Sidecars
```
/store/a3/bb/a3bb189e-....meta
```
Simple `key=value\n` format. No JSON dependency.

## Implementation Phases

### Phase 1: Skeleton
- Convert to XS module, ppport.h, Makefile.PL with Horus includes
- Minimal Apophis.pm (XSLoader only)
- BOOT section, t/00-load.t

### Phase 2: Core XS — Identification
- new() constructor
- identify() — horus_uuid_v5 wrapper
- namespace() accessor
- Tests: t/01-identify.t, t/02-namespace.t

### Phase 3: Storage
- path_for(), apophis_mkdir_p(), apophis_store_file()
- store(), fetch(), exists(), remove()
- Tests: t/03-store-fetch.t, t/04-sharding.t, t/05-exists-remove.t

### Phase 4: Streaming
- apophis_identify_stream() with PerlIO_read in 64KB chunks
- identify_file()
- Tests: t/07-streaming.t

### Phase 5: Integrity + Bulk
- verify(), store_many(), find_missing()
- Tests: t/06-verify.t, t/08-bulk.t

### Phase 6: Metadata
- apophis_meta_write(), apophis_meta_read()
- Integration into store/remove
- Tests: t/09-metadata.t

### Phase 7: Polish
- Edge case tests, POD, MANIFEST
- Tests: t/10-edge-cases.t
