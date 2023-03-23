# NAME

App::Greple::xlate - Greple tõlkimise tugimoodul

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.20

# DESCRIPTION

**Greple** **xlate** moodul leiab tekstiplokid ja asendab need tõlgitud tekstiga. Praegu toetab **xlate::deepl** moodul ainult DeepL teenust.

Kui soovite [pod](https://metacpan.org/pod/pod) stiilis dokumendis tavalist tekstiplokki tõlkida, kasutage **greple** käsku koos `xlate::deepl` ja `perl` mooduliga niimoodi:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Muster `^(\w.*\n)+` tähendab järjestikuseid ridu, mis algavad tähtnumbrilise tähega. See käsk näitab tõlgitavat ala. Valikut **--all** kasutatakse kogu teksti koostamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage valik `--xlate`, et tõlkida valitud ala. See leiab ja asendab need käsu **deepl** väljundiga.

Vaikimisi trükitakse originaal- ja tõlgitud tekst "konfliktimärkide" formaadis, mis on ühilduv [git(1)](http://man.he.net/man1/git). Kasutades `ifdef` formaati, saate soovitud osa hõlpsasti kätte käsuga [unifdef(1)](http://man.he.net/man1/unifdef). Formaat saab määrata **--xlate-format** valikuga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage valikut **--match-all**. See on otsetee, et määrata muster vastab kogu tekstile `(?s).+`.

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

    Määrake kasutatav tõlkemootor. Seda valikut ei pea kasutama, sest moodul `xlate::deepl` deklareerib seda kui `--xlate-engine=deepl`.

- **--xlate-labor**
- **--xlabor**

    Insted kutsudes tõlkemootor, siis oodatakse tööd. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikelauale. Eeldatakse, et kleebite need vormi, kopeerite tulemuse lõikelauale ja vajutate return.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. **DeepL** mootori kasutamisel saate saadaval olevad keeled kätte käsuga `deepl languages`.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake originaal- ja tõlgitud teksti väljundformaat.

    - **conflict**, **cm**

        Trükib originaal- ja tõlgitud teksti [git(1)](http://man.he.net/man1/git) konfliktimärgistuse formaadis.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Originaalfaili saate taastada järgmise käsuga [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Prindi originaal- ja tõlgitud tekst [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`-vormingus.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Saate ainult jaapani teksti taastada käsuga **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Prindi originaal- ja tõlgitud tekst ühe tühja reaga eraldatud.

    - **xtxt**

        Kui formaat on `xtxt` (tõlgitud tekst) või tundmatu, trükitakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määrake API-le korraga saadetava teksti maksimaalne pikkus. Vaikeväärtus on määratud nagu tasuta kontoteenuse puhul: 128K API jaoks (**--xlate**) ja 5000 lõikelaua liidesele (**--xlate-labor**). Kui kasutate Pro teenust, võite neid väärtusi muuta.

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

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Määrake oma autentimisvõti DeepL teenuse jaoks.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Pythoni raamatukogu ja CLI käsk.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vt **greple** käsiraamatust üksikasjalikult sihttekstimustri kohta. Kasutage **--inside**, **--outside**, **--include**, **--exclude** valikuid, et piirata sobitusala.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit, et muuta faile **greple** käsu tulemuse järgi.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif**, et näidata konfliktimärkide formaati kõrvuti valikuga **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
