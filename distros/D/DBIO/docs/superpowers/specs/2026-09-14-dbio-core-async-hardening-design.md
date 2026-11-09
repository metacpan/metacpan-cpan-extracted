# DBIO Core Async Hardening

**Status:** freigegebener Entwurf, ausstehende Dateisichtung  
**Datum:** 2026-09-14  
**Scope:** k193–k200 sowie Testinfrastruktur k202  
**Nicht im Scope:** k201, neue öffentliche Cancellation-/Timeout-/Streaming-APIs, echte Driver-I/O

## Ausgangslage

DBIO Core besitzt eine echte, transportunabhängige Async-Orchestrierung mit Backend-Auflösung, SQL-Erzeugung, Pooling, Transaction-/Pipeline-Contexts und ORM-Inflation. Die konkrete Event-Loop- und I/O-Implementierung liegt in Driver- beziehungsweise Async-Distributionen außerhalb von Core.

Eine statische Analyse und ein adversarial Offline-Repro haben neun Fehler bestätigt. Vier betreffen Ergebniskorrektheit oder Transaktionsisolation, zwei den Pool-Lebenszyklus und drei die Parität öffentlicher Async-Verträge. Der Repro lief gemeinsam mit den bestehenden Kontrolltests über `maint/capped-test`: 5 Dateien, 211 Tests, PASS, keine Skips. Ein PASS des adversarial Tests bedeutet, dass das jeweilige unerwünschte Verhalten beobachtet wurde.

Gleichzeitig hängen mehrere rein interne Core-Async-Tests unnötig von der optionalen CPAN-Distribution `Future` ab oder verwenden sofort fertige lokale Future-Doubles. Dadurch bleiben pending Zwischenzustände und Sequencing-Fehler unsichtbar.

## Ziele

1. Die bestätigten und ohne neue Produktentscheidung lösbaren Fehler k193–k200 schließen.
2. Die drei notwendigen Scope-Entscheidungen für Context-Ownership, Context-Propagation und Pool-Shutdown festlegen.
3. Core-Async-Verträge deterministisch ohne externe Async-Library oder Event Loop testen.
4. Sync-/Async-Parität dort wiederherstellen, wo vorhandene ADRs den Claim bereits festlegen.
5. Jeden Fix durch einen roten Mock-Zeugen, fokussierte Tests, die vollständige rekursive Suite und `dzil install` absichern.
6. Änderungen ticketweise klein, reviewbar und lokal committed halten.

## Nicht-Ziele

- k201 und die Entscheidung über die kanonische direkte Storage-Ergebnisform von `immediate`.
- Ein neuer allgemeiner öffentlicher Future-Vertrag für Driver.
- Cancellation, Query-Timeout, Streaming oder Backpressure.
- Echte Socket-/FD-Wakeups, Event-Loop-Integration, GC-/`retain`-Semantik oder reale Pipeline-Wire-Abschlüsse.
- Änderungen in Driver-Repositories.
- Änderungen an `@ISA` oder Composition-Architektur.
- Release, CPAN-Upload oder Git-Push.

## Gewählter Ansatz

Der Gesamtblock wird seriell in neun fachliche Inkremente zerlegt. Zuerst entsteht eine test-only Deferred-Future, anschließend werden Backend-Refusal, Context-Lebenszyklus und -Ownership, Query-Parität, Pool-Lebenszyklus und DDL-Parität geschlossen.

Die Alternative, nur die völlig lokalen Fixes umzusetzen, wurde verworfen, weil sie die bestätigten kritischen Cross-Storage- und Context-Propagation-Fehler offen ließe. Ein großer öffentlicher Async-Contract-Umbau wurde verworfen, weil er bestätigte Bugs mit neuen APIs und nicht entschiedener Semantik vermischen würde.

## Testarchitektur: k202

### Zweck

`DBIO::Test::Future` wird eine ausgelieferte, ausschließlich für Tests bestimmte manuell erfüllbare Deferred-Future. Sie ist kein Produktionsdefault, kein Async-Modus und keine Subklasse von `DBIO::Future::Immediate`.

Datei:

- `lib/DBIO/Test/Future.pm`

Eigener Contract-Test:

- `t/test/31_test_future.t`

### Unterstützte Semantik

- `new` erzeugt pending.
- Klassen- und Objektform von `done(@values)` und `fail($error)`.
- `is_ready`, `is_failed`, `get`.
- `then($on_done, $on_fail?)` und `catch($on_fail)`.
- Pending Callbacks werden FIFO registriert und genau einmal ausgeführt.
- Callback-Rückgaben werden im Skalarkontext ausgewertet.
- Callback-Ausnahmen failen die abgeleitete Future.
- Eine zurückgegebene `DBIO::Test::Future` wird auch pending geflattet.
- Doppelte Erfüllung wird laut verweigert.
- `get` auf pending wirft; der Helper blockiert und pollt nie.
- `needs_all` verbindet mehrere Test-Futures für Pipeline-Vertragstests.

Bewusst nicht angeboten werden `on_ready`, `on_fail`, `failure`, `is_done`, `await`, `cancel` oder eine vorgetäuschte `retain`-Semantik. Bestehende Tests werden auf den kleinen Core-Vertrag umgestellt, statt den Helper zu einer unvollständigen CPAN-`Future`-Kopie aufzublasen.

### Migration

Lokale sofort fertige Future-Doubles werden schrittweise ersetzt in:

- `t/test/15_async_orchestration.t`
- `t/test/16_async_future_io_convention.t`
- `t/test/19_async_deploy.t`
- `t/resultset/with_context.t`

Die Whole-File-Skips bei fehlendem CPAN `Future` entfallen aus:

- `t/storage/pool_base.t`
- `t/storage/pool_readiness.t`
- `t/storage/pool_ready_wiring.t`
- `t/storage/pool_connect_actions.t`
- `t/storage/async_connect_info_leak.t`
- `t/storage/async_access_broker.t`
- `t/composed/async_mirror.t`

`DBIO::Test::Storage` bleibt bewusst Immediate. Tests, die Pending-Zustände benötigen, wählen `DBIO::Test::Future` explizit als `future_class` einer lokalen Fake-Backend-/Pool-Klasse.

### Grenze zum öffentlichen Vertrag

`DBIO::Test::Future` darf mehr Testkomfort bieten als `DBIO::Future->validate` derzeit prüft. Daraus entsteht in k202 keine neue Driver-Anforderung. Eine spätere Erweiterung des öffentlichen Future-Vertrags braucht eine eigene Contract-/ADR-Entscheidung.

## Runtime-Inkremente

### k200 — falsches Backend laut verweigern

ADR 0030 verbietet stillen Sync-Fallback. `register_async_mode` bleibt lazy; nach Laden und Auflösung muss aber jedes Ziel außer dem expliziten Modus `immediate` von `DBIO::Storage::Async` erben.

Änderungen:

- `lib/DBIO/Storage/DBI.pm`: Backendklasse nach der lazy Auflösung validieren.
- `lib/DBIO/Storage.pm`: Sync-Dispatch ausschließlich bei `mode eq 'immediate'` erlauben.
- Fehler über die bestehende DBIO-Exception-Taxonomie mit Modus und Klasse melden.
- Den separaten Layer-Skip aus k159 nicht verändern.

Zeugen:

- `t/test/14_async_backend.t`
- `t/test/17_async_future_io_mro_walk.t`
- `t/test/20_async_future_io_unloadable_adapter.t`

### k194 — TransactionContext terminal machen

ADR 0045 bindet den Context an die Dauer der Transaktion. `txn_do_async` erhält einen zentralen Finalizer nach erfolgreichem Acquire:

1. Context invalidieren.
2. Connection genau einmal freigeben.
3. Ergebnis oder die bestehende Fehlerpräzedenz weiterreichen.

COMMIT- und ROLLBACK-Zweige releasen nicht mehr separat. Direkte Context-CRUD-Einstiege und verschachteltes `txn_do_async` prüfen die Aktivität. `in_txn` ist nach Abschluss false.

Zeugen decken Commit, Commitfehler, Callback-Throw, failed Callback-Future, Rollback, Rollbackfehler, Beginfehler und synchrone Seam-Throws ab. Nach erfolgreichem Acquire erfolgt genau ein Release; nach Acquirefehler keines.

Dateien:

- `lib/DBIO/Storage/Async.pm`
- `lib/DBIO/Storage/Async/TransactionContext.pm`
- `t/test/15_async_orchestration.t`
- `t/resultset/with_context.t`
- Klarstellung in ADR 0045 und AsyncStorage-POD

### k196 — generation-scoped Context-Ownership

Jede aktuelle Async-Backend-/Pool-Generation erhält ein opakes Ownership-Token. Sync-Owner, eingebettetes Async-Backend und von ihm erzeugte Transaction-/Pipeline-Contexts teilen dieses Token.

Regeln:

- `with_context` prüft das Token auf ResultSet, Row und ResultSetColumn.
- Der Dispatch prüft erneut, damit manuell konstruierte oder später veraltete Objekte fail-closed bleiben.
- Ein Backend-Rebuild infolge neuer `connect_info` erzeugt eine neue Generation und damit ein neues Token.
- Composed Storages teilen das Token ihres tatsächlichen Owners; Klassenname, DSN und Schema-Klasse sind keine Ownership-Identität.
- Fremde, abgelaufene oder nicht nachweisbare Ownership wird vor jedem Query-Dispatch verweigert.
- Externe Context-Klassen ohne diesen Core-Nachweis werden in diesem Inkrement nicht als pinning-fähig akzeptiert.

Dateien:

- `lib/DBIO/Storage/DBI.pm`
- `lib/DBIO/Storage/Async.pm`
- `lib/DBIO/Storage/Async/TransactionContext.pm`
- `lib/DBIO/Storage/Async/PipelineContext.pm`
- `lib/DBIO/ResultSet.pm`
- `lib/DBIO/Row.pm`
- `lib/DBIO/ResultSetColumn.pm`
- `t/resultset/with_context.t`
- `t/composed/async_mirror.t`
- Amendment zu ADR 0045

### k195 — Context-Propagation über Single-Parent-Ableitungen

Ein zentraler interner Helper propagiert denselben Context über alle eindeutigen Single-Parent-Ableitungen:

- ResultSet- und Row-Relationships,
- generierte Single-Relationship-Async-Accessors,
- `page` und `limited_page`,
- `as_subselect_rs`,
- Prefetch-Child-ResultSets und Child-Rows,
- `get_from_storage_async` und `discard_changes_async`,
- flaches `copy_async`,
- ResultSetColumn-Ableitungen.

Regeln:

- Cascade-`copy_async` unter gebundenem Context benutzt den bestehenden Refusal-Pfad.
- Gemeinsam genutzte warme Cacheobjekte werden nie in-place umgebunden. `with_context` liefert einen gebundenen ResultSet-Klon ohne übernommenen `_result_cache`; der ursprüngliche Cache bleibt unverändert, und der erste Async-Read des Klons lädt über den Pin neu.
- Multi-Parent-Setops und Custom-Inflators liegen außerhalb dieses Blocks; sie benötigen ein eigenes ADR-Amendment.
- Ein abgelaufener Context darf niemals still auf Pool-Dispatch zurückfallen.

Tests prüfen die tatsächlich verwendete Connection, nicht nur den internen Context-Slot.

Dateien:

- `lib/DBIO/ResultSet.pm`
- `lib/DBIO/Row.pm`
- `lib/DBIO/Relationship/Base.pm`
- `lib/DBIO/Relationship/Codegen.pm`
- `lib/DBIO/ResultSetColumn.pm`
- `t/resultset/with_context.t`
- Klarstellung in ADR 0045

### k193 — Async-Select-Parität

Async-SELECT wird durch dieselbe Vorbereitung wie Sync geführt, insbesondere über den Owner-Storage und `_select_args`. Dadurch werden übernommen:

- `rows`-/`offset`-Validierung,
- Offset-only-Normalisierung,
- Join-Pruning,
- Complex-Prefetch-Rewrite,
- Software-Limit auf rohen Zeilen vor Inflation und Collapse.

Fertige Hauptobjekte erst nach Collapse zu slicen ist ausdrücklich nicht zulässig, weil das die synchrone Semantik verändert und Children abschneiden kann.

Tests prüfen tatsächliche Ergebnis-IDs und vollständige Children für `software_limit`, `rows`, `offset`, Offset-only und Collapse/Prefetch sowie identische Diagnosen bei ungültigen Werten.

Dateien:

- `lib/DBIO/Storage/Async.pm`
- `lib/DBIO/ResultSet.pm`
- keine neue DBI-Hilfs-API: `DBIO::Storage::Async` ruft die bestehende `_select_args`-Naht des owning Sync-Storage auf
- `t/test/15_async_orchestration.t`
- `t/resultset/async_backend.t`

Kein ADR: Der bestehende Sync-Paritätsclaim wird wiederhergestellt.

### k197 — Readiness-Fehler retiren

Der zentrale Readiness-Gate erhält eine Failure-Continuation. Sie entfernt die Connection genau einmal über `_retire_connection`, räumt Readiness-Bookkeeping auf und fährt die Connection best-effort herunter. Der ursprüngliche Fehler bleibt eine failed Future; es gibt keinen synchronen Wurf.

`_retire_connection` wird idempotent. Eine nie ready gewordene Connection führt keine Disconnect-Actions aus. Nach einem Fehler steht die Kapazität sofort für einen Ersatz-Spawn zur Verfügung.

Dateien:

- `lib/DBIO/Storage/PoolBase.pm`
- `t/storage/pool_readiness.t`
- `t/storage/pool_ready_wiring.t`
- Referenztest `t/storage/pool_connect_actions.t`

### k198 — terminaler Pool-Shutdown

Shutdown ist terminal für eine Poolinstanz:

- Alle Queue-Waiter und readiness-pending Acquires werden mit einer eindeutigen failed Future beendet.
- Waiter werden vor Settlement aus internen Queues entfernt.
- Neue `acquire`- und `acquire_txn`-Aufrufe nach Shutdown liefern failed Futures.
- Späte Releases alter Handles füllen weder Idle-Liste noch alte Waiter.
- Wiederholter Shutdown ist idempotent.
- Der höhere DBIO-Reconnect-Pfad erzeugt Backend und Pool neu; Restartbarkeit derselben Poolinstanz ist kein Ziel.

Dateien:

- `lib/DBIO/Storage/PoolBase.pm`
- `lib/DBIO/Storage/Pool.pm`
- `lib/DBIO/Storage/Async.pm` und `lib/DBIO/Storage/DBI.pm` bleiben im Runtime-Pfad unverändert; `t/test/14_async_backend.t` bezeugt, dass Reconnect eine neue Backend-/Poolinstanz erzeugt
- `t/storage/pool_base.t`
- `t/storage/pool_readiness.t`
- `t/storage/pool_ready_wiring.t`
- Reconnect-Zeuge `t/test/14_async_backend.t`
- Amendment zu ADR 0030

### k199 — per-Statement Async-DDL

Die in k132 und ADR 0026 entschiedene synchrone Gruppierung wird async gespiegelt:

1. Statements vor dem ersten Acquire einmal über den Hook des owning Sync-Storage klassifizieren, aber nur wenn `transactional_ddl` global true ist.
2. Aufeinanderfolgende gleiche Antworten in Originalreihenfolge zu Läufen gruppieren.
3. Ein transaktionaler Lauf läuft in genau einem `txn_do_async`.
4. Ein nichttransaktionaler Lauf erhält eine explizit gepinnte Connection ohne BEGIN/COMMIT.
5. Läufe sind strikt seriell; nach dem ersten Fehler beginnt kein weiterer Acquire.
6. Jede Connection wird bei Erfolg, failed Future und synchronem Throw genau einmal freigegeben.

Fälle: `[T][N][T]`, benachbarte `N`, global false, Default true, Hookfehler vor Acquire, Fehler in beiden Lauftypen, Reihenfolge und Release-Zähler.

Dateien:

- `lib/DBIO/Storage/Async.pm`
- `t/test/19_async_deploy.t`
- Referenz `lib/DBIO/Deploy/Base.pm` und `t/deploy-base.t`
- Async-Paritätsnachtrag zu ADR 0026

Der bestehende synchrone Warntext zählt Läufe, nennt sie aber Statements. Diese Formulierung wird als erste Phase von k199 korrigiert und gemeinsam mit der Async-Parität in demselben Ticket-Commit geliefert.

## Reihenfolge und Abhängigkeiten

```text
k202 test-only Future
  → k200 Backend-Refusal
  → k194 Context-Lifecycle
  → k196 Context-Ownership
  → k195 Context-Propagation
  → k193 Select-Parität
  → k197 Readiness-Retire
  → k198 terminaler Shutdown
  → k199 DDL-Warntext-Korrektur + Async-DDL-Gruppierung
```

Harte beziehungsweise fachliche Abhängigkeiten:

- k194 und k196 vor k195.
- k197 vor k198.
- k194 vor k199.
- Die freigegebene Entscheidung für terminalen Shutdown definiert die Pool-Generation, die k196s Ownership-Modell benötigt; k198 muss dafür nicht vor k196 implementiert sein.
- k193 und k200 sind technisch unabhängig, stehen aber aus Risikogründen früh.

## Fehlersemantik

- Konfigurations- und Contract-Fehler werden synchron und über die bestehende DBIO-Exception-Taxonomie geworfen.
- Operationelle Fehler nach Erzeugung einer Future erscheinen als failed Future.
- Cleanup darf den ursprünglichen Fehler nicht still ersetzen; bestehende, bereits dokumentierte Fehlerpräzedenz bleibt erhalten, sofern das jeweilige Ticket sie nicht ausdrücklich testet und ändert.
- Jede erworbene Pool-Connection wird auf jedem terminalen Pfad genau einmal freigegeben oder retirert.
- Abgelaufene, fremde oder nicht beweisbar zugehörige Contexts fallen nie auf ungepinnten Pool-Dispatch zurück.

## Teststrategie

Für jedes Runtime-Ticket gilt TDD:

1. `dbio-test-mock-writer` schreibt den kleinstmöglichen roten Test mit `DBIO::Test::Storage` beziehungsweise `DBIO::Test::Future`.
2. Der rote Test wird einzeln über `maint/capped-test prove -l <datei>` ausgeführt; die Behauptung des Tests wird vor dem Fix festgehalten.
3. `dbio-worker` implementiert die kleinste Änderung, die denselben Claim erfüllt.
4. Fokussierter Testlauf über `maint/capped-test`.
5. Vollständiger rekursiver Lauf über `maint/capped-test dzil test`.
6. Nach abgeschlossenem Ticket `dzil install`.

Keine reale Datenbank, kein SQLite-DSN und kein Event Loop in Core-Tests. Reale I/O-Verträge bleiben in den Driver-Distributionen und werden in diesem Block nicht parallel gestartet.

## Ticket-, Review- und Git-Workflow

- Die Tickets werden seriell bearbeitet; nur das aktuelle Ticket wird nach `in-progress` bewegt und geclaimt.
- Tests und Runtime-Code werden an die dafür vorgesehenen DBIO-Agenten delegiert.
- Nach jedem signifikanten Schritt werden Diff und Testclaim geprüft.
- Pro abgeschlossenem Ticket entsteht ein lokaler Commit mit kNN-Referenz und vorgeschriebener Claude-Code-Attribution.
- Nur ticketrelevante Dateien werden gestaged. `.claude/skills/kanban-issues-karr-cli/SKILL.md` ist in `a400d55f` bereits übernommen und bleibt aus allen Async-Hardening-Commits ausgeschlossen.
- Danach wird das Ticket mit Testzahlen und Commit-ID in Review übergeben.
- karr-Mutationen erfolgen strikt seriell.
- Kein Git-Push und kein Release ohne neue ausdrückliche Anweisung.

## Erfolgskriterien des Gesamtblocks

- k193–k200 sind umgesetzt oder ein während TDD sichtbar gewordener echter Widerspruch ist mit präzisem Blocker am Ticket dokumentiert.
- k202 entfernt die optionale CPAN-`Future`-Abhängigkeit aus den sieben rein offline testbaren Dateien.
- Die neun ursprünglich reproduzierten Fehler sind durch permanente Regressionstests abgedeckt; kein Test wird durch Abschwächen seines Claims grün gemacht.
- Jede Ticket-Suite und die abschließende vollständige Suite laufen über `maint/capped-test` ohne Skips in den berührten Tests.
- `dzil install` wurde nach jedem abgeschlossenen Ticket ausgeführt.
- Der Arbeitsbaum ist am Ende clean. Der zuvor unstaged geänderte karr-Skill wurde während der Planerstellung extern in Commit `a400d55f` übernommen; kein Ticket darf ihn erneut ändern oder stagen. Wird ein Ticket blockiert, werden seine partiellen Codeänderungen vor dem nächsten Ticket zurückgenommen und der Blocker ausschließlich auf der karr-Karte dokumentiert; keine fremde Änderung wird committed.
