# App::FileSync — Specification (draft v0.2, for approval)

A cron/CLI file synchroniser: multiple clients ↔ one master tree on a server, with an
independent replica of the master on a second machine.

- **Distribution:** `App::FileSync`; source in `~/njh/src/njh/App-FileSync`; commands
  `filesync`, `filesync-server`, `filesync-admin`.
- **Status:** approved. Phases 1 and 2 are implemented (merge engine, scan/hash cache,
  local and SSH transports, forced-command server, host key checking, locking, journal,
  push/pull/delete/trash, conflicts, tests); phase 3 (replica mirror, snapshots, verify,
  restore) is next.
- **Target:** Perl 5.20+ (developed and tested on 5.40), pure Perl, no XS, no database
  server, no daemon, no web UI.
- **Supersedes nothing.** The existing [syncfiles](../syncfiles/syncfiles) script (one-way,
  date-bucketed copy for photo archives) is a different tool and will be left alone.

---

## 1. Purpose

Provide a small, auditable, fully Perl file sync system that does one job: keep a set of
client directories in step with a master copy on a server, and keep a second machine
holding a faithful copy of that master.

OwnCloud/Nextcloud failed for this use case. This design deliberately removes the usual
failure surfaces:

| Usual component | Here |
| --- | --- |
| PHP web application | none |
| Database server | none — JSON index files |
| Long-running sync daemon | none — every run is a short-lived CLI process |
| Proprietary sync protocol | line-delimited JSON over one SSH connection |
| Web UI / browser session | none — `status`, `log`, `restore` subcommands |
| rsync / unison / rclone | none — all file logic in Perl; `ssh` is the only external binary |

Everything is inspectable with `ls`, `cat`, `diff` and `perl -d`.

## 2. Goals

1. Bidirectional sync between each client and the master, driven only by cron (Unix) or
   Task Scheduler (Windows).
2. The master is authoritative for arbitration but is *not* read-only: files dropped into
   the master by an administrator propagate to clients on their next run.
3. Deletions propagate, but only through a trash area with retention.
4. No silent data loss. Every version that ever existed is recoverable from the master,
   the server trash, a conflict copy, or a replica snapshot.
5. A second machine holds a verified copy of the master, restorable without filesync.
6. Runs unattended; a failed or interrupted run leaves no partial or corrupt files.
7. Operable by one person with `crontab`, `ssh` and a text editor.
8. 100% Perl: all logic, scanning, hashing, merging, transfer framing and file writing.
   The only external program invoked is `ssh` (plus `ssh-keygen` during setup).

## 3. Non-goals

- Real-time / filesystem-watching sync. Changes appear at the next run.
- Multi-writer collaborative editing of the same file (conflicts are resolved, not merged).
- Windows ACLs, Unix ownership, xattrs, resource forks, hard-link identity.
- Encryption beyond what SSH provides; the master and replica are plaintext at rest.
- Web, GUI, mobile clients, sharing links, versioning UI.
- Syncing special files (sockets, FIFOs, device nodes).
- Being a general backup program (there is no archive format; the replica is a directory).

## 4. Definitions

| Term | Meaning |
| --- | --- |
| **repo** | A named sync set: one master directory on the server, one local directory per client. |
| **master** | The authoritative tree for a repo, stored on the server as ordinary files under `<root>/master/<repo>/`. |
| **client** | A machine running `filesync sync` against a repo. Has a unique client id (e.g. `laptop-1`). |
| **base** | The server-side record of the state a given client last synchronised successfully. One file per client per repo. |
| **replica** | A machine holding an exact mirror of the master (`--role replica`). Pull-only, never pushes. |
| **trash** | Dated holding area for deleted files, on server and on each client. |
| **conflict copy** | A file preserved next to the winner when both sides changed the same path differently. |
| **index** | Server-side cache of the master: path, type, size, mtime, mode, SHA-256. Rebuildable. |

## 5. Architecture

```
        client A ──┐
        client B ──┼── ssh (one connection per run) ──►  filesync-server  ──►  master/<repo>/
        client C ──┘        request/response              (policy engine)      .filesync/repos/<repo>/
                                                                                ├── clients/<id>.json   (base)
                                                                                ├── master.json         (index)
                                                                                ├── trash/YYYY/MM/DD/
                                                                                ├── journal/YYYY-MM.jsonl
                                                                                └── locks/

        replica ───── ssh (pull-only) ─────────────────────────────────────►  same server
            └─ mirror of master + .filesync-snapshots/YYYY-MM-DD/ (hardlinks)
```

**Policy lives on the server, not in the clients.** A client only:

1. scans and hashes its local tree (stat cache first),
2. sends its manifest,
3. executes the plan the server returns,
4. acks each completed action.

This means one implementation of the merge rules, one place to fix a bug, and clients that
are thin enough to run on Strawberry Perl. A `Local` transport (spawn `filesync-server`
directly, no ssh) is used by the test suite and for single-machine use.

### 5.1 Processes

There is no daemon. `filesync-server` is invoked by sshd as a forced command, one process
per client per run, and exits when the client disconnects. A stale process cannot outlive
the TCP connection for long: the session has an idle timeout and takes the repo lock with
`flock`, released by the kernel on exit.

### 5.2 Why the server decides

The three inputs to arbitration are the client's manifest (A), the master index (B) and the
client's base (base). Only the server has all three reliably; a client that has been
offline for a week, or whose cache was deleted, must not be able to invent history.

## 6. On-disk layout

### 6.1 Server

The server root is `/srv/filesync` by default and is resolved from `--root`, `$FILESYNC_ROOT`
or that default, in that order, by both server binaries.

```
/srv/filesync/                                   # server root, configurable
├── master/<repo>/                               # THE master tree — plain files
└── .filesync/repos/<repo>/
    ├── config.json                              # ignore patterns, retention, limits
    ├── master.json                              # index of master/
    ├── clients/<client-id>.json                 # base manifest per client
    ├── trash/2026/10/22/<original/rel/path>     # deleted files, date-bucketed
    ├── journal/2026-10.jsonl                    # append-only audit trail
    └── locks/repo.lock
```

The master is deliberately a plain directory, not a database or object store: recovery is
`cp -a`, inspection is `find`, and no filesync version is needed to read it.

### 6.2 Client

```
~/.filesync/                       # %USERPROFILE%\.filesync on Windows
├── config.json                    # repos, server addresses, identity file
├── cache/<repo>.json              # stat/hash cache + copy of base (for status only)
├── trash/2026/10/22/<rel/path>    # files deleted locally by a server-side deletion
├── logs/<repo>.jsonl              # one line per completed run (exit, counts, warnings)
└── locks/<repo>.lock
```

The client's sync root is whatever the user configured — it is not required to be inside
`~/.filesync`. A marker file `.filesync-root` is created there by `init` and never synced;
its absence aborts the run (protection against an unmounted drive looking like an empty
directory).

### 6.3 Replica

The replica's root is an exact mirror of `master/<repo>/`. It additionally keeps
`.filesync-snapshots/YYYY-MM-DD/` containing hardlinks to the mirrored files (Unix), or
copies if `--snapshot-mode copy` is configured (Windows). Snapshots are taken *before* the
sync so a bad master state can be rolled back.

`.filesync-snapshots` is on the shared ignore list, so the mirror never treats it as a
local extra and deletes it. Only the first snapshot of a day is taken: a later run reports
that the day already exists rather than overwriting the state from before the first sync.
`--keep N` prunes all but the newest N days. Because a hardlink shares its inode, editing a
mirrored file in place also changes the snapshots that hold it — the syncer always replaces
files, and copy mode avoids the issue entirely. `snapshot restore` replaces the target
files but does not delete files added since the snapshot, so it recovers versions rather
than rewinding the directory; restoring into the replica root is undone by the next mirror
run, so use `--to DIR` to keep the old version.

## 7. Configuration

### 7.1 Client (`~/.filesync/config.json`)

```json
{
  "version": 1,
  "client_id": "laptop-1",
  "ssh": { "command": "ssh", "identity": "/home/njh/.ssh/id_ed25519_filesync",
           "extra_args": ["-o", "BatchMode=yes"] },
  "repos": {
    "documents": {
      "root": "/home/njh/Documents",
      "transport": "ssh",
      "server": "filesync@files.example.com",
      "port": 22,
      "identity": "/home/njh/.ssh/id_ed25519_filesync",
      "known_hosts": "/home/njh/.ssh/known_hosts_filesync",
      "host_key_checking": "yes",
      "server_command": "filesync-server",
      "remote_repo": "documents",
      "role": "client",
      "local_trash_days": 30,
      "snapshot_mode": "hardlink",
      "snapshot_keep": 14,
      "log": "/home/njh/.filesync/logs/documents.log"
    }
  }
}
```

Notes:

- `client_id` is generated at `init` from the hostname, sanitised to `[A-Za-z0-9._-]`, and
  can be overridden with `--id` (needed when two machines share a hostname).
- `ssh.command` allows `ssh.exe`, a wrapper, or a `plink`-style shim.
- `transport` is `local` or `ssh`. The local transport spawns `filesync-server` as a child
  process over a pipe; `server_root` names the server's root directory. It exists for the
  test suite and for a server directory that is local to the client. `server_bin` can
  override the path to the server program. The ssh transport is described in 10.1.
- `host_key_checking` is `yes` (the default) or `accept-new`; `filesync init
  --accept-host-key` records the latter, which trusts a key the first time it is seen and
  refuses any later change. There is no setting that disables host key checking.
- `known_hosts` points ssh at a private known-hosts file for this sync account, so a
  machine-wide `~/.ssh/known_hosts` is not required. `server_command` is the remote
  program and defaults to `filesync-server`; the server's root is never sent by the client.
- No credentials are stored: SSH keys and `~/.ssh/config` do authentication.
- `local_trash_days` governs the client's own trash; retention of the server trash is server
  policy (7.2). Deletion and size limits are server policy only, so one file decides them.
- `snapshot_mode` (`hardlink` or `copy`, from `init --snapshot-mode`) and `snapshot_keep`
  (default 14) apply to a replica only; `snapshot --keep N` overrides the retained count for
  that run. Clients ignore both.
- Ignore patterns are **not** configurable per client (see 7.3) — a client-side exclusion
  would be indistinguishable from a deletion.

### 7.2 Server repo (`.../repos/<repo>/config.json`)

```json
{
  "version": 1,
  "name": "documents",
  "created": "2026-10-22T12:00:00Z",
  "trash_days": 30,
  "max_deletes": 200,
  "max_delete_percent": 10,
  "conflicts": "inline",
  "preserve_mode": true,
  "allow_symlinks": false,
  "clients": { "laptop-1": { "role": "client" }, "backup-1": { "role": "replica" } },
  "ignore": [
    ".filesync-root", ".filesync-tmp-*", ".filesync-snapshots",
    "*.swp", "*~", ".#*", "#*#",
    ".DS_Store", "._*", "Thumbs.db", "desktop.ini", "*.crdownload", "*.part"
  ]
}
```

`clients` is an allowlist: an empty map means "any client the SSH key presents" (not
recommended). Roles are pinned per client id.

### 7.3 Ignore patterns

One list, stored on the server, applied by both sides (`hello` returns it to the client).
Patterns match paths relative to the sync root, using glob syntax:

- `*` matches within one path segment, `?` one character, `**` any number of segments.
- A pattern with no `/` matches any segment (i.e. `*.swp` matches `a/b/c.swp`).
- A leading `!` re-includes; patterns are evaluated in order.
- `#` at the start is a comment.

Ignored paths never enter a manifest or a base, so they can never be mistaken for a
deletion. `filesync-admin repo set-ignore` edits the list; clients pick it up on next run.

### 7.4 Process settings (`Object::Configure`)

Settings that belong to the process rather than to a repo are read through
`Object::Configure`. The file is `~/.conf/app-filesync.json` when it exists, or the path in
`$FILESYNC_SETTINGS`; the section key is `App__FileSync`. Environment variables named
`App__FileSync__<key>` take precedence, and a `UNIVERSAL` section in the same directory
applies to every class that uses the module.

```json
{
  "App__FileSync": {
    "log_level": "warning",
    "log_format": "%level%: %message%",
    "log_file": "",
    "ssh_identity": "",
    "ssh_known_hosts": "",
    "server_command": "filesync-server"
  }
}
```

| Key | Default | Meaning |
| --- | --- | --- |
| `log_level` | `warning` | Minimum level: trace, debug, info, notice, warning, error, crit, alert, emerg. |
| `log_format` | `%level%: %message%` | `Log::Abstraction` format for the file/fd backends. |
| `log_file` | empty | Append to this file instead of standard error; leading directories are created. |
| `ssh_identity` | empty | `ssh -i` for every SSH repo, unless the repo records its own `identity`. |
| `ssh_known_hosts` | empty | `UserKnownHostsFile` for every SSH repo, unless the repo records its own `known_hosts`. |
| `server_command` | `filesync-server` | Remote program run over SSH, unless the repo records its own `server_command`. |

Caller-supplied values are the lowest priority in `Object::Configure`; the shipped
defaults above are what remain when no file or variable sets a key. A value stored in a
repo's client entry by `filesync init --identity`, `--known-hosts` or `--server-command`
beats the process setting for that repo, so the common case needs no per-repo options
while an exception still has somewhere to go. The repo definitions
are *not* part of this file - they stay in 7.1/7.2, because `filesync init` and
`filesync-admin` write them and `Object::Configure` only reads. `--verbose` and `--quiet`
clone the logger after reading the settings, so the flag describes that run and wins.

`filesync settings` reports the six effective values and, for each, the layer that
supplied it: a built-in default, a section of the settings file (`App__FileSync`, or
`UNIVERSAL` from `universal.json` beside it), or an `App__FileSync__<key>` environment
variable. Environment names are matched case-insensitively, as `Config::Abstraction`
matches its prefix, and reported in the spelling the environment itself uses - which is
upper-cased on Windows, whatever case the variable was set in. It then resolves every SSH setting for each repo in the client config
(`--config FILE`, defaulting as for the other commands) and shows, per repo, the value
the transport will use and whether the repo's own entry, the process settings or ssh's
own default supplied it; a local-transport repo is listed as not using them. The repo
port and host-key-checking policy have no process-wide counterpart, so they appear for
every SSH repo and are always marked `[repo only]` in the text output and
`"repo_only":true` in the JSON, including when ssh's own default is shown. It needs no
network. With `--json` it prints
`{"settings_file":...,"config_file":...,"settings":[{"key","value","source","label"}],
"repos":[{"repo","transport","server","ssh":[{"key","value","source","label","repo_only"}]}]}`,
where `repo_only` is present only on the rows for those two settings and
the process `source` is `default`, `file`, `env` or `merged` (a value that came from a
layer the report does not model, such as a `global` section), and the per-repo `source`
is `repo`, `process` or `default`. Raw values are reported; an empty `ssh_identity`,
`ssh_known_hosts` or `log_file` means the ssh or stderr default, and an empty
`server_command` means `filesync-server`.

Command results (summaries, plans, `--json`) are written to standard output by the
commands; the logger carries diagnostics on standard error, so cron can separate them.

## 8. Reconciliation algorithm

### 8.1 Inputs, per path

- `base` — state at the client's last successful sync (`absent` or `{hash,size,mtime,mode,type}`).
- `A` — client's manifest now.
- `B` — master now (from index, refreshed by a stat walk; rehashed where stat changed).

`hash` is SHA-256 of the file content. A file is only rehashed when size or mtime differs
from the cached value (or with `--deep`).

### 8.2 Decision table

| # | base | client (A) | master (B) | Action |
| --- | --- | --- | --- | --- |
| 1 | same | same | same | no-op (refresh base if needed) |
| 2 | X | X | Y≠X | **pull**: master → client |
| 3 | X | Y≠X | X | **push**: client → master |
| 4 | X | Y | Y | converge: update base, no transfer |
| 5 | X | absent | X | **delete master** (→ server trash) |
| 6 | X | X | absent | **delete client** (→ client trash) |
| 7 | X | absent | absent | converge: base entry removed |
| 8 | X | absent | Y≠X | **pull** (modification beats deletion; file is resurrected on the client), warning |
| 9 | X | Y≠X | absent | **push** (modification beats deletion; file is resurrected in the master), warning |
| 10 | absent | Y | Y | converge: base entry added |
| 11 | absent | Y | absent | **push** (new on client) |
| 12 | absent | absent | Y | **pull** (new on master) |
| 13 | absent | Y | Z≠Y | **conflict** (both new, different) |
| 14 | X | Y≠X | Z≠X, Z≠Y | **conflict** (both modified) |

File↔directory type changes are treated as delete + create and follow rows 8–14; a type
change on both sides differently is a conflict resolved by the same rules, with the losing
subtree preserved in the trash.

### 8.3 Conflict resolution

1. Compare `mtime` (UTC epoch, seconds; sub-second if the filesystem provides it).
2. Later mtime wins. If within 2 seconds, or exactly equal, the **master** wins
   (deterministic, never flip-flops between runs).
3. The losing content is preserved as a conflict copy *next to the path*, on both sides,
   named:

   ```
   report.txt  →  report.conflict-laptop-1-20261022T101500Z.txt
   ```

   (extension preserved at the end so editors and viewers still open it), where `<timestamp>`
   is the UTC time the conflict was resolved.
4. The winner is written on both sides; the conflict copy propagates to other clients as an
   ordinary new file.
5. The conflict is logged with both hashes, both mtimes, the winning side, and the name of
   the copy. Conflict copies are never automatically deleted or pruned — they are real
   files the user decides about.

There is no per-run override of step 2: `filesync sync` has no `--prefer`, so a first sync
always merges the two trees and keeps each losing version as a conflict copy. To make the
master authoritative, start the new client with an empty root — the first sync pulls the
master — then copy in only the local files that should be added.

### 8.4 First sync / join

A client with no base (new machine, or `filesync-admin client forget`) produces conflicts for
every path present on both sides with different content. Recommended procedure:

```
filesync sync --dry-run --repo documents    # inspect the plan, nothing is touched
filesync sync --repo documents              # merge; §8.3 decides each conflict
```

There is no automatic "adopt everything" on first sync: two populated trees are merged, not
overwritten.

### 8.5 Metadata

- **mtime** is preserved in both directions (set after the atomic rename). When the content
  hashes are equal, mtime is *not* propagated, so a `touch` on one machine does not cause
  a copy of every file.
- **mode** (permission bits) is preserved on Unix↔Unix. A push from a Windows client keeps
  the master's existing mode for an existing path, and uses `0644` for new files
  (`preserve_mode` can turn mode syncing off entirely).
- **ownership** is never changed.
- Directories: created on demand; empty directories are synced, and a removed empty directory
  is deleted (and recorded in the journal) rather than trashed.

### 8.6 Worked example

Base, client and master all hold `notes.txt` with hash `aaa`.

1. Laptop edits it (hash `bbb`) and saves at 10:00; desktop edits it (hash `ccc`) at 10:05
   and syncs first.
2. Desktop's run: base `aaa`, client `ccc`, master `aaa` → push. Master is now `ccc`,
   desktop's base is `ccc`.
3. Laptop's run: base `aaa`, client `bbb` (mtime 10:00), master `ccc` (mtime 10:05) →
   conflict, master wins. Laptop receives `ccc`, renames its `bbb` to
   `notes.conflict-laptop-1-20261022T101200Z.txt`, and the conflict file is left as a new
   local file.
4. Laptop's next run pushes the conflict file; desktop's next run pulls it. All three trees
   now hold the winner and an identical conflict copy, and `filesync log` / the server
   journal show who won and why.

If instead the laptop deleted `notes.txt` and the desktop edited it, row 8 applies: the
edit wins, the file is resurrected on the laptop, and the run exits 3 with a warning — no
content is lost and nothing is trashed.

## 9. Deletion and trash

1. A deletion is only recognised when `base` says the path existed and the side that still
   has it is unchanged — never from a missing file alone.
2. **Server deletes**: the file (or whole subtree, in one rename) moves to
   `trash/YYYY/MM/DD/<original rel path>` inside the repo metadata directory. On POSIX this
   is an atomic `rename` when trash and master are on the same filesystem; otherwise a
   copy-then-unlink with the original left in place until the copy verifies.
3. **Client deletes**: same scheme under `~/.filesync/trash/YYYY/MM/DD/`.
4. Retention: entries older than `trash_days` (default 30) are pruned at the start of a run,
   at most once per day per repo. The server uses the repo's `trash_days`; each client uses
   its own `local_trash_days` (default 30).
5. Restore:
   - server: `filesync-admin restore documents path/to/file --to /tmp`, or `--list` to see
     versions;
   - client: `filesync restore path/to/file --to /tmp`.
6. Deleting a directory that contains ignored files leaves those files in place; the
   directory itself is removed only if empty, otherwise the journal records it as skipped.

Restoring from a backup mirror of `master/<repo>/` — an `rsync -a --delete` copy taken by
cron, say — is a filesystem operation, not a filesync one. Stop the client jobs and the
mirror job first so neither changes the tree during the copy, and let a running sync
finish.

To roll the whole master back, mirror the backup over it:

```sh
rsync -a --delete --checksum /srv/backups/FileSync/documents/ \
    /srv/filesync/master/documents/
```

This is a rollback rather than a merge: files created after the backup was taken disappear
from the master, and the next sync propagates that to the clients, so copy anything you
need to keep out of the tree first. `--checksum` compares contents rather than trusting
size and mtime, so a restored file is not skipped because it happens to match. The server
would rehash the restored files on the next session anyway, but `filesync-admin reindex`
rebuilds the index immediately, before any client reconnects; clients then pull the
restored versions, merging edits they have not synced as usual.

Before re-enabling anything, check that the copy itself is exact by comparing the restored
master with the backup. This is a read-only comparison, so it is safe while the jobs are
paused:

```sh
rsync -a --delete --checksum --dry-run --itemize-changes \
    /srv/backups/FileSync/documents/ /srv/filesync/master/documents/
```

No output and exit 0 mean every restored file matches the backup and nothing extra is
left behind. A line beginning `>f` names a path that still differs and would be rewritten
by a real run; a `*deleting` line names one the rollback should have removed. Resolve
anything it reports before going on.

The index is a cache and still describes the pre-rollback tree, so `filesync-admin verify`
may report drift straight after the copy — that is expected, not evidence of a bad
restore. Rebuild the index from the restored tree, then check it:

```sh
sudo -u filesync filesync-admin reindex documents
sudo -u filesync filesync-admin verify documents --deep
```

`reindex` hashes every file in the master and replaces `master.json` atomically, reporting
`indexed N files, N empty dirs (N B); master index written`; it holds the repo lock, so it
refuses to run while a sync session is active. Paths the scanner cannot index, such as
symlinks or unreadable files, are listed as skipped rather than silently dropped. `clean`
and exit 0 from `verify` confirm that the master and its index agree. If the index check
still reports modified, missing or extra paths, stop and investigate rather than
re-enabling cron. Re-enable the client and mirror jobs once that check is clean.

To restore just one file or directory, copy that path back instead:

```sh
rsync -a --checksum /srv/backups/FileSync/documents/notes/plan.txt \
    /srv/filesync/master/documents/notes/
rsync -a --checksum /srv/backups/FileSync/documents/photos/ \
    /srv/filesync/master/documents/photos/
```

The trailing slash on the second source copies the directory's contents; without it rsync
puts the directory itself inside the destination. Add `--delete` only when that directory
should match the backup exactly, since it removes files created after the backup was taken.
Everything outside the restored paths is left alone; refresh the index with `reindex` as
above, or let the next session do it. Check the restored paths with the matching read-only
comparison before re-enabling the jobs, for example:

```sh
rsync -a --checksum --dry-run --itemize-changes \
    /srv/backups/FileSync/documents/notes/plan.txt \
    /srv/filesync/master/documents/notes/
```

No output means the path matches the backup; use `--delete` in the comparison too when
the restore used it, so extra files in that directory are reported. The `reindex` and
`verify` checks above apply here as well.

### Recovery automation

A recovery script can make the index check the gate for restoring the jobs. This one runs
`reindex` and `verify --deep`, parses both JSON documents, and re-enables the jobs only when
the index was written, nothing was skipped and verify is clean. Any failure leaves them
disabled and prints why:

```sh
#!/bin/sh
# Run on the server after the rollback and the rsync comparison, with the
# client and mirror cron entries removed.
set -eu

repo=documents

admin() {
    sudo -u filesync filesync-admin "$@"
}

# reindex reports a refusal only through its exit status (a held lock, an
# unknown repo); there is no JSON to parse in that case.
if ! reindex="$(admin reindex "$repo" --json)"; then
    echo "reindex failed; jobs stay disabled" >&2
    exit 1
fi

# verify prints its report and then exits 4 when it finds drift, so a non-zero
# status is not by itself a failure to run. Anything else is.
verify_status=0
verify="$(admin verify "$repo" --deep --json)" || verify_status=$?
if [ "$verify_status" -ne 0 ] && [ "$verify_status" -ne 4 ]; then
    echo "verify could not run (exit $verify_status); jobs stay disabled" >&2
    exit 1
fi

printf '%s\n%s\n' "$reindex" "$verify" | perl -MJSON::PP -e '
    local $/;
    my ($reindex_json, $verify_json) = split /\n/, <STDIN>;
    my $reindex = decode_json($reindex_json);
    my $verify  = decode_json($verify_json);

    sub fail { print STDERR @_; exit 1 }

    fail("reindex did not write the index\n") unless $reindex->{written};

    my %skipped = %{ $reindex->{skipped} || {} };
    my @skipped = sort keys %skipped;
    if (@skipped) {
        fail sprintf "reindex skipped %d path(s): %s\n", scalar @skipped,
            join(", ", map { "$_ ($skipped{$_})" }
                @skipped[0 .. ($#skipped < 4 ? $#skipped : 4)]);
    }

    unless ($verify->{ok}) {
        my @drift;
        for my $kind (qw(modified missing extra)) {
            my @paths = map { $_->{p} } @{ $verify->{$kind} || [] };
            next unless @paths;
            push @drift, sprintf "%d %s (%s)", scalar @paths, $kind,
                join(", ", @paths[0 .. ($#paths < 4 ? $#paths : 4)]);
        }
        fail "verify found drift: " . join("; ", @drift) . "\n";
    }

    printf "indexed %d files, %d empty dirs; verify clean (%d rehashed)\n",
        $reindex->{files}, $reindex->{dirs}, $verify->{rehashed};
' || {
    echo "recovery checks failed; jobs stay disabled" >&2
    exit 1
}

# Only reached when every check passed, so re-enable both job sets here.
crontab /etc/filesync/crontab
```

Skipped paths are fatal on purpose: `reindex` still exits 0 after leaving a symlink or an
unreadable file out of the index, and starting the jobs over an index that omits a path can
make the next client session read that path as deleted from the master. The drift message
names up to five paths per kind, which is usually enough to see whether the rollback or the
index is at fault. Replace the final command with however the jobs are managed on this host,
and keep the checks before it: restoring the cron entries is the one step that must not
happen after a partial restore.

## 10. Transport and protocol

### 10.1 Transport

One `ssh` process per repo per run, spawned with an argument list (never through a shell):

```
ssh -T -o BatchMode=yes -o ServerAliveInterval=30 -i <identity> -p <port> \
    filesync@host /usr/local/bin/filesync-server --repo documents --client laptop-1 \
    --role client --proto 2
```

- Forced command in `authorized_keys` fixes the repo, the client id and the role, with
  `restrict` (no pty, no forwarding, no agent, no X11). The server refuses a session whose
  `hello` disagrees with its arguments.
- `BatchMode=yes` means a missing key fails the run instead of prompting — correct for cron.
- The client always sets `StrictHostKeyChecking`: `yes` by default, or `accept-new` if the
  repo was initialised with `--accept-host-key`. An unknown or changed host key therefore
  fails the run with ssh's own message, which is reported verbatim; nothing in the
  configuration can turn the check off.
- `--root` is not part of the client's command. The server takes it from the forced command
  or `FILESYNC_ROOT`, defaulting to `/srv/filesync`, and `SSH_ORIGINAL_COMMAND` may only
  repeat the pinned `--repo`, `--client`, `--role` and `--proto` values. A session that asks
  for a different repo, client, role or root is refused before the protocol starts.
- On Windows, `ssh.exe` ships with Windows 10+; Strawberry Perl is the client Perl. A
  configured ssh `command` ending in `.cmd` or `.bat` is started through `cmd /d /c`,
  because `CreateProcess` cannot run a batch file itself. The child is spawned with
  `IPC::Open3`, which uses a native spawn on Windows rather than Perl's pseudo-`fork`,
  whose pipe handles the core documentation warns may not be duplicated faithfully.

### 10.2 Framing

Strictly lock-step request/response, one outstanding request at a time. This avoids
`select()` deadlocks and works on Windows pipes.

- Control messages: one JSON object per line (`\n`-terminated), no embedded newlines.
- Data: a JSON header with `"len": N` (the bytes on the wire) followed immediately by
  exactly N bytes, then the normal reply line from the peer. Chunks are 256 KiB. When the
  payload is at least 256 bytes and raw deflate makes it smaller, the header also carries
  `"z":1`; the peer inflates it before use. Incompressible and small payloads are sent
  unchanged, so a compressed frame is never larger than the original. A run's transfer
  report counts these on-wire payload lengths: data frames only, so JSON headers,
  acknowledgements and other control messages are excluded.
- All integers are decimal; timestamps are UTC epoch seconds; paths are relative, `/`-separated,
  and are opaque byte strings (UTF-8 encoded on Windows).

### 10.3 Session

```
C→S  {"cmd":"hello","proto":2,"client":"laptop-1","host":"laptop","os":"linux",
      "role":"client","repo":"documents","case_insensitive":false,"now":1792756800}
S→C  {"ok":true,"proto":2,"server":{"os":"linux"},"repo":{"name":"documents"},
      "policy":{"ignore":[...],"trash_days":30,"max_deletes":200}}

C→S  {"cmd":"manifest","part":0,"of":3,"entries":[
        {"p":"a/b.txt","t":"f","s":1234,"m":1792700000,"h":"<sha256>","mode":33188},
        {"p":"empty/dir","t":"d"}]}
S→C  {"ok":true,"need":1}

C→S  {"cmd":"plan"}                       # after the last manifest part
S→C  {"ok":true,"plan_id":"7f3a","actions":[
        {"a":"pull","p":"x.jpg","h":"<sha256>","s":99,"m":1792700000,"mode":33188},
        {"a":"push","p":"y.txt"},
        {"a":"delete_remote","p":"old.txt"},
        {"a":"delete_local","p":"gone.txt"},
        {"a":"conflict","p":"z.md","winner":"remote","loser_name":"z.conflict-laptop-1-20261022T101500Z.md"},
        {"a":"skip","p":"locked.docx","reason":"file in use"}],
      "warnings":["clock skew 312s"]}
```

Per action:

- `pull`: `C→S {"cmd":"get","p":...,"off":0,"max":262144}` → `S→C {"ok":true,"len":N,"eof":false}`
  + N bytes. Client hashes as it writes, fsyncs a temp file, renames into place, sets mtime,
  then `C→S {"cmd":"ack","p":...,"h":...}`.
- `push`: `C→S {"cmd":"put","p":...,"s":N,"h":...,"m":...,"mode":...}` →
  chunks as `{"cmd":"chunk","p":...,"len":N}` + bytes, server replies
  `{"ok":true,"off":N}` after each → `{"cmd":"chunk_end","p":...}` → server verifies the
  hash, fsyncs, renames, updates the index, replies `{"ok":true}`.
- `delete_remote` / `delete_local`: `{"cmd":"del","p":...}` → ack.
- `conflict`: encoded as the pair of actions it really is (`pull` or `push` for the winner,
  plus a client-side rename for the loser) with the conflict metadata attached. Conflicts
  use whole-file transfer, because the loser is renamed before the winner is written.

Both transfers have a delta form. The receiver first describes the file it already has:
one record per full block, a 4-byte weak checksum followed by the 32-byte SHA-256, so
`K` blocks are `36 × K` bytes. Block length is 16 KiB up to 64 MiB and grows beyond that so a
signature never exceeds 4,096 blocks. A file smaller than 64 KiB, an unrelated file, or a
missing local copy is not worth a signature and uses the whole-file form.

- **Delta pull** (the client already has an old version):
  `C→S {"cmd":"dsig","p":...,"b":N,"n":K,"h":"<sha256>"}` + the signature bytes →
  `S→C {"ok":true,"delta":1,"s":N,"m":...,"mode":...,"b":N}`, then the client asks for
  one record at a time with `{"cmd":"dop","p":...}`. Each reply is
  `{"ok":true,"op":"copy","off":N,"len":N}` (copy that range from the local file),
  `{"ok":true,"op":"lit","len":N}` + bytes (new content, compressed as above), or
  `{"ok":true,"done":1}`. The client hashes as it writes, verifies the size and hash,
  renames the temp file into place, and acks exactly as for `get`. If the delta would not
  be smaller than the file, the server answers `{"delta":0}` and the client uses `get`.
- **Delta push** (the server already has an old version):
  `C→S {"cmd":"sig","p":...}` → `S→C {"ok":true,"delta":1,"s":N,"b":N,"n":K}` + the
  signature bytes, or `{"delta":0}`. The client then sends
  `{"cmd":"delta","p":...,"s":N,"h":...,"m":...,"mode":...}` followed by
  `{"cmd":"dcopy","p":...,"off":N,"len":N}` and `{"cmd":"dlit","p":...,"len":N}` +
  bytes records, ending with `{"cmd":"delta_end","p":...}`. The server rebuilds the file
  from its current copy plus the literals, verifies the size and hash, and commits it with
  the same atomic rename as `put`. The journal records the push with `"delta":1`.

Matching is bounded: unchanged leading blocks are compared directly, and the remainder is
scanned with a rolling checksum for at most 8 MiB. Everything after that is sent literally,
which is still correct and still smaller than the file whenever the prefix or the scanned
part matched. A delta is only used when its literal bytes plus record overhead are smaller
than the file, so a wholly different file falls back to the whole-file form.

End of session:

```
C→S  {"cmd":"done","applied":[{"p":...,"h":...,"s":...,"m":...,"mode":...}]}
S→C  {"ok":true,"summary":{"pulled":3,"pushed":4,"deleted":1,"conflicts":1,"skipped":0},
      "base_written":true}
```

The server commits the new base atomically (`base.json.tmp` → `base.json`) only after all
actions for that path are acked. A dropped connection therefore leaves the base at the last
consistent point, and the next run re-derives the differences — sync is never resumed from
a questionable state.

### 10.4 Protocol errors

Unknown command, bad JSON, hash mismatch, oversized frame, a corrupt compressed payload, a
delta record outside the file, or a path that fails validation ⇒ the server replies
`{"ok":false,"error":"...","fatal":true}` and exits non-zero. The client aborts without
touching the base and reports the error; temp files are removed or cleaned by the next run.

## 11. Command-line interface

### 11.1 `filesync` (client)

| Command | Purpose |
| --- | --- |
| `init --repo NAME --root DIR --server USER@HOST --remote-repo NAME [--id ID] [--port N] [--identity FILE] [--role client\|replica] [--accept-host-key] [--known-hosts FILE] [--server-command PATH]` | Write config, create root + `.filesync-root`, print client id. |
| `sync [--repo NAME]... [--dry-run] [--force] [--verbose\|--quiet] [--json] [--no-prune] [--no-delta]` | Run a sync. Default: all repos. `--no-delta` forces whole-file transfer. |
| `status [--repo NAME] [--json]` | Last run per repo, pending local changes (stat-level), base size, trash size. |
| `verify [--repo NAME] [--deep]` | Hash the local tree against the cached base; report drift. |
| `log [--repo NAME] [-n N] [--since YYYY-MM-DD\|EPOCH] [--until YYYY-MM-DD\|EPOCH] [--exit N]... [--warnings] [--json]` | Recent local attempts (runs, failures and lock refusals), optionally in a time window, selected by exit code or by having warnings, and as JSON. |
| `settings [--config FILE] [--json]` | Effective process settings (7.4) with the file, section, variable or default each came from, plus each repo's resolved SSH identity, known-hosts file and remote program. |
| `prune [--repo NAME] [--dry-run]` | Prune trash beyond retention. |
| `restore PATH [--repo NAME] [--to DIR] [--list]` | Restore a path from the local trash. |
| `snapshot [--repo NAME] [--keep N]` | Replica only: hardlink snapshot of the mirrored tree. |
| `snapshot list \| snapshot restore DATE [PATH] [--to DIR]` | Inspect / restore snapshots. |
| `config path \| config show` | Print the config file location and its effective settings. |
| `version` | Version and protocol number. |

`restore` copies rather than moves, so the same version can be restored again, and refuses
to overwrite an existing path; `snapshot restore` replaces its target because it is a
rollback.

After a real run, `sync` prints a second line of per-run transfer accounting:

```
documents: pulled 1, pushed 1, deleted 0, conflicts 0
  transfer: sent 1,652 B, received 864 B, 1 file by delta (1 pushed)
```

`sent` and `received` are the payload bytes that crossed the connection in each direction,
counted after compression and excluding control messages, so they show what the link
actually carried. The delta figure counts files that moved as a delta rather than whole,
with the direction breakdown when either count is non-zero; a settled run reports zeros,
and a dry run prints no transfer line because it sends no file payloads. Past runs keep
the same figures in `filesync log`.

Exit codes (both binaries): `0` success (changes or none), `1` fatal error, `2` another run
holds the lock, `3` completed with warnings (conflicts, skipped files), `4` verification
failure. Cron mails anything non-zero that produces output; `--quiet` suppresses the
"nothing to do" line only.

### 11.2 `filesync-admin` (server)

| Command | Purpose |
| --- | --- |
| `repo create NAME [--trash-days N] [--max-deletes N] [--ignore PATTERN]...` | Create master dir + metadata. |
| `repo list \| repo show NAME \| repo delete NAME [--purge-data]` | Manage repos. `delete` refuses without `--purge-data`. |
| `repo set NAME key=value` | Retention, limits, ignore list, `preserve_mode`, `allow_symlinks`. |
| `client list [NAME] \| client show ID \| client allow ID [--role R] \| client forget ID` | Manage allowlist and bases (`forget` forces the next run to be a join). |
| `verify NAME [--deep] [--sample N] [--json]` | Rehash master against the index; report missing/extra/modified. |
| `reindex NAME [--dry-run] [--json]` | Rebuild `master.json` from the tree, hashing every file (after a manual repair or restore). `--dry-run` reports what would be indexed and writes nothing; skipped paths are named. `--json` prints the same counts, the dry-run/written flags and a `skipped` path map. |
| `restore NAME PATH [--to DIR] [--list] [--date YYYY-MM-DD]` | Restore from server trash into the master (or `--to` an export); rebuilds the index and is journaled. |
| `prune NAME [--dry-run]` | Prune trash. |
| `log NAME... [-n N] [--client ID] [--since DATE] [--until DATE] [--exit N]... [--warnings] [--json]` | Query one or more journals, optionally in a time window, by session exit code or by sessions that kept conflict copies, as text or JSON. |
| `stats NAME` | Files, bytes, per-client last run, trash size, conflict count. |

`filesync-server` is not intended for interactive use; it is the forced command.

### 11.3 Examples

```sh
# server, once
sudo useradd --system --create-home filesync
sudo -u filesync filesync-admin repo create documents
sudo -u filesync filesync-admin client allow laptop-1 --role client
sudo -u filesync filesync-admin client allow backup-1 --role replica

# client
filesync init --repo documents --root ~/Documents \
    --server filesync@files.example.com --remote-repo documents --id laptop-1
filesync sync --repo documents --dry-run
filesync sync --repo documents

# cron on the client
*/15 * * * * /usr/local/bin/filesync sync --quiet >/dev/null

# backup host: snapshot, then mirror
0 2 * * * /usr/local/bin/filesync snapshot --repo documents --keep 14
30 2 * * * /usr/local/bin/filesync sync --repo documents --quiet
```

Windows clients use a scheduled task rather than cron.  With the script in
`C:\filesync` and Strawberry Perl installed, the same job is set up from a
command prompt:

```bat
REM once, on the client
C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync init ^
  --repo documents --root C:\Users\foo\Documents --server srv

REM then create the task; it runs every minute as the current user
schtasks /Create /SC MINUTE /MO 1 /TN FileSync /F ^
  /TR "C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync sync --repo documents --quiet"
```

The task runs only while that user is logged on, which suits a Documents
folder; its run log is still written under `%USERPROFILE%\.filesync\logs`, so
`filesync log --repo documents --warnings` works there too.

## 12. Safety and failure handling

| Risk | Mitigation |
| --- | --- |
| Two cron runs overlap | `flock` on a per-repo lock file, client and server; default fail-fast (exit 2), `--wait N` optional. |
| Empty/misconfigured root wipes the master | `.filesync-root` marker must exist; missing marker or missing root = fatal before any plan. |
| Bulk deletion (bad restore, wrong drive) | `max_deletes` (default 200) and `max_delete_percent` (default 10% of base) abort the plan unless `--force`; the abort happens before anything is deleted. |
| Partial transfer | temp file in the target directory, hash verified, fsync, then `rename`; temp files are cleaned at session start. |
| Interrupted run | base committed only for completed paths; next run recomputes. |
| Server crash mid-write | atomic rename; no master file is ever half-written. |
| Destination full | pre-flight free-space check (`pull_bytes × 1.1`); abort before writing. |
| Path traversal from a hostile client | every path validated: relative, no `..`, no NUL, no absolute or drive prefix; server resolves each parent with `lstat` and refuses symlinked components (unless `allow_symlinks`); final path must be inside the master. |
| Client impersonation | SSH key + `command=` pins repo/client/role; `hello` must match. |
| Clock skew | server compares client `now` with its own; warns beyond 5 minutes; conflict ties go to the master, so skew cannot cause flapping. |
| Case-insensitive client | probe at startup; two master paths differing only in case are reported and skipped on that client, never silently overwritten. |
| File open/locked (Windows) | per-file `skip` with a warning, exit 3, retried next run — never a hard failure. |
| Disk full or permission error mid-plan | stop the plan, keep the base consistent for completed paths, report each failure. |

## 13. Cross-platform rules

| Topic | Unix client | Windows client |
| --- | --- | --- |
| Paths | native, bytes as returned by the OS | UTF-8 encoded for the protocol, `/` internally, `\` only at the OS boundary |
| Case | sensitive | insensitive: detected by probe; collisions reported |
| Reserved names (`CON`, `NUL`, `COM1`…, trailing dot/space, `<>:"\|?*`) | n/a | incoming paths that cannot be represented are skipped with a warning, never renamed silently |
| mode | preserved | not applied on the client; master keeps existing mode on push |
| symlinks | skipped by default (`allow_symlinks` opt-in; never followed out of the root) | not supported; skipped |
| mtime granularity | 1s or better | FAT: 2s — comparison tolerance 2s, mtimes still set where possible |
| locks | `flock` | `flock` emulation (LockFileEx) via PerlIO |
| scheduler | cron | Task Scheduler (`schtasks`) |
| line endings | untouched — files are byte streams | untouched (no CRLF conversion) |

macOS is supported as a Unix client; `.DS_Store`/`._*` are ignored by default and NFD/NFC
path normalisation is not applied (paths are opaque), with normalisation collisions reported
like case collisions.

## 14. Security model

- Server: a dedicated unprivileged account, `filesync`, owning `/srv/filesync`. Nothing runs
  as root; no setuid, no sudo.
- `authorized_keys` entries use `restrict` and a forced `command=`, so a stolen client key
  can only run a sync session for its own repo and client id.
- One key per client (and one for the replica). Revocation = remove the line.
- The replica connects to the server; the server holds no credentials to the replica. A
  compromised server cannot reach into the backup host.
- The replica role is enforced server-side: `role=replica` gets a pull-only plan; any push,
  put or delete attempt is a fatal protocol error.
- The journal records every write, delete, conflict and restore with client id, timestamp,
  path, size and hash — enough to audit what a client did.

## 15. Logging, status and observability

- **Journal** (server, JSONL, one line per action, monthly files, 12-month retention):
  `{"ts":"...","client":"laptop-1","action":"push","path":"a.txt","size":12,"sha256":"...","result":"ok"}`.
  Partial trailing lines are tolerated on read. A finished session is journalled as
  `{"action":"session","result":"ok","exit":0,...}` with the run's counts (`exit` is 3
  when the session kept conflict copies, matching the client); a session that
  never reached the end is recorded with `result: "error"`, `exit: 1` and its reason, and a
  refusal because another session holds the repo lock with `exit: 2`, `locked: true` and the
  reason - the same codes the client run log uses. `filesync-admin log` takes `--since`,
  `--until` (a date means through 23:59:59 UTC that day) and repeatable `--exit N`, which
  selects session outcomes (action entries carry no exit code), plus `--warnings`, which
  keeps session outcomes with a non-zero `conflicts` count - the server-side counterpart
  of the client filter. A plan event's planned conflicts do not count, since the session
  outcome records whether the copies were kept. All filters apply before `-n`. Failures
  before the repo store exists (a bad hello, say) are logged but not journalled, and dry
  runs write no session entry. `filesync-admin log NAME... --json`
  prints `{"results":[{"repo","path","client","since","until","exits","warnings","events":[...]}]}`,
  one result per named repo in the order given, where `path` is its journal directory and
  `events` are the journal objects in read order; the filter keys appear only when they
  were given (`since` and `until` as epochs, `exits` as a list, `warnings` as `1`). With
  several names the text output heads each group with `NAME:` and indents its lines; a
  single name prints the lines unadorned, as before. Each repo gets its own `-n` limit. An empty selection prints an
  empty `events` list rather than the text-mode "No journal entries" message.
- **Diagnostics** (`Log::Abstraction`): warnings and errors to standard error by default,
  `%level%: %message%`, configurable through 7.4. The client logs the plan at `debug` and
  the finished run at `info`; the server logs session open/finish at `info`, the plan at
  `debug`, and a refusal at `error`. `error()` never dies: a logged failure is still a
  reported failure, not a second one. `--verbose` selects `debug`, `--quiet` selects
  `error` for that run.
- `filesync status` prints per repo: transport, the last successful run's timestamp and
  its transfer accounting (payload bytes each way and files by delta), and the number of
  local files, all from the cache without hashing; `--json` carries the whole last summary.
  A cache written before byte accounting existed simply omits the transfer line.
- **Client run log**: every attempt appends `{ts, exit, summary, warnings, dry_run}` to
  `~/.filesync/logs/<repo>.jsonl`, trimmed to the newest 500 entries. The summary carries
  `pulled`, `pushed`, `deleted`, `conflicts` and `skipped`, plus `delta_pulled` and
  `delta_pushed` — the number of files that moved as a delta rather than whole — and
  `bytes_sent`/`bytes_received`, the on-wire payload totals. `filesync log` reads it
  back and repeats the transfer figures, so an overnight conflict or an unexpectedly
  large transfer can be audited without the server. A fatal failure is
  recorded with `exit` 1 and an `error` string; a lock refusal (client-held or server-held)
  with `exit` 2, `locked: true` and its reason, so the audit shows what cron tried even when
  nothing ran. A torn final line from a killed run is skipped and the next entry starts on a
  line of its own. Dry runs are recorded too, and are marked.
  `--since` (a `YYYY-MM-DD` date, UTC midnight, or an epoch) drops older entries and
  `--until` (a date means through 23:59:59 UTC that day) drops newer ones, both before `-n`;
  `--exit N` (repeatable) keeps only that exit code; `--warnings` keeps attempts that
  recorded at least one warning (a conflict or a skipped path), so they can be found
  without knowing they exit 3. All filters apply before `-n` and compose. `--json` prints
  `{"results":[{"repo","path","since","until","exits","warnings","runs":[...]}]}`, one
  result per repo, with the filter keys present only when they were given.
- `--json` on `status`, `sync`, `verify` and `log` for machine consumption.
- No metadata, lock or temp file is ever created inside `master/`, so after a run
  `find master -name '.filesync*'` returning nothing is a valid health check.

## 16. Performance targets

Measured on the reference test corpus (see §18):

| Metric | Target |
| --- | --- |
| No-change run, 50,000 files | < 60 s end to end (stat walk + manifest + plan), no file hashed |
| No-change run, 5,000 files | < 5 s |
| Memory | < 200 MB for 200,000 files; files are streamed, never slurped |
| Transfer | ≥ 10 MB/s on a LAN, 256 KiB chunks, one SSH connection per run |
| Concurrent clients | 8 clients against one repo serialised by the repo lock; a waiting client exits 2 rather than queueing indefinitely |
| Repo size | documented limit 200,000 files / 1 TB per repo (beyond that, split repos) |

Delta transfer changes what a second edit costs. A 1 GB file whose edit is near the start
reuses the unchanged leading blocks and sends the changed region plus at most 8 MiB of
scanned content literally; an edit near the end is mostly prefix copies. A wholly different
file, a file below 64 KiB, a missing local copy and conflicts fall back to whole-file
transfer. Deflate is applied per payload, so text shrinks and already-compressed media is
sent unchanged. The 256 KiB chunk target still applies to the literal parts.

## 17. Packaging and dependencies

- Distribution `App::FileSync` (directory `App-FileSync`), layout:

  ```
  App-FileSync/
  ├── Makefile.PL          # generated from cpanfile conventions used elsewhere in this tree
  ├── cpanfile
  ├── bin/filesync
  ├── bin/filesync-server
  ├── bin/filesync-admin
  ├── lib/App/FileSync.pm
  ├── lib/App/FileSync/{Config,Delta,Index,Ignore,Scan,Merge,Protocol,Transport,Store,Trash,Journal,Snapshot,Settings,Lock,CLI,Server,Admin}.pm
  ├── t/*.t
  └── .github/workflows/ci.yml
  ```

- Dependencies are all core or pure-Perl CPAN: `Getopt::Long`, `JSON::PP`, `Digest::SHA`,
  `Compress::Raw::Zlib`, `File::Find`, `File::Path`, `File::Copy`, `File::Spec`,
  `File::Temp`, `File::Basename`, `Fcntl`, `POSIX`, `Time::Local`, `Time::HiRes`, `Encode`,
  `IO::Handle`, `IPC::Open3`, plus `Log::Abstraction` and `Object::Configure` (which bring
  `Config::Abstraction`, `Log::Log4perl`, `Params::Get` and friends). Compression uses the
  `Compress::Raw::Zlib` that ships with Perl (XS, but prebuilt on every supported platform),
  so Windows/Strawberry still installs without a compiler.
- Optional: `Test::More`, `Test::Deep`, `Test::Exception` for the suite.
- Perl 5.20 minimum; developed on 5.40.
- `cpanm --installdeps .` installs nothing exotic; `make test` runs the suite.

## 18. Testing plan

### 18.1 Unit tests

- Merge table: every row of §8.2, plus type changes and first-sync joins, as a
  table-driven test over synthetic manifests.
- Conflict naming (extension preservation, names with dots, spaces, UTF-8, very long names).
- Ignore-pattern matching, including `**`, negation, segment matching.
- Path validation (§12) — `../`, absolute, `C:\`, NUL, embedded newline, symlinked parent.
- Trash retention boundary (exactly N days, DST/local midnight).
- Delta: signatures and rolling-checksum matching rebuild a file after insertions,
  replacements and deletions; an unchanged file is nearly all copies; an unrelated file is
  all literals; a truncated record is refused. Protocol compression round-trips text,
  random bytes, empty and tiny payloads, and leaves control messages alone.
- Journal reader with a truncated final line.
- Case/normalisation collision detection.
- Base commit/rollback: kill the session between actions, assert no false base entries.

### 18.2 Integration tests (no network)

A `Local` transport spawns `filesync-server` as a child process over pipes. Each test builds
a temp server root and 1–3 client roots, then asserts on trees and exit codes:

1. Create/modify/rename/delete on one client and on the server; converge after one run.
2. Two clients editing the same file: newest wins, both keep an identical conflict copy,
   a third client receives winner + copy.
3. Delete vs modify both ways (rows 8, 9): file resurrected, warning recorded, nothing lost.
4. Delete on client → trash on server; `restore` brings it back; prune removes it after
   retention.
5. Interrupted transfer: kill the client mid-`put`; master unchanged, no temp files, next run
   completes.
6. Lock contention: second run exits 2 without touching anything.
7. `--dry-run` performs zero writes (compare full tree hashes and mtimes before/after).
8. Idempotency: second identical run transfers zero bytes, base unchanged.
9. Replica: mirror matches master exactly; a push attempt by the replica is refused; delete
   on master moves the replica copy to replica trash; snapshot restore recovers an old
   version.
10. Bulk-deletion guard: deleting 300 of 1,000 files aborts without `--force`. A replica
    whose base survives is refused by the percentage rule when the master loses most of its
    files: the refusal names the count, the baseline and the percentage, the local mirror
    and stored base are untouched, and `--force` completes the mirror. Deletions at exactly
    the percentage allowance are allowed through: the replica removes those files to its
    trash and converges without `--force`; one more than the allowance (three of twenty) is
    refused and needs `--force`. The same pair holds for a normal client with a surviving
    base in both directions: two of twenty local deletions propagate to the master and
    three are refused before the master or the stored base is touched; two master-side
    deletions reach the client's tree and trash, and three are refused before the client
    removes anything. Where the percentage floors to zero on a small base, one deletion is
    still allowed and two are refused, so the tool stays usable without permitting a
    two-file batch. The same holds for a nine-file base, the largest base whose ten percent
    still floors to zero; ten files first reach an allowance of one.
11. Missing marker (simulated unmounted drive) aborts before any plan is sent.
12. Windows-specific suite (Strawberry on CI): reserved names, 2s mtime tolerance,
    case-only collision, locked file skipped with exit 3.
13. Unicode and awkward filenames: spaces, quotes, newlines, emoji, 255-byte names.
14. 50,000-file corpus for the timing targets in §16.
15. Delta transfer: a one-block edit to a large file is pushed and pulled with only the
    changed blocks (`delta_pushed`/`delta_pulled` in the run summary), and the transfer
    report's byte totals are smaller than the file while a settled run reports zero; the
    journal records the push with `"delta":1`; a small file, a missing local copy and
    `--no-delta` take the whole-file path and still converge.
16. First sync (join), covering both documented procedures: a dry run on two populated
    trees plans the merge and writes nothing; the real run pulls master-only files, pushes
    client-only files, resolves both same-path disagreements by §8.3 while keeping each
    losing version as a conflict copy, and those copies propagate on later runs. An empty
    root pulls the master with no conflicts, and only files added afterwards are pushed. A
    client whose server-side base was removed with `filesync-admin client forget` rejoins
    the same way, reproducing the merge and its conflict copies. A forgotten replica
    rejoins as a mirror: local edits are overwritten, local extras and master-deleted
    files are removed, no push is attempted, and no conflict copy is kept. When the
    master is empty, the absolute `max_deletes` guard still refuses to wipe the local
    mirror; `--force` is needed to complete that deletion.
17. Reindex: a hand-repaired master drifts from its index; `--dry-run` reports what would
    be indexed, writes nothing and journals nothing; the real run hashes every file, indexes
    empty directories, drops deleted paths, journals the run, and `verify --deep` is clean.
    `--json` carries the counts, dry-run/written flags and the skipped path map. A held repo
    lock refuses the reindex, and a skipped symlink is named rather than dropped silently.

### 18.3 SSH integration (Linux CI, optional locally)

Real `sshd` on a high port in a container, `authorized_keys` with the forced command;
verifies the forced-command binding, replica push refusal, and that a `hello` mismatch is
rejected. Not required for `make test`; run in CI and before release.

### 18.4 Acceptance criteria

The implementation is accepted when:

1. `make test` passes on Linux and Windows (client side), including 100% of the merge table.
2. Two clients, a server and a replica reach identical trees after any sequence of
   create/modify/delete/conflict operations, within two runs (usually one).
3. No test loses data: for every version written during the suite, the bytes are findable in
   master, trash, a conflict copy, or a snapshot.
4. `--dry-run` provably writes nothing.
5. A no-change run on 50k files meets the §16 target on the reference machine.
6. Kill -9 of client or server mid-run never leaves a partial master file or a base that
   claims an action that did not happen.
7. Documentation covers install, key setup, cron/Task Scheduler, restore, and the
   troubleshooting runbook.

## 19. Implementation phases

| Phase | Content | Deliverable |
| --- | --- | --- |
| 1 | Skeleton, config, scan/hash cache, ignore, index, merge engine, Local transport, push/pull/delete/trash, unit tests | `filesync sync` works between two local dirs |
| 2 | Protocol over ssh, forced-command setup, locking, journal, `init`/`status`/`log`/`verify`, bulk-delete guard | Real client ↔ server sync via cron |
| 3 | Replica role, mirror semantics, snapshots, `verify`, `restore`, admin CLI | Server + backup host in production |
| 4 | Windows/macOS polish, packaging, CI matrix, docs and runbook | Release 1.0 |

Each phase ends with tests and a working demo; nothing is deferred to "later" silently.

## 20. Decisions taken (from review discussion)

| Question | Decision |
| --- | --- |
| Concurrent edits | Newest mtime wins; loser preserved as a conflict copy on both sides; ties go to the master. |
| Deletions | Propagate, but as moves into a date-bucketed trash with retention (default 30 days). |
| Client–server transport | Pure-Perl sync protocol over SSH; `ssh` is the only external binary. |
| Transfer optimisation | Deflate each data payload when it shrinks; rsync-style block signatures for files of at least 64 KiB, with an 8 MiB scan limit and a whole-file fallback. |
| Client platforms | Linux, macOS and Windows. |
| Name and location | Distribution `App::FileSync`, source `~/njh/src/njh/App-FileSync`. |

## 21. Open points for your approval

1. **Conflict copies are inline and never auto-deleted.** Is that acceptable, or should they
   live under a `.filesync/conflicts/` directory instead?
2. **Replica snapshots** (hardlink, 14-day default) are an addition beyond "a backup copy";
   they protect against a corrupted master propagating. Keep them?
3. **Ignore list is server-side only** (one policy for all clients). Per-client excludes are
   deliberately not offered because they are indistinguishable from deletions.
4. **`max_deletes` defaults** (200 files / 10%) — appropriate for your trees?

Phase 1 is implemented and covered by the test suite (`make test`); phase 2 (the SSH
transport and forced-command setup) is next, and each phase will be demonstrated with
tests before moving on.
