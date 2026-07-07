# NAME

App::Greple::xlate - modul de suport pentru traducere pentru greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** găsește blocurile de text dorite și le înlocuiește cu textul tradus. Motorul principal este GPT-5.5 (`llm/gpt5.pm`), care apelează comanda [llm](https://llm.datasette.io/); DeepL (`deepl.pm`) și motoarele moștenite bazate pe **gpty** sunt de asemenea incluse.

Traducerile sunt puse în cache pe fișier, astfel încât rerularea unei comenzi nu costă nimic pentru textul neschimbat. Când un document este editat, numai paragrafele modificate sunt trimise din nou la API; un motor conștient de context primește, de asemenea, traducerile înconjurătoare, textul sursă brut din jurul modificării și versiunea anterioară a paragrafului editat, astfel încât noua traducere păstrează formularea stabilită (vedeți **--xlate-context-window**). Șirurile sensibile pot fi mascate înainte de transmitere (vedeți ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Dacă doriți să traduceți blocuri de text obișnuite într-un document scris în stilul pod al Perl, utilizați comanda **greple** cu `--xlate-engine gpt5` și modulul `perl` astfel:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

În această comandă, șirul de tipar `^([\w\pP].*\n)+` înseamnă linii consecutive care încep cu litere și cifre și semne de punctuație. Această comandă arată zona ce urmează a fi tradusă evidențiată. Opțiunea **--all** este folosită pentru a produce textul integral.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi adăugați opțiunea `--xlate` pentru a traduce zona selectată. Atunci va găsi secțiunile dorite și le va înlocui cu ieșirea motorului de traducere.

Implicit, textul original și cel tradus sunt tipărite în formatul „conflict marker” compatibil cu [git(1)](http://man.he.net/man1/git). Folosind formatul `ifdef`, puteți obține partea dorită cu comanda [unifdef(1)](http://man.he.net/man1/unifdef) ușor. Formatul ieșirii poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, folosiți opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica tiparul `(?s).+` care se potrivește întregului text.

Datele în format conflict marker pot fi vizualizate în stil side-by-side cu comanda [sdif](https://metacpan.org/pod/App%3A%3Asdif) și opțiunea `-V`. Deoarece nu are sens să comparați pe bază de șir, se recomandă opțiunea `--no-cdif`. Dacă nu aveți nevoie să colorați textul, specificați `--no-textcolor` (sau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Procesarea se face în unitățile specificate, dar în cazul unei secvențe de mai multe linii de text ne-gol, acestea sunt convertite împreună într-o singură linie. Această operație se efectuează după cum urmează:

- Eliminați spațiile albe de la începutul și sfârșitul fiecărei linii.
- Dacă o linie se termină cu un caracter de punctuație full-width, concatenați cu linia următoare.
- Dacă o linie se termină cu un caracter full-width și linia următoare începe cu un caracter full-width, concatenați liniile.
- Dacă fie sfârșitul, fie începutul unei linii nu este un caracter full-width, concatenați-le inserând un caracter spațiu.

Datele din cache sunt gestionate pe baza textului normalizat, astfel încât, chiar dacă se fac modificări care nu afectează rezultatele normalizării, datele de traducere din cache vor rămâne valabile.

Acest proces de normalizare se efectuează numai pentru modelul (tiparul) primul (al 0-lea) și pentru cele cu număr par. Astfel, dacă sunt specificate două tipare ca mai jos, textul care se potrivește primului tipar va fi procesat după normalizare, iar pe textul care se potrivește celui de-al doilea tipar nu se va efectua niciun proces de normalizare.

    greple -Mxlate -E normalized -E not-normalized

Prin urmare, folosiți primul tipar pentru textul care urmează să fie procesat prin combinarea mai multor linii într-o singură linie și folosiți al doilea tipar pentru text preformatat. Dacă nu există text care să se potrivească primului tipar, folosiți un tipar care nu se potrivește cu nimic, cum ar fi `(?!)`.

# MASKING

Ocazional, există părți din text pe care nu doriți să le traduceți. De exemplu, etichete în fișiere markdown. DeepL sugerează ca, în astfel de cazuri, partea de text care trebuie exclusă să fie convertită în etichete XML, tradusă, apoi restaurată după finalizarea traducerii. Pentru a susține acest lucru, este posibil să specificați părțile care vor fi mascate de la traducere.

    --xlate-setopt maskfile=MASKPATTERN

Aceasta va interpreta fiecare linie a fișierului `MASKPATTERN` ca o expresie regulată, va traduce șirurile care se potrivesc cu aceasta și va reveni după procesare. Liniile care încep cu `#` sunt ignorate.

Un tipar complex poate fi scris pe mai multe linii cu newline scăpat prin backslash.

Modul în care textul este transformat prin mascarea poate fi văzut prin opțiunea **--xlate-mask**.

Mascarea protejează marcajul împotriva traducerii. Pentru a ascunde șirurile sensibile de serviciul de traducere însuși, consultați ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); ambele pot fi utilizate împreună.

Această interfață este experimentală și poate suferi modificări în viitor.

# ANONYMIZATION AND TEMPLATES

Șirurile sensibile pot fi ascunse înainte de a fi trimise către API-ul de traducere și restaurate în ieșire. Sunt disponibile trei surse de reguli de anonimizare: un fișier dicționar (**--xlate-anonymize**), marcaje inline în documentul însuși (**--xlate-anonymize-mark**) și valori YAML front matter (**--xlate-frontmatter**). Fiecare șir este înlocuit cu o etichetă de categorie, cum ar fi `<person id=1 />`, în timpul transmiterii. Ținta ascunderii este doar transmiterea către API: fișierele cache locale stochează text simplu restaurat. Folosiți **--xlate-dryrun** pentru a inspecta exact ce ar fi transmis.

Pentru documente de tip formular (rapoarte trimestriale și altele asemenea), definiți actorii în avans și faceți referire la ei în corp:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Traduceți șablonul o singură dată pentru fiecare limbă cu `--xlate-template` (și `--xlate-frontmatter` când valorile sunt păstrate în fișier), apoi redați fiecare caz cu modul autonom **pandoc-embedz** -- valorile de sub `global:` dintr-o configurație externă nu ajung niciodată la API-ul de traducere:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Pentru marcaje inline, furnizarea unei configurații de definiție a macrocomenzilor face ca același șablon tradus să redea fie numele reale, fie o versiune redactată:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Excludeți blocurile embedz de la traducere atunci când un document le conține:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Pornește procesul de traducere pentru fiecare zonă potrivită.

    Fără această opțiune, **greple** se comportă ca o comandă de căutare normală. Astfel puteți verifica ce parte a fișierului va face obiectul traducerii înainte de a porni munca efectivă.

    Rezultatul comenzii merge la ieșirea standard, deci redirecționați către fișier dacă este necesar sau luați în considerare folosirea modulului [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opțiunea **--xlate** apelează opțiunea **--xlate-color** cu opțiunea **--color=never**.

    Cu opțiunea **--xlate-fold**, textul convertit este împărțit la lățimea specificată. Lățimea implicită este 70 și poate fi setată prin opțiunea **--xlate-fold-width**. Patru coloane sunt rezervate pentru operația run-in, astfel încât fiecare linie poate conține cel mult 74 de caractere.

- **--xlate-engine**=_engine_

    Specifică motorul de traducere care va fi utilizat.

    În acest moment, sunt disponibile următoarele motoare

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Modulele de motor sunt căutate mai întâi în spațiile de nume backend (`llm`, apoi `gpty`), apoi direct sub `App::Greple::xlate`. Astfel, `gpt5` încarcă `App::Greple::xlate::llm::gpt5`, care apelează comanda `llm`, în timp ce `gpt4o` revine la `App::Greple::xlate::gpty::gpt4o`. Folosiți `--xlate-setopt backend=gpty` pentru a forța un backend specific.

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați manual. După pregătirea textului de tradus, acesta este copiat în clipboard. Se așteaptă să îl lipiți în formular, să copiați rezultatul în clipboard și să apăsați Enter.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Motoarele LLM acceptă orice nume de limbă sau cod pe care modelul îl înțelege; acesta este interpolat în promptul de traducere. Puteți obține limbile disponibile cu comanda `deepl languages` când folosiți motorul **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Etichetă utilizată pentru textul original în formatele de ieșire `conflict`, `colon` și `ifdef`. Cu motorul **DeepL**, o valoare diferită de cea implicită este transmisă și ca limbă sursă.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și tradus.

    Următoarele formate, altele decât `xtxt`, presupun că partea de tradus este o colecție de linii. De fapt, este posibil să traduceți doar o porțiune a unei linii, dar specificarea unui format diferit de `xtxt` nu va produce rezultate semnificative.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul marcatorilor de conflict [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original cu următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Textul original și cel tradus sunt afișate într-un stil de container personalizat pentru markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Textul de mai sus va fi tradus în următorul format HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Numărul de două puncte este 7 în mod implicit. Dacă specificați o secvență de două puncte precum `:::::`, aceasta este folosită în locul celor 7 două puncte.

    - **ifdef**

        Textul original și cel convertit sunt tipărite în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți prelua doar textul japonez cu comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Textul original și cel convertit sunt tipărite separate de o linie goală. Pentru `space+`, se afișează și un rând nou după textul convertit.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește doar textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specificați lungimea maximă a textului care va fi trimis la API dintr-o singură dată. Valoarea implicită 0 înseamnă limita proprie a motorului: pentru serviciul contului DeepL gratuit, aceasta este 128K pentru API (**--xlate**) și 5000 pentru interfața clipboard (**--xlate-labor**). Este posibil să puteți schimba aceste valori dacă utilizați serviciul Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificați numărul maxim de linii de text care vor fi trimise la API dintr-o singură dată.

    Setați această valoare la 1 dacă doriți să traduceți câte o linie pe rând. Această opțiune are prioritate față de opțiunea `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Specificați un prompt personalizat care să fie trimis motorului de traducere. Această opțiune este disponibilă pentru motoarele LLM (`gpt3`, `gpt4o`, `gpt5`), dar nu pentru DeepL. Puteți personaliza comportamentul traducerii furnizând instrucțiuni specifice modelului AI. Dacă promptul conține `%s`, acesta va fi înlocuit cu numele limbii țintă.

- **--xlate-context**=_text_

    Specificați informații contextuale suplimentare care să fie trimise motorului de traducere. Această opțiune poate fi utilizată de mai multe ori pentru a furniza multiple șiruri de context. Informațiile de context ajută motorul de traducere să înțeleagă fundalul și să producă traduceri mai precise.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Numărul de blocuri traduse înconjurătoare transmise ca context de referință la retraducerea blocurilor modificate (implicit 2). Contextul include și textul sursă brut din jurul regiunii modificate (titluri, structura listelor, legende) și, când este disponibilă, versiunea anterioară a textului modificat recuperată din cache, astfel încât formulările neschimbate să fie păstrate. Setați la 0 pentru a dezactiva complet traducerea conștientă de context. Rețineți că fiecare regiune modificată este tradusă în propriul apel API, iar contextul poate adăuga până la aproximativ 8000 de caractere la promptul de sistem, astfel încât traducerea conștientă de context schimbă un cost suplimentar pentru consecvență.

- **--xlate-cache-seed**=_file_

    Inițializați cache-ul unui document nou din fișierul cache al altui document. Util pentru rapoarte periodice: inițializați cache-ul noului număr cu cel al numărului anterior, astfel încât paragrafele neschimbate să nu fie retraduse și paragrafele editate să păstreze formularea numărului anterior. Sămânța este folosită numai când cache-ul țintă este gol; altfel este ignorată cu un avertisment. Cu valoarea implicită `--xlate-cache=auto`, specificarea unei semințe implică și crearea fișierului cache al noului document.

- **--xlate-anonymize**=_file_

    Anonimizați șirurile sensibile înainte ca acestea să fie trimise către API-ul de traducere și restaurați-le în ieșire. Fișierul dicționar oferă câte o intrare pentru fiecare element: în JSON (canonic, generabil de mașină)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    sau într-un format simplu pe linii (`category pattern`, `/.../` pentru regex). Fiecare element este înlocuit cu o etichetă de categorie precum `<person id=1 />`; același șir primește întotdeauna aceeași etichetă, astfel încât modelul să poată ține evidența cine este cine. Câmpurile JSON necunoscute sunt ignorate, astfel încât generatoarele (de ex. un LLM local care extrage entități) își pot adăuga propriile adnotări. Categoria `lit` este rezervată. Fișierele cache locale stochează în continuare text simplu restaurat: ținta mascării este doar transmiterea către API.

    Un dicționar poate fi generat de un instrument extern -- de exemplu un model local care extrage entități sensibile:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Un BOM UTF-8 în fișier este tolerat. Valorile din formatul de linie front matter pot avea un comentariu final numai pe propria lor linie, nu după valoare.

- **--xlate-anonymize-mark**\[=_regex_\]

    Colectați intrări de anonimizare din marcaje inline în documentul însuși. Marcați prima apariție ca `{{ person("山田太郎") }}` și fiecare apariție a șirului în întregul document este anonimizată. Marcajul însuși rămâne în sursă și în traducere, astfel încât un document poate fi procesat și de un procesor de macrocomenzi în stil Jinja2 (definiți macrocomanda `person` pentru a afișa sau redacta numele). Un _regex_ personalizat trebuie să conțină capturi numite `(?<category>...)` și `(?<text>...)`.

    Rețineți că, pentru o opțiune cu valoare opțională ca aceasta, un argument de fișier următor ar fi luat drept valoare: scrieți `--xlate-anonymize-mark=` (cu un `=` final) când folosiți notația implicită.

    Notații alternative pot fi configurate, de exemplu `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` pentru marcaje în stil `@@person:NAME@@`, sau o formă de comentariu HTML care rămâne invizibilă în Markdown redat. Regulile de marcaj sunt colectate per document: un șir marcat într-un fișier de intrare nu este ascuns în alt fișier din aceeași rulare (spre deosebire de valorile front matter, care se acumulează între fișiere).

- **--xlate-template**\[=_regex_\]

    Tratați expresiile de șablon (implicit: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) ca substituenți opaci: instruiți modelul să le copieze neschimbate și verificați, pentru fiecare bloc, că răspunsul conține exact aceleași expresii, fiecare de același număr de ori. Ordinea lor se poate schimba, deoarece traducerea le reordonează legitim pentru a urma ordinea cuvintelor din limba țintă. O expresie deteriorată abandonează rularea; cache-ul este checkpointat și înghețat, astfel încât nimic plătit nu se pierde.

    Rețineți că, în cazul unei opțiuni cu valoare opțională ca aceasta, un argument de fișier care urmează ar fi luat drept valoare: scrieți `--xlate-template=` (cu un `=` la sfârșit) când utilizați notația implicită.

- **--xlate-frontmatter**

    Tratați un bloc inițial `---` ... `---` ca front matter YAML: excludeți-l de la traducere și din feliile de context din faza 2 și adăugați valorile sale plate `key: value` la regulile de anonimizare (categoria `var`) ca plasă de siguranță. Cu mai multe fișiere de intrare, valorile colectate se acumulează (greșind în favoarea ascunderii).

    Lăsați întotdeauna o linie goală după `---` de închidere. Cu un tipar de potrivire de tip paragraf, front matter-ul care intră direct în textul corpului formează un singur bloc suprapus pe care excluderea nu îl poate suprima (în acest caz se afișează un avertisment); valorile sunt totuși anonimizate, dar front matter-ul însuși ar fi trimis pentru traducere.

- **--xlate-glossary**=_glossary_

    Specificați un ID de glosar care să fie utilizat pentru traducere. Această opțiune este disponibilă doar atunci când se folosește motorul DeepL. ID-ul glosarului trebuie obținut din contul dvs. DeepL și asigură traducerea consecventă a termenilor specifici.

- **--xlate-dryrun**

    Nu apelați API-ul de traducere; în schimb, afișați prin afișajul de progres fiecare payload exact așa cum ar fi transmis (după anonimizare și mascare). Util pentru a verifica ce părăsește mașina și pentru a estima costul unei rulări.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR. Payload-ul `From` este afișat așa cum a fost transmis, după anonimizare și mascare.

- **--xlate-stripe**

    Folosiți modulul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pentru a afișa partea potrivită în stil zebra striping. Acest lucru este util atunci când părțile potrivite sunt conectate consecutiv.

    Paleta de culori este comutată în funcție de culoarea fundalului terminalului. Dacă doriți să specificați explicit, puteți folosi **--xlate-stripe-light** sau **--xlate-stripe-dark**.

- **--xlate-mask**

    Efectuați funcția de mascarea și afișați textul convertit așa cum este, fără restaurare.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

- **--lineify-cm**
- **--lineify-colon**

    În cazul formatelor `cm` și `colon`, ieșirea este împărțită și formatată linie cu linie. Prin urmare, dacă doar o porțiune dintr-o linie trebuie tradusă, nu se poate obține rezultatul așteptat. Aceste filtre repară ieșirea care este coruptă prin traducerea unei părți a unei linii într-o ieșire normală linie cu linie.

    În implementarea curentă, dacă sunt traduse mai multe părți ale unei linii, acestea sunt afișate ca linii independente.

# CACHE OPTIONS

Modulul **xlate** poate stoca textul de traducere în cache pentru fiecare fișier și îl poate citi înainte de execuție pentru a elimina costul interogării serverului. Cu strategia de cache implicită `auto`, menține datele din cache numai atunci când fișierul de cache există pentru fișierul țintă.

Folosiți **--xlate-cache=clear** pentru a iniția gestionarea cache-ului sau pentru a curăța toate datele de cache existente. Odată executată cu această opțiune, va fi creat un fișier de cache nou dacă nu există unul și apoi va fi menținut automat ulterior.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mențineți fișierul de cache dacă există.

    - `create`

        Creați fișier de cache gol și ieșiți.

    - `always`, `yes`, `1`

        Menține memoria cache oricum, atât timp cât ținta este un fișier normal.

    - `clear`

        Golește mai întâi datele din cache.

    - `never`, `no`, `0`

        Nu folosi niciodată fișierul cache chiar dacă există.

    - `accumulate`

        În mod implicit, datele neutilizate sunt eliminate din fișierul cache. Dacă nu dorești să le elimini și să le păstrezi în fișier, folosește `accumulate`.
- **--xlate-update**

    Această opțiune forțează actualizarea fișierului cache chiar dacă nu este necesar.

# COMMAND LINE INTERFACE

Poți folosi ușor acest modul din linia de comandă folosind comanda `xlate` inclusă în distribuție. Vezi pagina de manual `xlate` pentru utilizare.

Comanda `xlate` acceptă opțiuni lungi în stil GNU precum `--to-lang`, `--from-lang`, `--engine` și `--file`. Folosiți `xlate -h` pentru a vedea toate opțiunile disponibile.

Comanda `xlate` funcționează în concert cu mediul Docker, deci chiar dacă nu ai nimic instalat local, o poți folosi atâta timp cât Docker este disponibil. Folosește opțiunea `-D` sau `-C`.

Operațiunile Docker sunt gestionate de [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), care poate fi folosit și ca o comandă de sine stătătoare. Comanda `dozo` acceptă fișierul de configurare `.dozorc` pentru setări persistente ale containerului.

De asemenea, deoarece sunt furnizate makefile-uri pentru diverse stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Folosește opțiunea `-M`.

Poți combina și opțiunile Docker și `make` astfel încât să poți rula `make` într-un mediu Docker.

Rularea ca `xlate -C` va lansa un shell cu depozitul git de lucru curent montat.

Citește articolul în japoneză din secțiunea ["SEE ALSO"](#see-also) pentru detalii.

# EMACS

Încarcă fișierul `xlate.el` inclus în depozit pentru a folosi comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și poți specifica limba apelând-o cu un argument prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setează cheia ta de autentificare pentru serviciul DeepL.

- OPENAI\_API\_KEY

    Cheie de autentificare OpenAI, folosită de motoarele vechi **gpty**. Motorul **gpt5** bazat pe `llm` citește și el această variabilă, dar funcționează și cheile stocate cu `llm keys set openai`.

- GREPLE\_XLATE\_CACHE

    Setează strategia implicită de cache (vezi ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Instalează instrumentul de linie de comandă pentru motorul pe care îl folosești: `llm` pentru motorul **gpt5**, `deepl` pentru DeepL, `gpty` pentru motoarele GPT vechi.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Runner Docker generic folosit de xlate pentru operațiuni cu containere

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vezi manualul **greple** pentru detalii despre modelul de text țintă. Folosește opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Poți folosi modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Folosește **sdif** pentru a afișa formatul marcatorilor de conflict alăturat cu opțiunea **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Modulul Greple **stripe** este folosit prin opțiunea **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagine de container Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Biblioteca `getoptlong.sh` utilizată pentru analizarea opțiunilor în scriptul `xlate` și [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Comanda `llm` utilizată de motorul **gpt5** pentru a accesa modelele LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca Python DeepL și comanda CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfața de linie de comandă OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple pentru a traduce și înlocui doar părțile necesare cu API-ul DeepL (în japoneză)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generarea documentelor în 15 limbi cu modulul API DeepL (în japoneză)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Mediu Docker pentru traducere automată cu API-ul DeepL (în japoneză)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
