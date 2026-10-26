## Name

App::FileSync - cron-driven file synchronisation without a daemon

## Version

0.001.5

## Synopsis

```
    filesync-admin --root ~/filesync repo create documents
    filesync init --repo documents --root ~/Documents \
            --transport local --server-root ~/filesync --remote-repo documents
    filesync sync --repo documents --dry-run
    filesync sync --repo documents
```

## Description

App::FileSync keeps a directory on each client in step with one master copy on
the server.  Clients never talk to each other: each pushes its changes to the
master and pulls everyone else's from it, so a change made on one client - a
new file, an edit or a deletion - reaches the others on their next run.  Any
number of clients can share a repo this way.

A separate machine can hold a replica of the master.  Every run is a
short-lived CLI process suitable for cron or the Windows Task Scheduler: there
is no daemon, no database and no web interface.

Only files whose content changed are transferred.  Data frames are deflated when that
makes them smaller, and files of at least 64 KiB are sent as rsync-style block deltas
when the other side already holds an older copy, so an edit moves the changed blocks
rather than the whole file.  `filesync sync --no-delta` forces whole files.  Each run
reports the payload bytes it sent and received and how many files moved as a delta, and
`filesync log` repeats those figures for past runs.

Every message the tools print is looked up in a catalogue
([App::FileSync::I18N](https://metacpan.org/pod/App%3A%3AFileSync%3A%3AI18N)), so a translation is one new catalogue.

This module holds the pieces shared by the client, the server and the admin tools:
byte-transparent JSON, path validation, conflict-copy naming and atomic file writes.

## Functions

### Json\_Encode

Purpose: encode a structure as one line of canonical JSON.

Args: `$data`, any JSON-encodable value.

Returns: the JSON text, keys sorted, with no trailing newline.

Side Effects: none.

Usage:

```
    print {$fh} json_encode($event), "\n";
```

#### Example

```perl
    print json_encode({ b => 1, a => [ 'x' ] }), "\n";      # {"a":["x"],"b":1}
```

#### Api Specification

##### Input

```perl
    [ { name => 'data', type => 'scalar', optional => 1 } ]
```

##### Output

```perl
    { type => 'string', min => 1 }
```

#### Messages

JSON::PP's own error for a value it cannot encode (a code reference, say).

#### Formal Specification

```
    json_encode : VALUE → TEXT
    json_decode(json_encode(v)) = v
```

### Json\_Decode

Purpose: decode one JSON document, keeping strings as byte strings.

Args: `$text`.

Returns: the decoded structure.  Strings that fit in bytes are downgraded, so a
path read back from JSON names the same file as the bytes it was written from.

Side Effects: none.

Usage:

```perl
    my $config = json_decode(read_text($path));
```

#### Example

```perl
    my $entry = json_decode('{"p":"caf\u00e9.txt"}');
    print length($entry->{p}), "\n";        # 8 (bytes), not 9
```

#### Api Specification

##### Input

```perl
    [ { name => 'text', type => 'string' } ]
```

##### Output

```perl
    { type => 'scalar', optional => 1 }
```

#### Messages

JSON::PP's own error for malformed JSON.

#### Formal Specification

```
    json_decode : TEXT ↛ VALUE
    ∀ s : STRING in result • ¬ utf8_flag(s) ∨ ∃ c ∈ s • ord c > 255
```

### Validate\_Relpath

Purpose: decide whether a path is safe to join to a sync root.

Args: `$path`, a relative path as it travels on the wire.

Returns: a two-element list `(1, undef)` for a usable path, or
`(0, $reason)` where `$reason` is a translated explanation.  (A list rather
than a reference because every caller destructures it at once, and it is
called once per path in the tree.)

Side Effects: none.

Usage:

```perl
    my ($ok, $reason) = validate_relpath($path);
```

#### Example

```perl
    my ($ok, $why) = validate_relpath('notes/../secret');
    print "$why\n" unless $ok;      # parent path component
```

#### Api Specification

##### Input

```perl
    [ { name => 'path', type => 'scalar', optional => 1 } ]
```

##### Output

```perl
    { type => 'arrayref', min => 2, max => 2 }
```

#### Messages

```
    Key                       Meaning
    path.missing              no path was given
    path.not_text             the path is a reference
    path.empty                the path is empty
    path.too_long             longer than 4096 bytes
    path.absolute             starts with /
    path.drive                starts with a drive letter
    path.backslash            contains a backslash
    path.nul                  contains a NUL byte
    path.control              contains a control character
    path.empty_component      contains //, or starts or ends with /
    path.dot_component        has a . component
    path.parent_component     has a .. component
    path.component_too_long   a component is longer than 255 bytes
```

Resolution: rename the file on the side that holds it.

#### Formal Specification

```
    SafePath == { p : seq BYTE |
            0 < #p ≤ 4096 ∧ head p ≠ '/' ∧ ¬ drive(p) ∧
            '\' ∉ ran p ∧ ran p ∩ CONTROL = ∅ ∧
            ∀ c : split('/', p) • c ∉ {⟨⟩, ".", ".."} ∧ #c ≤ 255 }
    validate_relpath(p) = (1, ⊥)        if p ∈ SafePath
                        = (0, reason)   otherwise
```

#### Pseudocode

```
    reject undef, references and empty strings
    reject paths over 4096 bytes
    reject absolute, drive-relative, backslash, NUL and control characters
    for each "/"-separated component:
            reject empty, ".", ".." and components over 255 bytes
    accept
```

### Validate\_Repo\_Name

Documented with ["validate\_client\_id"](#validate_client_id) below.

### Validate\_Client\_Id

Purpose: decide whether a repo name or client id is usable as a directory name.

Args: `$value`.

Returns: `(1, undef)`, or `(0, $reason)` with a translated reason.  The
alphabet is `[A-Za-z0-9][A-Za-z0-9._-]*`, at most 64 characters.

Side Effects: none.

Usage:

```perl
    my ($ok, $reason) = validate_client_id($id);
```

#### Example

```perl
    my ($ok, $why) = validate_repo_name('../etc');
    print "$why\n"; # bad repo name '../etc'
```

#### Api Specification

##### Input

```perl
    [ { name => 'value', type => 'scalar', optional => 1 } ]
```

##### Output

```perl
    { type => 'arrayref', min => 2, max => 2 }
```

#### Messages

```perl
    Key           Meaning                         Resolution
    id.missing    no value was given              supply one
    id.not_text   the value is a reference        pass a string
    id.empty      the value is empty              supply one
    id.too_long   longer than 64 characters       shorten it
    id.bad        outside the allowed alphabet    use letters, digits, . _ -
```

#### Formal Specification

```
    Id == { s : seq CHAR | 0 < #s ≤ 64 ∧ head s ∈ ALNUM ∧ ran s ⊆ ALNUM ∪ {'.','_','-'} }
    validate(s) = (1, ⊥) if s ∈ Id, (0, reason) otherwise
```

### Parse\_Since

Purpose: the start of a time window.

Args: `$value` (`YYYY-MM-DD` or an epoch), optional `$option` naming the
command-line option for the error message (default `--since`).

Returns: the epoch, or `undef` when `$value` is undef.  A date means
midnight UTC that day.

Side Effects: none.

Usage:

```perl
    my $since = parse_since($opts{since});
```

#### Example

```
    print parse_since('2026-10-22'), "\n";  # 1792627200
```

#### Api Specification

##### Input

```perl
    [
            { name => 'value',  type => 'string', optional => 1 },
            { name => 'option', type => 'string', optional => 1 },
    ]
```

##### Output

```perl
    { type => 'integer', optional => 1, min => 0 }
```

#### Messages

```perl
    Key        Meaning                              Resolution
    when.bad   neither a date nor an epoch          use YYYY-MM-DD or digits
```

#### Formal Specification

```
    parse_since : (DATE ∪ ℕ ∪ {⊥}) ↛ ℕ ∪ {⊥}
    parse_since(n) = n ; parse_since(d) = midnight_utc(d) ; parse_since(⊥) = ⊥
```

### Parse\_Until

Purpose: the end of a time window.

Args: as for ["parse\_since"](#parse_since) (default option name `--until`).

Returns: the epoch, or `undef`.  A date means the last second of that day, so
`--until 2026-10-22` includes that day's runs.

Side Effects: none.

Usage:

```perl
    my $until = parse_until($opts{until});
```

#### Example

```
    print parse_until('2026-10-22'), "\n";  # 1792713599
```

#### Api Specification

##### Input

```perl
    [
            { name => 'value',  type => 'string', optional => 1 },
            { name => 'option', type => 'string', optional => 1 },
    ]
```

##### Output

```perl
    { type => 'integer', optional => 1, min => 0 }
```

#### Messages

```perl
    Key        Meaning                              Resolution
    when.bad   neither a date nor an epoch          use YYYY-MM-DD or digits
```

#### Formal Specification

```
    parse_until(n) = n ; parse_until(d) = midnight_utc(d) + 86399 ; parse_until(⊥) = ⊥
```

### Format\_Utc

Purpose: a compact UTC timestamp.

Args: optional `$epoch` (default now).

Returns: `YYYYMMDDTHHMMSSZ`.

Side Effects: none.

Usage:

```perl
    my $stamp = format_utc($run->{ts});
```

#### Example

```
    print format_utc(0), "\n";      # 19700101T000000Z
```

#### Api Specification

##### Input

```perl
    [ { name => 'epoch', type => 'number', optional => 1 } ]
```

##### Output

```perl
    { type => 'string', matches => qr/\A\d{8}T\d{6}Z\z/ }
```

#### Messages

None.

#### Formal Specification

```
    format_utc : ℕ → STAMP
    format_utc(e) = yyyy mm dd 'T' HH MM SS 'Z' of gmtime(e)
```

### Split\_Name

Purpose: split a relative path into directory, stem and extension.

Args: `$path`.

Returns: an arrayref `[ $dir, $stem, $ext ]`; `$dir` has no trailing slash
and is empty at the top level, `$ext` includes its dot and is empty when there
is none.  A leading dot (`.profile`) is part of the stem.

Side Effects: none.

Usage:

```perl
    my ($dir, $stem, $ext) = @{ split_name('a/b/report.txt') };
```

#### Example

```perl
    my $parts = split_name('notes/plan.v2.txt');    # ['notes', 'plan.v2', '.txt']
```

#### Api Specification

##### Input

```perl
    [ { name => 'path', type => 'string', min => 1 } ]
```

##### Output

```perl
    { type => 'arrayref', min => 3, max => 3 }
```

#### Messages

None.

#### Formal Specification

```
    split_name(p) = (d, s, e) where p = d ⁀ "/" ⁀ s ⁀ e ∨ (d = ⟨⟩ ∧ p = s ⁀ e)
                    e = ⟨⟩ ∨ (head e = '.' ∧ '.' ∉ ran(tail e)) ; s ≠ ⟨⟩
```

### Name\_With\_Suffix

Purpose: make a name unique by numbering it before its extension.

Args: `$path`, `$suffix` (a number).

Returns: `report-2.txt` for `report.txt` and 2, keeping the directory.

Side Effects: none.

Usage:

```perl
    my $candidate = name_with_suffix($loser_name, $n);
```

#### Example

```
    print name_with_suffix('a/b.txt', 3), "\n";     # a/b-3.txt
```

#### Api Specification

##### Input

```perl
    [
            { name => 'path',   type => 'string', min => 1 },
            { name => 'suffix', type => 'integer', min => 1 },
    ]
```

##### Output

```perl
    { type => 'string', min => 1 }
```

#### Messages

None.

#### Formal Specification

```
    let (d, s, e) = split_name(p)
    name_with_suffix(p, n) = join(d, s ⁀ "-" ⁀ n ⁀ e)
```

### Conflict\_Name

Purpose: the name a losing version is kept under.

Args: `$path`, `$client_id` (may be undef), `$epoch` (default now).

Returns: the original name with `.conflict-CLIENT-TIMESTAMP` inserted before
the extension, kept within 200 bytes so it fits common filesystems.

Side Effects: none.

Usage:

```perl
    my $name = conflict_name('notes.txt', 'laptop-1', time);
```

#### Example

```
    print conflict_name('report.txt', 'laptop-1', 1_792_664_100), "\n";
    # report.conflict-laptop-1-20261022T101500Z.txt
```

#### Api Specification

##### Input

```perl
    [
            { name => 'path',      type => 'string', min => 1 },
            { name => 'client_id', type => 'string', optional => 1 },
            { name => 'epoch',     type => 'number', optional => 1 },
    ]
```

##### Output

```perl
    { type => 'string', min => 1 }
```

#### Messages

None.

#### Formal Specification

```
    let (d, s, e) = split_name(p) ; id = sanitise(c) ; t = format_utc(when)
    let room = max(16, 200 − #(".conflict-" ⁀ id ⁀ "-" ⁀ t ⁀ e))
    conflict_name(p, c, when) = join(d, s[1..room] ⁀ ".conflict-" ⁀ id ⁀ "-" ⁀ t ⁀ e)
```

### Write\_Atomic

Documented with ["set\_mtime"](#set_mtime) below.

### Read\_Text

Documented with ["set\_mtime"](#set_mtime) below.

### Set\_Mtime

Re-exported from [App::FileSync::IO](https://metacpan.org/pod/App%3A%3AFileSync%3A%3AIO), where they are documented.

## Examples

Two machines are involved: the server, which holds the master, and each
client, which holds a copy.  Install App::FileSync on both - `cpanm
App::FileSync`, say - because `filesync-admin` and `filesync-server` run on
the server and `filesync` on the clients.

The example keeps the master in the server account's home directory, so
nothing has to run as root.  `/srv/filesync` is the built-in default root;
"A root of /srv/filesync instead" below says what changes if you prefer it.

### On the Server

Create the repo as the account the clients log in to.  A session over ssh
carries only the repo, the client id and the role, so the client never tells
the server which root to use: name the same `--root` on every server command.

```
    # on the server, once
    filesync-admin --root ~/filesync repo create documents
    filesync-admin --root ~/filesync client allow laptop --repo documents
```

`repo create` makes the master directory and the metadata beside it, printing
both paths.  `client allow` is optional, because a repo with no clients
admits every client, and it takes the client's id: the host name unless
`--id` was given.

The server also needs `--root` when `filesync-server` starts, and the client
cannot pass one, so wrap it:

```
    # on the server, once
    cat > ~/bin/filesync-server-home <<'EOF'
    #!/bin/sh
    exec /usr/local/bin/filesync-server --root "$HOME/filesync" "$@"
    EOF
    chmod +x ~/bin/filesync-server-home
```

Use the path `filesync-server` was actually installed to, which
`ssh srv 'command -v filesync-server'` shows: a non-interactive ssh command
can see a shorter PATH than an interactive login shell.

### On Each Client

Register the directory and name the wrapper as the server program:

```
    # on the client, once
    filesync init --repo documents --root /home/foo/Documents \
            --server foo@srv \
            --server-command /home/foo/bin/filesync-server-home
    filesync sync --repo documents --dry-run
    filesync sync --repo documents
```

Nothing needs naming: the client reports its host name, which is the id
`client allow` lists and the name the server keeps this client's base, its
journal entries and its conflict copies under.  Pass `--id` only when the
host name is not the name you want, and allow that name on the server
instead.  An id is not a login - the ssh key and the account do the
authenticating - and it does not divide the repo: every client of a repo
syncs the whole tree.

ssh runs with `BatchMode=yes`, so the client's key must already be in the
server account's `authorized_keys`, or loaded in `ssh-agent`: cron cannot
answer a password prompt.

### From Cron

```
    # crontab -e, on each client
    * * * * * /usr/local/bin/filesync sync --repo documents --quiet >/dev/null
```

The summary line is dropped so cron does not mail on every successful run;
diagnostics still go to standard error, so a failure is mailed.  Every attempt,
successful or not, is also appended to `~/.filesync/logs/documents.jsonl`, and
`filesync log --repo documents --exit 1` lists the ones that failed.

### On Windows

Windows clients use a scheduled task rather than cron.  With the script in
`C:\filesync` and Strawberry Perl installed, the same job is set up from a
command prompt:

```
    REM on the client, once
    C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync init ^
      --repo documents --root C:\Users\foo\Documents --server foo@srv ^
      --server-command /home/foo/bin/filesync-server-home

    REM then create the task; it runs every minute as the current user
    schtasks /Create /SC MINUTE /MO 1 /TN FileSync /F ^
      /TR "C:\Strawberry\perl\bin\perl.exe C:\filesync\bin\filesync sync --repo documents --quiet"
```

The task runs only while that user is logged on, which suits a Documents
folder; its run log is still written under `%USERPROFILE%\.filesync\logs`, so
`filesync log --repo documents --warnings` works there too.

### A Root of /srv/filesync Instead

To keep the master outside a home directory, create the default root once for
the account the clients log in to.  Then no `--root` is needed on the server
commands, and no `--server-command` on the client:

```
    # on the server, as an administrator
    sudo mkdir -p /srv/filesync
    sudo chown -R foo /srv/filesync
```

`filesync-admin repo create documents` works as it is, and the master is
`/srv/filesync/master/documents`.

### Backup and Restore

The master directory is an ordinary directory tree, so it can be mirrored to a
backup directory from the server account's crontab.  Make the backup directory
once - rsync creates the last component only - then let cron keep it in step:

```
    # on the server, once
    mkdir -p /home/foo/backups/documents

    # crontab -e, on the server
    * * * * * rsync -a --delete --exclude '.filesync-tmp-*' \
        /home/foo/filesync/master/documents/ /home/foo/backups/documents/
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
    rsync -a --delete --checksum \
        /home/foo/backups/documents/ /home/foo/filesync/master/documents/
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
        /home/foo/backups/documents/ /home/foo/filesync/master/documents/
```

No output and exit 0 mean the master matches the backup.  Any line beginning
`>f` names a path that still differs, and `*deleting` names one the
rollback should have removed.  The index still describes the pre-rollback tree,
so `filesync-admin verify` may report drift at this point; that is expected.
Rebuild it and check it:

```
    filesync-admin --root ~/filesync reindex documents
    filesync-admin --root ~/filesync verify documents --deep
```

`reindex` hashes every file in the master and replaces the index atomically; it
refuses to run while a sync session holds the repo lock, and it names any paths
it could not index.  `clean` and exit 0 from `verify` confirm that the master
and its index agree.  Re-enable the jobs once that check passes.

To restore just one file or directory, copy that path back instead of mirroring
the whole tree, with the jobs paused as above so nothing changes the tree while
the copy runs:

```
    rsync -a --checksum /home/foo/backups/documents/notes/plan.txt \
        /home/foo/filesync/master/documents/notes/
    rsync -a --checksum /home/foo/backups/documents/photos/ \
        /home/foo/filesync/master/documents/photos/
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

## Limitations

These are the design weaknesses a reviewer should weigh before relying on the
tool.  None of them loses data silently; most cost time or space.

- **One master.**  The topology is a star around one server.  The replica
is a pull-only mirror, not a failover: if the server is lost, clients stop
until an administrator points them at a rebuilt master.
- **Every run exchanges the whole manifest.**  The client sends one entry
per file and the server answers with the whole plan as a single JSON line, so
a run costs O(files) in time, memory and bandwidth even when nothing changed.
A tree of a million files means a plan message of the order of a hundred
megabytes.  A change journal or Merkle summary would remove that, at the cost
of the "everything is inspectable with cat" property.
- **No line-length cap on the wire.**  Because of the previous point, a
control message cannot be bounded without breaking large trees.  The peer is
authenticated by ssh and pinned by the forced command, so this is a resource
risk from a misbehaving client, not from the network.
- **Lock-step protocol.**  One request is in flight at a time and each
256 KiB chunk waits for its acknowledgement, so throughput is bound by the
round-trip time on a high-latency link.
- **Clock-dependent tie-breaks.**  When both sides changed a file, the
newer mtime wins (the master wins ties within 2 seconds).  A client with a
wrong clock picks the wrong winner; the loser is still kept as a conflict copy.
- **No fsync.**  Renames are atomic between processes but not durable
across a power cut; see ["LIMITATIONS" in App::FileSync::IO](https://metacpan.org/pod/App%3A%3AFileSync%3A%3AIO#LIMITATIONS).
- **Pure-Perl deltas are bounded.**  Only the first 8 MiB after the
unchanged prefix are scanned for moved blocks; later changes go as literals.
See [App::FileSync::Delta](https://metacpan.org/pod/App%3A%3AFileSync%3A%3ADelta).
- **What is not synced.**  Symlinks, devices, sockets, extended attributes,
ACLs and ownership.  Permission bits are carried only between POSIX systems.
- **Names.**  Unicode normalisation is not reconciled, so the same name
in NFC (Linux) and NFD (older macOS) is two different files.  A
case-insensitive client cannot hold two master paths that differ only in case.
- **Encapsulation costs.**  Private methods use [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) in
`enforce` mode, which costs about 1.4 microseconds per call (measured on
5.40).  Helpers that run per file or per JSON value (the merge comparisons,
the JSON byte downgrade, the rolling checksum) are therefore lexical code
references: private by scope, with no wrapper.  Both Sub::Private and
[Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected) are bypassed while `HARNESS_ACTIVE` is set.
- **Validation costs.**  [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) costs about 11
microseconds per call, so it guards the public entry points that run a few
times per command (constructors, admin and client operations).  Functions that
run per path or per protocol frame (["validate\_relpath"](#validate_relpath), the protocol
methods, the scanner) check their arguments by hand.
- **Errors carry locations.**  Library errors are raised with `croak` and
so end with `at FILE line N.`; the commands strip that before printing, and
`FILESYNC_TRACE=1` turns every error into a full stack trace instead.
- **English only.**  The catalogue mechanism supports other languages,
plural forms and gender, but only the English catalogue ships.

## See Also

- [App::FileSync::I18N](https://metacpan.org/pod/App%3A%3AFileSync%3A%3AI18N) - the message catalogue
- [Test Dashboard](https://nigelhorne.github.io/App-FileSync/coverage/)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
