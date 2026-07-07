# NAME

App::Greple::xlate - Greple tõlkimise tugimoodul

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** moodulid leiavad soovitud tekstilõigud ja asendavad need tõlgitud tekstiga. Peamine mootor on GPT-5.5 (`llm/gpt5.pm`), mis kutsub välja käsu [llm](https://llm.datasette.io/); Samuti on kaasatud DeepL (`deepl.pm`) ja vanemad **gpty**-põhised mootorid.

Tõlked salvestatakse failipõhiselt vahemällu, seega ei maksa muutumatu teksti puhul käsu uuesti käivitamine midagi. Dokumendi redigeerimisel saadetakse API-le uuesti ainult muudetud lõigud; kontekstist lähtuv mootor saab ka ümbritsevad tõlked, muudatuse ümbruse algteksti ning redigeeritud lõigu eelmise versiooni, nii et uus tõlge säilitab väljakujunenud sõnastuse (vt **--xlate-context-window**). Tundlikud stringid saab enne edastamist varjata (vt ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Kui soovite tõlkida tavalisi tekstilõike dokumendis, mis on kirjutatud Perli pod-stiilis, kasutage käsku **greple** koos moodulitega `--xlate-engine gpt5` ja `perl` järgmiselt:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsus tähendab musterjada `^([\w\pP].*\n)+` järjestikuseid ridu, mis algavad tähtnumbrilise ja kirjavahemärgiga. See käsk näitab tõlgitavat ala esile tõstetud kujul. Valikut **--all** kasutatakse kogu teksti koostamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage valitud ala tõlkimiseks valik `--xlate`. Seejärel leiab süsteem soovitud lõigud ja asendab need tõlkemootori väljundiga.

Vaikimisi trükitakse algne ja tõlgitud tekst [git(1)](http://man.he.net/man1/git)-ga ühilduvas "konfliktimärkide" formaadis. Kasutades `ifdef` formaati, saab soovitud osa hõlpsasti kätte käsuga [unifdef(1)](http://man.he.net/man1/unifdef). Väljundi formaati saab määrata valikuga **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage valikut **--match-all**. See on otsetee, et määrata muster `(?s).+`, mis vastab kogu tekstile.

Konfliktimärkide formaadis andmeid saab vaadata kõrvuti, kasutades käsku [sdif](https://metacpan.org/pod/App%3A%3Asdif) koos valikuga `-V`. Kuna stringide kaupa pole mõtet võrrelda, on soovitatav kasutada `--no-cdif` valikut. Kui teil ei ole vaja teksti värvida, määrake `--no-textcolor` (või `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub kindlaksmääratud ühikutes, kuid mitme mittetäieliku tekstirea järjestuse korral teisendatakse need kokku üheks reaks. See operatsioon toimub järgmiselt:

- Eemaldatakse valge tühik iga rea alguses ja lõpus.
- Kui rida lõpeb täies laiuses kirjavahemärgiga, ühendage see järgmise reaga.
- Kui rida lõpeb täies laiuses märgiga ja järgmine rida algab täies laiuses märgiga, ühendatakse read.
- Kui rea lõpp või algus ei ole täies laiuses märk, ühendage need, lisades tühiku.

Vahemälu andmeid hallatakse normaliseeritud teksti alusel, nii et isegi kui tehakse muudatusi, mis ei mõjuta normaliseerimise tulemusi, on vahemälus olevad tõlkeandmed ikkagi tõhusad.

See normaliseerimisprotsess viiakse läbi ainult esimese (0.) ja paarisnumbrilise mustri puhul. Seega, kui kaks mustrit on määratud järgmiselt, töödeldakse pärast normaliseerimist esimesele mustrile vastavat teksti ja teisele mustrile vastavat teksti ei normaliseerita.

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasutage esimest mustrit teksti puhul, mida tuleb töödelda mitme rea ühendamise teel üheks reaks, ja teist mustrit eelnevalt vormindatud teksti puhul. Kui esimeses mustris ei ole sobivat teksti, kasutage mustrit, mis ei vasta millelegi, näiteks `(?!)`.

# MASKING

Mõnikord on tekstiosasid, mida te ei soovi tõlkida. Näiteks markdown-failide sildid. DeepL soovitab sellistel juhtudel konverteerida välja jäetav tekstiosa XML-tähtedeks, tõlkida ja pärast tõlkimise lõpetamist taastada. Selle toetamiseks on võimalik määrata osad, mis tuleb tõlkimisest välja jätta.

    --xlate-setopt maskfile=MASKPATTERN

See tõlgendab faili `MASKPATTERN` iga rida regulaarse väljendina, tõlgib sellega sobivad stringid ja taastab pärast töötlemist. Ridadega, mis algavad `#`, ei arvestata.

Keerukaid mustreid saab kirjutada mitmele reale, kasutades tagasikaldkriipsuga eskapitud reavahetust.

Seda, kuidas tekst on maskeerimise abil muudetud, saab näha valiku **--xlate-mask** abil.

Maskimine kaitseb märgistust tõlkimise eest. Tundlike stringide varjamiseks tõlketeenuse enda eest vaadake ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); mõlemat saab kasutada koos.

See liides on eksperimentaalne ja võib tulevikus muutuda.

# ANONYMIZATION AND TEMPLATES

Tundlikud stringid saab varjata enne nende saatmist tõlke-API-le ja taastada väljundis. Anonüümimise reegleid on saadaval kolmest allikast: sõnastikufailist (**--xlate-anonymize**), dokumendis endas olevatest sisseehitatud märgetest (**--xlate-anonymize-mark**) ja YAML-i esiosade väärtustest (**--xlate-frontmatter**). Iga string asendatakse edastamise ajal kategooriasildiga, näiteks `<person id=1 />`. Varjamise sihtmärk on ainult API-edastus: kohalikud vahemälufailid salvestavad taastatud tavateksti. Kasutage **--xlate-dryrun**, et täpselt kontrollida, mis edastataks.

Vormidokumentide puhul (kvartaliaruanded jms) määrake osalised eelnevalt kindlaks ja viidake neile tekstis:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Tõlkige mall üks kord iga keele kohta, kasutades `--xlate-template` (ja `--xlate-frontmatter`, kui väärtused säilitatakse failis), seejärel renderdage iga juhtum **pandoc-embedz** eraldiseisvas režiimis – väärtused, mis asuvad välises konfiguratsioonis `global:` all, ei jõua tõlke-API-ni üldse:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Sisestusmärkide puhul võimaldab makrodefinitsiooni konfiguratsiooni esitamine renderida samal tõlgitud mallil kas tegelikud nimed või redigeeritud versiooni:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Jäta embedz-plokid tõlkimisest välja, kui dokument neid sisaldab:

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

    Määrab kasutatava tõlkemootori.

    Praegu on saadaval järgmised mootorid

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Mootorimooduleid otsitakse esmalt tagapõhja nimeruumi alt (`llm`, seejärel `gpty`), seejärel otse `App::Greple::xlate` all. Seega laadib `gpt5` sisse `App::Greple::xlate::llm::gpt5`, mis kutsub välja käsu `llm`, samas kui `gpt4o` kasutab tagavarana `App::Greple::xlate::gpty::gpt4o`. Kasutage `--xlate-setopt backend=gpty`, et sundida kasutama konkreetset backendit.

- **--xlate-labor**
- **--xlabor**

    Selle asemel, et kutsuda tõlkemootorit, oodatakse tööd. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikelauale. Eeldatakse, et te kleebite need vormi, kopeerite tulemuse lõikelauale ja vajutate return.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. LLM-mootorid aktsepteerivad mis tahes keelenime või koodi, mida mudel mõistab; see interpoleeritakse tõlkeprompti. Saadavalolevad keeled saate teada käsu `deepl languages` abil, kui kasutate mootorit **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Silt, mida kasutatakse algteksti jaoks väljundvormingutes `conflict`, `colon` ja `ifdef`. Mootori **DeepL** puhul edastatakse allikakeelena ka mitte-vaikimisi väärtus.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake originaal- ja tõlgitud teksti väljundformaat.

    Järgmised vormingud, välja arvatud `xtxt`, eeldavad, et tõlgitav osa on ridade kogum. Tegelikult on võimalik tõlkida ainult osa reast, kuid muu formaadi kui `xtxt` määramine ei anna mõttekaid tulemusi.

    - **conflict**, **cm**

        Algne ja teisendatud tekst trükitakse [git(1)](http://man.he.net/man1/git) konfliktimärgistuse formaadis.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Originaalfaili saate taastada järgmise käsuga [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Algne ja tõlgitud tekst väljastatakse markdowni kohandatud konteineri stiilis.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Ülaltoodud tekst tõlgitakse HTML-is järgmiselt.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Koolonite arv on vaikimisi 7. Kui määrate koolonite järjestuse nagu `:::::`, kasutatakse seda 7 kooloni asemel.

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
    - **space+**

        Algne ja teisendatud tekst on trükitud ühe tühja reaga eraldatud. `space+` puhul väljastab see ka uue rea pärast teisendatud teksti.

    - **xtxt**

        Kui formaat on `xtxt` (tõlgitud tekst) või tundmatu, trükitakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määrake API-le korraga saadetava teksti maksimaalne pikkus. Vaikimisi väärtus 0 tähendab mootori enda piirangut: DeepLi tasuta kontoteenuse puhul on see API-le (**--xlate**) 128K ja lõikelauale (**--xlate-labor**) 5000. Kui kasutate Pro-teenust, võite neid väärtusi muuta.

- **--xlate-maxline**=_n_ (Default: 0)

    Määrake API-le korraga saadetava teksti maksimaalne ridade arv.

    Määrake selle väärtuseks 1, kui soovite tõlkida ühe rea korraga. See valik on ülimuslik valikust `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Määrake tõlkemootorile saadetav kohandatud käsk. See valik on saadaval LLM-mootorite (`gpt3`, `gpt4o`, `gpt5`) puhul, kuid mitte DeepL-i puhul. Võite kohandada tõlkimiskäitumist, andes AI-mudelile konkreetseid juhiseid. Kui käsk sisaldab `%s`, asendatakse see sihtkeele nimega.

- **--xlate-context**=_text_

    Määrake lisakonteksti teave, mis saadetakse tõlkemootorile. Seda valikut saab kasutada mitu korda, et anda mitu kontekstijada. Kontekstiandmed aitavad tõlkemootoril mõista tausta ja toota täpsemaid tõlkeid.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Muudetud plokkide uuesti tõlkimisel viitekontekstina edastatavate ümbritsevate tõlgitud plokkide arv (vaikimisi 2). Kontekst hõlmab ka muudetud piirkonna ümbruses olevat töötlemata allikateksti (pealkirjad, loendistruktuur, allkirjad) ning, kui see on kättesaadav, vahemälust taastatud muudetud teksti eelmist versiooni, et säilitada muutmata sõnastus. Määrake väärtuseks 0, et kontekstipõhine tõlkimine täielikult välja lülitada. Pange tähele, et iga muudetud piirkond tõlgitakse omaette API-kõnes ning kontekst võib süsteemi käsklusele lisada kuni umbes 8000 tähemärki, seega kontekstipõhine tõlkimine toob järjepidevuse nimel kaasa mõningaid lisakulusid.

- **--xlate-cache-seed**=_file_

    Initsialiseerige uue dokumendi vahemälu teise dokumendi vahemälufaili põhjal. Kasulik perioodiliste aruannete puhul: algandmetena kasutage uue väljaande vahemälus eelmise väljaande andmeid, nii et muutmata lõikeid ei tõlgita uuesti ja muudetud lõigud säilitavad eelmise väljaande sõnastuse. Alustust kasutatakse ainult siis, kui sihtvahemälu on tühi; muidu ignoreeritakse seda koos hoiatusega. Vaikimisi `--xlate-cache=auto` puhul tähendab alustuse määramine ka uue dokumendi vahemälufaili loomist.

- **--xlate-anonymize**=_file_

    Anonüümistage tundlikud stringid enne nende saatmist tõlke-API-le ja taastage need väljundis. Sõnastikufailis on iga elemendi kohta üks kanne: JSON-vormingus (kanoniline, masinloetav)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    või lihtsas ridaformaadis (`category pattern`, `/.../` regulaaravaldiste jaoks). Iga kirje asendatakse kategooriasildiga, näiteks `<person id=1 />`; sama string saab alati sama sildi, nii et mudel saab jälgida, kes on kes. Tundmatuid JSON-välju ignoreeritakse, seega võivad genereerijad (nt entiteete eraldav kohalik LLM) lisada oma märkusi. Kategooria `lit` on reserveeritud. Kohalikud vahemälufailid salvestavad endiselt taastatud lihtteksti: varjamise eesmärk on ainult API-ülekande puhul.

    Sõnastiku saab genereerida välise tööriistaga – näiteks tundlikke entiteete eraldava kohaliku mudeliga:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Failis olevat UTF-8 BOM-i aktsepteeritakse. Esilehe rea formaadis olevad väärtused võivad sisaldada lõpus kommentaari ainult oma eraldi real, mitte väärtuse järel.

- **--xlate-anonymize-mark**\[=_regex_\]

    Koguge anonüümimise kanded dokumendi enda sisseehitatud märkidest. Märgi esimene esinemine näiteks `{{ person("山田太郎") }}` ja kogu dokumendis esinev string anonüümistatakse. Märge ise jääb nii allikasse kui ka tõlkesse, seega saab dokumenti töödelda ka Jinja2-stiilis makroprotsessoriga (määratle makro `person` nime väljastamiseks või redigeerimiseks). Kohandatud _regex_ peab sisaldama nimelisi püüdmisi `(?<category>...)` ja `(?<text>...)`.

    Pange tähele, et sellise valikulise väärtusega valiku puhul võetakse järgnev failiargument väärtusena: kirjutage `--xlate-anonymize-mark=` (koos lõpus oleva `=`-ga), kui kasutate vaikimisi märgistust.

    Võimalik on konfigureerida alternatiivseid märkimisviise, näiteks `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` `@@person:NAME@@`-stiilis märkide jaoks või HTML-kommentaari vorm, mis jääb renderdatud Markdownis nähtamatuks. Märgistuseeskirjad kogutakse dokumendi kaupa: ühes sisendfailis märgistatud stringi ei peeta sama käivituse teises failis varjatuks (erinevalt esilehe väärtustest, mis kogunevad failide vahel).

- **--xlate-template**\[=_regex_\]

    Käsitle malliväljendeid (vaikimisi: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) läbipaistmatute asendusmärkidena: anna mudelile juhis need muutmata kujul kopeerida ja kontrolli iga ploki puhul, et vastus sisaldaks täpselt samu väljendeid, igaüht sama arv kordi. Nende järjekord võib muutuda, kuna tõlkimisel järjestatakse need sihtkeele sõnajärje järgi ümber. Rikkis väljend katkestab töö; vahemälu salvestatakse ja külmutatakse, nii et midagi makstud tööd ei lähe kaotsi.

    Pange tähele, et sellise valikulise väärtusega valiku puhul võetakse järgnev failiargument väärtusena: kirjutage `--xlate-template=` (koos lõpus oleva `=`-ga), kui kasutate vaikimisi märgistust.

- **--xlate-frontmatter**

    Käsitlege alguses olevat `---` ... `---` plokki kui YAML-i esiosa: jäta see tõlkest ja 2. faasi kontekstilõikudest välja ning lisa selle lihtsad `key: value` väärtused anonüümimise reeglitesse (kategooria `var`) turvavõrguna. Mitme sisendfaili korral kogunevad kogutud väärtused (eelistades varjamist).

    Jäta alati tühirida sulgevate `---` järel. Lõigu-stiilis sobitusmustri korral moodustab sissejuhatus, mis ulatub otse põhiteksti sisse, ühe üle ulatuva ploki, mida välistamine ei suuda maha suruda (sel juhul kuvatakse hoiatus); väärtused anonüümistatakse ikkagi, kuid sissejuhatav tekst ise saadetakse tõlkimiseks.

- **--xlate-glossary**=_glossary_

    Määrake sõnastiku ID, mida kasutatakse tõlkimisel. See valik on saadaval ainult siis, kui kasutatakse DeepL mootorit. Sõnastiku ID tuleks saada teie DeepL kontolt ja see tagab konkreetsete terminite järjepideva tõlkimise.

- **--xlate-dryrun**

    Ära kutsu tõlke-API-d; näita selle asemel edastusnäidiku kaudu iga andmepaketti täpselt nii, nagu see edastataks (pärast anonüümistamist ja maskeerimist). See on kasulik selle kontrollimiseks, mis masinast väljub, ning töökäigu maksumuse hindamiseks.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaata tõlketulemust reaalajas STDERR-väljundis. Andmepakett `From` kuvatakse edastatuna, pärast anonüümimist ja maskeerimist.

- **--xlate-stripe**

    Kasutage [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) moodulit, et näidata sobitatud osa sebratriibu moodi. See on kasulik siis, kui sobitatud osad on omavahel ühendatud.

    Värvipalett vahetatakse vastavalt terminali taustavärvile. Kui soovite seda selgesõnaliselt määrata, võite kasutada **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    Sooritage maskeerimisfunktsioon ja kuvage teisendatud tekst sellisena, nagu see on, ilma taastamiseta.

- **--match-all**

    Määrake kogu faili tekst sihtkohaks.

- **--lineify-cm**
- **--lineify-colon**

    Formaatide `cm` ja `colon` puhul jagatakse ja vormistatakse väljund rida-realt. Seega, kui tõlgitakse ainult osa reast, ei saa oodatud tulemust. Need filtrid parandavad väljundi, mis on rikutud, kui osa reast tõlgitakse tavalise rea kaupa väljundiks.

    Praeguses rakenduses, kui rea mitu osa tõlgitakse, väljastatakse need sõltumatute ridadega.

# CACHE OPTIONS

**xlate** moodul võib salvestada iga faili tõlketeksti vahemällu ja lugeda seda enne täitmist, et kõrvaldada serveri küsimisega kaasnev koormus. Vaikimisi vahemälustrateegia `auto` puhul säilitab ta vahemälu andmeid ainult siis, kui vahemälufail on sihtfaili jaoks olemas.

Kasutage **--xlate-cache=clear**, et alustada vahemälu haldamist või puhastada kõik olemasolevad vahemälu andmed. Selle valikuga käivitamisel luuakse uus vahemälufail, kui seda ei ole veel olemas, ja seejärel hooldatakse seda automaatselt.

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
- **--xlate-update**

    See valik sunnib uuendama vahemälufaili isegi siis, kui see pole vajalik.

# COMMAND LINE INTERFACE

Seda moodulit saab hõlpsasti kasutada käsurealt, kasutades jaotuses sisalduvat käsku `xlate`. Kasutamise kohta vaata man-lehte `xlate`.

Käsk `xlate` toetab GNU stiilis pikki valikuid nagu `--to-lang`, `--from-lang`, `--engine` ja `--file`. Kasutage `xlate -h`, et näha kõiki olemasolevaid valikuid.

`xlate` käsk töötab koos Dockeri keskkonnaga, nii et isegi kui teil ei ole midagi paigaldatud, saate seda kasutada, kui Docker on saadaval. Kasutage valikut `-D` või `-C`.

Dockeri operatsioone käsitletakse [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), mida saab kasutada ka iseseisva käsuna. Käsk `dozo` toetab `.dozorc` konfiguratsioonifaili püsivate konteineri seadete jaoks.

Samuti, kuna makefile'id erinevate dokumendistiilide jaoks on olemas, on tõlkimine teistesse keeltesse võimalik ilma spetsiaalse täpsustuseta. Kasutage valikut `-M`.

Saate ka kombineerida Dockeri ja `make` valikuid, nii et saate käivitada `make` Dockeri keskkonnas.

Käivitamine nagu `xlate -C` käivitab shell'i, kuhu on paigaldatud praegune töötav git-repositoorium.

Lugege üksikasjalikult Jaapani artiklit ["SEE ALSO"](#see-also) osas.

# EMACS

Laadige repositooriumis sisalduv fail `xlate.el`, et kasutada `xlate` käsku Emacs redaktorist. `xlate-region` funktsioon tõlkida antud piirkonda. Vaikimisi keel on `EN-US` ja te võite määrata keele, kutsudes seda prefix-argumendiga.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Määrake oma autentimisvõti DeepL teenuse jaoks.

- OPENAI\_API\_KEY

    OpenAI autentimise võti, mida kasutavad vanemad **gpty**-mootorid. Ka `llm`-põhine **gpt5**-mootor loeb seda muutujat, kuid toimivad ka `llm keys set openai`-ga salvestatud võtmed.

- GREPLE\_XLATE\_CACHE

    Määra vaikimisi vahemälustrateegia (vaata ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Paigalda kasutatava mootori jaoks mõeldud käsurea tööriist: `llm` mootori **gpt5** jaoks, `deepl` DeepL-i jaoks, `gpty` vanemate GPT-mootorite jaoks.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - üldine Docker runner, mida xlate kasutab konteineroperatsioonideks.

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vt **greple** käsiraamatust üksikasjalikult sihttekstimustri kohta. Kasutage **--inside**, **--outside**, **--include**, **--exclude** valikuid, et piirata sobitusala.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saate kasutada `-Mupdate` moodulit, et muuta faile **greple** käsu tulemuse järgi.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasutage **sdif**, et näidata konfliktimärkide formaati kõrvuti valikuga **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **xlate-stripe** mooduli kasutamine **--xlate-stripe** valikuga.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockeri konteineri kujutis.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` raamatukogu, mida kasutatakse `xlate` skripti ja [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) valikute parsimiseks.

- [https://llm.datasette.io/](https://llm.datasette.io/)

    `llm`-käsk, mida **gpt5**-mootor kasutab LLM-mudelitele juurdepääsuks.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Pythoni raamatukogu ja CLI käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythoni raamatukogu

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides

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

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
