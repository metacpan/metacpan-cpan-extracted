# NAME

App::Greple::xlate - Greple tõlkimise tugimoodul

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.29

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstiplokid ja asendab need tõlgitud tekstiga. Praegu on tagasiside mootorina rakendatud DeepL (`deepl.pm`) ja ChatGPT (`gpt3.pm`) moodul.

Kui soovite tõlkida tavalisi tekstiplokke Perli pod-stiilis kirjutatud dokumendis, kasutage käsku **greple** koos `xlate::deepl` ja `perl` mooduliga niimoodi:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Selles käsus tähendab musterjada `^(\w.*\n)+` järjestikuseid ridu, mis algavad tähtnumbrilise tähega. See käsk näitab tõlgitavat ala esile tõstetud kujul. Valikut **--all** kasutatakse kogu teksti koostamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisatakse valik `--xlate`, et tõlkida valitud ala. Seejärel leitakse soovitud lõigud ja asendatakse need käsu **deepl** väljundiga.

Vaikimisi trükitakse algne ja tõlgitud tekst [git(1)](http://man.he.net/man1/git)-ga ühilduvas "konfliktimärkide" formaadis. Kasutades `ifdef` formaati, saab soovitud osa hõlpsasti kätte käsuga [unifdef(1)](http://man.he.net/man1/unifdef). Väljundi formaati saab määrata valikuga **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage valikut **--match-all**. See on otsetee, et määrata muster `(?s).+`, mis vastab kogu tekstile.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitage tõlkimisprotsess iga sobitatud ala jaoks.

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsklus. Seega saate enne tegeliku töö käivitamist kontrollida, millise faili osa kohta tehakse tõlge.

    Käsu tulemus läheb standardväljundisse, nii et vajadusel suunake see faili ümber või kaaluge mooduli [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) kasutamist.

    Valik **--xlate** kutsub **--xlate-color** valiku **--color=never** valikul.

    Valikuga **--xlate-fold** volditakse konverteeritud tekst määratud laiusega. Vaikimisi laius on 70 ja seda saab määrata valikuga **--xlate-fold-width**. Neli veergu on reserveeritud sisselülitamiseks, nii et iga rida võib sisaldada maksimaalselt 74 märki.

- **--xlate-engine**=_engine_

    Määratleb kasutatava tõlkemootori. Kui määrate mootori mooduli otse, näiteks `-Mxlate::deepl`, ei pea seda valikut kasutama.

- **--xlate-labor**
- **--xlabor**

    Insted kutsudes tõlkemootor, siis oodatakse tööd. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikelauale. Eeldatakse, et kleebite need vormi, kopeerite tulemuse lõikelauale ja vajutate return.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. **DeepL** mootori kasutamisel saate saadaval olevad keeled kätte käsuga `deepl languages`.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake originaal- ja tõlgitud teksti väljundformaat.

    - **conflict**, **cm**

        Algne ja teisendatud tekst trükitakse [git(1)](http://man.he.net/man1/git) konfliktimärgistuse formaadis.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Originaalfaili saate taastada järgmise käsuga [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Algne ja teisendatud tekst trükitakse [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaadis.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Saate ainult jaapani teksti taastada käsuga **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Algne ja teisendatud tekst trükitakse ühe tühja reaga eraldatuna.

    - **xtxt**

        Kui formaat on `xtxt` (tõlgitud tekst) või tundmatu, trükitakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määrake API-le korraga saadetava teksti maksimaalne pikkus. Vaikeväärtus on määratud nagu tasuta DeepL kontoteenuse puhul: 128K API jaoks (**--xlate**) ja 5000 lõikelaua liidesele (**--xlate-labor**). Saate neid väärtusi muuta, kui kasutate Pro teenust.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Näete tõlkimise tulemust reaalajas STDERR-väljundist.

- **--match-all**

    Määrake kogu faili tekst sihtkohaks.

# CACHE OPTIONS

**xlate** moodul võib salvestada iga faili tõlketeksti vahemällu ja lugeda seda enne täitmist, et kõrvaldada serveri küsimisega kaasnev koormus. Vaikimisi vahemälustrateegia `auto` puhul säilitab ta vahemälu andmeid ainult siis, kui vahemälufail on sihtfaili jaoks olemas.

- --cache-clear

    Valikut **--cache-clear** saab kasutada vahemälu haldamise alustamiseks või kõigi olemasolevate vahemälu andmete värskendamiseks. Selle valikuga käivitamisel luuakse uus vahemälufail, kui seda ei ole veel olemas, ja seejärel hooldatakse seda automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Säilitada vahemälufaili, kui see on olemas.

    - `create`

        Loob tühja vahemälufaili ja väljub.

    - `always`, `yes`, `1`

        Säilitab vahemälu andmed niikuinii, kui sihtfail on tavaline fail.

    - `clear`

        Tühjendage esmalt vahemälu andmed.

    - `never`, `no`, `0`

        Ei kasuta kunagi vahemälufaili, isegi kui see on olemas.

    - `accumulate`

        Vaikimisi käitumise kohaselt eemaldatakse kasutamata andmed vahemälufailist. Kui te ei soovi neid eemaldada ja failis hoida, kasutage `accumulate`.

# COMMAND LINE INTERFACE

Seda moodulit saab hõlpsasti kasutada käsurealt, kasutades repositooriumis sisalduvat käsku `xlate`. Kasutamise kohta vaata `xlate` abiinfot.

# EMACS

Laadige repositooriumis sisalduv fail `xlate.el`, et kasutada `xlate` käsku Emacs redaktorist. `xlate-region` funktsioon tõlkida antud piirkonda. Vaikimisi keel on `EN-US` ja te võite määrata keele, kutsudes seda prefix-argumendiga.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Määrake oma autentimisvõti DeepL teenuse jaoks.

- OPENAI\_API\_KEY

    OpenAI autentimisvõti.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Peate installima käsurea tööriistad DeepL ja ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Pythoni raamatukogu ja CLI käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythoni raamatukogu

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vt **greple** käsiraamatust üksikasjalikult sihttekstimustri kohta. Kasutage **--inside**, **--outside**, **--include**, **--exclude** valikuid, et piirata sobitusala.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit, et muuta faile **greple** käsu tulemuse järgi.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif**, et näidata konfliktimärkide formaati kõrvuti valikuga **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul tõlkida ja asendada ainult vajalikud osad DeepL API (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduliga (jaapani keeles).

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatne tõlkekeskkond Docker koos DeepL API-ga (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
