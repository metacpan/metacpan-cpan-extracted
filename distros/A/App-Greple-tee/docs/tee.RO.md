# NAME

App::Greple::tee - modul de înlocuire a textului cu rezultatul unei comenzi externe

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Modulul **-Mtee** al lui Greple trimite partea de text potrivit la comanda de filtrare dată și le înlocuiește cu rezultatul comenzii. Ideea este derivată din comanda numită **teip**. Este ca și cum ar ocoli datele parțiale către comanda de filtrare externă.

Comanda de filtrare urmează după declarația modulului (`-Mtee`) și se termină prin două liniuțe (`--`). De exemplu, următoarea comandă apelează comanda `tr` comanda cu argumente `a-z A-Z` pentru cuvântul potrivit din date.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Comanda de mai sus convertește toate cuvintele potrivite din minuscule în majuscule. De fapt, acest exemplu în sine nu este atât de util, deoarece **greple** poate face același lucru mai eficient cu opțiunea **--cm**.

În mod implicit, comanda este executată ca un singur proces, iar toate datele potrivite sunt trimise către acesta amestecate împreună. În cazul în care textul potrivit nu se termină cu newline, acesta este adăugat înainte și eliminat după. Datele sunt mapate linie cu linie, astfel încât numărul de linii de date de intrare și de ieșire trebuie să fie identic.

Utilizând opțiunea **--discret**, se apelează o comandă individuală pentru fiecare piesă care se potrivește. Puteți face diferența prin următoarele comenzi.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Liniile de date de intrare și de ieșire nu trebuie să fie identice atunci când se utilizează opțiunea **--discrete**.

# VERSION

Version 0.9902

# OPTIONS

- **--discrete**

    Invocarea unei noi comenzi individuale pentru fiecare piesă care se potrivește.

- **--fillup**

    Combină o secvență de linii care nu sunt goale într-o singură linie înainte de a le transmite comenzii de filtrare. Caracterele newline dintre caracterele largi sunt șterse, iar alte caractere newline sunt înlocuite cu spații.

- **--blocks**

    În mod normal, zona care corespunde modelului de căutare specificat este trimisă la comanda externă. În cazul în care se specifică această opțiune, nu zona care corespunde, ci întregul bloc care o conține va fi procesat.

    De exemplu, pentru a trimite liniile care conțin modelul `foo` la comanda externă, trebuie să specificați modelul care se potrivește cu întreaga linie:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Dar cu opțiunea **--blocuri**, se poate face la fel de simplu, după cum urmează:

        greple -Mtee cat -n -- foo --blocks

    Cu opțiunea **--blocuri**, acest modul se comportă mai mult ca opțiunea **-g** de la [teip(1)](http://man.he.net/man1/teip). În rest, comportamentul este similar cu cel al lui [teip(1)](http://man.he.net/man1/teip) cu opțiunea **-o**.

    Nu utilizați **--blocks** cu opțiunea **--all**, deoarece blocul va fi reprezentat de toate datele.

- **--squeeze**

    Combină două sau mai multe caractere de linie nouă consecutive într-unul singur.

# WHY DO NOT USE TEIP

În primul rând, ori de câte ori puteți face acest lucru cu comanda **teip**, utilizați-o. Este un instrument excelent și mult mai rapid decât **greple**.

Deoarece **greple** este concepută pentru a procesa fișiere document, are multe caracteristici care îi sunt adecvate, cum ar fi controalele zonei de potrivire. Ar putea merita să utilizați **greple** pentru a profita de aceste caracteristici.

De asemenea, **teip** nu poate trata mai multe linii de date ca o singură unitate, în timp ce **greple** poate executa comenzi individuale pe un fragment de date format din mai multe linii.

# EXAMPLE

Următoarea comandă va găsi blocuri de text în interiorul documentului de stil [perlpod(1)](http://man.he.net/man1/perlpod) inclus în fișierul modul Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Puteți să le traduceți prin serviciul DeepL executând comanda de mai sus convinsă cu modulul **-Mtee** care apelează comanda **deepl** astfel:

    greple -Mtee deepl text --to JA - -- --fillup ...

Totuși, modulul dedicat [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) este mai eficient în acest scop. De fapt, sugestia de implementare a modulului **tee** a venit de la modulul **xlate**.

# EXAMPLE 2

Următoarea comandă va găsi o parte indentată în documentul LICENȚĂ.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Puteți reformata această parte utilizând modulul **tee** cu comanda **ansifold**:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Utilizarea opțiunii `--discrete` necesită mult timp. Deci, puteți utiliza opțiunea `--separate '\r'` cu `ansifold` care produce o singură linie folosind caracterul CR în loc de NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Apoi, convertiți caracterul CR în NL prin comanda [tr(1)](http://man.he.net/man1/tr) sau alta.

    ... | tr '\r' '\n'

# EXAMPLE 3

Luați în considerare o situație în care doriți să căutați prin grep șiruri de caractere din liniile fără antet. De exemplu, este posibil să doriți să căutați imagini din comanda `docker image ls`, dar să lăsați linia de antet. Puteți face acest lucru prin următoarea comandă.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Opțiunea `-Mline -L 2:` recuperează penultima linie și o trimite la comanda `grep perl`. Opțiunea `--discrete` este necesară, dar aceasta este apelată o singură dată, deci nu există niciun dezavantaj de performanță.

În acest caz, `teip -l 2- -- grep` produce o eroare deoarece numărul de linii de la ieșire este mai mic decât cel de la intrare. Cu toate acestea, rezultatul este destul de satisfăcător :)

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

Este posibil ca opțiunea `--fillup` să nu funcționeze corect pentru textul coreean.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
