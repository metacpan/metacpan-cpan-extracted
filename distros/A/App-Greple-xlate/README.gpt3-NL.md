# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

**Greple** **xlate** module vindt tekstblokken en vervangt ze door de vertaalde tekst. Momenteel zijn de DeepL (`deepl.pm`) en ChatGPT (`gpt3.pm`) modules geïmplementeerd als een back-end engine.

Als je normale tekstblokken wilt vertalen die zijn geschreven in de [pod](https://metacpan.org/pod/pod) stijl, gebruik dan het **greple** commando met de `xlate::deepl` en `perl` module als volgt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Patroon `^(\w.*\n)+` betekent opeenvolgende regels die beginnen met een alfanumeriek teken. Dit commando toont het gebied dat vertaald moet worden. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg vervolgens de optie `--xlate` toe om het geselecteerde gebied te vertalen. Het zal ze vinden en vervangen door de uitvoer van het **deepl** commando.

Standaard worden het oorspronkelijke en vertaalde tekst afgedrukt in het formaat van de "conflict marker" dat compatibel is met [git(1)](http://man.he.net/man1/git). Met behulp van het `ifdef` formaat kun je het gewenste deel krijgen met het [unifdef(1)](http://man.he.net/man1/unifdef) commando. De uitvoerindeling kan worden gespecificeerd met de **--xlate-format** optie.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de hele tekst wilt vertalen, gebruik dan de **--match-all** optie. Dit is een snelkoppeling om het patroon `(?s).+` te specificeren dat de hele tekst matcht.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Roep het vertaalproces aan voor elk overeenkomend gebied.

    Zonder deze optie gedraagt **greple** zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand onderwerp zal zijn van de vertaling voordat u daadwerkelijk aan het werk gaat.

    Het resultaat van het commando wordt naar standaarduitvoer gestuurd, dus leid het om naar een bestand indien nodig, of overweeg het gebruik van de [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module.

    Optie **--xlate** roept de optie **--xlate-color** aan met de optie **--color=never**.

    Met de optie **--xlate-fold** wordt de geconverteerde tekst gevouwen volgens de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie **--xlate-fold-width**. Vier kolommen zijn gereserveerd voor de run-in bewerking, zodat elke regel maximaal 74 tekens kan bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalmotor. Als je de engine module direct specificeert, zoals `-Mxlate::deepl`, hoef je deze optie niet te gebruiken.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmotor te bellen, wordt van u verwacht dat u werkt. Nadat u de tekst hebt voorbereid om te vertalen, wordt deze gekopieerd naar het klembord. U wordt verwacht deze tekst in het formulier te plakken, het resultaat naar het klembord te kopiëren en op Enter te drukken.

- **--xlate-to** (Default: `EN-US`)

    Specificeer de doeltaal. U kunt de beschikbare talen krijgen met het `deepl languages` commando wanneer u de **DeepL** motor gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor de oorspronkelijke en vertaalde tekst.

    - **conflict**, **cm**

        Druk de oorspronkelijke en vertaalde tekst af in het formaat van het [git(1)](http://man.he.net/man1/git) conflict marker.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        U kunt het oorspronkelijke bestand herstellen met het volgende [sed(1)](http://man.he.net/man1/sed) commando.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Druk de oorspronkelijke en vertaalde tekst af in het [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        U kunt alleen de Japanse tekst ophalen met het **unifdef** commando:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Druk de oorspronkelijke en vertaalde tekst af gescheiden door een enkele lege regel.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen de vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Vertaal de volgende tekst naar het Nederlands, regel voor regel.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Bekijk het vertaalresultaat in realtime in de STDERR-uitvoer.

- **--match-all**

    Stel de volledige tekst van het bestand in als een doelgebied.

# CACHE OPTIONS

De **xlate** module kan gecachte tekst van vertaling voor elk bestand opslaan en deze lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache-strategie `auto` wordt de cache alleen behouden wanneer het cachebestand bestaat voor het doelbestand.

- --cache-clear

    De optie **--cache-clear** kan worden gebruikt om het cachebeheer te starten of om alle bestaande cachegegevens te vernieuwen. Zodra deze optie is uitgevoerd, wordt er een nieuw cachebestand gemaakt als dit nog niet bestaat en vervolgens automatisch onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cachebestand aan en stop.

    - `always`, `yes`, `1`

        Onderhoud de cache hoe dan ook zolang het doel een normaal bestand is.

    - `clear`

        Wis eerst de cachegegevens.

    - `never`, `no`, `0`

        Gebruik nooit het cachebestand, zelfs als het bestaat.

    - `accumulate`

        Standaardgedrag is dat ongebruikte gegevens uit het cachebestand worden verwijderd. Als u ze niet wilt verwijderen en in het bestand wilt bewaren, gebruik dan `accumulate`.

# COMMAND LINE INTERFACE

Je kunt deze module gemakkelijk gebruiken vanaf de commandoregel door het `xlate` commando te gebruiken dat is opgenomen in de repository. Zie de `xlate` helpinformatie voor het gebruik.

# EMACS

Laad het bestand `xlate.el` dat is opgenomen in de repository om het `xlate` commando te gebruiken vanuit de Emacs-editor. De functie `xlate-region` vertaalt het opgegeven gedeelte. De standaardtaal is `EN-US` en je kunt de taal specificeren door het aan te roepen met een voorvoegselargument.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel je authenticatiesleutel in voor de DeepL-service.

- OPENAI\_API\_KEY

    OpenAI authenticatiesleutel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Je moet command line tools installeren voor DeepL en ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-bibliotheek en CLI-commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI command line interface

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de handleiding van **greple** voor meer informatie over het doelpatroon van de tekst. Gebruik de opties **--inside**, **--outside**, **--include**, **--exclude** om het overeenkomende gebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Je kunt de module `-Mupdate` gebruiken om bestanden te wijzigen op basis van het resultaat van het **greple** commando.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het conflictmarkeringsformaat zij aan zij weer te geven met de optie **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
