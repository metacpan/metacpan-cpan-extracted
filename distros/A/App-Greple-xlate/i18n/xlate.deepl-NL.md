# NAME

App::Greple::xlate - vertaalondersteuningsmodule voor greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate**-module zoekt de gewenste tekstblokken en vervangt deze door de vertaalde tekst. De primaire engine is GPT-5.5 (`llm/gpt5.pm`), die het [llm](https://llm.datasette.io/)-commando aanroept; DeepL (`deepl.pm`) en oudere, op **gpty** gebaseerde engines zijn ook inbegrepen.

Vertalingen worden per bestand in de cache opgeslagen, dus het opnieuw uitvoeren van een commando kost niets voor ongewijzigde tekst. Wanneer een document wordt bewerkt, worden alleen de gewijzigde alinea’s opnieuw naar de API verzonden; een contextbewuste engine ontvangt ook de omringende vertalingen, de onbewerkte brontekst rondom de wijziging en de vorige versie van de bewerkte alinea, zodat de nieuwe vertaling de gevestigde bewoording behoudt (zie **--xlate-context-window**). Gevoelige tekenreeksen kunnen vóór verzending worden verborgen (zie ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Als u normale tekstblokken wilt vertalen in een document dat is geschreven in de pod-stijl van Perl, gebruikt u het **greple**-commando met de `--xlate-engine gpt5`- en `perl`-module als volgt:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In deze opdracht betekent patroontekenreeks `^([\w\pP].*\n)+` opeenvolgende regels die beginnen met alfanumerieke letters en leestekens. Deze opdracht laat het te vertalen gebied gemarkeerd zien. Optie **--all** wordt gebruikt om de volledige tekst te produceren.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Voeg vervolgens de optie `--xlate` toe om het geselecteerde gebied te vertalen. Vervolgens worden de gewenste secties gevonden en vervangen door de uitvoer van de vertaalengine.

Standaard wordt originele en vertaalde tekst afgedrukt in het "conflict marker" formaat dat compatibel is met [git(1)](http://man.he.net/man1/git). Door `ifdef` formaat te gebruiken, kun je gemakkelijk het gewenste deel krijgen met [unifdef(1)](http://man.he.net/man1/unifdef) commando. Uitvoerformaat kan gespecificeerd worden met **--xlate-format** optie.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Als je de hele tekst wilt vertalen, gebruik dan de optie **--match-all**. Dit is een snelkoppeling om het patroon `(?s).+` op te geven dat overeenkomt met de hele tekst.

Gegevens in conflictmarkerformaat kunnen naast elkaar worden bekeken met het [sdif](https://metacpan.org/pod/App%3A%3Asdif) commando met de `-V` optie. Omdat het geen zin heeft om per string te vergelijken, wordt de optie `--no-cdif` aanbevolen. Als je de tekst niet hoeft te kleuren, geef dan `--no-textcolor` op (of `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

De verwerking wordt gedaan in gespecificeerde eenheden, maar in het geval van een opeenvolging van meerdere regels niet-lege tekst, worden ze samen omgezet in een enkele regel. Deze bewerking wordt als volgt uitgevoerd:

- Verwijder witruimte aan het begin en einde van elke regel.
- Als een regel eindigt met een leesteken over de hele breedte, aaneenschakelen met de volgende regel.
- Als een regel eindigt met een teken van volledige breedte en de volgende regel begint met een teken van volledige breedte, worden de regels aan elkaar gekoppeld.
- Als het einde of het begin van een regel geen teken voor de volledige breedte is, voeg ze dan samen door een spatieteken in te voegen.

Cachegegevens worden beheerd op basis van de genormaliseerde tekst, dus zelfs als er wijzigingen worden aangebracht die geen invloed hebben op de normalisatieresultaten, zullen de vertaalgegevens in de cache nog steeds effectief zijn.

Dit normalisatieproces wordt alleen uitgevoerd voor het eerste (0e) en even genummerde patroon. Dus als twee patronen als volgt worden gespecificeerd, wordt de tekst die overeenkomt met het eerste patroon verwerkt na normalisatie en wordt er geen normalisatieproces uitgevoerd op de tekst die overeenkomt met het tweede patroon.

    greple -Mxlate -E normalized -E not-normalized

Gebruik daarom het eerste patroon voor tekst die verwerkt moet worden door meerdere regels samen te voegen tot een enkele regel, en gebruik het tweede patroon voor voorgeformatteerde tekst. Als er geen tekst is om mee te matchen in het eerste patroon, gebruik dan een patroon dat nergens mee overeenkomt, zoals `(?!)`.

# MASKING

Soms zijn er delen van tekst die je niet vertaald wilt hebben. Bijvoorbeeld tags in markdown-bestanden. DeepL stelt voor dat in dergelijke gevallen het deel van de tekst dat moet worden uitgesloten, wordt geconverteerd naar XML-tags, wordt vertaald en vervolgens wordt hersteld nadat de vertaling is voltooid. Om dit te ondersteunen, is het mogelijk om de delen te specificeren die moeten worden gemaskeerd van vertaling.

    --xlate-setopt maskfile=MASKPATTERN

Hierdoor wordt elke regel van het bestand `MASKPATTERN` geïnterpreteerd als een reguliere expressie, worden strings die hiermee overeenkomen vertaald en wordt na verwerking de oorspronkelijke tekst hersteld. Regels die beginnen met `#` worden genegeerd.

Complexe patronen kunnen over meerdere regels worden geschreven met een door een backslash geëscapeerde regeleinde.

Hoe de tekst door het maskeren wordt omgezet, kun je zien met de optie **--xlate-mask**.

Door maskering wordt markup beschermd tegen vertaling. Om gevoelige tekenreeksen te verbergen voor de vertaaldienst zelf, zie ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); beide kunnen samen worden gebruikt.

Deze interface is experimenteel en kan in de toekomst veranderen.

# ANONYMIZATION AND TEMPLATES

Gevoelige tekenreeksen kunnen worden verborgen voordat ze naar de vertaal-API worden verzonden en in de uitvoer weer worden weergegeven. Er zijn drie bronnen voor anonimiseringsregels beschikbaar: een woordenboekbestand (**--xlate-anonymize**), inline-markeringen in het document zelf (**--xlate-anonymize-mark**) en YAML-frontmatter-waarden (**--xlate-frontmatter**). Elke tekenreeks wordt tijdens de overdracht vervangen door een categorietag, zoals `<person id=1 />`. Het verbergen geldt alleen voor de API-overdracht: lokale cachebestanden slaan de herstelde platte tekst op. Gebruik **--xlate-dryrun** om precies te controleren wat er zou worden verzonden.

Voor formulierdocumenten (kwartaalrapporten en dergelijke) definieer je de actoren vooraf en verwijs je ernaar in de hoofdtekst:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Vertaal het sjabloon één keer per taal met `--xlate-template` (en `--xlate-frontmatter` wanneer de waarden in het bestand worden bewaard), en geef vervolgens elk geval weer met **pandoc-embedz** in de standalone-modus — waarden onder `global:` in een externe configuratie bereiken de vertaal-API helemaal niet:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Voor inline-markeringen zorgt het opgeven van een macrodefinitieconfiguratie ervoor dat dezelfde vertaalde sjabloon ofwel de echte namen ofwel een geredigeerde versie weergeeft:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Sluit embedz-blokken uit van vertaling wanneer een document deze bevat:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Roep het vertaalproces op voor elk gematcht gebied.

    Zonder deze optie gedraagt **greple** zich als een normaal zoekcommando. U kunt dus controleren welk deel van het bestand zal worden vertaald voordat u het eigenlijke werk uitvoert.

    Commandoresultaat gaat naar standaard out, dus redirect naar bestand indien nodig, of overweeg [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module te gebruiken.

    Optie **--xlate** roept **--xlate-kleur** aan met **--color=never** optie.

    Met de optie **--xlate-fold** wordt geconverteerde tekst gevouwen met de opgegeven breedte. De standaardbreedte is 70 en kan worden ingesteld met de optie **--xlate-fold-width**. Vier kolommen zijn gereserveerd voor inloopoperaties, zodat elke regel maximaal 74 tekens kan bevatten.

- **--xlate-engine**=_engine_

    Hiermee wordt de te gebruiken vertaalengine gespecificeerd.

    Op dit moment zijn de volgende engines beschikbaar

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Engine-modules worden eerst doorzocht in backend-naamruimten (`llm`, daarna `gpty`), vervolgens direct onder `App::Greple::xlate`. Dus `gpt5` laadt `App::Greple::xlate::llm::gpt5`, dat het `llm`-commando aanroept, terwijl `gpt4o` terugvalt op `App::Greple::xlate::gpty::gpt4o`. Gebruik `--xlate-setopt backend=gpty` om een specifieke backend te forceren.

- **--xlate-labor**
- **--xlabor**

    In plaats van de vertaalmachine op te roepen, wordt er van je verwacht dat je zelf aan de slag gaat. Na het voorbereiden van tekst die vertaald moet worden, worden ze gekopieerd naar het klembord. Er wordt van je verwacht dat je ze op het formulier plakt, het resultaat naar het klembord kopieert en op return drukt.

- **--xlate-to** (Default: `EN-US`)

    Geef de doeltaal op. LLM-engines accepteren elke taalnaam of -code die het model begrijpt; deze wordt in de vertaalprompt geïnterpoleerd. Je kunt de beschikbare talen opvragen met het `deepl languages`-commando wanneer je de **DeepL**-engine gebruikt.

- **--xlate-from** (Default: `ORIGINAL`)

    Label dat wordt gebruikt voor de oorspronkelijke tekst in de uitvoerformaten `conflict`, `colon` en `ifdef`. Bij de **DeepL**-engine wordt ook een niet-standaardwaarde doorgegeven als brontaal.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specificeer het uitvoerformaat voor originele en vertaalde tekst.

    De volgende indelingen anders dan `xtxt` gaan ervan uit dat het te vertalen deel een verzameling regels is. In feite is het mogelijk om slechts een deel van een regel te vertalen, maar het specificeren van een andere opmaak dan `xtxt` zal geen zinvolle resultaten opleveren.

    - **conflict**, **cm**

        Originele en geconverteerde tekst worden afgedrukt in [git(1)](http://man.he.net/man1/git) conflictmarkeerder formaat.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        U kunt het originele bestand herstellen met de volgende [sed(1)](http://man.he.net/man1/sed) opdracht.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        De originele en vertaalde tekst worden uitgevoerd in de aangepaste containerstijl van markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Bovenstaande tekst wordt vertaald naar het volgende in HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Het aantal dubbele punten is standaard 7. Als je een dubbele punt reeks specificeert zoals `:::::`, wordt deze gebruikt in plaats van 7 dubbele punten.

    - **ifdef**

        Originele en geconverteerde tekst worden afgedrukt in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formaat.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        U kunt alleen Japanse tekst terughalen met het commando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Originele en geconverteerde tekst worden gescheiden afgedrukt door een enkele lege regel. Voor `space+` wordt ook een nieuwe regel na de geconverteerde tekst afgedrukt.

    - **xtxt**

        Als het formaat `xtxt` (vertaalde tekst) of onbekend is, wordt alleen vertaalde tekst afgedrukt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geef de maximale lengte op van de tekst die in één keer naar de API mag worden verzonden. De standaardwaarde 0 betekent de eigen limiet van de engine: voor de gratis DeepL-accountservice is dat 128K voor de API (**--xlate**) en 5000 voor de klembordinterface (**--xlate-labor**). U kunt deze waarden mogelijk wijzigen als u de Pro-service gebruikt.

- **--xlate-maxline**=_n_ (Default: 0)

    Geef het maximum aantal regels tekst op dat in één keer naar de API moet worden gestuurd.

    Stel deze waarde in op 1 als je één regel per keer wilt vertalen. Deze optie heeft voorrang op de `--xlate-maxlen` optie.

- **--xlate-prompt**=_text_

    Geef een aangepaste prompt op die naar de vertaalengine moet worden verzonden. Deze optie is beschikbaar voor de LLM-engines (`gpt3`, `gpt4o`, `gpt5`), maar niet voor DeepL. U kunt het vertaalgedrag aanpassen door specifieke instructies aan het AI-model te geven. Als de prompt `%s` bevat, wordt dit vervangen door de naam van de doeltaal.

- **--xlate-context**=_text_

    Geef aanvullende contextinformatie op die naar de vertaalmachine moet worden gestuurd. Deze optie kan meerdere keren worden gebruikt om meerdere contextstrings op te geven. De contextinformatie helpt de vertaalmachine om de achtergrond te begrijpen en nauwkeurigere vertalingen te produceren.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Aantal omliggende vertaalde blokken die als referentiecontext worden doorgegeven bij het opnieuw vertalen van gewijzigde blokken (standaard 2). De context omvat ook de onbewerkte brontekst rondom het gewijzigde gebied (koppen, lijststructuur, bijschriften) en, indien beschikbaar, de vorige versie van de gewijzigde tekst die uit de cache is opgehaald, zodat ongewijzigde bewoordingen behouden blijven. Stel deze waarde in op 0 om contextbewuste vertaling volledig uit te schakelen. Houd er rekening mee dat elk gewijzigd gebied in een eigen API-aanroep wordt vertaald en dat de context tot ongeveer 8000 tekens aan de systeemprompt kan toevoegen; contextbewuste vertaling brengt dus enige extra kosten met zich mee in ruil voor consistentie.

- **--xlate-cache-seed**=_file_

    Initialiseer de cache van een nieuw document vanuit het cachebestand van een ander document. Handig voor periodieke rapporten: vul de cache van de nieuwe uitgave aan met die van de vorige uitgave, zodat ongewijzigde alinea’s niet opnieuw worden vertaald en bewerkte alinea’s de formulering van de vorige uitgave behouden. De seed wordt alleen gebruikt als de doelcache leeg is; anders wordt deze genegeerd en wordt er een waarschuwing gegeven. Met de standaardinstelling `--xlate-cache=auto` houdt het opgeven van een seed ook in dat het cachebestand van het nieuwe document wordt aangemaakt.

- **--xlate-anonymize**=_file_

    Anonimiseer gevoelige tekenreeksen voordat ze naar de vertaal-API worden verzonden, en herstel ze in de uitvoer. Het woordenboekbestand bevat één vermelding per item: in JSON (canonisch, machinaal genereerbaar)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    of in een eenvoudig regelformaat (`category pattern`, `/.../` voor regex). Elk item wordt vervangen door een categorietag zoals `<person id=1 />`; dezelfde tekenreeks krijgt altijd dezelfde tag, zodat het model kan bijhouden wie wie is. Onbekende JSON-velden worden genegeerd, zodat generatoren (bijv. een lokale LLM die entiteiten extraheert) hun eigen annotaties kunnen toevoegen. Categorie `lit` is gereserveerd. Lokale cachebestanden slaan nog steeds de herstelde platte tekst op: het verbergen is uitsluitend bedoeld voor API-overdracht.

    Een woordenboek kan worden gegenereerd door een externe tool – bijvoorbeeld een lokaal model dat gevoelige entiteiten extraheert:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Een UTF-8 BOM in het bestand wordt getolereerd. Waarden in het ‘front matter’-regelformaat mogen alleen een afsluitende opmerking op hun eigen regel bevatten, niet na de waarde.

- **--xlate-anonymize-mark**\[=_regex_\]

    Verzamel anonimiseringsvermeldingen uit inline-markeringen in het document zelf. Markeer de eerste keer dat de tekenreeks voorkomt als `{{ person("山田太郎") }}` en elke keer dat de tekenreeks in het hele document voorkomt, wordt deze geanonimiseerd. De markering zelf blijft in de bron en in de vertaling staan, zodat een document ook kan worden verwerkt door een Jinja2-achtige macroprocessor (definieer de `person`-macro om de naam af te drukken of te redigeren). Een aangepaste _regex_ moet de benoemde captures `(?<category>...)` en `(?<text>...)` bevatten.

    Merk op dat bij een optie met een optionele waarde zoals deze, een volgend bestandsargument als waarde wordt beschouwd: schrijf `--xlate-anonymize-mark=` (met een afsluitende `=`) bij gebruik van de standaardnotatie.

    Alternatieve notaties kunnen worden geconfigureerd, bijvoorbeeld `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` voor markeringen in de stijl van `@@person:NAME@@`, of een HTML-commentaarvorm die onzichtbaar blijft in weergegeven Markdown. Markeringsregels worden per document verzameld: een tekenreeks die in één invoerbestand is gemarkeerd, wordt niet verborgen in een ander bestand van dezelfde run (in tegenstelling tot front-matter-waarden, die over bestanden heen worden opgeteld).

- **--xlate-template**\[=_regex_\]

    Behandel sjabloonuitdrukkingen (standaard: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) als ondoorzichtige plaatshouders: geef het model de opdracht om ze ongewijzigd te kopiëren en controleer per blok of het antwoord precies dezelfde uitdrukkingen bevat, elk even vaak. Hun volgorde kan veranderen, aangezien de vertaling ze terecht herschikt om de woordvolgorde van de doeltaal te volgen. Een ongeldige uitdrukking breekt de run af; de cache wordt vastgelegd en bevroren, zodat niets waarvoor betaald is, verloren gaat.

    Merk op dat bij een optie met een optionele waarde zoals deze, een volgend bestandsargument als de waarde zou worden beschouwd: schrijf `--xlate-template=` (met een afsluitend `=`) bij gebruik van de standaardnotatie.

- **--xlate-frontmatter**

    Behandel een inleidend `---` ... `---`-blok als YAML-frontmatter: sluit het uit van de vertaling en van de fase-2-contextfragmenten, en voeg de platte `key: value`-waarden ervan toe aan de anonimiseringsregels (categorie `var`) als vangnet. Bij meerdere invoerbestanden worden de verzamelde waarden opgeteld (waarbij het zekere voor het onzekere wordt genomen).

    Laat altijd een lege regel achter na de afsluitende `---`. Bij een overeenkomend patroon in paragraafstijl vormt front matter dat direct overgaat in de hoofdtekst één blok dat de uitsluiting niet kan onderdrukken (in dat geval wordt een waarschuwing weergegeven); de waarden worden nog steeds geanonimiseerd, maar de voorpagina zelf zou voor vertaling worden verzonden.

- **--xlate-glossary**=_glossary_

    Geef een woordenlijst-ID op die moet worden gebruikt voor vertaling. Deze optie is alleen beschikbaar wanneer je de DeepL engine gebruikt. De woordenlijst-ID moet verkregen worden via je DeepL account en zorgt voor een consistente vertaling van specifieke termen.

- **--xlate-dryrun**

    Roep de vertaal-API niet aan; toon in plaats daarvan via de voortgangsbalk elke payload precies zoals deze zou worden verzonden (na anonimisering en maskering). Handig om te controleren wat de machine verlaat en om de kosten van een vertaalrun in te schatten.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Bekijk het vertaalresultaat in realtime in de STDERR-uitvoer. De `From`-payload wordt weergegeven zoals deze wordt verzonden, na anonimisering en maskering.

- **--xlate-stripe**

    Gebruik de module [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) om het gematchte deel weer te geven met zebrastrepen. Dit is nuttig wanneer de gematchte delen rug-aan-rug verbonden zijn.

    Het kleurenpalet wordt omgeschakeld volgens de achtergrondkleur van de terminal. Als je dit expliciet wilt specificeren, kun je **--xlate-stripe-light** of **--xlate-stripe-dark** gebruiken.

- **--xlate-mask**

    Voer de maskeerfunctie uit en geef de geconverteerde tekst weer zoals hij is, zonder restauratie.

- **--match-all**

    Stel de hele tekst van het bestand in als doelgebied.

- **--lineify-cm**
- **--lineify-colon**

    In het geval van de `cm` en `colon` opmaak wordt de uitvoer regel voor regel opgesplitst en opgemaakt. Daarom kan het verwachte resultaat niet worden verkregen als slechts een deel van een regel moet worden vertaald. Deze filters herstellen uitvoer die beschadigd is door het vertalen van een deel van een regel naar normale regel-voor-regel uitvoer.

    In de huidige implementatie, als meerdere delen van een regel worden vertaald, worden ze uitgevoerd als onafhankelijke regels.

# CACHE OPTIONS

De module **xlate** kan de tekst van de vertaling voor elk bestand in de cache opslaan en lezen vóór de uitvoering om de overhead van het vragen aan de server te elimineren. Met de standaard cache strategie `auto`, onderhoudt het alleen cache gegevens wanneer het cache bestand bestaat voor het doelbestand.

Gebruik **--xlate-cache=clear** om cachebeheer te starten of om alle bestaande cachegegevens op te ruimen. Eenmaal uitgevoerd met deze optie, zal een nieuw cachebestand worden aangemaakt als er geen bestaat en daarna automatisch worden onderhouden.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Onderhoud het cachebestand als het bestaat.

    - `create`

        Maak een leeg cache bestand en sluit af.

    - `always`, `yes`, `1`

        Cache-bestand toch behouden voor zover het doelbestand een normaal bestand is.

    - `clear`

        Wis eerst de cachegegevens.

    - `never`, `no`, `0`

        Cache-bestand nooit gebruiken, zelfs niet als het bestaat.

    - `accumulate`

        Standaard worden ongebruikte gegevens uit het cachebestand verwijderd. Als u ze niet wilt verwijderen en in het bestand wilt houden, gebruik dan `accumuleren`.
- **--xlate-update**

    Deze optie dwingt om het cachebestand bij te werken, zelfs als dat niet nodig is.

# COMMAND LINE INTERFACE

Je kunt deze module eenvoudig vanaf de commandoregel gebruiken met het `xlate` commando dat bij de distributie zit. Zie de `xlate` man pagina voor het gebruik.

Het `xlate` commando ondersteunt GNU-stijl lange opties zoals `--to-lang`, `--from-lang`, `--engine`, en `--file`. Gebruik `xlate -h` om alle beschikbare opties te zien.

Het `xlate` commando werkt samen met de Docker omgeving, dus zelfs als je niets geïnstalleerd hebt, kun je het gebruiken zolang Docker beschikbaar is. Gebruik de optie `-D` of `-C`.

Docker-operaties worden afgehandeld door [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), dat ook als zelfstandig commando kan worden gebruikt. Het `dozo` commando ondersteunt het `.dozorc` configuratiebestand voor persistente containerinstellingen.

Omdat er makefiles voor verschillende documentstijlen worden meegeleverd, is vertaling naar andere talen mogelijk zonder speciale specificaties. Gebruik de optie `-M`.

Je kunt ook de Docker en `make` opties combineren, zodat je `make` in een Docker omgeving kunt draaien.

Uitvoeren als `xlate -C` zal een shell starten met de huidige werkende git repository aangekoppeld.

Lees het Japanse artikel in de ["SEE ALSO"](#see-also) sectie voor meer informatie.

# EMACS

Laad het `xlate.el` bestand in het archief om het `xlate` commando te gebruiken vanuit de Emacs editor. `xlate-region` functie vertaalt de gegeven regio. De standaardtaal is `EN-US` en u kunt de taal specificeren met het prefix argument.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Stel uw authenticatiesleutel in voor DeepL service.

- OPENAI\_API\_KEY

    OpenAI-authenticatiesleutel, gebruikt door de oudere **gpty**-engines. De op `llm` gebaseerde **gpt5**-engine leest deze variabele ook, maar sleutels die met `llm keys set openai` zijn opgeslagen, werken eveneens.

- GREPLE\_XLATE\_CACHE

    Stel de standaardcachestrategie in (zie ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Installeer het opdrachtregelprogramma voor de engine die je gebruikt: `llm` voor de **gpt5**-engine, `deepl` voor DeepL, `gpty` voor de verouderde GPT-engines.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Generieke Docker runner gebruikt door xlate voor containeroperaties

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Zie de **greple** handleiding voor de details over het doeltekstpatroon. Gebruik **--inside**, **--outside**, **--include**, **--exclude** opties om het overeenkomende gebied te beperken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    U kunt de module `-Mupdate` gebruiken om bestanden te wijzigen door het resultaat van het commando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gebruik **sdif** om het formaat van de conflictmarkering naast de optie **-V** te tonen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** module gebruik door **--xlate-stripe** optie.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker containerafbeelding.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    De `getoptlong.sh` bibliotheek gebruikt voor optie parsing in het `xlate` script en [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Het `llm`-commando dat door de **gpt5**-engine wordt gebruikt om toegang te krijgen tot LLM-modellen.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python bibliotheek en CLI commando.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Bibliotheek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI opdrachtregelinterface

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple module om alleen de benodigde onderdelen te vertalen en te vervangen met DeepL API (in het Japans)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Documenten genereren in 15 talen met DeepL API-module (in het Japans)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatisch vertaalde Docker-omgeving met DeepL API (in het Japans)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
