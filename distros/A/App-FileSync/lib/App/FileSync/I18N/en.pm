package App::FileSync::I18N::en;

# The English catalogue: every user-facing string in the distribution, by key.
# Placeholders are %{name}FMT (any sprintf conversion); see App::FileSync::I18N.
# Keys are grouped by the module that raises them.

use strict;
use warnings;

use version; our $VERSION = version->declare('0.001.2');

our %MESSAGES = (
	# ---------------------------------------------------------- i18n itself
	'i18n.bad_language'  => "Bad language code '%{language}s' (want two or three lower-case letters)",
	'i18n.bad_catalogue' => "The catalogue for '%{language}s' is not a hash",

	# -------------------------------------------------------- arguments
	'args.invalid' => '%{routine}s: %{reason}s',

	# ------------------------------------------------------- shared words
	'word.file'      => { _by => 'count', one => '%{count}d file', other => '%{count}d files' },
	'word.empty_dir' => { _by => 'count', one => '%{count}d empty dir', other => '%{count}d empty dirs' },
	'word.snapshot'  => { _by => 'count', one => 'snapshot', other => 'snapshots' },

	# ---------------------------------------------------- path validation
	'path.missing'            => 'missing path',
	'path.not_text'           => 'path is not text',
	'path.empty'              => 'empty path',
	'path.too_long'           => 'path is too long',
	'path.absolute'           => 'absolute path',
	'path.drive'              => 'drive-relative path',
	'path.backslash'          => 'backslash in path',
	'path.nul'                => 'NUL in path',
	'path.control'            => 'control character in path',
	'path.empty_component'    => 'empty path component',
	'path.dot_component'      => 'dot path component',
	'path.parent_component'   => 'parent path component',
	'path.component_too_long' => 'path component is too long',
	'path.unsafe'             => "Unsafe path '%{path}s': %{reason}s",

	# ------------------------------------------------------ id validation
	'id.repo_name' => 'repo name',
	'id.client_id' => 'client id',
	'id.missing'   => 'missing %{what}s',
	'id.not_text'  => '%{what}s is not text',
	'id.empty'     => 'empty %{what}s',
	'id.too_long'  => '%{what}s is too long',
	'id.bad'       => "bad %{what}s '%{value}s'",

	# ------------------------------------------------------- date parsing
	'when.bad' => "Bad %{option}s '%{value}s' (use YYYY-MM-DD or an epoch)",

	# ------------------------------------------------------- file system
	'io.read'        => 'Cannot read %{path}s: %{error}s',
	'io.write'       => 'Cannot write %{path}s: %{error}s',
	'io.append'      => 'Cannot append to %{path}s: %{error}s',
	'io.temp'        => 'Cannot create a temporary file in %{path}s: %{error}s',
	'io.rename'      => 'Cannot move %{from}s to %{to}s: %{error}s',
	'io.remove'      => 'Cannot remove %{path}s: %{error}s',
	'io.replace_dir' => 'Cannot replace non-empty directory %{path}s',
	'io.copy'        => 'Cannot copy %{from}s to %{to}s: %{error}s',
	'io.mkdir'       => 'Cannot create directory %{path}s: %{error}s',
	'io.seek'        => 'Cannot seek in %{path}s: %{error}s',
	'io.utime'       => 'Cannot set the modification time of %{path}s: %{error}s',
	'io.short'       => 'Unexpected end of %{path}s',

	# ------------------------------------------------------- configuration
	'config.no_home'    => 'Cannot determine your home directory; set FILESYNC_HOME',
	'config.parse'      => 'Cannot parse %{path}s: %{error}s',
	'config.not_object' => '%{path}s is not a JSON object',
	'config.no_repo'    => "No such repo '%{repo}s' under %{root}s (run filesync-admin repo create)",

	# ------------------------------------------------------------ scanning
	'scan.unreadable'  => 'cannot read: %{error}s',
	'scan.cannot_stat' => 'cannot stat: %{error}s',
	'scan.cannot_list' => 'cannot read directory: %{error}s',
	'scan.symlink'     => 'symbolic link',
	'scan.special'     => 'not a regular file',

	# --------------------------------------------------------------- trash
	'trash.move'        => 'Cannot move %{from}s to %{to}s: %{error}s',
	'trash.missing'     => 'Trash: %{path}s is not there',
	'trash.exists'      => 'Trash: refusing to overwrite %{path}s',
	'trash.cannot_stat' => 'Trash: cannot stat %{path}s: %{error}s',
	'trash.not_regular' => 'Trash: %{path}s is not a regular file',

	# -------------------------------------------------------------- verify
	'verify.no_root'      => 'Verify: %{root}s is not a directory',
	'verify.type_changed' => 'type changed',

	# --------------------------------------------------------------- merge
	'merge.master'              => 'master',
	'merge.deleted_changed'     => '%{path}s: deleted on %{client}s but changed on the master; restored from the master',
	'merge.changed_deleted'     => '%{path}s: changed on %{client}s but deleted on the master; restored to the master',
	'merge.conflict_copy'       => '%{path}s: changed on both %{client}s and the master; %{kept}s version kept, %{other}s version saved as %{copy}s',
	'merge.conflict_dir'        => '%{path}s: changed on both %{client}s and the master; %{kept}s version kept, the empty directory on the other side was discarded',
	'merge.replica_overwritten' => '%{path}s: changed on the replica; overwritten from the master',
	'merge.replica_removed'     => '%{path}s: removed on the replica; not in the master',
	'merge.too_many'            => 'refusing to delete %{count}d files (limit is %{max}d); rerun with --force if this is intended',
	'merge.too_many_percent'    => 'refusing to delete %{count}d of %{known}d known files (limit is %{percent}s%%); rerun with --force if this is intended',

	# --------------------------------------------------------------- delta
	'delta.bad_count'      => 'Bad signature block count',
	'delta.bad_length'     => 'Signature is %{length}d bytes, expected %{expected}d',
	'delta.no_output'      => 'Delta: no output handle',
	'delta.no_block'       => 'Delta: signature has no block length',
	'delta.write'          => 'Cannot write the delta: %{error}s',
	'delta.read'           => 'Cannot read the delta: %{error}s',
	'delta.bad_record'     => "Bad delta record '%{type}s'",
	'delta.write_restored' => 'Cannot write the restored file: %{error}s',

	# ------------------------------------------------------------ protocol
	'protocol.closed'       => 'Protocol: connection is closed',
	'protocol.write_failed' => 'Protocol: cannot write to the connection: %{error}s',
	'protocol.malformed'    => 'Protocol: malformed message from the peer: %{error}s',
	'protocol.not_object'   => 'Protocol: message is not an object',
	'protocol.bad_length'   => 'Protocol: bad payload length',
	'protocol.inflate'      => 'Protocol: cannot decompress the payload',
	'protocol.corrupt'      => 'Protocol: corrupt compressed payload',
	'protocol.too_large'    => 'Protocol: compressed payload expands beyond the limit',
	'protocol.negative'     => 'Protocol: negative payload length',
	'protocol.read_failed'  => 'Protocol: read error: %{error}s',
	'protocol.eof'          => 'Protocol: connection closed by the peer',

	# --------------------------------------------------------------- store
	'store.bad_client' => 'Store: %{reason}s',
	'store.bad_repo'   => 'Store: %{reason}s',
	'store.symlink'    => 'Refusing to write through symlinked directory %{path}s',
	'store.no_master'  => 'Master directory is missing: %{path}s',

	'admin.bad_repo'        => 'Invalid repo name: %{reason}s',
	'admin.bad_client'      => 'Invalid client id: %{reason}s',
	'admin.bad_role'        => q{Invalid role '%{role}s' (want %{roles}s)},
	'admin.repo_exists'     => q{Repo '%{repo}s' already exists at %{path}s},
	'admin.root_unwritable' => q{Server root '%{root}s' is not writable by this account (%{blocked}s); chown it to the account that runs filesync-admin and filesync-server, or use --root elsewhere},
	'admin.locked'          => q{Another sync session holds the lock for repo '%{repo}s'},
	'admin.unsafe_path'     => q{Unsafe path '%{path}s': %{reason}s},
	'admin.no_versions'     => q{No trashed version of '%{path}s' in repo '%{repo}s'},
	'admin.bad_date'        => q{Bad --date '%{date}s' (want YYYY-MM-DD)},
	'admin.no_version_on'   => q{No version of '%{path}s' in the trash for %{date}s},
	'admin.not_dir'         => 'Restore target %{path}s is not a directory',
	'admin.exists'          => 'Refusing to overwrite %{path}s; move it aside first',

	'server.missing'         => 'Server: no %{what}s given',
	'server.bad_role'        => q{Server: bad role '%{role}s'},
	'server.bad_id'          => 'Server: %{reason}s',
	'server.no_connection'   => 'Server: no connection',
	'server.locked'          => q{Another sync session holds the lock for repo '%{repo}s'},
	'server.unknown_error'   => 'unknown server error',
	'server.not_allowed'     => q{Client '%{client}s' is not allowed on repo '%{repo}s'},
	'server.wrong_role'      => q{Client '%{client}s' is registered as '%{registered}s', not '%{asked}s'},
	'server.proto'           => 'Unsupported protocol version',
	'server.pinned'          => q{Session is pinned to %{field}s '%{expected}s' but the client asked for '%{given}s'},
	'server.unknown'         => q{Unknown command '%{command}s'},
	'server.manifest_list'   => 'Manifest is not a list',
	'server.manifest_entry'  => 'Manifest entry is not an object',
	'server.manifest_path'   => 'Manifest path rejected: %{reason}s',
	'server.manifest_field'  => q{Bad manifest field '%{field}s' for %{path}s},
	'server.refused'         => '%{reason}s',
	'server.op.read'         => 'Read',
	'server.op.write'        => 'Write',
	'server.op.delta'        => 'Delta write',
	'server.op.pull'         => 'Signature upload',
	'server.op.mkdir'        => 'Directory creation',
	'server.op.delete'       => 'Deletion',
	'server.op.ack'          => 'Ack',
	'server.unplanned'       => q{%{what}s of unplanned path '%{path}s'},
	'server.not_planned'     => q{%{what}s of '%{path}s' is not in the plan},
	'server.bad_field'       => q{Bad '%{field}s' for '%{path}s'},
	'server.conflict_name'   => q{Conflict copy of '%{path}s' must be named '%{expected}s'},
	'server.no_put'          => q{Data for '%{path}s' without a put},
	'server.too_large'       => q{Chunk for '%{path}s' is too large},
	'server.bad_copy'        => q{Delta copy outside '%{path}s'},
	'server.bad_signature'   => q{Bad signature for '%{path}s'},
	'server.no_signature'    => q{Delta read for '%{path}s' without a signature},
	'server.no_delta'        => q{Delta data for '%{path}s' without a delta},
	'server.bad_ack'         => q{Ack for '%{path}s' does not match its planned action},
	'server.conflict_unsafe' => 'Unsafe conflict name: %{reason}s',
	'server.conflict_same'   => q{Conflict name for '%{path}s' is the same as the path},
	'server.conflict_exists' => 'Conflict copy already exists: %{path}s',
	'server.conflict_move'   => 'Cannot preserve %{path}s as %{to}s: %{error}s',
	'server.unfinished'      => 'Session ended before all actions completed: %{paths}s',
	'server.busy'            => q{Already receiving '%{path}s'},
	'server.overflow'        => q{Upload of '%{path}s' is larger than announced},
	'server.hash_mismatch'   => q{Hash mismatch for '%{path}s': expected %{expected}s, got %{got}s},
	'server.size_mismatch'   => q{Size mismatch for '%{path}s': expected %{expected}s, got %{got}s},
	'server.cannot_stat'     => 'Cannot stat %{path}s: %{error}s',
	'server.not_file'        => q{Cannot send a directory for '%{path}s'},

	'forced.program'  => q{unexpected program '%{program}s' in the remote command},
	'forced.argument' => q{unexpected argument '%{token}s' in the remote command},
	'forced.no_value' => 'the remote command gives --%{flag}s without a value',
	'forced.flag'     => 'the remote command may not set --%{flag}s',
	'forced.proto'    => q{the remote command asks for protocol '%{proto}s'},
	'forced.pinned'   => q{the remote command asks for %{field}s '%{value}s' but this key is pinned to '%{expected}s'},

	'client.no_config'        => 'Client: no config',
	'client.bad_name'         => 'Client: %{reason}s',
	'client.no_repo'          => q{No repo '%{repo}s' in %{path}s},
	'client.bad_root'         => q{Sync root for '%{repo}s' is not a directory: %{root}s},
	'client.no_marker'        => 'Sync root %{root}s has no .filesync-root marker (unmounted drive?); refusing to sync',
	'client.locked'           => q{Another filesync run holds the lock for '%{repo}s'},
	'client.no_client_id'     => 'No client_id in the client configuration',
	'client.refused'          => 'Server refused the session: %{reason}s',
	'client.unknown_reason'   => 'unknown error',
	'client.skipped'          => '%{path}s: skipped (%{reason}s)',
	'client.verbose_action'   => '  %{verb}s %{path}s',
	'client.unknown_action'   => q{Unknown action '%{action}s' for %{path}s},
	'client.req.plan'         => '%{reason}s',
	'client.req.end'          => 'Server did not accept the end of the session: %{reason}s',
	'client.req.manifest'     => 'Server rejected the manifest: %{reason}s',
	'client.req.delete'       => 'Cannot delete %{path}s on the server: %{reason}s',
	'client.req.ack_delete'   => 'Server did not accept the deletion of %{path}s: %{reason}s',
	'client.req.ack_dir'      => 'Server did not accept directory %{path}s: %{reason}s',
	'client.req.ack'          => 'Server did not accept %{path}s: %{reason}s',
	'client.req.get'          => 'Cannot read %{path}s from the server: %{reason}s',
	'client.req.mkdir'        => 'Cannot create directory %{path}s on the server: %{reason}s',
	'client.req.put'          => 'Server refused %{path}s: %{reason}s',
	'client.req.chunk'        => 'Server rejected data for %{path}s: %{reason}s',
	'client.req.store'        => 'Cannot store %{path}s on the server: %{reason}s',
	'client.req.signature'    => 'Server refused the signature for %{path}s: %{reason}s',
	'client.req.delta'        => 'Server refused the delta for %{path}s: %{reason}s',
	'client.req.delta_data'   => 'Server rejected delta data for %{path}s: %{reason}s',
	'client.hash_mismatch'    => 'Hash mismatch while copying %{path}s: expected %{expected}s, got %{got}s',
	'client.size_mismatch'    => 'Size mismatch while copying %{path}s: expected %{expected}s, got %{got}s',
	'client.bad_copy'         => 'Bad copy instruction for %{path}s',
	'client.bad_op'           => 'Unknown delta instruction for %{path}s',
	'client.conflict_exists'  => 'Conflict copy already exists: %{path}s',
	'client.conflict_move'    => 'Cannot preserve %{path}s as %{to}s: %{error}s',
	'client.unsafe'           => q{Unsafe path '%{path}s': %{reason}s},
	'client.cannot_stat'      => 'Cannot stat %{path}s: %{error}s',
	'client.need_server_root' => 'Repo %{repo}s needs a server_root for the local transport',
	'client.need_server'      => 'Repo %{repo}s needs a server (user@host) for the ssh transport',
	'client.bad_transport'    => q{Unknown transport '%{transport}s' for repo %{repo}s},
	'client.record_failed'    => 'cannot record this run in %{path}s: %{error}s',
	'client.no_versions'      => q{No trashed version of '%{path}s' for repo '%{repo}s' in %{trash}s},
	'client.not_dir'          => 'Restore target %{path}s is not a directory',
	'client.exists'           => 'Refusing to overwrite %{path}s; move it aside or use --to DIR',
	'client.not_replica'      => q{Repo '%{repo}s' is a client, not a replica; only a replica keeps snapshots},

	'transport.missing'   => '%{transport}s transport: no %{what}s given',
	'transport.bad_value' => q{SSH transport: bad %{field}s '%{value}s'},
	'transport.bad_id'    => 'SSH transport: %{reason}s',

	'cli.help.client' => <<'USAGE',
filesync - keep a directory in step with a master copy

    filesync init --repo NAME --root DIR --server USER@HOST [--remote-repo NAME]
                  [--id ID] [--role client|replica] [--port N] [--identity FILE]
                  [--accept-host-key] [--known-hosts FILE] [--server-command PATH]
                  [--snapshot-mode hardlink|copy]
    filesync init --repo NAME --root DIR --transport local --server-root DIR
                  [--remote-repo NAME] [--id ID] [--role client|replica]
    filesync sync   [--repo NAME]... [--dry-run] [--force] [--verbose] [--quiet]
                    [--json] [--no-prune] [--no-delta]
    filesync status [--repo NAME] [--json]
    filesync log    [--repo NAME] [-n N] [--since YYYY-MM-DD|EPOCH]
                    [--until YYYY-MM-DD|EPOCH] [--exit N]... [--warnings] [--json]
    filesync settings [--config FILE] [--json]
    filesync verify [--repo NAME] [--deep] [--json]
    filesync restore PATH [--repo NAME] [--to DIR] [--list]
    filesync snapshot [--repo NAME] [--keep N]
    filesync snapshot list [--repo NAME]
    filesync snapshot restore DATE [PATH] [--repo NAME] [--to DIR]
    filesync version

The sync root must contain the .filesync-root marker created by "filesync init".
Diagnostics go to stderr; settings are read from ~/.conf/app-filesync.json or
$FILESYNC_SETTINGS (log_level, log_format, log_file, ssh_identity,
ssh_known_hosts, server_command).  "filesync settings" prints the effective
values and where each came from.  Per-repo values from "filesync init" win;
port and host_key_checking exist per repo only and are marked [repo only].

Exit codes: 0 ok, 1 fatal, 2 another run holds the lock, 3 completed with
warnings, 4 verification found drift.
USAGE
	'cli.help.admin' => <<'USAGE',
filesync-admin --root DIR <command>

    repo create NAME [--trash-days N] [--max-deletes N] [--max-delete-percent N]
                     [--ignore PATTERN]...
    repo list
    repo show NAME
    client allow ID --repo NAME [--role client|replica]
    client list --repo NAME
    client forget ID --repo NAME
    reindex NAME [--dry-run] [--json]
    verify NAME [--deep] [--sample N] [--json]
    restore NAME PATH [--to DIR] [--list] [--date YYYY-MM-DD]
    log NAME... [-n N] [--client ID] [--since YYYY-MM-DD|EPOCH]
                  [--until YYYY-MM-DD|EPOCH] [--exit N]... [--warnings] [--json]

Exit codes: 0 ok, 1 fatal, 4 verification found drift.
USAGE

	'cli.unknown_command'  => q{Unknown command '%{command}s' (try: %{program}s help)},
	'cli.usage'            => 'Usage: %{usage}s',
	'cli.unexpected'       => '%{command}s: unexpected arguments: %{args}s',
	'cli.required'         => '%{command}s: %{what}s is required',
	'cli.positive'         => '%{command}s: %{option}s must be positive',
	'cli.exit_range'       => 'log: --exit must be between 0 and %{max}d',
	'cli.no_repos'         => 'No repos configured; run filesync init first',
	'cli.no_repo'          => q{No repo '%{repo}s' in the configuration},
	'cli.need_repo'        => '%{command}s: --repo is required when several repos are configured',
	'cli.unknown_snapshot' => q{Unknown snapshot command '%{verb}s' (try: filesync help)},
	'cli.repo_error'       => '%{repo}s: %{error}s',
	'cli.warning'          => '  warning: %{warning}s',
	'cli.never'            => 'never',
	'cli.version'          => 'filesync %{version}s (protocol %{proto}d)',

	'cli.usage.server'           => 'filesync-server [--root DIR] --repo NAME --client ID --role client|replica [--proto 2]',
	'cli.usage.init'             => 'filesync init --repo NAME --root DIR ...',
	'cli.usage.sync'             => 'filesync sync [--repo NAME] [--dry-run] [--force]',
	'cli.usage.status'           => 'filesync status [--repo NAME] [--json]',
	'cli.usage.log'              => 'filesync log [--repo NAME] [-n N] [--since DATE] [--until DATE] [--exit N] [--warnings] [--json]',
	'cli.usage.settings'         => 'filesync settings [--config FILE] [--json]',
	'cli.usage.verify'           => 'filesync verify [--repo NAME] [--deep] [--json]',
	'cli.usage.restore'          => 'filesync restore PATH [--repo NAME] [--to DIR] [--list]',
	'cli.usage.snapshot'         => 'filesync snapshot [--repo NAME] [--keep N]',
	'cli.usage.snapshot_list'    => 'filesync snapshot list [--repo NAME]',
	'cli.usage.snapshot_restore' => 'filesync snapshot restore DATE [PATH] [--repo NAME] [--to DIR]',
	'cli.usage.repo_create'      => 'filesync-admin repo create NAME [--trash-days N] ...',
	'cli.usage.admin_log'        => 'filesync-admin log NAME... [-n N] [--client ID] [--since DATE] [--until DATE] [--exit N] [--warnings] [--json]',
	'cli.usage.reindex'          => 'filesync-admin reindex NAME [--dry-run] [--json]',
	'cli.usage.admin_verify'     => 'filesync-admin verify NAME [--deep] [--sample N] [--json]',
	'cli.usage.admin_restore'    => 'filesync-admin restore NAME PATH [--to DIR] [--list] [--date YYYY-MM-DD]',
	'cli.usage.client_allow'     => 'filesync-admin client allow ID --repo NAME [--role R]',
	'cli.usage.client_list'      => 'filesync-admin client list --repo NAME',
	'cli.usage.client_forget'    => 'filesync-admin client forget ID --repo NAME',

	'cli.server.bad_role' => q{filesync-server: bad role '%{role}s'},
	'cli.server.proto'    => q{filesync-server: unsupported protocol '%{proto}s'},
	'cli.server.forced'   => 'filesync-server: %{reason}s',
	'cli.server.tty'      => 'filesync-server speaks the sync protocol on stdin and is not for interactive use; it is the forced command in authorized_keys',

	'cli.init.bad_id'          => 'init: %{reason}s',
	'cli.init.bad_role'        => q{init: bad role '%{role}s'},
	'cli.init.bad_mode'        => q{init: bad snapshot mode '%{mode}s' (want hardlink or copy)},
	'cli.init.bad_transport'   => q{init: unknown transport '%{transport}s'},
	'cli.init.need_server_root' => 'init: the local transport needs --server-root',
	'cli.init.need_server'     => 'init: the ssh transport needs --server',
	'cli.init.bad_server'      => q{init: bad server '%{server}s' (want user@host or host)},
	'cli.init.no_known_hosts'  => 'init: --known-hosts does not exist: %{path}s',
	'cli.init.accept_ssh_only' => 'init: --accept-host-key only applies to the ssh transport',
	'cli.init.bad_root'        => 'init: cannot use %{root}s as a sync root',
	'cli.init.done'            => q{Initialised repo '%{repo}s'},
	'cli.init.client_id'       => '  client id: %{id}s',
	'cli.init.root'            => '  root:      %{root}s',
	'cli.init.transport'       => '  transport: %{transport}s',
	'cli.init.server'          => '  server:    %{server}s',
	'cli.init.host_key_tofu'   => '  host key:  accept-new (trusted on first use)',
	'cli.init.host_key_strict' => '  host key:  strict',
	'cli.init.config'          => '  config:    %{path}s',

	'cli.sync.would'    => '  would %{verb}s %{path}s',
	'cli.sync.summary'  => '%{repo}s%{dry}s: pulled %{pulled}d, pushed %{pushed}d, deleted %{deleted}d, conflicts %{conflicts}d',
	'cli.sync.dry_tag'  => ' (dry run)',
	'cli.sync.transfer' => '  transfer: %{report}s',

	'cli.transfer.report' => 'sent %{sent}s, received %{received}s, %{files}s by delta%{detail}s',
	'cli.transfer.pulled' => '%{count}d pulled',
	'cli.transfer.pushed' => '%{count}d pushed',
	'cli.size.bytes'      => '%{value}d B',
	'cli.size.scaled'     => '%{value}.1f %{unit}s',
	'cli.size.exact'      => '%{value}s B',

	'cli.status.repo'      => '%{repo}s: %{root}s',
	'cli.status.transport' => '  transport: %{transport}s',
	'cli.status.last_run'  => '  last run:  %{last_run}s',
	'cli.status.transfer'  => '  transfer:  %{report}s',
	'cli.status.files'     => '  files:     %{files}d',

	'cli.log.none'      => '%{repo}s: no runs recorded',
	'cli.log.error'     => '%{repo}s  %{ts}s  exit %{exit}d  %{message}s',
	'cli.log.run'       => '%{repo}s  %{ts}s  exit %{exit}d  pulled %{pulled}d, pushed %{pushed}d, deleted %{deleted}d, conflicts %{conflicts}d%{skipped}s%{transfer}s%{dry}s',
	'cli.log.skipped'   => ', skipped %{count}d',
	'cli.log.dry_tag'   => '  (dry run)',
	'cli.log.heading'   => '%{repo}s:',
	'cli.log.no_events' => 'No journal entries for %{repo}s',
	'cli.log.event'     => '%{indent}s%{ts}s  %{client}-12s %{action}-12s %{detail}s',

	'cli.settings.file'           => 'settings file: %{file}s',
	'cli.settings.no_file'        => '(none)',
	'cli.settings.row'            => '  %{key}-16s %{value}-40s %{source}s',
	'cli.settings.note'           => "An empty ssh_identity or ssh_known_hosts means ssh's own default; an empty server_command means filesync-server.\nIn the repo sections, [repo only] marks port and host_key_checking, which have no process-wide default.",
	'cli.settings.repos'          => 'repos:',
	'cli.settings.repo'           => '  %{repo}s (%{transport}s%{server}s)',
	'cli.settings.local'          => '    the local transport does not use the SSH settings',
	'cli.settings.repo_row'       => '    %{key}-18s %{value}-38s %{source}s',
	'cli.settings.stderr'         => '(stderr)',
	'cli.settings.ssh_default'    => '(ssh default)',
	'cli.settings.server_default' => 'filesync-server',
	'cli.source.default'          => '%{label}s',
	'cli.source.merged'           => 'merged: %{label}s',
	'cli.source.env'              => 'environment %{label}s',
	'cli.source.file'             => 'file %{label}s',
	'cli.repo_source.repo'        => 'repo (%{label}s)',
	'cli.repo_source.process'     => 'process (%{label}s)',
	'cli.repo_source.default'     => '%{label}s',
	'cli.source.repo_only'        => '%{description}s [repo only]',

	'cli.verify.summary'  => '%{repo}s: %{state}s (%{files}s, %{rehashed}d rehashed, %{trusted}d unchanged)',
	'cli.verify.clean'    => 'clean',
	'cli.verify.drift'    => 'drift detected',
	'cli.verify.no_base'  => '  no cached base for this repo (it has not synced yet)',
	'cli.verify.modified' => '  modified: %{path}s%{reason}s',
	'cli.verify.missing'  => '  missing:  %{path}s',
	'cli.verify.extra'    => '  extra:    %{path}s',

	'cli.restore.no_versions'    => q{No trashed versions of '%{path}s'},
	'cli.restore.no_versions_in' => q{No trashed versions of '%{path}s' in %{repo}s},
	'cli.restore.version'        => '%{date}-12s %{size}10s  %{mtime}s  %{path}s',
	'cli.restore.done'           => 'Restored %{path}s to %{to}s',
	'cli.restore.admin_done'     => 'Restored %{repo}s:%{path}s from %{from}s to %{to}s',
	'cli.restore.the_trash'      => 'the trash',

	'cli.snapshot.exists'       => '%{repo}s: snapshot %{date}s already exists; left as it was',
	'cli.snapshot.taken'        => '%{repo}s: snapshot %{date}s taken (%{files}s, %{size}s) in %{path}s',
	'cli.snapshot.pruned'       => {
		_by   => 'count',
		one   => '%{repo}s: pruned %{count}d old snapshot (kept %{kept}d): %{dates}s',
		other => '%{repo}s: pruned %{count}d old snapshots (kept %{kept}d): %{dates}s',
	},
	'cli.snapshot.none'         => 'No snapshots for %{repo}s',
	'cli.snapshot.header'       => '%{date}-12s %{files}8s %{size}10s  %{path}s',
	'cli.snapshot.column.date'  => 'DATE',
	'cli.snapshot.column.files' => 'FILES',
	'cli.snapshot.column.size'  => 'SIZE',
	'cli.snapshot.column.path'  => 'PATH',
	'cli.snapshot.row'          => '%{date}-12s %{files}8d %{size}10s  %{path}s',
	'cli.snapshot.restored'     => '%{repo}s: restored %{what}s from snapshot %{date}s (%{files}s, %{size}s) to %{to}s',
	'cli.snapshot.whole_tree'   => 'the whole tree',
	'cli.snapshot.into_root'    => 'note: a replica mirrors the master again on the next sync; use --to DIR to keep an exported copy',

	'cli.admin.root_value'   => 'filesync-admin: --root needs a value',
	'cli.admin.unknown_verb' => q{Unknown %{group}s command '%{verb}s'},
	'cli.admin.empty_name'   => 'log: NAME must not be empty',

	'cli.repo.created.name'   => q{Created repo '%{repo}s'},
	'cli.repo.created.master' => '  master: %{master}s',
	'cli.repo.created.config' => '  config: %{config}s',
	'cli.repo.none'           => 'No repos under %{root}s',
	'cli.repo.no_clients'     => '(none)',
	'cli.repo.show'           => "name:    %{name}s\nmaster:  %{master}s\nmeta:    %{meta}s\ntrash:   %{trash_days}s days\nlimits:  %{max_deletes}s files / %{max_delete_percent}s%%\nclients: %{clients}s",

	'cli.reindex.would'   => '%{repo}s: would index %{files}s, %{dirs}s (%{size}s); index unchanged',
	'cli.reindex.done'    => '%{repo}s: indexed %{files}s, %{dirs}s (%{size}s); master index written',
	'cli.reindex.skipped' => '  skipped: %{path}s (%{reason}s)',

	'cli.client.allowed' => 'Allowed %{client}s on %{repo}s as %{role}s',
	'cli.client.none'    => 'No clients registered for %{repo}s',
	'cli.client.row'     => '%{client}-24s %{role}-8s %{state}s',
	'cli.client.synced'  => 'has synced',
	'cli.client.never'   => 'never synced',
	'cli.client.forgot'  => 'Forgot %{client}s (removed %{path}s)',
	'cli.client.nothing' => 'No stored state for %{client}s',

	'settings.bad_level' => q{Invalid log_level '%{level}s' (want %{valid}s)},

	'snapshot.no_root'     => 'Snapshot: no sync root given',
	'snapshot.not_dir'     => 'Snapshot: %{path}s is not a directory',
	'snapshot.bad_date'    => q{Snapshot: bad date '%{date}s' (want YYYY-MM-DD)},
	'snapshot.bad_mode'    => q{Snapshot: bad mode '%{mode}s' (want hardlink or copy)},
	'snapshot.read'        => 'Snapshot: cannot read %{path}s: %{error}s',
	'snapshot.failed'      => 'Snapshot: cannot create %{path}s: %{error}s',
	'snapshot.remove'      => 'Snapshot: cannot remove %{path}s (%{error}s)',
	'snapshot.need_date'   => 'Snapshot: --date is required',
	'snapshot.none'        => 'Snapshot: no snapshot for %{date}s under %{path}s',
	'snapshot.need_to'     => 'Snapshot: no destination given',
	'snapshot.to_not_dir'  => 'Snapshot: destination %{path}s is not a directory',
	'snapshot.unsafe'      => q{Unsafe snapshot path '%{path}s': %{reason}s},
	'snapshot.no_path'     => q{Snapshot %{date}s has no path '%{path}s'},
	'snapshot.cannot_stat' => 'Snapshot: cannot stat %{path}s: %{error}s',
	'snapshot.not_regular' => 'Snapshot: %{path}s is not a regular file',
	'snapshot.replace'     => 'Snapshot: cannot replace %{path}s',
);

1;

__END__

=head1 NAME

App::FileSync::I18N::en - the English message catalogue

=head1 DESCRIPTION

C<%App::FileSync::I18N::en::MESSAGES> maps every message key to its English
text.  It is the fallback for every other language, so it must hold every key
the code uses; F<t/locales.t> checks that.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
