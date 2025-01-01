# NAME

App::Greple::xlate - module d'aide à la traduction pour greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9902

# DESCRIPTION

Le module **Greple** **xlate** recherche les blocs de texte souhaités et les remplace par le texte traduit. Actuellement, les modules DeepL (`deepl.pm`) et ChatGPT (`gpt3.pm`) sont mis en œuvre en tant que moteur dorsal. Un support expérimental pour gpt-4 et gpt-4o est également inclus.

Si vous souhaitez traduire des blocs de texte normaux dans un document écrit dans le style Perl's pod, utilisez la commande **greple** avec les modules `xlate::deepl` et `perl` comme suit :

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dans cette commande, la chaîne de caractères `^([\w\p].*\n)+` signifie des lignes consécutives commençant par des lettres alphanumériques et de ponctuation. Cette commande permet de mettre en évidence la zone à traduire. L'option **-tout** est utilisée pour produire un texte entier.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ajoutez ensuite l'option `--xlate` pour traduire la zone sélectionnée. Ensuite, les sections souhaitées seront trouvées et remplacées par la sortie de la commande **deepl**.

Par défaut, les textes originaux et traduits sont imprimés dans le format "marqueur de conflit" compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez facilement obtenir la partie souhaitée par la commande [unifdef(1)](http://man.he.net/man1/unifdef). Le format de sortie peut être spécifié par l'option **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous souhaitez traduire un texte entier, utilisez l'option **--match-all**. Il s'agit d'un raccourci pour spécifier le modèle `(?s).+` qui correspond à un texte entier.

Les données du format de marqueur de conflit peuvent être visualisées côte à côte par la commande `sdif` avec l'option `-V`. Étant donné qu'il est absurde de comparer les données par chaîne, il est recommandé d'utiliser l'option `--no-cdif`. Si vous n'avez pas besoin de colorer le texte, spécifiez `--no-textcolor` (ou `--no-tc`).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

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

Chaque ligne du fichier \`MASKPATTERN\` sera interprétée comme une expression régulière, traduira les chaînes de caractères qui y correspondent et reviendra en arrière après le traitement. Les lignes commençant par `#` sont ignorées.

Un motif complexe peut être écrit sur plusieurs lignes avec une barre oblique inverse et une nouvelle ligne.

L'option **--xlate-mask** permet de voir comment le texte est transformé par le masquage.

Cette interface est expérimentale et peut être modifiée à l'avenir.

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

    Spécifie le moteur de traduction à utiliser. Si vous spécifiez directement le module du moteur, tel que `-Mxlate::deepl`, vous n'avez pas besoin d'utiliser cette option.

    À l'heure actuelle, les moteurs suivants sont disponibles

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        L'interface de **gpt-4o** est instable et son bon fonctionnement ne peut être garanti pour le moment.

- **--xlate-labor**
- **--xlabor**

    Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour lui. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous devez les coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur la touche retour.

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles par la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et le texte traduit.

    Les formats suivants, autres que `xtxt`, supposent que la partie à traduire est une collection de lignes. En fait, il est possible de ne traduire qu'une partie d'une ligne, et la spécification d'un format autre que `xtxt` ne produira pas de résultats significatifs.

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

    Spécifiez la longueur maximale du texte à envoyer à l'API en une seule fois. La valeur par défaut est la même que pour le service de compte gratuit DeepL : 128K pour l'API (**--xlate**) et 5000 pour l'interface du presse-papiers (**--xlate-labor**). Vous pouvez modifier ces valeurs si vous utilisez le service Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Indiquez le nombre maximal de lignes de texte à envoyer à l'API en une seule fois.

    Définissez cette valeur sur 1 si vous souhaitez traduire une ligne à la fois. Cette option est prioritaire sur l'option `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Voir le résultat de la traduction en temps réel dans la sortie STDERR.

- **--xlate-stripe**

    Utilisez le module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pour afficher la partie correspondante sous forme de bandes zébrées. Ceci est utile lorsque les parties correspondantes sont connectées dos à dos.

    La palette de couleurs est modifiée en fonction de la couleur d'arrière-plan du terminal. Si vous souhaitez le spécifier explicitement, vous pouvez utiliser **--xlate-stripe-light** ou **--xlate-stripe-dark**.

- **--xlate-mask**

    Exécuter la fonction de masquage et afficher le texte converti tel quel sans restauration.

- **--match-all**

    Définissez l'ensemble du texte du fichier comme zone cible.

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

La commande `xlate` fonctionne de concert avec l'environnement Docker, donc même si vous n'avez rien d'installé, vous pouvez l'utiliser tant que Docker est disponible. Utilisez l'option `-D` ou `-C`.

De plus, comme des makefiles pour différents styles de documents sont fournis, la traduction dans d'autres langues est possible sans spécification particulière. Utilisez l'option `-M`.

Vous pouvez également combiner les options Docker et make afin de pouvoir exécuter make dans un environnement Docker.

L'exécution de `xlate -GC` lancera un shell avec le dépôt git actuel monté.

Lire l'article japonais dans la section ["SEE ALSO"](#see-also) pour plus de détails.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -u   force update cache
        -s   silent mode
        -e # translation engine (*deepl, gpt3, gpt4, gpt4o)
        -p # pattern to determine translation area
        -x # file containing mask patterns
        -w # wrap line by # width
        -o # output format (*xtxt, cm, ifdef, space, space+, colon)
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   end of option
        N.B. default is marked as *

    Make options
        -M   run make
        -n   dry-run

    Docker options
        -D * run xlate on the container with the same parameters
        -C * execute following command on the container, or run shell
        -S * start the live container
        -A * attach to the live container
        N.B. -D/-C/-A terminates option handling

        -G   mount git top-level directory
        -H   mount home directory
        -V # specify mount directory
        -U   do not mount
        -R   mount read-only
        -L   do not remove and keep live container
        -K   kill and remove live container
        -E # specify environment variable to be inherited
        -I # docker image or version (default: tecolicom/xlate:version)

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

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

    Clé d'authentification OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Vous devez installer les outils de ligne de commande pour DeepL et ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Image de conteneur Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Bibliothèque Python et commande CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliothèque Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interface de ligne de commande OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Voir le manuel **greple** pour les détails sur le modèle de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier les fichiers par le résultat de la commande **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format des marqueurs de conflit côte à côte avec l'option **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Utilisation du module Greple **stripe** par l'option **--xlate-stripe**.

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
