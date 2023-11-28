# NAME

App::Greple::xlate - tõlketoe moodul greple jaoks

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

**Greple** **xlate** moodul leiab tekstiplokid ja asendab need tõlgitud tekstiga. Praegu on tagurpidi mootorina kasutusel DeepL (`deepl.pm`) ja ChatGPT (`gpt3.pm`) moodul.

Kui soovite tõlkida tavalisi tekstiplokke, mis on kirjutatud [pod](https://metacpan.org/pod/pod) stiilis, kasutage **greple** käsku koos `xlate::deepl` ja `perl` mooduliga järgmiselt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Muster `^(\w.*\n)+` tähendab järjestikuseid ridu, mis algavad alfa-numbrilise tähega. See käsk näitab tõlgitavat ala. Valik **--all** kasutatakse kogu teksti tootmiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage `--xlate` valik valitud ala tõlkimiseks. See leiab ja asendab need **deepl** käsu väljundiga.

Vaikimisi prinditakse algne ja tõlgitud tekst "konfliktimärgendi" formaadis, mis on ühilduv [git(1)](http://man.he.net/man1/git)-ga. Kasutades `ifdef` formaati, saate soovitud osa hõlpsasti kätte [unifdef(1)](http://man.he.net/man1/unifdef) käsu abil. Väljundi formaati saab määrata **--xlate-format** valikuga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida terve teksti, kasutage **--match-all** valikut. See on otsetee, et määrata mustrit `(?s).+`, mis sobib tervele tekstile.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitage tõlkimisprotsess iga sobiva ala jaoks.

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsk. Seega saate enne tegeliku töö käivitamist kontrollida, milline osa failist saab tõlkeobjektiks.

    Käsu tulemus läheb standardväljundisse, nii et suunake see vajadusel faili või kaaluge [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) mooduli kasutamist.

    Valik **--xlate** kutsub välja valiku **--xlate-color** koos valikuga **--color=never**.

    Valikuga **--xlate-fold** volditakse teisendatud tekst määratud laiusega. Vaikimisi laius on 70 ja seda saab määrata valikuga **--xlate-fold-width**. Neli veergu on reserveeritud run-in toimingu jaoks, nii et iga rida võib sisaldada kõige rohkem 74 tähemärki.

- **--xlate-engine**=_engine_

    Määrab kasutatava tõlke mootori. Kui määrate mootori mooduli otse, näiteks `-Mxlate::deepl`, siis pole selle valiku kasutamine vajalik.

- **--xlate-labor**
- **--xlabor**

    Selle asemel, et kutsuda tõlke mootorit, oodatakse, et töötaksite. Pärast tõlgitava teksti ettevalmistamist kopeeritakse see lõikelauale. Oodatakse, et kleepite selle vormi, kopeerite tulemuse lõikelauale ja vajutate sisestusklahvi.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. Saate saada saadaolevad keeled käsu `deepl languages` abil, kui kasutate **DeepL** mootorit.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake algse ja tõlgitud teksti väljundi vorming.

    - **conflict**, **cm**

        Prindi algne ja tõlgitud tekst [git(1)](http://man.he.net/man1/git) konfliktimärgendi vormingus.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Saate algse faili taastada järgmise [sed(1)](http://man.he.net/man1/sed) käsu abil.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Prindi algne ja tõlgitud tekst [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` vormingus.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Saate ainult jaapani keelse teksti kätte **unifdef** käsu abil:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Prindi algne ja tõlgitud tekst eraldatuna ühe tühja reaga.

    - **xtxt**

        Kui vorming on `xtxt` (tõlgitud tekst) või tundmatu, prinditakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tõlgi järgnev tekst eesti keelde, rida-realt.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaadake tõlke tulemust reaalajas STDERR väljundis.

- **--match-all**

    Määrake faili kogu tekst sihtalaks.

# CACHE OPTIONS

**xlate** moodul saab salvestada tõlke teksti vahemällu iga faili jaoks ja lugeda selle enne täitmist, et kõrvaldada päringu ülekoormus. Vaikimisi vahemälu strateegia `auto` korral hoitakse vahemälu andmeid ainult siis, kui sihtfaili jaoks on olemas vahemälu fail.

- --cache-clear

    Võite kasutada valikut **--cache-clear** vahemälu haldamiseks või kõigi olemasolevate vahemälu andmete värskendamiseks. Selle valikuga käivitamisel luuakse uus vahemälu fail, kui ühtegi pole olemas, ja seejärel hoitakse seda automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Hoia vahemälu faili, kui see on olemas.

    - `create`

        Loo tühi vahemälu fail ja välju.

    - `always`, `yes`, `1`

        Hoia vahemälu igal juhul, kui sihtfail on tavaline fail.

    - `clear`

        Kustuta kõigepealt vahemälu andmed.

    - `never`, `no`, `0`

        Ära kasuta vahemälu faili isegi siis, kui see on olemas.

    - `accumulate`

        Vaikimisi käitumise korral eemaldatakse kasutamata andmed vahemälu failist. Kui te ei soovi neid eemaldada ja soovite neid failis hoida, kasutage `accumulate`.

# COMMAND LINE INTERFACE

Saate seda moodulit hõlpsasti kasutada käsurealt, kasutades hõlpsasti kasutatavat `xlate` käsku, mis on kaasasolevas hoidlas. Vaadake `xlate` kasutusjuhendit lisateabe saamiseks.

# EMACS

Laadige `xlate.el` fail, mis on kaasasolevas hoidlas, et kasutada `xlate` käsku Emacs redaktorist. `xlate-region` funktsioon tõlgib antud piirkonna. Vaikimisi keel on `EN-US` ja saate keele määrata eesliiteargumendiga.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Seadistage oma autentimisvõti DeepL-teenuse jaoks.

- OPENAI\_API\_KEY

    OpenAI autentimisvõti.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Peate installima käsurea tööriistad DeepL ja ChatGPT jaoks.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Pythoni teek ja käsurea käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythoni teek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurealiides

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vaadake **greple** käsiraamatut sihtteksti mustrite üksikasjade kohta. Piirake vastavust **--inside**, **--outside**, **--include**, **--exclude** valikutega.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit failide muutmiseks **greple** käsu tulemuse põhjal.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif** konfliktimärgendi vormingu kuvamiseks kõrvuti **-V** valikuga.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
