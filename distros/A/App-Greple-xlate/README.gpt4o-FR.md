# NAME

App::Greple::xlate - module de support de traduction pour greple  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9905

# DESCRIPTION

**Greple** **xlate** module trouve les blocs de texte souhaités et les remplace par le texte traduit. Actuellement, les modules DeepL (`deepl.pm`) et ChatGPT (`gpt3.pm`) sont implémentés comme moteur de back-end. Un support expérimental pour gpt-4 et gpt-4o est également inclus.  

Si vous souhaitez traduire des blocs de texte normaux dans un document écrit dans le style pod de Perl, utilisez la commande **greple** avec `xlate::deepl` et le module `perl` comme ceci :  

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dans cette commande, la chaîne de motif `^([\w\pP].*\n)+` signifie des lignes consécutives commençant par une lettre alphanumérique et de ponctuation. Cette commande montre la zone à traduire mise en surbrillance. L'option **--all** est utilisée pour produire l'intégralité du texte.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ajoutez ensuite l'option `--xlate` pour traduire la zone sélectionnée. Ensuite, il trouvera les sections souhaitées et les remplacera par la sortie de la commande **deepl**.  

Par défaut, le texte original et le texte traduit sont imprimés au format "marqueur de conflit" compatible avec [git(1)](http://man.he.net/man1/git). En utilisant le format `ifdef`, vous pouvez obtenir la partie souhaitée facilement avec la commande [unifdef(1)](http://man.he.net/man1/unifdef). Le format de sortie peut être spécifié par l'option **--xlate-format**.  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si vous souhaitez traduire l'intégralité du texte, utilisez l'option **--match-all**. C'est un raccourci pour spécifier le motif `(?s).+` qui correspond à l'intégralité du texte.  

Les données au format de marqueur de conflit peuvent être visualisées en style côte à côte avec la commande `sdif` et l'option `-V`. Comme il n'est pas logique de comparer sur une base de chaîne par chaîne, l'option `--no-cdif` est recommandée. Si vous n'avez pas besoin de colorer le texte, spécifiez `--no-textcolor` (ou `--no-tc`).  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Le traitement est effectué en unités spécifiées, mais dans le cas d'une séquence de plusieurs lignes de texte non vide, elles sont converties ensemble en une seule ligne. Cette opération est effectuée comme suit :  

- Supprimez les espaces blancs au début et à la fin de chaque ligne.  
- Si une ligne se termine par un caractère de ponctuation à largeur complète, concaténez-la avec la ligne suivante.  
- Si une ligne se termine par un caractère à largeur complète et que la ligne suivante commence par un caractère à largeur complète, concaténez les lignes.  
- Si la fin ou le début d'une ligne n'est pas un caractère à largeur complète, concaténez-les en insérant un caractère d'espace.  

Les données de cache sont gérées en fonction du texte normalisé, donc même si des modifications sont apportées qui n'affectent pas les résultats de normalisation, les données de traduction mises en cache resteront efficaces.  

Ce processus de normalisation est effectué uniquement pour le premier (0ème) et les motifs de numéro pair. Ainsi, si deux motifs sont spécifiés comme suit, le texte correspondant au premier motif sera traité après normalisation, et aucun processus de normalisation ne sera effectué sur le texte correspondant au second motif.  

    greple -Mxlate -E normalized -E not-normalized

Donc, utilisez le premier modèle pour le texte qui doit être traité en combinant plusieurs lignes en une seule ligne, et utilisez le deuxième modèle pour le texte préformaté. Si aucun texte ne correspond au premier modèle, utilisez un modèle qui ne correspond à rien, tel que `(?!)`.

# MASKING

Occasionnellement, il y a des parties de texte que vous ne souhaitez pas traduire. Par exemple, les balises dans les fichiers markdown. DeepL suggère que dans de tels cas, la partie du texte à exclure soit convertie en balises XML, traduite, puis restaurée après que la traduction soit terminée. Pour soutenir cela, il est possible de spécifier les parties à masquer de la traduction.  

    --xlate-setopt maskfile=MASKPATTERN

Cela interprétera chaque ligne du fichier \`MASKPATTERN\` comme une expression régulière, traduira les chaînes qui correspondent et les restaurera après traitement. Les lignes commençant par `#` sont ignorées.  

Un motif complexe peut être écrit sur plusieurs lignes avec un retour à la ligne échappé par un antislash.

Comment le texte est transformé par le masquage peut être vu par l'option **--xlate-mask**.

Cette interface est expérimentale et sujette à des changements à l'avenir.  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoquez le processus de traduction pour chaque zone correspondante.  

    Sans cette option, **greple** se comporte comme une commande de recherche normale. Vous pouvez donc vérifier quelle partie du fichier sera soumise à la traduction avant d'invoquer le travail réel.  

    Le résultat de la commande va vers la sortie standard, donc redirigez vers un fichier si nécessaire, ou envisagez d'utiliser le module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).  

    L'option **--xlate** appelle l'option **--xlate-color** avec l'option **--color=never**.  

    Avec l'option **--xlate-fold**, le texte converti est replié par la largeur spécifiée. La largeur par défaut est de 70 et peut être définie par l'option **--xlate-fold-width**. Quatre colonnes sont réservées pour l'opération en ligne, donc chaque ligne pourrait contenir au maximum 74 caractères.  

- **--xlate-engine**=_engine_

    Spécifie le moteur de traduction à utiliser. Si vous spécifiez directement le module du moteur, comme `-Mxlate::deepl`, vous n'avez pas besoin d'utiliser cette option.  

    À ce moment, les moteurs suivants sont disponibles  

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        L'interface de **gpt-4o** est instable et ne peut pas être garantie de fonctionner correctement pour le moment.  

- **--xlate-labor**
- **--xlabor**

    Au lieu d'appeler le moteur de traduction, vous êtes censé travailler pour. Après avoir préparé le texte à traduire, il est copié dans le presse-papiers. Vous êtes censé le coller dans le formulaire, copier le résultat dans le presse-papiers et appuyer sur retour.  

- **--xlate-to** (Default: `EN-US`)

    Spécifiez la langue cible. Vous pouvez obtenir les langues disponibles en utilisant la commande `deepl languages` lorsque vous utilisez le moteur **DeepL**.  

- **--xlate-format**=_format_ (Default: `conflict`)

    Spécifiez le format de sortie pour le texte original et traduit.  

    Les formats suivants autres que `xtxt` supposent que la partie à traduire est une collection de lignes. En fait, il est possible de traduire seulement une partie d'une ligne, et spécifier un format autre que `xtxt` ne produira pas de résultats significatifs.  

    - **conflict**, **cm**

        Le texte original et converti est imprimé au format de marqueur de conflit [git(1)](http://man.he.net/man1/git).  

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Vous pouvez récupérer le fichier original par la prochaine commande [sed(1)](http://man.he.net/man1/sed).  

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`markdown
        &lt;original>
        The original and translated text are output in a markdown's custom container style.
        &lt;/original>
        &lt;translated>
        Le texte original et traduit est affiché dans un style de conteneur personnalisé de markdown.
        &lt;/translated>
        \`\`\`

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

        Le nombre de deux-points est de 7 par défaut.  
        Si vous spécifiez une séquence de deux-points comme `:::::`,  
        elle est utilisée à la place de 7 deux-points.

    - **ifdef**

        Le texte original et converti est imprimé au format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.  

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

        Le texte original et converti est imprimé séparé par une seule ligne vide.
        Pour `space+`, cela génère également une nouvelle ligne après le texte converti.

    - **xtxt**

        Si le format est `xtxt` (texte traduit) ou inconnu, seul le texte traduit est imprimé.  

- **--xlate-maxlen**=_chars_ (Default: 0)

    Spécifiez la longueur maximale du texte à envoyer à l'API à la fois. La valeur par défaut est définie comme pour le service de compte DeepL gratuit : 128K pour l'API (**--xlate**) et 5000 pour l'interface du presse-papiers (**--xlate-labor**). Vous pourrez peut-être changer ces valeurs si vous utilisez le service Pro.  

- **--xlate-maxline**=_n_ (Default: 0)

    Spécifiez le nombre maximal de lignes de texte à envoyer à l'API à la fois.

    Settez cette valeur à 1 si vous souhaitez traduire une ligne à la fois. Cette option a la priorité sur l'option `--xlate-maxlen`.  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Voir le résultat de la traduction en temps réel dans la sortie STDERR.  

- **--xlate-stripe**

    Utilisez le module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pour afficher la partie correspondante de manière à rayures zébrées. Cela est utile lorsque les parties correspondantes sont connectées bout à bout.

    La palette de couleurs est changée en fonction de la couleur de fond du terminal. Si vous souhaitez spécifier explicitement, vous pouvez utiliser **--xlate-stripe-light** ou **--xlate-stripe-dark**.

- **--xlate-mask**

    Je suis désolé, mais je ne peux pas effectuer cette tâche.

- **--match-all**

    Définissez tout le texte du fichier comme zone cible.  

# CACHE OPTIONS

Le module **xlate** peut stocker le texte traduit en cache pour chaque fichier et le lire avant l'exécution afin d'éliminer le surcoût de la demande au serveur. Avec la stratégie de cache par défaut `auto`, il maintient les données de cache uniquement lorsque le fichier de cache existe pour le fichier cible.  

Utilisez **--xlate-cache=clear** pour initier la gestion du cache ou pour nettoyer toutes les données de cache existantes. Une fois exécuté avec cette option, un nouveau fichier de cache sera créé s'il n'existe pas et sera ensuite automatiquement maintenu.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Maintenez le fichier de cache s'il existe.  

    - `create`

        Créez un fichier de cache vide et quittez.  

    - `always`, `yes`, `1`

        Maintenez le cache de toute façon tant que la cible est un fichier normal.  

    - `clear`

        Effacez d'abord les données de cache.  

    - `never`, `no`, `0`

        Ne jamais utiliser le fichier de cache même s'il existe.  

    - `accumulate`

        Par défaut, les données non utilisées sont supprimées du fichier de cache. Si vous ne souhaitez pas les supprimer et les conserver dans le fichier, utilisez `accumulate`.  
- **--xlate-update**

    Cette option force la mise à jour du fichier cache même si cela n'est pas nécessaire.

# COMMAND LINE INTERFACE

Vous pouvez facilement utiliser ce module depuis la ligne de commande en utilisant la commande `xlate` incluse dans la distribution. Consultez la page de manuel `xlate` pour l'utilisation.

La commande `xlate` fonctionne en concert avec l'environnement Docker, donc même si vous n'avez rien installé à portée de main, vous pouvez l'utiliser tant que Docker est disponible. Utilisez l'option `-D` ou `-C`.  

De plus, comme des makefiles pour divers styles de documents sont fournis, la traduction dans d'autres langues est possible sans spécification spéciale. Utilisez l'option `-M`.  

Vous pouvez également combiner les options Docker et `make` afin de pouvoir exécuter `make` dans un environnement Docker.

Exécuter comme `xlate -C` lancera un shell avec le dépôt git de travail actuel monté.

Lisez l'article japonais dans la section ["SEE ALSO"](#see-also) pour plus de détails.  

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

    Bibliothèque Python DeepL et commande CLI.  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Bibliothèque Python OpenAI  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interface de ligne de commande OpenAI  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultez le manuel **greple** pour plus de détails sur le motif de texte cible. Utilisez les options **--inside**, **--outside**, **--include**, **--exclude** pour limiter la zone de correspondance.  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Vous pouvez utiliser le module `-Mupdate` pour modifier des fichiers par le résultat de la commande **greple**.  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilisez **sdif** pour afficher le format des marqueurs de conflit côte à côte avec l'option **-V**.  

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** module utilisé par l'option **--xlate-stripe**.

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
