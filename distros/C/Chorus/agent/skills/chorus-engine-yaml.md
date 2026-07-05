# Chorus::Engine — YAML Authoring Reference

> **Authoritative source for YAML authoring.**
> This file owns its sections — do not duplicate them in `chorus-engine.md`.
>
> Loaded by: `chorus-feed` (§0 Prerequisites)
> For direct Perl work in `$ENGINE`: load this file + `chorus-engine-infra.md`
> Scope: everything needed to write correct YAML rules and Helpers.pm.
> Not covered here: Perl infrastructure (Feed, Agent, Expert, run.pl) → `chorus-engine-infra.md`
> Not covered here: Collection::List / Collection::Filter → `chorus-engine.md`

---

## Frame essentials for YAML authors

### `$SELF` and `fmatch()`

**`$SELF`** = current context, available in any slot of type `sub { }` and in YAML EFFETs:

```perl
# In a Perl frame:
my $f = Chorus::Frame->new(
    label => sub { "I am " . $SELF->name },
    name  => 'Chorus',
);
```

**`fmatch()`** — slot-based Frame selection via `%REPOSITORY`:

```perl
my @c = fmatch(slot => 'couleur');                        # all Frames with slot 'couleur'
my @r = fmatch(slot => ['couleur', 'score']);             # intersection
my @r = fmatch(slot => 'couleur', from => \@subset);      # restricted search space
```

> ⛔ A Frame is only visible to `fmatch` if its slot was registered via `$f->set('slot', val)`.
> Direct assignment `$f->{slot} = val` bypasses registration → `fmatch` returns 0 Frames → **silent pipeline break**.

### Reading and writing slots

```perl
$f->get('slot')        # read — traverses inheritance chain
$f->slot               # shorthand read
$f->set('slot', $val)  # write — registers in %REPOSITORY → visible to fmatch
$f->delete('slot')     # delete — unregisters from %REPOSITORY
```

### Reserved system slots — never use as domain slot names

`_KEY` `_PARENT_KEY` `_ISA` `_VALUE` `_DEFAULT` `_NEEDED` `_BEFORE` `_AFTER` `_REQUIRE` `_NOFRAME` `_SERIALIZE`

---

## Engine — Rule triggering

**Rule structure (pure Perl — what YAML compiles to):**

```perl
$agent->addrule(
    _ID    => 'nom-unique',
    _SCOPE => {
        var => sub { [ fmatch(slot => 'slot_cible') ] },
    },
    _APPLY => sub {
        my %opts = @_;
        return unless <condition>;
        # ... effets ...
        return 1;
    },
);
```

**Inference loop:** `loop()` calls `applyrules()` as long as at least one rule returns true.
Safety: `_MAX_CYCLES` (default 10,000) → warning + stop if exceeded.

**Flow controls in YAML ACTION — use `$SELF` (never `$agent`):**

| `$SELF->method()` | Effect |
|---|---|
| `$SELF->cut()` | exits scope loops → next rule (same agent) |
| `$SELF->last()` | exits rules loop → next agent |
| `$SELF->replay()` | restarts from 1st rule of this agent |
| `$SELF->replay_all()` | restarts from 1st agent |
| `$SELF->solved()` | `BOARD->{SOLVED} = 'Y'` → immediate stop |
| `$SELF->failed()` | `BOARD->{FAILED} = 'Y'` → immediate stop |

> ⛔ `$agent` is **not** in scope inside a YAML ACTION eval → `Global symbol "$agent"` crash.
> Always use `$SELF` for flow control in `.yml` files.
>
> ⚠️ `$agent` is **not** in scope in a YAML ACTION — use `$SELF` for flow control.

---

## Implicit Slot Pipeline

Agent chaining via the slot targeted in `FIND`:

| Agent | `FIND.attribut` | Sets the slot |
|---|---|---|
| Specialty 1 | `slot_brut` | `slot_enrichi` |
| Specialty 2 | `slot_enrichi` | `slot_calcule` |
| Specialty 3 | `slot_calcule` | `statut` |
| Ctrl | `slot_cle` (+ check `statut`) | calls `solved()` |

> **Golden rule:** each agent looks for a slot that only the previous agent can have set.
> This guarantees execution order without explicit coupling.

---

## Complete YAML Guide

> **Language rule:** use English keywords by default (`RULE`, `FIND`, `ACTION`, `PREMISES`).
> Switch to French keywords (`REGLE`, `CHERCHER`, `EFFET`, `PREMISSES`) only when the corpus
> processed by `chorus-feed` is in French.
> Sub-keys `attribut` and `filtre` are invariant — no English alias exists in the engine.

### Rule Structure

```yaml
RULE: rule-name                  # mandatory — becomes _ID (deduplication)
TERMINAL: solved                 # optional — 'solved' or 'failed'
PREMISES:                        # optional — metadata for reorder()
  - slot-prerequisite
  - another-slot
FIND:                            # mandatory — defines _SCOPE
  var1:
    attribut: slot-name          # → fmatch(slot => 'slot-name')
    filtre: '$_->prop > 0'       # optional → grep { ... }
  var2:
    attribut: another-slot
CONDITION: '$var1->ok'           # optional — return unless CONDITION
EXCEPTION: 'defined $var1->{r}' # optional — return if EXCEPTION
ACTION: |                        # mandatory — body of _APPLY
  $var1->set('result', $var2->value);
  1
```

> French equivalent (corpus in French): `REGLE` / `CHERCHER` / `EFFET` / `PREMISSES`

### FIND — Variable Scope

```yaml
FIND:
  p:
    attribut: classe_bois
# → _SCOPE => { p => sub { [ fmatch(slot => 'classe_bois') ] } }

  p:
    attribut: level
    filtre: '$_->level < 5'
# → _SCOPE => { p => sub { [ grep { $_->level < 5 } fmatch(slot => 'level') ] } }
```

- **`attribut`**: slot passed to `fmatch` — defines the search space.
- **`filtre`**: Perl expression on **`$_`** (the iterated Frame) — narrows the space **before** the combinatorial loop → critical optimization.

> ⛔ **`$f` is not defined inside `filtre`** — `$f` (or any scope variable) only exists inside `ACTION`/`EFFET`, after `my $f = $opts{f}` is executed by `_APPLY`. Using `$f->` in a `filtre` expression causes `Global symbol "$f" requires explicit package name` at rule compilation time.
> ```yaml
> # ⛔ WRONG — $f not in scope here
> FIND:
>   f:
>     attribut: type_element
>     filtre: "defined $f->{type_element} && defined $f->{classe_bois}"
>
> # ✅ CORRECT — use $_ (the iterated Frame)
> FIND:
>   f:
>     attribut: type_element
>     filtre: "defined $_->{type_element} && defined $_->{classe_bois}"
> ```
> Multi-line block scalars (`|`) follow the same rule — every line uses `$_`:
> ```yaml
>     filtre: |
>       defined $_->{type_element}
>       && defined $_->{classe_bois}
> ```

### CONDITION vs EXCEPTION

| Key | Semantics | Generated code |
|---|---|---|
| `CONDITION` | rule **must** be true to fire | `return unless <CONDITION>;` |
| `EXCEPTION` | rule **must not** fire if true | `return if <EXCEPTION>;` |

> **Idempotence:** always add `EXCEPTION: defined $var->{slot_pose}` to prevent re-firing on the same Frame.

### ACTION — Syntaxes

```yaml
# Single instruction
ACTION: "$frame->increase; 1"

# Multi-line (use | not >)
ACTION: |
  my $W = $p->{width} * $p->{height} ** 2 / 6;
  $p->set('sigma_m', $M / $W);
  1

# Sequential list
ACTION:
  - '$p->set("step1", "y")'
  - '$p->set("done", "y"); 1'
```

> ⚠️ Last instruction must return a truthy value. Use `|` (newlines preserved), never `>`.

### TERMINAL — Automatic Termination

```yaml
RULE: all-processed
FIND:
  p:
    attribut: status
TERMINAL: solved
EXCEPTION: '$p->{status} ne "FINAL"'
ACTION: "1"
```

- `TERMINAL: solved` — fires when the rule matches and `_APPLY` returns true → reliable, idiomatic.
- `$SELF->solved()` in ACTION — also valid: `$SELF` inside a YAML ACTION is the agent (Engine), so `$SELF->solved()` correctly sets `BOARD->{SOLVED}`. Can be combined with `TERMINAL: solved` or used alone.
- ⛔ **Never** use a global `fmatch` in a YAML `FIND`/`CHERCHER` block for a termination rule → guaranteed infinite loop. Use `fmatch` in `EXCEPTION`/`CONDITION` only (safe — not bound).

### Loading Order

`loadRules($dir)` loads `*.yml` files in **alphabetical order** → name files `R01-`, `R02-`, etc.

Multiple directories = multiple `loadRules()` calls.

### PREMISES — for reorder()

```perl
sub sort_by_interest {
    my ($r1, $r2) = @_;
    return 1  if $r1->_PREMISSES->{CAT_NOM};
    return -1 if $r2->_PREMISSES->{CAT_NOM};
    return 0;
}
$agent->reorder(\&sort_by_interest);
```

---

## Rule Documentation Standard

> **Mandatory for every generated YAML rule.**
> The header language must match the corpus language:
> English header for an English corpus, French header for a French corpus.
> Adapt the field labels accordingly (see both templates below).

### Header template — English corpus

```yaml
##
# RULE: <R0N-rule-slug>
# AGENT: <Namespace>::Agent::<Name>  (pos. N / total)
# CORPUS: §<N> — <standard/document> — <section title>
#
# PURPOSE
#   <One or two sentences describing what this rule checks and why.>
#   <Mention element types in scope if the rule is type-restricted.>
#
# INPUTS  (slots read)
#   <targeting_slot>  : targeting slot — set by <feed | previous agent RNN>
#   <slot_a>          : <type and meaning, e.g. "float — measured deflection in mm">
#   <slot_b>          : <allowed values or range>
#
# OUTPUTS (slots written)
#   <result_slot>     : <"OUI"/"NON", "OK"/"KO", or any domain value> — result of this rule
#   <targeting_slot>  : deleted after processing (consumed targeting slot)
#
# HELPERS  (omit section if none)
#   <helper_name>(<args>)  → <return type and meaning>
#
# GUARD — EXCEPTION: defined $<var>->{<slot_set>}
#   Idempotence — prevents re-processing a Frame already handled in a previous cycle.
##
```

### Header template — French corpus

```yaml
##
# REGLE: <R0N-slug-regle>
# AGENT: <Namespace>::Agent::<Nom>  (pos. N / total)
# CORPUS: §<N> — <norme/document> — <titre section>
#
# OBJECTIF
#   <Une ou deux phrases décrivant ce que vérifie cette règle et pourquoi.>
#   <Mentionner les types d'éléments en scope si la règle est restreinte par type.>
#
# ENTRÉES  (slots lus)
#   <slot_ciblage>    : slot de ciblage — posé par <feed | agent précédent RNN>
#   <slot_a>          : <type et signification, ex. "float — flèche mesurée en mm">
#   <slot_b>          : <valeurs admises ou plage>
#
# SORTIES  (slots écrits)
#   <slot_resultat>   : <"OUI"/"NON", "OK"/"KO", ou valeur domaine> — résultat de la règle
#   <slot_ciblage>    : supprimé après traitement (slot de ciblage consommé)
#
# HELPERS  (supprimer la section si aucun)
#   <nom_helper>(<args>)  → <type retour et signification>
#
# GARDE — EXCEPTION: defined $<var>->{<slot_pose>}
#   Idempotence — évite de retraiter un Frame déjà traité lors d'un cycle précédent.
##
```

### Inline comment rules (ACTION / EFFET body)

- **Group** the code into logical blocks with a one-line comment per block.
- **Annotate every early `return`**: explain *why* the Frame is skipped (out-of-scope type, missing data, etc.).
- **Mark slot writes** that produce the targeting slot for the next agent.
- **Reference the corpus** (§N) on the line that encodes a normative threshold.

```yaml
# English example
ACTION: |
  # Read input slots
  my $val  = $p->get('measured_value');
  return 0 unless defined $val;      # slot absent → frame out of scope, skip silently

  # Normative check — §4.2
  my $min = _min_required($p->{element_type});
  return 0 unless defined $min;      # element type not covered by this rule → skip

  # Write result
  if ($val < $min) {
    $p->set('result_ok', 'NON');
    $p->set('rejection_reason', "value $val < min $min (§4.2)");
    return 1;
  }
  $p->set('result_ok', 'OUI');
  return 1;
```

```yaml
# French example
EFFET: |
  # Lecture des slots d'entrée
  my $val  = $p->get('valeur_mesuree');
  return 0 unless defined $val;      # slot absent → frame hors scope, ignoré silencieusement

  # Vérification normative — §4.2
  my $min = _seuil_min($p->{type_element});
  return 0 unless defined $min;      # type non couvert par cette règle → ignoré

  # Écriture du résultat
  if ($val < $min) {
    $p->set('resultat_ok', 'NON');
    $p->set('motif_refus', "valeur $val < min $min (§4.2)");
    return 1;
  }
  $p->set('resultat_ok', 'OUI');
  return 1;
```

> **CORPUS line:** when the rule encodes a single standard article, one `CORPUS:` line suffices.
> When the rule combines several articles, list them all:
> ```yaml
> # CORPUS: §4.2 — NF DTU 31.2 — Section minimale montant porteur
> #          §A.2 — NF DTU 31.2 — Annexe A — Tableaux dimensionnels
> ```

---

## Checklist — Anti-Pitfalls

### ✅ YAML Rules

- [ ] ⛔ **`type_element` — canonical slot name:** the slot identifying the element type is
      **always** named `type_element` in every `FIND`/`CHERCHER` `attribut:` that routes by
      element type. Never `element_type`, `type`, `kind`, or any other variant.
      A mismatch with the project JSON key (`"type_element"`) causes a SOLVED pipeline with
      **all elements unprocessed** — no error, no warning, 0 processed frames.
      This rule applies to every YAML rule in every sandbox and every `chorus-feed` run.
- [ ] **Header present** — every generated rule starts with the structured comment header (§ Rule Documentation Standard). Language matches the corpus (English or French).
- [ ] **CORPUS line traceable** — `CORPUS:` references the exact standard article (§N) that justifies the rule. If the source is unknown → `# CORPUS: TODO — source not identified in corpus`.
- [ ] **Always** end `ACTION` with a truthy value (`1` or truthy expression)
- [ ] **`filtre` in `FIND`: always use `$_`, never `$f`** — `$f` (scope variable) is only defined inside `ACTION`/`EFFET`. Using `$f->` in `filtre` causes a compilation crash (`Global symbol "$f"`). Use `$_->{slot}` or `$_->get('slot')`.
- [ ] **`CONDITION` must test data presence, not conformance** — a CONDITION that tests a business result (e.g. `$f->{result} eq 'OK'` or a Helper call returning a pass/fail value) silently blocks all non-conforming Frames: the rule never fires on them, so no slot is ever set → downstream agents never see those Frames → silent pipeline gap. Always restrict `CONDITION` to testing slot presence (`defined $f->{slot}`), type routing (`$f->{type} eq '...'`), or the existence of prerequisite computed slots. Move the conformance test into `ACTION`/`EFFET`, which sets the `_ok` slot to `'OUI'` or `'NON'`.
      ```yaml
      # ⛔ WRONG — non-conforming Frames silently skipped; slot never set
      CONDITION: |
        SomeHelper->is_valid($f->{val}, SomeHelper->min_required($f->{type}))
      # ✅ CORRECT — always fires when data is present
      CONDITION: "defined $f->{val} && defined $f->{type}"
      # ACTION then computes and sets 'result_ok' to 'OUI' or 'NON'
      ```
- [ ] **Conditional ACTION without `else`**: if the `if` modifies nothing and returns `1` → infinite loop until `_MAX_CYCLES`.
      ```yaml
      # ⛔ WRONG — infinite loop if condition never true
      ACTION: |
        if ($p->{val} > 5) { $p->set('flag', 'KO') }
        1
      # ✅ CORRECT
      ACTION: |
        if ($p->{val} > 5) { $p->set('flag', 'KO'); return 1 }
        0
      ```
      > Invisible on a sandbox (6 frames), critical at real scale (300 frames × 40 rules).
- [ ] **Always** add `EXCEPTION: defined $var->{slot_pose}` for idempotence
- [ ] Use `|` (block scalar) for multi-line `ACTION`, never `>`
- [ ] Name files `R01-`, `R02-` to control loading order
- [ ] `filtre` in `FIND` to narrow scope **before** `_APPLY`

### ✅ Frames

- [ ] ⛔ **Never `$f->{slot} = $val`** — use `$f->set('slot', $val)` — direct assignment bypasses `%REPOSITORY` → `fmatch` returns 0 Frames → **silent** pipeline break
      ```perl
      # ⛔ WRONG — slot invisible to fmatch (pipeline silently broken)
      $f->{besoin_conformite} = 1;
      # ✅ CORRECT
      $f->set('besoin_conformite', 1);
      ```
- [ ] Never use `delete $f->{slot}` — use `$f->delete('slot')`
- [ ] Never name a domain slot with a `_UPPERCASE` prefix (reserved for the system)
- [ ] In `_AFTER`: capture `$SELF` **before** any call to `set()` on another Frame:
      ```perl
      # ⛔ WRONG — $SELF overwritten by internal set()
      _AFTER => sub { $other->set('x', $SELF->val) }
      # ✅ CORRECT
      _AFTER => sub { my $ctx = $SELF; $other->set('x', $ctx->val) }
      ```

### ✅ Multi-Specialty Architecture

- [ ] **1 specialty = 1 agent = 1 YAML directory = 1 optional Perl module**
- [ ] The implicit pipeline: each agent reads the slot set by the previous one
- [ ] **Perl helpers — mandatory typeglob injection into `Chorus::Engine` before `loadRules()`**:
      ```perl
      use MyAgent::Helpers qw(mon_helper);
      { no strict 'refs'; *{'Chorus::Engine::mon_helper'} = \&mon_helper; }
      $agent->loadRules("$base/rules/mon-agent");
      ```
      Without this: `Undefined subroutine &Chorus::Engine::mon_helper`.

---

## Quick Reference — YAML DSL Keys

```
RULE        → _ID              (alias: REGLE — French corpus)
TERMINAL    → 'solved' | 'failed'
PREMISES    → [slot, ...]      (alias: PREMISSES — French corpus)
FIND        → _SCOPE (attribut + filtre optional)   (alias: CHERCHER — French corpus)
CONDITION   → return unless ...
EXCEPTION   → return if ...
ACTION      → _APPLY body (must return true)         (alias: EFFET — French corpus)
```
