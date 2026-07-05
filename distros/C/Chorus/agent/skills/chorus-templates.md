# Templates — Chorus Infrastructure Perl

> Loaded by `chorus-check` on the **full path only** (infrastructure absent or incomplete).
> **Do not load on the fast path** (infrastructure already present).
>
> Each section maps to a `chorus-check` phase:
> **T1** → Phase 2 (`Feed.pm`) · **T2** → Phase 3 (`Agent/<Nom>.pm`) · **T3** → Phase 3 (termination `addrule`)
> **T4** → Phase 4 (`Expert.pm`) · **T5** → Phase 5 (`run.pl`)

---

## T1 — Feed.pm

```perl
package <Namespace>::Feed;

use strict;
use warnings;
use Chorus::Frame;
use JSON ();
use Exporter 'import';

our @EXPORT_OK = qw(load_projet);

# Slots obligatoires par type — extrait des KB (Catalogue des Frames)
my %SLOTS_REQUIS = (
    '<type1>' => [qw(<slot_a> <slot_b>)],
    '<type2>' => [qw(<slot_a> <slot_c>)],
);

sub load_projet {
    my ($fichier) = @_;

    # JSON->new->utf8->decode() handles UTF-8 decoding from raw bytes itself
    # — open without ':utf8' to avoid double decoding (Wide character).
    open my $fh, '<', $fichier
        or die "Impossible d'ouvrir $fichier : $!\n";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $data = JSON->new->utf8->decode($json);
    my @frames;

    for my $elem (@{ $data->{elements} }) {
        my $id   = $elem->{id}   // die "Element without 'id'\n";
        my $type = $elem->{type} // die "Element '$id' without 'type'\n";

        my $requis = $SLOTS_REQUIS{$type};
        unless ($requis) {
            # Type out-of-scope for this sandbox: skip without dying.
            # Partitioning elements by sandbox is the responsibility
            # of chorus-import-project (flag _hors_perimetre). This warn is
            # a safety net for mixed JSON files that somehow reach
            # run.pl despite partitioning.
            warn "Type '$type' (element '$id') out-of-scope — skipped\n";
            next;
        }

        for my $slot (@$requis) {
            die "Slot '$slot' manquant pour '$id' (type $type)\n"
                unless defined $elem->{$slot};
        }

        # The agent 1 targeting slot (<slot_ciblage_agent1>) is
        # guaranteed present by the validation above.
        push @frames, Chorus::Frame->new(%$elem);
    }

    return @frames;
}

1;
```

**Substitutions from the KBs:**
- `%SLOTS_REQUIS` ← `obligatoire` slots from the Catalogue des Frames of each KB
- agent 1 targeting slot comment ← `Slots de ciblage` section KB pos 1

---

## T2 — Agent/\<Nom\>.pm

```perl
package <Namespace>::Agent::<Nom>;

use strict;
use warnings;
use Chorus::Engine;
use Chorus::Frame;

# Business knowledge helpers — produced by chorus-feed
# Imported BEFORE loadRules() to be available in YAML EFFETs (eval)
use <Namespace>::Agent::<Nom>::Helpers qw(
    <helper1>
    <helper2>
);

# Shared helpers between agents (if present)
# use <Namespace>::Helpers::Shared qw(<helper_partage>);

use Exporter 'import';
our @EXPORT_OK = qw($agent);

our $agent;

sub build {
    my ($class, %opts) = @_;
    my $base = $opts{base_dir} // '.';

    $agent = Chorus::Engine->new(
        _IDENT      => '<Nom>',
        _MAX_CYCLES => $opts{max_cycles} // 10_000,  # infinite loop safeguard
                                                      # increase for long pipelines
                                                      # heuristic: N_frames × N_rules × N_agents × 10
        # _LOCK_UNTIL_STABLE => 'Y',   # optional: skip this agent if a previous
                                       # agent already succeeded in the current
                                       # iteration (optimization)
    );

    # ⚠️ Inject helpers into Chorus::Engine BEFORE loadRules().
    # YAML EFFETs are eval'd inside Chorus::Engine — a simple `use ... qw(fn)`
    # in this module is not enough: the helper must be visible in the
    # Chorus::Engine namespace at eval time.
    # Mandatory pattern for any agent with Helpers.pm:
    {
        no strict 'refs';
        *{'Chorus::Engine::<helper1>'} = \&<helper1>;
        *{'Chorus::Engine::<helper2>'} = \&<helper2>;
    }

    $agent->loadRules("$base/rules/<slug>");

    # reorder() optional — sort rules by relevance after loadRules()
    # if the KB defines PREMISSES and an initial sort is beneficial:
    # $agent->reorder(sub {
    #     my ($r1, $r2) = @_;
    #     return 1  if $r1->_PREMISSES && $r1->_PREMISSES->{<slot_cle>};
    #     return -1 if $r2->_PREMISSES && $r2->_PREMISSES->{<slot_cle>};
    #     return 0;
    # });

    # pause() optional — disable the agent until an external condition
    # calls $agent->wakeup():
    # $agent->pause() if $opts{deferred};

    return $agent;
}

1;
```

**Substitutions:** `<Nom>`, `<slug>` from `index.org` —
one `*{'Chorus::Engine::fn'} = \&fn` per helper listed in `@EXPORT_OK` of `Helpers.pm`.
If `Helpers.pm` absent for this agent → omit the `use ... ::Helpers` block and the typeglob injection.

---

## T3 — Termination rule (pure Perl addrule)

Use when global termination is needed (e.g. verifying that ALL Frames have their status set).
Add **after** `loadRules()` in the termination agent's `build()`.

```perl
$agent->addrule(
    _ID    => 'terminer',
    _SCOPE => {
        p => sub { [ Chorus::Frame::fmatch(slot => '<slot_ciblage>') ] },
    },
    _APPLY => sub {
        my %opts = @_;
        # Test global — ne pas utiliser cut()/last() ici sauf intention explicite
        my @sans = grep { !defined $_->{statut} }
                   Chorus::Frame::fmatch(slot => '<slot_ciblage>');
        if (@sans == 0) {
            $agent->solved();   # $agent captured as closure — correct
            return 1;
        }
        return;
    },
);
```

**Flow controls available in `_APPLY` (pure Perl `addrule`):**
- `$agent->cut()`        → exits the current scope → next rule (same agent)
- `$agent->last()`       → exits the rule loop → next agent
- `$agent->replay()`     → restarts from the 1st rule of this agent
- `$agent->replay_all()` → restarts from the 1st agent
- `$agent->solved()`     → `BOARD->{SOLVED} = 'Y'` → immediate stop
- `$agent->failed()`     → `BOARD->{FAILED} = 'Y'` → immediate stop

> `$agent` **must be captured as a closure** — never use `$SELF->solved()` in a pure Perl `addrule()`.
> `$SELF` is the current rule-Frame, not the Engine agent.

---

## T4 — Expert.pm

```perl
package <Namespace>::Expert;

use strict;
use warnings;
use Chorus::Expert;
use Chorus::Frame;
use <Namespace>::Agent::<Nom1>;
use <Namespace>::Agent::<Nom2>;
# ... un use par agent dans l'ordre du pipeline

sub run {
    my ($class, %opts) = @_;
    my $base = $opts{base_dir} // '.';

    my $a1 = <Namespace>::Agent::<Nom1>->build(base_dir => $base, max_cycles => $opts{max_cycles});
    my $a2 = <Namespace>::Agent::<Nom2>->build(base_dir => $base, max_cycles => $opts{max_cycles});
    # ... dans l'ordre de #+PIPELINE_POS

    my $xprt = Chorus::Expert->new();
    # ⚠️ Bug connu : new() ignore ses arguments — forcer _MAX_ITER par affectation directe
    $xprt->{_MAX_ITER} = $opts{max_iter} // 50_000;
    $xprt->register($a1, $a2);   # ordre = pipeline (#+PIPELINE_POS)

    # BOARD — shared state between all agents
    # Accessible in rules via: $agent->BOARD->{<key>}
    # Inter-agent usage examples:
    #   $a1->BOARD->{current_phase} = 'validation';   # set by a1
    #   $a2->BOARD->{current_phase}                   # read by a2
    # SOLVED and FAILED keys are reserved by the engine.
    # INPUT is set by process(): $agent->BOARD->{INPUT} = $input

    return $xprt->process($opts{input} // {});
}

1;
```

**Substitutions:** one `use` + one `->build()` per agent in `#+PIPELINE_POS` order.
Force `$xprt->{_MAX_ITER}` after `new()` (known bug: `new()` ignores its arguments).
Document BOARD inter-agent keys in `index.org`.

> ⚠ Do not confuse BOARD and Frames:
> - **Frame**: knowledge about a domain object (element, entity)
> - **BOARD**: shared execution state (global flags, counters, INPUT)

---

## T5 — run.pl

```perl
#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../Engine/lib";   # Chorus::Engine, Frame, Expert, Collection
use lib "$Bin/lib";                 # <Namespace>::*

use <Namespace>::Feed   qw(load_projet);
use <Namespace>::Expert;

my $fichier = shift @ARGV
    or die "Usage : perl run.pl <fichier-projet.json>\n";
-f $fichier or die "Fichier introuvable : $fichier\n";

# Feed — project data → Chorus Frames
my @elements = load_projet($fichier);
printf "Feed: %d element(s) loaded\n\n", scalar @elements;

# Calibrate _MAX_CYCLES to the actual project volume
# Heuristic: N_frames × N_rules_total_estimated × margin
# Safe value: N_elements × 50 × 10 (50 rules max, margin ×10)
my $max_cycles = scalar(@elements) * 50 * 10;
$max_cycles = 10_000 if $max_cycles < 10_000;  # safety minimum

# Pipeline
my ($ok) = <Namespace>::Expert->run(
    base_dir   => $Bin,
    input      => { elements => \@elements },
    max_cycles => $max_cycles,
);

# Result slots to display (set by agents)
# ⚠️ Adapt @slots_resultat_display to the actual sandbox pipeline.
my @slots_resultat_display = qw(
    qualifie motif_refus
    <slot_ok_agent1> <motif_refus_agent1>
    <slot_ok_agent2> <motif_refus_agent2>
    statut_conformite raison_non_conformite
    besoin_<agent1> besoin_<agent2> besoin_conformite
);

print "=" x 62 . "\n";
print "  COMPLIANCE REPORT — <Namespace>\n";
print "=" x 62 . "\n\n";

my $n_conforme     = 0;
my $n_non_conforme = 0;
my $n_non_traite   = 0;

for my $e (@elements) {
    my $id   = $e->{id}   // '?';
    my $type = $e->{type_element} // $e->{type} // '?';
    my $stat = $e->{statut_conformite} // '(unprocessed)';

    if    ($stat eq 'CONFORME')     { $n_conforme++ }
    elsif ($stat eq 'NON_CONFORME') { $n_non_conforme++ }
    else                            { $n_non_traite++ }

    my $flag = $stat eq 'CONFORME'     ? '✅'
             : $stat eq 'NON_CONFORME' ? '❌'
             : '⚠️ ';

    printf "  %s  [%s — %s]\n", $flag, $id, $type;

    my @res = grep { defined $e->{$_} } @slots_resultat_display;
    for my $slot (@res) {
        next if $slot eq 'raison_non_conformite';
        printf "       %-32s : %s\n", $slot, $e->{$slot};
    }
    if (defined $e->{raison_non_conformite}) {
        printf "       %-32s : %s\n", '→ raison', $e->{raison_non_conformite};
    }
    print "\n";
}

# ── Block 1: Compliance rate ──────────────────────────────────────────────
my $n_total = scalar @elements;
my $taux    = $n_total ? int(0.5 + 100 * $n_conforme / $n_total) : 0;
my $bar_ok  = int($taux / 5);
my $bar_ko  = 20 - $bar_ok;
my $barre   = '█' x $bar_ok . '░' x $bar_ko;

print "─" x 62 . "\n";
printf "  Conformes      : %d / %d  (%d%%)\n", $n_conforme,     $n_total, $taux;
printf "  Non conformes  : %d / %d\n",          $n_non_conforme, $n_total;
printf "  Unprocessed    : %d / %d\n",           $n_non_traite,   $n_total;
printf "  [%s]  %d%%\n", $barre, $taux;
printf "  Pipeline       : %s\n", $ok ? 'SOLVED ✅' : 'FAILED/TIMEOUT ❌';
print "─" x 62 . "\n";

# ── Block 2: Validation process — traversal by agent ──────────────────────
# Adapt @pipeline_def to the sandbox's index.org:
#   [ label, slot_ciblage, slot_resultat_ok ]
{
    my @pipeline_def = (
        [ '<Agent1>', 'besoin_<agent1>', '<slot_ok_agent1>' ],
        [ '<Agent2>', 'besoin_<agent2>', '<slot_ok_agent2>' ],
        [ 'Conformite', 'besoin_conformite', 'statut_conformite' ],
    );

    print "\n  Validation process — traversal by agent\n";
    print "  " . "─" x 58 . "\n";
    printf "  %-16s  %7s  %6s  %6s  %5s\n", 'Agent', 'Targeted', 'OK', 'KO', 'NA';
    print "  " . "─" x 58 . "\n";

    for my $def (@pipeline_def) {
        my ($label, $slot_cible, $slot_res) = @$def;
        my @cibles   = grep { defined $_->{$slot_cible} } @elements;
        my $n_cibles = scalar @cibles;
        my ($n_ok, $n_ko, $n_na) = (0, 0, 0);
        for my $e (@cibles) {
            my $res = $e->{$slot_res} // '';
            if    ($res eq 'NA')                              { $n_na++ }
            elsif ($res =~ /^(OUI|CONFORME|1)$/i)            { $n_ok++ }
            elsif ($res =~ /^(NON|NON_CONFORME|KO)$/i)       { $n_ko++ }
            elsif ($slot_res eq 'statut_conformite') {
                if    ($res eq 'CONFORME')     { $n_ok++ }
                elsif ($res eq 'NON_CONFORME') { $n_ko++ }
            }
        }
        printf "  %-16s  %7d  %6s  %6s  %5s\n",
            $label, $n_cibles,
            $n_ok ? $n_ok : '-',
            $n_ko ? $n_ko : '-',
            $n_na ? $n_na : '-';
    }
    print "  " . "─" x 58 . "\n";

    # Path of each element through agents
    print "\n  Validation path per element\n";
    print "  " . "─" x 58 . "\n";
    for my $e (@elements) {
        my $id   = $e->{id}   // '?';
        my $stat = $e->{statut_conformite} // '';
        my $flag = $stat eq 'CONFORME'     ? '✅'
                 : $stat eq 'NON_CONFORME' ? '❌'
                 : '⚠️ ';
        my @chemin;
        for my $def (@pipeline_def) {
            my ($label, $slot_cible, $slot_res) = @$def;
            next unless defined $e->{$slot_cible};
            my $res = $e->{$slot_res} // '?';
            my $res_short = $res =~ /^(OUI|CONFORME|1)$/i      ? '✓'
                          : $res =~ /^(NON|NON_CONFORME|KO)$/i ? '✗'
                          : $res eq 'NA'                        ? '–'
                          : '?';
            push @chemin, "$label($res_short)";
        }
        printf "  %s  %-18s  %s\n", $flag, $id, join(' → ', @chemin);
    }
    print "  " . "─" x 58 . "\n";
}

# ── Block 3: Distribution by element type ─────────────────────────────────
{
    my (%ok_par_type, %ko_par_type, %tous_types);
    for my $e (@elements) {
        my $type = $e->{type_element} // $e->{type} // '?';
        $tous_types{$type}++;
        my $stat = $e->{statut_conformite} // '';
        if    ($stat eq 'CONFORME')     { $ok_par_type{$type}++ }
        elsif ($stat eq 'NON_CONFORME') { $ko_par_type{$type}++ }
    }
    print "\n  Distribution by element type\n";
    print "  " . "─" x 46 . "\n";
    printf "  %-30s  %5s  %5s\n", 'Type', '✅', '❌';
    print "  " . "─" x 46 . "\n";
    for my $t (sort keys %tous_types) {
        printf "  %-30s  %5d  %5d\n",
            $t,
            $ok_par_type{$t} // 0,
            $ko_par_type{$t} // 0;
    }
    print "  " . "─" x 46 . "\n";
}

# ── Block 4: Non-conformity summary ───────────────────────────────────────
{
    my @nc;
    for my $e (@elements) {
        push @nc, $e if ($e->{statut_conformite} // '') eq 'NON_CONFORME';
    }
    if (@nc) {
        print "\n  Non-conformity summary\n";
        print "  " . "─" x 58 . "\n";
        for my $e (@nc) {
            my $id   = $e->{id}   // '?';
            my $type = $e->{type_element} // $e->{type} // '?';
            # Adapter la cascade de motifs aux slots du sandbox
            my $raison = $e->{raison_non_conformite}
                      // $e->{motif_refus}
                      // '(reason not specified)';
            printf "  ❌  %-18s [%s]\n      %s\n\n", $id, $type, $raison;
        }
        print "  " . "─" x 58 . "\n";
    }
}
```

**Substitutions:**
- `<Namespace>` ← from `index.org`
- `@slots_resultat_display` ← result slots from the pipeline KB (statut_conformite, raison_non_conformite, motif_refus, besoin_*, etc.)
- `@pipeline_def` ← one entry per agent: `[ label, slot_ciblage, slot_resultat_ok ]` from `index.org` pipeline table

**Rule:** `run.pl` contains **no hardcoded data** — all project input comes from the JSON argument.
