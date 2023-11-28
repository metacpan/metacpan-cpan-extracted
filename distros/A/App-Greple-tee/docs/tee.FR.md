# NAME

App::Greple::tee - module permettant de remplacer le texte correspondant par le résultat de la commande externe

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Le module **-Mtee** de Greple envoie les parties de texte correspondantes à la commande de filtrage donnée, et les remplace par le résultat de la commande. L'idée est dérivée de la commande appelée **teip**. C'est comme si on contournait des données partielles vers la commande de filtrage externe.

La commande de filtrage suit la déclaration du module (`-Mtee`) et se termine par deux tirets (`--`). Par exemple, la commande suivante appelle la commande `tr` avec les arguments `a-z A-Z` pour le mot correspondant dans les données.

    greple -Mtee tr a-z A-Z -- '\w+' ...

La commande ci-dessus convertit tous les mots correspondants des minuscules aux majuscules. En fait, cet exemple n'est pas très utile car **greple** peut faire la même chose plus efficacement avec l'option **--cm**.

Par défaut, la commande est exécutée comme un seul processus, et toutes les données correspondantes lui sont envoyées mélangées. Si le texte correspondant ne se termine pas par une nouvelle ligne, il est ajouté avant et supprimé après. Les données sont mappées ligne par ligne, le nombre de lignes de données d'entrée et de sortie doit donc être identique.

En utilisant l'option **--discrete**, une commande individuelle est appelée pour chaque pièce appariée. Vous pouvez faire la différence avec les commandes suivantes.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Il n'est pas nécessaire que les lignes de données d'entrée et de sortie soient identiques lorsque l'option **--discrete** est utilisée.

# VERSION

Version 0.9902

# OPTIONS

- **--discrete**

    Lancez une nouvelle commande individuellement pour chaque pièce correspondante.

- **--fillup**

    Combine une séquence de lignes non vides en une seule ligne avant de les transmettre à la commande de filtrage. Les caractères de nouvelle ligne entre les caractères larges sont supprimés et les autres caractères de nouvelle ligne sont remplacés par des espaces.

- **--blocks**

    Normalement, la zone correspondant au modèle de recherche spécifié est envoyée à la commande externe. Si cette option est spécifiée, ce n'est pas la zone correspondant au motif de recherche qui sera traitée, mais l'ensemble du bloc qui la contient.

    Par exemple, pour envoyer à la commande externe des lignes contenant le motif `foo`, vous devez spécifier le motif correspondant à la ligne entière :

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Mais avec l'option **--blocks**, cela peut être fait aussi simplement que suit :

        greple -Mtee cat -n -- foo --blocks

    Avec l'option **--blocs**, ce module se comporte plus comme l'option **-g** de [teip(1)](http://man.he.net/man1/teip). Sinon, le comportement est similaire à celui de [teip(1)](http://man.he.net/man1/teip) avec l'option **-o**.

    N'utilisez pas l'option **--blocks** avec l'option **--all**, car le bloc sera la totalité des données.

- **--squeeze**

    Combine deux ou plusieurs caractères de retour à la ligne consécutifs en un seul.

# WHY DO NOT USE TEIP

Tout d'abord, chaque fois que vous pouvez le faire avec la commande **teip**, utilisez-la. C'est un excellent outil et beaucoup plus rapide que **greple**.

Comme **greple** est conçu pour traiter des fichiers de documents, il possède de nombreuses fonctionnalités qui lui sont appropriées, comme les contrôles de la zone de correspondance. Il peut être intéressant d'utiliser **greple** pour profiter de ces fonctionnalités.

Par ailleurs, **teip** ne peut pas traiter plusieurs lignes de données comme une seule unité, alors que **greple** peut exécuter des commandes individuelles sur un fragment de données composé de plusieurs lignes.

# EXAMPLE

La commande suivante trouvera des blocs de texte dans le document de style [perlpod(1)](http://man.he.net/man1/perlpod) inclus dans le fichier du module Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Vous pouvez les traduire par le service DeepL en exécutant la commande ci-dessus combinée avec le module **-Mtee** qui appelle la commande **deepl** comme ceci :

    greple -Mtee deepl text --to JA - -- --fillup ...

Le module dédié [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) est plus efficace dans ce but, cependant. En fait, l'indice d'implémentation du module **tee** vient du module **xlate**.

# EXAMPLE 2

La prochaine commande trouvera une partie indentée dans le document LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Vous pouvez reformater cette partie en utilisant le module **tee** avec la commande **ansifold** :

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

L'utilisation de l'option `--discrete` prend du temps. Vous pouvez donc utiliser l'option `--separate '\r'` avec `ansifold` qui produit une seule ligne en utilisant le caractère CR au lieu de NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Ensuite, convertissez le caractère CR en NL à l'aide de la commande [tr(1)](http://man.he.net/man1/tr) ou d'une autre commande.

    ... | tr '\r' '\n'

# EXAMPLE 3

Considérons une situation dans laquelle vous souhaitez rechercher des chaînes de caractères dans des lignes autres que les lignes d'en-tête. Par exemple, vous pouvez rechercher des images à partir de la commande `docker image ls`, mais en laissant la ligne d'en-tête. Vous pouvez le faire en utilisant la commande suivante.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

L'option `-Mline -L 2:` récupère l'avant-dernière ligne et l'envoie à la commande `grep perl`. L'option `--discrete` est nécessaire, mais elle n'est appelée qu'une seule fois, de sorte qu'il n'y a pas d'inconvénient en termes de performances.

Dans ce cas, `teip -l 2- -- grep` produit une erreur car le nombre de lignes en sortie est inférieur au nombre de lignes en entrée. Cependant, le résultat est tout à fait satisfaisant :)

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# BUGS

L'option `--fillup` peut ne pas fonctionner correctement pour le texte coréen.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
