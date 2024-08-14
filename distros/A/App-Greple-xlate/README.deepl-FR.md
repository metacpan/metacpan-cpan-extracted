# NAME

App::Greple::xlate - module d'aide à la traduction pour greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3202

# DESCRIPTION

Le module **Greple** **xlate** recherche les blocs de texte souhaités et les remplace par le texte traduit. Actuellement, les modules DeepL (`deepl.pm`) et ChatGPT (`gpt3.pm`) sont mis en œuvre en tant que moteur dorsal. Un support expérimental pour gpt-4 est également inclus.

Si vous souhaitez traduire des blocs de texte normaux dans un document écrit dans le style Perl's pod, utilisez la commande **greple** avec les modules `xlate::deepl` et `perl` comme suit :

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Dans cette commande, la chaîne de caractères `^(\w.*\n)+` signifie des lignes consécutives commençant par une lettre alphanumérique. Cette commande met en évidence la zone à traduire. L'option **--tout** est utilisée pour produire le texte entier.

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
- Si une ligne se termine par un caractère de pleine largeur et que la ligne suivante commence par un caractère de pleine largeur, concaténer les lignes.
- Si la fin ou le début d'une ligne n'est pas un caractère de pleine largeur, concaténer les lignes en insérant un caractère d'espacement.

Les données mises en cache sont gérées sur la base du texte normalisé, de sorte que même si des modifications sont apportées sans affecter les résultats de la normalisation, les données de traduction mises en cache resteront effectives.

Ce processus de normalisation n'est effectué que pour le premier (0e) motif et les motifs pairs. Ainsi, si deux motifs sont spécifiés comme suit, le texte correspondant au premier motif sera traité après normalisation, et aucun processus de normalisation ne sera effectué sur le texte correspondant au second motif.

    greple -Mxlate -E normalized -E not-normalized

Par conséquent, il convient d'utiliser le premier motif pour le texte qui doit être traité en combinant plusieurs lignes en une seule et d'utiliser le second motif pour le texte préformaté. S'il n'y a pas de texte à faire correspondre au premier motif, alors un motif qui ne correspond à rien, tel que `( ?!)`.

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

- **--xlate-labor**
- **--xlabor**

    Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour lui. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous devez les coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur la touche retour.

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles par la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et le texte traduit.

    - **conflict**, **cm**

        Le texte original et le texte converti sont imprimés au format [git(1)](http://man.he.net/man1/git) marqueur de conflit.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original par la commande [sed(1)](http://man.he.net/man1/sed) suivante.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

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

        Le texte original et le texte converti sont imprimés séparés par une seule ligne blanche.

    - **xtxt**

        Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est imprimé.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Spécifiez la longueur maximale du texte à envoyer à l'API en une seule fois. La valeur par défaut est la même que pour le service de compte gratuit DeepL : 128K pour l'API (**--xlate**) et 5000 pour l'interface du presse-papiers (**--xlate-labor**). Vous pouvez modifier ces valeurs si vous utilisez le service Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Voir le résultat de la traduction en temps réel dans la sortie STDERR.

- **--match-all**

    Définissez l'ensemble du texte du fichier comme zone cible.

# CACHE OPTIONS

Le module **xlate** peut stocker le texte de la traduction en cache pour chaque fichier et le lire avant l'exécution pour éliminer les frais généraux de demande au serveur. Avec la stratégie de cache par défaut `auto`, il maintient les données de cache uniquement lorsque le fichier de cache existe pour le fichier cible.

- --cache-clear

    L'option **--cache-clear** peut être utilisée pour initier la gestion du cache ou pour rafraîchir toutes les données du cache existant. Une fois exécutée avec cette option, un nouveau fichier de cache sera créé s'il n'en existe pas, puis automatiquement maintenu par la suite.

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

# COMMAND LINE INTERFACE

Vous pouvez facilement utiliser ce module à partir de la ligne de commande en utilisant la commande `xlate` incluse dans la distribution. Voir l'aide de `xlate` pour l'utilisation.

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
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
        -w # wrap line by # width
        -o # output format (default "xtxt", or "cm", "ifdef")
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
        -M   run make
        -n   dry-run
    Docker options
        -G   mount git top-level directory
        -B   run in non-interactive (batch) mode
        -R   mount read-only
        -E * specify environment variable to be inherited
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

Chargez le fichier `xlate.el` inclus dans le dépôt pour utiliser la commande `xlate` à partir de l'éditeur Emacs. La fonction `xlate-region` traduit la région donnée. La langue par défaut est `EN-US` et vous pouvez spécifier la langue en l'invoquant avec l'argument prefix.

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

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

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

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
