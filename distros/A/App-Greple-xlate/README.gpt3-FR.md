# NAME

App::Greple::xlate - module de support de traduction pour greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.30

# DESCRIPTION

Le module **Greple** **xlate** trouve les blocs de texte souhaités et les remplace par le texte traduit. Actuellement, les modules DeepL (`deepl.pm`) et ChatGPT (`gpt3.pm`) sont implémentés en tant que moteur de back-end. Un support expérimental pour gpt-4 est également inclus.

Si vous souhaitez traduire des blocs de texte normaux dans un document écrit dans le style pod de Perl, utilisez la commande **greple** avec les modules `xlate::deepl` et `perl` de cette manière :

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Dans cette commande, la chaîne de motif `^(\w.*\n)+` signifie des lignes consécutives commençant par une lettre alphanumérique. Cette commande affiche la zone à traduire mise en évidence. L'option **--all** est utilisée pour produire l'intégralité du texte.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ensuite, ajoutez l'option `--xlate` pour traduire la zone sélectionnée. Ensuite, il trouvera les sections souhaitées et les remplacera par la sortie de la commande **deepl**.

Par défaut, le texte original et traduit est affiché dans le format "conflict marker" compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez obtenir la partie souhaitée avec la commande [unifdef(1)](http://man.he.net/man1/unifdef) facilement. Le format de sortie peut être spécifié avec l'option **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous souhaitez traduire l'intégralité du texte, utilisez l'option **--match-all**. Il s'agit d'un raccourci pour spécifier le motif `(?s).+` qui correspond à l'ensemble du texte.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Lancez le processus de traduction pour chaque zone correspondante.

    Sans cette option, **greple** se comporte comme une commande de recherche normale. Vous pouvez donc vérifier quelle partie du fichier sera soumise à la traduction avant de lancer le travail réel.

    Le résultat de la commande est renvoyé sur la sortie standard, donc redirigez-le vers un fichier si nécessaire, ou envisagez d'utiliser le module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    L'option **--xlate** appelle l'option **--xlate-color** avec l'option **--color=never**.

    Avec l'option **--xlate-fold**, le texte converti est plié selon la largeur spécifiée. La largeur par défaut est de 70 et peut être définie par l'option **--xlate-fold-width**. Quatre colonnes sont réservées pour l'opération run-in, donc chaque ligne peut contenir au maximum 74 caractères.

- **--xlate-engine**=_engine_

    Spécifie le moteur de traduction à utiliser. Si vous spécifiez directement le module du moteur, tel que `-Mxlate::deepl`, vous n'avez pas besoin d'utiliser cette option.

- **--xlate-labor**
- **--xlabor**

    Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour lui. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous êtes censé le coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur Entrée.

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles avec la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et traduit.

    - **conflict**, **cm**

        Original et texte converti sont imprimés au format de marqueur de conflit [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original avec la commande [sed(1)](http://man.he.net/man1/sed) suivante.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Original et texte converti sont imprimés au format `#ifdef` [cpp(1)](http://man.he.net/man1/cpp).

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Vous pouvez récupérer uniquement le texte japonais avec la commande **unifdef** :

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Original et texte converti sont imprimés séparés par une seule ligne vide.

    - **xtxt**

        Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est imprimé.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Traduisez le texte suivant en français, ligne par ligne.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Voyez le résultat de la traduction en temps réel dans la sortie STDERR.

- **--match-all**

    Définissez l'intégralité du texte du fichier comme zone cible.

# CACHE OPTIONS

Le module **xlate** peut stocker le texte traduit en cache pour chaque fichier et le lire avant l'exécution pour éliminer les frais généraux de demande au serveur. Avec la stratégie de cache par défaut `auto`, il ne conserve les données en cache que lorsque le fichier de cache existe pour le fichier cible.

- --cache-clear

    L'option **--cache-clear** peut être utilisée pour initier la gestion du cache ou pour rafraîchir toutes les données de cache existantes. Une fois exécutée avec cette option, un nouveau fichier de cache sera créé s'il n'existe pas, puis automatiquement maintenu par la suite.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Maintenez le fichier de cache s'il existe.

    - `create`

        Créez un fichier de cache vide et quittez.

    - `always`, `yes`, `1`

        Maintenez le cache de toute façon tant que la cible est un fichier normal.

    - `clear`

        Effacez d'abord les données du cache.

    - `never`, `no`, `0`

        N'utilisez jamais le fichier de cache même s'il existe.

    - `accumulate`

        Par défaut, les données inutilisées sont supprimées du fichier de cache. Si vous ne souhaitez pas les supprimer et les conserver dans le fichier, utilisez `accumulate`.

# COMMAND LINE INTERFACE

Vous pouvez facilement utiliser ce module depuis la ligne de commande en utilisant la commande `xlate` incluse dans le référentiel. Consultez les informations d'aide de `xlate` pour connaître son utilisation.

# EMACS

Chargez le fichier `xlate.el` inclus dans le référentiel pour utiliser la commande `xlate` depuis l'éditeur Emacs. La fonction `xlate-region` traduit la région donnée. La langue par défaut est `EN-US` et vous pouvez spécifier la langue en l'appelant avec un argument préfixe.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Définissez votre clé d'authentification pour le service DeepL.

- OPENAI\_API\_KEY

    Clé d'authentification OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Vous devez installer les outils en ligne de commande pour DeepL et ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Bibliothèque DeepL Python et commande CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliothèque Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interface en ligne de commande OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultez le manuel **greple** pour plus de détails sur le motif de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier les fichiers en fonction du résultat de la commande **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format des marqueurs de conflit côte à côte avec l'option **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Module Greple pour traduire et remplacer uniquement les parties nécessaires avec l'API DeepL (en japonais)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Génération de documents dans 15 langues avec le module DeepL API (en japonais)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Environnement Docker de traduction automatique avec l'API DeepL (en japonais)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
