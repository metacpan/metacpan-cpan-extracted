# NAME

App::Greple::xlate - modul de suport pentru traducere pentru Greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** modulul identifică blocurile de text dorite și le înlocuiește cu textul tradus. Motorul principal este GPT-5.5 (`llm/gpt5.pm`), care apelează comanda [llm](https://llm.datasette.io/); Sunt incluse, de asemenea, DeepL (`deepl.pm`) și motoarele vechi bazate pe **gpty**.

Traducerile sunt stocate în cache pentru fiecare fișier, astfel încât rulați din nou o comandă nu implică costuri suplimentare pentru textul nemodificat. Când un document este editat, doar paragrafele modificate sunt trimise din nou către API; un motor sensibil la context primește, de asemenea, traducerile din jur, textul sursă brut din jurul modificării și versiunea anterioară a paragrafului editat, astfel încât noua traducere păstrează formularea stabilită (vezi **--xlate-context-window**). Șirurile sensibile pot fi ascunse înainte de transmitere (vezi ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Dacă doriți să traduceți blocuri de text normale dintr-un document scris în stilul pod al limbajului Perl, utilizați comanda **greple** împreună cu modulele `--xlate-engine gpt5` și `perl` astfel:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

În această comandă, șirul de modele `^([\w\pP].*\n)+` înseamnă linii consecutive care încep cu litere alfanumerice și de punctuație. Această comandă afișează evidențiată zona care urmează să fie tradusă. Opțiunea **--all** este utilizată pentru a produce întregul text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Apoi adăugați opțiunea `--xlate` pentru a traduce zona selectată. Astfel, se vor identifica secțiunile dorite și se vor înlocui cu rezultatul generat de motorul de traducere.

În mod implicit, textul original și cel tradus sunt tipărite în formatul "conflict marker" compatibil cu [git(1)](http://man.he.net/man1/git). Utilizând formatul `ifdef`, puteți obține cu ușurință partea dorită prin comanda [unifdef(1)](http://man.he.net/man1/unifdef). Formatul de ieșire poate fi specificat prin opțiunea **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Dacă doriți să traduceți întregul text, utilizați opțiunea **--match-all**. Aceasta este o scurtătură pentru a specifica modelul `(?s).+` care se potrivește cu întregul text.

Datele din formatul markerului de conflict pot fi vizualizate în stil paralel prin comanda [sdif](https://metacpan.org/pod/App%3A%3Asdif) cu opțiunea `-V`. Deoarece nu are sens să comparați fiecare șir de caractere, este recomandată opțiunea `--no-cdif`. Dacă nu trebuie să colorați textul, specificați `--no-textcolor` (sau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Prelucrarea se face în unități specificate, dar în cazul unei secvențe de linii multiple de text nevid, acestea sunt convertite împreună într-o singură linie. Această operațiune se efectuează după cum urmează:

- Se elimină spațiul alb de la începutul și sfârșitul fiecărei linii.
- Dacă o linie se termină cu un caracter de punctuație de lățime maximă, concatenarea se face cu linia următoare.
- Dacă o linie se termină cu un caracter de lățime întreagă și următoarea linie începe cu un caracter de lățime întreagă, se concatenează liniile.
- Dacă sfârșitul sau începutul unei linii nu este un caracter de lățime maximă, concatenați-le prin inserarea unui caracter de spațiu.

Datele din cache sunt gestionate pe baza textului normalizat, astfel încât, chiar dacă sunt efectuate modificări care nu afectează rezultatele normalizării, datele de traducere din cache vor fi în continuare eficiente.

Acest proces de normalizare se efectuează numai pentru primul model (al 0-lea) și pentru cel cu număr par. Astfel, dacă sunt specificate două modele după cum urmează, textul care corespunde primului model va fi prelucrat după normalizare și nu va fi efectuat niciun proces de normalizare pentru textul care corespunde celui de-al doilea model.

    greple -Mxlate -E normalized -E not-normalized

Prin urmare, utilizați primul model pentru textul care urmează să fie prelucrat prin combinarea mai multor linii într-o singură linie și utilizați al doilea model pentru textul preformattat. Dacă nu există niciun text care să se potrivească în primul model, utilizați un model care nu se potrivește cu nimic, cum ar fi `(?!)`.

# MASKING

Ocazional, există părți de text pe care nu le doriți traduse. De exemplu, etichetele din fișierele markdown. DeepL sugerează ca, în astfel de cazuri, partea de text care trebuie exclusă să fie convertită în etichete XML, tradusă și apoi restaurată după finalizarea traducerii. Pentru a sprijini acest lucru, este posibil să se specifice părțile care urmează să fie mascate de la traducere.

    --xlate-setopt maskfile=MASKPATTERN

Acest lucru va interpreta fiecare linie a fișierului `MASKPATTERN` ca o expresie regulată, va traduce șirurile care se potrivesc și va reveni la starea inițială după procesare. Liniile care încep cu `#` sunt ignorate.

Modelele complexe pot fi scrise pe mai multe linii, cu caracterul de linie nouă precedat de o bară oblică inversă.

Modul în care textul este transformat prin mascare poate fi văzut prin opțiunea **--xlate-mask**.

Mascarea protejează marcajul împotriva traducerii. Pentru a ascunde șirurile sensibile chiar de serviciul de traducere, consultați ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); ambele opțiuni pot fi utilizate împreună.

Această interfață este experimentală și poate fi modificată în viitor.

# ANONYMIZATION AND TEMPLATES

Șirurile sensibile pot fi ascunse înainte de a fi trimise către API-ul de traducere și restabilite în rezultatul final. Sunt disponibile trei surse de reguli de anonimizare: un fișier dicționar (**--xlate-anonymize**), marcaje încorporate în documentul propriu-zis (**--xlate-anonymize-mark**) și valori din secțiunea de antet YAML (**--xlate-frontmatter**). Fiecare șir este înlocuit cu o etichetă de categorie, cum ar fi `<person id=1 />`, în timpul transmiterii. Ascunderea vizează doar transmiterea către API: fișierele din cache-ul local stochează textul simplu restaurat. Utilizați **--xlate-dryrun** pentru a verifica exact ce ar fi transmis.

Pentru documentele de tip formular (rapoarte trimestriale și altele asemenea), definiți actorii de la început și faceți referire la ei în corpul textului:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Traduceți șablonul o singură dată pentru fiecare limbă cu `--xlate-template` (și `--xlate-frontmatter` când valorile sunt păstrate în fișier), apoi generați fiecare caz cu **pandoc-embedz** în modul autonom — valorile de sub `global:` dintr-o configurație externă nu ajung deloc la API-ul de traducere:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Pentru marcajele încorporate, furnizarea unei configurații de definiție a macro-ului face ca același șablon tradus să afișeze fie numele reale, fie o versiune redactată:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Excludeți blocurile embedz din traducere atunci când un document le conține:

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

    Specifică motorul de traducere care urmează să fie utilizat.

    În acest moment, sunt disponibile următoarele motoare

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Modulele motorului sunt căutate mai întâi în spațiile de nume din backend (`llm`, apoi `gpty`), apoi direct sub `App::Greple::xlate`. Astfel, `gpt5` încarcă `App::Greple::xlate::llm::gpt5`, care apelează comanda `llm`, în timp ce `gpt4o` recurge la `App::Greple::xlate::gpty::gpt4o`. Utilizați `--xlate-setopt backend=gpty` pentru a forța un backend specific.

- **--xlate-labor**
- **--xlabor**

    În loc să apelați motorul de traducere, se așteaptă să lucrați pentru. După pregătirea textului care urmează să fie tradus, acestea sunt copiate în clipboard. Se așteaptă să le lipiți în formular, să copiați rezultatul în clipboard și să apăsați return.

- **--xlate-to** (Default: `EN-US`)

    Specificați limba țintă. Motoarele LLM acceptă orice nume sau cod de limbă pe care modelul îl înțelege; acesta este interpolat în promptul de traducere. Puteți obține limbile disponibile prin comanda `deepl languages` atunci când utilizați motorul **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Etichetă utilizată pentru textul original în formatele de ieșire `conflict`, `colon` și `ifdef`. Cu motorul **DeepL**, o valoare non-implicită este, de asemenea, transmisă ca limbă sursă.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificați formatul de ieșire pentru textul original și cel tradus.

    Următoarele formate, altele decât `xtxt`, presupun că partea care urmează să fie tradusă este o colecție de linii. De fapt, este posibil să se traducă doar o parte a unei linii, dar specificarea unui alt format decât `xtxt` nu va produce rezultate semnificative.

    - **conflict**, **cm**

        Textul original și cel convertit sunt tipărite în formatul de marker de conflict [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puteți recupera fișierul original prin următoarea comandă [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Textul original și cel tradus sunt editate într-un stil de container personalizat markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Textul de mai sus va fi tradus în următoarele în HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Numărul de două puncte este de 7 în mod implicit. Dacă specificați o secvență de două puncte precum `:::::`, aceasta este utilizată în locul celor 7 două puncte.

    - **ifdef**

        Textul original și cel convertit sunt tipărite în formatul [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puteți recupera doar textul japonez prin comanda **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Textul original și cel convertit sunt tipărite separate de o singură linie albă. Pentru `space+`, se tipărește și o linie nouă după textul convertit.

    - **xtxt**

        Dacă formatul este `xtxt` (text tradus) sau necunoscut, se tipărește numai textul tradus.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specificați lungimea maximă a textului care urmează să fie trimis către API într-o singură tranzacție. Valoarea implicită 0 înseamnă limita proprie a motorului: pentru serviciul gratuit DeepL, aceasta este de 128K pentru API (**--xlate**) și de 5000 pentru interfața clipboard-ului (**--xlate-labor**). Puteți modifica aceste valori dacă utilizați serviciul Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Specificați numărul maxim de linii de text care urmează să fie trimise simultan către API.

    Setați această valoare la 1 dacă doriți să traduceți un rând pe rând. Această opțiune are prioritate față de opțiunea `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Specificați o solicitare personalizată care să fie trimisă motorului de traducere. Această opțiune este disponibilă pentru motoarele LLM (`gpt3`, `gpt4o`, `gpt5`), dar nu și pentru DeepL. Puteți personaliza comportamentul traducerii oferind instrucțiuni specifice modelului de IA. Dacă promptul conține `%s`, acesta va fi înlocuit cu numele limbii țintă.

- **--xlate-context**=_text_

    Specificați informații contextuale suplimentare care urmează să fie trimise motorului de traducere. Această opțiune poate fi utilizată de mai multe ori pentru a furniza mai multe șiruri de context. Informațiile de context ajută motorul de traducere să înțeleagă contextul și să producă traduceri mai precise.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Numărul de blocuri traduse înconjurătoare transmise ca context de referință la retraducerea blocurilor modificate (implicit 2). Contextul include, de asemenea, textul sursă brut din jurul regiunii modificate (titluri, structura listei, legende) și, atunci când este disponibilă, versiunea anterioară a textului modificat recuperată din cache, astfel încât formularea nemodificată să fie păstrată. Setați la 0 pentru a dezactiva complet traducerea bazată pe context. Rețineți că fiecare regiune modificată este tradusă într-un apel API separat, iar contextul poate adăuga până la aproximativ 8000 de caractere la promptul sistemului, astfel încât traducerea bazată pe context implică un cost suplimentar în schimbul consecvenței.

- **--xlate-cache-seed**=_file_

    Inițializați memoria cache a unui document nou pornind de la fișierul de cache al altui document. Util pentru rapoarte periodice: inițializați memoria cache a noii ediții cu cea a ediției anterioare, astfel încât paragrafele nemodificate să nu fie retraduse, iar paragrafele editate să păstreze formularea din ediția anterioară. Initializarea este utilizată numai atunci când memoria cache de destinație este goală; în caz contrar, este ignorată și se afișează un avertisment. Cu valoarea implicită `--xlate-cache=auto`, specificarea unei inițializări implică, de asemenea, crearea fișierului de cache al noului document.

- **--xlate-anonymize**=_file_

    Anonimizează șirurile sensibile înainte ca acestea să fie trimise către API-ul de traducere și le restabilește în rezultatul final. Fișierul dicționar conține o singură intrare pentru fiecare element: în format JSON (canonic, generabil automat)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    sau într-un format simplu pe linii (`category pattern`, `/.../` pentru expresii regulate). Fiecare element este înlocuit cu o etichetă de categorie, cum ar fi `<person id=1 />`; același șir primește întotdeauna aceeași etichetă, astfel încât modelul să poată ține evidența identității fiecăruia. Câmpurile JSON necunoscute sunt ignorate, astfel încât generatoarele (de exemplu, un LLM local care extrage entități) pot adăuga propriile adnotări. Categoria `lit` este rezervată. Fișierele din cache-ul local stochează în continuare textul simplu restaurat: obiectivul ascunderii vizează doar transmiterea prin API.

    Un dicționar poate fi generat de un instrument extern — de exemplu, un model local care extrage entități sensibile:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Un BOM UTF-8 în fișier este tolerat. Valorile din formatul de linie de antet pot conține un comentariu final doar pe propria linie, nu după valoare.

- **--xlate-anonymize-mark**\[=_regex_\]

    Colectați intrările de anonimizare din marcajele încorporate din documentul însuși. Marcați prima apariție ca `{{ person("山田太郎") }}` și fiecare apariție a șirului în întregul document va fi anonimizată. Marca în sine rămâne în sursă și în traducere, astfel încât un document poate fi procesat și de un procesor de macrocomenzi în stil Jinja2 (definiți macrocomanda `person` pentru a afișa sau a redacta numele). Un _regex_ personalizat trebuie să conțină capturi numite `(?<category>...)` și `(?<text>...)`.

    Rețineți că, în cazul unei opțiuni cu valoare opțională precum aceasta, un argument de fișier următor ar fi considerat ca valoare: scrieți `--xlate-anonymize-mark=` (cu un `=` la sfârșit) atunci când utilizați notația implicită.

    Se pot configura notații alternative, de exemplu `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` pentru marcaje de tip `@@person:NAME@@`, sau o formă de comentariu HTML care rămâne invizibilă în Markdown-ul redat. Regulile de marcare sunt colectate pe document: un șir marcat într-un fișier de intrare nu este ascuns într-un alt fișier din aceeași execuție (spre deosebire de valorile din front matter, care se acumulează între fișiere).

- **--xlate-template**\[=_regex_\]

    Tratează expresiile șablonului (implicit: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) ca substituenți opaci: instruiește modelul să le copieze nemodificate și verifică, pentru fiecare bloc, dacă răspunsul conține exact aceleași expresii, fiecare de același număr de ori. Ordinea acestora se poate modifica, deoarece traducerea le reordonează în mod legitim pentru a respecta ordinea cuvintelor din limba țintă. O expresie incorectă întrerupe execuția; memoria cache este salvată la un punct de control și înghețată, astfel încât nimic din ceea ce a fost plătit nu se pierde.

    Rețineți că, în cazul unei opțiuni cu valoare opțională precum aceasta, un argument de fișier care urmează ar fi considerat ca valoare: scrieți `--xlate-template=` (cu un `=` la sfârșit) atunci când utilizați notația implicită.

- **--xlate-frontmatter**

    Tratați un bloc `---` de la început... `---` ca element de front matter YAML: excludeți-l din traducere și din segmentele de context din faza 2 și adăugați valorile sale simple `key: value` la regulile de anonimizare (categoria `var`) ca măsură de siguranță. În cazul mai multor fișiere de intrare, valorile colectate se acumulează (preferându-se o abordare mai prudentă în ceea ce privește ascunderea).

    Lăsați întotdeauna o linie goală după eticheta de închidere `---`. Cu un model de potrivire de tip paragraf, front matter-ul care se continuă direct în textul principal formează un bloc care se întinde pe ambele părți și pe care excluderea nu îl poate suprima (în acest caz se afișează un avertisment); valorile sunt totuși anonimizate, dar partea introductivă în sine ar fi trimisă spre traducere.

- **--xlate-glossary**=_glossary_

    Specificați un ID de glosar care urmează să fie utilizat pentru traducere. Această opțiune este disponibilă numai atunci când se utilizează motorul DeepL. ID-ul glosarului trebuie obținut din contul dvs. DeepL și asigură traducerea consecventă a termenilor specifici.

- **--xlate-dryrun**

    Nu apelați API-ul de traducere; în schimb, afișați, prin intermediul indicatorului de progres, fiecare încărcătură exact așa cum ar fi transmisă (după anonimizare și mascare). Este util pentru a verifica ce părăsește sistemul și pentru a estima costul unei rulări.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vedeți rezultatul traducerii în timp real în ieșirea STDERR. Datele `From` sunt afișate așa cum sunt transmise, după anonimizare și mascare.

- **--xlate-stripe**

    Utilizați modulul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) pentru a afișa partea corespunzătoare prin metoda zebrei. Acest lucru este util atunci când părțile potrivite sunt conectate spate în spate.

    Paleta de culori este comutată în funcție de culoarea de fundal a terminalului. Dacă doriți să specificați explicit, puteți utiliza **--xlate-stripe-light** sau **--xlate-stripe-dark**.

- **--xlate-mask**

    Efectuați funcția de mascare și afișați textul convertit ca atare, fără restaurare.

- **--match-all**

    Setați întregul text al fișierului ca zonă țintă.

- **--lineify-cm**
- **--lineify-colon**

    În cazul formatelor `cm` și `colon`, rezultatul este împărțit și formatat linie cu linie. Prin urmare, dacă trebuie tradusă doar o parte a unei linii, rezultatul așteptat nu poate fi obținut. Aceste filtre fixează ieșirea care este coruptă prin traducerea unei părți a unei linii în ieșire normală linie cu linie.

    În implementarea actuală, dacă mai multe părți ale unei linii sunt traduse, acestea sunt emise ca linii independente.

# CACHE OPTIONS

Modulul **xlate** poate stoca în memoria cache textul traducerii pentru fiecare fișier și îl poate citi înainte de execuție, pentru a elimina costurile suplimentare de solicitare a serverului. Cu strategia implicită de cache `auto`, acesta păstrează datele din cache numai atunci când fișierul cache există pentru fișierul țintă.

Utilizați **--xlate-cache=clear** pentru a iniția gestionarea cache-ului sau pentru a curăța toate datele cache existente. Odată executat cu această opțiune, se va crea un nou fișier cache dacă nu există unul și apoi se va actualiza automat.

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
- **--xlate-update**

    Această opțiune forțează actualizarea fișierului cache chiar dacă nu este necesar.

# COMMAND LINE INTERFACE

Puteți utiliza cu ușurință acest modul din linia de comandă folosind comanda `xlate` inclusă în distribuție. Consultați pagina de manual `xlate` pentru utilizare.

Comanda `xlate` acceptă opțiuni lungi în stil GNU, precum `--to-lang`, `--from-lang`, `--engine` și `--file`. Utilizați `xlate -h` pentru a vedea toate opțiunile disponibile.

Comanda `xlate` funcționează de comun acord cu mediul Docker, astfel încât, chiar dacă nu aveți nimic instalat la îndemână, îl puteți utiliza atâta timp cât Docker este disponibil. Utilizați opțiunea `-D` sau `-C`.

Operațiunile Docker sunt gestionate de [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), care poate fi utilizată și ca o comandă de sine stătătoare. Comanda `dozo` acceptă fișierul de configurare `.dozorc` pentru setările persistente ale containerului.

De asemenea, deoarece sunt furnizate makefile-uri pentru diferite stiluri de documente, traducerea în alte limbi este posibilă fără specificații speciale. Utilizați opțiunea `-M`.

De asemenea, puteți combina opțiunile Docker și `make` astfel încât să puteți rula `make` într-un mediu Docker.

Executarea ca `xlate -C` va lansa un shell cu depozitul git de lucru curent montat.

Citiți articolul japonez din secțiunea ["SEE ALSO"](#see-also) pentru detalii.

# EMACS

Încărcați fișierul `xlate.el` inclus în depozit pentru a utiliza comanda `xlate` din editorul Emacs. Funcția `xlate-region` traduce regiunea dată. Limba implicită este `EN-US` și puteți specifica limba invocând-o cu argumentul prefix.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setați cheia de autentificare pentru serviciul DeepL.

- OPENAI\_API\_KEY

    Cheia de autentificare OpenAI, utilizată de motoarele vechi **gpty**. Motorul **gpt5** bazat pe `llm` citește și această variabilă, dar funcționează și cheile stocate cu `llm keys set openai`.

- GREPLE\_XLATE\_CACHE

    Setați strategia implicită de cache (consultați ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Instalați instrumentul de linie de comandă pentru motorul pe care îl utilizați: `llm` pentru motorul **gpt5**, `deepl` pentru DeepL, `gpty` pentru motoarele GPT vechi.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Docker runner generic utilizat de xlate pentru operațiunile cu containere

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consultați manualul **greple** pentru detalii despre modelul de text țintă. Utilizați opțiunile **--inside**, **--outside**, **--include**, **--exclude** pentru a limita zona de potrivire.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puteți utiliza modulul `-Mupdate` pentru a modifica fișierele în funcție de rezultatul comenzii **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Folosiți **sdif** pentru a afișa formatul markerilor de conflict unul lângă altul cu opțiunea **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Utilizarea modulului Greple **stripe** prin opțiunea **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagine container Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Biblioteca `getoptlong.sh` utilizată pentru analizarea opțiunilor în scriptul `xlate` și [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Comanda `llm` utilizată de motorul **gpt5** pentru a accesa modelele LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Biblioteca Python și comanda CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfață de linie de comandă OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple pentru a traduce și a înlocui doar părțile necesare cu DeepL API (în japoneză)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generarea de documente în 15 limbi cu modulul DeepL API (în japoneză)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Traducerea automată a mediului Docker cu DeepL API (în japoneză)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
