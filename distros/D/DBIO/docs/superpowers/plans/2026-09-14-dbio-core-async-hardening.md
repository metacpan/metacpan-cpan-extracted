# DBIO Core Async Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die bestätigten Core-Async-Fehler k193–k200 mit der test-only Deferred-Future aus k202 seriell schließen, ohne neue öffentliche Async-API oder Driver-I/O einzuführen.

**Architecture:** Die Arbeit läuft als neun einzeln review- und commitbare Ticket-Inkremente auf `main`: zuerst die deterministische Test-Future, dann Backend- und Context-Sicherheit, Select- und Pool-Parität und zuletzt DDL-Parität. Pro Ticket schreibt `dbio-test-mock-writer` ausschließlich den roten Mock-Zeugen, `dbio-worker` ausschließlich Runtime-/POD-/ADR-Code, und der orchestrierende Main besitzt Claim, Diff-Gates, Verifikation, exaktes Staging, lokalen Commit und den seriellen karr-Handoff.

**Tech Stack:** Perl 5, `DBIO::Test::Storage`, `DBIO::Test::Future`, `Test::More`, DBIO-Exception-Taxonomie, Class::Accessor::Grouped, Dist::Zilla, `maint/capped-test`, karr.

**Spec:** `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`

## Global Constraints

- Verbindliche Reihenfolge: k202 → k200 → k194 → k196 → k195 → k193 → k197 → k198 → k199.
- k201, die direkte `immediate`-Storage-Ergebnisform, neue Cancellation-/Timeout-/Streaming-/Backpressure-APIs und echter Driver-I/O bleiben außerhalb des Scopes.
- Core-Tests verwenden ausschließlich `DBIO::Test::Storage` und `DBIO::Test::Future`; kein SQLite-DSN, keine reale Datenbank und kein Event Loop.
- `DBIO::Test::Storage` bleibt Immediate; pending Tests setzen `future_class` explizit auf `DBIO::Test::Future`.
- Keine Änderung an `@ISA`, Storage-Layer-Composition oder Driver-Repositories.
- Contract-/Konfigurationsfehler werfen synchron über `DBIO::Exception`; operationelle Fehler nach Erzeugung einer Future bleiben failed Futures.
- Jede nach erfolgreichem Acquire erhaltene Connection wird auf jedem terminalen Pfad genau einmal released oder retired; Cleanup ersetzt den ursprünglichen Fehler nicht still.
- Fremde, veraltete oder nicht beweisbar zugehörige Contexts fallen nie auf Pool-Dispatch zurück.
- Pro Ticket genau ein lokaler Commit mit `kNN` und `Co-Authored-By: Claude Code <noreply@anthropic.com>`; der kleine synchrone DDL-Warntext-Fix gehört in den k199-Commit.
- Jedes Ticket ergänzt `Changes` im passenden Abschnitt mit seiner öffentlichen oder testinfrastrukturellen Wirkung; `Changes` wird im jeweiligen Ticket-Commit exakt mitgestaged.
- Nur der orchestrierende Main verändert Git-Index, Commit-Historie oder karr. Test- und Produktionsagenten committen nicht und mutieren karr nicht.
- Der zuvor unstaged geänderte karr-Skill wurde während der Planerstellung extern in Commit `a400d55f` übernommen. Der Arbeitsbaum ist nach dem Plan-Commit clean; `.claude/skills/kanban-issues-karr-cli/SKILL.md` bleibt dennoch als nicht ticketrelevanter Pfad aus jedem k193–k202-Commit ausgeschlossen.
- Nach jedem Ticket: fokussierte Tests und `maint/capped-test dzil test`, danach `maint/capped-test dzil install`, erst dann Commit und Main-seitiger karr-Handoff.
- Kein Git-Push, kein `dzil release`, kein CPAN-Upload.

---

## Dateistruktur und Teilplan-Grenzen

| Teilplan | Tickets | Verantwortete Dateien und Verantwortung |
|---|---|---|
| `docs/superpowers/plans/2026-09-14-dbio-test-future.md` | k202 | `lib/DBIO/Test/Future.pm` als manuell erfüllbare test-only Future; Contract-Test; Migration von vier lokalen Doubles und sieben CPAN-`Future`-Skips. |
| `docs/superpowers/plans/2026-09-14-dbio-async-context-safety.md` | k200, k194, k196, k195 | Backend-Verweigerung; terminaler TransactionContext; generation-scoped Ownership; Context-Propagation über eindeutige Single-Parent-Ableitungen. |
| `docs/superpowers/plans/2026-09-14-dbio-async-query-pool.md` | k193, k197, k198 | Sync-parallele Select-Vorbereitung und Raw-Row-Grenze; idempotentes Readiness-Retire; terminaler Pool-Shutdown. |
| `docs/superpowers/plans/2026-09-14-dbio-async-ddl.md` | k199 | Synchroner Warntext und async per-Statement-DDL-Gruppierung in demselben Ticket und Commit. |
| `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md` | alle | Freigegebene Semantik und Scope-Grenze; jeder Agent liest sie zusätzlich zu seinem Teilplan. |

## Schnittstellen zwischen den Teilplänen

1. **k202 produziert die Test-Naht für alle Folgetickets.** `DBIO::Test::Future->new`, Klassen-/Objekt-`done` und `fail`, `is_ready`, `is_failed`, `get`, `then`, `catch` und `needs_all` stehen nach k202 zur Verfügung. Kein Folgeticket erweitert diesen Helper nebenbei.
2. **k200 schließt den Dispatch vor Context-Arbeit.** Nur `immediate` darf ohne `DBIO::Storage::Async` synchron dispatchen; k194–k199 dürfen deshalb von einem echten Async-Backend ausgehen.
3. **k194 produziert den terminalen TransactionContext.** Der zentrale Finalizer invalidiert den Context und released genau einmal; k195 und k199 bauen auf diesem Abschlussvertrag auf und duplizieren kein Release in COMMIT-/ROLLBACK-Zweigen.
4. **k196 produziert die generation-scoped Ownership-Identität.** Sync-Owner, eingebettetes Async-Backend, `TransactionContext` und `PipelineContext` teilen dasselbe opake Token. k195 propagiert nur bereits validierte Contexts und k193 dispatcht weiterhin gegen deren verifizierten Owner.
5. **k195 produziert die Single-Parent-Propagationsnaht.** ResultSet-, Row-, Relationship- und ResultSetColumn-Ableitungen reichen denselben Context weiter; Multi-Parent-Setops und Custom-Inflators bleiben ausgeschlossen.
6. **k193 konsumiert den owning Sync-Storage.** `DBIO::Storage::Async` benutzt dessen bestehende `_select_args`-Naht; es entsteht keine neue DBI-Hilfs-API und die Fake-Cursor-Invariante bleibt erhalten.
7. **k197 produziert idempotentes `_retire_connection`.** k198 darf Shutdown-, Late-release- und Readiness-Rennen darüber bereinigen, ohne eine zweite Retirement-Semantik einzuführen.
8. **k198 macht jede Poolinstanz terminal.** Reconnect erzeugt über den höheren DBIO-Pfad Backend und Pool neu; k196s neues Ownership-Token unterscheidet diese Generationen.
9. **k199 konsumiert k194 und k202.** Transaktionale DDL-Läufe verwenden `txn_do_async`; nichttransaktionale Läufe verwenden eine explizit gepinnte Connection und denselben Exactly-once-Cleanup-Anspruch.

## Dateisichtungsnachträge zur freigegebenen Spec

- **k199-Wortlaut:** Die Spec legt nach ihrer Dateisichtung fest, dass synchrone Warntextkorrektur und Async-DDL-Parität als zwei TDD-Phasen desselben k199-Tickets in genau einem Commit landen.
- **k202-Dateiliste:** Die neue `DBIO::Test::Future::catch`-Methode erfordert zusätzlich `t/55namespaces_cleaned.t`; außerdem enthält `dist.ini` noch den falschen Satz, der Helper sei entfernt. Beide notwendigen Begleitdateien sind im k202-Staging enthalten; `cpanfile` bleibt unverändert.
- **k198-Zeuge:** `t/test/14_async_backend.t:229-243` belegt aktuell nur Teardown, noch keinen neuen Backend-/Pool-refaddr. k198 erweitert die Fixture explizit, statt den vorhandenen Test fälschlich als Reconnect-Zeugen zu bezeichnen.
- **k193-Pruning-Fixture:** `Artist` mit `join => 'cds'` ist wegen des multiplying Join kein Pruning-Zeuge. Der Plan verwendet die bereits belegte `CD`-Form `join => 'artist', prefetch => 'tracks', rows => 2` aus `t/test/08_replicated.t:522-541`.
- **k196-Poolgeneration:** Ein Async-Backendobjekt kann `disconnect` überleben und lazy einen neuen Pool liefern. Contexts snapshotten deshalb das Token bei Construction; `Storage::Async::connect_info` und `disconnect` rotieren es zusätzlich zum DBI-Backend-Rebuild.

## Rollen- und Artefaktprotokoll pro Ticket

### Test-Handoff an `dbio-test-mock-writer`

Der Main übergibt genau diese Artefakte:

- freigegebene Spec: `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`;
- den zum Ticket gehörenden Teilplan und die konkrete Task-Überschrift;
- den aktuellen `karr show $TICKET_ID`-Text, wobei jede Ticket-Task `TICKET_ID` auf ihre feste bare Zahl setzt;
- die erlaubte Test-Dateiliste und den vor dem Fix geltenden Claim;
- bei k194–k199 die bereits grüne `DBIO::Test::Future` aus k202;
- bei abhängigen Tickets die Commit-ID des unmittelbar benötigten Vorgängers.

Der Testagent liefert ausschließlich:

- einen uncommitteten Test-Diff in den erlaubten Testdateien;
- exakte neue Subtest-/Testnamen;
- den fokussierten `maint/capped-test`-Befehl;
- die beobachtete rote Diagnose und eine Ein-Satz-Formulierung des Claims;
- die Bestätigung, dass weder Produktionsdateien noch Git-Index noch karr verändert wurden.

### Produktions-Handoff an `dbio-worker`

Der Main übergibt genau diese Artefakte:

- denselben Spec- und Teilplanpfad;
- den vom Main geprüften roten Test-Diff, der im Arbeitsbaum liegen bleibt;
- den exakten roten Befehl und seine Diagnose;
- die erlaubte Produktions-/POD-/ADR-Dateiliste;
- die relevanten Vorgänger-Commit-IDs und die in „Schnittstellen“ benannten Contracts.

Der Produktionsagent liefert ausschließlich:

- einen uncommitteten Produktions-/POD-/ADR-Diff in der erlaubten Dateiliste;
- die Liste der geänderten Methoden;
- den fokussierten grünen Testbefehl samt Resultat;
- eine Bestätigung, dass der Testclaim nicht abgeschwächt wurde;
- die Bestätigung, dass weder Tests, Git-Index noch karr verändert wurden.

### Main-Gates

Der Main konsumiert beide Diffs und übernimmt allein:

1. Claim-/Statusprüfung und `in-progress`-Move.
2. Prüfung des roten Claims vor Produktionsarbeit.
3. Prüfung von Test- und Produktions-Diff gegen die Allowlist.
4. Fokussierte und vollständige capped Verifikation sowie capped Installation.
5. Exaktes Staging, Cached-Diff-Prüfung und lokalen Commit.
6. Handoff nach `review` mit Commit-ID und realen Testzahlen.

---

### Task 1: Ausgangszustand und serielle Ausführung sperren

**Files:**
- Read: `docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md`
- Read: alle vier Teilpläne unter `docs/superpowers/plans/2026-09-14-dbio-*.md`
- Protect from ticket commits: `.claude/skills/kanban-issues-karr-cli/SKILL.md`

**Interfaces:**
- Consumes: freigegebene Spec und die vier ausführbaren Teilpläne.
- Produces: einen belegten cleanen Ausgangszustand nach dem Plan-Commit, in dem genau ein Ticket zur Zeit geclaimt werden darf.

- [ ] **Step 1: Lies die freigegebene Spec vollständig**

Run:

```bash
perl -ne 'print' docs/superpowers/specs/2026-09-14-dbio-core-async-hardening-design.md
```

Expected: Scope nennt k193–k200 und k202; k201 und Driver-I/O sind ausgeschlossen.

- [ ] **Step 2: Lies die vier ausführbaren Teilpläne vollständig**

Run:

```bash
perl -ne 'print' \
  docs/superpowers/plans/2026-09-14-dbio-test-future.md \
  docs/superpowers/plans/2026-09-14-dbio-async-context-safety.md \
  docs/superpowers/plans/2026-09-14-dbio-async-query-pool.md \
  docs/superpowers/plans/2026-09-14-dbio-async-ddl.md
```

Expected: Die Ticketreihenfolge ist in allen Dokumenten mit der Masterreihenfolge vereinbar.

- [ ] **Step 3: Prüfe den Git-Ausgangszustand, ohne etwas zu stagen**

Run:

```bash
git status --short
```

Expected beim Start der Ticketserie: keine Ausgabe. Falls die fünf Plan-Dateien noch untracked oder unstaged erscheinen, beginnt die Ticketserie nicht; sie werden zuerst als eigener Planungsstand committed und dürfen nie in einen k193–k202-Commit geraten.

- [ ] **Step 4: Prüfe, dass kein Index-Inhalt vorliegt**

Run:

```bash
test -z "$(git diff --cached --name-only)"
```

Expected: Exit 0 und keine Ausgabe.

- [ ] **Step 5: Prüfe, dass kein anderes Async-Hardening-Ticket aktiv geclaimt ist**

Run:

```bash
for id in 202 200 194 196 195 193 197 198 199; do
  karr show "$id" --compact
done
```

Expected: Vor k202 steht keines der neun Tickets in `in-progress` oder `review` unter einem fremden Claim.

---

### Task 2: Tickets in der verbindlichen Reihenfolge ausführen

**Files:**
- Execute: `docs/superpowers/plans/2026-09-14-dbio-test-future.md`
- Execute: `docs/superpowers/plans/2026-09-14-dbio-async-context-safety.md`
- Execute: `docs/superpowers/plans/2026-09-14-dbio-async-query-pool.md`
- Execute: `docs/superpowers/plans/2026-09-14-dbio-async-ddl.md`

**Interfaces:**
- Consumes: den sauberen Gate-Zustand aus Task 1 und die Schnittstellen der jeweils vorherigen Tickets.
- Produces: neun lokale Ticket-Commits und neun Main-seitige, streng serielle Handoffs nach `review` oder einen präzise blockierten, bereinigten Ticketzustand.

- [ ] **Step 1: Öffne k202 als einziges aktives Child-Ticket**

Main setzt den aktiven Ausführungspfad auf `docs/superpowers/plans/2026-09-14-dbio-test-future.md` und beginnt dort Task 1, Step 1. Kein anderer Child-Plan wird gleichzeitig gestartet.

- [ ] **Step 2: Prüfe das k202-Completion-Gate**

```bash
karr show 202 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k202 in `review`, jüngster Commit nennt `karr k202` samt Co-Author, der Arbeitsbaum ist clean; erst jetzt beginnt k200.

- [ ] **Step 3: Öffne k200 als einziges aktives Child-Ticket**

Main wechselt zu `docs/superpowers/plans/2026-09-14-dbio-async-context-safety.md`, Task 1, und beginnt den dortigen Claim-Step.

- [ ] **Step 4: Prüfe das k200-Completion-Gate**

```bash
karr show 200 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k200 in `review`, Commit nennt `karr k200`; nur `immediate` besitzt Sync-Fallback.

- [ ] **Step 5: Öffne k194 als einziges aktives Child-Ticket**

Main bleibt im Context-Teilplan, wechselt zu Task 2 und beginnt den k194-Claim-Step.

- [ ] **Step 6: Prüfe das k194-Completion-Gate**

```bash
karr show 194 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k194 in `review`, Commit nennt `karr k194`; terminale Pfade invalidieren und releasen einmal.

- [ ] **Step 7: Öffne k196 als einziges aktives Child-Ticket**

Main wechselt im Context-Teilplan zu Task 3 und beginnt den k196-Claim-Step.

- [ ] **Step 8: Prüfe das k196-Completion-Gate**

```bash
karr show 196 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k196 in `review`, Commit nennt `karr k196`; Same-/Foreign-/Stale-/Composed-Ownership ist grün.

- [ ] **Step 9: Öffne k195 als einziges aktives Child-Ticket**

Main wechselt im Context-Teilplan zu Task 4 und beginnt den k195-Claim-Step.

- [ ] **Step 10: Prüfe das k195-Completion-Gate**

```bash
karr show 195 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k195 in `review`, Commit nennt `karr k195`; Connection-Identität und Cache-Isolation sind grün.

- [ ] **Step 11: Öffne k193 als einziges aktives Child-Ticket**

Main wechselt zu `docs/superpowers/plans/2026-09-14-dbio-async-query-pool.md`, Task 1, und beginnt den k193-Claim-Step.

- [ ] **Step 12: Prüfe das k193-Completion-Gate**

```bash
karr show 193 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k193 in `review`, Commit nennt `karr k193`; Raw-row-Limit und vollständige Children sind grün.

- [ ] **Step 13: Öffne k197 als einziges aktives Child-Ticket**

Main wechselt im Query-/Pool-Teilplan zu Task 2 und beginnt den k197-Claim-Step.

- [ ] **Step 14: Prüfe das k197-Completion-Gate**

```bash
karr show 197 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k197 in `review`, Commit nennt `karr k197`; Ersatzkapazität nach Readiness-Fehler ist grün.

- [ ] **Step 15: Öffne k198 als einziges aktives Child-Ticket**

Main wechselt im Query-/Pool-Teilplan zu Task 3 und beginnt den k198-Claim-Step.

- [ ] **Step 16: Prüfe das k198-Completion-Gate**

```bash
karr show 198 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k198 in `review`, Commit nennt `karr k198`; terminaler Shutdown und neue Backend-/Poolgeneration sind grün.

- [ ] **Step 17: Öffne k199 als einziges aktives Child-Ticket**

Main wechselt zu `docs/superpowers/plans/2026-09-14-dbio-async-ddl.md`, Task 1, und beginnt den k199-Claim-Step einschließlich Phase A.

- [ ] **Step 18: Prüfe das k199-Completion-Gate**

```bash
karr show 199 --compact
git log -1 --format='%s%n%b'
git status --short
```

Expected: k199 in `review`, genau ein Commit nennt `karr k199` und enthält synchronen Warntext plus Async-DDL-Parität; der Arbeitsbaum ist clean.

---

### Task 3: Gesamtblock verifizieren

**Files:**
- Verify: `t/**/*.t`
- Protect from ticket commits: `.claude/skills/kanban-issues-karr-cli/SKILL.md`

**Interfaces:**
- Consumes: alle neun committed Ticket-Inkremente.
- Produces: einen abschließenden rekursiven PASS-Nachweis und einen Arbeitsbaum ohne partielle Ticketänderungen.

- [ ] **Step 1: Führe die vollständige rekursive Suite ein letztes Mal aus**

Run:

```bash
set -o pipefail
maint/capped-test dzil test 2>&1 | tee /tmp/dbio-async-hardening-final.log
```

Expected: Exit 0, `Result: PASS`, keine Skips in den durch die neun Tickets berührten Tests.

- [ ] **Step 2: Prüfe alle neun Ticket-Commits in Reihenfolge**

Run:

```bash
git log -9 --format='%h %s%n%b'
```

Expected: genau ein Commit je k202, k200, k194, k196, k195, k193, k197, k198 und k199; jeder Body endet mit der vorgeschriebenen Co-Author-Zeile.

- [ ] **Step 3: Prüfe den finalen Arbeitsbaum**

Run:

```bash
git status --short
```

Expected: keine Ausgabe.

- [ ] **Step 4: Prüfe die karr-Endzustände ohne Mutation**

Run:

```bash
for id in 202 200 194 196 195 193 197 198 199; do
  karr show "$id" --compact
done
```

Expected: jedes erfolgreich abgeschlossene Ticket steht in `review`; ein blockiertes Ticket ist als blockiert und ohne partielle Arbeitsbaumänderungen sichtbar.

## Verifikationsregeln

- Ein roter Test ist nur akzeptiert, wenn seine Diagnose den vorab formulierten Produktclaim verletzt; ein Syntaxfehler, fehlender Import außerhalb des absichtlich noch fehlenden `DBIO::Test::Future` oder falsches Fixture-Setup zählt nicht.
- Kein Produktionsagent startet, bevor Main den roten Claim und die Test-Allowlist bestätigt hat.
- „Grün“ bedeutet immer den fokussierten capped Lauf und anschließend `maint/capped-test dzil test`; ein Top-Level-`prove -l t/` ist kein Ersatz.
- Jeder Handoff nennt die per Log extrahierten `Files=N, Tests=N`, `Result: PASS`, die Commit-ID und `dzil install: PASS`.
- Contract-Versionen werden nur angefasst, wenn die öffentliche Form von `Introspect::Base`, `Diff::Base`, `Deploy::Base`, `SQLMaker` oder `Storage::DBI::Capabilities` erweitert wird. Die geplanten privaten Async-/Pool-Helfer und der reine Warntext ändern diese fünf Contracts nicht; deshalb ist kein Versionsbump vorgesehen.
- Die Fake-Cursor-SQL-Invariante bleibt erhalten: jeder Select-Test, der Fake-SQL beurteilt, muss über den owning Storage und dessen `_select_args` laufen.

## Blocker-Fortsetzungsmatrix

Die `review`-Expectations in Task 2 beschreiben den grünen Pfad. Nach einem vollständig bereinigten und auf der Karte dokumentierten Blocker gilt stattdessen diese feste Fortsetzung:

| Blockiertes Ticket | Nächster Schritt |
|---|---|
| k202 | Gesamtblock stoppen; alle Folgetests konsumieren `DBIO::Test::Future`. |
| k200 | Mit k194 fortfahren; Backend-Refusal ist fachlich unabhängig von den Context-/Pool-/DDL-Fixes. |
| k194 | k196 noch ausführen; k195 und k199 auslassen, weil beide den terminalen TransactionContext konsumieren; k193, k197 und bei grünem k197 k198 weiter ausführen. |
| k196 | k195 auslassen; mit k193 fortfahren. |
| k195 | Mit k193 fortfahren; keine spätere harte Abhängigkeit. |
| k193 | Mit k197 fortfahren; Pool-Härtung ist unabhängig. |
| k197 | k198 auslassen; k199 nur ausführen, wenn k194 grün ist. |
| k198 | Mit k199 fortfahren, sofern k194 grün ist. |
| k199 | Gesamtblockbericht erstellen; keine Folgetickets. |

Ein ausgelassenes Ticket wird nicht geclaimt und nicht mutiert; der Gesamtbericht nennt die blockierende kNN-Karte und die ausgelassenen abhängigen IDs. Technisch unabhängige Tickets behalten die festgelegte relative Reihenfolge.

## Rollback- und Blockerregeln

1. **Falscher roter Claim:** Main schickt den Test-Diff mit Diagnose an `dbio-test-mock-writer` zurück; Produktionsarbeit beginnt nicht.
2. **Produktions-Diff außerhalb der Allowlist:** Main lässt den Agenten nur die fremden Hunks entfernen; `.claude/skills/kanban-issues-karr-cli/SKILL.md` wird weder restored noch gestaged.
3. **Fokussierter oder vollständiger Test rot:** Das Ticket bleibt `in-progress`; Main klärt zuerst, ob der neue Claim, die Implementierung oder ein echter Spec-Widerspruch Ursache ist. Ein Test wird nie durch Abschwächen der behaupteten Eigenschaft grün gemacht.
4. **Echter Widerspruch oder nicht lösbarer Blocker:** Vor dem nächsten Ticket führt Main den im jeweiligen Teilplan vollständig ausgeschriebenen Restore-Befehl aus, prüft erneut `git status --short`, setzt `BLOCK_REASON` auf eine wörtliche Ein-Satz-Zusammenfassung der gerade beobachteten roten Diagnose einschließlich Methode und verletzter Spec-Regel und führt dann ausschließlich für die in der Ticket-Task gesetzte bare Zahl aus:

```bash
CLAIM=$(karr agent-name)
karr edit "$TICKET_ID" \
  --claim "$CLAIM" \
  --block "$BLOCK_REASON" \
  --release
```

Die Child-Task setzt `TICKET_ID` vor dem Claim auf eine der festen Zahlen `202`, `200`, `194`, `196`, `195`, `193`, `197`, `198` oder `199`; in Prosa bleibt die Form `kNN`.
5. **Installationsfehler:** Kein Commit und kein Handoff. Das Ticket bleibt aktiv, bis `maint/capped-test dzil install` grün ist oder nach Regel 4 vollständig bereinigt und blockiert wurde.
6. **Stagingfehler:** Main führt `git restore --staged -- .` aus, führt danach den in der aktuellen Child-Task vollständig ausgeschriebenen `git add`-Befehl erneut aus und prüft, dass `.claude/skills/kanban-issues-karr-cli/SKILL.md` nicht im Cached Diff vorkommt.
7. **Kein pauschales Zurücksetzen:** Kein `git reset --hard`, kein globales `git clean`, kein Restore nicht ticketrelevanter Pfade und kein Revert eines bereits reviewten Vorgängertickets.
