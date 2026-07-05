# Skill — Chorus::Engine

> Automatically loaded for any Perl code created or modified in `$ENGINE`.
> Reference: report `$SESSIONS/2026-06-22-16-54-deep-analysis-engine.md`

---

## Sub-skills

All domain knowledge is split into two **authoritative** sub-skills — no duplication.

| Sub-skill | Authoritative content | Load when |
|---|---|---|
| `chorus-engine-yaml.md` | Frame essentials for YAML (`$SELF`, `fmatch`, `set`), §Engine rule triggering, §Implicit pipeline, §Complete YAML guide (REGLE/CHERCHER/CONDITION/EXCEPTION/EFFET/TERMINAL/PREMISSES), §Checklists YAML + Frames + Multi-Specialty, §YAML DSL quick ref | Writing or reviewing YAML rules — loaded by `chorus-feed` |
| `chorus-engine-infra.md` | §1 Core Mechanisms (Expert→Agent→Frame chain, Frame slots, Engine rule triggering, Expert orchestration), §2 Multi-Specialty Pattern (project structure, agent template, Expert assembly, implicit pipeline), §Checklists Engine/Expert + Multi-Specialty, §Quick ref (Engine slots, BOARD) | Generating Perl infrastructure (Feed, Agent, Expert, run.pl) — loaded by `chorus-check` (full path) |

**For direct Perl work in `$ENGINE`** (trigger `engine-ctx` or auto Perl trigger):
→ load **both** sub-skills: `chorus-engine-yaml.md` + `chorus-engine-infra.md`

---

## Chorus::Collection

> This section lives here only — it is not in either sub-skill.
> Load this file (or this section) when working with `Collection::List` or `Collection::Filter`.

### Collection::List — Ordered Frame Sequences

```perl
use Chorus::Collection::List qw($LIST);

my $sequence = Chorus::Frame->new(_ISA => $LIST);
$sequence->build($f1, $f2, $f3);   # initialise _ITEMS, pose _CONTAINER sur chaque item

$sequence->push_items($f4);         # append to the right
$sequence->unshift_items($f0);      # prepend to the left
$sequence->first_item;              # $f0
$sequence->last_item;               # $f4
$sequence->length;                  # 5

$sequence->HAS('slot');             # premier item ayant le slot truthy
$sequence->HAS_NO('slot');          # vrai si aucun item n'a ce slot
$sequence->STARTS_WITH('slot');     # teste le premier item
$sequence->ENDS_WITH('slot');       # teste le dernier item
```

**Bidirectional prev/succ chaining:**
```perl
$f2->connect_left($f1);    # $f2->prev = $f1, $f1->succ = $f2
$f2->connect_right($f3);   # $f2->succ = $f3, $f3->prev = $f2
```

**List merging:**
```perl
$target->merge_left($list_a, $list_b);   # moves items to the left
$target->merge_right($list_c);           # moves items to the right
# source lists are emptied after merge
```

**Container name:** `_CONTAINER` by default, customizable:
```perl
$sequence->set_container_name('_PHRASE');
# chaque item aura un slot _PHRASE → $item->_PHRASE == $sequence
```

### Collection::Filter — Pattern Matching on Sequences

```perl
use Chorus::Collection::Filter qw($FILTER @_VFILTER);

my $filtre = Chorus::Frame->new(_ISA => $FILTER);

$filtre->set_node_test(sub {
    my ($frame) = @_;
    return $frame->categorie;
});

$filtre->set_filter('^NOM (ADJ+) !PONCT*$');

if ($filtre->check(@tokens)) {
    my ($adjectifs) = @_VFILTER;   # capture du groupe (ADJ+)
}
```

**Pattern syntax:**

| Token | Meaning |
|---|---|
| `^` | sequence start anchor |
| `$` | sequence end anchor |
| `X` | exactly token X |
| `[A B C]` | OR: A or B or C |
| `!X` | NOT: is not X |
| `.` | ANYTHING: any token |
| `X+` | 1 or more |
| `X*` | 0 or more (greedy) |
| `X?` | 0 or 1 (lazy) |
| `X{m,n}` | between m and n occurrences |
| `(...)` | capture group → `@_VFILTER` |

> `@_VFILTER` is reset on each `check()` call. Capture immediately after.

**Checklist:**
- [ ] Always call `set_node_test()` before `check()` (the default returns the raw Frame)
- [ ] `@_VFILTER` is a shared global — capture immediately after `check()`
- [ ] A pattern with `^` and `$` must cover **exactly** the entire sequence

### Exported Symbols

```perl
use Chorus::Collection::List qw($LIST);
use Chorus::Collection::Filter qw($FILTER @_VFILTER);
```
