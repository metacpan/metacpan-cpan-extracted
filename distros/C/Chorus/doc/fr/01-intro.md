# Chorus Engine — Guide technique

> Le [README](../../README.md) décrit le pipeline et la division du travail LLM/moteur.
> Ce guide entre dans la mécanique : structure des règles YAML, comportement du moteur,
> API Perl de référence. Il s'adresse à l'expert du domaine qui lit, corrige et étend
> le pipeline généré par l'agent IA.
>
> Le moteur Perl est le socle — frames, slots, règles YAML, chaîne d'inférence.
> Un agent IA s'y greffe pour lire le corpus normatif et générer les règles.
> Le moteur s'exécute ensuite sans LLM — déterministe, reproductible.

---

## Cycle d'inférence

### Niveau 1 — Chaîne d'agents

```
Expert.process()  ─  répète jusqu'à SOLVED | FAILED
│
▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agent A   │ ──► │   Agent B   │ ──► │   Agent C   │
│  [R1 R2 R3] │     │  [R1 R2]    │     │  [R1]       │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
    loop()              loop()              loop()
   fixpoint             fixpoint            fixpoint
       │
       │◄── replay() : relance loop() depuis R1 (cet agent)
       │
◄──────┴─────────────────────────────────────────────────
replay_all() : relance depuis Agent A
```

### Niveau 2 — Boucle de fixpoint (un agent)

```
loop()  ─  répète tant qu'au moins une règle s'est déclenchée dans la passe

┌─ Règle R1 ────────────────────────────────────────────────────────┐
│  CHERCHER résout les combinaisons de frames                       │
│                                                                   │
│  Pour chaque combinaison :                                        │
│    _APPLY() → 0  (inactive)  ──► combinaison suivante             │
│    _APPLY() → 1  (active)                                         │
│               │                                                   │
│               ├── cut()     ──► stop combis → règle suivante      │
│               └── TERMINAL  ──► solved() ou failed()              │
└───────────────────────────────────────────────────────────────────┘
┌─ Règle R2 ────────────────────────────────────────────────────────┐
│    last() ──────────────────────────────────────────────────────── ──► Agent B
└───────────────────────────────────────────────────────────────────┘
┌─ Règle R3 ────────────────────────────────────────────────────────┐
│  ...                                                              │
└───────────────────────────────────────────────────────────────────┘

Quiescence : aucune règle déclenchée ──► fin loop() → agent suivant
```

**Contrôles de flux disponibles dans `EFFET` / `ACTION` :**

| Mécanisme | Portée | Effet |
|---|---|---|
| `$SELF->cut()` | combinaisons | stop scope → règle suivante |
| `$SELF->last()` | règles de l'agent | stop loop() → agent suivant |
| `$SELF->replay()` | agent courant | relance loop() depuis R1 |
| `$SELF->replay_all()` | chaîne complète | relance depuis Agent A |
| `$SELF->solved()` | global | `BOARD.SOLVED` → arrêt Expert |
| `$SELF->failed()` | global | `BOARD.FAILED` → arrêt Expert |
| `TERMINAL: solved\|failed` | raccourci YAML | déclenche solved()/failed() si `_APPLY` retourne 1 |

---

## Trois niveaux d'utilisation

Trois niveaux d'utilisation, indépendants — Perl direct, règles YAML, pipeline agent IA. Chacun est un point d'entrée valable.

| Niveau | Ce qu'on utilise | Prérequis | Pour qui |
|---|---|---|---|
| **1 — Perl direct** | `addrule()`, `loop()` en Perl | Perl 5 | Découverte, prototypage, petits projets |
| **2 — YAML** | Règles DSL YAML, `loadRules()` | Perl 5 | Projets maintenables, logique métier riche |
| **3 — Agent IA** | Pipeline généré depuis un corpus | Perl 5 + agent IA | Domaines normatifs, corpus volumineux |

Niveaux 1 et 2 : **100 % autonomes** — Perl pur, aucune dépendance externe.
Le niveau 3 ajoute un agent IA comme outil de *développement* uniquement ; le
pipeline généré tourne comme un pipeline de niveau 1, sans agent IA ni réseau.

> **Point de départ :** `sandboxes/demo_en` est entièrement fonctionnel sans agent IA :
> `perl sandboxes/demo_en/run.pl sandboxes/demo_en/project-01.json`

---

## DSL YAML — Formulation des règles

Pour les projets avec de nombreuses règles, le DSL YAML externalise la logique
métier sans code Perl répétitif.

### Structure d'une règle

```yaml
REGLE: nom-de-la-regle           # identifiant unique (_ID interne)
PREMISSES:                       # slots requis sur le frame candidat (filtre rapide)
  - slot_requis
CHERCHER:                        # bindings : nom → critères de sélection
  var:
    attribut: nom_slot           # le frame doit posséder ce slot
    filtre:   '$_->{slot} > 0'  # expression Perl évaluée sur le frame candidat
CONDITION: |                     # condition globale (tous les bindings résolus)
  $var->{slot} > seuil
EXCEPTION: |                     # court-circuit : ne pas déclencher si vrai
  defined $var->{resultat}
EFFET: |                         # corps de règle — doit retourner 1 si actif
  $var->set('resultat', calcul($var->{slot}));
  1
TERMINAL: solved                 # terminer le pipeline
```

**Aliases anglais (2.0)** — `RULE` / `FIND` / `ACTION` / `PREMISES` sont des
synonymes acceptés de `REGLE` / `CHERCHER` / `EFFET` / `PREMISSES`. Les
sous-clés `attribut` et `filtre` sont invariantes (pas d'alias).

### Le champ `TERMINAL` — nouveauté 2.0

`TERMINAL` remplace le code Perl qui appelait `solved()` ou `failed()` depuis
`_APPLY`. Il est déclaré directement dans la règle YAML, sans glue code :

```yaml
REGLE: tout-verifie
CHERCHER:
  obj:
    attribut: statut
CONDITION: |
  $obj->{statut} eq 'ok'
TERMINAL: solved
```

Valeurs acceptées : `solved` · `failed`.

Quand la règle s'active et que `TERMINAL` est présent, le moteur appelle
`solved()` ou `failed()` puis sort de la boucle immédiatement.

### Chargement des règles

```perl
$agent->loadRules('rules/mon-agent/');       # tous les *.yml du répertoire
$agent->loadRules('rules/R01-ma-regle.yml'); # fichier unique
```

### Variables de contexte dans `EFFET`

Les variables liées par `CHERCHER` sont directement accessibles sous leur nom dans le bloc `EFFET`.
`$SELF` désigne le moteur (`Chorus::Engine`) — pas un frame — et donne accès au tableau partagé via `$SELF->BOARD` :

```yaml
EFFET: |
  my $val = $source->{mesure} * $cible->{facteur};
  $cible->set('valeur_corrigee', $val);
  1
```

---

### `_MAX_CYCLES` — garde-fou boucle infinie

`loop()` s'arrête après `_MAX_CYCLES` cycles (défaut : 10 000) et émet un
avertissement. Chaque instance possède sa propre limite, indépendante des
autres agents d'un même `Chorus::Expert`.

Calibrage recommandé : `N_frames × N_règles × N_agents × 10`. La KB
générée par `chorus-feed` documente la valeur cible dans le fichier org de
chaque agent.

---

## Chorus::Frame

| Concept | Description |
|---|---|
| `Chorus::Frame->new(%slots)` | Crée un frame ; `_ISA => $parent` active l'héritage |
| `$f->set('slot', $val)` / `$f->delete('slot')` | Mutation indexée — **ne jamais** passer par `$f->{slot} = …` (contourne l'index `fmatch`) |
| `fmatch(slot => 'nom')` | Retourne tous les frames possédant ce slot ; filtrer avec `grep` |

> `perldoc Chorus::Frame` — slots procéduraux, héritage, modes N/Z, démons, `fselect`, `complete()`, `_TERMINAL_SLOTS`, `_ALTERNATIVES`

---

## Chorus::Engine

| Concept | Description |
|---|---|
| `Chorus::Engine->new(_IDENT => …, _MAX_CYCLES => N)` | Crée un agent ; `_IDENT` pour les logs |
| `$agent->addrule(_SCOPE => …, _APPLY => sub {})` | Ajoute une règle Perl |
| `$agent->loadRules('rules/mon-agent/')` | Charge les règles YAML d'un répertoire ou d'un fichier |
| `$agent->loop()` | Lance la boucle de fixpoint (autonome, sans Expert) |

> `perldoc Chorus::Engine` — règles, boucle d'inférence, DSL YAML, contrôle de flux

---

## Chorus::Expert

| Concept | Description |
|---|---|
| `Chorus::Expert->new(_MAX_ITER => N)` | Crée l'orchestrateur ; `_MAX_ITER` limite les passes sur la chaîne |
| `$xprt->register($a, $b, …)` | Enregistre les agents dans l'ordre d'exécution |
| `$xprt->process($données)` | Lance le cycle complet → `1` (solved) ou `undef` (failed / timeout) |
| `$xprt->BOARD->set/get('clé', …)` | Tableau de bord partagé entre tous les agents |

> `perldoc Chorus::Expert` — orchestration multi-agents, BOARD partagé, `_LOCK_UNTIL_STABLE`

---

## Pour aller plus loin

- [`02-ai-agent.md`](02-ai-agent.md) — positionnement LLM vs Chorus, architecture daemon, pipeline complet
- [`03-applications.md`](03-applications.md) — domaines d'application, onboarding par secteur
- [`04-chorus-commands.md`](04-chorus-commands.md) — référence complète des commandes `chorus-*`
- `perldoc Chorus::Engine` — règles, boucle d'inférence, DSL YAML, contrôle de flux
- `perldoc Chorus::Frame` — slots, héritage, modes N/Z, démons (`_NEEDED`/`_AFTER`/`_ON_DELETE`), `fmatch`, `fselect`, `complete()`, `_TERMINAL_SLOTS`, `_ALTERNATIVES`
- `perldoc Chorus::Expert` — orchestration multi-agents, BOARD partagé
- `perldoc Chorus::Collection::List` — séquences ordonnées de frames
- `perldoc Chorus::Collection::Filter` — correspondance de motifs sur séquences
