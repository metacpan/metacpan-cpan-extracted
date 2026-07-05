# Chorus à l'ère des LLMs

## L'IA symbolique et les LLMs — une complémentarité naturelle

Les systèmes à base de règles des années 80–90 (CLIPS, OPS5, systèmes experts
commerciaux) reposaient sur des fondements théoriques solides : connaissance
explicite, raisonnement traçable, résultat déterministe. Ils se heurtent à
trois difficultés structurelles :

1. **L'acquisition des connaissances** — remplir une base de règles demandait
   des *knowledge engineers* dédiés et ne passait pas à l'échelle. Chaque nouveau
   domaine était un chantier long et coûteux.
2. **Le langage naturel** — le monde réel s'exprime en prose, en tableaux, en PDF
   et en notes informelles. Les parseurs symboliques cassaient à la première exception.
3. **La maintenance** — à mesure que la base de règles grossissait, les règles
   s'entrechoquaient, les exceptions s'accumulaient, et la base devenait ingérable.

Chorus-2.0 répond à ces trois problèmes, non pas en abandonnant l'approche
symbolique, mais en confiant exactement ces trois difficultés à un modèle de langage :

| freins IA symbolique seule | Chorus-2.0 |
|---|---|
| Acquisition des connaissances | `chorus-feed` lit des documents bruts et alimente la KB automatiquement |
| Langage naturel en entrée | Le LLM extrait et structure ; le moteur ne parse jamais du texte libre |
| Maintenance des règles | Les règles YAML sont courtes, lisibles, versionnables, auditables à la main |

Le LLM fait ce qu'il fait bien — lire du texte ambigu à grande échelle. Le moteur
d'inférence fait ce qu'il fait bien — appliquer des règles de façon déterministe.
Aucun des deux n'empiète sur le domaine de l'autre.

> **Sur la terminologie.** L'étiquette *neuro-symbolique* est parfois appliquée
> à des systèmes comme Chorus. Elle est inexacte ici. Dans les systèmes
> neuro-symboliques, un modèle neuronal apprend à *simuler* des règles logiques.
> Dans Chorus, le moteur symbolique est réel — frames, slots, chaîne d'inférence
> explicite — et le LLM structure et formalise la connaissance, sans intervenir dans le raisonnement. *Symbolique augmenté* est
> une description plus précise.

---

## La complémentarité plutôt que la concurrence

| Tâche | Outil adapté |
|---|---|
| Compréhension de texte libre, extraction, génération | LLM |
| Validation de contraintes métier strictes | Chorus |
| Justification et traçabilité des décisions | Chorus |
| Adaptation rapide à un nouveau domaine | LLM |
| Garantie de conformité à une norme | Chorus |

Un LLM peut extraire et structurer les données d'entrée ; Chorus applique
les règles métier et certifie le résultat. Les deux se complètent sans se
concurrencer.

---

## Couplage avec un agent IA — l'architecture assistée par IA

Partez d'un PDF de 150 pages — une norme de construction, un DTU, un cahier des
charges technique. L'objectif est un pipeline d'inférence Chorus opérationnel qui
valide des projets réels contre cette norme : agents spécialisés, règles YAML
idempotentes, tables normatives extraites du document, infrastructure Perl câblée,
rapport de conformité structuré.

Sans assistance : plusieurs jours de travail Perl expert. Avec un agent IA et ses
skills Chorus, le même résultat s'obtient en une session de travail.

> **L'agent IA n'est pas une dépendance d'exécution.** Le pipeline qu'il génère est
> du Perl pur — `Feed.pm`, `Agent/*.pm`, `Expert.pm`, `run.pl`. Il tourne sur
> n'importe quelle machine avec Perl installé, sans agent IA, sans connexion réseau.
> Une fois généré, le pipeline est entièrement autonome pour l'exécution.
>
> **L'agent IA est une dépendance de projet.** Adapter un sandbox à un nouveau projet
> — aligner les documents d'ingénieur avec les slots de la KB et produire un
> fichier JSON projet valide — requiert `chorus-create-project` ou
> `chorus-import-project`, deux skills de l'agent IA. La dépendance est réelle et assumée :
> le LLM lit la KB et gère l'écart de terminologie qu'aucun script statique ne
> peut couvrir de façon générique. L'agent IA est aussi nécessaire lorsque le corpus
> normatif évolue — pour relancer `chorus-feed --enrich` puis `chorus-check`.

> Les skills Chorus fonctionnent depuis n'importe quel terminal IA — Claude,
> Copilot, ou tout agent compatible `AGENTS.md`.

**Ce que la chaîne fait concrètement :**

```
chorus-pdf   norme.pdf            → corpus/001-norme-vision.md
chorus-word  annexe.docx          → corpus/002-annexe-vision.md
chorus-excel tableaux-ref.xlsx    → corpus/003-tableaux-text.txt

chorus-feed mon-sandbox corpus/
    → identifie les spécialités → agents
    → conçoit l'ontologie de slots
    → écrit agent/agents/<specialite>.org (KB par agent)
    → génère rules/<specialite>/R01-xxx.yml … (règles YAML)
    → génère lib/MonApp/Agent/<Specialite>/Helpers.pm (tables normatives)

chorus-check mon-sandbox projet.json
    → lit la KB, génère Feed.pm + Agent/*.pm + Expert.pm + run.pl
    → lance perl run.pl projet.json
    → affiche le rapport de conformité
```

L'extraction du corpus (PDF, Word, Excel) + `chorus-feed` + `chorus-check` couvrent l'intégralité du pipeline.

**Ce qui rend ça possible :**

L'astuce centrale est la **base de connaissance locale** — des fichiers org-mode
produits par l'agent IA, un par agent, qui contiennent tout ce que le moteur a besoin de
savoir : l'ontologie du domaine, le dictionnaire des slots, le catalogue des règles
avec leur code, les helpers Perl avec leur source normative (`# §4.2 DTU 31.2`).

Ces fichiers sont lisibles par un ingénieur du domaine sans qu'il sache lire du
Perl. Il peut corriger une table, contester une règle, affiner une contrainte.
L'agent IA relit la KB corrigée et régénère les artefacts en aval. Chorus exécute le
résultat sans jamais impliquer le LLM — de façon déterministe, à l'identique,
autant de fois qu'on veut.

```
norme.pdf
    │ chorus-pdf
    ▼
corpus/
    │ chorus-feed
    ▼
agent/agents/*.org  ←──── l'expert du domaine lit, corrige, affine
rules/**/*.yml
lib/**/Helpers.pm
    │ chorus-check
    ▼
Feed.pm · Agent/*.pm · Expert.pm · run.pl
    │ perl run.pl projet.json
    ▼
✅ CONFORME / ❌ NON_CONFORME  — avec motif, par élément, par agent
```

**Quand la norme change :**

```
chorus-feed mon-sandbox nouveau-corpus.txt --enrich
chorus-check mon-sandbox projet.json
```

La KB est mise à jour de façon incrémentale. L'infrastructure Perl est régénérée.
Le pipeline tourne à nouveau — résultat garanti conforme aux règles telles qu'elles
ont été définies, sans dérive.

**En pratique, sur un vrai domaine :**

Un sandbox de test COB (Construction Ossature Bois, DTU 31.2) a été construit
avec cette chaîne : 7 agents spécialisés, 37 règles YAML, 7 modules de helpers
avec tables EC5 et NF EN 338, un pipeline validant 210 éléments de bâtiment en
une passe. L'intégralité du code Perl et YAML — environ 2 000 lignes — a été
générée par un agent IA depuis le corpus. Aucune ligne écrite à la main.

> Les skills de l'agent IA pour Chorus (`chorus-pdf`, `chorus-feed`, `chorus-check`,
> `chorus-create-project`, `chorus-import-project`) sont versionnés dans
> `$ENGINE/agent/skills/` et documentés dans le dépôt.

> **Explorer le sandbox de démo :** le sandbox `sandboxes/demo_en` illustre
> concrètement ce que produit le pipeline. À l'origine, il ne contenait qu'un
> seul fichier — le corpus brut :
>
> ```
> corpus/001-timber-frame-intro-simul.txt   ← point de départ
> ```
>
> Un agent IA a ensuite exécuté `chorus-feed` puis `chorus-check` pour générer
> l'intégralité de ce qui s'y trouve aujourd'hui : fichiers KB org, règles YAML,
> `Feed.pm`, `Agent/*.pm`, `Expert.pm`, `run.pl`. Vous pouvez lancer le pipeline
> tel quel :
>
> ```sh
> perl sandboxes/demo_en/run.pl sandboxes/demo_en/project-01.json
> ```
>
> ou repartir du corpus seul et rejouer `chorus-feed` + `chorus-check` pour voir
> la chaîne se construire depuis zéro. Adapter un nouveau projet (fichier JSON
> projet) requiert un agent IA (`chorus-create-project` ou
> `chorus-import-project`).

---

## Les commandes `chorus-*`

> Voir [`04-chorus-commands.md`](04-chorus-commands.md) — référence complète de
> `chorus-pdf`, `chorus-feed`, `chorus-check`, `chorus-create-project`,
> `chorus-import-project` : syntaxe, modes, prérequis, sorties, workflow de bout
> en bout et tableau de référence rapide.

---

## Domaines d'application

> Voir [`03-applications.md`](03-applications.md) — analyse secteur par secteur,
> pattern de compatibilité, temps d'onboarding estimé par domaine.
