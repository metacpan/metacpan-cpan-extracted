# NAME

App::Greple::xlate - module de support de traduction pour greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9915

# DESCRIPTION

**Greple** **xlate** le module trouve les blocs de texte souhaités et les remplace par le texte traduit. Actuellement, les modules DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) et GPT-5 (`gpt5.pm`) sont implémentés comme moteurs de traitement en arrière-plan.

Si vous souhaitez traduire des blocs de texte normaux dans un document rédigé dans le style pod de Perl, utilisez la commande **greple** avec les modules `xlate::deepl` et `perl` comme ceci :

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dans cette commande, la chaîne de motif `^([\w\pP].*\n)+` signifie des lignes consécutives commençant par une lettre alphanumérique ou de ponctuation. Cette commande affiche la zone à traduire en surbrillance. L'option **--all** est utilisée pour produire le texte entier.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ajoutez ensuite l'option `--xlate` pour traduire la zone sélectionnée. Elle trouvera alors les sections souhaitées et les remplacera par la sortie de la commande **deepl**.

Par défaut, le texte original et le texte traduit sont imprimés dans le format "marqueur de conflit" compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez obtenir la partie souhaitée facilement avec la commande [unifdef(1)](http://man.he.net/man1/unifdef). Le format de sortie peut être spécifié avec l'option **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous souhaitez traduire l'intégralité du texte, utilisez l'option **--match-all**. Il s'agit d'un raccourci pour spécifier le motif `(?s).+` qui correspond à l'ensemble du texte.

Les données au format de marqueur de conflit peuvent être affichées en mode côte à côte avec la commande [sdif](https://metacpan.org/pod/App%3A%3Asdif) et l'option `-V`. Comme il n'est pas pertinent de comparer ligne par ligne, l'option `--no-cdif` est recommandée. Si vous n'avez pas besoin de colorer le texte, indiquez `--no-textcolor` (ou `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Le traitement est effectué par unités spécifiées, mais dans le cas d'une séquence de plusieurs lignes de texte non vide, elles sont converties ensemble en une seule ligne. Cette opération est réalisée comme suit :

- Supprimez les espaces au début et à la fin de chaque ligne.
- Si une ligne se termine par un caractère de ponctuation pleine largeur, concaténez-la avec la ligne suivante.
- Si une ligne se termine par un caractère pleine largeur et que la ligne suivante commence par un caractère pleine largeur, concaténez les lignes.
- Si la fin ou le début d'une ligne n'est pas un caractère pleine largeur, concaténez-les en insérant un espace.

Les données du cache sont gérées en fonction du texte normalisé, donc même si des modifications sont apportées qui n'affectent pas les résultats de la normalisation, les données de traduction mises en cache resteront valides.

Ce processus de normalisation n'est effectué que pour le premier (0ème) et les motifs de numéro pair. Ainsi, si deux motifs sont spécifiés comme suit, le texte correspondant au premier motif sera traité après normalisation, et aucun processus de normalisation ne sera effectué sur le texte correspondant au second motif.

    greple -Mxlate -E normalized -E not-normalized

Par conséquent, utilisez le premier motif pour le texte devant être traité en combinant plusieurs lignes en une seule, et utilisez le second motif pour le texte préformaté. S'il n'y a pas de texte correspondant au premier motif, utilisez un motif qui ne correspond à rien, comme `(?!)`.

# MASKING

Parfois, il y a des parties du texte que vous ne souhaitez pas traduire. Par exemple, les balises dans les fichiers markdown. DeepL suggère que dans de tels cas, la partie du texte à exclure soit convertie en balises XML, traduite, puis restaurée après la traduction. Pour cela, il est possible de spécifier les parties à masquer de la traduction.

    --xlate-setopt maskfile=MASKPATTERN

Cela interprétera chaque ligne du fichier \`MASKPATTERN\` comme une expression régulière, traduira les chaînes correspondantes, puis les rétablira après le traitement. Les lignes commençant par `#` sont ignorées.

Un motif complexe peut être écrit sur plusieurs lignes avec un saut de ligne échappé par une barre oblique inverse.

La façon dont le texte est transformé par le masquage peut être vue grâce à l'option **--xlate-mask**.

Cette interface est expérimentale et susceptible d'être modifiée à l'avenir.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Lancez le processus de traduction pour chaque zone correspondante.

    Sans cette option, **greple** se comporte comme une commande de recherche normale. Vous pouvez donc vérifier quelle partie du fichier sera soumise à la traduction avant de lancer le travail réel.

    Le résultat de la commande est envoyé sur la sortie standard, donc redirigez vers un fichier si nécessaire, ou envisagez d'utiliser le module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    L'option **--xlate** appelle l'option **--xlate-color** avec l'option **--color=never**.

    Avec l'option **--xlate-fold**, le texte converti est replié selon la largeur spécifiée. La largeur par défaut est de 70 et peut être définie par l'option **--xlate-fold-width**. Quatre colonnes sont réservées pour l'opération en cours, donc chaque ligne peut contenir au maximum 74 caractères.

- **--xlate-engine**=_engine_

    Spécifie le moteur de traduction à utiliser. Si vous spécifiez directement le module du moteur, comme `-Mxlate::deepl`, vous n'avez pas besoin d'utiliser cette option.

    À ce jour, les moteurs suivants sont disponibles

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        L'interface de **gpt-4o** est instable et son bon fonctionnement ne peut être garanti pour le moment.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Au lieu d'appeler le moteur de traduction, il vous est demandé d'intervenir. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous devez le coller dans le formulaire, copier le résultat dans le presse-papiers, puis appuyer sur Entrée.

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles avec la commande `deepl languages` lors de l'utilisation du moteur **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et le texte traduit.

    Les formats suivants autres que `xtxt` supposent que la partie à traduire est un ensemble de lignes. En réalité, il est possible de ne traduire qu'une partie d'une ligne, mais spécifier un format autre que `xtxt` ne produira pas de résultats significatifs.

    - **conflict**, **cm**

        Le texte original et le texte converti sont imprimés au format marqueur de conflit [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original avec la commande suivante [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Le texte original et le texte traduit sont affichés dans un style de conteneur personnalisé markdown.

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

        Le nombre de deux-points est de 7 par défaut. Si vous spécifiez une séquence de deux-points comme `:::::`, elle sera utilisée à la place des 7 deux-points.

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

        Le texte original et le texte converti sont imprimés séparés par une seule ligne vide.

    - **xtxt**

        Pour `space+`, il affiche également une nouvelle ligne après le texte converti.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est affiché.

- **--xlate-maxline**=_n_ (Default: 0)

    Spécifiez la longueur maximale du texte à envoyer à l'API en une seule fois. La valeur par défaut est définie comme pour le service de compte gratuit DeepL : 128K pour l'API (**--xlate**) et 5000 pour l'interface presse-papiers (**--xlate-labor**). Vous pouvez éventuellement modifier ces valeurs si vous utilisez le service Pro.

    Spécifiez le nombre maximal de lignes de texte à envoyer à l'API en une seule fois.

- **--xlate-prompt**=_text_

    Spécifiez une invite personnalisée à envoyer au moteur de traduction. Cette option n'est disponible que lors de l'utilisation des moteurs ChatGPT (gpt3, gpt4, gpt4o). Vous pouvez personnaliser le comportement de la traduction en fournissant des instructions spécifiques au modèle d'IA. Si l'invite contient `%s`, elle sera remplacée par le nom de la langue cible.

- **--xlate-context**=_text_

    Spécifiez des informations de contexte supplémentaires à envoyer au moteur de traduction. Cette option peut être utilisée plusieurs fois pour fournir plusieurs chaînes de contexte. Les informations de contexte aident le moteur de traduction à comprendre l'arrière-plan et à produire des traductions plus précises.

- **--xlate-glossary**=_glossary_

    Spécifiez un identifiant de glossaire à utiliser pour la traduction. Cette option n'est disponible que lors de l'utilisation du moteur DeepL. L'identifiant de glossaire doit être obtenu à partir de votre compte DeepL et garantit une traduction cohérente de termes spécifiques.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Définissez cette valeur à 1 si vous souhaitez traduire une ligne à la fois. Cette option a la priorité sur l'option `--xlate-maxlen`.

- **--xlate-stripe**

    Voyez le résultat de la traduction en temps réel dans la sortie STDERR.

    Utilisez le module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pour afficher la partie correspondante en mode zébré. Ceci est utile lorsque les parties correspondantes sont reliées bout à bout.

- **--xlate-mask**

    La palette de couleurs est adaptée en fonction de la couleur de fond du terminal. Si vous souhaitez la spécifier explicitement, vous pouvez utiliser **--xlate-stripe-light** ou **--xlate-stripe-dark**.

- **--match-all**

    Effectuez la fonction de masquage et affichez le texte converti tel quel sans restauration.

- **--lineify-cm**
- **--lineify-colon**

    Dans le cas des formats `cm` et `colon`, la sortie est divisée et formatée ligne par ligne. Par conséquent, si seule une partie d'une ligne doit être traduite, le résultat attendu ne peut pas être obtenu. Ces filtres corrigent la sortie qui est corrompue en traduisant une partie d'une ligne en une sortie normale ligne par ligne.

    Dans l'implémentation actuelle, si plusieurs parties d'une ligne sont traduites, elles sont produites comme des lignes indépendantes.

# CACHE OPTIONS

Définissez l'ensemble du texte du fichier comme zone cible.

Le module **xlate** peut stocker le texte traduit en cache pour chaque fichier et le lire avant exécution afin d'éliminer la surcharge de requête au serveur. Avec la stratégie de cache par défaut `auto`, il maintient les données en cache uniquement lorsque le fichier de cache existe pour le fichier cible.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Utilisez **--xlate-cache=clear** pour initier la gestion du cache ou pour nettoyer toutes les données de cache existantes. Une fois exécuté avec cette option, un nouveau fichier de cache sera créé s'il n'en existe pas et sera ensuite maintenu automatiquement.

    - `create`

        Maintenez le fichier de cache s'il existe.

    - `always`, `yes`, `1`

        Créez un fichier de cache vide et quittez.

    - `clear`

        Maintenez le cache de toute façon tant que la cible est un fichier normal.

    - `never`, `no`, `0`

        Effacez d'abord les données du cache.

    - `accumulate`

        N'utilisez jamais de fichier de cache même s'il existe.
- **--xlate-update**

    Par défaut, les données inutilisées sont supprimées du fichier de cache. Si vous ne souhaitez pas les supprimer et les conserver dans le fichier, utilisez `accumulate`.

# COMMAND LINE INTERFACE

Cette option force la mise à jour du fichier de cache même si ce n'est pas nécessaire.

Vous pouvez facilement utiliser ce module depuis la ligne de commande en utilisant la commande `xlate` incluse dans la distribution. Consultez la page de manuel `xlate` pour l'utilisation.

La commande `xlate` fonctionne en concert avec l'environnement Docker, donc même si vous n'avez rien installé localement, vous pouvez l'utiliser tant que Docker est disponible. Utilisez l'option `-D` ou `-C`.

De plus, comme des makefiles pour différents styles de documents sont fournis, la traduction dans d'autres langues est possible sans spécification particulière. Utilisez l'option `-M`.

Vous pouvez également combiner les options Docker et `make` afin de pouvoir exécuter `make` dans un environnement Docker.

Lancer comme `xlate -C` ouvrira un shell avec le dépôt git de travail actuel monté.

# EMACS

Chargez le fichier `xlate.el` inclus dans le dépôt pour utiliser la commande `xlate` depuis l'éditeur Emacs. La fonction `xlate-region` traduit la région donnée. La langue par défaut est `EN-US` et vous pouvez spécifier la langue en l'invoquant avec un argument préfixe.

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

Vous devez installer les outils en ligne de commande pour DeepL et ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Image de conteneur Docker.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Bibliothèque Python DeepL et commande CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliothèque Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interface en ligne de commande OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultez le manuel **greple** pour plus de détails sur le modèle de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier les fichiers selon le résultat de la commande **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format du marqueur de conflit côte à côte avec l'option **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Le module Greple **stripe** s'utilise avec l'option **--xlate-stripe**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Module Greple pour traduire et remplacer uniquement les parties nécessaires avec l'API DeepL (en japonais)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Génération de documents en 15 langues avec le module API DeepL (en japonais)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Environnement Docker de traduction automatique avec l'API DeepL (en japonais)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
