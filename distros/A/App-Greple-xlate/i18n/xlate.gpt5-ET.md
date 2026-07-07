# NAME

App::Greple::xlate - tõlke tugimoodul greple jaoks

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** moodul leiab soovitud tekstiplokid ja asendab need tõlgitud tekstiga. Peamine mootor on GPT-5.5 (`llm/gpt5.pm`), mis kutsub käsku [llm](https://llm.datasette.io/); samuti on kaasas DeepL (`deepl.pm`) ja pärandmootorid, mis põhinevad **gpty**-l.

Tõlked salvestatakse vahemällu failipõhiselt, nii et käsu uuesti käivitamine ei maksa muutmata teksti puhul midagi. Kui dokumenti redigeeritakse, saadetakse API-le uuesti ainult muudetud lõigud; kontekstiteadlik mootor saab ka ümbritsevad tõlked, muudatuse ümber oleva töötlemata lähteteksti ja redigeeritud lõigu eelmise versiooni, nii et uus tõlge säilitab väljakujunenud sõnastuse (vt **--xlate-context-window**). Tundlikke stringe saab enne edastamist varjata (vt ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Kui soovite tõlkida tavalisi tekstiplokke dokumendis, mis on kirjutatud Perli pod-stiilis, kasutage käsku **greple** koos `--xlate-engine gpt5` ja mooduliga `perl` järgmiselt:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Selles käsus tähendab mustrijada `^([\w\pP].*\n)+` järjestikuseid ridu, mis algavad tähtnumbrilise ja kirjavahemärgi märgiga. See käsk näitab tõlkimiseks valitud ala esiletõstetuna. Valikut **--all** kasutatakse kogu teksti kuvamiseks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Seejärel lisage valik `--xlate`, et tõlkida valitud ala. Seejärel leiab see soovitud jaotised ja asendab need tõlkemootori väljundiga.

Vaikimisi prinditakse originaal ja tõlgitud tekst „konfliktimärgi” vormingus, mis on ühilduv [git(1)](http://man.he.net/man1/git)-ga. Kasutades vormingut `ifdef`, saate soovitud osa hõlpsasti kätte käsuga [unifdef(1)](http://man.he.net/man1/unifdef). Väljundvormingut saab määrata valikuga **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Kui soovite tõlkida kogu teksti, kasutage valikut **--match-all**. See on otsetee mustri `(?s).+` määramiseks, mis vastab kogu tekstile.

Konfliktimärgi vormingu andmeid saab vaadata kõrvuti stiilis käsuga [sdif](https://metacpan.org/pod/App%3A%3Asdif) koos valikuga `-V`. Kuna üksikute stringide kaupa võrdlemisel pole mõtet, on soovitatav valik `--no-cdif`. Kui te ei pea teksti värvima, määrake `--no-textcolor` (või `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Töötlemine toimub määratud ühikutes, kuid mitme järjestikuse tühjade ridadeta tekstiridade korral ühendatakse need koos üheks reaks. See toiming tehakse järgmiselt:

- Eemaldage iga rea algusest ja lõpust tühikud.
- Kui rida lõpeb täislaiuses kirjavahemärgiga, liidetakse järgmise reaga.
- Kui rida lõpeb täislaiuses märgiga ja järgmine rida algab täislaiuses märgiga, liidetakse read.
- Kui kas rea lõpp või algus ei ole täislaiuses märk, ühendage need, lisades tühiku.

Puhvriandmeid hallatakse normaliseeritud teksti alusel, seega isegi kui tehakse muudatusi, mis ei mõjuta normaliseerimise tulemust, jäävad puhverdatud tõlkeandmed kehtima.

See normaliseerimisprotsess tehakse ainult esimesele (0.) ja paarisnumbrilistele mustritele. Seega, kui on määratud kaks mustrit järgmiselt, töödeldakse esimesele mustrile vastav tekst pärast normaliseerimist ning teisele mustrile vastava teksti puhul normaliseerimist ei tehta.

    greple -Mxlate -E normalized -E not-normalized

Seetõttu kasutage esimest mustrit teksti jaoks, mida tuleb töödelda mitme rea ühendamisega üheks reaks, ja teist mustrit eelformindatud teksti jaoks. Kui esimesele mustrile ei vasta ühtegi teksti, kasutage mustrit, mis millelegi ei vasta, näiteks `(?!)`.

# MASKING

Mõnikord on tekstis osasid, mida te ei soovi tõlkida. Näiteks sildid markdown-failides. DeepL soovitab sellistel juhtudel tõlkimisest välja jäetav osa teisendada XML-siltideks, lasta see läbi tõlke ja taastada pärast tõlkimise lõppu. Selle toetamiseks on võimalik määrata osad, mis tuleb tõlkimise eest maskeerida.

    --xlate-setopt maskfile=MASKPATTERN

See tõlgendab faili iga rida `MASKPATTERN` kui regulaaravaldis, tõlgib sellega vastavad stringid ja taastab algse oleku pärast töötlemist. Ridu, mis algavad `#`, eiratakse.

Keerukat mustrit saab kirjutada mitmele reale, kasutades tagurpidi kaldkriipsuga paojärjestatud reavahetust.

Kuidas tekst maskeerimise käigus muundatakse, on nähtav valikuga **--xlate-mask**.

Maskeerimine kaitseb märgistust tõlkimise eest. Tundlike stringide peitmiseks tõlketeenuse enda eest vt ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); mõlemat saab kasutada koos.

See liides on eksperimentaalne ja võib tulevikus muutuda.

# ANONYMIZATION AND TEMPLATES

Tundlikud stringid saab peita enne nende saatmist tõlke-API-sse ja väljundis taastada. Saadaval on kolm anonüümimisreeglite allikat: sõnastikufail (**--xlate-anonymize**), dokumendis endas olevad reasisesed märgid (**--xlate-anonymize-mark**) ja YAML-i front matter väärtused (**--xlate-frontmatter**). Iga string asendatakse edastamise ajal kategooriasildiga, näiteks `<person id=1 />`. Peitmise sihtmärk on ainult API-edastus: kohalikud vahemälufailid salvestavad taastatud lihtteksti. Kasutage käsku **--xlate-dryrun**, et kontrollida täpselt, mida edastataks.

Vormidokumentide (kvartaliaruanded ja muu sarnane) puhul määratlege osalised kohe alguses ja viidake neile põhitekstis:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Tõlkige mall iga keele jaoks üks kord käsuga `--xlate-template` (ja `--xlate-frontmatter`, kui väärtused hoitakse failis), seejärel renderdage iga juhtum **pandoc-embedz** eraldiseisvas režiimis -- välises konfiguratsioonis `global:` all olevad väärtused ei jõua tõlke-API-sse üldse:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Reasiseste märgendite puhul võimaldab makrodefinitsiooni konfiguratsiooni andmine samal tõlgitud mallil renderduda kas pärisnimedega või redigeeritud versioonina:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Välistage embedz-plokid tõlkimisest, kui dokument neid sisaldab:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Käivitab tõlkeprotsessi iga vaste piirkonna jaoks.

    Ilma selle valikuta käitub **greple** nagu tavaline otsingukäsk. Nii saate enne tegeliku töö käivitamist kontrollida, milline faili osa läheb tõlkimisele.

    Käsu tulemus läheb standardsesse väljundisse, seega suunake vajadusel faili või kaaluge mooduli [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) kasutamist.

    Valik **--xlate** kutsub välja valiku **--xlate-color** koos valikuga **--color=never**.

    Valikuga **--xlate-fold** murtakse teisendatud tekst etteantud laiusele. Vaikelaius on 70 ja seda saab määrata valikuga **--xlate-fold-width**. Neli veergu on reserveeritud jooksva sisestuse jaoks, seega mahub igale reale maksimaalselt 74 märki.

- **--xlate-engine**=_engine_

    Määrab kasutatava tõlkemootori.

    Praegu on saadaval järgmised mootorid

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Mootorimooduleid otsitakse esmalt taustsüsteemi nimeruumidest (`llm`, seejärel `gpty`), seejärel otse `App::Greple::xlate` alt. Seega `gpt5` laadib `App::Greple::xlate::llm::gpt5`, mis kutsub käsku `llm`, samas kui `gpt4o` langeb tagasi `App::Greple::xlate::gpty::gpt4o` peale. Kasutage `--xlate-setopt backend=gpty`, et sundida kasutama konkreetset taustsüsteemi.

- **--xlate-labor**
- **--xlabor**

    Tõlkemootori kutsumise asemel eeldatakse, et teete töö ise. Pärast tõlgitava teksti ettevalmistamist kopeeritakse need lõikepuhvrisse. Eeldatakse, et kleebite need vormi, kopeerite tulemuse lõikepuhvrisse ja vajutate Enter.

- **--xlate-to** (Default: `EN-US`)

    Määrake sihtkeel. LLM-mootorid aktsepteerivad mis tahes keelenime või -koodi, mida mudel mõistab; see interpoleeritakse tõlkeviipa. Saadavalolevaid keeli saate `deepl languages` käsuga, kui kasutate mootorit **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Originaalteksti jaoks kasutatav silt väljundvormingutes `conflict`, `colon` ja `ifdef`. Mootori **DeepL** puhul edastatakse mittevaikeväärtus ka lähtekeelena.

- **--xlate-format**=_format_ (Default: `conflict`)

    Määrake originaal- ja tõlketeksti väljundvorming.

    Järgnevad vormingud peale `xtxt` eeldavad, et tõlgitav osa on ridade kogum. Tegelikult on võimalik tõlkida ainult osa reast, kuid muu kui `xtxt` vormingu määramine ei anna mõtestatud tulemust.

    - **conflict**, **cm**

        Algne ja teisendatud tekst prinditakse [git(1)](http://man.he.net/man1/git) konfliktimarkerite vormingus.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Algse faili saate taastada järgmise käsuga [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Algne ja tõlgitud tekst väljastatakse markdown’i kohandatud konteineri stiilis.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Ülaltoodud tekst teisendatakse HTML-is järgnevaks.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Koolonite arv on vaikimisi 7. Kui määrate koolonite jada nagu `:::::`, kasutatakse seda 7 kooloni asemel.

    - **ifdef**

        Algne ja teisendatud tekst prinditakse vormingus [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Ainult jaapanikeelse teksti saate kätte käsuga **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Algne ja teisendatud tekst prinditakse, eraldatuna ühe tühja reaga. `space+` korral väljastatakse teisendatud teksti järel ka reavahetus.

    - **xtxt**

        Kui vorming on `xtxt` (tõlgitud tekst) või tundmatu, prinditakse ainult tõlgitud tekst.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Määra maksimaalne teksti pikkus, mis korraga API-le saadetakse. Vaikeväärtus 0 tähendab mootori enda piirangut: DeepL tasuta konto teenuse puhul on see 128K API jaoks (**--xlate**) ja 5000 lõikepuhvri liidese jaoks (**--xlate-labor**). Kui kasutad Pro-teenust, võid neid väärtusi muuta.

- **--xlate-maxline**=_n_ (Default: 0)

    Määra maksimaalne ridade arv, mis korraga API-le saadetakse.

    Sea see väärtus 1, kui soovid tõlkida ühe rea kaupa. See valik on ülimuslik valiku `--xlate-maxlen` suhtes.

- **--xlate-prompt**=_text_

    Määrake tõlkemootorile saadetav kohandatud viip. See valik on saadaval LLM-mootorite (`gpt3`, `gpt4o`, `gpt5`) jaoks, kuid mitte DeepL-i jaoks. Saate tõlkekäitumist kohandada, andes tehisintellekti mudelile konkreetsed juhised. Kui viip sisaldab `%s`, asendatakse see sihtkeele nimega.

- **--xlate-context**=_text_

    Määra täiendav kontekstiinfo, mis saadetakse tõlkemootorile. Seda valikut saab kasutada mitu korda, et edastada mitu kontekstistringi. Kontekst aitab tõlkemootoril tausta mõista ja anda täpsemaid tõlkeid.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Ümbritsevate tõlgitud plokkide arv, mis antakse muudetud plokkide uuesti tõlkimisel viitekontekstina (vaikimisi 2). Kontekst sisaldab ka muudetud piirkonda ümbritsevat toorest lähteksti (pealkirjad, loendistruktuur, pildiallkirjad) ning võimaluse korral vahemälust taastatud muudetud teksti eelmist versiooni, et muutmata sõnastus säiliks. Määrake väärtuseks 0, et kontekstiteadlik tõlge täielikult keelata. Pange tähele, et iga muudetud piirkond tõlgitakse eraldi API-kutses ja kontekst võib süsteemiviibale lisada kuni umbes 8000 märki, seega vahetab kontekstiteadlik tõlge järjepidevuse nimel mõningase lisakulu vastu.

- **--xlate-cache-seed**=_file_

    Lähtesta uue dokumendi vahemälu teise dokumendi vahemälufailist. Kasulik perioodiliste aruannete puhul: külva uue väljaande vahemälu eelmise väljaande omaga, et muutmata lõike ei tõlgitaks uuesti ja muudetud lõigud säilitaksid eelmise väljaande sõnastuse. Seemet kasutatakse ainult siis, kui sihtvahemälu on tühi; vastasel juhul eiratakse seda hoiatusega. Vaikimisi `--xlate-cache=auto` korral tähendab seemne määramine ka uue dokumendi vahemälufaili loomist.

- **--xlate-anonymize**=_file_

    Anonümiseeri tundlikud stringid enne nende saatmist tõlke-API-le ja taasta need väljundis. Sõnastikufail annab iga üksuse kohta ühe kirje: JSON-is (kanoniline, masinaga genereeritav)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    või lihtsas reaformaadis (`category pattern`, `/.../` regexi jaoks). Iga üksus asendatakse kategooriasildiga, näiteks `<person id=1 />`; sama string saab alati sama sildi, nii et mudel saab jälgida, kes on kes. Tundmatuid JSON-välju eiratakse, seega võivad generaatorid (nt kohalik LLM, mis ekstraheerib olemeid) lisada oma annotatsioone. Kategooria `lit` on reserveeritud. Kohalikud vahemälufailid talletavad endiselt taastatud lihtteksti: varjamise siht on ainult API-edastus.

    Sõnastiku saab genereerida välise tööriistaga -- näiteks kohalik mudel, mis ekstraheerib tundlikke olemeid:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Failis olev UTF-8 BOM on lubatud. Front matter'i reaformaadis võivad väärtustel olla lõpus kommentaarid ainult eraldi real, mitte väärtuse järel.

- **--xlate-anonymize-mark**\[=_regex_\]

    Kogu anonümiseerimiskirjed dokumendi enda sisestest märgetest. Märgi esimene esinemine kujul `{{ person("山田太郎") }}` ja iga selle stringi esinemine kogu dokumendis anonümiseeritakse. Märge ise jääb lähtekoodi ja tõlkesse, nii et dokumenti saab töödelda ka Jinja2-stiilis makrotöötlejaga (määratle makro `person`, et nimi printida või redigeerida). Kohandatud _regex_ peab sisaldama nimega hõiveid `(?<category>...)` ja `(?<text>...)`.

    Pange tähele, et sellise valikulise väärtusega valiku korral võetaks järgnev failiargument väärtuseks: kirjutage `--xlate-anonymize-mark=` (lõpus oleva `=`-ga), kui kasutate vaikimisi märgistust.

    Alternatiivseid märgistusi saab konfigureerida, näiteks `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` `@@person:NAME@@`-stiilis märgete jaoks, või HTML-kommentaari vormi, mis jääb renderdatud Markdownis nähtamatuks. Märkereeglid kogutakse dokumendipõhiselt: ühes sisendfailis märgitud stringi ei varjata sama käivituse teises failis (erinevalt front matter'i väärtustest, mis kogunevad failide vahel).

- **--xlate-template**\[=_regex_\]

    Käsitle malliväljendeid (vaikimisi: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) läbipaistmatute kohatäitjatena: juhenda mudelit neid muutmata kopeerima ja kontrolli iga ploki kohta, et vastus sisaldaks täpselt samu väljendeid, igaüht sama arv kordi. Nende järjekord võib muutuda, sest tõlkimisel järjestatakse need õigustatult ümber, et järgida sihtkeele sõnajärge. Katkine väljend katkestab käivituse; vahemälu salvestatakse kontrollpunktina ja külmutatakse, nii et midagi tasulist kaotsi ei lähe.

    Pange tähele, et sellise valikulise väärtusega valiku korral võetaks järgnev failargument väärtusena: kasutage vaikemärgistuse korral `--xlate-template=` (lõpus oleva `=`-ga).

- **--xlate-frontmatter**

    Käsitle alguses olevat `---` ... `---` plokki YAML-i esiosana: jäta see tõlkimisest ja 2. faasi kontekstilõikudest välja ning lisa selle lamedad `key: value` väärtused anonüümimisreeglitesse (kategooria `var`) turvavõrguna. Mitme sisendfaili korral kogutud väärtused kuhjuvad (pigem varjamise kasuks eksides).

    Jäta alati tühi rida pärast sulgevat `---`. Lõigustiilis vastemustriga moodustab otse põhitekstiga kokku jooksev esiosa ühe üle piiri ulatuva ploki, mida välistamine ei suuda maha suruda (sellisel juhul prinditakse hoiatus); väärtused anonüümitakse siiski, kuid esiosa ise saadetaks tõlkimiseks.

- **--xlate-glossary**=_glossary_

    Määra sõnastiku ID, mida tõlkimisel kasutada. See valik on saadaval ainult DeepL mootori kasutamisel. Sõnastiku ID tuleb hankida oma DeepL kontolt ning see tagab kindlate terminite ühtlase tõlke.

- **--xlate-dryrun**

    Ära kutsu tõlke-API-t; selle asemel näita edenemiskuva kaudu iga payload täpselt sellisena, nagu see edastataks (pärast anonüümimist ja maskimist). Kasulik kontrollimaks, mis masinast väljub, ning käivituse maksumuse hindamiseks.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vaata tõlketulemust reaalajas STDERR-väljundis. `From` payload kuvatakse edastatud kujul, pärast anonüümimist ja maskimist.

- **--xlate-stripe**

    Kasuta moodulit [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe), et näidata sobitatud osa sebramustriga. See on kasulik, kui sobitatud osad paiknevad vahetult üksteise järel.

    Värvipalett lülitub vastavalt terminali taustavärvile. Kui soovid seda selgesõnaliselt määrata, võid kasutada **--xlate-stripe-light** või **--xlate-stripe-dark**.

- **--xlate-mask**

    Tee maskimine ja kuva teisendatud tekst taastamata kujul.

- **--match-all**

    Sea kogu faili tekst sihtalaks.

- **--lineify-cm**
- **--lineify-colon**

    Vormingute `cm` ja `colon` puhul jagatakse väljund ridade kaupa ja vormindatakse vastavalt. Seetõttu ei saa oodatud tulemust, kui tõlgitakse ainult osa reast. Need filtrid parandavad väljundi, mis on rikutud rea osalise tõlkimise tõttu, viies selle normaalse reahaaval väljundi kujule.

    Praeguses teostuses, kui ühest reast tõlgitakse mitu osa, väljastatakse need sõltumatute ridadena.

# CACHE OPTIONS

Moodul **xlate** saab talletada iga faili tõlke puhverdatud teksti ja lugeda selle enne täitmist, et vältida päringute esitamise ülekulu serverile. Vaikimisi puhverdamisstrateegia `auto` korral hoitakse puhvriandmeid ainult siis, kui sihtfaili jaoks on olemas puhverfail.

Kasuta **--xlate-cache=clear**, et algatada puhvri haldus või puhastada kogu olemasolev puhvriandmestik. Kui see valik on korra käivitatud, luuakse uus puhverfail, kui seda ei ole, ja seda hallatakse edaspidi automaatselt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Säilita puhverfail, kui see eksisteerib.

    - `create`

        Loo tühi puhverfail ja välju.

    - `always`, `yes`, `1`

        Säilita vahemälu igal juhul, kui siht on tavaline fail.

    - `clear`

        Tühjenda esmalt vahemälu andmed.

    - `never`, `no`, `0`

        Ära kasuta vahemälufaili isegi siis, kui see olemas on.

    - `accumulate`

        Vaikimisi eemaldatakse kasutamata andmed vahemälufailist. Kui sa ei soovi neid eemaldada ja tahad faili alles jätta, kasuta `accumulate`.
- **--xlate-update**

    See valik sunnib vahemälufaili uuendama isegi siis, kui see pole vajalik.

# COMMAND LINE INTERFACE

Seda moodulit saab hõlpsasti kasutada käsurealt, kasutades levitusega kaasas olevat käsku `xlate`. Vaata kasutusjuhiseid man-lehelt `xlate`.

Käsk `xlate` toetab GNU-stiilis pikki valikuid nagu `--to-lang`, `--from-lang`, `--engine` ja `--file`. Kasuta `xlate -h` kõigi saadaolevate valikute nägemiseks.

Käsk `xlate` töötab kooskõlas Dockeri keskkonnaga, seega isegi kui sul pole midagi lokaalselt paigaldatud, saad seda kasutada seni, kuni Docker on saadaval. Kasuta valikut `-D` või `-C`.

Dockeri toiminguid haldab [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), mida saab kasutada ka iseseisva käsuna. Käsk `dozo` toetab püsivate konteineri sätete jaoks konfiguratsioonifaili `.dozorc`.

Samuti, kuna on pakutud mitmesuguste dokumendistiilide makefile’e, on tõlkimine teistesse keeltesse võimalik ilma erisäteteta. Kasuta valikut `-M`.

Võid kombineerida ka Docker ja `make` valikud, et käitada `make` Dockeri keskkonnas.

Käivitamine kujul `xlate -C` avab shelli, kus jooksev töökoopia git-repositoorium on ühendatud.

Loe üksikasju jaapani artiklist jaotisest ["SEE ALSO"](#see-also).

# EMACS

Laadi repositooriumis olev `xlate.el` fail, et kasutada Emacsis käsku `xlate`. Funktsioon `xlate-region` tõlgib etteantud piirkonna. Vaikimisi keel on `EN-US` ning keelt saab määrata seda prefiksargumendiga kutsudes.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Sea oma DeepL teenuse autentimisvõti.

- OPENAI\_API\_KEY

    OpenAI autentimisvõti, mida kasutavad pärand-**gpty** mootorid. `llm`-põhine **gpt5** mootor loeb samuti seda muutujat, kuid töötavad ka võtmed, mis on salvestatud käsuga `llm keys set openai`.

- GREPLE\_XLATE\_CACHE

    Sea vaikimisi vahemälustrateegia (vt ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Paigalda kasutatava mootori käsurea tööriist: `llm` **gpt5** mootori jaoks, `deepl` DeepL-i jaoks, `gpty` pärand-GPT mootorite jaoks.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlate’i poolt konteineri toiminguteks kasutatav üldine Dockeri käitaja

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vaata sihtteksti mustri üksikasju käsiraamatust **greple**. Kasuta valikuid **--inside**, **--outside**, **--include**, **--exclude** vastendusala piiramiseks.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Saad kasutada moodulit `-Mupdate`, et muuta faile käsu **greple** tulemuste põhjal.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Kasuta **sdif**, et näidata konfliktimärgendite formaati kõrvuti valikuga **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** moodulit kasutatakse valikuga **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockeri konteineripilt.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` teek, mida kasutatakse valikute parsimiseks skriptis `xlate` ja [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Käsk `llm`, mida mootor **gpt5** kasutab LLM-mudelitele juurdepääsuks.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python’i teek ja CLI käsk.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python’i teek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI käsurea liides

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple moodul vajalike osade tõlkimiseks ja asendamiseks ainult DeepL API-ga (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Dokumentide genereerimine 15 keeles DeepL API mooduliga (jaapani keeles)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automaatse tõlke Docker-keskkond DeepL API-ga (jaapani keeles)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
