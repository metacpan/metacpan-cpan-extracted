# DBIO Async Context Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** k200, k194, k196 und k195 verweigern in genau dieser Reihenfolge falsche Backends, machen TransactionContexts terminal, beweisen generation-scoped Ownership und propagieren gültige Contexts über jede eindeutige Single-Parent-Ableitung.

**Architecture:** Zuerst wird der einzige erlaubte Sync-Fallback auf den literalen Modus `immediate` begrenzt. Danach zentralisiert `txn_do_async` terminales Invalidate-plus-Release; die nächste Schicht gibt jeder Backendgeneration ein opakes Token, das Sync-Owner, Async-Backend und Core-Contexts teilen und sowohl `with_context` als auch Dispatch prüfen; erst dann reicht ein zentraler interner Propagationshelper denselben geprüften Context über Beziehungen, Ableitungen, Prefetch, Refresh, Copy und ResultSetColumn weiter.

**Tech Stack:** Perl 5, `DBIO::Storage`, `DBIO::Storage::DBI`, `DBIO::Storage::Async`, `TransactionContext`, `PipelineContext`, `DBIO::ResultSet`, `DBIO::Row`, `DBIO::ResultSetColumn`, `DBIO::Test::Storage`, `DBIO::Test::Future`, `Test::More`, `Test::Exception`, Dist::Zilla, `maint/capped-test`, karr.

**Spec:** `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`

## Global Constraints

- Verbindliche Reihenfolge in diesem Plan: k200 → k194 → k196 → k195; jedes Ticket wird vor dem nächsten vollständig getestet, installiert, lokal committed und Main-seitig nach `review` übergeben.
- Nur der explizite Modus `immediate` darf ohne `DBIO::Storage::Async`-Backend synchron dispatchen; jeder andere geladene Registry-Eintrag muss erben oder laut mit Modus und Klasse verweigern.
- Der separate Async-Layer-Skip aus k159 in `DBIO::Storage::DBI::_async_storage` bleibt unverändert.
- Nach erfolgreichem Transaction-Acquire laufen Context-Invalidierung und genau ein Release durch einen zentralen Finalizer; COMMIT-/ROLLBACK-Zweige releasen nicht separat.
- `TransactionContext::in_txn` ist nach jedem terminalen Pfad false; direkte CRUD- und verschachtelte `txn_do_async`-Aufrufe auf einem terminalen Context werden synchron verweigert.
- Ein opakes Token identifiziert genau eine aktuelle Async-Backend-/Poolgeneration. Klassenname, DSN, Schema-Klasse und bloßer Objektklassengleichstand sind keine Ownership-Identität.
- Sync-Owner, eingebettetes beziehungsweise composed Async-Backend und dessen Transaction-/Pipeline-Contexts teilen dasselbe Token. `connect_info`-Rebuild und Disconnect invalidieren die alte Generation, bevor ein neues Backend entsteht.
- ResultSet, Row und ResultSetColumn prüfen Ownership beim `with_context` und erneut direkt vor Dispatch; manuell injizierte, fremde, alte oder tokenlose Contexts bleiben fail-closed.
- Externe Context-Klassen ohne Core-Token werden in diesem Block nicht als pinning-fähig akzeptiert.
- Context-Propagation gilt nur für eindeutige Single-Parent-Ableitungen. Multi-Parent-Setops und Custom-Inflators bleiben außerhalb des Blocks.
- `with_context` auf einem warmen ResultSet liefert einen Clone ohne übernommenen `_result_cache`; das Original und seine Rows bleiben ungebunden und unverändert.
- Cascade-`copy_async` unter gebundenem Context verwendet den bestehenden Refusal-Pfad; kein stiller Sync- oder Pool-Fallback.
- Tests behaupten die tatsächlich verwendete Connection (`pinned`/Connection-ID und Capture-Log), nicht nur `{_async_context}`.
- Neue Fehler laufen über `$self->throw_exception` oder `DBIO::Exception->throw`; kein neuer bare `croak`.
- Keine `@ISA`-/Composition-Architekturänderung und keine neue öffentliche Cancellation-/Timeout-/Streaming-API.
- Keine Änderung der fünf ADR-0024-Contract-Versionen: die geplanten Helpers sind privat und die geänderten Klassen sind, abgesehen von bestehendem `Storage::DBI`, nicht die versionierten Shape-Basen; es wird keine neue Capability oder Driver-Signatur eingeführt.
- Tests nur mit `DBIO::Test::Storage`/`DBIO::Test::Future`; keine reale DB, kein SQLite-DSN, kein Event Loop.
- Tests schreibt `dbio-test-mock-writer`, Produktion/POD/ADR `dbio-worker`, Claim/Diff/Test/Git/karr nur Main.
- Pro Ticket genau ein lokaler Commit mit `kNN` und Co-Author-Zeile; der Arbeitsbaum ist nach dem Plan-Commit clean und `.claude/skills/kanban-issues-karr-cli/SKILL.md` bleibt aus allen vier Ticket-Commits ausgeschlossen.
- Jedes Ticket ergänzt `Changes` im passenden `{{$NEXT}}`-Abschnitt und staged diesen Eintrag zusammen mit seinem Test-/Runtime-Diff.
- Jeder Ticketabschluss enthält fokussierten capped Lauf, `maint/capped-test dzil test`, `maint/capped-test dzil install`, lokalen Commit und seriellen Main-Handoff; kein Push oder Release.

---

## Verifizierter aktueller Call-Graph

### Backend-Auflösung und Dispatch

- `lib/DBIO/Storage/DBI.pm:951-977` — `register_async_mode($class, $mode, $backend_class)` speichert nur die Registry-Zuordnung.
- `lib/DBIO/Storage/DBI.pm:1005-1060` — `_resolve_async_mode_class($self, $mode, %opt)` und `_try_load_async_class($self, $candidate, $what)`.
- `lib/DBIO/Storage/DBI.pm:1068-1296` — `_async_storage($self)`; Zeilen 1170–1173 behandeln jede Nicht-Async-Klasse fälschlich wie `immediate`.
- `lib/DBIO/Storage.pm:763-794` — `_run_async($self, $op, @args)` führt bei definiertem Modus und undef Backend synchron aus.
- `t/test/14_async_backend.t` — Registry-/Immediate-/Missing-/Disconnect-Matrix; neue wrong-type Registry-Klasse.
- `t/test/17_async_future_io_mro_walk.t:200-228` — unveränderte Referenz, dass convention-discovered `future_io` wrong-type bereits laut verweigert.
- `t/test/20_async_future_io_unloadable_adapter.t` — unveränderte Missing-dependency-/Syntax-Referenz.

### Transaction-Lebenszyklus

- `lib/DBIO/Storage/Async.pm:1179-1259` — `txn_do_async($self, $coderef, @args)` mit derzeit acht verteilten Releases und keiner `_invalidate`-Stelle.
- `lib/DBIO/Storage/Async/TransactionContext.pm:37-45` — `new($class, %args)`; Felder `{storage}`, `{txn_conn}`.
- `TransactionContext.pm:53,61,69,77,95,97` — `storage`, `txn_conn`, `pool`, derzeit konstantes `in_txn`, `_context_active`, vorhandenes `_invalidate`.
- `TransactionContext.pm:106-138` — direkte Query-/CRUD-/Blocking-/`txn_do_async`-Einstiege prüfen Aktivität derzeit nicht.
- `lib/DBIO/Storage/Async.pm:1335-1391` — Pipeline-Vergleich invalidiert bei Callback-Ende.
- `t/test/15_async_orchestration.t:418-477` — bestehende Commit-/Rollback-Seams.
- `t/resultset/with_context.t:143-170,283-317` — gepinnter Transaction-Erfolg und stale Pipeline, aber kein aufgehobener TransactionContext.

### Ownership und ORM-Dispatch

- `lib/DBIO/Storage/Async.pm:548-568` — `_owner_storage($self)` hält schwachen Backlink.
- `lib/DBIO/Storage/DBI.pm:1282-1295` — Backend-Aufbau installiert `_owner_storage($self)`.
- `lib/DBIO/ResultSet.pm:674-683`, `lib/DBIO/Row.pm:535-544`, `lib/DBIO/ResultSetColumn.pm:748-757` — `with_context($self, $ctx)` prüft derzeit nur defined/blessed/`can('select_async')`.
- `ResultSet.pm:2166-2194` — `_rs_run_async($self, $name, $backend_build, $sync_run)` priorisiert den Context.
- `Row.pm:486-512` — `_row_run_async` gleicher Fehlerpfad.
- `ResultSetColumn.pm:700-725` — `_rsc_run_async` gleicher Fehlerpfad.
- `t/resultset/with_context.t` — `wired_schema`, `Test::CtxBackend`, `captured_matching` und bestehende Same-backend-Zeugen.
- `t/composed/async_mirror.t` — `T::AM::RecordingTransport` und `build_storage` für composed Ownership.

### Propagationslücken

- Bereits korrekt: `ResultSet::search_rs` (`ResultSet.pm:619-630`), `new_result` (`3231-3270`), Top-Level-Inflation (`1751-1759`) und ResultSetColumn-Konstruktor (`ResultSetColumn.pm:75-154`).
- ResultSet-Beziehungen: `related_resultset($self, $rel)` (`ResultSet.pm:5451-5514`), `search_related`/`search_related_rs` (`1210-1226`).
- Row-Beziehungen: `Relationship::Base::related_resultset` (`Relationship/Base.pm:500-602`), `search_related*` (`622-635`), `new_related` (`673-683`).
- Codegen: Single-`$rel_async` (`Relationship/Codegen.pm:83-106`) ignoriert den von `_row_run_async` gelieferten Backend/Context; Multi-Accessor (`143-151`).
- ResultSet-Ableitungen: `page($self, $page)` (`3207-3210`), `limited_page` (`6912-6925`), `as_subselect_rs` (`5610-5632`), `correlate($self, $rel)` (`7188-7202`), `bare` (`7376`).
- Multi-Parent `_set_operation` (`7288-7333`) bleibt ausdrücklich ausgeschlossen.
- Prefetch-Children: `Row.pm:1811-1873`; Top-Level-Context wird erst danach in ResultSet gestempelt.
- Row-Operationen: `copy_async` (`1716-1753`), `get_from_storage_async` (`2150-2176`), `discard_changes_async` (`2257-2288`), `self_rs` (`2376-2380`), `clean_rs` (`2383`).
- RSC-Ableitungen: `func_rs($self, $function)` (`ResultSetColumn.pm:626-641`) und `_resultset($self)` (`806-836`) lesen derzeit den ungebundenen Parent eines direkt gebundenen RSC.

---

### Task 1: k200 — Falsches Backend laut verweigern

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/test/14_async_backend.t`
- Reference tests: `t/test/17_async_future_io_mro_walk.t`, `t/test/20_async_future_io_unloadable_adapter.t`
- Modify by worker: `lib/DBIO/Storage/DBI.pm`
- Modify by worker: `lib/DBIO/Storage.pm`
- Modify by worker: `lib/DBIO/Manual/AsyncStorage.pod`
- Modify by worker: `docs/adr/0030-async-explicit-per-connection-mode.md`

**Interfaces:**
- Consumes: Registry `register_async_mode($mode, $backend_class)`, lazy Loader und aktueller `immediate => DBIO::Future::Immediate`-Eintrag.
- Produces: `_async_storage()` gibt für `immediate` weiterhin undef zurück, liefert sonst ein `DBIO::Storage::Async`-Objekt oder wirft; `_run_async($op,@args)` erlaubt Sync nur bei `mode eq 'immediate'`.

- [ ] **Step 1: Prüfe und claime k200 als Main**

```bash
TICKET_ID=200
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k202 ist bereits in `review`; k200 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere ausschließlich den wrong-type Registry-Zeugen an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe nur den roten k200-Diff in `t/test/14_async_backend.t` nach Task 1
dieses Plans. Ergänze eine ladbare Klasse, die nicht von
DBIO::Storage::Async erbt, registriere `not_backend`, fordere Refusal von
`_async_storage` und `select_async` mit Modus und Klasse. Bewahre die vorhandenen
valid/immediate/missing/future_io/layer Fälle. Ändere keine Produktion,
Git-Index oder karr. Berichte roten capped Lauf und Claim.
```

- [ ] **Step 3: Ergänze die ladbare Nicht-Backend-Klasse und Registry**

Der Testagent setzt neben `My::Mock::AsyncA/B`:

```perl
{
  package My::Mock::NotAsyncBackend;
  sub marker { 'loadable but not async' }
}

DBIO::Storage::DBI->register_async_mode(
  not_backend => 'My::Mock::NotAsyncBackend'
);
```

- [ ] **Step 4: Schreibe die beiden roten Refusal-Assertions**

```perl
my $storage = DBIO::Test->init_schema->storage;
set_mode($storage, 'not_backend');
throws_ok { $storage->_async_storage }
  qr/async mode 'not_backend'.*My::Mock::NotAsyncBackend.*DBIO::Storage::Async/,
  'loaded registry target must satisfy the async backend contract';
throws_ok {
  $storage->select_async('artist', ['artistid'], {}, {});
} qr/async mode 'not_backend'.*My::Mock::NotAsyncBackend/,
  'public async dispatch never degrades a wrong backend to sync';
```

Current failure: `_async_storage` liefert undef und `select_async` führt den synchronen Fake-Cursor-Pfad aus.

- [ ] **Step 5: Führe k200 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l t/test/14_async_backend.t 2>&1 \
  | tee /tmp/dbio-k200-red.log
```

Expected: FAIL an den beiden neuen Refusal-Assertions; bestehendes `immediate` bleibt grün.

Claim:

```text
k200 behauptet: Ausschließlich der literale Modus immediate darf nach lazy
Auflösung ohne DBIO::Storage::Async-Backend synchron dispatchen; jede andere
ladbare Registry-Klasse wird mit Modus und Klasse synchron verweigert.
```

- [ ] **Step 6: Delegiere Runtime und Contract-Klarstellung an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k200 Task 1 in Storage/DBI.pm, Storage.pm, AsyncStorage.pod,
ADR 0030 und `Changes` gegen den bestätigten roten Diff. Validiere nach lazy
Load; nur mode eq immediate darf undef Backend liefern. Füge in `_run_async`
einen zweiten fail-closed Guard ein. Verändere weder k159-Layer-Skip noch Tests,
Contract-Version, Git-Index oder karr. Der Changes-Eintrag benennt den beseitigten
stillen Sync-Fallback.
```

- [ ] **Step 7: Ersetze den impliziten Nicht-Subclass-Fallback in `_async_storage`**

Der Worker ersetzt die aktuelle Stelle bei `DBI.pm:1170-1173` durch:

```perl
unless ($backend_class->isa('DBIO::Storage::Async')) {
  return $self->{_async_storage_obj} = undef
    if $mode eq 'immediate';
  $self->throw_exception(
    "async mode '$mode' resolved to $backend_class, which is not a "
  . 'DBIO::Storage::Async backend'
  );
}
```

Die Prüfung bleibt nach erfolgreichem lazy Load. `_try_load_async_class` und der Layer-Skip um `DBI.pm:1191-1219` bleiben unverändert.

- [ ] **Step 8: Begrenze den zweiten Sync-Fallback in `_run_async`**

Nach dem bestehenden Backend-Dispatch liest der Worker den aktuellen Modus und verwendet Sync nur exakt so:

```perl
my $mode = $self->_async_mode;
$self->throw_exception(
  "not an async connection -- connect with { async => ... } to use ${op}_async"
) unless defined $mode;
$self->throw_exception(
  "async mode '$mode' did not produce a DBIO::Storage::Async backend"
) unless $mode eq 'immediate';

my @result = eval { $self->$op(@args) };
return $@ ? $self->future_class->fail($@)
          : $self->future_class->done(@result);
```

Damit bleibt der vorhandene Immediate-Vertrag gleich und jeder künftige inkonsistente undef-Backend-Pfad fail-closed.

- [ ] **Step 9: Aktualisiere ADR/POD nur um die bestehende Regel**

`docs/adr/0030-async-explicit-per-connection-mode.md` und `lib/DBIO/Manual/AsyncStorage.pod` sagen danach explizit:

- `immediate` ist der einzige registrierte Nicht-`Storage::Async`-Sonderfall;
- ein anderer geladener wrong-type Target ist Contractfehler, kein Fallback;
- lazy Registrierung und k159s fehlender Layer-Mirror bleiben getrennte Fragen.

- [ ] **Step 10: Führe k200 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/14_async_backend.t \
  t/test/17_async_future_io_mro_walk.t \
  t/test/20_async_future_io_unloadable_adapter.t \
  2>&1 | tee /tmp/dbio-k200-focused.log
```

Expected: PASS; valid, immediate, generic wrong-type, missing und convention-wrong-type Quadranten sind belegt.

- [ ] **Step 11: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k200-full.log
```

Expected: Exit 0, `Result: PASS`.

- [ ] **Step 12: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k200-install.log
```

Expected: Exit 0.

- [ ] **Step 13: Stage k200 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/Storage/DBI.pm \
  lib/DBIO/Storage.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0030-async-explicit-per-connection-mode.md \
  t/test/14_async_backend.t
```

Expected: sechs Ticketdateien sind gestaged.

- [ ] **Step 14: Prüfe den k200-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md)"
git diff --cached --name-only
```

Expected: exakt sechs Dateien.

- [ ] **Step 15: Committe k200 lokal**

```bash
git commit \
  -m "fix(async): refuse invalid backend targets (karr k200)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k200-Commit; kein Push.

- [ ] **Step 16: Übergib k200 Main-seitig und seriell**

```bash
TICKET_ID=200
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k200-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k200-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Only immediate retains sync fallback; k159 layer behavior unchanged." \
  -t
```

Expected: k200 in `review`; `git status --short` liefert keine Ausgabe.

**k200 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Storage/DBI.pm \
  lib/DBIO/Storage.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0030-async-explicit-per-connection-mode.md \
  t/test/14_async_backend.t
git status --short
```

---

### Task 2: k194 — TransactionContext terminal machen

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/test/15_async_orchestration.t`
- Modify by test agent: `t/resultset/with_context.t`
- Modify by worker: `lib/DBIO/Storage/Async.pm`
- Modify by worker: `lib/DBIO/Storage/Async/TransactionContext.pm`
- Modify by worker: `lib/DBIO/Manual/AsyncStorage.pod`
- Modify by worker: `docs/adr/0045-resultset-async-pinned-context.md`

**Interfaces:**
- Consumes: `txn_do_async($coderef,@args)`, vorhandene `TransactionContext::_invalidate`, `txn_conn`, `DBIO::Test::Future` und k200s echter Backendvertrag.
- Produces: neuer privater `_finalize_txn_async($ctx,$conn,$terminal_future)` invalidiert vor Release und gibt Ergebnis/Fehler mit bestehender Präzedenz weiter; Context-Direkteinstiege prüfen `_context_active`.

- [ ] **Step 1: Prüfe und claime k194 als Main**

```bash
TICKET_ID=194
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k200 ist in `review`; k194 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere die terminale Pfadmatrix an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe nur die roten k194-Zeugen in t/test/15_async_orchestration.t und
t/resultset/with_context.t. Nutze pending DBIO::Test::Future. Halte den Context
nach außen und teste Commit, Commitfehler, Callback-Throw, failed Callback-
Future, Rollback, Rollbackfehler, Beginfehler, synchrone Query-Seam-Throws und
Acquirefehler. Nach erfolgreichem Acquire exakt ein Release, nach Acquirefehler
keines; post-terminal direct CRUD/nested txn und ORM-Dispatch müssen laut
refusen. Ändere keine Produktion, Git-Index oder karr.
```

- [ ] **Step 3: Ergänze steuerbare Future-/Throw-Seams und Release-Zähler**

Der Testagent erweitert `Test::SyncBackend` beziehungsweise eine lokale Unterfixture um:

```perl
$self->{fail_on}  = $opt{fail_on};
$self->{throw_on} = $opt{throw_on};

if ($self->{throw_on} && $sql =~ $self->{throw_on}) {
  die "synchronous seam throw on $sql\n";
}
if ($self->{fail_on} && $sql =~ $self->{fail_on}) {
  return $self->future_class->fail("future failure on $sql\n");
}
```

`Test::SyncPool` zählt `acquire_txn` und jedes `release`; ein konfigurierter Acquirefehler liefert `DBIO::Test::Future->fail('acquire failed')`.

- [ ] **Step 4: Schreibe den pending Commit-Erfolgsfall**

```perl
my ($saved_ctx, $gate);
$gate = DBIO::Test::Future->new;
my $txn = $backend->txn_do_async(sub {
  ($saved_ctx) = @_;
  return $gate;
});
ok $saved_ctx->_context_active, 'context is active while callback Future is pending';
ok !$txn->is_ready, 'outer transaction waits for callback Future';
$gate->done('value');
is $txn->get, 'value', 'transaction preserves callback result';
ok !$saved_ctx->_context_active, 'context is terminal after COMMIT';
ok !$saved_ctx->in_txn, 'in_txn is false after COMMIT';
is scalar @{ $backend->pool->{released} }, 1, 'successful transaction releases once';
throws_ok { $saved_ctx->select_async('artist', ['id'], {}, {}) }
  qr/no longer active/,
  'direct CRUD rejects completed context';
throws_ok { $saved_ctx->txn_do_async(sub { 1 }) }
  qr/no longer active/,
  'nested transaction rejects completed context';
```

- [ ] **Step 5: Schreibe Callback-Throw und failed Callback-Future**

Zwei getrennte Blöcke halten `$ctx` und behaupten nach `ROLLBACK`:

```perl
ok !$ctx->_context_active, 'callback failure invalidates context';
ok !$ctx->in_txn, 'failed transaction no longer reports in_txn';
is scalar @{ $backend->pool->{released} }, 1,
  'rollback path releases exactly once';
like join('|', $backend->_sqls), qr/BEGIN.*ROLLBACK/,
  'callback failure rolls back';
```

Der Throw-Fall erwartet die ursprüngliche Callback-Diagnose; der pending Future-Fall settled erst nach explizitem `$gate->fail('callback future failed')` und erwartet denselben Fehler.

- [ ] **Step 6: Schreibe BEGIN-/COMMIT-/ROLLBACK-Fehlerpräzedenz**

Der Testagent verwendet `fail_on` nacheinander für `BEGIN`, `COMMIT` und `ROLLBACK` und prüft nach je einem `eval { $future->get }`:

```perl
like $@, qr/BEGIN failed: future failure on BEGIN/,
  'BEGIN failure keeps existing prefix';
like $@, qr/COMMIT failed: future failure on COMMIT/,
  'COMMIT failure keeps existing prefix';
like $@, qr/future failure on ROLLBACK/,
  'ROLLBACK failure keeps current raw rollback precedence';
```

Diese drei Assertions stehen in getrennten Testblöcken, sodass `$@` jeweils unmittelbar aus dem zugehörigen `get` stammt. Jeder Fall nach erfolgreichem Acquire erwartet genau einen Release. Acquirefehler erwartet null Releases und keine `BEGIN`-Query.

- [ ] **Step 7: Schreibe synchrone Seam-Throw-Fälle**

Der Testagent führt drei getrennte Fälle mit dieser konkreten Matrix aus:

```perl
my @cases = (
  [ 'BEGIN',    qr/^BEGIN$/,    sub { 'unused' },
    qr/synchronous seam throw on BEGIN/ ],
  [ 'COMMIT',   qr/^COMMIT$/,   sub { 'plain result' },
    qr/synchronous seam throw on COMMIT/ ],
  [ 'ROLLBACK', qr/^ROLLBACK$/, sub {
      DBIO::Test::Future->fail('callback future failed')
    }, qr/synchronous seam throw on ROLLBACK/ ],
);
for my $case (@cases) {
  my ($name, $throw_on, $callback, $diagnostic) = @$case;
  my $backend = new_backend(throw_on => $throw_on);
  my $future;
  lives_ok {
    $future = $backend->txn_do_async($callback);
  } "$name seam throw is captured after acquire";
  ok $future->is_failed, "$name seam throw returns failed Future";
  eval { $future->get };
  like $@, $diagnostic, "$name seam diagnostic is preserved";
  is scalar @{ $backend->pool->{released} }, 1,
    "$name seam throw releases exactly once";
}
```

Der Rollbackfall pinnt damit die bestehende Präzedenz: der Rollbackfehler ersetzt den vorausgehenden Callbackfehler. Kein Fall darf synchron aus `txn_do_async` entweichen, nachdem Acquire erfolgreich war.

- [ ] **Step 8: Schreibe den ORM-Zeugen für einen gespeicherten Context**

In `t/resultset/with_context.t` bindet der Testagent während der offenen Transaktion einen ResultSet-Clone, settled danach die Transaction und ruft erst dann:

```perl
throws_ok { $bound->all_async }
  qr/no longer active/,
  'ResultSet carrying a completed transaction context refuses';
is scalar @{ $backend->{captured} }, $captured_before,
  'expired transaction context does not fall back to pool dispatch';
```

- [ ] **Step 9: Führe k194 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/15_async_orchestration.t \
  t/resultset/with_context.t \
  2>&1 | tee /tmp/dbio-k194-red.log
```

Expected: FAIL an aktiven gespeicherten Contexts, post-terminal CRUD und duplicated/leakenden Releasepfaden; Fixture bleibt pending kontrollierbar.

Claim:

```text
k194 behauptet: Nach jedem terminalen Transaktionsausgang ist der Context vor
dem einzigen Release invalid, in_txn false und weder direkt noch über ORM oder
nested txn wiederverwendbar; Acquirefehler releasen nichts.
```

- [ ] **Step 10: Delegiere Finalizer und Context-Guard an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k194 in Storage/Async.pm, TransactionContext.pm,
Manual/AsyncStorage.pod, ADR 0045 und `Changes` gegen den roten Diff.
Zentralisiere nach erfolgreichem Acquire invalidate-before-release; entferne
Release aus Commit-/Rollback-Zweigen. Wandle synchrone Seam-Throws nach Acquire
in failed Futures, bewahre bestehende Fehlerpräzedenz. Direkte Context-CRUD/
nested txn prüfen Aktivität; in_txn spiegelt sie. Ändere keine Tests, Git-Index
oder karr. Der Changes-Eintrag nennt terminale Contexts und Exactly-once-Release.
```

- [ ] **Step 11: Implementiere einen zentralen terminalen Finalizer**

Der neue private Helper in `Storage::Async` hat diese vorgeschlagene Signatur:

```perl
sub _finalize_txn_async {
  my ($self, $ctx, $conn, $terminal) = @_;
  my $fc = $self->future_class;
  return $terminal->then(
    sub {
      my @result = @_;
      $ctx->_invalidate;
      my ($released, $release_error);
      {
        local $@;
        $released = eval { $self->pool->release($conn); 1 };
        $release_error = $@ unless $released;
      }
      return $released ? $fc->done(@result) : $fc->fail($release_error);
    },
    sub {
      my $error = shift;
      $ctx->_invalidate;
      eval { $self->pool->release($conn) };
      return $fc->fail($error);
    },
  );
}
```

Bei vorhandenem Originalfehler bleibt ein Cleanup-Throw sekundär; bei Erfolg darf ein Release-Throw die terminale Future failen.

- [ ] **Step 12: Baue `txn_do_async` auf eine einzige terminale Future um**

Direkt nach `acquire_txn` konstruiert der Worker den Context wie heute, erzeugt den gesamten BEGIN/Callback/COMMIT-or-ROLLBACK-Chain ohne Release-Aufruf und fängt synchrone Throws der Query-Seams:

```perl
my ($terminal, $thrown);
{
  local $@;
  my $ok = eval {
    $terminal = $self->_txn_terminal_chain($txn_ctx, $conn, $coderef, \@args);
    1;
  };
  $thrown = $@ unless $ok;
}
$terminal = $fc->fail($thrown) if defined $thrown;
return $self->_finalize_txn_async($txn_ctx, $conn, $terminal);
```

`_txn_terminal_chain` ist ein neuer vorgeschlagener privater Name für diese konkrete release-freie Form:

```perl
sub _txn_terminal_chain {
  my ($self, $ctx, $conn, $coderef, $args) = @_;
  my $fc = $self->future_class;

  my $chain = $self->_query_async_pinned($conn, 'BEGIN', [])->then(
    sub {
      my ($inner, $callback_error);
      {
        local $@;
        my $ok = eval {
          $inner = $coderef->($ctx, @$args);
          1;
        };
        $callback_error = $@ unless $ok;
      }
      if (defined $callback_error) {
        return $self->_query_async_pinned($conn, 'ROLLBACK', [])->then(
          sub { return $fc->fail($callback_error) },
          sub { return $fc->fail($_[0]) },
        );
      }

      my $inner_future = ref($inner) && $inner->can('then')
        ? $inner
        : $fc->done($inner);
      return $inner_future->then(
        sub {
          my @result = @_;
          return $self->_query_async_pinned($conn, 'COMMIT', [])->then(
            sub { return $fc->done(@result) },
            sub { return $fc->fail("COMMIT failed: $_[0]") },
          );
        },
        sub {
          my $error = shift;
          return $self->_query_async_pinned($conn, 'ROLLBACK', [])->then(
            sub { return $fc->fail($error) },
            sub { return $fc->fail($_[0]) },
          );
        },
      );
    },
    sub { return $fc->fail("BEGIN failed: $_[0]") },
  );
  $chain->retain if $chain->can('retain');
  return $chain;
}
```

Die bisherigen Release-Stellen verschwinden vollständig aus den Branches; der äußere `_finalize_txn_async` besitzt den einzigen Release.

- [ ] **Step 13: Mache TransactionContext-Direkteinstiege terminal-sicher**

`TransactionContext` lädt `DBIO::Exception ();` und erhält:

```perl
sub _assert_context_active {
  my ($self) = @_;
  DBIO::Exception->throw('transaction context is no longer active')
    unless $self->_context_active;
  return $self;
}

sub in_txn { return $_[0]->_context_active ? 1 : 0 }
```

`_query_async`, die fünf pinned CRUD-Methoden und `txn_do_async` rufen `_assert_context_active` vor jeder Delegation. Die vorhandenen Constructor- und Accessor-Signaturen bleiben unverändert.

- [ ] **Step 14: Neutralisiere die stale-Context-Diagnose und dokumentiere den Lifecycle**

Die drei ORM-Refusals sagen nicht mehr nur „pipeline context“, sondern `async context is no longer active`. ADR 0045 und `Manual::AsyncStorage` halten Invalidate-before-release, `in_txn == false`, direkte Refusals und bestehende Fehlerpräzedenz fest.

- [ ] **Step 15: Führe k194 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/test/15_async_orchestration.t \
  t/resultset/with_context.t \
  2>&1 | tee /tmp/dbio-k194-focused.log
```

Expected: PASS; alle terminalen Pfade nach Acquire releasen exakt einmal, Acquirefehler null.

- [ ] **Step 16: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k194-full.log
```

Expected: Exit 0, Full Suite `Result: PASS`.

- [ ] **Step 17: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k194-install.log
```

Expected: Exit 0.

- [ ] **Step 18: Stage k194 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Storage/Async/TransactionContext.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0045-resultset-async-pinned-context.md \
  t/test/15_async_orchestration.t \
  t/resultset/with_context.t
```

Expected: sieben Ticketdateien sind gestaged.

- [ ] **Step 19: Prüfe den k194-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md)"
git diff --cached --name-only
```

Expected: exakt sieben Dateien.

- [ ] **Step 20: Committe k194 lokal**

```bash
git commit \
  -m "fix(async): terminate transaction contexts (karr k194)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k194-Commit.

- [ ] **Step 21: Übergib k194 Main-seitig und seriell**

```bash
TICKET_ID=194
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k194-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k194-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Commit/rollback/begin/callback/throw paths and exact-once release verified." \
  -t
```

Expected: k194 in `review`; `git status --short` liefert keine Ausgabe.

**k194 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Storage/Async/TransactionContext.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0045-resultset-async-pinned-context.md \
  t/test/15_async_orchestration.t \
  t/resultset/with_context.t
git status --short
```

---

### Task 3: k196 — Generation-scoped Context-Ownership

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/resultset/with_context.t`
- Modify by test agent: `t/composed/async_mirror.t`
- Modify by worker: `lib/DBIO/Storage/DBI.pm`
- Modify by worker: `lib/DBIO/Storage/Async.pm`
- Modify by worker: `lib/DBIO/Storage/Async/TransactionContext.pm`
- Modify by worker: `lib/DBIO/Storage/Async/PipelineContext.pm`
- Modify by worker: `lib/DBIO/ResultSet.pm`
- Modify by worker: `lib/DBIO/Row.pm`
- Modify by worker: `lib/DBIO/ResultSetColumn.pm`
- Modify by worker: `lib/DBIO/Manual/AsyncStorage.pod`
- Modify by worker: `docs/adr/0045-resultset-async-pinned-context.md`

**Interfaces:**
- Consumes: k194s aktive/terminale Contextprüfung und `_owner_storage`-Backlink.
- Produces: neue private Token-/Validator-Signaturen `_async_context_owner_token` auf Sync-Owner, `_context_owner_token` und `_rotate_context_owner_token` auf dem Backend, ein bei Construction gesnapshottetes `_context_owner_token` auf Core-Contexts und `_assert_async_context_owner($ctx)` auf dem owning Storage; ORM `with_context` und Dispatch rufen denselben Validator.

- [ ] **Step 1: Prüfe und claime k196 als Main**

```bash
TICKET_ID=196
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k194 ist in `review`; k196 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere Same-/Foreign-/Stale-/Composed-Zeugen an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe nur den roten k196-Diff in t/resultset/with_context.t und
composed/async_mirror.t. Baue zwei wired_schema-Instanzen derselben Klassen,
halte Context B pending und binde ResultSet, Row und RSC aus A; alle müssen vor
Query mit Ownership-Diagnose scheitern. Same-backend bleibt erlaubt. Umgehe
with_context einmal durch manuelle Slot-Injektion, damit Dispatch erneut prüft.
Rekonfiguriere connect_info und verweigere den alten Context; rufe außerdem
`backend->disconnect` und lazy `backend->pool` auf demselben Backendobjekt auf
und verweigere dessen gesnapshotteten alten Context. Belege composed
Owner/Backend als erlaubt und tokenlose externe Contexts als verweigert. Ändere
keine Produktion, Git-Index oder karr.
```

- [ ] **Step 3: Schreibe Cross-storage-Refusals für RS, Row und RSC**

Der Testagent erzeugt zwei unabhängige `(schema, backend)`-Paare derselben Klassen. Context B bleibt durch eine pending Callback-Future aktiv:

```perl
my ($schema_a, $backend_a) = wired_schema();
my ($schema_b, $backend_b) = wired_schema();
my ($ctx_b, $gate_b);
$gate_b = DBIO::Test::Future->new;
my $txn_b = $backend_b->txn_do_async(sub {
  ($ctx_b) = @_;
  return $gate_b;
});

my $rs_a  = $schema_a->resultset('Artist');
my $row_a = $rs_a->new_result({ artistid => 1, name => 'A' });
my $rsc_a = $rs_a->get_column('artistid');
for my $object ($rs_a, $row_a, $rsc_a) {
  throws_ok { $object->with_context($ctx_b) }
    qr/does not belong to this storage generation|ownership cannot be proven/,
    'foreign context is rejected before binding';
}
is scalar @{ $backend_a->{captured} }, 0, 'storage A ran no query';
is scalar @{ $backend_b->{captured} }, 1,
  'storage B only contains its BEGIN query';
```

Danach failt der Testagent `$gate_b`, damit k194 den offenen Test-Context sauber rollt und released.

- [ ] **Step 4: Belege Same-backend und tokenlose externe Contexts**

Innerhalb einer offenen Transaction von Backend A:

```perl
my $bound = $schema_a->resultset('Artist')->with_context($ctx_a);
lives_ok { $bound->all_async }
  'same-generation transaction context is accepted';
```

Eine neue vorgeschlagene lokale Testklasse erfüllt die alte Shape-Prüfung, besitzt aber absichtlich kein Token:

```perl
{
  package Test::TokenlessContext;
  sub new { bless {}, shift }
  sub select_async { DBIO::Test::Future->done }
}
```

Sie wird jetzt fail-closed abgewiesen:

```perl
throws_ok { $rs_a->with_context(Test::TokenlessContext->new) }
  qr/ownership cannot be proven/,
  'external context without Core ownership proof is rejected';
```

- [ ] **Step 5: Belege den zweiten Dispatch-Guard**

Der Testagent klont ein ResultSet ohne `with_context`, setzt testintern `{_async_context} = $ctx_b` und ruft `all_async`:

```perl
my $manual = $rs_a->search_rs;
$manual->{_async_context} = $ctx_b;
throws_ok { $manual->all_async }
  qr/does not belong to this storage generation/,
  'dispatch revalidates manually injected context';
```

Weder Backend A noch B darf danach eine Artist-Query enthalten.

- [ ] **Step 6: Belege Rebuild und composed Storage**

Der Rebuild-Zeuge speichert den aktuellen raw Connect-info-Wert aus dem verifizierten Getter und gibt genau dieselbe Arrayref an den Setter zurück:

```perl
my $rebuild_schema = DBIO::Test->init_schema;
my $rebuild_storage = $rebuild_schema->storage;
$rebuild_storage->connect_info([
  sub { },
  { async => 'with_ctx_backend' },
]);
my $old_backend = $rebuild_storage->_async_storage;
my $old_ctx_class = $old_backend->_txn_context_class;
my $old_ctx = $old_ctx_class->new(
  storage  => $old_backend,
  txn_conn => 'OLD_CONN',
);
my $bound_to_old_ctx =
  $rebuild_schema->resultset('Artist')->with_context($old_ctx);
my $connect_info = $rebuild_storage->connect_info;
$rebuild_storage->connect_info($connect_info);
my $new_backend = $rebuild_storage->_async_storage;
isnt Scalar::Util::refaddr($new_backend), Scalar::Util::refaddr($old_backend),
  'connect_info rebuild creates a new backend generation';
throws_ok { $bound_to_old_ctx->all_async }
  qr/does not belong to this storage generation/,
  'old context is refused after rebuild';
```

Der Getter `connect_info()` liefert aktuell den raw gespeicherten Wert, der Setter hat die Signatur `connect_info($arrayref)`; ein Splat wäre falsch. Diese Mockprobe behauptet Cache-/Ownership-Rebuild, nicht Teardown des alten Backends.

Ein zweiter Zeuge hält dasselbe Backendobjekt fest und ersetzt nur dessen lazy Poolgeneration:

```perl
my $old_pool = $backend_a->pool;
my $ctx_class = $backend_a->_txn_context_class;
my $old_ctx = $ctx_class->new(
  storage  => $backend_a,
  txn_conn => 'OLD_CONN',
);
$backend_a->disconnect;
my $new_pool = $backend_a->pool;
isnt Scalar::Util::refaddr($new_pool), Scalar::Util::refaddr($old_pool),
  'direct backend disconnect creates a new pool generation';
throws_ok {
  $schema_a->resultset('Artist')->with_context($old_ctx);
} qr/does not belong to this storage generation/,
  'context snapshots old pool generation even when backend object survives';
```

Dieser Fall verhindert eine dynamische Context-Ableitung über `context->storage->pool`, die nach Disconnect fälschlich dem neuen Pool folgen würde.

In `t/composed/async_mirror.t` verwendet der Testagent zweimal die vorhandene `build_storage`-Fixture, installiert den separat gebauten Storage explizit in sein Schema und bindet manuell erzeugte Core-Contexts:

```perl
my ($storage_a, $schema_a) = build_storage(
  storage_class => 'T::AM::S1::Storage',
  mode          => 'future_io',
  layers        => [ 'T::AM::S1::LayerA', 'T::AM::S1::LayerB' ],
);
my ($storage_b, $schema_b) = build_storage(
  storage_class => 'T::AM::S1::Storage',
  mode          => 'future_io',
  layers        => [ 'T::AM::S1::LayerA', 'T::AM::S1::LayerB' ],
);
$schema_a->storage($storage_a);
$schema_b->storage($storage_b);

my $async_a = $storage_a->async;
my $async_b = $storage_b->async;
my $ctx_class = $async_a->_txn_context_class;
my $ctx_a = $ctx_class->new(storage => $async_a, txn_conn => 'CONN_A');
my $ctx_b = $ctx_class->new(storage => $async_b, txn_conn => 'CONN_B');

my $bound;
lives_ok {
  $bound = $schema_a->resultset('Artist')->with_context($ctx_a);
} 'same-owner context is accepted on composed storage';
is $bound->_async_context, $ctx_a, 'same composed context is carried';
throws_ok {
  $schema_a->resultset('Artist')->with_context($ctx_b);
} qr/does not belong to this storage generation/,
  'identically composed foreign context is rejected';
```

Beide Backendpaare haben identische synthesised Klassen; nur das Objekt-/Token-Modell kann A erlauben und B verweigern. Die Fixture braucht keinen pinned Query-Seam-Zusatz, weil dieser Block ausschließlich das `with_context`-Ownership-Gate belegt.

- [ ] **Step 7: Führe k196 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/resultset/with_context.t \
  t/composed/async_mirror.t \
  2>&1 | tee /tmp/dbio-k196-red.log
```

Expected: fremde Contexts werden aktuell akzeptiert und dispatchen über Backend B; neue Token-/Rebuild-Assertions sind rot.

Claim:

```text
k196 behauptet: Context und ORM-Objekt müssen dasselbe opake Token der aktuell
gültigen Backend-/Poolgeneration besitzen; Shape, Klasse und DSN beweisen keine
Ownership, und with_context sowie Dispatch prüfen unabhängig voneinander.
```

- [ ] **Step 8: Delegiere Token, Guards und Contract-Amendment an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k196 in der in Task 3 erlaubten Produktions-/POD-/ADR-
Dateiliste sowie `Changes` gegen den roten Diff. Erzeuge pro Backend-/Poolaufbau
ein opakes Token, spiegle es zwischen tatsächlichem sync Owner und composed
Async-Backend und snapshotte es in Core-Contexts. Rotiere bei Async-connect_info/
disconnect sowie DBI-connect_info/disconnect; ein altes Backend darf kein neues
Owner-Token überschreiben. Implementiere einen zentralen owner-validator und rufe
ihn in RS/Row/RSC with_context und erneut im Dispatch. Direkte Transaction-/
Pipeline-Context-Nutzung prüft Aktivität und aktuelle Ownergeneration. Tokenlose
externe Contexts fail-closed. Keine Tests, Git-Index-, karr-, @ISA- oder
Capability-Änderung. Der Changes-Eintrag nennt Cross-Storage- und stale-Context-
Refusal.
```

- [ ] **Step 9: Spiegle das aktuelle Backendtoken im owning DBI-Storage**

`Storage::DBI` ergänzt `_async_context_owner_token` in der vorhandenen `simple`-Accessorgruppe direkt neben `_async_mode`; es entsteht kein handgeschriebener paralleler Accessor:

```perl
__PACKAGE__->mk_group_accessors('simple' => qw/
  _connect_info _dbio_connect_attributes _driver_determined
  _dbh _dbh_details _conn_pid _sql_maker _sql_maker_opts _dbh_autocommit
  _perform_autoinc_retrieval _autoinc_supplied_for_op _async_mode
  _async_context_owner_token _server_messages
/);
```

Die neuen vorgeschlagenen privaten Lifecycle-Helpers lauten:

```perl
sub _reset_async_context_owner_token {
  my ($self) = @_;
  $self->_async_context_owner_token(undef);
  return;
}

sub _adopt_async_context_owner_token {
  my ($self, $backend, $token) = @_;
  my $current = $self->{_async_storage_obj} or return;
  return unless Scalar::Util::refaddr($current)
    == Scalar::Util::refaddr($backend);
  $self->_async_context_owner_token($token);
  return;
}
```

Jeder DBI-Pfad, der `_async_storage_obj` wegen `connect_info` oder `disconnect` löscht, ruft `_reset_async_context_owner_token` vor der Löschung. Beim Backendaufbau bleibt die aktuelle Reihenfolge `new`, Backend-`connect_info`, `_owner_storage`; danach spiegelt der Owner das vom Backend erzeugte aktuelle Token:

```perl
$async->_owner_storage($self);
$self->_async_context_owner_token($async->_context_owner_token);
return $self->{_async_storage_obj} = $async;
```

`_adopt_async_context_owner_token` verhindert, dass ein später rotierendes altes Backend das Token eines inzwischen aktuellen neuen Backendobjekts überschreibt.

- [ ] **Step 10: Erzeuge und rotiere das Token im Async-Backend**

`Storage::Async::new($class,$schema,$args)` initialisiert nach dem Bless ein backend-eigenes Token. Die neuen privaten Helpers lauten:

```perl
sub _new_context_owner_token {
  my $opaque;
  return \$opaque;
}

sub _context_owner_token {
  my ($self) = @_;
  return $self->{_context_owner_token};
}

sub _rotate_context_owner_token {
  my ($self) = @_;
  my $token = $self->_new_context_owner_token;
  $self->{_context_owner_token} = $token;
  if (my $owner = $self->_owner_storage) {
    $owner->_adopt_async_context_owner_token($self, $token)
      if $owner->can('_adopt_async_context_owner_token');
  }
  return $token;
}
```

Der Constructor ruft `_rotate_context_owner_token` einmal. Am Anfang des truthy Setter-Zweigs von `connect_info($info)` ersetzt diese Form den bisherigen nur-bei-Pool-Disconnect:

```perl
if ($self->{pool}) {
  $self->disconnect;
}
else {
  $self->_rotate_context_owner_token;
}
```

`disconnect` selbst rotiert vor `pool->shutdown` und `{pool}=undef`, auch wenn aktuell kein Pool gespeichert ist. Damit rotiert jeder Setter genau einmal und dasselbe Backendobjekt kann nach lazy Pool-Neuanlage kein altes Contexttoken wiederverwenden.

- [ ] **Step 11: Snapshotte die Generation bei Context-Construction**

Transaction- und PipelineContext ergänzen in ihren bestehenden `new($class,%args)`-Hashes:

```perl
context_owner_token => $args{storage}->_context_owner_token,
```

und liefern ausschließlich den Snapshot:

```perl
sub _context_owner_token {
  my ($self) = @_;
  return $self->{context_owner_token};
}
```

Sie leiten das Token ausdrücklich nicht später über `storage` oder `pool` ab, weil beide nach Disconnect auf eine neue Poolgeneration zeigen können. Kein Klassenname, DSN oder Schema-Name fließt in den Vergleich ein.

- [ ] **Step 12: Implementiere den zentralen Storage-Validator**

`Storage::DBI` lädt beziehungsweise verwendet das bereits vorhandene `Scalar::Util` und erhält:

```perl
sub _assert_async_context_owner {
  my ($self, $ctx) = @_;
  $self->throw_exception('async context ownership cannot be proven')
    unless Scalar::Util::blessed($ctx)
      && $ctx->can('_context_owner_token');

  my $ours   = $self->_async_context_owner_token;
  my $theirs = $ctx->_context_owner_token;
  $self->throw_exception(
    'async context does not belong to this storage generation'
  ) unless $ours && $theirs
    && Scalar::Util::refaddr($ours) == Scalar::Util::refaddr($theirs);
  return $ctx;
}
```

Dies ist der eine Vergleich, den alle ORM-Klassen konsumieren.

- [ ] **Step 13: Prüfe Ownership in allen drei `with_context`-Methoden**

Nach der bestehenden Shape-Diagnose und vor Clone-Erzeugung verwenden ResultSet und Row:

```perl
my $storage = $self->result_source->storage;
$storage->_assert_async_context_owner($ctx);
```

ResultSetColumn verwendet seinen aktuellen Parent statt einen neuen ResultSet abzuleiten:

```perl
my $storage = $self->{_parent_resultset}->result_source->storage;
$storage->_assert_async_context_owner($ctx);
```

Die vorhandenen Clone-Signaturen bleiben unverändert.

- [ ] **Step 14: Prüfe Ownership erneut in allen drei Dispatchern**

Unmittelbar nach `_assert_async_context_active` und vor `$backend_build->($ctx,$fc)`:

```perl
$storage->_assert_async_context_owner($ctx);
```

Dies wird in `_rs_run_async`, `_row_run_async` und `_rsc_run_async` wiederholt, damit manuelle Slot-Injektion und nach dem Bind erfolgte Rebuilds fail-closed bleiben.

- [ ] **Step 15: Mache direkte Core-Contexts generation-sicher**

TransactionContext und PipelineContext ergänzen ihre Aktivitätsprüfung um:

```perl
my $backend = $self->storage;
my $owner = $backend->_owner_storage;
DBIO::Exception->throw('async context ownership cannot be proven')
  unless $owner;
$owner->_assert_async_context_owner($self);
```

Alle direkten Query-/CRUD-Einstiege beider Core-Contexts rufen diese kombinierte Prüfung. Ein alter Backend-Context kann nach `connect_info` oder Disconnect nicht direkt weiterqueryen.

- [ ] **Step 16: Dokumentiere Generation und Composition**

ADR 0045 und `Manual::AsyncStorage` halten fest:

- Token gilt für genau eine Backend-/Poolgeneration; Contexts snapshotten es bei Construction und folgen nicht dynamisch einem späteren `context->storage->pool`;
- composed Klassen teilen das Token ihres tatsächlichen Ownerobjekts;
- Rebuild/Disconnect rotiert vor Neuanlage; `connect_info` rotiert auch ohne aktuell materialisierten Pool;
- konkrete Backends ersetzen ein vorhandenes Poolobjekt nur über diese `connect_info`-/`disconnect`-Pfade, weil die abstrakte Core-`pool`-Methode beliebige Subclass-Zuweisungen nicht beobachten kann;
- Shape-/Klassen-/DSN-Gleichheit beweist nichts;
- externe Contexts ohne Core-Nachweis sind in diesem Inkrement nicht pinning-fähig.

- [ ] **Step 17: Führe k196 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/resultset/with_context.t \
  t/composed/async_mirror.t \
  t/test/14_async_backend.t \
  2>&1 | tee /tmp/dbio-k196-focused.log
```

Expected: PASS; Same-/Foreign-/Manual-/Stale-/Composed-Matrix belegt Query-Identität.

- [ ] **Step 18: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k196-full.log
```

Expected: Exit 0, `Result: PASS`.

- [ ] **Step 19: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k196-install.log
```

Expected: Exit 0.

- [ ] **Step 20: Stage k196 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/Storage/DBI.pm \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Storage/Async/TransactionContext.pm \
  lib/DBIO/Storage/Async/PipelineContext.pm \
  lib/DBIO/ResultSet.pm \
  lib/DBIO/Row.pm \
  lib/DBIO/ResultSetColumn.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0045-resultset-async-pinned-context.md \
  t/resultset/with_context.t \
  t/composed/async_mirror.t
```

Expected: zwölf Ticketdateien sind gestaged.

- [ ] **Step 21: Prüfe den k196-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md)"
git diff --cached --name-only
```

Expected: exakt zwölf Dateien.

- [ ] **Step 22: Committe k196 lokal**

```bash
git commit \
  -m "fix(async): scope contexts to backend generations (karr k196)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k196-Commit.

- [ ] **Step 23: Übergib k196 Main-seitig und seriell**

```bash
TICKET_ID=196
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k196-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k196-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Same/foreign/stale/manual/composed ownership verified by generation token." \
  -t
```

Expected: k196 in `review`; `git status --short` liefert keine Ausgabe.

**k196 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/Storage/DBI.pm \
  lib/DBIO/Storage/Async.pm \
  lib/DBIO/Storage/Async/TransactionContext.pm \
  lib/DBIO/Storage/Async/PipelineContext.pm \
  lib/DBIO/ResultSet.pm \
  lib/DBIO/Row.pm \
  lib/DBIO/ResultSetColumn.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0045-resultset-async-pinned-context.md \
  t/resultset/with_context.t \
  t/composed/async_mirror.t
git status --short
```

---

### Task 4: k195 — Context über Single-Parent-Ableitungen propagieren

**Files:**
- Modify by worker: `Changes`
- Modify by test agent: `t/resultset/with_context.t`
- Modify by worker: `lib/DBIO/ResultSet.pm`
- Modify by worker: `lib/DBIO/Row.pm`
- Modify by worker: `lib/DBIO/Relationship/Base.pm`
- Modify by worker: `lib/DBIO/Relationship/Codegen.pm`
- Modify by worker: `lib/DBIO/ResultSetColumn.pm`
- Modify by worker: `lib/DBIO/Manual/AsyncStorage.pod`
- Modify by worker: `docs/adr/0045-resultset-async-pinned-context.md`

**Interfaces:**
- Consumes: k194s terminale Aktivitätsprüfung, k196s Ownership-Validator und den bestehenden `{_async_context}`-Slot.
- Produces: neuer vorgeschlagener zentraler interner Helper `DBIO::ResultSet::_inherit_async_context($source,$target) -> bound clone or original`; alle eindeutigen Single-Parent-Ableitungen konsumieren ihn, ohne Shared Cacheobjekte in-place umzubinden. Der exakte Core-Inflator `DBIO::Row::inflate_result($class,$rsrc,$me,$prefetch,$async_context_optional)` akzeptiert intern einen kompatiblen optionalen fünften Wert; Custom-Inflators werden weiter mit ihrer bisherigen Form aufgerufen.

- [ ] **Step 1: Prüfe und claime k195 als Main**

```bash
TICKET_ID=195
CLAIM=$(karr agent-name)
karr show "$TICKET_ID"
karr move "$TICKET_ID" in-progress --claim "$CLAIM"
```

Expected: k196 ist in `review`; k195 war unclaimed und unblocked.

- [ ] **Step 2: Delegiere die vollständige Ableitungsmatrix an `dbio-test-mock-writer`**

Handoff prompt:

```text
Schreibe ausschließlich den roten k195-Diff in t/resultset/with_context.t.
Verwende einen live pending TransactionContext und prüfe die tatsächlich
captured Connection für ResultSet-/Row-Relationships, generated single/multi,
page, limited_page, as_subselect_rs, correlate, bare, prefetched child RS/Row,
get_from_storage_async, discard_changes_async, flat copy_async, self_rs,
clean_rs und direkt gebundenes RSC func_rs/_resultset. Ergänze warmen Cache:
bound clone lädt pinned neu, Originalcache/Rows bleiben ungebunden. Expired
Pipeline/Transaction propagieren und refusen statt Pool-Fallback; cascade copy
nimmt den bestehenden Refusal. Ändere keine Produktion, Git-Index oder karr.
```

- [ ] **Step 3: Schreibe ResultSet- und Relationship-Zeugen**

Innerhalb einer offenen Transaction bindet der Testagent einen Artist-ResultSet und fordert für jede Ableitung eine Query mit derselben gepinnten Connection:

```perl
my @derived = (
  $bound_rs->related_resultset('cds'),
  $bound_rs->search_related('cds'),
  $bound_rs->search_related_rs('cds'),
  $bound_rs->rows(1)->page(2),
  $bound_rs->limited_page({ page => 2, rows => 1 }),
  $bound_rs->as_subselect_rs,
  $bound_rs->correlate('cds'),
  $bound_rs->bare,
);
for my $derived (@derived) {
  $derived->all_async->get;
  ok $backend->{captured}[-1]{pinned}, 'derived ResultSet used pin';
  is $backend->{captured}[-1]{conn}, $ctx->txn_conn,
    'derived ResultSet used transaction connection';
}
```

Für Row-Beziehungen werden ein gespeicherter Artist und eine CD verwendet:

```perl
$artist->cds->all_async->get;
$artist->search_related('cds')->all_async->get;
$cd->artist_async->get;
```

Jeder letzte Capture nennt `pinned => 1` und exakt `$ctx->txn_conn`. `new_related` liefert eine Row, deren anschließendes `insert_async` denselben Pin verwendet.

- [ ] **Step 4: Schreibe Prefetch-Child-ResultSet-/Row-Zeugen**

Der Testagent speist die bekannte Artist/CD-Joinform:

```perl
[
  [ 1, 'Miles Davis', 13, undef, 10, 1, 'Kind of Blue', 1959, undef, undef ],
  [ 1, 'Miles Davis', 13, undef, 11, 1, 'Bitches Brew', 1970, undef, undef ],
]
```

Nach `my ($artist) = $bound_prefetch->all_async->get` werden sowohl Child-ResultSet als auch Child-Row aktiv dispatcht:

```perl
my $child_rs = $artist->cds;
$child_rs->update_async({ year => 1960 })->get;
my ($cd) = $child_rs->all;
$cd->update_async({ title => 'Pinned child' })->get;
```

Beide Update-Captures nennen `pinned => 1` und exakt dieselbe Transaction-Connection. Das anschließende synchrone `all` liest die prefetched Children ohne Zusatzquery und belegt, dass der exklusive Child-Cache trotz Context-Bindung erhalten blieb.

- [ ] **Step 5: Schreibe Warm-cache-Clone-Isolation**

```perl
my $original = $schema->resultset('Artist');
my $cached_row = $original->new_result({ artistid => 1, name => 'Cached' });
$original->set_cache([$cached_row]);
my $bound = $original->with_context($ctx);

my @fresh = $bound->all_async->get;
ok $backend->{captured}[-1]{pinned},
  'bound clone ignores inherited warm cache and reloads through pin';
is scalar($original->all), 1, 'original cache remains available';
ok !$cached_row->_async_context, 'original cached row was not rebound in place';
$fresh[0]->update_async({ name => 'Pinned fresh' })->get;
is $backend->{captured}[-1]{conn}, $ctx->txn_conn,
  'freshly loaded clone row retains context';
```

- [ ] **Step 6: Schreibe Row-Refresh-/Copy-Ableitungen**

Auf einer gebundenen gespeicherten Row:

```perl
$row->get_from_storage_async->get;
$row->discard_changes_async->get;
$row->self_rs->all_async->get;
$row->clean_rs->all_async->get;
my $copy = $row->copy_async({ artistid => 99 })->get;
```

Nach jeder Operation ist der letzte Capture gepinnt und nutzt `$ctx->txn_conn`; der flache Copy-Insert läuft nicht über Pool. Für einen Cascade-Copy unter Context erwartet der Testagent den bereits vorhandenen Async-context-Refusal statt synchronem `copy`.

- [ ] **Step 7: Schreibe direkt gebundene ResultSetColumn-Ableitungen**

```perl
my $rsc = $schema->resultset('Artist')->get_column('artistid')
  ->with_context($ctx);
$rsc->func_rs('MAX')->all_async->get;
$rsc->_resultset->all_async->get;
```

Beide letzten Captures müssen `pinned => 1` und `$ctx->txn_conn` tragen. Dieser Fall ist getrennt von einem RSC, dessen Parent bereits gebunden war.

- [ ] **Step 8: Schreibe expired-Context-No-fallback-Zeugen**

Der Testagent leitet während eines aktiven Pipeline- und TransactionContexts je ein Relationship-/Page-/Prefetch-Child-Objekt ab, invalidiert beziehungsweise beendet den Context und ruft erst danach async auf:

```perl
throws_ok { $derived->all_async }
  qr/no longer active/,
  'derived object preserves expired context and refuses';
is scalar @{ $backend->{captured} }, $before,
  'expired derived object does not fall back to pool';
```

- [ ] **Step 9: Führe k195 rot aus und fixiere den Claim**

```bash
set -o pipefail
maint/capped-test prove -l t/resultset/with_context.t 2>&1 \
  | tee /tmp/dbio-k195-red.log
```

Expected: bestätigte Relationships, Page, Subselect, Prefetch, Refresh, Copy, Cache und direkt gebundene RSC-Pfade verlieren aktuell den Context oder mutieren/verwenden den alten Cache.

Claim:

```text
k195 behauptet: Jede eindeutige Single-Parent-Ableitung übernimmt denselben
validierten Context und benutzt nachweislich dessen Connection; warme Shared
Caches werden nicht in-place umgebunden, expired Contexts fallen nie auf Pool
zurück und Multi-Parent-Setops bleiben unberührt.
```

- [ ] **Step 10: Delegiere Propagationshelper und alle Call-sites an `dbio-worker`**

Handoff prompt:

```text
Implementiere nur k195 in ResultSet.pm, Row.pm, Relationship/Base.pm,
Relationship/Codegen.pm, ResultSetColumn.pm, Manual/AsyncStorage.pod, ADR 0045
und `Changes` gegen den roten Diff. Nutze k196s with_context/ownership. Führe
einen zentralen privaten `_inherit_async_context($source,$target)` ein. Propagiere
nur Single-Parent-Pfade aus der Task; `_set_operation` und Custom-Inflators
bleiben unverändert. ResultSet::with_context verwirft geerbten result_cache;
Prefetch bindet neu erzeugte Childobjekte ohne Shared-In-place-Mutation. Cascade
copy nutzt bestehenden Refusal. Ändere keine Tests, Git-Index oder karr. Der
Changes-Eintrag nennt die geschlossenen Ableitungspfade und die ausgeschlossenen
Multi-Parent-/Custom-Inflator-Fälle.
```

- [ ] **Step 11: Implementiere den zentralen internen Propagationshelper**

In `DBIO::ResultSet` entsteht diese neue private Package-Naht:

```perl
sub _inherit_async_context {
  my ($source, $target) = @_;
  my $ctx = $source->{_async_context};
  return $target unless $ctx;
  return $target->with_context($ctx);
}
```

Row, Relationship::Base, generierter Code und ResultSetColumn rufen sie vollqualifiziert als `DBIO::ResultSet::_inherit_async_context($source,$target)`; sie duplizieren keine eigene Ownership-Logik.

- [ ] **Step 12: Mache `ResultSet::with_context` cache-isoliert**

Nach `my $clone = $self->search_rs` und vor dem Setzen des Contexts:

```perl
delete $clone->{_result_cache};
$clone->{_async_context} = $ctx;
```

Der Original-ResultSet und seine gecachten Rows werden weder geleert noch gestempelt; der erste Async-Read des Clones läuft durch den Pin.

- [ ] **Step 13: Propagiere ResultSet-Ableitungen**

Die Return-Pfade von `related_resultset`, `page`, `as_subselect_rs`, `correlate` und `bare` wickeln ihr neu erzeugtes ResultSet jeweils ein:

```perl
return DBIO::ResultSet::_inherit_async_context($self, $derived_rs);
```

`search_related` und `search_related_rs` erben über `related_resultset`; `limited_page` erbt über den korrigierten `page`-Pfad. `_set_operation` bleibt unverändert, weil es zwei Parents besitzt.

- [ ] **Step 14: Propagiere Row-Relationships und generierte Accessors**

`Relationship::Base::related_resultset` bindet sowohl Crosstable- als auch gewöhnlichen Return; `new_related` bindet die neue Row. Der generierte Single-Async-Accessor propagiert vom Row-Parent statt den von `_row_run_async` gewählten Dispatchweg zu verlieren:

```perl
my $related = DBIO::ResultSet::_inherit_async_context(
  $self,
  $self->search_related($rel),
);
return $related->single_async;
```

Bei einem bereits in `_relationship_data` gecachten Child liefert Codegen `DBIO::ResultSet::_inherit_async_context($self,$cached_child)` und mutiert das Shared Child nicht in-place. Der Multi-Accessor erbt über das korrigierte Row-`related_resultset`. Der von `_row_run_async` gelieferte `$backend` bleibt für ungebundene Rows der normale Pool-Dispatch und wird nicht künstlich als Context gespeichert.

- [ ] **Step 15: Propagiere Prefetch beim Core-Row-Inflator**

Der Worker erweitert ausschließlich den exakten Core-Row-Call um einen optionalen fünften, neuen internen Parameter. `ResultSet::_construct_results` ruft bei bereits nachgewiesenem `is_core_row` statt der aktuellen Vier-Argument-Form auf:

```perl
$_ = $inflator_cref->(
  $res_class,
  $rsrc,
  @$_,
  $self->{_async_context},
) for @$rows;
```

`DBIO::Row::inflate_result` erhält die vorgeschlagene interne Erweiterung:

```perl
sub inflate_result {
  my ($class, $rsrc, $me, $prefetch, $async_context) = @_;

  my $new = bless
    { _column_data => $me, _result_source => $rsrc },
    ref($class) || $class;
  $new->{_async_context} = $async_context if $async_context;
```

Weil `$new` vor `related_resultset($rel_name)` gestempelt ist, liefert der in Step 14 korrigierte Relationship-Pfad bereits einen gebundenen `$rel_rs`. Der Worker ersetzt die beiden rekursiven Calls durch einen lokalen Inflator, der den Context nur beim exakten Core-Coderef anhängt:

```perl
my $rel_rsrc = $rel_rs->result_source;
my $rel_class = $rel_rs->result_class;
my $rel_inflator = $rel_class->can('inflate_result');
my $inflate_one = sub {
  my @inflate_args = ($rel_rsrc, @_);
  push @inflate_args, $async_context
    if $async_context
      && $rel_inflator == \&DBIO::Row::inflate_result;
  return $rel_class->$rel_inflator(@inflate_args);
};

if (ref $prefetch->{$rel_name}[0] eq 'ARRAY') {
  @rel_objects = map { $inflate_one->(@$_) }
    @{ $prefetch->{$rel_name} };
}
else {
  @rel_objects = $inflate_one->(@{ $prefetch->{$rel_name} });
}
```

Der gebundene `$rel_rs` erhält erst danach mit `set_cache(\@rel_objects)` die bereits context-gebundenen Core-Child-Rows. Der bisherige Top-Level-only-Stempel in `ResultSet.pm:1751-1759` wird entfernt; Custom-Inflators erhalten keinen neuen Contextparameter und bleiben wie festgelegt außerhalb dieses Blocks.

- [ ] **Step 16: Propagiere Refresh, flachen Copy und Row-ResultSets**

`get_from_storage_async`, `self_rs` und `clean_rs` binden ihren frisch aus `result_source->resultset` erzeugten ResultSet vor Query. `discard_changes_async` ruft den context-erhaltenden Refreshpfad auf. Der flache `copy_async`-Zweig bindet die neue Row vor `insert_async`:

```perl
$new = DBIO::ResultSet::_inherit_async_context($self, $new);
return $new->insert_async;
```

Der Cascade-Zweig ruft statt synchronem `copy` die vorhandene `_async_ctx_or_sync_punt`-Refusal-Naht auf.

- [ ] **Step 17: Propagiere direkt gebundene RSCs auf ihren Parent**

`ResultSetColumn::with_context` setzt auf dem Clone nicht nur `{_async_context}`, sondern ersetzt den Parent durch einen context-gebundenen Clone und verwirft ein möglicherweise memoisiertes ungebundenes `{_resultset}`:

```perl
$clone->{_parent_resultset} =
  $self->{_parent_resultset}->with_context($ctx);
delete $clone->{_resultset};
```

Damit erben `func_rs` und `_resultset` ohne zusätzliche Sonderdispatches.

- [ ] **Step 18: Dokumentiere exakte Grenze**

ADR 0045 und `Manual::AsyncStorage` listen Relationships, generated Accessors, Page/limited_page, Subselect/correlate/bare, Prefetch Childs, Refresh/Discard, flachen Copy, self_rs/clean_rs und RSC-Derivationen. Sie halten ausdrücklich fest: kein Multi-Parent-Setop, kein Custom-Inflator-Vertrag, kein In-place-Rebinding warmer Shared Caches.

- [ ] **Step 19: Führe k195 fokussiert grün aus**

```bash
set -o pipefail
maint/capped-test prove -l \
  t/resultset/with_context.t \
  t/resultset/async_backend.t \
  2>&1 | tee /tmp/dbio-k195-focused.log
```

Expected: PASS; jeder neue Zeuge prüft Connection-ID beziehungsweise pinned Capture und Cache-Isolation.

- [ ] **Step 20: Führe die vollständige rekursive Suite aus**

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-k195-full.log
```

Expected: Exit 0, `Result: PASS`.

- [ ] **Step 21: Installiere den abgeschlossenen Core**

```bash
set -o pipefail
maint/capped-test dzil install 2>&1 | tee /tmp/dbio-k195-install.log
```

Expected: Exit 0.

- [ ] **Step 22: Stage k195 exakt**

```bash
git add -- \
  Changes \
  lib/DBIO/ResultSet.pm \
  lib/DBIO/Row.pm \
  lib/DBIO/Relationship/Base.pm \
  lib/DBIO/Relationship/Codegen.pm \
  lib/DBIO/ResultSetColumn.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0045-resultset-async-pinned-context.md \
  t/resultset/with_context.t
```

Expected: neun Ticketdateien sind gestaged.

- [ ] **Step 23: Prüfe den k195-Cached-Diff**

```bash
git diff --cached --check
test -z "$(git diff --cached --name-only -- \
  .claude/skills/kanban-issues-karr-cli/SKILL.md)"
git diff --cached --name-only
```

Expected: exakt neun Dateien.

- [ ] **Step 24: Committe k195 lokal**

```bash
git commit \
  -m "fix(async): propagate pinned contexts through derivations (karr k195)" \
  -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: genau ein lokaler k195-Commit.

- [ ] **Step 25: Übergib k195 Main-seitig und seriell**

```bash
TICKET_ID=195
CLAIM=$(karr agent-name)
FOCUSED=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k195-focused.log)
FULL=$(perl -ne '$s=$1 if /(Files=\d+,\s+Tests=\d+)/; END { print $s }' \
  /tmp/dbio-k195-full.log)
karr handoff "$TICKET_ID" --claim "$CLAIM" \
  --note "Commit $(git rev-parse --short HEAD). Focused: $FOCUSED, Result: PASS. Full: $FULL, Result: PASS. maint/capped-test dzil install: PASS. Single-parent relationships/derivations, nested prefetch, refresh/copy/RSC and warm-cache isolation verified by connection identity." \
  -t
```

Expected: k195 in `review`; erst danach darf Main k193 claimen.

**k195 rollback:**

```bash
git restore --staged -- .
git restore --worktree -- \
  Changes \
  lib/DBIO/ResultSet.pm \
  lib/DBIO/Row.pm \
  lib/DBIO/Relationship/Base.pm \
  lib/DBIO/Relationship/Codegen.pm \
  lib/DBIO/ResultSetColumn.pm \
  lib/DBIO/Manual/AsyncStorage.pod \
  docs/adr/0045-resultset-async-pinned-context.md \
  t/resultset/with_context.t
git status --short
```
