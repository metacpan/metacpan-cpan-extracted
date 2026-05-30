# Packing a MySQL/PostgreSQL Data Dir into a Single File

SQLite is a single file. MySQL and PostgreSQL use data **directories**. This
documents how to wrap such a data dir into a single file that is still usable
(read-only base, ephemeral writes), and whether unprivileged users can mount and
run a DB against it.

## Core Constraint: No DB Starts Truly Read-Only

Both servers must write at startup, even when "serving" read-only data:

- **PostgreSQL**: `postmaster.pid`, `postmaster.opts`, `pg_wal/`, lock files,
  stats files. No clean read-only-datadir mode.
- **MySQL / InnoDB**: redo logs, `.pid`, socket, tmp files — unless forced with
  flags (see below).

So a single-file, read-only base needs a **writable scratch layer** for the bits
the server must touch. Scratch can be throwaway (tmpfs).

## Single-File Packaging Options

| Method                         | Single file | Rootless mount        | Read-only      | Notes                          |
|--------------------------------|-------------|-----------------------|----------------|--------------------------------|
| ext4 image + `mount -o loop`   | yes         | **no** (root/fstab)   | optional       | classic; regular user blocked  |
| **SquashFS + `squashfuse`**    | yes         | **yes** (FUSE)        | yes (always)   | compressed; best fit           |
| `fuse2fs` on ext4 image        | yes         | yes (FUSE)            | optional       | rw possible but slow           |
| tarball                        | yes         | no (must extract)     | n/a            | not directly usable            |

## Can Regular Users Mount It?

- Plain `mount` of a disk image: **no** — needs root, or a pre-configured
  `/etc/fstab` entry with the `user` option.
- **FUSE: yes** — `squashfuse`, `fuse2fs`, `fuse-overlayfs` all run unprivileged
  (where FUSE is permitted, which is the Linux default).

## Recommended Stack (rootless, read-only base + ephemeral writes)

1. Build the data dir once (`initdb` / mysql install / load schema + seed data).
2. Pack into squashfs (the single file):
   ```
   mksquashfs datadir/ db.sqfs
   ```
3. At use time, fully rootless:
   ```
   squashfuse db.sqfs /mnt/lower
   fuse-overlayfs -o lowerdir=/mnt/lower,upperdir=/tmp/up,workdir=/tmp/work /mnt/merged
   postgres -D /mnt/merged          # or: mysqld --datadir=/mnt/merged
   ```
   Reads hit the immutable squashfs file. Writes (WAL, pid, locks) land in the
   tmpfs upper layer. Base file never changes — shareable across runs.

Alternative to `fuse-overlayfs`: user namespace + kernel overlayfs (rootless on
modern kernels):
```
unshare -Urm
mount -t overlay overlay -o lowerdir=/mnt/lower,upperdir=/tmp/up,workdir=/tmp/work /mnt/merged
```

## DB-Specific Shortcuts (skip the overlay)

### MySQL — has a real read-only mode
Run straight off the squashfuse mount, redirect writable bits elsewhere:
```
mysqld --datadir=/mnt/lower \
       --innodb-read-only=ON \
       --pid-file=/tmp/x.pid \
       --socket=/tmp/x.sock \
       --tmpdir=/tmp
```

### PostgreSQL — no clean read-only datadir
Use the overlay approach. Hacks via `hot_standby` / recovery mode exist but are
fragile. Overlay is simplest and robust.

## Fit for DBIx::QuickDB

Strong fit: pre-seed schema once → squashfs → spin throwaway test DBs fast via
overlay. Base file is immutable and shared across runs, so spin-up is copy-free
and fast. Candidate feature: a driver method that packs a built data dir into a
squashfs file and mounts it (squashfuse + fuse-overlayfs) on launch.
