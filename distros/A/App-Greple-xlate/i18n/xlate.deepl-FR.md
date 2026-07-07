# NAME

App::Greple::xlate - module d'aide à la traduction pour greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** : le module recherche les blocs de texte souhaités et les remplace par le texte traduit. Le moteur principal est GPT-5.5 (`llm/gpt5.pm`), qui appelle la commande [llm](https://llm.datasette.io/) ; DeepL (`deepl.pm`) et les moteurs hérités basés sur **gpty** sont également inclus.

Les traductions sont mises en cache par fichier ; ainsi, relancer une commande ne coûte rien pour le texte inchangé. Lorsqu’un document est modifié, seuls les paragraphes modifiés sont renvoyés à l’API ; un moteur sensible au contexte reçoit également les traductions environnantes, le texte source brut entourant la modification et la version précédente du paragraphe modifié, de sorte que la nouvelle traduction conserve la formulation établie (voir **--xlate-context-window**). Les chaînes sensibles peuvent être masquées avant la transmission (voir ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Si vous souhaitez traduire des blocs de texte normaux dans un document rédigé dans le style pod de Perl, utilisez la commande **greple** avec les modules `--xlate-engine gpt5` et `perl` comme suit :

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dans cette commande, la chaîne de caractères `^([\w\p].*\n)+` signifie des lignes consécutives commençant par des lettres alphanumériques et de ponctuation. Cette commande permet de mettre en évidence la zone à traduire. L'option **-tout** est utilisée pour produire un texte entier.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ajoutez ensuite l’option `--xlate` pour traduire la zone sélectionnée. Le moteur de traduction identifiera alors les sections souhaitées et les remplacera par le résultat de la traduction.

Par défaut, les textes originaux et traduits sont imprimés dans le format "marqueur de conflit" compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez facilement obtenir la partie souhaitée par la commande [unifdef(1)](http://man.he.net/man1/unifdef). Le format de sortie peut être spécifié par l'option **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous souhaitez traduire un texte entier, utilisez l'option **--match-all**. Il s'agit d'un raccourci pour spécifier le modèle `(?s).+` qui correspond à un texte entier.

Les données au format marqueur de conflit peuvent être visualisées côte à côte par la commande [sdif](https://metacpan.org/pod/App%3A%3Asdif) avec l'option `-V`. Étant donné qu'il n'est pas utile de comparer chaque chaîne de caractères, il est recommandé d'utiliser l'option `--no-cdif`. Si vous n'avez pas besoin de colorer le texte, spécifiez `--no-textcolor` (ou `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Le traitement se fait par unités spécifiées, mais dans le cas d'une séquence de plusieurs lignes de texte non vide, elles sont converties ensemble en une seule ligne. Cette opération s'effectue comme suit :

- Supprimer les espaces blancs au début et à la fin de chaque ligne.
- Si une ligne se termine par un caractère de ponctuation de pleine largeur, concaténer avec la ligne suivante.
- Si une ligne se termine par un caractère de pleine largeur et que la ligne suivante commence par un caractère de pleine largeur, concaténer les lignes.
- Si la fin ou le début d'une ligne n'est pas un caractère de pleine largeur, concaténer les lignes en insérant un caractère d'espacement.

Les données mises en cache sont gérées sur la base du texte normalisé, de sorte que même si des modifications sont apportées sans affecter les résultats de la normalisation, les données de traduction mises en cache resteront effectives.

Ce processus de normalisation n'est effectué que pour le premier (0e) motif et les motifs pairs. Ainsi, si deux motifs sont spécifiés comme suit, le texte correspondant au premier motif sera traité après normalisation, et aucun processus de normalisation ne sera effectué sur le texte correspondant au second motif.

    greple -Mxlate -E normalized -E not-normalized

Par conséquent, utilisez le premier motif pour le texte qui doit être traité en combinant plusieurs lignes en une seule, et utilisez le second motif pour le texte préformaté. S'il n'y a pas de texte à faire correspondre dans le premier motif, utilisez un motif qui ne correspond à rien, tel que `(?!)`.

# MASKING

Il arrive que des parties de texte ne soient pas traduites. Par exemple, les balises dans les fichiers markdown. DeepL suggère que dans de tels cas, la partie du texte à exclure soit convertie en balises XML, traduite, puis restaurée une fois la traduction terminée. Pour ce faire, il est possible de spécifier les parties à masquer de la traduction.

    --xlate-setopt maskfile=MASKPATTERN

Cela interprétera chaque ligne du fichier `MASKPATTERN` comme une expression régulière, traduira les chaînes qui correspondent et reviendra en arrière après le traitement. Les lignes commençant par `#` sont ignorées.

Les motifs complexes peuvent être écrits sur plusieurs lignes en utilisant des sauts de ligne échappés par une barre oblique inversée.

L'option **--xlate-mask** permet de voir comment le texte est transformé par le masquage.

Le masquage empêche le balisage d’être traduit. Pour masquer des chaînes sensibles vis-à-vis du service de traduction lui-même, consultez ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates) ; les deux méthodes peuvent être utilisées conjointement.

Cette interface est expérimentale et peut être modifiée à l'avenir.

# ANONYMIZATION AND TEMPLATES

Les chaînes sensibles peuvent être masquées avant d’être envoyées à l’API de traduction, puis restaurées dans le résultat final. Trois sources de règles d’anonymisation sont disponibles : un fichier de dictionnaire (**--xlate-anonymize**), des balises intégrées dans le document lui-même (**--xlate-anonymize-mark**) et les valeurs de l’en-tête YAML (**--xlate-frontmatter**). Chaque chaîne est remplacée par une balise de catégorie telle que `<person id=1 />` lors de la transmission. La dissimulation ne concerne que la transmission via l’API : les fichiers de cache locaux stockent le texte en clair restauré. Utilisez **--xlate-dryrun** pour vérifier exactement ce qui serait transmis.

Pour les documents de type formulaire (rapports trimestriels et autres), définissez les acteurs au préalable et faites-y référence dans le corps du texte :

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Traduisez le modèle une fois par langue avec `--xlate-template` (et `--xlate-frontmatter` lorsque les valeurs sont conservées dans le fichier), puis générez chaque cas en mode autonome avec **pandoc-embedz** — les valeurs situées sous `global:` dans une configuration externe n’atteignent jamais l’API de traduction :

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Pour les balises en ligne, fournir une configuration de définition de macro permet au même modèle traduit d’afficher soit les noms réels, soit une version expurgée :

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

    Invoquez le processus de traduction pour chaque zone appariée.

    Sans cette option, **greple** se comporte comme une commande de recherche normale. Vous pouvez donc vérifier quelle partie du fichier fera l'objet de la traduction avant d'invoquer le travail réel.

    Le résultat de la commande va vers la sortie standard, donc redirigez vers le fichier si nécessaire, ou envisagez d'utiliser le module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    L'option **--xlate** appelle l'option **--xlate-color** avec l'option **--color=never**.

    Avec l'option **--xlate-fold**, le texte converti est plié selon la largeur spécifiée. La largeur par défaut est de 70 et peut être définie par l'option **--xlate-fold-width**. Quatre colonnes sont réservées à l'opération de rodage, de sorte que chaque ligne peut contenir 74 caractères au maximum.

- **--xlate-engine**=_engine_

    Spécifie le moteur de traduction à utiliser.

    À l'heure actuelle, les moteurs suivants sont disponibles

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Les modules du moteur sont d’abord recherchés dans les espaces de noms du backend (`llm`, puis `gpty`), puis directement sous `App::Greple::xlate`. Ainsi, `gpt5` charge `App::Greple::xlate::llm::gpt5` qui appelle la commande `llm`, tandis que `gpt4o` se rabat sur `App::Greple::xlate::gpty::gpt4o`. Utilisez `--xlate-setopt backend=gpty` pour forcer un backend spécifique.

- **--xlate-labor**
- **--xlabor**

    Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour lui. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous devez les coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur la touche retour.

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Les moteurs LLM acceptent tout nom ou code de langue compris par le modèle ; celui-ci est interpolé dans la ligne de commande de traduction. Vous pouvez obtenir la liste des langues disponibles via la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Étiquette utilisée pour le texte d’origine dans les formats de sortie `conflict`, `colon` et `ifdef`. Avec le moteur **DeepL**, une valeur non par défaut est également transmise en tant que langue source.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et le texte traduit.

    Les formats suivants autres que `xtxt` supposent que la partie à traduire est une collection de lignes. En fait, il est possible de ne traduire qu'une partie d'une ligne, mais la spécification d'un format autre que `xtxt` ne produira pas de résultats significatifs.

    - **conflict**, **cm**

        Le texte original et le texte converti sont imprimés au format [git(1)](http://man.he.net/man1/git) marqueur de conflit.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original par la commande [sed(1)](http://man.he.net/man1/sed) suivante.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Le texte original et le texte traduit sont édités dans un style de conteneur personnalisé de markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Le texte ci-dessus sera traduit en HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Le nombre de deux-points est de 7 par défaut. Si vous spécifiez une séquence de deux points comme `:::::`, elle est utilisée à la place des 7 points.

    - **ifdef**

        Le texte original et le texte converti sont imprimés au format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Vous pouvez récupérer uniquement le texte japonais par la commande **unifdef** :

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Le texte original et le texte converti sont imprimés séparés par une seule ligne blanche. Pour `space+`, le texte converti est également suivi d'une nouvelle ligne.

    - **xtxt**

        Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est imprimé.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Spécifiez la longueur maximale du texte à envoyer à l’API en une seule fois. La valeur par défaut 0 correspond à la limite propre au moteur : pour le service DeepL en compte gratuit, elle est de 128K pour l’API (**--xlate**) et de 5000 pour l’interface du presse-papiers (**--xlate-labor**). Vous pouvez modifier ces valeurs si vous utilisez le service Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Indiquez le nombre maximal de lignes de texte à envoyer à l'API en une seule fois.

    Définissez cette valeur sur 1 si vous souhaitez traduire une ligne à la fois. Cette option est prioritaire sur l'option `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Spécifiez une invite personnalisée à envoyer au moteur de traduction. Cette option est disponible pour les moteurs LLM (`gpt3`, `gpt4o`, `gpt5`), mais pas pour DeepL. Vous pouvez personnaliser le comportement de traduction en fournissant des instructions spécifiques au modèle d’IA. Si la consigne contient `%s`, celle-ci sera remplacée par le nom de la langue cible.

- **--xlate-context**=_text_

    Spécifiez des informations contextuelles supplémentaires à envoyer au moteur de traduction. Cette option peut être utilisée plusieurs fois pour fournir plusieurs chaînes de contexte. Les informations contextuelles aident le moteur de traduction à comprendre le contexte et à produire des traductions plus précises.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Nombre de blocs traduits environnants transmis comme contexte de référence lors de la retraduction des blocs modifiés (valeur par défaut : 2). Le contexte inclut également le texte source brut entourant la zone modifiée (titres, structure de liste, légendes) et, le cas échéant, la version précédente du texte modifié récupérée dans le cache, afin de préserver les formulations inchangées. Définissez cette valeur sur 0 pour désactiver complètement la traduction contextuelle. Notez que chaque zone modifiée est traduite via son propre appel API et que le contexte peut ajouter jusqu’à environ 8 000 caractères à la commande système ; la traduction contextuelle implique donc un surcoût en échange d’une meilleure cohérence.

- **--xlate-cache-seed**=_file_

    Initialise le cache d’un nouveau document à partir du fichier de cache d’un autre document. Utile pour les rapports périodiques : initialise le cache du nouveau numéro avec celui du numéro précédent, de sorte que les paragraphes inchangés ne soient pas retraduits et que les paragraphes modifiés conservent la formulation du numéro précédent. L’initialisation n’est utilisée que lorsque le cache cible est vide ; sinon, elle est ignorée et un avertissement est affiché. Avec la valeur par défaut `--xlate-cache=auto`, la spécification d’une initialisation implique également la création du fichier de cache du nouveau document.

- **--xlate-anonymize**=_file_

    Anonymiser les chaînes sensibles avant leur envoi à l’API de traduction, puis les restaurer dans la sortie. Le fichier de dictionnaire contient une entrée par élément : au format JSON (canonique, générable par une machine)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    ou au format ligne simple (`category pattern`, `/.../` pour les expressions régulières). Chaque élément est remplacé par une balise de catégorie telle que `<person id=1 />` ; une même chaîne reçoit toujours la même balise, ce qui permet au modèle de savoir qui est qui. Les champs JSON inconnus sont ignorés, de sorte que les générateurs (par exemple, un LLM local extrayant des entités) peuvent ajouter leurs propres annotations. La catégorie `lit` est réservée. Les fichiers de cache locaux continuent de stocker le texte brut restauré : la dissimulation ne concerne que la transmission via l’API.

    Un dictionnaire peut être généré par un outil externe — par exemple un modèle local extrayant des entités sensibles :

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    La présence d’un BOM UTF-8 dans le fichier est tolérée. Les valeurs au format « front matter » peuvent comporter un commentaire final uniquement sur leur propre ligne, et non après la valeur.

- **--xlate-anonymize-mark**\[=_regex_\]

    Collectez les entrées d’anonymisation à partir des balises intégrées dans le document lui-même. Marquez la première occurrence comme `{{ person("山田太郎") }}` et chaque occurrence de la chaîne dans l’ensemble du document sera anonymisée. La balise elle-même reste dans la source et dans la traduction, de sorte qu’un document peut également être traité par un processeur de macros de type Jinja2 (définissez la macro `person` pour afficher ou masquer le nom). Une balise personnalisée _regex_ doit contenir des captures nommées `(?<category>...)` et `(?<text>...)`.

    Notez qu’avec une option à valeur facultative comme celle-ci, un argument de fichier suivant serait considéré comme la valeur : écrivez `--xlate-anonymize-mark=` (suivi de `=`) lorsque vous utilisez la notation par défaut.

    D’autres notations peuvent être configurées, par exemple `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` pour les balises de type `@@person:NAME@@`, ou une forme de commentaire HTML qui reste invisible dans le Markdown rendu. Les règles de marquage sont regroupées par document : une chaîne marquée dans un fichier d’entrée n’est pas masquée dans un autre fichier de la même exécution (contrairement aux valeurs de l’en-tête, qui s’accumulent d’un fichier à l’autre).

- **--xlate-template**\[=_regex_\]

    Traitez les expressions de modèle (par défaut : Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) comme des espaces réservés opaques : demandez au modèle de les copier telles quelles et vérifiez, bloc par bloc, que la réponse contient exactement les mêmes expressions, chacune un nombre identique de fois. Leur ordre peut changer, car la traduction les réorganise légitimement pour respecter l’ordre des mots de la langue cible. Une expression incorrecte interrompt l’exécution ; le cache est sauvegardé et gelé, de sorte que rien de ce qui a été payé n’est perdu.

    Notez qu’avec une option à valeur facultative comme celle-ci, un argument de fichier suivant serait considéré comme la valeur : écrivez `--xlate-template=` (suivi de `=`) lorsque vous utilisez la notation par défaut.

- **--xlate-frontmatter**

    Traitez un bloc commençant par `---` ... `---` comme une partie d’en-tête YAML : l’exclure de la traduction et des tranches de contexte de la phase 2, et ajouter ses valeurs plates `key: value` aux règles d’anonymisation (catégorie `var`) à titre de filet de sécurité. En cas de fichiers d’entrée multiples, les valeurs collectées s’accumulent (en privilégiant la prudence).

    Laissez toujours une ligne vide après la balise de fermeture `---`. Avec un modèle de correspondance de type paragraphe, le front matter qui se fond directement dans le corps du texte forme un bloc chevauchant que l’exclusion ne peut pas supprimer (un avertissement s’affiche dans ce cas) ; les valeurs sont toujours anonymisées, mais les éléments préliminaires eux-mêmes seraient envoyés pour traduction.

- **--xlate-glossary**=_glossary_

    Spécifier un identifiant de glossaire à utiliser pour la traduction. Cette option n'est disponible que lors de l'utilisation du moteur DeepL. L'ID du glossaire doit être obtenu à partir de votre compte DeepL et garantit une traduction cohérente de termes spécifiques.

- **--xlate-dryrun**

    N’appelez pas l’API de traduction ; affichez plutôt, via la barre de progression, chaque charge utile exactement telle qu’elle serait transmise (après anonymisation et masquage). Utile pour vérifier ce qui sort de la machine et pour estimer le coût d’une exécution.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Consultez le résultat de la traduction en temps réel dans la sortie STDERR. La charge utile `From` est affichée telle qu’elle est transmise, après anonymisation et masquage.

- **--xlate-stripe**

    Utilisez le module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pour afficher la partie correspondante sous forme de bandes zébrées. Ceci est utile lorsque les parties correspondantes sont connectées dos à dos.

    La palette de couleurs est modifiée en fonction de la couleur d'arrière-plan du terminal. Si vous souhaitez le spécifier explicitement, vous pouvez utiliser **--xlate-stripe-light** ou **--xlate-stripe-dark**.

- **--xlate-mask**

    Exécuter la fonction de masquage et afficher le texte converti tel quel sans restauration.

- **--match-all**

    Définissez l'ensemble du texte du fichier comme zone cible.

- **--lineify-cm**
- **--lineify-colon**

    Dans le cas des formats `cm` et `colon`, la sortie est divisée et formatée ligne par ligne. Par conséquent, si seule une partie d'une ligne doit être traduite, le résultat escompté ne peut être obtenu. Ces filtres corrigent la sortie qui est corrompue par la traduction d'une partie d'une ligne en une sortie ligne par ligne normale.

    Dans l'implémentation actuelle, si plusieurs parties d'une ligne sont traduites, elles sont produites comme des lignes indépendantes.

# CACHE OPTIONS

Le module **xlate** peut stocker le texte de la traduction en cache pour chaque fichier et le lire avant l'exécution pour éliminer les frais généraux de demande au serveur. Avec la stratégie de cache par défaut `auto`, il maintient les données de cache uniquement lorsque le fichier de cache existe pour le fichier cible.

Utilisez **--xlate-cache=clear** pour lancer la gestion du cache ou pour nettoyer toutes les données de cache existantes. Une fois cette option exécutée, un nouveau fichier de cache sera créé s'il n'en existe pas et sera automatiquement maintenu par la suite.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Maintenir le fichier de cache s'il existe.

    - `create`

        Créer un fichier cache vide et quitter.

    - `always`, `yes`, `1`

        Maintenir le cache de toute façon tant que la cible est un fichier normal.

    - `clear`

        Effacer d'abord les données du cache.

    - `never`, `no`, `0`

        Ne jamais utiliser le fichier cache même s'il existe.

    - `accumulate`

        Par défaut, les données inutilisées sont supprimées du fichier cache. Si vous ne voulez pas les supprimer et les conserver dans le fichier, utilisez `accumulate`.
- **--xlate-update**

    Cette option oblige à mettre à jour le fichier de cache même si cela n'est pas nécessaire.

# COMMAND LINE INTERFACE

Vous pouvez facilement utiliser ce module à partir de la ligne de commande en utilisant la commande `xlate` incluse dans la distribution. Voir la page de manuel `xlate` pour l'utilisation.

La commande `xlate` prend en charge les options longues de style GNU telles que `--to-lang`, `--from-lang`, `--engine` et `--file`. Utilisez `xlate -h` pour voir toutes les options disponibles.

La commande `xlate` fonctionne de concert avec l'environnement Docker, donc même si vous n'avez rien d'installé, vous pouvez l'utiliser tant que Docker est disponible. Utilisez l'option `-D` ou `-C`.

Les opérations Docker sont gérées par [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), qui peut également être utilisé comme une commande autonome. La commande `dozo` prend en charge le fichier de configuration `.dozorc` pour les paramètres persistants des conteneurs.

De plus, comme des makefiles pour différents styles de documents sont fournis, la traduction dans d'autres langues est possible sans spécification particulière. Utilisez l'option `-M`.

Vous pouvez également combiner les options Docker et `make` afin d'exécuter `make` dans un environnement Docker.

L'exécution de `xlate -C` lancera un shell avec le dépôt git actuel monté.

Lire l'article japonais dans la section ["SEE ALSO"](#see-also) pour plus de détails.

# EMACS

Chargez le fichier `xlate.el` inclus dans le dépôt pour utiliser la commande `xlate` à partir de l'éditeur Emacs. La fonction `xlate-region` traduit la région donnée. La langue par défaut est `EN-US` et vous pouvez spécifier la langue en l'invoquant avec l'argument prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Définissez votre clé d'authentification pour le service DeepL.

- OPENAI\_API\_KEY

    Clé d’authentification OpenAI, utilisée par les moteurs hérités **gpty**. Le moteur **gpt5** basé sur `llm` lit également cette variable, mais les clés stockées avec `llm keys set openai` fonctionnent également.

- GREPLE\_XLATE\_CACHE

    Définissez la stratégie de cache par défaut (voir ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Installez l’outil en ligne de commande correspondant au moteur que vous utilisez : `llm` pour le moteur **gpt5**, `deepl` pour DeepL, `gpty` pour les anciens moteurs GPT.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Exécutant Docker générique utilisé par xlate pour les opérations sur les conteneurs.

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Voir le manuel **greple** pour les détails sur le modèle de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier les fichiers par le résultat de la commande **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format des marqueurs de conflit côte à côte avec l'option **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Utilisation du module Greple **stripe** par l'option **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Image de conteneur Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La bibliothèque `getoptlong.sh` utilisée pour l'analyse des options dans le script `xlate` et [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    La commande `llm` utilisée par le moteur **gpt5** pour accéder aux modèles LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Bibliothèque Python et commande CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliothèque Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interface de ligne de commande OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Module Greple pour traduire et remplacer uniquement les parties nécessaires avec DeepL API (en japonais)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Génération de documents en 15 langues avec le module DeepL API (en japonais)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Traduction automatique de l'environnement Docker avec DeepL API (en japonais)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
