# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9920

# DESCRIPTION

**Greple** **xlate** Modul findet gewünschte Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit sind DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) und GPT-5 (`gpt5.pm`) als Backend-Engines implementiert.

Wenn Sie normale Textblöcke in einem Dokument im POD-Stil von Perl übersetzen möchten, verwenden Sie den Befehl **greple** mit den Modulen `xlate::deepl` und `perl` wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In diesem Befehl bedeutet die Zeichenkette `^([\w\pP].*\n)+` aufeinanderfolgende Zeilen, die mit alphanumerischen und Interpunktionszeichen beginnen. Dieser Befehl zeigt den zu übersetzenden Bereich hervorgehoben an. Die Option **--all** wird verwendet, um den gesamten Text auszugeben.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Fügen Sie dann die Option `--xlate` hinzu, um den ausgewählten Bereich zu übersetzen. Dann werden die gewünschten Abschnitte gefunden und durch die Ausgabe des Befehls **deepl** ersetzt.

Standardmäßig werden Original- und übersetzter Text im „Konfliktmarker“-Format ausgegeben, das mit [git(1)](http://man.he.net/man1/git) kompatibel ist. Mit dem Format `ifdef` können Sie den gewünschten Teil einfach mit dem Befehl [unifdef(1)](http://man.he.net/man1/unifdef) erhalten. Das Ausgabeformat kann mit der Option **--xlate-format** angegeben werden.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Wenn Sie den gesamten Text übersetzen möchten, verwenden Sie die Option **--match-all**. Dies ist eine Abkürzung, um das Muster `(?s).+` anzugeben, das den gesamten Text erfasst.

Daten im Konfliktmarker-Format können im Side-by-Side-Stil mit dem Befehl [sdif](https://metacpan.org/pod/App%3A%3Asdif) und der Option `-V` angezeigt werden. Da ein Vergleich pro Zeichenkette keinen Sinn ergibt, wird die Option `--no-cdif` empfohlen. Wenn Sie den Text nicht einfärben müssen, geben Sie `--no-textcolor` (oder `--no-tc`) an.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Die Verarbeitung erfolgt in angegebenen Einheiten, aber bei einer Folge mehrerer Zeilen nichtleeren Textes werden diese zusammen in eine einzelne Zeile konvertiert. Dieser Vorgang wird wie folgt durchgeführt:

- Entfernen Sie Leerzeichen am Anfang und Ende jeder Zeile.
- Wenn eine Zeile mit einem vollbreiten Satzzeichen endet, mit der nächsten Zeile verketten.
- Wenn eine Zeile mit einem vollbreiten Zeichen endet und die nächste Zeile mit einem vollbreiten Zeichen beginnt, die Zeilen verketten.
- Wenn entweder das Ende oder der Anfang einer Zeile kein vollbreites Zeichen ist, sie durch Einfügen eines Leerzeichens verketten.

Cache-Daten werden auf Basis des normalisierten Textes verwaltet, sodass zwischengespeicherte Übersetzungsdaten weiterhin wirksam sind, selbst wenn Änderungen vorgenommen werden, die das Normalisierungsergebnis nicht beeinflussen.

Dieser Normalisierungsprozess wird nur für das erste (0.) und die geradzahligen Muster durchgeführt. Wenn also zwei Muster wie folgt angegeben werden, wird der Text, der dem ersten Muster entspricht, nach der Normalisierung verarbeitet, und für den Text, der dem zweiten Muster entspricht, wird kein Normalisierungsprozess durchgeführt.

    greple -Mxlate -E normalized -E not-normalized

Verwenden Sie daher das erste Muster für Text, der durch das Kombinieren mehrerer Zeilen zu einer einzelnen Zeile verarbeitet werden soll, und das zweite Muster für vorformatierten Text. Wenn es keinen Text gibt, der auf das erste Muster passt, verwenden Sie ein Muster, das nichts trifft, wie `(?!)`.

# MASKING

Gelegentlich gibt es Textteile, die nicht übersetzt werden sollen. Zum Beispiel Tags in Markdown-Dateien. DeepL schlägt in solchen Fällen vor, den auszuschließenden Teil des Textes in XML-Tags umzuwandeln, zu übersetzen und nach Abschluss der Übersetzung wiederherzustellen. Um dies zu unterstützen, ist es möglich, die Teile zu spezifizieren, die von der Übersetzung maskiert werden sollen.

    --xlate-setopt maskfile=MASKPATTERN

Dabei wird jede Zeile der Datei \`MASKPATTERN\` als regulärer Ausdruck interpretiert, passende Zeichenketten werden übersetzt und nach der Verarbeitung wieder zurückgesetzt. Zeilen, die mit `#` beginnen, werden ignoriert.

Komplexe Muster können mit einem durch Backslash maskierten Zeilenumbruch über mehrere Zeilen geschrieben werden.

Wie der Text durch Maskierung transformiert wird, kann mit der Option **--xlate-mask** gesehen werden.

Diese Schnittstelle ist experimentell und kann sich in Zukunft ändern.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Rufen Sie den Übersetzungsprozess für jeden übereinstimmenden Bereich auf.

    Ohne diese Option verhält sich **greple** wie ein normaler Suchbefehl. So können Sie prüfen, welcher Teil der Datei Gegenstand der Übersetzung wird, bevor die eigentliche Arbeit gestartet wird.

    Das Kommandoergebnis geht an die Standardausgabe; leiten Sie es bei Bedarf in eine Datei um oder erwägen Sie die Verwendung des Moduls [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Option **--xlate** ruft die Option **--xlate-color** mit der Option **--color=never** auf.

    Mit der Option **--xlate-fold** wird der konvertierte Text auf die angegebene Breite umgebrochen. Die Standardbreite beträgt 70 und kann mit der Option **--xlate-fold-width** gesetzt werden. Vier Spalten sind für die Einlaufoperation reserviert, sodass jede Zeile höchstens 74 Zeichen aufnehmen kann.

- **--xlate-engine**=_engine_

    Gibt die zu verwendende Übersetzungs-Engine an. Wenn Sie das Engine-Modul direkt angeben, wie `-Mxlate::deepl`, müssen Sie diese Option nicht verwenden.

    Derzeit sind die folgenden Engines verfügbar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Die Schnittstelle von **gpt-4o** ist instabil und kann derzeit nicht garantiert korrekt funktionieren.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Anstatt die Übersetzungs-Engine aufzurufen, wird erwartet, dass Sie die Arbeit übernehmen. Nachdem der zu übersetzende Text vorbereitet wurde, wird er in die Zwischenablage kopiert. Sie sollen ihn in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und die Eingabetaste drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. Verfügbare Sprachen erhalten Sie mit dem Befehl `deepl languages`, wenn Sie die Engine **DeepL** verwenden.

- **--xlate-format**=_format_ (Default: `conflict`)

    Geben Sie das Ausgabeformat für Original- und übersetzten Text an.

    Die folgenden Formate außer `xtxt` setzen voraus, dass der zu übersetzende Teil eine Sammlung von Zeilen ist. Tatsächlich ist es möglich, nur einen Teil einer Zeile zu übersetzen, aber die Angabe eines anderen Formats als `xtxt` führt nicht zu sinnvollen Ergebnissen.

    - **conflict**, **cm**

        Original- und konvertierter Text werden im Konfliktmarker-Format von [git(1)](http://man.he.net/man1/git) ausgegeben.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Sie können die Originaldatei mit dem nächsten Befehl [sed(1)](http://man.he.net/man1/sed) wiederherstellen.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Der Original- und der übersetzte Text werden in einem benutzerdefinierten Containerstil von Markdown ausgegeben.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Der obige Text wird im HTML in Folgendes übersetzt.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Die Anzahl der Doppelpunkte beträgt standardmäßig 7. Wenn Sie eine Doppelpunktsfolge wie `:::::` angeben, wird diese anstelle von 7 Doppelpunkten verwendet.

    - **ifdef**

        Original- und konvertierter Text werden im Format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` ausgegeben.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Sie können nur den japanischen Text mit dem Befehl **unifdef** abrufen:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original- und konvertierter Text werden durch eine einzelne Leerzeile getrennt ausgegeben. Für `space+` wird nach dem konvertierten Text zusätzlich ein Zeilenumbruch ausgegeben.

    - **xtxt**

        Wenn das Format `xtxt` (übersetzter Text) oder unbekannt ist, wird nur der übersetzte Text ausgegeben.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geben Sie die maximale Textlänge an, die auf einmal an die API gesendet wird. Der Standardwert ist für den kostenlosen DeepL-Konto-Dienst festgelegt: 128K für die API (**--xlate**) und 5000 für die Zwischenablage-Schnittstelle (**--xlate-labor**). Wenn Sie den Pro-Dienst verwenden, können Sie diese Werte möglicherweise ändern.

- **--xlate-maxline**=_n_ (Default: 0)

    Geben Sie die maximale Anzahl von Textzeilen an, die auf einmal an die API gesendet werden.

    Setzen Sie diesen Wert auf 1, wenn Sie eine Zeile nach der anderen übersetzen möchten. Diese Option hat Vorrang vor der Option `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Geben Sie eine benutzerdefinierte Eingabeaufforderung an, die an die Übersetzungs-Engine gesendet wird. Diese Option ist nur bei Verwendung von ChatGPT-Engines (gpt3, gpt4, gpt4o) verfügbar. Sie können das Übersetzungsverhalten anpassen, indem Sie dem KI-Modell spezifische Anweisungen geben. Wenn die Eingabeaufforderung `%s` enthält, wird sie durch den Namen der Zielsprache ersetzt.

- **--xlate-context**=_text_

    Geben Sie zusätzliche Kontextinformationen an, die an die Übersetzungs-Engine gesendet werden. Diese Option kann mehrfach verwendet werden, um mehrere Kontextzeichenfolgen bereitzustellen. Die Kontextinformationen helfen der Übersetzungs-Engine, den Hintergrund zu verstehen und genauere Übersetzungen zu liefern.

- **--xlate-glossary**=_glossary_

    Geben Sie eine Glossar-ID an, die für die Übersetzung verwendet werden soll. Diese Option ist nur bei Verwendung der DeepL-Engine verfügbar. Die Glossar-ID sollte aus Ihrem DeepL-Konto stammen und sorgt für eine konsistente Übersetzung spezifischer Begriffe.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Sehen Sie das Übersetzungsergebnis in Echtzeit in der STDERR-Ausgabe.

- **--xlate-stripe**

    Verwenden Sie das Modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe), um den übereinstimmenden Teil im Zebra-Streifen-Stil anzuzeigen. Dies ist nützlich, wenn die übereinstimmenden Teile nahtlos aneinandergrenzen.

    Die Farbpalette wird entsprechend der Hintergrundfarbe des Terminals umgeschaltet. Wenn Sie dies explizit angeben möchten, können Sie **--xlate-stripe-light** oder **--xlate-stripe-dark** verwenden.

- **--xlate-mask**

    Führen Sie die Maskierungsfunktion aus und zeigen Sie den konvertierten Text unverändert ohne Wiederherstellung an.

- **--match-all**

    Setzen Sie den gesamten Text der Datei als Zielbereich.

- **--lineify-cm**
- **--lineify-colon**

    Bei den Formaten `cm` und `colon` wird die Ausgabe zeilenweise aufgeteilt und formatiert. Wenn daher nur ein Teil einer Zeile übersetzt werden soll, kann das erwartete Ergebnis nicht erzielt werden. Diese Filter korrigieren Ausgaben, die durch das Übersetzen eines Zeilenteils beschädigt wurden, zu einer normalen zeilenweisen Ausgabe.

    In der aktuellen Implementierung werden mehrere übersetzte Teile einer Zeile als unabhängige Zeilen ausgegeben.

# CACHE OPTIONS

Das Modul **xlate** kann für jede Datei zwischengespeicherten Übersetzungstext speichern und ihn vor der Ausführung einlesen, um den Overhead von Serveranfragen zu vermeiden. Mit der Standard-Cache-Strategie `auto` werden Cache-Daten nur beibehalten, wenn die Cache-Datei für die Zieldatei existiert.

Verwenden Sie **--xlate-cache=clear**, um die Cache-Verwaltung zu starten oder alle vorhandenen Cache-Daten zu bereinigen. Wenn diese Option einmal ausgeführt wurde, wird eine neue Cache-Datei erstellt, falls keine vorhanden ist, und anschließend automatisch gepflegt.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Pflegen Sie die Cache-Datei, falls sie existiert.

    - `create`

        Leere Cache-Datei erstellen und beenden.

    - `always`, `yes`, `1`

        Den Cache dennoch beibehalten, solange das Ziel eine normale Datei ist.

    - `clear`

        Zuerst die Cache-Daten löschen.

    - `never`, `no`, `0`

        Cache-Datei niemals verwenden, selbst wenn sie existiert.

    - `accumulate`

        Standardmäßig werden ungenutzte Daten aus der Cache-Datei entfernt. Wenn Sie sie nicht entfernen und in der Datei behalten möchten, verwenden Sie `accumulate`.
- **--xlate-update**

    Diese Option erzwingt das Aktualisieren der Cache-Datei, auch wenn es nicht notwendig ist.

# COMMAND LINE INTERFACE

Sie können dieses Modul einfach über die Kommandozeile verwenden, indem Sie den in der Distribution enthaltenen Befehl `xlate` verwenden. Siehe die `xlate`-Manpage zur Verwendung.

Der `xlate`-Befehl unterstützt GNU-ähnliche Long-Optionen wie `--to-lang`, `--from-lang`, `--engine` und `--file`. Verwenden Sie `xlate -h`, um alle verfügbaren Optionen anzuzeigen.

Der Befehl `xlate` arbeitet mit der Docker-Umgebung zusammen. Selbst wenn Sie lokal nichts installiert haben, können Sie ihn verwenden, solange Docker verfügbar ist. Verwenden Sie die Option `-D` oder `-C`.

Docker-Operationen werden vom Skript `dozo` ausgeführt, das auch als eigenständiger Befehl verwendet werden kann. Das Skript `dozo` unterstützt die Konfigurationsdatei `.dozorc` für persistente Containereinstellungen.

Da Makefiles für verschiedene Dokumentstile bereitgestellt werden, ist die Übersetzung in andere Sprachen ohne besondere Spezifikation möglich. Verwenden Sie die Option `-M`.

Sie können die Optionen Docker und `make` auch kombinieren, sodass Sie `make` in einer Docker-Umgebung ausführen können.

Das Ausführen wie `xlate -C` startet eine Shell mit dem aktuell eingehängten Git-Repository als Arbeitsverzeichnis.

Lesen Sie den japanischen Artikel im Abschnitt ["SEE ALSO"](#see-also) für Details.

# EMACS

Laden Sie die im Repository enthaltene Datei `xlate.el`, um den Befehl `xlate` aus dem Emacs-Editor zu verwenden. Die Funktion `xlate-region` übersetzt den angegebenen Bereich. Die Standardsprache ist `EN-US`, und Sie können die Sprache angeben, indem Sie sie mit Präfix-Argument aufrufen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Legen Sie Ihren Authentifizierungsschlüssel für den DeepL-Dienst fest.

- OPENAI\_API\_KEY

    OpenAI-Authentifizierungsschlüssel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Sie müssen die Kommandozeilentools für DeepL und ChatGPT installieren.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-Container-Image.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Die Bibliothek `getoptlong.sh` wird für die Optionsauswertung in den Skripten `xlate` und `dozo` verwendet.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL-Python-Bibliothek und CLI-Befehl.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI-Python-Bibliothek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI-Kommandozeilenschnittstelle

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Siehe das Handbuch **greple** für Details zum Zieltextmuster. Verwenden Sie die Optionen **--inside**, **--outside**, **--include**, **--exclude**, um den Abgleichsbereich einzuschränken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Sie können das Modul `-Mupdate` verwenden, um Dateien anhand des Ergebnisses des Befehls **greple** zu ändern.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Verwenden Sie **sdif**, um das Konfliktmarker-Format nebeneinander mit der Option **-V** anzuzeigen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple-Modul **stripe** wird mit der Option **--xlate-stripe** verwendet.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-Modul zum Übersetzen und Ersetzen nur der notwendigen Teile mit der DeepL-API (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Erzeugen von Dokumenten in 15 Sprachen mit dem DeepL-API-Modul (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische Übersetzungs-Docker-Umgebung mit der DeepL-API (auf Japanisch)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
