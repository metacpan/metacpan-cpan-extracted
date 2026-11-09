# DBD::Firebird: sporadic heap corruption in a process that used destroyed statements

NOT FIT TO SEND: no minimal example. Notes for the day there is one. Context:
DBIO::Firebird karr k45 (related to k48, `dbd-firebird-destroys-held-statements.md`).

## Observed

DBD::Firebird 1.39, Firebird 5.0.4, glibc malloc. A process that did a random
mix of raw DBI operations on one connection -- prepare, execute+fetch, `finish`,
DDL with commit, a failed `DROP TABLE`, `rollback`, dropping statement handles --
ended in SIGABRT in 3 of about 580 runs with `MALLOC_CHECK_=3
MALLOC_PERTURB_=165`:

- `corrupted size vs. prev_size in fastbins`
- `malloc_consolidate(): unaligned fastbin chunk detected`
- (earlier, in t/21 of DBIO::Firebird) `malloc(): unaligned tcache chunk
  detected`, once SIGSEGV

All at the end of the process (`Issuing rollback() due to DESTROY without
explicit disconnect()` in one of them), AutoCommit on and off. A run of the same
operation sequence is not deterministic: with ASLR off (`setarch -R`) the
sequence of one crashing seed aborted 3 of 50 times; cut after its 20th or 25th
step it still aborted (2 and 1 of 40, 0 of 40 after the 21st-24th: the rate is
noise-level), cut at any step up to the 18th never (0 of 60 each). The 19th and
20th steps executed a statement the DBD had destroyed (the commit after DDL,
see the other draft), then the process exited with those handles still held.
An explicit replay of the operation list, and every short sequence
tried by hand (execute a destroyed handle once or repeatedly, with and without
freeing it, with a second DDL), did not abort in 40 runs each.

So the lane is: statements destroyed by `ib_commit_transaction` /
`ib_rollback_transaction` without the Perl handles being told, used or freed
afterwards, plus connection teardown. Nothing narrower is established.

## Not a DBIO::Firebird storage path

The storage prepares through `_prepare_sth`, which asks every cached handle
whether the DBD still has its statement and does not execute one it has
destroyed (ADR 0011). A handle held outside the cache (a cursor over DDL) is the
remaining way into the same state.

## Next step

Valgrind (not installed here) or an ASan build of DBD::Firebird over the fuzz
loop; the loop was a 25-step random walk over {prepare, execute+fetch, finish,
ALTER TABLE+commit, DROP of a missing table, DROP of the table, rollback, free a
handle, `select 1`} with AutoCommit off.
