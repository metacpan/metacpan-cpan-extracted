## Name

App::FileSync - cron-driven file synchronisation without a daemon

## Synopsis

```
filesync init --repo documents --root ~/Documents \
    --transport local --server-root /srv/filesync --remote-repo documents
filesync sync --repo documents --dry-run
filesync sync --repo documents
```

## Description

App::FileSync keeps one directory per client in step with a master copy on a server, and
keeps a separate machine holding a replica of that master.  Every run is a short-lived CLI
process suitable for cron or the Windows Task Scheduler: there is no daemon, no database
and no web interface.

Only files whose content changed are transferred.  Data frames are deflated when that
makes them smaller, and files of at least 64 KiB are sent as rsync-style block deltas
when the other side already holds an older copy, so an edit moves the changed blocks
rather than the whole file.  `filesync sync --no-delta` forces whole files.  Each run
reports the payload bytes it sent and received and how many files moved as a delta, and
`filesync log` repeats those figures for past runs.

This module holds the pieces shared by the client, the server and the admin tools:
byte-transparent JSON, path validation, conflict-copy naming and atomic file writes.

## Functions

### Json\_Encode

### Json\_Decode

Encode and decode a structure as a single line of JSON.  Paths are byte strings and are
not treated as UTF-8 by these functions.

### Validate\_Relpath

Returns `(1, undef)` for a safe relative path, or `(0, $reason)`.  Absolute paths,
backslashes, control characters, empty, `.` and `..` components, and paths longer than
4096 bytes or with a component longer than 255 bytes are rejected.

### Validate\_Repo\_Name

### Validate\_Client\_Id

Return `(1, undef)` for a name usable as a directory name (`[A-Za-z0-9][A-Za-z0-9._-]*`,
at most 64 characters), or `(0, $reason)`.

### Conflict\_Name

```perl
my $name = conflict_name('notes.txt', 'laptop-1', time);
```

Returns the conflict-copy name for a losing version: the original name with
`.conflict-<client>-<timestamp>` inserted before the extension.

### Format\_Utc

Formats an epoch as `YYYYMMDDTHHMMSSZ`.

### Write\_Atomic

Writes a file through a temporary file in the same directory and renames it into place.

## Examples

On the server, create the master copy and allow the client once.  Then, on each
client, register the directory and add a cron entry that runs every minute:

```
# once, on the client
filesync init --repo documents --root /home/foo/Documents --server srv

# crontab -e, for foo on each client
* * * * * /usr/local/bin/filesync sync --repo documents --quiet >/dev/null
```

The summary line is dropped so cron does not mail on every successful run;
diagnostics still go to standard error, so a failure is mailed.  Every attempt,
successful or not, is also appended to `~/.filesync/logs/documents.jsonl`, and
`filesync log --repo documents --exit 1` lists the ones that failed.

Windows clients use a scheduled task rather than cron.  With the script in
`C:\filesync` and Strawberry Perl installed, the same job is set up from a
command prompt:

```
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

The master copy on the server is an ordinary directory tree, so it can be
mirrored to a backup directory from the same crontab:

```
# crontab -e, for foo on the server
* * * * * rsync -a --delete --exclude '.filesync-tmp-*' \
    /home/foo/FileSync/ /home/foo/backups/FileSync/
```

Filesync writes each file to a temporary name and renames it into place, so the
mirror never catches a half-written upload; the exclusion keeps the temporary
files themselves out of the backup.  `--delete` makes the copy a mirror: a
deletion that reaches the master also removes the backed-up file.

To restore the master from that backup, stop the client jobs (comment out their
cron lines, or disable the scheduled task) and the server's backup job, so the
backup job cannot copy a half-restored tree back into the backup.  Let any
running sync finish, then mirror the backup back:

```
rsync -a --delete --checksum /home/foo/backups/FileSync/ /home/foo/FileSync/
```

`--checksum` compares the contents, so a restored file is not skipped just
because its size and modification time happen to match the newer copy.  This is
a rollback rather than a merge: files created after the backup was taken
disappear from the master, and the next sync propagates that to the clients, so
copy anything you need to keep out of the tree first.  The server
would rehash the restored files on the next session anyway, but
`filesync-admin reindex` rebuilds the index immediately, before any client
reconnects; clients then pull the restored versions, merging edits they have not
synced as usual.

Before re-enabling the jobs, check that the copy is exact with a read-only
comparison against the backup:

```
rsync -a --delete --checksum --dry-run --itemize-changes \
    /home/foo/backups/FileSync/ /home/foo/FileSync/
```

No output and exit 0 mean the master matches the backup.  Any line beginning
`>f` names a path that still differs, and `*deleting` names one the
rollback should have removed.  The index still describes the pre-rollback tree,
so `filesync-admin verify` may report drift at this point; that is expected.
Rebuild it and check it:

```
sudo -u filesync filesync-admin reindex documents
sudo -u filesync filesync-admin verify documents --deep
```

`reindex` hashes every file in the master and replaces the index atomically; it
refuses to run while a sync session holds the repo lock, and it names any paths
it could not index.  `clean` and exit 0 from `verify` confirm that the master
and its index agree.  Re-enable the jobs once that check passes.

To restore just one file or directory, copy that path back instead of mirroring
the whole tree, with the jobs paused as above so nothing changes the tree while
the copy runs:

```
rsync -a --checksum /home/foo/backups/FileSync/notes/plan.txt /home/foo/FileSync/notes/
rsync -a --checksum /home/foo/backups/FileSync/photos/ /home/foo/FileSync/photos/
```

The trailing slash on the second source copies the directory's contents; without
it rsync would put the directory itself inside the destination.  Add `--delete`
only when that directory should match the backup exactly, since it removes files
created after the backup was taken.  Everything outside the restored paths is
left alone; refresh the index with `reindex` as above, or let the next session
do it, and clients pull the restored versions.  Check the restored paths with the
matching `rsync --dry-run --itemize-changes` comparison before re-enabling the
jobs; no output means they match the backup.

Adjust `/usr/local/bin/filesync` to where the script was installed, because
cron's default PATH rarely includes a per-user Perl bin directory.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/App-FileSync/coverage/)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
