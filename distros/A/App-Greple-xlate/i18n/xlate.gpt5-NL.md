# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** module vindt gewenste tekstblokken en vervangt deze door de vertaalde tekst. De primaire engine is GPT-5.5 (`llm/gpt5.pm`), die het [llm](https://llm.datasette.io/)-commando aanroept; DeepL (`deepl.pm`) en legacy **gpty**-gebaseerde engines zijn ook inbegrepen.

Vertalingen worden per bestand gecachet, dus het opnieuw uitvoeren van een commando kost niets voor ongewijzigde tekst. Wanneer een document wordt bewerkt, worden alleen de gewijzigde alinea's opnieuw naar de API gestuurd; een contextbewuste engine ontvangt ook de omringende vertalingen, de ruwe brontekst rond de wijziging en de vorige versie van de bewerkte alinea, zodat de nieuwe vertaling de gevestigde formulering behoudt (zie **--xlate-context-window**). Gevoelige strings kunnen vóór verzending worden verborgen (zie ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Als u normale tekstblokken wilt vertalen in een document dat is geschreven in de pod-stijl van Perl, gebruik dan de opdracht **greple** met `--xlate-engine gpt5` en de module `perl` zoals dit:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In dit commando betekent de patroonstring `^([\w\pP].*\n)+` opeenvolgende regels die beginnen met alfanumerieke en leestekens. Dit commando toont het te vertalen gebied gemarkeerd. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg vervolgens de optie `--xlate` toe om het geselecteerde gebied te vertalen. Dan worden de gewenste secties gevonden en vervangen door de uitvoer van de vertaalengine.

Standaard worden originele en vertaalde tekst afgedrukt in het "conflict marker"-formaat dat compatibel is met [git(1)](http://man.he.net/man1/git). Met `ifdef`-formaat kun je het gewenste deel gemakkelijk verkrijgen met het [unifdef(1)](http://man.he.net/man1/unifdef)-commando. Het uitvoerformaat kan worden gespecificeerd met de optie **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de volledige tekst wilt vertalen, gebruik dan de optie **--match-all**. Dit is een snelkoppeling om het patroon `(?s).+` op te geven dat overeenkomt met de volledige tekst.

Gegevens in conflict marker-formaat kunnen in zij-aan-zij-stijl worden bekeken met het [sdif](https://metacpan.org/pod/App%3A%3Asdif)-commando met optie `-V`. Aangezien het geen zin heeft om per string te vergelijken, wordt de optie `--no-cdif` aanbevolen. Als je de tekst niet hoeft te kleuren, specificeer `--no-textcolor` (of `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

De verwerking gebeurt in gespecificeerde eenheden, maar in het geval van een reeks van meerdere regels niet-lege tekst worden ze samen omgezet in één regel. Deze bewerking wordt als volgt uitgevoerd:

- Verwijder witruimte aan het begin en einde van elke regel.
- Als een regel eindigt met een full-width leesteken, concateneer met de volgende regel.
- Als een regel eindigt met een full-width teken en de volgende regel begint met een full-width teken, concateneer de regels.
- Als het einde of het begin van een regel geen full-width teken is, concateneer ze door een spatie in te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als wijzigingen worden aangebracht die de normalisatieresultaten niet beïnvloeden, blijft de vertaalde cachedata effectief.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Dus als twee patronen als volgt worden opgegeven, wordt de tekst die overeenkomt met het eerste patroon verwerkt na normalisatie, en wordt er geen normalisatieproces uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple -Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die moet worden verwerkt door meerdere regels te combineren tot één regel, en gebruik het tweede patroon voor vooraf opgemaakte tekst. Als er geen tekst is die overeenkomt met het eerste patroon, gebruik dan een patroon dat nergens mee overeenkomt, zoals `(?!)`.

# MASKING

Soms zijn er delen van de tekst die je niet wilt vertalen. Bijvoorbeeld tags in markdown-bestanden. DeepL stelt voor om in dergelijke gevallen het te uitsluiten deel van de tekst om te zetten naar XML-tags, te vertalen en daarna na voltooiing van de vertaling te herstellen. Ter ondersteuning hiervan is het mogelijk om de delen die van vertaling moeten worden gemaskeerd op te geven.

    --xlate-setopt maskfile=MASKPATTERN

Dit zal elke regel van het bestand `MASKPATTERN` interpreteren als een reguliere expressie, strings die ermee overeenkomen vertalen en terugdraaien na verwerking. Regels die beginnen met `#` worden genegeerd.

Een complex patroon kan over meerdere regels worden geschreven met een backslash-geëscapete regeleinde.

Hoe de tekst door maskering wordt getransformeerd, is te zien met de optie **--xlate-mask**.

Maskering beschermt markup tegen vertaling. Om gevoelige strings voor de vertaaldienst zelf te verbergen, zie ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); beide kunnen samen worden gebruikt.

Deze interface is experimenteel en kan in de toekomst veranderen.

# ANONYMIZATION AND TEMPLATES

Gevoelige tekenreeksen kunnen worden verborgen voordat ze naar de vertaal-API worden verzonden en in de uitvoer worden hersteld. Er zijn drie bronnen voor anonimiseringsregels beschikbaar: een woordenboekbestand (**--xlate-anonymize**), inline-markeringen in het document zelf (**--xlate-anonymize-mark**) en YAML-frontmatterwaarden (**--xlate-frontmatter**). Elke tekenreeks wordt tijdens de transmissie vervangen door een categorietag zoals `<person id=1 />`. Het doel van de verhulling is alleen API-transmissie: lokale cachebestanden slaan herstelde platte tekst op. Gebruik **--xlate-dryrun** om precies te inspecteren wat er zou worden verzonden.

Voor formulierdocumenten (kwartaalrapporten en dergelijke) definieer je de actoren vooraf en verwijs je ernaar in de hoofdtekst:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Vertaal de sjabloon één keer per taal met `--xlate-template` (en `--xlate-frontmatter` wanneer de waarden in het bestand worden bewaard), en render vervolgens elk geval met de standalone-modus **pandoc-embedz** -- waarden onder `global:` in een externe configuratie bereiken de vertaal-API helemaal niet:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Voor inline markeringen zorgt het opgeven van een configuratie voor macrodefinities ervoor dat dezelfde vertaalde sjabloon ofwel de echte namen ofwel een geredigeerde versie rendert:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Sluit embedz-blokken uit van vertaling wanneer een document ze bevat:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Start het vertaalproces voor elk overeenkomend gebied.

    Zonder deze optie gedraagt **greple** zich als een normale zoekopdracht. Zo kun je controleren welk deel van het bestand onderwerp van de vertaling zal zijn voordat je het echte werk start.

    Het commandoresultaat gaat naar standaarduitvoer, dus leid indien nodig om naar een bestand, of overweeg het gebruik van de module [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Optie **--xlate** roept optie **--xlate-color** aan met optie **--color=never**.

    Met optie **--xlate-fold** wordt geconverteerde tekst opgevouwen tot de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met optie **--xlate-fold-width**. Er zijn vier kolommen gereserveerd voor run-in-bewerking, dus elke regel kan maximaal 74 tekens bevatten.

- **--xlate-engine**=_engine_

    Specificeert de te gebruiken vertaalengine.

    Op dit moment zijn de volgende engines beschikbaar

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Engine-modules worden eerst gezocht in backend-naamruimten (`llm`, daarna `gpty`), vervolgens direct onder `App::Greple::xlate`. Dus `gpt5` laadt `App::Greple::xlate::llm::gpt5` dat het commando `llm` aanroept, terwijl `gpt4o` terugvalt op `App::Greple::xlate::gpty::gpt4o`. Gebruik `--xlate-setopt backend=gpty` om een specifieke backend af te dwingen.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalengine aan te roepen, wordt verwacht dat jij het werk doet. Na het voorbereiden van de te vertalen tekst worden deze naar het klembord gekopieerd. Je wordt verondersteld ze in het formulier te plakken, het resultaat naar het klembord te kopiëren en op return te drukken.

- **--xlate-to** (Default: `EN-US`)

    Specificeer de doeltaal. LLM-engines accepteren elke taalnaam of code die het model begrijpt; deze wordt in de vertaalprompt geïnterpoleerd. Je kunt beschikbare talen opvragen met het commando `deepl languages` wanneer je de engine **DeepL** gebruikt.

- **--xlate-from** (Default: `ORIGINAL`)

    Label dat wordt gebruikt voor de originele tekst in de uitvoerindelingen `conflict`, `colon` en `ifdef`. Met de engine **DeepL** wordt een niet-standaardwaarde ook doorgegeven als brontaal.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer de uitvoerindeling voor originele en vertaalde tekst.

    De volgende indelingen, anders dan `xtxt`, gaan ervan uit dat het te vertalen deel een verzameling regels is. In feite is het mogelijk slechts een gedeelte van een regel te vertalen, maar het specificeren van een andere indeling dan `xtxt` levert geen zinvol resultaat op.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git)-conflictmarkeringsformaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Je kunt het originele bestand herstellen met het volgende commando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        De originele en vertaalde tekst worden uitgevoerd in een aangepaste containerstijl van markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Bovenstaande tekst wordt in HTML als volgt vertaald.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Het aantal dubbele punten is standaard 7. Als je een reeks dubbele punten opgeeft zoals `:::::`, wordt die gebruikt in plaats van 7 dubbele punten.

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`-formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Je kunt alleen Japanse tekst ophalen met het commando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Originele en geconverteerde tekst worden afgedrukt, gescheiden door één lege regel. Voor `space+` wordt ook een regeleinde na de geconverteerde tekst uitgegeven.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) is of onbekend, wordt alleen de vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geef de maximale lengte op van tekst die in één keer naar de API wordt verzonden. De standaardwaarde 0 betekent de eigen limiet van de engine: voor de gratis DeepL-accountservice is dat 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). Mogelijk kunt u deze waarden wijzigen als u de Pro-service gebruikt.

- **--xlate-maxline**=_n_ (Default: 0)

    Geef het maximale aantal regels tekst op dat in één keer naar de API wordt verzonden.

    Stel deze waarde in op 1 als u één regel per keer wilt vertalen. Deze optie heeft voorrang op de optie `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Geef een aangepaste prompt op die naar de vertaalengine wordt gestuurd. Deze optie is beschikbaar voor de LLM-engines (`gpt3`, `gpt4o`, `gpt5`), maar niet voor DeepL. U kunt het vertaalgedrag aanpassen door specifieke instructies aan het AI-model te geven. Als de prompt `%s` bevat, wordt dit vervangen door de naam van de doeltaal.

- **--xlate-context**=_text_

    Geef extra contextinformatie op die naar de vertaalmachine wordt gestuurd. Deze optie kan meerdere keren worden gebruikt om meerdere contextstrings te leveren. De contextinformatie helpt de vertaalmachine de achtergrond te begrijpen en nauwkeurigere vertalingen te produceren.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Aantal omringende vertaalde blokken dat als referentiecontext wordt meegegeven bij het opnieuw vertalen van gewijzigde blokken (standaard 2). De context omvat ook de ruwe brontekst rond het gewijzigde gebied (koppen, lijststructuur, bijschriften) en, indien beschikbaar, de vorige versie van de gewijzigde tekst die uit de cache is hersteld, zodat ongewijzigde formuleringen behouden blijven. Stel in op 0 om contextbewuste vertaling volledig uit te schakelen. Merk op dat elk gewijzigd gebied in een eigen API-aanroep wordt vertaald en dat de context tot ongeveer 8000 tekens aan de systeemprompt kan toevoegen, dus contextbewuste vertaling ruilt enige extra kosten in voor consistentie.

- **--xlate-cache-seed**=_file_

    Initialiseer de cache van een nieuw document vanuit het cachebestand van een ander document. Handig voor periodieke rapporten: vul de cache van het nieuwe nummer met die van het vorige nummer, zodat ongewijzigde alinea's niet opnieuw worden vertaald en bewerkte alinea's de formulering van het vorige nummer behouden. De seed wordt alleen gebruikt wanneer de doelcache leeg is; anders wordt deze genegeerd met een waarschuwing. Met de standaard `--xlate-cache=auto` houdt het opgeven van een seed ook in dat het cachebestand van het nieuwe document wordt aangemaakt.

- **--xlate-anonymize**=_file_

    Anonimiseer gevoelige strings voordat ze naar de vertaal-API worden verzonden, en herstel ze in de uitvoer. Het woordenlijstbestand geeft één item per invoer: in JSON (canoniek, door machines te genereren)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    of in een eenvoudige regelindeling (`category pattern`, `/.../` voor regex). Elk item wordt vervangen door een categorietag zoals `<person id=1 />`; dezelfde string krijgt altijd dezelfde tag, zodat het model kan bijhouden wie wie is. Onbekende JSON-velden worden genegeerd, zodat generatoren (bijv. een lokale LLM die entiteiten extraheert) hun eigen annotaties kunnen toevoegen. Categorie `lit` is gereserveerd. Lokale cachebestanden slaan nog steeds herstelde platte tekst op: het doel van verbergen is alleen API-verzending.

    Een woordenlijst kan worden gegenereerd door een extern hulpmiddel -- bijvoorbeeld een lokaal model dat gevoelige entiteiten extraheert:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Een UTF-8-BOM in het bestand wordt getolereerd. Waarden in de front-matter-regelindeling mogen alleen een afsluitende opmerking op hun eigen regel hebben, niet na de waarde.

- **--xlate-anonymize-mark**\[=_regex_\]

    Verzamel anonimiseringsitems uit inline markeringen in het document zelf. Markeer de eerste voorkomen zoals `{{ person("山田太郎") }}` en elke voorkomen van de string in het hele document wordt geanonimiseerd. De markering zelf blijft in de bron en in de vertaling staan, zodat een document ook kan worden verwerkt door een Jinja2-achtige macroprocessor (definieer de macro `person` om de naam af te drukken of te redigeren). Een aangepaste _regex_ moet benoemde captures `(?<category>...)` en `(?<text>...)` bevatten.

    Merk op dat bij een optie met een optionele waarde zoals deze, een volgend bestandsargument als de waarde zou worden opgevat: schrijf `--xlate-anonymize-mark=` (met een afsluitende `=`) wanneer u de standaardnotatie gebruikt.

    Alternatieve notaties kunnen worden geconfigureerd, bijvoorbeeld `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` voor `@@person:NAME@@`-achtige markeringen, of een HTML-commentaarvorm die onzichtbaar blijft in gerenderde Markdown. Markeringsregels worden per document verzameld: een string die in één invoerbestand is gemarkeerd, wordt niet verborgen in een ander bestand van dezelfde run (in tegenstelling tot front-matter-waarden, die zich over bestanden heen opstapelen).

- **--xlate-template**\[=_regex_\]

    Behandel sjabloonexpressies (standaard: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) als ondoorzichtige placeholders: instrueer het model om ze ongewijzigd te kopiëren en verifieer per blok dat het antwoord exact dezelfde expressies bevat, elk hetzelfde aantal keren. Hun volgorde mag veranderen, omdat vertaling ze legitiem kan herordenen om de woordvolgorde van de doeltaal te volgen. Een kapotte expressie breekt de uitvoering af; de cache wordt gecheckpoint en bevroren, zodat niets waarvoor is betaald verloren gaat.

    Merk op dat bij een optie met een optionele waarde zoals deze een volgend bestandsargument als de waarde zou worden genomen: schrijf `--xlate-template=` (met een afsluitende `=`) wanneer u de standaardnotatie gebruikt.

- **--xlate-frontmatter**

    Behandel een leidend `---` ... `---`-blok als YAML-front matter: sluit het uit van vertaling en van de fase-2-contextsegmenten, en voeg de platte `key: value`-waarden ervan toe aan de anonimiseringsregels (categorie `var`) als vangnet. Bij meerdere invoerbestanden worden de verzamelde waarden opgeteld (waarbij aan de kant van verhulling wordt vergist).

    Laat altijd een lege regel staan na de afsluitende `---`. Bij een alinea-achtig matchpatroon vormt front matter die direct in de hoofdtekst overgaat één overlappend blok dat de uitsluiting niet kan onderdrukken (in dat geval wordt een waarschuwing afgedrukt); de waarden worden nog steeds geanonimiseerd, maar de front matter zelf zou voor vertaling worden verzonden.

- **--xlate-glossary**=_glossary_

    Geef een woordenlijst-ID op die voor vertaling wordt gebruikt. Deze optie is alleen beschikbaar bij gebruik van de DeepL-engine. De woordenlijst-ID moet uit uw DeepL-account worden verkregen en zorgt voor consistente vertaling van specifieke termen.

- **--xlate-dryrun**

    Roep de vertaal-API niet aan; toon in plaats daarvan, via de voortgangsweergave, elke payload precies zoals die zou worden verzonden (na anonimisering en masking). Handig om te controleren wat de machine verlaat en om de kosten van een run te schatten.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Bekijk het vertaalresultaat in realtime in de STDERR-uitvoer. De `From`-payload wordt getoond zoals verzonden, na anonimisering en masking.

- **--xlate-stripe**

    Gebruik de module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) om het overeenkomende deel te tonen met zebra-achtige arcering. Dit is handig wanneer de overeenkomende delen rug-aan-rug zijn verbonden.

    Het kleurenpalet wordt geschakeld volgens de achtergrondkleur van de terminal. Als u het expliciet wilt opgeven, kunt u **--xlate-stripe-light** of **--xlate-stripe-dark** gebruiken.

- **--xlate-mask**

    Voer de maskeringsfunctie uit en geef de geconverteerde tekst weer zoals die is, zonder herstel.

- **--match-all**

    Stel de volledige tekst van het bestand in als doelgebied.

- **--lineify-cm**
- **--lineify-colon**

    In het geval van de formaten `cm` en `colon` wordt de output gesplitst en regel voor regel opgemaakt. Daarom kan, als slechts een deel van een regel moet worden vertaald, het verwachte resultaat niet worden verkregen. Deze filters herstellen output die is beschadigd door het vertalen van een deel van een regel naar normale, regel-voor-regel output.

    In de huidige implementatie worden, als meerdere delen van een regel worden vertaald, deze als zelfstandige regels uitgegeven.

# CACHE OPTIONS

De module **xlate** kan gecachete vertalingstekst per bestand opslaan en vóór uitvoering inlezen om de overhead van het vragen aan de server te elimineren. Met de standaardcache-strategie `auto` wordt cachedata alleen onderhouden wanneer het cachebestand voor het doelfile bestaat.

Gebruik **--xlate-cache=clear** om cachebeheer te initiëren of om alle bestaande cachedata op te schonen. Na eenmaal met deze optie te zijn uitgevoerd, wordt een nieuw cachebestand aangemaakt als er nog geen bestaat en daarna automatisch onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cachebestand aan en sluit af.

    - `always`, `yes`, `1`

        Houd de cache toch bij zolang het doel een normaal bestand is.

    - `clear`

        Maak eerst de cachedata leeg.

    - `never`, `no`, `0`

        Gebruik nooit een cachebestand, zelfs niet als het bestaat.

    - `accumulate`

        Standaard worden ongebruikte gegevens uit het cachebestand verwijderd. Als je ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan `accumulate`.
- **--xlate-update**

    Deze optie dwingt een update van het cachebestand af, zelfs als dat niet nodig is.

# COMMAND LINE INTERFACE

Je kunt deze module eenvoudig vanaf de commandoregel gebruiken met het commando `xlate` dat in de distributie is opgenomen. Zie de man-pagina `xlate` voor gebruik.

De `xlate`-opdracht ondersteunt GNU-stijl lange opties zoals `--to-lang`, `--from-lang`, `--engine` en `--file`. Gebruik `xlate -h` om alle beschikbare opties te zien.

Het commando `xlate` werkt samen met de Docker-omgeving, dus ook als je niets lokaal hebt geïnstalleerd, kun je het gebruiken zolang Docker beschikbaar is. Gebruik de optie `-D` of `-C`.

Docker-bewerkingen worden afgehandeld door [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), dat ook als zelfstandige opdracht kan worden gebruikt. De opdracht `dozo` ondersteunt het configuratiebestand `.dozorc` voor persistente containerinstellingen.

Omdat makefiles voor verschillende documentstijlen worden meegeleverd, is vertalen naar andere talen mogelijk zonder speciale specificatie. Gebruik de optie `-M`.

Je kunt ook de Docker- en `make`-opties combineren zodat je `make` in een Docker-omgeving kunt uitvoeren.

Uitvoeren zoals `xlate -C` start een shell met de huidige werkende git-repository gemount.

Lees het Japanse artikel in de sectie ["SEE ALSO"](#see-also) voor details.

# EMACS

Laad het bestand `xlate.el` in de repository om het commando `xlate` vanuit de Emacs-editor te gebruiken. De functie `xlate-region` vertaalt de opgegeven regio. De standaardtaal is `EN-US` en je kunt een taal opgeven door het met een prefix-argument aan te roepen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel je authenticatiesleutel in voor de DeepL-service.

- OPENAI\_API\_KEY

    OpenAI-authenticatiesleutel, gebruikt door de legacy **gpty**-engines. De op `llm` gebaseerde **gpt5**-engine leest deze variabele ook, maar sleutels die met `llm keys set openai` zijn opgeslagen werken ook.

- GREPLE\_XLATE\_CACHE

    Stel de standaard cachestrategie in (zie ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Installeer het commandoregelhulpmiddel voor de engine die je gebruikt: `llm` voor de **gpt5**-engine, `deepl` voor DeepL, `gpty` voor de legacy GPT-engines.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Generieke Docker-runner die door xlate wordt gebruikt voor containeroperaties

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de handleiding **greple** voor details over het doelsjabloon. Gebruik de opties **--inside**, **--outside**, **--include**, **--exclude** om het matchgebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Je kunt de module `-Mupdate` gebruiken om bestanden te wijzigen op basis van het resultaat van het commando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het conflictmarkeerformaat naast elkaar te tonen met de optie **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe**-module gebruikt met de optie **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-containerimage.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    De bibliotheek `getoptlong.sh` die wordt gebruikt voor het parseren van opties in het script `xlate` en [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Het `llm`-commando dat door de **gpt5**-engine wordt gebruikt om toegang te krijgen tot LLM-modellen.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-bibliotheek en CLI-commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI commandoregelinterface

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-module om alleen de noodzakelijke delen te vertalen en te vervangen met de DeepL-API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Documenten genereren in 15 talen met de DeepL-API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische vertaal-Docker-omgeving met DeepL-API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
