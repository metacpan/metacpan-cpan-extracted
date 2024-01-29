# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.29

# DESCRIPTION

De module **Greple** **xlate** vindt de gewenste tekstblokken en vervangt ze door de vertaalde tekst. Momenteel zijn DeepL (`deepl.pm`) en ChatGPT (`gpt3.pm`) module geïmplementeerd als een back-end engine.

Als je normale tekstblokken wilt vertalen in een document dat geschreven is in de pod-stijl van Perl, gebruik dan het commando **greple** met de module `xlate::deepl` en `perl` als volgt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

In dit commando betekent pattern string `^(\w.*\n)+` opeenvolgende regels die beginnen met een alfa-numerieke letter. Deze opdracht toont het te vertalen gebied gemarkeerd. Optie **--all** wordt gebruikt om de hele tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg dan de optie `--xlate` toe om het geselecteerde gebied te vertalen. Vervolgens worden de gewenste secties gevonden en vervangen door de uitvoer van de opdracht **deepl**.

Standaard wordt originele en vertaalde tekst afgedrukt in het "conflict marker" formaat dat compatibel is met [git(1)](http://man.he.net/man1/git). Door `ifdef` formaat te gebruiken, kun je gemakkelijk het gewenste deel krijgen met [unifdef(1)](http://man.he.net/man1/unifdef) commando. Uitvoerformaat kan gespecificeerd worden met **--xlate-format** optie.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de hele tekst wilt vertalen, gebruik dan de optie **--match-all**. Dit is een snelkoppeling om het patroon `(?s).+` op te geven dat overeenkomt met de hele tekst.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Roep het vertaalproces op voor elk gematcht gebied.

    Zonder deze optie gedraagt **greple** zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand zal worden vertaald voordat u het eigenlijke werk uitvoert.

    Commandoresultaat gaat naar standaard out, dus redirect naar bestand indien nodig, of overweeg [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module te gebruiken.

    Optie **--xlate** roept **--xlate-kleur** aan met **--color=never** optie.

    Met de optie **--xlate-fold** wordt geconverteerde tekst gevouwen met de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie **--xlate-fold-width**. Vier kolommen zijn gereserveerd voor inloopoperaties, zodat elke regel maximaal 74 tekens kan bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalmachine. Als u de engine module rechtstreeks specificeert, zoals `-Mxlate::deepl`, hoeft u deze optie niet te gebruiken.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmachine op te roepen, wordt van u verwacht dat u voor werkt. Na het voorbereiden van te vertalen tekst, worden ze gekopieerd naar het klembord. Van u wordt verwacht dat u ze in het formulier plakt, het resultaat naar het klembord kopieert en op return drukt.

- **--xlate-to** (Default: `EN-US`)

    Geef de doeltaal op. U kunt de beschikbare talen krijgen met het commando `deepl languages` wanneer u de engine **DeepL** gebruikt.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor originele en vertaalde tekst.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git) conflictmarkeerder formaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        U kunt het originele bestand herstellen met de volgende [sed(1)](http://man.he.net/man1/sed) opdracht.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        U kunt alleen Japanse tekst terughalen met het commando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Originele en geconverteerde tekst worden gescheiden door een enkele lege regel afgedrukt.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geef de maximale lengte van de tekst op die in één keer naar de API moet worden gestuurd. De standaardwaarde is ingesteld zoals voor de gratis DeepL account service: 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). U kunt deze waarden wijzigen als u Pro-service gebruikt.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Zie het resultaat van de vertaling in real time in de STDERR uitvoer.

- **--match-all**

    Stel de hele tekst van het bestand in als doelgebied.

# CACHE OPTIONS

De module **xlate** kan de tekst van de vertaling voor elk bestand in de cache opslaan en lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache strategie `auto`, onderhoudt het alleen cache gegevens wanneer het cache bestand bestaat voor het doelbestand.

- --cache-clear

    De optie **--cache-clear** kan worden gebruikt om het beheer van de cache te starten of om alle bestaande cache-gegevens te vernieuwen. Eenmaal uitgevoerd met deze optie, wordt een nieuw cachebestand aangemaakt als er geen bestaat en daarna automatisch onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cache bestand en sluit af.

    - `always`, `yes`, `1`

        Cache-bestand toch behouden voor zover het doelbestand een normaal bestand is.

    - `clear`

        Wis eerst de cachegegevens.

    - `never`, `no`, `0`

        Cache-bestand nooit gebruiken, zelfs niet als het bestaat.

    - `accumulate`

        Standaard worden ongebruikte gegevens uit het cachebestand verwijderd. Als u ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan `accumuleren`.

# COMMAND LINE INTERFACE

U kunt deze module gemakkelijk gebruiken vanaf de commandoregel met het commando `xlate` dat in het archief is opgenomen. Zie de `xlate` help informatie voor gebruik.

# EMACS

Laad het `xlate.el` bestand in het archief om het `xlate` commando te gebruiken vanuit de Emacs editor. `xlate-region` functie vertaalt de gegeven regio. De standaardtaal is `EN-US` en u kunt de taal specificeren met het prefix argument.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel uw authenticatiesleutel in voor DeepL service.

- OPENAI\_API\_KEY

    OpenAI authenticatiesleutel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Je moet commandoregeltools installeren voor DeepL en ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python bibliotheek en CLI commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI opdrachtregelinterface

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de **greple** handleiding voor de details over het doeltekstpatroon. Gebruik **--inside**, **--outside**, **--include**, **--exclude** opties om het overeenkomende gebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    U kunt de module `-Mupdate` gebruiken om bestanden te wijzigen door het resultaat van het commando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het formaat van de conflictmarkering naast de optie **-V** te tonen.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple module om alleen de benodigde onderdelen te vertalen en te vervangen met DeepL API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Documenten genereren in 15 talen met DeepL API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatisch vertaalde Docker-omgeving met DeepL API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
