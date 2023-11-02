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

# VERSION

Version 0.9901

# OPTIONS

- **--discrete**

    Roep nieuw commando individueel op voor elk onderdeel.

- **--fillup**

    Combineer een reeks niet lege regels tot één regel voordat je ze doorgeeft aan de filteropdracht. Newline-tekens tussen brede tekens worden verwijderd en andere newline-tekens worden vervangen door spaties.

- **--blockmatch**

    Normaal gesproken wordt het gebied dat overeenkomt met het opgegeven zoekpatroon naar de externe opdracht gestuurd. Als deze optie is opgegeven, wordt niet het gebied dat overeenkomt, maar het hele blok dat het bevat, verwerkt.

    Om bijvoorbeeld regels met het patroon `foo` naar de externe opdracht te sturen, moet je het patroon opgeven dat overeenkomt met de hele regel:

        greple -Mtee cat -n -- '^.*foo.*\n'

    Maar met de optie **--blockmatch** kan het als volgt eenvoudig:

        greple -Mtee cat -n -- foo

    Met de **--blockmatch** optie gedraagt deze module zich meer als de **-g** optie van [teip(1)](http://man.he.net/man1/teip).

# WHY DO NOT USE TEIP

Allereerst, wanneer u het kunt doen met het commando **-teip**, gebruik het. Het is een uitstekend hulpmiddel en veel sneller dan **greple**.

Omdat **greple** is ontworpen om documentbestanden te verwerken, heeft het veel functies die daarvoor geschikt zijn, zoals controles van het matchgebied. Het kan de moeite waard zijn om **greple** te gebruiken om van die functies te profiteren.

Ook kan **teip** niet omgaan met meerdere regels gegevens als een enkele eenheid, terwijl **greple** individuele opdrachten kan uitvoeren op een gegevensbrok die uit meerdere regels bestaat.

# EXAMPLE

Het volgende commando vindt tekstblokken in [perlpod(1)](http://man.he.net/man1/perlpod) stijldocument opgenomen in het Perl-modulebestand.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

U kunt ze vertalen door DeepL service door het bovenstaande commando uit te voeren in combinatie met **-Mtee** module die het commando **deepl** als volgt oproept:

    greple -Mtee deepl text --to JA - -- --fillup ...

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

Het gebruik van de optie `--discrete` is tijdrovend. Dus je kunt de optie `--separate '\r'` gebruiken met `ansifold` die een enkele regel produceert met CR-karakters in plaats van NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Converteer vervolgens CR naar NL met [tr(1)](http://man.he.net/man1/tr) of iets dergelijks.

    ... | tr '\r' '\n'

# EXAMPLE 3

Overweeg een situatie waarin je wilt grepen naar tekenreeksen buiten de koptekstregels. Bijvoorbeeld, je wilt zoeken naar afbeeldingen van het `docker image ls` commando, maar laat de header regel staan. Je kunt dit doen met het volgende commando.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Optie `-Mline -L 2:` haalt de voorlaatste regels op en stuurt ze naar het commando `grep perl`. Optie `--discrete` is vereist, maar deze wordt maar één keer aangeroepen, dus er is geen prestatieverlies.

In dit geval geeft `teip -l 2- -- grep` een foutmelding omdat het aantal regels in de uitvoer minder is dan de invoer. Het resultaat is echter heel bevredigend :)

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

De optie `-fillup` werkt mogelijk niet correct voor Koreaanse tekst.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
