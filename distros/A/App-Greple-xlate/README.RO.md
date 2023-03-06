# NAME

App::Greple::xlate - modul de suport pentru traducere pentru Greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# DESCRIPTION

Modulul **Greple** **xlate** găsește blocurile de text și le înlocuiește cu textul tradus. În prezent, numai serviciul DeepL este suportat de modulul **xlate::deepl**.

Dacă doriți să traduceți un bloc de text normal într-un document în stil [pod](https://metacpan.org/pod/pod), utilizați comanda **greple** cu modulul `xlate::deepl` și `perl` astfel:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Modelul `^(\w.*\n)+` înseamnă linii consecutive care încep cu o literă alfanumerică. Această comandă arată zona care urmează să fie tradusă. Opțiunea **--all** este utilizată pentru a produce întregul text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi se adaugă opțiunea `--xlate` pentru a traduce zona selectată. Aceasta le va găsi și le va înlocui cu ieșirea comenzii **deepl**.

În mod implicit, textul original și cel tradus sunt tipărite în formatul "conflict marker" compatibil cu [git(1)](http://man.he.net/man1/git). Utilizând formatul `ifdef`, puteți obține cu ușurință partea dorită prin comanda [unifdef(1)](http://man.he.net/man1/unifdef). Formatul poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, utilizați opțiunea **--match-entire**. Aceasta este o prescurtare pentru a specifica modelul se potrivește cu întregul text `(?s).*`.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invocați procesul de traducere pentru fiecare zonă corespunzătoare.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Astfel, puteți verifica ce parte a fișierului va face obiectul traducerii înainte de a invoca lucrul efectiv.

    Rezultatul comenzii merge la ieșire standard, deci redirecționați-l către fișier dacă este necesar sau luați în considerare utilizarea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este pliat cu lățimea specificată. Lățimea implicită este 70 și poate fi stabilită prin opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operațiunea de rulare, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specificați motorul de traducere care urmează să fie utilizat. Nu este necesar să utilizați această opțiune deoarece modulul `xlate::deepl` o declară ca fiind `--xlate-engine=deepl`.

- **--xlate-labor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați pentru. După pregătirea textului care urmează să fie tradus, acestea sunt copiate în clipboard. Se așteaptă să le lipiți în formular, să copiați rezultatul în clipboard și să apăsați return.

- **--xlate-to** (Default: `JA`)

    Specificați limba țintă. Puteți obține limbile disponibile prin comanda `deepl languages` atunci când se utilizează motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    - **conflict**, **cm**

        Tipăriți textul original și tradus în formatul de marcare a conflictului [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original prin următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Tipăriți textul original și tradus în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți recupera doar textul japonez prin comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Tipăriți textul original și tradus separate de o singură linie albă.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește numai textul tradus.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

- **--match-entire**

    Setați întregul text al fișierului ca zonă țintă.

# CACHE OPTIONS

Modulul **xlate** poate stoca în memoria cache textul traducerii pentru fiecare fișier și îl poate citi înainte de execuție, pentru a elimina costurile suplimentare de solicitare a serverului. Cu strategia implicită de cache `auto`, acesta păstrează datele din cache numai atunci când fișierul cache există pentru fișierul țintă.

- --cache-clear

    Opțiunea **--cache-clear** poate fi utilizată pentru a iniția gestionarea memoriei cache sau pentru a reîmprospăta toate datele existente în memoria cache. Odată executat cu această opțiune, un nou fișier cache va fi creat dacă nu există unul și apoi va fi menținut automat.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Menține fișierul cache dacă acesta există.

    - `create`

        Creează un fișier cache gol și iese.

    - `always`, `yes`, `1`

        Menține oricum memoria cache în măsura în care fișierul țintă este un fișier normal.

    - `clear`

        Ștergeți mai întâi datele din memoria cache.

    - `never`, `no`, `0`

        Nu utilizează niciodată fișierul cache, chiar dacă există.

    - `accumulate`

        Prin comportament implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu doriți să le eliminați și să le păstrați în fișier, utilizați `acumulare`.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setați cheia de autentificare pentru serviciul DeepL.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Biblioteca Python și comanda CLI.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultați manualul **greple** pentru detalii despre modelul de text țintă. Utilizați opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puteți utiliza modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Folosiți **sdif** pentru a afișa formatul markerilor de conflict unul lângă altul cu opțiunea **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
