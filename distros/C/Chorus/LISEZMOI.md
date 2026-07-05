# Chorus::Engine

[![Version CPAN](https://badge.fury.io/pl/Chorus.svg)](https://metacpan.org/dist/Chorus)
[![CI](https://github.com/civorra/Chorus/actions/workflows/ci.yml/badge.svg)](https://github.com/civorra/Chorus/actions/workflows/ci.yml)
[![Perl](https://img.shields.io/badge/perl-5.006%2B-blue)](https://www.perl.org/)
[![Licence](https://img.shields.io/badge/license-Artistic--2.0-green)](LICENSE)

> Chorus est un moteur d'inférence Perl qui transforme un corpus normatif en
> pipeline de vérification de conformité. Un agent IA construit la base de
> connaissance ; le moteur l'exécute de façon déterministe et traçable.

Le système fonctionne en **deux temps radicalement distincts** :

```
Temps A — Construction   [agent IA, supervisé, une fois par norme]
  Corpus brut → chorus-feed → KB + règles YAML
              → chorus-check → pipeline Perl déployable

Temps B — Exécution      [Chorus seul, sans LLM, à chaque projet]
  projet.json → perl run.pl → rapport de conformité
  100 % déterministe · reproductible · certifiable
```

Le LLM intervient **uniquement** en Temps A — pour lire le corpus, structurer la
connaissance et générer les artefacts. En Temps B, il n'intervient plus : le pipeline
Perl s'exécute seul, de façon déterministe et reproductible.

```
Corpus normatif (PDF, texte, Word, Excel)
        │
   chorus-pdf / chorus-word / chorus-excel + chorus-feed   ← l'agent IA extrait et formalise les règles
        │
   KB : ontologie · règles YAML · tables normatives
        │
   chorus-check               ← génère le pipeline Perl, l'exécute
        │
   perl run.pl projet.json    ← déterministe, reproductible, sans agent IA
        ▼
  ✅ CONFORME / ❌ NON_CONFORME  (par élément, par agent, avec motif et référence)
```

---

## Genèse

Chorus appartient à la tradition de l'**IA symbolique** — celle qui représente
la connaissance de façon explicite, sous forme de règles et de structures
typées, et qui raisonne par inférence déterministe. Dans la lignée des
systèmes experts et des **Frames de Marvin Minsky**.

La première version est née en 2013 du portage en Perl d'un projet original
écrit en LISP. L'objectif était double : montrer que Perl était tout à fait
adapté à ce type d'implémentation, et offrir à la communauté CPAN un moteur
d'inférence inspiré des Frames de Minsky — objets typés, slots, héritage,
chaîne d'inférence.

Plus de dix ans après, l'analyse du projet par un LLM a mis en évidence une
complémentarité inattendue : là où le moteur symbolique excelle à exécuter
des règles de façon déterministe et traçable, le LLM excelle à lire un corpus
et à les formaliser. La friction réelle — la génération des règles YAML,
fastidieuse à écrire à la main — devenait le terrain naturel du LLM.

C'est cette rencontre qui a donné naissance à la version 2.

Chorus v2 est un système **symbolique augmenté** : le moteur d'inférence
reste souverain — frames, slots, chaîne d'inférence, sans réseau de neurones
dans la couche de décision. Le LLM est un outil de prétraitement, pas un
décideur. Deux formes d'IA, complémentaires plutôt que concurrentes.

---

## Pourquoi un LLM ne peut pas valider à lui seul la conformité à un corpus de normes

Chorus occupe une position spécifique dans le paysage IA actuel. La plupart des
systèmes hybrides utilisent un modèle de langage comme couche de décision et les
règles comme garde-fous. Chorus inverse ce schéma : le LLM est un outil d'extraction
qui lit des documents et formalise des règles ; le moteur d'inférence prend en charge
l'intégralité du raisonnement. Le LLM ne tire jamais de conclusion.

**1. Couverture exhaustive du corpus normatif — impossible à garantir.**
Un modèle de langage fait de la complétion probabiliste, pas de l'énumération
exhaustive. Les clauses rares, les notes de bas de page normatives et les renvois
croisés entre normes sont omis silencieusement. Le problème : le modèle ne sait pas
ce qu'il omet.

**2. Consistance sur un dossier complet — dégradation certaine.**
Un dossier réel comprend de nombreux documents hétérogènes — spécifications, notes de calcul,
fiches techniques, pièces justificatives. Sur un contexte long, un LLM perd en précision sur les
éléments introduits en début de contexte et ne détecte pas les contradictions
inter-documents de façon fiable.

**3. Reproductibilité — inexistante par nature.**
Deux runs sur le même dossier peuvent produire des verdicts différents. Pour un bureau
de contrôle ou un assureur, c'est rédhibitoire.

**4. Traçabilité — structurellement absente.**
Un LLM peut halluciner des références, paraphraser approximativement ou amalgamer deux
clauses. Il ne peut pas garantir que chaque assertion est ancrée sur un article précis
d'une norme précise.

**5. Mise à jour normative — opaque.**
Quand une norme est révisée, il est impossible de savoir quelle partie du raisonnement
LLM est affectée. Avec un moteur de règles explicites, la mise à jour est chirurgicale :
les règles YAML concernées sont identifiées, corrigées et retestées en isolation.

### La division du travail

Un LLM est un excellent extracteur et traducteur de textes normatifs en règles
formelles. C'est un mauvais exécuteur de vérification de conformité.

C'est précisément la division du travail qu'implémente Chorus : le LLM génère et
formalise les règles (`chorus-feed`) ; le moteur d'inférence les exécute de façon
déterministe et traçable (`chorus-check`). Ensemble, ils couvrent ce qu'aucun des deux
ne peut faire seul.

Lancer `chorus-check` deux fois sur le même fichier projet, sur n'importe quelle
machine, produit toujours la même sortie — aucun échantillonnage, aucune température,
aucun aléatoire dans la couche de décision.

> Le terme *neuro-symbolique* est parfois appliqué à des systèmes comme Chorus.
> Il n'est pas exact ici. Dans les systèmes neuro-symboliques, un modèle neuronal
> apprend à simuler des règles logiques. Dans Chorus, le moteur symbolique est réel —
> frames, slots, chaîne d'inférence — et le LLM est une étape de prétraitement.
> *Symbolique augmenté* est un label plus précis.

---

## Pipeline assisté par IA — commandes `chorus-*`

Les commandes `chorus-*` sont des **skills d'agent IA** — pas des scripts shell.
Chacune est chargée par un agent IA et exécutée de façon interactive dans votre
environnement de développement. Le pipeline Perl produit fonctionne ensuite de 
façon entièrement autonome : aucun agent IA, aucun LLM, aucune connexion réseau
requise à l'exécution.

### Vue d'ensemble

```
Corpus normatif (PDF, texte, Word, Excel)
        │
   chorus-pdf          ← extrait les PDFs (hybride par défaut / texte / auto / images)
   chorus-word         ← extrait les documents Word (.docx)
   chorus-excel        ← extrait les feuilles Excel et CSV (.xlsx, .csv)
        │
   corpus/<NNN>-<slug>.txt / -vision.md
        │
   chorus-feed         ← construit la KB : ontologie, règles YAML, Helpers.pm
        │
   agent/agents/*.org · rules/**/*.yml · lib/.../Helpers.pm
        │                 ← l'expert du domaine relit et corrige
   chorus-check        ← génère Feed.pm, Agent/*.pm, Expert.pm, run.pl
        │                   puis exécute : perl run.pl project.json
        ▼
  ✅ CONFORME / ❌ NON_CONFORME  (par élément, par agent, avec motif)
        │
   chorus-strengthen   ← classifie les écarts, produit une feuille de route
        │
   chorus-feed --enrich ← enrichissement ciblé de la KB
        └──────────────────────────────────────────┐
                                                   │ boucle de renforcement
                                            chorus-check --all ✅
```

Le fichier projet fourni à `chorus-check` peut être :
- **écrit à la main** (si le vocabulaire des slots est connu)
- **généré depuis la KB** avec `chorus-create-project` (variantes conformes + KO,
  suite de couverture 4 fichiers `--batch` en option)
- **aligné depuis des documents d'un dossier** avec `chorus-import-project` (PDF, Word,
  Excel, tableau inline) — fait le pont entre la terminologie ingénieur et les noms de slots de la KB *
  par l'enrichissement d'un thesaurus en attribuant à chaque terme source un **niveau de confiance** :

| Niveau | Signification |
|---|---|
| ✅ certain | Correspondance exacte ou trivialement équivalente |
| ⚠️ probable | Correspondance proche avec transformation documentée |
| ❓ ambigu | Plusieurs candidats KB — décision humaine requise |
| ⛔ gap | Slot obligatoire absent de la source — bloque le pipeline |
| ⬜ hors-périmètre | Présent dans la source, absent de la KB — noté mais ignoré |

Le rapport d'alignement produit (`import-report-NNN.org`) constitue la piste d'audit
de chaque décision et le thesaurus est relu et enrichi lors des imports suivants pour affiner la correspondance avec
la terminologie du corpus.

### Commandes en un coup d'œil

| Commande | Rôle |
|---|---|
| `chorus-quickstart` | Vue d'ensemble guidée — commencer ici si vous découvrez Chorus |
| `chorus-pdf` | Extraire un corpus PDF (hybride par défaut / texte / auto / images) |
| `chorus-word` | Extraire un document Word (.docx) en corpus enrichi |
| `chorus-excel` | Extraire une feuille Excel ou CSV en corpus enrichi |
| `chorus-feed` | Construire ou enrichir la KB depuis un corpus |
| `chorus-check` | Générer l'infrastructure + lancer la vérification de conformité |
| `chorus-create-project` | Générer un fichier projet JSON synthétique depuis la KB |
| `chorus-import-project` | Aligner des documents d'ingénieur avec les noms de slots de la KB |
| `chorus-strengthen` | Identifier les lacunes de règles, produire une feuille de route d'enrichissement |

### Boucle de renforcement

Une fois le premier pipeline en place, `chorus-strengthen` classe chaque discordance
(règle trop stricte, règle trop permissive, lacune de ciblage Feed) et recommande le
corpus nécessaire pour combler chaque écart :

```
chorus-create-project <sb> --batch          ← suite de couverture 4 fichiers
chorus-check <sb> --all                     ← tableau de synthèse
chorus-strengthen <sb>                      ← rapport de lacunes + feuille de route
chorus-feed <sb> corpus-fix.txt --enrich    ← enrichissement ciblé
chorus-check <sb> --all                     ← vérifier la convergence ✅
```

### Une fois généré, fonctionne sans agent IA

```bash
# Sur n'importe quelle machine avec Perl installé :
perl run.pl project.json

# Relancer avec un autre projet — sans régénération :
perl run.pl autre-projet.json
```

> Référence complète des commandes : [`doc/fr/04-chorus-commands.md`](doc/fr/04-chorus-commands.md)

---

## Domaines d'application

Chorus n'est pas lié à un secteur. Un domaine est applicable dès lors
que trois conditions sont réunies :

1. **Le projet est décrit par des éléments typés** — chaque objet à valider
   (élément de construction, clause contractuelle, composant logiciel…) a des
   attributs mesurables et un type discriminant.
2. **La norme énonce des seuils, des conditions et des tableaux de référence**
   — des exigences explicites, pas de prose interprétable.
3. **La décision doit être traçable et reproductible** — audit, certification,
   dépôt réglementaire, contentieux.

| Domaine | Corpus type |
|---|---|---|
| 🔐 **Cybersécurité / NIS2 / DORA** | SecNumCloud v3.2, NIS2 Annexe II, DORA, ETSI EN 319 412 |
| 🌿 **CSRD / Environnement** | ESRS E1–E5, S1–S4, GHG Protocol, Taxonomie EU |
| 🏗️ **Construction / BTP** | Eurocodes EC2/EC3/EC5, RE2020, DTU |
| ⚖️ **RGPD / Marchés publics** | RGPD Art. 13/14/28/30/35, NIS2, Code de la Commande Publique |
| 🏦 **Finance / RegTech** | Bâle IV (CRR3), MiFID II, EMIR |
| 💊 **Industrie pharmaceutique** | EU GMP Annexe 1, ICH Q8/Q9/Q10, Pharmacopée EU |
| 🏥 **Dispositifs médicaux** | MDR 2017/745, ISO 13485, IEC 62304, ISO 14971 |
| 🚗 **Automobile / ISO 26262** | ASIL A/B/C/D, ASPICE v3.1, MISRA C:2012 |
| ✈️ **Aérospatial / DO-178C** | DO-178C, ARP4754A, AMC 20-115 (EASA) |
| ⚡ **Énergie / Nucléaire** | RCC-M, IEC 61511, Guide ASN, IEC 62351 |

La variable principale est la **qualité du corpus**, pas la complexité du domaine.
Un corpus bien structuré (exigences numérotées, tableaux de référence, niveaux
hiérarchiques) s'onboarde en 2 à 4 semaines.

> Référence complète des domaines : [`doc/fr/03-applications.md`](doc/fr/03-applications.md)

---

## Exemple complet fonctionnel

`sandboxes/demo_en` — vérification de conformité d'une construction à ossature bois
selon BS EN 338, EC5, Building Regulations Part L/B, BS EN 13501 (simulation).

```sh
perl sandboxes/demo_en/run.pl sandboxes/demo_en/project-01.json
```

---

## Le socle — moteur d'inférence Perl

Le pipeline `chorus-*` repose sur un moteur d'inférence Perl pur sans dépendance
d'exécution au-delà du CPAN standard (`YAML`, `Scalar::Util`, `Digest::MD5`).

Chorus implémente le cycle classique **reconnaître–agir** de la tradition des systèmes
experts : à chaque itération, le moteur identifie les règles applicables à la mémoire
de travail courante, les déclenche, puis repart — jusqu'à ce que rien ne change ou
qu'un objectif soit atteint.

La mémoire de travail est constituée d'objets `Chorus::Frame` dont les propriétés
(slots) portent la connaissance du domaine. `Chorus::Expert` enchaîne plusieurs
moteurs spécialisés sur une mémoire de travail partagée.

| Module | Rôle |
|---|---|
| `Chorus::Frame` | Représentation de la connaissance — slots, héritage, registres globaux, chaînage avant/arrière |
| `Chorus::Engine` | Boucle d'inférence — règles, combinatoire des scopes, contrôle de flux, chargement YAML |
| `Chorus::Expert` | Orchestration multi-agents — BOARD partagé, boucle externe |
| `Chorus::Collection::List` | Séquences ordonnées de Frames — navigation bidirectionnelle `prev`/`succ`, merge, tests positionnels |
| `Chorus::Collection::Filter` | Filtrage regex-like sur séquences de Frames — groupes de capture dans `@_VFILTER` |

### API directe

```perl
use Chorus::Engine;
use Chorus::Frame;

my $agent = Chorus::Engine->new();

Chorus::Frame->new(color => 'blue', label => 'sky');
Chorus::Frame->new(color => 'red',  label => 'fire');

$agent->addrule(
    _SCOPE => { f => sub { [ grep { $_->{color} eq 'blue' } fmatch(slot => 'color') ] } },
    _APPLY => sub {
        my %o = @_;
        return if $o{f}->{tagged};
        $o{f}->set('tagged', 'yes');
        print "Tagged: ", $o{f}->{label}, "\n";   # → Tagged: sky
        return 1;
    },
);

$agent->loop();
```

Le DSL YAML permet d'exprimer la même logique sans code Perl répétitif :

```yaml
REGLE: marquer-frames-bleues
CHERCHER:
  f:
    attribut: color
    filtre:   blue
EXCEPTION: defined $f->{tagged}
EFFET: |
  $f->set('tagged', 'yes');
  print "Marqué : $f->{label}\n";   # → Marqué : sky
  return 1;
```

Chaque règle YAML vit dans un fichier `.yml` distinct. Pour les charger,
sauvegarder la règle dans `rules/marquer-frames-bleues.yml` puis appeler
`loadRules()` à la place de `addrule()` :

```perl
use Chorus::Engine;
use Chorus::Frame;

my $agent = Chorus::Engine->new();

Chorus::Frame->new(color => 'blue', label => 'sky');
Chorus::Frame->new(color => 'red',  label => 'fire');

$agent->loadRules('rules/');   # charge tous les *.yml du dossier

$agent->loop();
```

Les fichiers sont compilés dans l'ordre alphabétique — préfixer avec `R01-`,
`R02-`… pour contrôler la priorité. Plusieurs appels à `loadRules()` s'accumulent.

> Documentation technique complète :
> `perldoc Chorus::Engine` · `perldoc Chorus::Frame` · `perldoc Chorus::Expert`

---

## Installation

```sh
cpanm Chorus::Engine
```

Ou depuis les sources :

```sh
perl Makefile.PL && make && make test && make install
```

---

## Documentation

- [`doc/fr/01-intro.md`](doc/fr/01-intro.md) — concepts, architecture, DSL YAML
- [`doc/fr/02-ai-agent.md`](doc/fr/02-ai-agent.md) — pipeline LLM + Chorus, intégration agent IA
- [`doc/fr/03-applications.md`](doc/fr/03-applications.md) — domaines d'application (construction, CSRD, MDR, DO-178C…)
- [`doc/fr/04-chorus-commands.md`](doc/fr/04-chorus-commands.md) — référence des commandes `chorus-*`
- [`doc/en/01-intro.md`](doc/en/01-intro.md) — concepts, architecture, YAML DSL (en)
- [`doc/en/02-ai-agent.md`](doc/en/02-ai-agent.md) — LLM + Chorus pipeline (en)
- [`doc/en/03-applications.md`](doc/en/03-applications.md) — application domains (en)
- [`doc/en/04-chorus-commands.md`](doc/en/04-chorus-commands.md) — `chorus-*` commands reference (en)

---

## Contribuer

Les contributions sont bienvenues — rapports de bugs, corrections de documentation,
nouveaux exemples ou améliorations du moteur de règles.

- **Rapports de bugs / demandes de fonctionnalités** — ouvrir une [Issue](https://github.com/civorra/Chorus/issues)
- **Pull requests** — cibler la branche `devel` ; s'assurer que `make test` passe
- **Bonnes premières issues** — chercher le label [`good first issue`](https://github.com/civorra/Chorus/issues?q=label%3A%22good+first+issue%22)
- **Questions** — utiliser [GitHub Discussions](https://github.com/civorra/Chorus/discussions)
  ou la file RT du CPAN : <https://rt.cpan.org/Dist/Display.html?Name=Chorus>

---

## Dépôt

<https://github.com/civorra/Chorus>
