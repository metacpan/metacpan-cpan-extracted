# Skips: capability first, platform second

Reference for `dbio-driver-development`. A test skips on the capability it needs, and the
skip says which capability is missing.

## The rule

- **Ask the capability by trying it.** Start a probe script found through `PATH`, call
  `Time::HiRes::alarm`, call `crypt` with a bcrypt salt, read `$Config{d_fork}`; skip when
  the answer is no. The host then decides, not a list of operating-system names.
- **`$^O` names a platform fact only**, where the platform itself is the reason: POSIX file
  modes and permission bits, the meaning of `fork` (a thread on Windows).
- **Every skip carries a reason** naming the missing capability: `plan skip_all => '…'` for a
  file, `skip '…', $n` inside a `SKIP:` block.
- **Live tests** skip with `Set DBIO_TEST_<DB>_DSN, _USER and _PASS to run this test`
  (`skip_all_unless_live` of the transport's harness does it for async suites).
- **Optional modules** skip with `eval { require X; 1 } or plan skip_all => 'X not installed'`
  and sit in the cpanfile as `suggests`.

## In the core tests

| Capability asked | Where |
|---|---|
| a script starts from `PATH` by its shebang line (a `shebang-probe` is written and run; `plan skip_all` when it prints nothing) | `t/maint/live-preflight.t` |
| `Time::HiRes::alarm` exists (`eval { Time::HiRes::alarm(0); 1 }` in a `BEGIN`) | `t/test/54_async_harness_outer_alarm.t` |
| `fork` exists (`skip '…', $n unless $Config{d_fork}`) | `t/storage/pool_fork_safety.t`, `t/storage/pool_fork_acquire.t`, `t/storage/pool_spawn_reentry.t`, `t/test/38_async_listen_contract.t`, `t/access_broker/24-pool-broker-edge-paths.t` |
| `crypt` knows bcrypt (`crypt('secret', '$2b$06$…')` returns a `$2b$06$` hash) | `t/94encoded_column_audit.t` |

`$^O eq 'MSWin32'` stands only where Windows is itself the reason:

| Reason | Where |
|---|---|
| no execute permission bit on files | `t/93dbioadmin_script.t` |
| no Unix file permissions | `t/debug/trace_levels.t` |
| file modes are not POSIX | `t/debug/trace_connect_statement_secrets.t` |
| a fork is a thread, so no pid check | `t/access_broker/26-dbi-reconnect-triggers.t` |
