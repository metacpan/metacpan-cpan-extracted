# NAME

App::Greple::xlate - module d’assistance à la traduction pour greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** module recherche les blocs de texte souhaités et les remplace par le texte traduit. Le moteur principal est GPT-5.5 (`llm/gpt5.pm`), qui appelle la commande [llm](https://llm.datasette.io/) ; DeepL (`deepl.pm`) et les moteurs hérités basés sur **gpty** sont également inclus.

Les traductions sont mises en cache par fichier, de sorte que réexécuter une commande ne coûte rien pour le texte inchangé. Lorsqu’un document est modifié, seuls les paragraphes modifiés sont de nouveau envoyés à l’API ; un moteur sensible au contexte reçoit également les traductions environnantes, le texte source brut autour de la modification et la version précédente du paragraphe modifié, afin que la nouvelle traduction conserve la terminologie établie (voir **--xlate-context-window**). Les chaînes sensibles peuvent être masquées avant la transmission (voir ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Si vous souhaitez traduire des blocs de texte normaux dans un document écrit dans le style pod de Perl, utilisez la commande **greple** avec `--xlate-engine gpt5` et le module `perl` comme ceci :

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dans cette commande, la chaîne de motif `^([\w\pP].*\n)+` signifie des lignes consécutives commençant par des lettres alphanumériques et de ponctuation. Cette commande affiche en surbrillance la zone à traduire. L’option **--all** est utilisée pour produire le texte entier.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ajoutez ensuite l’option `--xlate` pour traduire la zone sélectionnée. Elle trouvera alors les sections souhaitées et les remplacera par la sortie du moteur de traduction.

Par défaut, le texte original et le texte traduit sont imprimés au format « marqueur de conflit » compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez obtenir la partie souhaitée facilement avec la commande [unifdef(1)](http://man.he.net/man1/unifdef). Le format de sortie peut être spécifié par l’option **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous souhaitez traduire l’intégralité du texte, utilisez l’option **--match-all**. Il s’agit d’un raccourci pour spécifier le motif `(?s).+` qui correspond à l’ensemble du texte.

Les données au format marqueur de conflit peuvent être visualisées côte à côte avec la commande [sdif](https://metacpan.org/pod/App%3A%3Asdif) et l’option `-V`. Comme il n’a pas de sens de comparer chaîne par chaîne, l’option `--no-cdif` est recommandée. Si vous n’avez pas besoin de colorer le texte, spécifiez `--no-textcolor` (ou `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Le traitement est effectué par unités spécifiées, mais dans le cas d’une séquence de plusieurs lignes de texte non vides, elles sont converties ensemble en une seule ligne. Cette opération est effectuée comme suit:

- Supprimer les espaces au début et à la fin de chaque ligne.
- Si une ligne se termine par un signe de ponctuation pleine chasse, la concaténer avec la ligne suivante.
- Si une ligne se termine par un caractère pleine chasse et que la ligne suivante commence par un caractère pleine chasse, concaténer les lignes.
- Si soit la fin soit le début d’une ligne n’est pas un caractère pleine chasse, les concaténer en insérant un espace.

Les données de cache sont gérées sur la base du texte normalisé, de sorte que même si des modifications sont apportées qui n’affectent pas les résultats de normalisation, les données de traduction mises en cache resteront efficaces.

Ce processus de normalisation est effectué uniquement pour le premier motif (0e) et les motifs de numéro pair. Ainsi, si deux motifs sont spécifiés comme suit, le texte correspondant au premier motif sera traité après normalisation, et aucun processus de normalisation ne sera effectué sur le texte correspondant au second motif.

    greple -Mxlate -E normalized -E not-normalized

Par conséquent, utilisez le premier motif pour le texte devant être traité en combinant plusieurs lignes en une seule, et utilisez le second motif pour le texte préformaté. S’il n’y a pas de texte correspondant au premier motif, utilisez un motif qui ne correspond à rien, tel que `(?!)`.

# MASKING

Il arrive qu’il y ait des parties du texte que vous ne souhaitez pas traduire. Par exemple, des balises dans des fichiers Markdown. DeepL suggère que, dans de tels cas, la partie du texte à exclure soit convertie en balises XML, traduite, puis restaurée une fois la traduction terminée. Pour prendre cela en charge, il est possible de spécifier les parties à masquer de la traduction.

    --xlate-setopt maskfile=MASKPATTERN

Cela interprétera chaque ligne du fichier `MASKPATTERN` comme une expression régulière, traduira les chaînes qui y correspondent, puis reviendra en arrière après le traitement. Les lignes commençant par `#` sont ignorées.

Un motif complexe peut être écrit sur plusieurs lignes avec un retour à la ligne échappé par une barre oblique inverse.

La manière dont le texte est transformé par le masquage peut être visualisée avec l’option **--xlate-mask**.

Le masquage protège le balisage contre la traduction. Pour dissimuler les chaînes sensibles au service de traduction lui-même, voir ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates) ; les deux peuvent être utilisés ensemble.

Cette interface est expérimentale et susceptible d’évoluer à l’avenir.

# ANONYMIZATION AND TEMPLATES

Les chaînes sensibles peuvent être dissimulées avant d’être envoyées à l’API de traduction et restaurées dans la sortie. Trois sources de règles d’anonymisation sont disponibles : un fichier dictionnaire (**--xlate-anonymize**), des marques inline dans le document lui-même (**--xlate-anonymize-mark**) et des valeurs de front matter YAML (**--xlate-frontmatter**). Chaque chaîne est remplacée par une balise de catégorie telle que `<person id=1 />` pendant la transmission. La cible de la dissimulation est uniquement la transmission à l’API : les fichiers de cache locaux stockent le texte brut restauré. Utilisez **--xlate-dryrun** pour examiner exactement ce qui serait transmis.

Pour les documents de formulaire (rapports trimestriels et similaires), définissez les acteurs en amont et référencez-les dans le corps :

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Traduisez le modèle une fois par langue avec `--xlate-template` (et `--xlate-frontmatter` lorsque les valeurs sont conservées dans le fichier), puis générez chaque cas avec le mode autonome **pandoc-embedz** -- les valeurs sous `global:` dans une configuration externe n’atteignent jamais du tout l’API de traduction :

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Pour les marques en ligne, fournir une configuration de définition de macros permet au même modèle traduit d’afficher soit les vrais noms, soit une version expurgée :

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Excluez les blocs embedz de la traduction lorsqu’un document en contient :

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Lancer le processus de traduction pour chaque zone correspondante.

    Sans cette option, **greple** se comporte comme une commande de recherche normale. Vous pouvez ainsi vérifier quelle partie du fichier sera traduite avant de lancer le travail effectif.

    Le résultat de la commande est envoyé sur la sortie standard ; redirigez vers un fichier si nécessaire, ou envisagez d’utiliser le module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    L’option **--xlate** appelle l’option **--xlate-color** avec l’option **--color=never**.

    Avec l’option **--xlate-fold**, le texte converti est replié à la largeur spécifiée. La largeur par défaut est 70 et peut être définie par l’option **--xlate-fold-width**. Quatre colonnes sont réservées pour l’opération en début de ligne, donc chaque ligne peut contenir au maximum 74 caractères.

- **--xlate-engine**=_engine_

    Spécifie le moteur de traduction à utiliser.

    À ce stade, les moteurs suivants sont disponibles

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Les modules de moteur sont d’abord recherchés dans les espaces de noms backend (`llm`, puis `gpty`), puis directement sous `App::Greple::xlate`. Ainsi, `gpt5` charge `App::Greple::xlate::llm::gpt5`, qui appelle la commande `llm`, tandis que `gpt4o` se rabat sur `App::Greple::xlate::gpty::gpt4o`. Utilisez `--xlate-setopt backend=gpty` pour forcer un backend spécifique.

- **--xlate-labor**
- **--xlabor**

    Au lieu d’appeler un moteur de traduction, il est attendu que vous travailliez manuellement. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous devez le coller dans le formulaire, copier le résultat dans le presse-papiers, puis appuyer sur Entrée.

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Les moteurs LLM acceptent tout nom ou code de langue que le modèle comprend ; il est interpolé dans l’invite de traduction. Vous pouvez obtenir les langues disponibles via la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Étiquette utilisée pour le texte original dans les formats de sortie `conflict`, `colon` et `ifdef`. Avec le moteur **DeepL**, une valeur non par défaut est également transmise comme langue source.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et le texte traduit.

    Les formats suivants autres que `xtxt` supposent que la partie à traduire est un ensemble de lignes. En fait, il est possible de traduire seulement une portion de ligne, mais spécifier un format autre que `xtxt` ne produira pas de résultats pertinents.

    - **conflict**, **cm**

        Le texte original et le texte converti sont imprimés au format des marqueurs de conflit [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original avec la commande suivante [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Le texte original et le texte traduit sont sortis dans un style de conteneur personnalisé de Markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Le texte ci-dessus sera traduit comme suit en HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Le nombre de deux-points est 7 par défaut. Si vous spécifiez une séquence de deux-points comme `:::::`, elle est utilisée à la place de 7 deux-points.

    - **ifdef**

        Le texte original et le texte converti sont imprimés au format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Vous pouvez récupérer uniquement le texte japonais avec la commande **unifdef** :

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Le texte original et le texte converti sont imprimés séparés par une ligne blanche. Pour `space+`, il ajoute également une nouvelle ligne après le texte converti.

    - **xtxt**

        Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est imprimé.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Spécifiez la longueur maximale du texte à envoyer à l’API en une seule fois. La valeur par défaut 0 signifie la limite propre au moteur : pour le service de compte gratuit DeepL, elle est de 128K pour l’API (**--xlate**) et de 5000 pour l’interface presse-papiers (**--xlate-labor**). Vous pouvez éventuellement modifier ces valeurs si vous utilisez le service Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Spécifiez le nombre maximal de lignes de texte à envoyer à l’API en une seule fois.

    Définissez cette valeur à 1 si vous souhaitez traduire une ligne à la fois. Cette option a priorité sur l’option `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Spécifiez une invite personnalisée à envoyer au moteur de traduction. Cette option est disponible pour les moteurs LLM (`gpt3`, `gpt4o`, `gpt5`), mais pas pour DeepL. Vous pouvez personnaliser le comportement de traduction en fournissant des instructions spécifiques au modèle d’IA. Si l’invite contient `%s`, elle sera remplacée par le nom de la langue cible.

- **--xlate-context**=_text_

    Spécifiez des informations de contexte supplémentaires à envoyer au moteur de traduction. Cette option peut être utilisée plusieurs fois pour fournir plusieurs chaînes de contexte. Les informations de contexte aident le moteur de traduction à comprendre l’arrière-plan et à produire des traductions plus précises.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Nombre de blocs traduits environnants transmis comme contexte de référence lors de la retraduction de blocs modifiés (par défaut 2). Le contexte inclut également le texte source brut autour de la région modifiée (titres, structure de liste, légendes) et, lorsqu’elle est disponible, la version précédente du texte modifié récupérée depuis le cache, afin que les formulations inchangées soient préservées. Définissez à 0 pour désactiver entièrement la traduction tenant compte du contexte. Notez que chaque région modifiée est traduite dans son propre appel API et que le contexte peut ajouter jusqu’à environ 8000 caractères à l’invite système, de sorte que la traduction tenant compte du contexte échange un coût supplémentaire contre de la cohérence.

- **--xlate-cache-seed**=_file_

    Initialisez le cache d’un nouveau document à partir du fichier de cache d’un autre document. Utile pour les rapports périodiques : amorcez le cache du nouveau numéro avec celui du numéro précédent, afin que les paragraphes inchangés ne soient pas retraduits et que les paragraphes modifiés conservent la formulation du numéro précédent. L’amorce n’est utilisée que lorsque le cache cible est vide ; sinon, elle est ignorée avec un avertissement. Avec la valeur par défaut `--xlate-cache=auto`, spécifier une amorce implique également de créer le fichier de cache du nouveau document.

- **--xlate-anonymize**=_file_

    Anonymisez les chaînes sensibles avant qu’elles ne soient envoyées à l’API de traduction, et restaurez-les dans la sortie. Le fichier de dictionnaire fournit une entrée par élément : en JSON (canonique, générable par machine)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    ou dans un format simple par ligne (`category pattern`, `/.../` pour les regex). Chaque élément est remplacé par une étiquette de catégorie telle que `<person id=1 />` ; la même chaîne reçoit toujours la même étiquette, de sorte que le modèle peut suivre qui est qui. Les champs JSON inconnus sont ignorés, de sorte que les générateurs (par exemple un LLM local extrayant des entités) peuvent ajouter leurs propres annotations. La catégorie `lit` est réservée. Les fichiers de cache locaux stockent toujours le texte brut restauré : la cible de la dissimulation est uniquement la transmission à l’API.

    Un dictionnaire peut être généré par un outil externe — par exemple un modèle local extrayant des entités sensibles :

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Un BOM UTF-8 dans le fichier est toléré. Les valeurs dans le format de ligne de front matter peuvent porter un commentaire final uniquement sur leur propre ligne, pas après la valeur.

- **--xlate-anonymize-mark**\[=_regex_\]

    Collectez les entrées d’anonymisation à partir des marques inline dans le document lui-même. Marquez la première occurrence comme `{{ person("山田太郎") }}` et chaque occurrence de la chaîne dans l’ensemble du document est anonymisée. La marque elle-même reste dans la source et dans la traduction, de sorte qu’un document peut également être traité par un processeur de macros de style Jinja2 (définissez la macro `person` pour imprimer ou rédacter le nom). Un _regex_ personnalisé doit contenir des captures nommées `(?<category>...)` et `(?<text>...)`.

    Notez qu’avec une option à valeur facultative comme celle-ci, un argument de fichier suivant serait pris comme valeur : écrivez `--xlate-anonymize-mark=` (avec un `=` final) lorsque vous utilisez la notation par défaut.

    Des notations alternatives peuvent être configurées, par exemple `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` pour des marques de style `@@person:NAME@@`, ou une forme de commentaire HTML qui reste invisible dans le Markdown rendu. Les règles de marque sont collectées par document : une chaîne marquée dans un fichier d’entrée n’est pas dissimulée dans un autre fichier de la même exécution (contrairement aux valeurs de front matter, qui s’accumulent entre les fichiers).

- **--xlate-template**\[=_regex_\]

    Traitez les expressions de modèle (par défaut : Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) comme des espaces réservés opaques : indiquez au modèle de les copier sans les modifier et vérifiez, pour chaque bloc, que la réponse contient exactement les mêmes expressions, chacune le même nombre de fois. Leur ordre peut changer, car la traduction les réordonne légitimement pour respecter l’ordre des mots de la langue cible. Une expression cassée interrompt l’exécution ; le cache est enregistré à un point de contrôle et gelé, de sorte que rien de ce qui a été payé n’est perdu.

    Notez qu’avec une option à valeur facultative comme celle-ci, un argument de fichier suivant serait pris comme valeur : écrivez `--xlate-template=` (avec un `=` final) lorsque vous utilisez la notation par défaut.

- **--xlate-frontmatter**

    Traitez un bloc initial `---` ... `---` comme un front matter YAML : excluez-le de la traduction et des tranches de contexte de phase 2, et ajoutez ses valeurs `key: value` plates aux règles d’anonymisation (catégorie `var`) comme filet de sécurité. Avec plusieurs fichiers d’entrée, les valeurs collectées s’accumulent (en privilégiant la dissimulation en cas de doute).

    Laissez toujours une ligne vide après le `---` de fermeture. Avec un motif de correspondance de style paragraphe, un front matter qui se poursuit directement dans le texte du corps forme un bloc chevauchant que l’exclusion ne peut pas supprimer (un avertissement est affiché dans ce cas) ; les valeurs sont tout de même anonymisées, mais le front matter lui-même serait envoyé à la traduction.

- **--xlate-glossary**=_glossary_

    Spécifiez un ID de glossaire à utiliser pour la traduction. Cette option n’est disponible qu’avec le moteur DeepL. L’ID de glossaire doit être obtenu depuis votre compte DeepL et garantit une traduction cohérente des termes spécifiques.

- **--xlate-dryrun**

    N’appelez pas l’API de traduction ; affichez plutôt, via l’affichage de progression, chaque charge utile exactement telle qu’elle serait transmise (après anonymisation et masquage). Utile pour vérifier ce qui quitte la machine et pour estimer le coût d’une exécution.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Voir le résultat de la traduction en temps réel dans la sortie STDERR. La charge utile `From` est affichée telle qu’elle est transmise, après anonymisation et masquage.

- **--xlate-stripe**

    Utilisez le module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pour afficher la partie correspondante avec un zébrage. Ceci est utile lorsque les parties correspondantes sont enchaînées dos à dos.

    La palette de couleurs est basculée en fonction de la couleur de fond du terminal. Si vous souhaitez spécifier explicitement, vous pouvez utiliser **--xlate-stripe-light** ou **--xlate-stripe-dark**.

- **--xlate-mask**

    Effectuer la fonction de masquage et afficher le texte converti tel quel sans restauration.

- **--match-all**

    Définir l’ensemble du texte du fichier comme zone cible.

- **--lineify-cm**
- **--lineify-colon**

    Dans le cas des formats `cm` et `colon`, la sortie est scindée et formatée ligne par ligne. Par conséquent, si seule une partie d’une ligne doit être traduite, le résultat attendu ne peut pas être obtenu. Ces filtres corrigent une sortie corrompue par la traduction d’une partie de ligne en une sortie normale ligne par ligne.

    Dans l’implémentation actuelle, si plusieurs parties d’une ligne sont traduites, elles sont sorties comme des lignes indépendantes.

# CACHE OPTIONS

Le module **xlate** peut stocker le texte traduit en cache pour chaque fichier et le lire avant l’exécution afin d’éliminer la surcharge des requêtes au serveur. Avec la stratégie de cache par défaut `auto`, il maintient les données du cache uniquement lorsque le fichier de cache existe pour le fichier cible.

Utilisez **--xlate-cache=clear** pour initier la gestion du cache ou pour nettoyer toutes les données de cache existantes. Une fois exécutée avec cette option, un nouveau fichier de cache sera créé s’il n’existe pas, puis automatiquement maintenu par la suite.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Maintenir le fichier de cache s’il existe.

    - `create`

        Créer un fichier de cache vide et quitter.

    - `always`, `yes`, `1`

        Maintenir le cache tant que la cible est un fichier normal.

    - `clear`

        Effacer d’abord les données du cache.

    - `never`, `no`, `0`

        Ne jamais utiliser le fichier de cache même s’il existe.

    - `accumulate`

        Par défaut, les données inutilisées sont supprimées du fichier de cache. Si vous ne voulez pas les supprimer et les conserver dans le fichier, utilisez `accumulate`.
- **--xlate-update**

    Cette option force la mise à jour du fichier de cache même si ce n’est pas nécessaire.

# COMMAND LINE INTERFACE

Vous pouvez facilement utiliser ce module depuis la ligne de commande en utilisant la commande `xlate` incluse dans la distribution. Voir la page de manuel `xlate` pour l’utilisation.

La commande `xlate` prend en charge les options longues au format GNU telles que `--to-lang`, `--from-lang`, `--engine` et `--file`. Utilisez `xlate -h` pour afficher toutes les options disponibles.

La commande `xlate` fonctionne de concert avec l’environnement Docker, donc même si vous n’avez rien installé localement, vous pouvez l’utiliser tant que Docker est disponible. Utilisez l’option `-D` ou `-C`.

Les opérations Docker sont gérées par [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), qui peut également être utilisé comme commande autonome. La commande `dozo` prend en charge le fichier de configuration `.dozorc` pour des paramètres de conteneur persistants.

De plus, comme des makefiles pour divers styles de documents sont fournis, la traduction vers d’autres langues est possible sans spécification particulière. Utilisez l’option `-M`.

Vous pouvez également combiner les options Docker et `make` afin de pouvoir exécuter `make` dans un environnement Docker.

L’exécution comme `xlate -C` lancera un shell avec le dépôt git de travail actuel monté.

Lisez l’article japonais dans la section ["SEE ALSO"](#see-also) pour plus de détails.

# EMACS

Chargez le fichier `xlate.el` inclus dans le dépôt pour utiliser la commande `xlate` depuis l’éditeur Emacs. La fonction `xlate-region` traduit la région donnée. La langue par défaut est `EN-US` et vous pouvez spécifier la langue en l’invoquant avec un préfixe.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Définissez votre clé d’authentification pour le service DeepL.

- OPENAI\_API\_KEY

    Clé d’authentification OpenAI, utilisée par les moteurs hérités **gpty**. Le moteur **gpt5** basé sur `llm` lit également cette variable, mais les clés stockées avec `llm keys set openai` fonctionnent aussi.

- GREPLE\_XLATE\_CACHE

    Définissez la stratégie de cache par défaut (voir ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Installez l’outil en ligne de commande pour le moteur que vous utilisez : `llm` pour le moteur **gpt5**, `deepl` pour DeepL, `gpty` pour les moteurs GPT hérités.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Exécuteur Docker générique utilisé par xlate pour les opérations sur les conteneurs

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Voir le manuel **greple** pour les détails sur le motif de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier des fichiers selon le résultat de la commande **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format de marqueur de conflit côte à côte avec l’option **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Module Greple **stripe** utilisé avec l’option **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Image de conteneur Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La bibliothèque `getoptlong.sh` utilisée pour l’analyse des options dans le script `xlate` et [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    La commande `llm` utilisée par le moteur **gpt5** pour accéder aux modèles LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Bibliothèque Python DeepL et commande CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliothèque Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interface en ligne de commande OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Module Greple pour traduire et remplacer uniquement les parties nécessaires avec l’API DeepL (en japonais)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Génération de documents en 15 langues avec le module API DeepL (en japonais)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Environnement Docker de traduction automatique avec l’API DeepL (en japonais)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
