# NAME

App::Greple::xlate - modul de suport pentru traducere pentru greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

Modulul **xlate** din **Greple** găsește blocuri de text și le înlocuiește cu textul tradus. În prezent, modulul DeepL (`deepl.pm`) și modulul ChatGPT (`gpt3.pm`) sunt implementate ca motoare de fundal.

Dacă doriți să traduceți blocuri normale de text scrise în stilul [pod](https://metacpan.org/pod/pod), utilizați comanda **greple** cu modulul `xlate::deepl` și modulul `perl` în felul următor:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Modelul `^(\w.*\n)+` înseamnă linii consecutive care încep cu o literă alfanumerică. Această comandă arată zona care trebuie tradusă. Opțiunea **--all** este folosită pentru a produce întregul text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi adăugați opțiunea `--xlate` pentru a traduce zona selectată. Aceasta va găsi și înlocui textul cu ieșirea comenzii **deepl**.

În mod implicit, textul original și textul tradus sunt afișate în formatul "conflict marker", compatibil cu [git(1)](http://man.he.net/man1/git). Utilizând formatul `ifdef`, puteți obține partea dorită cu ușurință folosind comanda [unifdef(1)](http://man.he.net/man1/unifdef). Formatul de ieșire poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, utilizați opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica modelul `(?s).+` care se potrivește cu întregul text.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invocați procesul de traducere pentru fiecare zonă potrivită.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Deci puteți verifica care parte a fișierului va fi supusă traducerii înainte de a invoca lucrul efectiv.

    Rezultatul comenzii este trimis la ieșirea standard, deci redirecționați-l într-un fișier dacă este necesar sau luați în considerare utilizarea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este pliat în funcție de lățimea specificată. Lățimea implicită este de 70 și poate fi setată prin opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operația run-in, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specifică motorul de traducere care trebuie utilizat. Dacă specifici direct modulul motorului, cum ar fi `-Mxlate::deepl`, nu este nevoie să folosești această opțiune.

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați pentru el. După pregătirea textului de tradus, acesta este copiat în clipboard. Se așteaptă să îl lipiți în formular, să copiați rezultatul în clipboard și să apăsați Enter.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Puteți obține limbile disponibile prin comanda `deepl languages` atunci când utilizați motorul **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    - **conflict**, **cm**

        Tipăriți textul original și cel tradus în formatul "conflict marker" al [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original cu următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Tipăriți textul original și cel tradus în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți recupera doar textul japonez cu comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Tipăriți textul original și cel tradus separate printr-o singură linie goală.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește doar textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Traduceți următorul text în limba română, linie cu linie.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

# CACHE OPTIONS

Modulul **xlate** poate stoca textul tradus în cache pentru fiecare fișier și îl poate citi înainte de execuție pentru a elimina costurile de întrebare către server. Cu strategia implicită de cache `auto`, acesta menține datele cache doar atunci când fișierul cache există pentru fișierul țintă.

- --cache-clear

    Opțiunea **--cache-clear** poate fi utilizată pentru a iniția gestionarea cache-ului sau pentru a reîmprospăta toate datele cache existente. Odată executată cu această opțiune, va fi creat un nou fișier cache dacă nu există și apoi va fi menținut automat.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mențineți fișierul cache dacă există.

    - `create`

        Creați un fișier cache gol și ieșiți.

    - `always`, `yes`, `1`

        Mențineți cache-ul oricum, atâta timp cât ținta este un fișier normal.

    - `clear`

        Ștergeți mai întâi datele cache.

    - `never`, `no`, `0`

        Nu utilizați niciodată fișierul cache chiar dacă există.

    - `accumulate`

        În mod implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu doriți să le eliminați și să le păstrați în fișier, utilizați `accumulate`.

# COMMAND LINE INTERFACE

Puteți utiliza cu ușurință acest modul de la linia de comandă folosind comanda `xlate` inclusă în depozit. Consultați informațiile de ajutor `xlate` pentru utilizare.

# EMACS

Încărcați fișierul `xlate.el` inclus în depozit pentru a utiliza comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și puteți specifica limba prin invocarea acesteia cu un argument de prefix.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setați cheia de autentificare pentru serviciul DeepL.

- OPENAI\_API\_KEY

    Cheia de autentificare OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Trebuie să instalezi instrumentele de linie de comandă pentru DeepL și ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Bibliotecă Python DeepL și comandă CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfața de linie de comandă OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultați manualul **greple** pentru detalii despre modelul de text țintă. Utilizați opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puteți utiliza modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilizați **sdif** pentru a afișa formatul markerului de conflict alături de opțiunea **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
