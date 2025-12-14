# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für Greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9920

# DESCRIPTION

**Greple** **xlate** Das Modul findet die gewünschten Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit sind die Module DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) und GPT-5 (`gpt5.pm`) als Backend-Engine implementiert.

Wenn Sie normale Textblöcke in einem Dokument übersetzen wollen, das im Pod-Stil von Perl geschrieben ist, verwenden Sie den Befehl **greple** mit dem Modul `xlate::deepl` und `perl` wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In diesem Befehl bedeutet die Zeichenkette `^([\w\pP].*\n)+` aufeinanderfolgende Zeilen, die mit einem alphanumerischen und einem Interpunktionsbuchstaben beginnen. Mit diesem Befehl wird der zu übersetzende Bereich hervorgehoben dargestellt. Die Option **--all** wird verwendet, um den gesamten Text zu übersetzen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Fügen Sie dann die Option `--xlate` hinzu, um den ausgewählten Bereich zu übersetzen. Dann werden die gewünschten Abschnitte gefunden und durch die Ausgabe des Befehls **deepl** ersetzt.

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

Dadurch wird jede Zeile der Datei \`MASKPATTERN\` als regulärer Ausdruck interpretiert, die entsprechenden Zeichenfolgen werden übersetzt und nach der Verarbeitung wiederhergestellt. Zeilen, die mit `#` beginnen, werden ignoriert.

Komplexe Muster können auf mehreren Zeilen mit Backslash und escpaed newline geschrieben werden.

Wie der Text durch die Maskierung umgewandelt wird, können Sie mit der Option **--xlate-mask** sehen.

Diese Schnittstelle ist experimentell und kann sich in Zukunft noch ändern.

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

    Gibt das zu verwendende Übersetzungsmodul an. Wenn Sie das Modul direkt angeben, z. B. `-Mxlate::deepl`, müssen Sie diese Option nicht verwenden.

    Zur Zeit sind die folgenden Engines verfügbar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Die Schnittstelle von **gpt-4o** ist instabil und es kann nicht garantiert werden, dass sie im Moment korrekt funktioniert.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Anstatt die Übersetzungsmaschine aufzurufen, wird von Ihnen erwartet, dass Sie für arbeiten. Nachdem Sie den zu übersetzenden Text vorbereitet haben, wird er in die Zwischenablage kopiert. Es wird erwartet, dass Sie sie in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und die Eingabetaste drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. Sie können die verfügbaren Sprachen mit dem Befehl `deepl languages` abrufen, wenn Sie die Engine **DeepL** verwenden.

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

    Geben Sie die maximale Länge des Textes an, der auf einmal an die API gesendet werden soll. Der Standardwert ist wie beim kostenlosen DeepL account service eingestellt: 128K für die API (**--xlate**) und 5000 für die Zwischenablage-Schnittstelle (**--xlate-labor**). Sie können diese Werte ändern, wenn Sie den Pro-Service nutzen.

- **--xlate-maxline**=_n_ (Default: 0)

    Geben Sie die maximale Anzahl von Textzeilen an, die auf einmal an die API gesendet werden sollen.

    Setzen Sie diesen Wert auf 1, wenn Sie jeweils nur eine Zeile übersetzen wollen. Diese Option hat Vorrang vor der Option `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Geben Sie eine benutzerdefinierte Eingabeaufforderung an, die an die Übersetzungsmaschine gesendet werden soll. Diese Option ist nur bei Verwendung von ChatGPT-Engines (gpt3, gpt4, gpt4o) verfügbar. Sie können das Übersetzungsverhalten anpassen, indem Sie dem KI-Modell spezifische Anweisungen geben. Wenn die Eingabeaufforderung `%s` enthält, wird sie durch den Namen der Zielsprache ersetzt.

- **--xlate-context**=_text_

    Geben Sie zusätzliche Kontextinformationen an, die an die Übersetzungsmaschine gesendet werden sollen. Diese Option kann mehrfach verwendet werden, um mehrere Kontextstrings anzugeben. Die Kontextinformationen helfen der Übersetzungsmaschine, den Hintergrund zu verstehen und genauere Übersetzungen zu erstellen.

- **--xlate-glossary**=_glossary_

    Geben Sie eine Glossarkennung an, die für die Übersetzung verwendet werden soll. Diese Option ist nur bei Verwendung der DeepL Engine verfügbar. Die Glossar-ID sollte von Ihrem DeepL Konto bezogen werden und gewährleistet eine konsistente Übersetzung bestimmter Begriffe.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Sie können das Ergebnis der Übertragung in Echtzeit in der STDERR-Ausgabe sehen.

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

Docker-Operationen werden durch das `dozo`-Skript ausgeführt, das auch als eigenständiger Befehl verwendet werden kann. Das `dozo`-Skript unterstützt die `.dozorc`-Konfigurationsdatei für dauerhafte Container-Einstellungen.

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

    OpenAI-Authentifizierungsschlüssel.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Sie müssen die Befehlszeilentools für DeepL und ChatGPT installieren.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-Container-Abbild.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Die `getoptlong.sh`-Bibliothek wird für das Parsen von Optionen in den `xlate`- und `dozo`-Skripten verwendet.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-Bibliothek und CLI-Befehl.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-Bibliothek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI Kommandozeilen-Schnittstelle

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Siehe das **greple**-Handbuch für Details über Zieltextmuster. Verwenden Sie die Optionen **--inside**, **--outside**, **--include**, **--exclude**, um den passenden Bereich einzuschränken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Sie können das Modul `-Mupdate` verwenden, um Dateien anhand des Ergebnisses des Befehls **greple** zu ändern.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Verwenden Sie **sdif**, um das Format der Konfliktmarkierung zusammen mit der Option **-V** anzuzeigen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** Modul Verwendung durch **--xlate-stripe** Option.

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
