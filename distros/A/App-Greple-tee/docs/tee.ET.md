# NAME

App::Greple::tee - moodul sobitatud teksti asendamiseks välise käsu tulemusega

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.01

# DESCRIPTION

Greple'i **-Mtee** moodul saadab sobitatud tekstiosa antud filtrikomandole ja asendab need käsu tulemusega. Idee on tuletatud käsust nimega **teip**. See on nagu osaliste andmete edastamine välise filtri käsule.

Filtri käsk järgneb moodulideklaratsioonile (`-Mtee`) ja lõpeb kahe kriipsuga (`--`). Näiteks järgmine käsk kutsub käsu `tr` käsu `a-z A-Z` argumentidega sobiva sõna andmete jaoks.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Ülaltoodud käsk teisendab kõik sobitatud sõnad väiketähtedest suurtähtedeks. Tegelikult ei ole see näide iseenesest nii kasulik, sest **greple** saab sama asja tõhusamalt teha valikuga **--cm**.

Vaikimisi täidetakse käsk ühe protsessina ja kõik sobivad andmed saadetakse protsessile segamini. Kui sobitatud tekst ei lõpe newline'iga, lisatakse see enne saatmist ja eemaldatakse pärast vastuvõtmist. Sisend- ja väljundandmed kaardistatakse rea kaupa, seega peab sisend- ja väljundridade arv olema identne.

Valiku **--diskreetne** abil kutsutakse iga sobitatud tekstiala jaoks eraldi käsk. Erinevust saab eristada järgmiste käskude abil.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Sisend- ja väljundandmete read ei pea olema identsed, kui kasutatakse valikut **--diskreetne**.

# OPTIONS

- **--discrete**

    Kutsuge uus käsk eraldi iga sobitatud osa jaoks.

- **--bulkmode**

    Valiku <--diskreetne> puhul täidetakse iga käsk nõudmisel. Käskkiri
    <--bulkmode> option causes all conversions to be performed at once.

- **--crmode**

    See valik asendab kõik uue rea märgid iga ploki keskel vagunipöördumismärkidega. Käsu täitmise tulemuses sisalduvad vagunipöörded tagastatakse uusjoonemärkideks. Seega saab mitmest reast koosnevaid plokke töödelda partiidena ilma **--diskreetse** valikuta.

- **--fillup**

    Ühendage mittetäielike ridade jada üheks reaks enne nende edastamist filtri käsule. Laiade laiade märkide vahel olevad read kustutatakse ja muud read asendatakse tühikutega.

- **--squeeze**

    Ühendab kaks või enam järjestikust uusjoonemärki üheks.

- **-Mline** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip)'i **--offload** valik on rakendatud erinevas moodulis **-Mline**.

        greple -Mtee cat -n -- -Mline --offload 'seq 10 20'

    Mooduli **line** abil saab töödelda ainult paarisnumbrilisi ridu järgmiselt.

        greple -Mtee cat -n -- -Mline 2::2

# LEGACIES

**--plokkide** valikut ei ole enam vaja, kuna **--stretch** (**-S**) valik on implementeeritud **greple**-sse. Saate lihtsalt teha järgmist.

    greple -Mtee cat -n -- --all -SE foo

**--blocks** ei ole soovitatav kasutada, kuna see võib tulevikus aeguda.

- **--blocks**

    Tavaliselt saadetakse määratud otsingumustrile vastav ala välisele käsule. Kui see valik on määratud, ei töödelda mitte sobivat ala, vaid kogu seda sisaldavat plokki.

    Näiteks, et saata väliskäsule mustrit `foo` sisaldavad read, tuleb määrata kogu reale vastav muster:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Kuid valikuga **--blocks** saab seda teha nii lihtsalt kui järgnevalt:

        greple -Mtee cat -n -- foo --blocks

    **--blocks** valikuga käitub see moodul rohkem nagu [teip(1)](http://man.he.net/man1/teip) **-g** valik. Muidu on käitumine sarnane [teip(1)](http://man.he.net/man1/teip) **-o** valikuga.

    Ärge kasutage **--blocks** koos valikuga **--all**, sest plokk on kogu andmestik.

# WHY DO NOT USE TEIP

Kõigepealt, kui te saate seda teha käsuga **teip**, kasutage seda. See on suurepärane vahend ja palju kiirem kui **greple**.

Kuna **greple** on mõeldud dokumendifailide töötlemiseks, on tal palju selle jaoks sobivaid funktsioone, näiteks sobitusala kontroll. Nende funktsioonide ärakasutamiseks tasuks ehk kasutada **greple**.

Samuti ei saa **teip** töödelda mitut rida andmeid ühe üksusena, samas kui **greple** saab täita üksikuid käske mitmest reast koosnevale andmekogumile.

# EXAMPLE

Järgmine käsk leiab tekstiplokid Perli moodulifailis sisalduva [perlpod(1)](http://man.he.net/man1/perlpod) stiilis dokumendi sees.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

Saate neid tõlkida DeepL teenuse abil, kui täidate ülaltoodud käsu koos mooduliga **-Mtee**, mis kutsub käsu **deepl** järgmiselt:

    greple -Mtee deepl text --to JA - -- --fillup ...

Spetsiaalne moodul [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) on selleks otstarbeks siiski tõhusam. Tegelikult tuli **tee** mooduli implementatsiooni vihje **xlate** moodulist.

# EXAMPLE 2

Järgmine käsk leiab mingi sissekirjutatud osa LICENSE dokumendist.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

Seda osa saab ümber vormindada, kasutades **tee** moodulit koos **ansifold** käsuga:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Valikuga --diskreetne käivitatakse mitu protsessi, seega võtab protsessi täitmine kauem aega. Seega võite kasutada valikut `--separate '\r'` koos `ansifold`, mis toodab ühe rea, kasutades CR-märki NL-i asemel.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Seejärel teisendage CR märk NL-ks pärast seda käsuga [tr(1)](http://man.he.net/man1/tr) või mõnega.

    ... | tr '\r' '\n'

# EXAMPLE 3

Mõelge olukorrale, kus te soovite grep'i abil leida stringid mitte-pealkirjaridadest. Näiteks võite soovida otsida Docker image'i nimesid käsust `docker image ls`, kuid jätta pealkirjarida alles. Saate seda teha järgmise käsuga.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Valik `-Mline -L 2:` otsib välja eelviimased read ja saadab need käsule `grep perl`. Valik --diskreetne on vajalik, sest sisendi ja väljundi ridade arv muutub, kuid kuna käsk täidetakse ainult üks kord, ei ole tulemuslikkuse puudujääki.

Kui püüda sama asja teha käsuga **teip**, annab `teip -l 2- -- grep` vea, sest väljundridade arv on väiksem kui sisendridade arv. Saadud tulemusega ei ole aga mingit probleemi.

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

Valik `--fillup` eemaldab korea keele teksti liidestamisel Hangul-märkide vahel olevad tühikud.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
