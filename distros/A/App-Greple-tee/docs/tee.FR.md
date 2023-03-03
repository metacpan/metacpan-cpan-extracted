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

# OPTIONS

- **--discrete**

    Lancez une nouvelle commande individuellement pour chaque pièce correspondante.

# WHY DO NOT USE TEIP

Tout d'abord, chaque fois que vous pouvez le faire avec la commande **teip**, utilisez-la. C'est un excellent outil et beaucoup plus rapide que **greple**.

Comme **greple** est conçu pour traiter des fichiers de documents, il possède de nombreuses fonctionnalités qui lui sont appropriées, comme les contrôles de la zone de correspondance. Il peut être intéressant d'utiliser **greple** pour profiter de ces fonctionnalités.

Par ailleurs, **teip** ne peut pas traiter plusieurs lignes de données comme une seule unité, alors que **greple** peut exécuter des commandes individuelles sur un fragment de données composé de plusieurs lignes.

# EXAMPLE

La commande suivante trouvera des blocs de texte dans le document de style [perlpod(1)](http://man.he.net/man1/perlpod) inclus dans le fichier du module Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Vous pouvez les traduire par le service DeepL en exécutant la commande ci-dessus combinée avec le module **-Mtee** qui appelle la commande **deepl** comme ceci :

    greple -Mtee deepl text --to JA - -- --discrete ...

Comme **deepl** fonctionne mieux pour la saisie sur une seule ligne, vous pouvez modifier la partie de la commande comme ceci :

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

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
    

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
