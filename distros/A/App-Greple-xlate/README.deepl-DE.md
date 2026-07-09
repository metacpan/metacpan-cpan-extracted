# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für Greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** Das Modul sucht die gewünschten Textblöcke und ersetzt sie durch den übersetzten Text. Die primäre Engine ist GPT-5.5 (`llm/gpt5.pm`), die den Befehl [llm](https://llm.datasette.io/) aufruft; DeepL (`deepl.pm`) und ältere, auf **gpty** basierende Engines sind ebenfalls enthalten.

Übersetzungen werden pro Datei zwischengespeichert, sodass die erneute Ausführung eines Befehls für unveränderten Text keine Kosten verursacht. Wenn ein Dokument bearbeitet wird, werden nur die geänderten Absätze erneut an die API gesendet; eine kontextbezogene Engine erhält zudem die umgebenden Übersetzungen, den Rohquelltext rund um die Änderung sowie die vorherige Version des bearbeiteten Absatzes, sodass die neue Übersetzung die etablierte Formulierung beibehält (siehe **--xlate-context-window**). Sensible Zeichenfolgen können vor der Übertragung ausgeblendet werden (siehe ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Wenn Sie normale Textblöcke in einem Dokument übersetzen möchten, das im Perl-Pod-Stil verfasst ist, verwenden Sie den Befehl **greple** zusammen mit den Modulen `--xlate-engine gpt5` und `perl` wie folgt:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In diesem Befehl bedeutet die Zeichenkette `^([\w\pP].*\n)+` aufeinanderfolgende Zeilen, die mit einem alphanumerischen und einem Interpunktionsbuchstaben beginnen. Mit diesem Befehl wird der zu übersetzende Bereich hervorgehoben dargestellt. Die Option **--all** wird verwendet, um den gesamten Text zu übersetzen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Fügen Sie anschließend die Option `--xlate` hinzu, um den ausgewählten Bereich zu übersetzen. Daraufhin werden die gewünschten Abschnitte gefunden und durch die Ausgabe der Übersetzungs-Engine ersetzt.

Standardmäßig werden der ursprüngliche und der übersetzte Text im Format "Konfliktmarkierung" ausgegeben, das mit [git(1)](http://man.he.net/man1/git) kompatibel ist. Wenn Sie das Format `ifdef` verwenden, können Sie den gewünschten Teil mit dem Befehl [unifdef(1)](http://man.he.net/man1/unifdef) leicht erhalten. Das Ausgabeformat kann mit der Option **--xlate-format** festgelegt werden.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Wenn Sie den gesamten Text übersetzen wollen, verwenden Sie die Option **--match-all**. Dies ist eine Abkürzung zur Angabe des Musters `(?s).+`, das auf den gesamten Text passt.

Daten im Konfliktmarkerformat können mit dem Befehl [sdif](https://metacpan.org/pod/App%3A%3Asdif) und der Option `-V` nebeneinander angezeigt werden. Da es keinen Sinn macht, die Daten pro Zeichenfolge zu vergleichen, wird die Option `--no-cdif` empfohlen. Wenn Sie den Text nicht einfärben müssen, geben Sie `--no-textcolor` (oder `--no-tc`) an.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Die Verarbeitung erfolgt in den angegebenen Einheiten, aber im Falle einer Folge von mehreren nicht leeren Textzeilen werden diese zusammen in eine einzige Zeile umgewandelt. Dieser Vorgang wird wie folgt durchgeführt:

- Am Anfang und am Ende jeder Zeile wird der Leerraum entfernt.
- Wenn eine Zeile mit einem Satzzeichen in voller Breite endet, wird sie mit der nächsten Zeile verkettet.
- Wenn eine Zeile mit einem Zeichen voller Breite endet und die nächste Zeile mit einem Zeichen voller Breite beginnt, werden die Zeilen verkettet.
- Wenn entweder das Ende oder der Anfang einer Zeile kein Zeichen mit voller Breite ist, verketten Sie sie durch Einfügen eines Leerzeichens.

Die Cache-Daten werden auf der Grundlage des normalisierten Textes verwaltet. Selbst wenn Änderungen vorgenommen werden, die sich nicht auf die Normalisierungsergebnisse auswirken, sind die im Cache gespeicherten Übersetzungsdaten weiterhin gültig.

Dieser Normalisierungsprozess wird nur für das erste (0.) und geradzahlige Muster durchgeführt. Wenn also zwei Muster wie folgt angegeben werden, wird der Text, der dem ersten Muster entspricht, nach der Normalisierung verarbeitet, und für den Text, der dem zweiten Muster entspricht, wird kein Normalisierungsprozess durchgeführt.

    greple -Mxlate -E normalized -E not-normalized

Verwenden Sie daher das erste Muster für Text, der durch die Kombination mehrerer Zeilen in einer einzigen Zeile verarbeitet werden soll, und das zweite Muster für vorformatierten Text. Wenn das erste Muster keinen Text enthält, der übereinstimmt, verwenden Sie ein Muster, das auf nichts zutrifft, wie z. B. `(?!)`.

# MASKING

Gelegentlich gibt es Textteile, die Sie nicht übersetzt haben möchten. Zum Beispiel Tags in Markdown-Dateien. DeepL schlägt vor, in solchen Fällen den auszuschließenden Teil des Textes in XML-Tags umzuwandeln, zu übersetzen und dann nach Abschluss der Übersetzung wiederherzustellen. Um dies zu unterstützen, ist es möglich, die Teile anzugeben, die von der Übersetzung ausgenommen werden sollen.

    --xlate-setopt maskfile=MASKPATTERN

Dadurch wird jede Zeile der Datei `MASKPATTERN` als regulärer Ausdruck interpretiert, übereinstimmende Zeichenfolgen werden übersetzt und nach der Verarbeitung wieder zurückgesetzt. Zeilen, die mit `#` beginnen, werden ignoriert.

Komplexe Muster können über mehrere Zeilen hinweg geschrieben werden, wobei Zeilenumbrüche mit einem Backslash maskiert werden.

Wie der Text durch die Maskierung umgewandelt wird, können Sie mit der Option **--xlate-mask** sehen.

Durch Maskierung wird das Markup vor der Übersetzung geschützt. Um sensible Zeichenfolgen vor dem Übersetzungsdienst selbst zu verbergen, siehe ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); beide Funktionen können zusammen verwendet werden.

Diese Schnittstelle ist experimentell und kann sich in Zukunft noch ändern.

# ANONYMIZATION AND TEMPLATES

Sensible Zeichenfolgen können vor dem Senden an die Übersetzungs-API ausgeblendet und in der Ausgabe wiederhergestellt werden. Es stehen drei Quellen für Anonymisierungsregeln zur Verfügung: eine Wörterbuchdatei (**--xlate-anonymize**), Inline-Markierungen im Dokument selbst (**--xlate-anonymize-mark**) und YAML-Front-Matter-Werte (**--xlate-frontmatter**). Jede Zeichenfolge wird während der Übertragung durch ein Kategorie-Tag wie `<person id=1 />` ersetzt. Die Ausblendung gilt nur für die API-Übertragung: Lokale Cache-Dateien speichern den wiederhergestellten Klartext. Verwenden Sie **--xlate-dryrun**, um genau zu überprüfen, was übertragen würde.

Bei Formulardokumenten (Quartalsberichte und Ähnliches) definieren Sie die Akteure im Vorfeld und verweisen im Hauptteil darauf:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Übersetzen Sie die Vorlage einmal pro Sprache mit `--xlate-template` (und `--xlate-frontmatter`, wenn die Werte in der Datei gespeichert werden), und rendern Sie dann jeden Fall im eigenständigen Modus mit **pandoc-embedz** – Werte unter `global:` in einer externen Konfiguration erreichen die Übersetzungs-API überhaupt nicht:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Bei Inline-Markierungen sorgt die Bereitstellung einer Makrodefinitionskonfiguration dafür, dass dieselbe übersetzte Vorlage entweder die tatsächlichen Namen oder eine geschwärzte Version rendert:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Schließen Sie „embedz“-Blöcke von der Übersetzung aus, wenn ein Dokument diese enthält:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Rufen Sie den Übersetzungsprozess für jeden übereinstimmenden Bereich auf.

    Ohne diese Option verhält sich **greple** wie ein normaler Suchbefehl. Sie können also überprüfen, welcher Teil der Datei Gegenstand der Übersetzung sein wird, bevor Sie die eigentliche Arbeit aufrufen.

    Das Ergebnis des Befehls wird im Standard-Output ausgegeben, also leiten Sie es bei Bedarf in eine Datei um oder verwenden Sie das Modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Die Option **--xlate** ruft die Option **--xlate-color** mit der Option **--color=never** auf.

    Mit der Option **--xlate-fold** wird der konvertierte Text um die angegebene Breite gefaltet. Die Standardbreite ist 70 und kann mit der Option **--xlate-fold-width** eingestellt werden. Vier Spalten sind für den Einlaufvorgang reserviert, so dass jede Zeile maximal 74 Zeichen enthalten kann.

- **--xlate-engine**=_engine_

    Legt die zu verwendende Übersetzungs-Engine fest.

    Zur Zeit sind die folgenden Engines verfügbar

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Engine-Module werden zuerst in Backend-Namespaces durchsucht (`llm`, dann `gpty`), anschließend direkt unter `App::Greple::xlate`. So lädt `gpt5` `App::Greple::xlate::llm::gpt5`, das den Befehl `llm` aufruft, während `gpt4o` auf `App::Greple::xlate::gpty::gpt4o` zurückgreift. Verwenden Sie `--xlate-setopt backend=gpty`, um ein bestimmtes Backend zu erzwingen.

- **--xlate-labor**
- **--xlabor**

    Anstatt die Übersetzungsmaschine aufzurufen, wird von Ihnen erwartet, dass Sie für arbeiten. Nachdem Sie den zu übersetzenden Text vorbereitet haben, wird er in die Zwischenablage kopiert. Es wird erwartet, dass Sie sie in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und die Eingabetaste drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. LLM-Engines akzeptieren jeden Sprachnamen oder -code, den das Modell versteht; dieser wird in die Übersetzungsaufforderung eingefügt. Die verfügbaren Sprachen können Sie mit dem Befehl `deepl languages` abrufen, wenn Sie die Engine **DeepL** verwenden.

- **--xlate-from** (Default: `ORIGINAL`)

    Bezeichnung, die für den Originaltext in den Ausgabeformaten `conflict`, `colon` und `ifdef` verwendet wird. Bei der **DeepL**-Engine wird ein vom Standard abweichender Wert ebenfalls als Ausgangssprache übergeben.

- **--xlate-format**=_format_ (Default: `conflict`)

    Legen Sie das Ausgabeformat für den ursprünglichen und den übersetzten Text fest.

    Die folgenden Formate mit Ausnahme von `xtxt` gehen davon aus, dass der zu übersetzende Teil eine Sammlung von Zeilen ist. In der Tat ist es möglich, nur einen Teil einer Zeile zu übersetzen, aber die Angabe eines anderen Formats als `xtxt` führt zu keinen sinnvollen Ergebnissen.

    - **conflict**, **cm**

        Original und konvertierter Text werden im Format [git(1)](http://man.he.net/man1/git) conflict marker ausgegeben.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Sie können die Originaldatei mit dem nächsten Befehl [sed(1)](http://man.he.net/man1/sed) wiederherstellen.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Der ursprüngliche und der übersetzte Text werden in einem benutzerdefinierten Container-Stil von Markdown ausgegeben.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Der obige Text wird in HTML wie folgt übersetzt.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Die Anzahl der Doppelpunkte ist standardmäßig 7. Wenn Sie eine Doppelpunktfolge wie `:::::` angeben, wird diese anstelle von 7 Doppelpunkten verwendet.

    - **ifdef**

        Original und konvertierter Text werden im Format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` ausgedruckt.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Mit dem Befehl **unifdef** können Sie nur japanischen Text wiederherstellen:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original und konvertierter Text werden durch eine einzelne Leerzeile getrennt ausgegeben. Bei `Leerzeichen+` wird nach dem konvertierten Text auch ein Zeilenumbruch ausgegeben.

    - **xtxt**

        Wenn das Format `xtxt` (übersetzter Text) oder unbekannt ist, wird nur der übersetzte Text gedruckt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geben Sie die maximale Länge des Textes an, der auf einmal an die API gesendet werden soll. Der Standardwert 0 entspricht der engine-eigenen Begrenzung: Für den kostenlosen DeepL-Account-Dienst beträgt diese 128K für die API (**--xlate**) und 5000 für die Zwischenablage-Schnittstelle (**--xlate-labor**). Möglicherweise können Sie diese Werte ändern, wenn Sie den Pro-Dienst nutzen.

- **--xlate-maxline**=_n_ (Default: 0)

    Geben Sie die maximale Anzahl von Textzeilen an, die auf einmal an die API gesendet werden sollen.

    Setzen Sie diesen Wert auf 1, wenn Sie jeweils nur eine Zeile übersetzen wollen. Diese Option hat Vorrang vor der Option `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Geben Sie eine benutzerdefinierte Eingabeaufforderung an, die an die Übersetzungs-Engine gesendet werden soll. Diese Option ist für die LLM-Engines (`gpt3`, `gpt4o`, `gpt5`) verfügbar, nicht jedoch für DeepL. Sie können das Übersetzungsverhalten anpassen, indem Sie dem KI-Modell spezifische Anweisungen geben. Wenn die Eingabeaufforderung `%s` enthält, wird diese durch den Namen der Zielsprache ersetzt.

- **--xlate-context**=_text_

    Geben Sie zusätzliche Kontextinformationen an, die an die Übersetzungsmaschine gesendet werden sollen. Diese Option kann mehrfach verwendet werden, um mehrere Kontextstrings anzugeben. Die Kontextinformationen helfen der Übersetzungsmaschine, den Hintergrund zu verstehen und genauere Übersetzungen zu erstellen.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Anzahl der umgebenden übersetzten Blöcke, die bei der Neuübersetzung geänderter Blöcke als Referenzkontext übergeben werden (Standardwert 2). Der Kontext umfasst auch den Rohquelltext rund um den geänderten Bereich (Überschriften, Listenstruktur, Bildunterschriften) sowie, sofern verfügbar, die aus dem Cache wiederhergestellte vorherige Version des geänderten Textes, sodass unveränderte Formulierungen erhalten bleiben. Setzen Sie den Wert auf 0, um die kontextbezogene Übersetzung vollständig zu deaktivieren. Beachten Sie, dass jeder geänderte Bereich in einem eigenen API-Aufruf übersetzt wird und der Kontext die System-Eingabeaufforderung um bis zu etwa 8000 Zeichen erweitern kann; die kontextbezogene Übersetzung erkauft sich also Konsistenz mit etwas zusätzlichem Aufwand.

- **--xlate-cache-seed**=_file_

    Initialisieren Sie den Cache eines neuen Dokuments anhand der Cache-Datei eines anderen Dokuments. Nützlich für periodische Berichte: Füllen Sie den Cache der neuen Ausgabe mit dem der vorherigen Ausgabe, damit unveränderte Absätze nicht erneut übersetzt werden und bearbeitete Absätze den Wortlaut der vorherigen Ausgabe beibehalten. Der Startwert wird nur verwendet, wenn der Ziel-Cache leer ist; andernfalls wird er mit einer Warnung ignoriert. Bei der Standardeinstellung `--xlate-cache=auto` bedeutet die Angabe eines Startwerts auch, dass die Cache-Datei des neuen Dokuments erstellt wird.

- **--xlate-anonymize**=_file_

    Anonymisieren Sie sensible Zeichenfolgen, bevor sie an die Übersetzungs-API gesendet werden, und stellen Sie sie in der Ausgabe wieder her. Die Wörterbuchdatei enthält einen Eintrag pro Element: im JSON-Format (kanonisch, maschinell generierbar)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    oder in einem einfachen Zeilenformat (`category pattern`, `/.../` für reguläre Ausdrücke). Jedes Element wird durch ein Kategorie-Tag wie `<person id=1 />` ersetzt; dieselbe Zeichenfolge erhält immer dasselbe Tag, sodass das Modell den Überblick darüber behalten kann, wer wer ist. Unbekannte JSON-Felder werden ignoriert, sodass Generatoren (z. B. ein lokales LLM, das Entitäten extrahiert) ihre eigenen Anmerkungen hinzufügen können. Die Kategorie `lit` ist reserviert. Lokale Cache-Dateien speichern weiterhin den wiederhergestellten Klartext: Das Ziel der Verschleierung ist ausschließlich die API-Übertragung.

    Ein Wörterbuch kann von einem externen Tool generiert werden – zum Beispiel von einem lokalen Modell, das sensible Entitäten extrahiert:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Ein UTF-8-BOM in der Datei wird toleriert. Werte im Front-Matter-Zeilenformat dürfen einen abschließenden Kommentar nur in einer eigenen Zeile enthalten, nicht nach dem Wert.

- **--xlate-anonymize-mark**\[=_regex_\]

    Sammeln Sie Anonymisierungseinträge aus Inline-Markierungen im Dokument selbst. Markieren Sie das erste Vorkommen wie `{{ person("山田太郎") }}`, und jedes Vorkommen der Zeichenfolge im gesamten Dokument wird anonymisiert. Die Markierung selbst bleibt im Quelltext und in der Übersetzung erhalten, sodass ein Dokument auch von einem Makroprozessor im Jinja2-Stil verarbeitet werden kann (definieren Sie das Makro `person`, um den Namen auszugeben oder zu schwärzen). Ein benutzerdefiniertes _regex_ muss die benannten Erfassungen `(?<category>...)` und `(?<text>...)` enthalten.

    Beachten Sie, dass bei einer Option mit optionalem Wert wie dieser ein nachfolgendes Dateiargument als Wert übernommen würde: Schreiben Sie `--xlate-anonymize-mark=` (mit einem nachgestellten `=`), wenn Sie die Standardnotation verwenden.

    Alternative Notationen können konfiguriert werden, zum Beispiel `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` für Markierungen im `@@person:NAME@@`-Stil oder eine HTML-Kommentarform, die im gerenderten Markdown unsichtbar bleibt. Markierungsregeln werden pro Dokument gesammelt: Eine in einer Eingabedatei markierte Zeichenfolge wird in einer anderen Datei desselben Durchlaufs nicht ausgeblendet (im Gegensatz zu Front-Matter-Werten, die sich über mehrere Dateien hinweg summieren).

- **--xlate-template**\[=_regex_\]

    Behandeln Sie Vorlagenausdrücke (Standard: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) als undurchsichtige Platzhalter: Weisen Sie das Modell an, diese unverändert zu kopieren und pro Block zu überprüfen, ob die Antwort genau dieselben Ausdrücke enthält, jeweils in derselben Anzahl. Ihre Reihenfolge kann sich ändern, da die Übersetzung sie legitimerweise neu anordnet, um der Wortreihenfolge der Zielsprache zu folgen. Ein fehlerhafter Ausdruck bricht den Durchlauf ab; der Cache wird gesichert und eingefroren, sodass keine bezahlten Daten verloren gehen.

    Beachten Sie, dass bei einer Option mit optionalem Wert wie dieser ein nachfolgendes Dateiargument als Wert übernommen würde: Schreiben Sie `--xlate-template=` (mit einem nachgestellten `=`), wenn Sie die Standardnotation verwenden.

- **--xlate-frontmatter**

    Behandeln Sie einen vorangestellten `---` ... `---`-Block als YAML-Frontmatter: Schließe ihn von der Übersetzung und den Phasen-2-Kontext-Slices aus und füge seine flachen `key: value`-Werte als Sicherheitsnetz zu den Anonymisierungsregeln (Kategorie `var`) hinzu. Bei mehreren Eingabedateien summieren sich die gesammelten Werte (wobei eher auf der Seite der Verschleierung gehandelt wird).

    Lassen Sie nach dem schließenden `---` immer eine Leerzeile. Bei einem Übereinstimmungsmuster im Absatzstil bildet Front Matter, das direkt in den Fließtext übergeht, einen übergreifenden Block, den der Ausschluss nicht unterdrücken kann (in diesem Fall wird eine Warnung ausgegeben); die Werte werden zwar weiterhin anonymisiert, aber die Vorbemerkungen selbst würden zur Übersetzung gesendet.

- **--xlate-glossary**=_glossary_

    Geben Sie eine Glossarkennung an, die für die Übersetzung verwendet werden soll. Diese Option ist nur bei Verwendung der DeepL Engine verfügbar. Die Glossar-ID sollte von Ihrem DeepL Konto bezogen werden und gewährleistet eine konsistente Übersetzung bestimmter Begriffe.

- **--xlate-dryrun**

    Rufen Sie die Übersetzungs-API nicht auf; zeigen Sie stattdessen über die Fortschrittsanzeige jede Nutzlast genau so an, wie sie übertragen würde (nach Anonymisierung und Maskierung). Dies ist nützlich, um zu überprüfen, was den Rechner verlässt, und um die Kosten eines Durchlaufs abzuschätzen.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Sehen Sie sich das Übersetzungsergebnis in Echtzeit in der STDERR-Ausgabe an. Die `From`-Nutzlast wird so angezeigt, wie sie nach Anonymisierung und Maskierung übertragen wurde.

- **--xlate-stripe**

    Verwenden Sie das Modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe), um den übereinstimmenden Teil in Form eines Zebrastreifens anzuzeigen. Dies ist nützlich, wenn die übereinstimmenden Teile Rücken an Rücken verbunden sind.

    Die Farbpalette wird entsprechend der Hintergrundfarbe des Terminals umgeschaltet. Wenn Sie dies explizit angeben wollen, können Sie **--xlate-stripe-light** oder **--xlate-stripe-dark** verwenden.

- **--xlate-mask**

    Führen Sie die Maskierungsfunktion aus und zeigen Sie den umgewandelten Text so an, wie er ist, ohne ihn wiederherzustellen.

- **--match-all**

    Legen Sie den gesamten Text der Datei als Zielbereich fest.

- **--lineify-cm**
- **--lineify-colon**

    Im Falle der Formate `cm` und `colon` wird die Ausgabe zeilenweise aufgeteilt und formatiert. Wenn also nur ein Teil einer Zeile übersetzt werden soll, kann das erwartete Ergebnis nicht erzielt werden. Diese Filter korrigieren die Ausgabe, die durch die Übersetzung eines Teils einer Zeile in die normale zeilenweise Ausgabe verfälscht wird.

    Werden in der derzeitigen Implementierung mehrere Teile einer Zeile übersetzt, werden sie als unabhängige Zeilen ausgegeben.

# CACHE OPTIONS

Das Modul **xlate** kann den Text der Übersetzung für jede Datei im Cache speichern und vor der Ausführung lesen, um den Overhead durch die Anfrage an den Server zu vermeiden. Bei der Standard-Cache-Strategie `auto` werden die Cache-Daten nur dann beibehalten, wenn die Cache-Datei für die Zieldatei existiert.

Verwenden Sie **--xlate-cache=clear**, um die Cache-Verwaltung zu starten oder um alle vorhandenen Cache-Daten zu löschen. Nach der Ausführung dieser Option wird eine neue Cache-Datei erstellt, falls noch keine vorhanden ist, und anschließend automatisch gepflegt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Cache-Datei beibehalten, wenn sie vorhanden ist.

    - `create`

        Leere Cachedatei erstellen und beenden.

    - `always`, `yes`, `1`

        Cache trotzdem beibehalten, sofern das Ziel eine normale Datei ist.

    - `clear`

        Löschen Sie zuerst die Cache-Daten.

    - `never`, `no`, `0`

        Niemals die Cache-Datei verwenden, selbst wenn sie vorhanden ist.

    - `accumulate`

        Standardmäßig werden nicht verwendete Daten aus der Cache-Datei entfernt. Wenn Sie sie nicht entfernen und in der Datei behalten wollen, verwenden Sie `accumulate`.
- **--xlate-update**

    Diese Option erzwingt die Aktualisierung der Cache-Datei, auch wenn dies nicht erforderlich ist.

# COMMAND LINE INTERFACE

Sie können dieses Modul einfach von der Kommandozeile aus verwenden, indem Sie den in der Distribution enthaltenen Befehl `xlate` verwenden. Siehe die Manpage `xlate` zur Verwendung.

Der Befehl `xlate` unterstützt lange Optionen im GNU-Stil wie `--to-lang`, `--from-lang`, `--engine` und `--file`. Verwenden Sie `xlate -h`, um alle verfügbaren Optionen zu sehen.

Der Befehl `xlate` arbeitet mit der Docker-Umgebung zusammen, d. h. selbst wenn Sie nichts installiert haben, können Sie ihn verwenden, solange Docker verfügbar ist. Verwenden Sie die Option `-D` oder `-C`.

Docker-Operationen werden über [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) abgewickelt, das auch als eigenständiger Befehl verwendet werden kann. Der Befehl `dozo` unterstützt die Konfigurationsdatei `.dozorc` für dauerhafte Container-Einstellungen.

Da Makefiles für verschiedene Dokumentstile zur Verfügung gestellt werden, ist auch eine Übersetzung in andere Sprachen ohne besondere Angaben möglich. Verwenden Sie die Option `-M`.

Sie können auch die Optionen Docker und `make` kombinieren, so dass Sie `make` in einer Docker-Umgebung ausführen können.

Wenn Sie `xlate -C` ausführen, wird eine Shell gestartet, in der das aktuelle Git-Repository eingebunden ist.

Lesen Sie den japanischen Artikel im Abschnitt ["SEE ALSO"](#see-also) für weitere Details.

# EMACS

Laden Sie die im Repository enthaltene Datei `xlate.el`, um den Befehl `xlate` im Emacs-Editor zu verwenden. Die Funktion `xlate-region` übersetzt die angegebene Region. Die Standardsprache ist `EN-US` und Sie können die Sprache mit dem Präfix-Argument angeben.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Legen Sie Ihren Authentifizierungsschlüssel für den Dienst DeepL fest.

- OPENAI\_API\_KEY

    OpenAI-Authentifizierungsschlüssel, der von den älteren **gpty**-Engines verwendet wird. Die auf `llm` basierende **gpt5**-Engine liest diese Variable ebenfalls, aber auch mit `llm keys set openai` gespeicherte Schlüssel funktionieren.

- GREPLE\_XLATE\_CACHE

    Legen Sie die Standard-Cache-Strategie fest (siehe ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Installieren Sie das Befehlszeilentool für die von Ihnen verwendete Engine: `llm` für die **gpt5**-Engine, `deepl` für DeepL, `gpty` für die älteren GPT-Engines.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Generischer Docker-Runner, der von xlate für Container-Operationen verwendet wird.

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Siehe das **greple**-Handbuch für Details über Zieltextmuster. Verwenden Sie die Optionen **--inside**, **--outside**, **--include**, **--exclude**, um den passenden Bereich einzuschränken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Sie können das Modul `-Mupdate` verwenden, um Dateien anhand des Ergebnisses des Befehls **greple** zu ändern.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Verwenden Sie **sdif**, um das Format der Konfliktmarkierung zusammen mit der Option **-V** anzuzeigen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** Modul Verwendung durch **--xlate-stripe** Option.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-Container-Abbild.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Die `getoptlong.sh`-Bibliothek, die für das Optionsparsing im `xlate`-Skript und [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) verwendet wird.

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Der Befehl `llm`, der von der **gpt5**-Engine für den Zugriff auf LLM-Modelle verwendet wird.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-Bibliothek und CLI-Befehl.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-Bibliothek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI Kommandozeilen-Schnittstelle

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-Modul zum Übersetzen und Ersetzen nur der notwendigen Teile mit DeepL API (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generierung von Dokumenten in 15 Sprachen mit dem Modul DeepL API (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische Übersetzung der Docker-Umgebung mit DeepL API (auf Japanisch)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
