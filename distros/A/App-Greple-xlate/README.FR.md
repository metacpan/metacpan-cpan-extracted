# NAME

App::Greple::xlate - module d'aide à la traduction pour greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# DESCRIPTION

Le module **Greple** **xlate** trouve des blocs de texte et les remplace par le texte traduit. Actuellement, seul le service DeepL est pris en charge par le module **xlate::deepl**.

Si vous voulez traduire un bloc de texte normal dans un document de style [pod](https://metacpan.org/pod/pod), utilisez la commande **greple** avec le module `xlate::deepl` et `perl` comme ceci :

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Le motif `^(\w.*\n)+` signifie des lignes consécutives commençant par une lettre alpha-numérique. Cette commande montre la zone à traduire. L'option **--all** est utilisée pour produire le texte entier.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ensuite, ajoutez l'option `--xlate` pour traduire la zone sélectionnée. Elle les trouvera et les remplacera par la sortie de la commande **deepl**.

Par défaut, le texte original et traduit est imprimé dans le format "marqueur de conflit" compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez obtenir facilement la partie souhaitée par la commande [unifdef(1)](http://man.he.net/man1/unifdef). Le format peut être spécifié par l'option **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous voulez traduire un texte entier, utilisez l'option **--match-entire**. Il s'agit d'un raccourci pour spécifier que le motif correspond au texte entier `(?s).*`.

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

    Spécifiez le moteur de traduction à utiliser. Vous n'avez pas à utiliser cette option car le module `xlate::deepl` le déclare comme `--xlate-engine=deepl`.

- **--xlate-labor**

    Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour. Après avoir préparé les textes à traduire, ils sont copiés dans le presse-papiers. Vous êtes censé les coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur la touche retour.

- **--xlate-to** (Default: `JA`)

    Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles par la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et le texte traduit.

    - **conflict**, **cm**

        Imprimez le texte original et traduit au format de marqueur de conflit [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original par la commande [sed(1)](http://man.he.net/man1/sed) suivante.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Impression du texte original et du texte traduit au format `#ifdef` de [cpp(1)](http://man.he.net/man1/cpp).

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Vous pouvez récupérer uniquement le texte japonais par la commande **unifdef** :

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Imprimer le texte original et le texte traduit séparés par une seule ligne blanche.

    - **xtxt**

        Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est imprimé.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Voir le résultat de la traduction en temps réel dans la sortie STDERR.

- **--match-entire**

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

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Définissez votre clé d'authentification pour le service DeepL.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Bibliothèque Python et commande CLI.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Voir le manuel **greple** pour les détails sur le modèle de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier les fichiers par le résultat de la commande **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format des marqueurs de conflit côte à côte avec l'option **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
