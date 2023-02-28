# NAME

App::Greple::tee - module om gematchte tekst te vervangen door het externe opdrachtresultaat

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple's **-Mtee** module stuurt gematchte tekstdelen naar het gegeven filtercommando, en vervangt ze door het resultaat van het commando. Het idee is afgeleid van het commando **teip**. Het is als het omzeilen van gedeeltelijke gegevens naar het externe filtercommando.

Het filtercommando volgt op de moduleverklaring (`-Mtee`) en eindigt met twee streepjes (`--`). Bijvoorbeeld, het volgende commando roept commando `tr` op met `a-z A-Z` argumenten voor het gezochte woord in de gegevens.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Bovenstaand commando zet alle overeenkomende woorden om van kleine letters naar hoofdletters. Eigenlijk is dit voorbeeld zelf niet zo nuttig omdat **greple** hetzelfde effectiever kan doen met de optie **--cm**.

Standaard wordt het commando uitgevoerd als een enkel proces, en alle gematchte gegevens worden erdoor gemengd. Als de gematchte tekst niet eindigt met een newline, wordt hij ervoor toegevoegd en erna verwijderd. De gegevens worden regel voor regel in kaart gebracht, dus het aantal regels invoer- en uitvoergegevens moet identiek zijn.

Met de optie **--discreet** wordt voor elk gematcht onderdeel een afzonderlijk commando opgeroepen. U kunt het verschil zien aan de hand van de volgende commando's.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Bij gebruik van de optie **--discreet** hoeven de regels invoer- en uitvoergegevens niet identiek te zijn.

# OPTIONS

- **--discrete**

    Roep nieuw commando individueel op voor elk onderdeel.

# WHY DO NOT USE TEIP

Allereerst, wanneer u het kunt doen met het commando **-teip**, gebruik het. Het is een uitstekend hulpmiddel en veel sneller dan **greple**.

Omdat **greple** is ontworpen om documentbestanden te verwerken, heeft het veel functies die daarvoor geschikt zijn, zoals controles van het matchgebied. Het kan de moeite waard zijn om **greple** te gebruiken om van die functies te profiteren.

Ook kan **teip** niet omgaan met meerdere regels gegevens als een enkele eenheid, terwijl **greple** individuele opdrachten kan uitvoeren op een gegevensbrok die uit meerdere regels bestaat.

# EXAMPLE

Het volgende commando vindt tekstblokken in [perlpod(1)](http://man.he.net/man1/perlpod) stijldocument opgenomen in het Perl-modulebestand.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

U kunt ze vertalen door DeepL service door het bovenstaande commando uit te voeren in combinatie met **-Mtee** module die het commando **deepl** als volgt oproept:

    greple -Mtee deepl text --to JA - -- --discrete ...

Omdat **deepl** beter werkt voor invoer op één regel, kunt u het commandogedeelte als volgt wijzigen:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

De speciale module [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) is echter effectiever voor dit doel. In feite kwam de implementatiehint van de module **tee** van de module **xlate**.

# EXAMPLE 2

Het volgende commando vindt een ingesprongen deel in het LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

U kunt dit deel opnieuw formatteren door de module **tee** te gebruiken met het commando **ansifold**:

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
