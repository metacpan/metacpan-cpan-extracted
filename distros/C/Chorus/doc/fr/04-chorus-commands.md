# Les commandes `chorus-*` — Référence du workflow assisté par agent IA

Les neuf commandes `chorus-*` forment un pipeline complet pour transformer un
corpus normatif (PDF, texte, Word, Excel) en un moteur d'inférence Perl
opérationnel qui valide des projets réels.

Ce sont des **commandes de l'agent IA** — pas des modules Perl ni des scripts shell. Chacune
est un skill chargé par un agent IA (Claude, Copilot, ECA…) et exécuté de façon interactive dans l'environnement
de développement.

**Une fois le pipeline généré, l'exécution est autonome.** Le code Perl produit par la
chaîne tourne sur n'importe quelle machine avec Perl installé — sans agent IA, sans
connexion réseau, de façon déterministe.

**Un agent IA reste nécessaire au niveau projet.** `chorus-create-project` et
`chorus-import-project` lisent la KB et gèrent l'écart entre la terminologie
de l'ingénieur et les noms de slots exacts qu'attend le pipeline. Cette capacité
ne peut pas être couverte par un script statique — elle est propre à chaque sandbox
et à chaque corpus. Un agent IA est aussi requis lorsque le corpus normatif change
(`chorus-feed --enrich` puis `chorus-check`).

---

## Le pipeline complet en un coup d'œil

```
                      ┌─────────────────────────────────┐
                      │  Corpus normatif (PDF, texte…)  │
                      └──────────────┬──────────────────┘
                                     │
                          chorus-pdf    (si PDF)
                          chorus-word   (si .docx)
                          chorus-excel  (si .xlsx / .csv)
                                     │
                                     ▼
                      ┌─────────────────────────────────┐
                      │  corpus/<NNN>-<slug>-text.txt   │
                      │  corpus/<NNN>-<slug>-vision.md  │
                      └──────────────┬──────────────────┘
                                     │
                          chorus-feed
                                     │
                                     ▼
                      ┌─────────────────────────────────┐
                      │  agent/agents/<slug>.org  (KB)  │
                      │  rules/<slug>/R<NN>-xxx.yml     │
                      │  lib/…/Agent/<Slug>/Helpers.pm  │
                      └──────────────┬──────────────────┘
                                     │  ← l'expert du domaine relit, corrige
                                     │
                          chorus-check
                                     │
                                     ▼
                      ┌─────────────────────────────────┐
                      │  Feed.pm · Agent/*.pm           │
                      │  Expert.pm · run.pl             │
                      └──────────────┬──────────────────┘
                                     │
                         perl run.pl projet.json
                                     │
                                     ▼
                      ✅ CONFORME / ❌ NON_CONFORME
                         avec motif, par élément, par agent
                                     │
                          chorus-strengthen
                                     │
                                     ▼
                      ┌─────────────────────────────────┐
                      │  rapport d'écarts + roadmap     │
                      └──────────────┬──────────────────┘
                                     │
                   chorus-feed --enrich  (corrections ciblées)
                                     └──────────────────┐
                                                        │ boucle de renforcement
                                                chorus-check --all ✅
```

Le fichier projet peut être écrit à la main, généré depuis la KB avec
`chorus-create-project`, ou aligné depuis des documents d'ingénieur avec
`chorus-import-project`. Une fois un fichier projet disponible, `chorus-strengthen`
peut identifier les lacunes dans les règles YAML et recommander les corpus
d'enrichissement à fournir.

---

## `chorus-quickstart` — Vue d'ensemble du pipeline

```
chorus-quickstart
```

**Responsabilité unique :** afficher le pipeline complet depuis un corpus brut jusqu'au
rapport de conformité, avec les deux chemins disponibles et leur bifurcation.

Cette commande n'exécute rien — c'est une référence guidée qui présente :

- **Chemin A** (vrai projet) — `chorus-feed` → `chorus-import-project` → `chorus-check`
- **Chemin B** (couverture synthétique) — `chorus-feed` → `chorus-create-project` → `chorus-check`
- Quand utiliser `chorus-import-project` vs `chorus-create-project`
- La boucle de renforcement via `chorus-strengthen`
- Le layout du répertoire sandbox après un run complet
- Un cheat-sheet des commandes pour les deux chemins

> **Commencer ici** si vous découvrez Chorus ou si vous n'êtes pas sûr du chemin à suivre.

---

## `chorus-pdf` — Extraire un corpus PDF

```
chorus-pdf <sandbox-name> <fichier.pdf> [--out <slug>] [--hybrid] [--auto] [--images] [--batch]
```

**Responsabilité unique :** produire un fichier texte enrichi depuis un PDF.
Les outils PDF classiques suppriment silencieusement les tableaux normatifs rendus
en images, les mises en page multi-colonnes et les annotations de figures.
`chorus-pdf` les récupère.

### Modes d'extraction

| Mode | Flag | Moteur | Clé API | Sortie |
|---|---|---|---|---|
| **Hybride** (**défaut**) | *(aucun — auto-détecté)* | `pdfminer` texte sur toutes les pages + Claude vision sur figures recadrées | ✅ `ANTHROPIC_API_KEY` | `<slug>-vision.md` |
| **Texte** (repli) | *(aucun — sans clé API)* | `pdfminer.six` uniquement | ❌ non requise | `<slug>-text.txt` |
| **Auto** | `--auto` | pdfminer (pages texte) + vision LLM (pages figures) | ✅ | `<slug>-vision.md` |
| **Images** | `--images` | `pdftoppm` 150 DPI + vision LLM sur toutes les pages | ✅ | `<slug>-vision.md` |

**Choisir un mode :**

```
Pas de flag fourni
  → Phase 0.0 détecte automatiquement ANTHROPIC_API_KEY
  → clé valide   : --hybrid activé automatiquement  ← DÉFAUT
  → clé absente ou invalide : mode texte (repli)

Clé API disponible, document mixte (texte + figures intégrées)
  → (défaut — hybrid activé automatiquement)

Clé API disponible, document majoritairement textuel (peu ou pas de figures)
  → --auto  ← plus rapide, moins d'appels API

Clé API disponible, PDF composé de schémas ou scanné
  → --images

Pas de clé API disponible
  → (mode texte — repli forcé)
```

`--auto` classifie d'abord chaque page (pdfminer sur les pages texte, vision sur
les pages avec figures), minimisant les appels API aux pages qui en ont réellement
besoin.

### Sortie

`corpus/<NNN>-<slug>-text.txt` ou `corpus/<NNN>-<slug>-vision.md`
(numéroté en séquence avec les fichiers corpus existants)

### Prérequis

```bash
pip install pdfminer.six pypdf
sudo apt install poppler-utils          # pour --auto et --images
export ANTHROPIC_API_KEY="sk-ant-..."   # pour --auto et --images
```

### Étape suivante

```
chorus-feed <sandbox-name> corpus/<NNN>-<slug>-text.txt
            (ou : corpus/<NNN>-<slug>-vision.md)
```

---

## `chorus-word` — Extraire un document Word

```
chorus-word <sandbox-name> <fichier.docx> [--out <slug>] [--batch]
```

**Responsabilité unique :** produire un fichier texte enrichi depuis un document Word (.docx).
Les outils de conversion Word classiques suppriment silencieusement les images intégrées,
les cellules fusionnées et l'ordre de lecture réel. `chorus-word` les préserve.

### Modes d'extraction

| Mode | Moteur | Clé API | Images | Tableaux | Sortie |
|---|---|---|---|---|---|
| **Hybride** (**défaut**) | python-docx texte + Claude vision sur images | ✅ `ANTHROPIC_API_KEY` | ✅ décrits | ✅ Markdown pipe | `<slug>-vision.md` |
| **Texte** (repli) | python-docx uniquement | ❌ non requise | `[IMAGE — non extraite]` | ✅ Markdown pipe | `<slug>-text.txt` |

Le mode est détecté automatiquement : hybride si la clé API est présente et valide, texte sinon.

### Prérequis

```bash
pip install python-docx
export ANTHROPIC_API_KEY="sk-ant-..."   # pour le mode hybride
```

### Étape suivante

```
chorus-feed <sandbox-name> corpus/<NNN>-<slug>-vision.md
            (ou : corpus/<NNN>-<slug>-text.txt)
```

---

## `chorus-excel` — Extraire une feuille Excel ou CSV

```
chorus-excel <sandbox-name> <fichier.xlsx|fichier.csv> [--out <slug>] [--sheet <nom>] [--batch]
```

**Responsabilité unique :** produire un fichier texte enrichi depuis un tableur Excel (.xlsx) ou CSV.
Les conversions naïves aplatissent les cellules fusionnées, ignorent les images intégrées et ne
décrivent pas les graphiques. `chorus-excel` les récupère.

### Modes d'extraction

| Mode | Format | Moteur | Clé API | Images/Graphiques | Sortie |
|---|---|---|---|---|---|
| **Hybride** (**défaut**) | `.xlsx` | openpyxl + Claude vision | ✅ `ANTHROPIC_API_KEY` | ✅ décrits | `<slug>-vision.md` |
| **Texte** (repli) | `.xlsx` | openpyxl uniquement | ❌ non requise | `[IMAGE/CHART — non extrait]` | `<slug>-text.txt` |
| **CSV** | `.csv` | `csv.reader` | ❌ | N/A | `<slug>-text.txt` |

Le mode est détecté automatiquement selon l'extension et la présence de la clé API.

### Prérequis

```bash
pip install openpyxl
sudo apt install libreoffice   # pour les graphiques en mode hybride
export ANTHROPIC_API_KEY="sk-ant-..."   # pour le mode hybride
```

### Étape suivante

```
chorus-feed <sandbox-name> corpus/<NNN>-<slug>-vision.md
            (ou : corpus/<NNN>-<slug>-text.txt)
```

---

## `chorus-feed` — Construire la base de connaissance

```
chorus-feed <sandbox-name> <corpus> [--enrich]
```

**Responsabilité unique :** extraire la connaissance d'un corpus et l'écrire dans
des fichiers KB structurés. Ne génère **pas** d'infrastructure Perl.

`<corpus>` doit être un fichier texte (`.txt`) ou Markdown (`.md`) — jamais un PDF.
Si un PDF est fourni, `chorus-feed` s'arrête et suggère d'exécuter `chorus-pdf`
d'abord.

### Deux modes

**Mode A — Initialisation** (défaut, sans flag)

Utilisé pour un nouveau sandbox ou un nouveau départ. Crée la structure complète :

```
<sandbox-name>/
  corpus/001-<slug>.txt          ← le corpus
  agent/agents/<slug>.org        ← KB par agent (ontologie, slots, règles, helpers)
  agent/agents/index.org         ← index du pipeline
  rules/<slug>/R<NN>-xxx.yml     ← règles d'inférence YAML
  lib/…/Agent/<Slug>/Helpers.pm  ← tables normatives (extraites du corpus)
  README.org
```

Ce que l'agent IA produit par agent :
- **Ontologie des slots** — les types de Frame et le dictionnaire des slots du domaine
- **Règles YAML** — un fichier par règle, nommé `R<NN>-<slug>.yml` (chargé par ordre alphabétique)
- **`Helpers.pm`** — tables de lookup normatives et calculs, annotés avec leur source
  corpus (`# §4.2 EC5 — Résistance en flexion par classe de bois`)

**Mode B — Enrichissement incrémental** (`--enrich` requis)

Utilisé quand le sandbox contient déjà une KB et qu'un nouveau corpus normatif
est arrivé. L'agent IA lit la KB existante, classifie chaque nouvelle règle en
*raffinement*, *extension* ou *nouveau domaine*, et applique des modifications
ciblées.

```
chorus-feed <sandbox-name> nouveau-corpus.txt --enrich
```

### Ce que `chorus-feed` ne fait PAS

Il ne génère jamais `Feed.pm`, `Agent/*.pm`, `Expert.pm` ni `run.pl`.
Ces fichiers sont la responsabilité de `chorus-check`.

### Décisions de conception intégrées dans la KB

- **Stratégie de ciblage** — comment le `_SCOPE` de chaque agent trouve ses Frames
  (`fmatch` + slot de présence pour les grands volumes ; slot discriminant + filtre pour les petits)
- **Idempotence** — chaque règle YAML qui écrit un slot porte
  `EXCEPTION: defined $var->{slot}` pour éviter les re-déclenchements
- **Calibrage de `_MAX_CYCLES`** — documenté par agent, calibré sur
  `N_frames × N_règles × N_agents × 10`
- **Traçabilité normative** — chaque seuil dans `Helpers.pm` est annoté avec
  sa référence corpus

### Étape suivante

```
chorus-check <sandbox-name> projet.json
```

Ou, pour relire ce qui a été généré avant d'exécuter :
```
# Ouvrir la KB dans l'éditeur
agent/agents/<slug>.org
```

---

## `chorus-check` — Générer l'infrastructure et exécuter

```
chorus-check <sandbox-name> <fichier-projet.json> [--all]
```

**Responsabilité unique :** lire la KB, générer l'infrastructure Perl, exécuter
le pipeline contre le fichier projet et produire un rapport de conformité.

`--all` exécute tous les fichiers `projet-*.json` du sandbox en un seul passage
et produit un tableau de synthèse (voir ci-dessous). Le chemin rapide s'applique :
l'infrastructure est vérifiée une seule fois et réutilisée pour chaque fichier projet.

### Régénération intelligente

`chorus-check` conserve un hash des fichiers KB (`agent/.kb-hash`). À chaque appel :

- **KB inchangée** → saute toute la génération, exécute `perl run.pl` directement (chemin rapide)
- **KB modifiée** (après un `chorus-feed --enrich`) → régénère l'infrastructure, puis exécute
- **Pas encore d'infrastructure** → génère depuis zéro

Cela signifie qu'exécuter `chorus-check` deux fois sur le même sandbox avec
des fichiers projet différents ne coûte presque rien au deuxième appel.

### Ce qui est généré

| Fichier | Rôle |
|---|---|
| `lib/<NS>/Feed.pm` | Charge le JSON projet, crée les Frames, positionne les slots de ciblage |
| `lib/<NS>/Agent/<Slug>.pm` | Shell de chaque agent : importe les Helpers, charge les règles YAML |
| `lib/<NS>/Expert.pm` | Câble tous les agents, fixe `_MAX_CYCLES`, enregistre auprès de l'Expert |
| `run.pl` | Point d'entrée : `perl run.pl projet.json` |

Le code généré est du **Perl pur** — pas de dépendance à un agent IA, pas de LLM, pas de réseau.
Il tourne sur n'importe quelle machine avec Perl et les modules CPAN installés.

### Sortie

Un rapport de conformité structuré, par élément et par agent :

```
✅ ÉLÉMENT poteau-bois-01 — CONFORME
   [qualification] classe : C24 ✓
   [domain]        élancement : 45 ≤ 60 ✓
   [fire]          REI 60 atteint ✓

❌ ÉLÉMENT poteau-bois-03 — NON_CONFORME
   [qualification] teneur en humidité : 22% > 18% max (EC5 §3.3)
   [domain]        pare-vapeur : MANQUANT
```

### Étape suivante

```
# Relancer avec un autre projet (pas de régénération) :
perl run.pl autre-projet.json

# Exécuter tous les projet-*.json d'un coup :
chorus-check <sandbox-name> --all

# Mettre à jour le corpus et régénérer :
chorus-feed <sandbox-name> nouvel-addendum.txt --enrich
chorus-check <sandbox-name> projet.json
```

### Tableau de synthèse `--all`

Lorsque `--all` est utilisé, `chorus-check` produit un tableau de synthèse
à la place des rapports verbatim individuels :

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  chorus-check --all  <sandbox-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Fichier projet     │ Statut    │ OK │ KO │ Non-traités │ Disc
  projet-rules-iso   │ SOLVED ✅ │  N │  N │      0      │  0
  projet-edges       │ SOLVED ✅ │  N │  N │      0      │  0
  projet-cross       │ SOLVED ✅ │  N │  N │      0      │  0
  projet-scale       │ SOLVED ✅ │  N │  N │      0      │  0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Résultat global : CONVERGÉ ✅   Discordances : 0 / N_total
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Si des discordances sont trouvées → lancer `chorus-strengthen <sandbox-name>`
pour identifier les lacunes et obtenir un plan d'enrichissement.

---

## `chorus-create-project` — Générer un JSON projet depuis la KB

```
chorus-create-project <sandbox-name> <fichier-sortie.json> [--batch]
```

**Responsabilité unique :** lire la KB du sandbox et générer un fichier JSON
projet valide, peuplé d'éléments conformes ET non-conformes qui explorent la
variété du domaine.

`--batch` génère la suite de couverture complète en quatre fichiers (voir
ci-dessous) au lieu d'un fichier projet unique.

Utile pour :
- **Tester** le pipeline de bout en bout avant qu'un vrai projet soit disponible
- **Démontrer** l'étendue des vérifications effectuées par le moteur
- **Amorcer** un modèle de projet qu'un ingénieur pourra remplir

### Ce que l'agent IA lit

1. `agent/agents/index.org` — types de Frame, pipeline, namespace
2. `agent/agents/<slug>.org` — slots obligatoires, seuils, domaines de valeurs valides
3. Tout `projet-*.json` existant dans le sandbox — format de référence

> ⚠️ `chorus-create-project` ne lit jamais `Helpers.pm`, `Feed.pm` ni aucun
> fichier Perl généré. Les fichiers org KB sont toujours la source canonique.

### Sortie (mode unitaire)

Un fichier JSON avec :
- Un ensemble représentatif d'éléments projet (un par type de Frame, avec variations)
- Des cas conformes explicites (tous les seuils respectés)
- Des cas non-conformes explicites (une violation de règle par élément défaillant)
- Des commentaires indiquant quelle règle chaque cas défaillant est conçu à déclencher

### Suite de couverture (mode `--batch`)

`--batch` produit quatre fichiers projet ciblant des angles de test différents :

| Fichier | Objectif |
|---|---|
| `projet-rules-iso.json` | Tester chaque règle isolément (1 OK + 1 KO par règle) |
| `projet-edges.json` | Tester les valeurs seuils (valeur = seuil et seuil ± ε) |
| `projet-cross.json` | Exposer les interactions entre règles (éléments déclenchant plusieurs règles) |
| `projet-scale.json` | Test de volume pour le calibrage de `_MAX_CYCLES` (≥ 100 éléments) |

Les IDs sont stables d'une régénération à l'autre (préfixes `I-`, `E-`, `X-`, `S-`)
pour permettre des comparaisons diff entre les runs `chorus-check --all`.

### Étape suivante

```
# Mode unitaire :
chorus-check <sandbox-name> <fichier-sortie.json>

# Mode batch — exécuter toute la suite :
chorus-check <sandbox-name> --all

# Si la suite révèle des lacunes :
chorus-strengthen <sandbox-name>
```

---

## `chorus-strengthen` — Identifier les lacunes et recommander un enrichissement

```
chorus-strengthen <sandbox-name>
```

**Responsabilité unique :** exécuter la suite complète de projets, classifier
chaque discordance et élément non-traité en un type de lacune, produire un
rapport d'écarts structuré et recommander le corpus d'enrichissement à passer
à `chorus-feed --enrich`.

`chorus-strengthen` ne modifie jamais aucun fichier KB, YAML ou Perl — il
lit et rapporte uniquement.

### Prérequis

- `chorus-check` a été exécuté au moins une fois (infrastructure présente)
- Au moins un fichier `projet-*.json` existe dans `$SANDBOX/`
  (idéalement la suite de quatre fichiers de `chorus-create-project --batch`)

### Classification des lacunes

Chaque élément discordant ou non-traité est classifié en l'un des trois types :

| Type de lacune | Motif | Cause probable |
|---|---|---|
| **Règle trop stricte** | Attendu CONFORME → obtenu NON_CONFORME | Seuil erroné, CONDITION trop étroite ou cas limite non couvert |
| **Règle trop permissive** | Attendu NON_CONFORME → obtenu CONFORME | Règle manquante, seuil trop élevé ou CONDITION excluant ce type |
| **Lacune Feed** | Élément `(non-traité)` | Slot de ciblage non positionné par Feed pour ce type d'élément |

### Sortie

Un rapport d'écarts structuré par élément (id, type, attendu, obtenu, règle
déclenchée, hypothèse, référence corpus, correctif suggéré) suivi d'un plan
d'enrichissement :

- **Bucket A** — clarification corpus nécessaire (source normative ambiguë)
- **Bucket B** — ajustement YAML direct (pas besoin de `chorus-feed`)
- **Bucket C** — couverture manquante → rédaction d'un `corpus-correctif.txt`
  pour `chorus-feed <sandbox-name> corpus-correctif.txt --enrich`

### Boucle de renforcement

```
chorus-create-project <sb> --batch     ← construire la suite de couverture (une fois)
        ↓
chorus-strengthen <sb>                 ← identifier les lacunes
        ↓
[éditer les YAML directement]          ← corrections bucket B
chorus-feed <sb> corpus-fix.txt --enrich  ← nouvelles règles bucket C
        ↓
chorus-check <sb> --all                ← vérifier
        ↓
chorus-strengthen <sb>                 ← vérifier la convergence
        ↓
✅ CONVERGÉ — tous les projets passent, 0 discordance
```

---

## `chorus-import-project` — Aligner des documents d'ingénieur avec la KB

```
chorus-import-project <sandbox-name> <source…> [--out <fichier.json>] [--batch]
```

**Responsabilité unique :** lire un document projet produit par un ingénieur
(PDF, Word, Excel, texte, tableau collé dans le chat) et aligner sa terminologie
avec les slots et types de la KB du sandbox, en produisant un fichier JSON
projet valide.

Cette commande comble le fossé entre la façon dont les ingénieurs décrivent un
projet (terminologie libre, jargon métier, tableaux informels) et les noms de
slots et domaines de valeurs exacts qu'attend le pipeline Chorus.

### Trois modes d'invocation

| Syntaxe | Mode | Sortie |
|---|---|---|
| `chorus-import-project sb fichier.pdf` | **Unitaire** | 1 JSON |
| `chorus-import-project sb f1.pdf f2.xlsx f3.docx` | **Fusion** | 1 JSON fusionné (même projet, fichiers complémentaires) |
| `chorus-import-project sb ./dossier/` ou `--batch` | **Batch** | 1 JSON par fichier + rapport de synthèse |

**Le mode est détecté automatiquement** en fonction du nombre et du type des
arguments sources.

### Ce que l'agent IA lit

1. `agent/agents/index.org` — types de Frame, pipeline, namespace
2. `agent/agents/<slug>.org` — noms de slots, domaines de valeurs, obligatoires/optionnels
3. `agent/thesaurus.org` (si présent) — terminologie projet validée lors des imports précédents *(priorité maximale)*
4. Tout `agent/import-report-*.org` précédent — décisions d'alignement antérieures (secondaire — ignoré si couvert par le thésaurus)

### Ce que l'agent IA produit

- `projet-import-<NNN>.json` — le JSON projet aligné
- `agent/import-report-<NNN>.org` — rapport d'alignement : correspondances de termes, lacunes, ambiguïtés
- `agent/thesaurus.org` — mis à jour incrémentalement après chaque décision d'alignement ; créé au premier import si absent

Les lacunes (valeurs absentes du document source) sont signalées mais jamais inventées.

### Étape suivante

```
# Relire le rapport d'import avant d'exécuter :
agent/import-report-<NNN>.org

# Puis valider :
chorus-check <sandbox-name> projet-import-<NNN>.json
```

---

## Workflow complet — de bout en bout

### Démarrer depuis un corpus PDF

```bash
# 1. Extraire le corpus (--auto recommandé pour les normes techniques)
chorus-pdf mon-sandbox corpus/norme.pdf --auto
#   → corpus/001-norme-vision.md

# 2. Construire la base de connaissance
chorus-feed mon-sandbox corpus/001-norme-vision.md
#   → agent/agents/*.org, rules/**/*.yml, lib/.../Helpers.pm
#   ← l'expert du domaine relit et corrige agent/agents/*.org

# 3. Générer l'infrastructure et exécuter
chorus-check mon-sandbox projet.json
#   → Feed.pm, Agent/*.pm, Expert.pm, run.pl
#   → rapport de conformité
```

### Démarrer depuis un document d'ingénieur

```bash
# Générer ou importer un fichier projet
chorus-create-project mon-sandbox --batch             # générer depuis la KB
chorus-import-project mon-sandbox notes-ingenieur.pdf # aligner depuis le document

# Valider
chorus-check mon-sandbox --all
```

### Valider et renforcer la base de règles

```bash
# Générer la suite de couverture
chorus-create-project mon-sandbox --batch
#   → projet-rules-iso.json, projet-edges.json, projet-cross.json, projet-scale.json

# Exécuter tous les projets en un seul passage
chorus-check mon-sandbox --all
#   → tableau de synthèse avec CONFORME / NON_CONFORME / non-traités / discordances

# En cas de discordances → identifier les lacunes et obtenir un plan d'enrichissement
chorus-strengthen mon-sandbox
#   → rapport d'écarts + recommandation corpus-correctif.txt

# Appliquer les corrections et relancer
chorus-feed mon-sandbox corpus-correctif.txt --enrich
chorus-check mon-sandbox --all
#   → tous les projets CONVERGÉS ✅
```

### Mettre à jour quand la norme change

```bash
chorus-feed mon-sandbox nouvel-addendum.txt --enrich
chorus-check mon-sandbox projet.json     # régénère uniquement ce qui a changé
```

---

## Ce qui tourne sans agent IA

Une fois que `chorus-check` a généré l'infrastructure, **l'exécution est
entièrement autonome** — sans agent IA, sans LLM, sans réseau :

```bash
# Sur n'importe quelle machine avec Perl et les modules CPAN requis :
perl run.pl projet.json

# Relancer avec un autre projet (pas de régénération) :
perl run.pl autre-projet.json
```

**Adapter un nouveau projet requiert un agent IA.** Un JSON projet peut en principe
être écrit à la main, mais `chorus-create-project` et `chorus-import-project`
sont le chemin pratique : ils lisent la KB et gèrent l'écart entre la
terminologie de l'ingénieur et les noms de slots et domaines de valeurs exacts
qu'attend le pipeline. Un agent IA est aussi nécessaire lorsque le corpus normatif
change (`chorus-feed --enrich` suivi de `chorus-check`).

---

## Prérequis techniques

### Perl (exécution)

```bash
cpanm Chorus::Engine    # moteur d'inférence
cpanm YAML              # chargement des règles YAML
```

### Python (extraction corpus — chorus-pdf uniquement)

```bash
pip install pdfminer.six pypdf   # texte et classification des pages
sudo apt install poppler-utils   # pdftoppm (modes --auto et --images)
export ANTHROPIC_API_KEY="sk-ant-..."   # vision LLM (--auto et --images)
```

### Explorer le sandbox sans agent IA

Le sandbox `sandboxes/demo_en` contient la sortie complète de la chaîne —
corpus, KB org, règles YAML, infrastructure Perl. Lancer
`perl sandboxes/demo_en/run.pl sandboxes/demo_en/project-01.json` montre le résultat
en direct avec le JSON projet pré-construit inclus dans le sandbox. Pour
adapter un nouveau projet, un agent IA est requis.

---

## Référence rapide

| Commande | Entrée | Sortie | Prérequis |
|---|---|---|---|
| `chorus-quickstart` | *(aucune)* | Guide interactif — présentation du pipeline | — |
| `chorus-pdf` | Fichier PDF | `corpus/<NNN>-<slug>-text.txt` ou `-vision.md` | `pdfminer.six` ; clé API pour `--hybrid`/`--auto`/`--images` |
| `chorus-word` | Fichier `.docx` | `corpus/<NNN>-<slug>-vision.md` ou `-text.txt` | `python-docx` ; clé API pour le mode hybride |
| `chorus-excel` | Fichier `.xlsx` ou `.csv` | `corpus/<NNN>-<slug>-vision.md` ou `-text.txt` | `openpyxl` ; clé API pour le mode hybride |
| `chorus-feed` | Corpus `.txt` ou `.md` | `agent/agents/*.org`, règles YAML, `Helpers.pm` | — |
| `chorus-check` | JSON projet (ou `--all`) | `Feed.pm`, `Agent/*.pm`, `Expert.pm`, `run.pl` + rapport | `chorus-feed` exécuté au préalable |
| `chorus-create-project` | *(KB uniquement)* | JSON projet ou suite de 4 fichiers (`--batch`) | `chorus-feed` exécuté au préalable |
| `chorus-import-project` | Document d'ingénieur | JSON projet aligné + rapport d'import | `chorus-feed` exécuté au préalable |
| `chorus-strengthen` | *(suite de projets)* | rapport d'écarts + plan d'enrichissement | `chorus-check` exécuté au préalable |

---

## Pour aller plus loin

- [`01-intro.md`](01-intro.md) — concepts Chorus, modèle Frame, moteur d'inférence, DSL YAML
- [`02-ai-agent.md`](02-ai-agent.md) — positionnement LLM vs Chorus, pourquoi la chaîne fonctionne
- [`03-applications.md`](03-applications.md) — analyse par domaine, temps d'onboarding
- `agent/skills/chorus-pdf.md` — référence complète du skill `chorus-pdf`
- `agent/skills/chorus-feed.md` — référence complète du skill `chorus-feed`
- `agent/skills/chorus-check.md` — référence complète du skill `chorus-check`
- `agent/skills/chorus-create-project.md` — référence complète du skill `chorus-create-project`
- `agent/skills/chorus-import-project.md` — référence complète du skill `chorus-import-project`
- `agent/skills/chorus-strengthen.md` — référence complète du skill `chorus-strengthen`
