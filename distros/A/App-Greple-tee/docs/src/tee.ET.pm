=encoding utf-8

=head1 NAME

App::Greple::tee - moodul sobitatud teksti asendamiseks välise käsu tulemusega

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple'i B<-Mtee> moodul saadab sobitatud tekstiosa antud filtrikomandole ja asendab need käsu tulemusega. Idee on tuletatud käsust nimega B<teip>. See on nagu osaliste andmete edastamine välise filtri käsule.

Filtri käsk järgneb moodulideklaratsioonile (C<-Mtee>) ja lõpeb kahe kriipsuga (C<-->). Näiteks järgmine käsk kutsub käsu C<tr> käsu C<a-z A-Z> argumentidega sobiva sõna andmete jaoks.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Ülaltoodud käsk teisendab kõik sobitatud sõnad väiketähtedest suurtähtedeks. Tegelikult ei ole see näide iseenesest nii kasulik, sest B<greple> saab sama asja tõhusamalt teha valikuga B<--cm>.

Vaikimisi täidetakse käsk ühe protsessina ja kõik sobitatud andmed saadetakse sellele segamini. Kui sobitatud tekst ei lõpe newline'iga, lisatakse see enne ja eemaldatakse pärast. Andmed kaardistatakse rea kaupa, nii et sisend- ja väljundandmete ridade arv peab olema identne.

Valiku B<--diskreetne> abil kutsutakse iga sobitatud osa jaoks eraldi käsk. Erinevust saab eristada järgmiste käskude abil.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Sisend- ja väljundandmete read ei pea olema identsed, kui kasutatakse valikut B<--diskreetne>.

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

Kutsuge uus käsk eraldi iga sobitatud osa jaoks.

=item B<--fillup>

Kombineerib mittetühjad read üheks reaks enne nende edastamist käsule filter. Laiade tähemärkide vahel olevad read kustutatakse ja muud read asendatakse tühikutega.

=item B<--blocks>

Tavaliselt saadetakse määratud otsingumustrile vastav ala välisele käsule. Kui see valik on määratud, ei töödelda mitte sobivat ala, vaid kogu seda sisaldavat plokki.

Näiteks, et saata väliskäsule mustrit C<foo> sisaldavad read, tuleb määrata kogu reale vastav muster:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Kuid valikuga B<--blocks> saab seda teha nii lihtsalt kui järgnevalt:

    greple -Mtee cat -n -- foo --blocks

B<--blocks> valikuga käitub see moodul rohkem nagu L<teip(1)> B<-g> valik. Muidu on käitumine sarnane L<teip(1)> B<-o> valikuga.

Ärge kasutage B<--blocks> koos valikuga B<--all>, sest plokk on kogu andmestik.

=item B<--squeeze>

Ühendab kaks või enam järjestikust uusjoonemärki üheks.

=back

=head1 WHY DO NOT USE TEIP

Kõigepealt, kui te saate seda teha käsuga B<teip>, kasutage seda. See on suurepärane vahend ja palju kiirem kui B<greple>.

Kuna B<greple> on mõeldud dokumendifailide töötlemiseks, on tal palju selle jaoks sobivaid funktsioone, näiteks sobitusala kontroll. Nende funktsioonide ärakasutamiseks tasuks ehk kasutada B<greple>.

Samuti ei saa B<teip> töödelda mitut rida andmeid ühe üksusena, samas kui B<greple> saab täita üksikuid käske mitmest reast koosnevale andmekogumile.

=head1 EXAMPLE

Järgmine käsk leiab tekstiplokid Perli moodulifailis sisalduva L<perlpod(1)> stiilis dokumendi sees.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Saate neid tõlkida DeepL teenuse abil, kui täidate ülaltoodud käsu koos mooduliga B<-Mtee>, mis kutsub käsu B<deepl> järgmiselt:

    greple -Mtee deepl text --to JA - -- --fillup ...

Spetsiaalne moodul L<App::Greple::xlate::deepl> on selleks otstarbeks siiski tõhusam. Tegelikult tuli B<tee> mooduli implementatsiooni vihje B<xlate> moodulist.

=head1 EXAMPLE 2

Järgmine käsk leiab mingi sissekirjutatud osa LICENSE dokumendist.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Seda osa saab ümber vormindada, kasutades B<tee> moodulit koos B<ansifold> käsuga:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Valiku C<--diskreet> kasutamine on aeganõudev. Seega võite kasutada C<--separate '\r'> valikut koos C<ansifold>, mis toodab ühe rea, kasutades CR-märki NL-i asemel.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Seejärel teisendage CR märk NL-ks pärast seda käsuga L<tr(1)> või mõnega.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Mõelge olukorrale, kus te soovite grep'i abil leida stringid mitte-pealkirjaridadest. Näiteks võite soovida otsida pilte C<docker image ls> käsust, kuid jätta pealkirjarida alles. Saate seda teha järgmise käsuga.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Valik C<-Mline -L 2:> otsib välja eelviimased read ja saadab need käsule C<grep perl>. Vajalik on valik C<--diskreet>, kuid seda kutsutakse ainult üks kord, nii et see ei kahjusta jõudlust.

Sellisel juhul annab C<teip -l 2- -- grep> vea, sest väljundis olevate ridade arv on väiksem kui sisend. Tulemus on siiski üsna rahuldav :)

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

=head1 BUGS

Valik C<--fillup> ei pruugi koreakeelse teksti puhul korrektselt töötada.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
