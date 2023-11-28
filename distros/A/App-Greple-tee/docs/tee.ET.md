# NAME

App::Greple::tee - moodul sobitatud teksti asendamiseks välise käsu tulemusega

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple'i **-Mtee** moodul saadab sobitatud tekstiosa antud filtrikomandole ja asendab need käsu tulemusega. Idee on tuletatud käsust nimega **teip**. See on nagu osaliste andmete edastamine välise filtri käsule.

Filtri käsk järgneb moodulideklaratsioonile (`-Mtee`) ja lõpeb kahe kriipsuga (`--`). Näiteks järgmine käsk kutsub käsu `tr` käsu `a-z A-Z` argumentidega sobiva sõna andmete jaoks.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Ülaltoodud käsk teisendab kõik sobitatud sõnad väiketähtedest suurtähtedeks. Tegelikult ei ole see näide iseenesest nii kasulik, sest **greple** saab sama asja tõhusamalt teha valikuga **--cm**.

Vaikimisi täidetakse käsk ühe protsessina ja kõik sobitatud andmed saadetakse sellele segamini. Kui sobitatud tekst ei lõpe newline'iga, lisatakse see enne ja eemaldatakse pärast. Andmed kaardistatakse rea kaupa, nii et sisend- ja väljundandmete ridade arv peab olema identne.

Valiku **--diskreetne** abil kutsutakse iga sobitatud osa jaoks eraldi käsk. Erinevust saab eristada järgmiste käskude abil.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Sisend- ja väljundandmete read ei pea olema identsed, kui kasutatakse valikut **--diskreetne**.

# VERSION

Version 0.9902

# OPTIONS

- **--discrete**

    Kutsuge uus käsk eraldi iga sobitatud osa jaoks.

- **--fillup**

    Kombineerib mittetühjad read üheks reaks enne nende edastamist käsule filter. Laiade tähemärkide vahel olevad read kustutatakse ja muud read asendatakse tühikutega.

- **--blocks**

    Tavaliselt saadetakse määratud otsingumustrile vastav ala välisele käsule. Kui see valik on määratud, ei töödelda mitte sobivat ala, vaid kogu seda sisaldavat plokki.

    Näiteks, et saata väliskäsule mustrit `foo` sisaldavad read, tuleb määrata kogu reale vastav muster:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Kuid valikuga **--blocks** saab seda teha nii lihtsalt kui järgnevalt:

        greple -Mtee cat -n -- foo --blocks

    **--blocks** valikuga käitub see moodul rohkem nagu [teip(1)](http://man.he.net/man1/teip) **-g** valik. Muidu on käitumine sarnane [teip(1)](http://man.he.net/man1/teip) **-o** valikuga.

    Ärge kasutage **--blocks** koos valikuga **--all**, sest plokk on kogu andmestik.

- **--squeeze**

    Ühendab kaks või enam järjestikust uusjoonemärki üheks.

# WHY DO NOT USE TEIP

Kõigepealt, kui te saate seda teha käsuga **teip**, kasutage seda. See on suurepärane vahend ja palju kiirem kui **greple**.

Kuna **greple** on mõeldud dokumendifailide töötlemiseks, on tal palju selle jaoks sobivaid funktsioone, näiteks sobitusala kontroll. Nende funktsioonide ärakasutamiseks tasuks ehk kasutada **greple**.

Samuti ei saa **teip** töödelda mitut rida andmeid ühe üksusena, samas kui **greple** saab täita üksikuid käske mitmest reast koosnevale andmekogumile.

# EXAMPLE

Järgmine käsk leiab tekstiplokid Perli moodulifailis sisalduva [perlpod(1)](http://man.he.net/man1/perlpod) stiilis dokumendi sees.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

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

Valiku `--diskreet` kasutamine on aeganõudev. Seega võite kasutada `--separate '\r'` valikut koos `ansifold`, mis toodab ühe rea, kasutades CR-märki NL-i asemel.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Seejärel teisendage CR märk NL-ks pärast seda käsuga [tr(1)](http://man.he.net/man1/tr) või mõnega.

    ... | tr '\r' '\n'

# EXAMPLE 3

Mõelge olukorrale, kus te soovite grep'i abil leida stringid mitte-pealkirjaridadest. Näiteks võite soovida otsida pilte `docker image ls` käsust, kuid jätta pealkirjarida alles. Saate seda teha järgmise käsuga.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Valik `-Mline -L 2:` otsib välja eelviimased read ja saadab need käsule `grep perl`. Vajalik on valik `--diskreet`, kuid seda kutsutakse ainult üks kord, nii et see ei kahjusta jõudlust.

Sellisel juhul annab `teip -l 2- -- grep` vea, sest väljundis olevate ridade arv on väiksem kui sisend. Tulemus on siiski üsna rahuldav :)

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

Valik `--fillup` ei pruugi koreakeelse teksti puhul korrektselt töötada.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
