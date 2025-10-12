# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9914

# DESCRIPTION

**Greple** **xlate** Modul findet gewünschte Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit sind DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) und GPT-5 (`gpt5.pm`) als Back-End-Engines implementiert.

Wenn Sie normale Textblöcke in einem im Perl-Pod-Stil geschriebenen Dokument übersetzen möchten, verwenden Sie den **greple**-Befehl mit `xlate::deepl` und `perl`-Modul wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In diesem Befehl bedeutet der Musterstring `^([\w\pP].*\n)+` aufeinanderfolgende Zeilen, die mit alphanumerischen und Satzzeichen beginnen. Dieser Befehl hebt den zu übersetzenden Bereich hervor. Die Option **--all** wird verwendet, um den gesamten Text auszugeben.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Fügen Sie dann die Option `--xlate` hinzu, um den ausgewählten Bereich zu übersetzen. Dann werden die gewünschten Abschnitte gefunden und durch die Ausgabe des **deepl**-Befehls ersetzt.

Standardmäßig werden Original- und Übersetzungstext im "Konfliktmarker"-Format ausgegeben, das mit [git(1)](http://man.he.net/man1/git) kompatibel ist. Mit dem `ifdef`-Format können Sie den gewünschten Teil einfach mit dem [unifdef(1)](http://man.he.net/man1/unifdef)-Befehl extrahieren. Das Ausgabeformat kann mit der Option **--xlate-format** festgelegt werden.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Wenn Sie den gesamten Text übersetzen möchten, verwenden Sie die Option **--match-all**. Dies ist eine Abkürzung für das Muster `(?s).+`, das auf den gesamten Text passt.

Konfliktmarkierungsformatdaten können im Nebeneinander-Stil mit dem Befehl [sdif](https://metacpan.org/pod/App%3A%3Asdif) und der Option `-V` angezeigt werden. Da ein Vergleich auf Zeichenkettenbasis keinen Sinn ergibt, wird die Option `--no-cdif` empfohlen. Wenn Sie den Text nicht einfärben müssen, geben Sie `--no-textcolor` (oder `--no-tc`) an.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Die Verarbeitung erfolgt in den angegebenen Einheiten, aber bei einer Folge mehrerer Zeilen mit nicht-leerem Text werden diese zusammen in eine einzige Zeile umgewandelt. Dieser Vorgang wird wie folgt durchgeführt:

- Entfernen von Leerzeichen am Anfang und Ende jeder Zeile.
- Wenn eine Zeile mit einem vollbreiten Satzzeichen endet, wird sie mit der nächsten Zeile verbunden.
- Wenn eine Zeile mit einem vollbreiten Zeichen endet und die nächste Zeile mit einem vollbreiten Zeichen beginnt, werden die Zeilen zusammengefügt.
- Wenn entweder das Ende oder der Anfang einer Zeile kein vollbreites Zeichen ist, werden sie durch Einfügen eines Leerzeichens verbunden.

Cache-Daten werden auf Basis des normalisierten Textes verwaltet, sodass auch bei Änderungen, die das Normalisierungsergebnis nicht beeinflussen, die zwischengespeicherten Übersetzungsdaten weiterhin wirksam sind.

Dieser Normalisierungsprozess wird nur für das erste (0.) und gerade nummerierte Muster durchgeführt. Wenn also zwei Muster wie folgt angegeben werden, wird der Text, der dem ersten Muster entspricht, nach der Normalisierung verarbeitet, und für den Text, der dem zweiten Muster entspricht, erfolgt keine Normalisierung.

    greple -Mxlate -E normalized -E not-normalized

Verwenden Sie daher das erste Muster für Text, der durch Zusammenfassen mehrerer Zeilen zu einer einzigen Zeile verarbeitet werden soll, und das zweite Muster für vorformatierten Text. Wenn im ersten Muster kein Text gefunden wird, verwenden Sie ein Muster, das auf nichts passt, wie `(?!)`.

# MASKING

Gelegentlich gibt es Textteile, die nicht übersetzt werden sollen. Zum Beispiel Tags in Markdown-Dateien. DeepL schlägt vor, in solchen Fällen den zu überspringenden Textteil in XML-Tags umzuwandeln, zu übersetzen und nach Abschluss der Übersetzung wiederherzustellen. Um dies zu unterstützen, ist es möglich, die zu maskierenden Teile von der Übersetzung auszuschließen.

    --xlate-setopt maskfile=MASKPATTERN

Jede Zeile der Datei \`MASKPATTERN\` wird als regulärer Ausdruck interpretiert, passende Zeichenfolgen werden übersetzt und nach der Verarbeitung wiederhergestellt. Zeilen, die mit `#` beginnen, werden ignoriert.

Komplexe Muster können über mehrere Zeilen mit einem Backslash und einem Zeilenumbruch geschrieben werden.

Wie der Text durch Maskierung umgewandelt wird, kann mit der Option **--xlate-mask** angezeigt werden.

Diese Schnittstelle ist experimentell und kann sich in Zukunft ändern.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Der Übersetzungsprozess wird für jeden übereinstimmenden Bereich aufgerufen.

    Ohne diese Option verhält sich **greple** wie ein normaler Suchbefehl. So können Sie prüfen, welcher Teil der Datei übersetzt wird, bevor die eigentliche Arbeit beginnt.

    Das Kommandoergebnis wird an die Standardausgabe gesendet, daher ggf. in eine Datei umleiten oder das Modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) verwenden.

    Die Option **--xlate** ruft die Option **--xlate-color** mit der Option **--color=never** auf.

    Mit der Option **--xlate-fold** wird der umgewandelte Text auf die angegebene Breite umgebrochen. Die Standardbreite beträgt 70 und kann mit der Option **--xlate-fold-width** eingestellt werden. Vier Spalten sind für den Einzug reserviert, sodass jede Zeile maximal 74 Zeichen enthalten kann.

- **--xlate-engine**=_engine_

    Legt die zu verwendende Übersetzungs-Engine fest. Wenn Sie das Engine-Modul direkt angeben, wie z. B. `-Mxlate::deepl`, müssen Sie diese Option nicht verwenden.

    Derzeit sind folgende Engines verfügbar

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        Die Schnittstelle von **gpt-4o** ist instabil und kann derzeit nicht korrekt funktionieren.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    Statt die Übersetzungs-Engine aufzurufen, wird erwartet, dass Sie selbst arbeiten. Nachdem der zu übersetzende Text vorbereitet wurde, wird er in die Zwischenablage kopiert. Sie sollen ihn in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und die Eingabetaste drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. Verfügbare Sprachen erhalten Sie mit dem Befehl `deepl languages` bei Verwendung der Engine **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Geben Sie das Ausgabeformat für Original- und Übersetzungstext an.

    Die folgenden Formate außer `xtxt` gehen davon aus, dass der zu übersetzende Teil eine Sammlung von Zeilen ist. Tatsächlich ist es möglich, nur einen Teil einer Zeile zu übersetzen, aber die Angabe eines anderen Formats als `xtxt` führt nicht zu sinnvollen Ergebnissen.

    - **conflict**, **cm**

        Original- und umgewandelter Text werden im Konfliktmarker-Format [git(1)](http://man.he.net/man1/git) ausgegeben.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Sie können die Originaldatei mit dem nächsten Befehl [sed(1)](http://man.he.net/man1/sed) wiederherstellen.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Der Original- und der übersetzte Text werden im benutzerdefinierten Container-Stil von Markdown ausgegeben.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Der obige Text wird im Folgenden in HTML übersetzt.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Die Anzahl der Doppelpunkte beträgt standardmäßig 7. Wenn Sie eine Doppelpunktsequenz wie `:::::` angeben, wird diese anstelle von 7 Doppelpunkten verwendet.

    - **ifdef**

        Original- und umgewandelter Text werden im [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`-Format ausgegeben.

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

        Original- und konvertierter Text werden durch eine einzelne Leerzeile getrennt ausgegeben.

    - **xtxt**

        Für `space+` wird nach dem konvertierten Text ebenfalls eine neue Zeile ausgegeben.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Wenn das Format `xtxt` (übersetzter Text) oder unbekannt ist, wird nur der übersetzte Text ausgegeben.

- **--xlate-maxline**=_n_ (Default: 0)

    Geben Sie die maximale Textlänge an, die auf einmal an die API gesendet werden soll. Der Standardwert ist wie für den kostenlosen DeepL-Kontodienst festgelegt: 128K für die API (**--xlate**) und 5000 für die Zwischenablage-Schnittstelle (**--xlate-labor**). Sie können diese Werte möglicherweise ändern, wenn Sie den Pro-Service nutzen.

    Geben Sie die maximale Zeilenanzahl an, die auf einmal an die API gesendet werden soll.

- **--xlate-prompt**=_text_

    Geben Sie eine benutzerdefinierte Eingabeaufforderung an, die an die Übersetzungs-Engine gesendet wird. Diese Option ist nur verfügbar, wenn ChatGPT-Engines (gpt3, gpt4, gpt4o) verwendet werden. Sie können das Übersetzungsverhalten anpassen, indem Sie dem KI-Modell spezifische Anweisungen geben. Wenn die Eingabeaufforderung `%s` enthält, wird sie durch den Namen der Zielsprache ersetzt.

- **--xlate-context**=_text_

    Geben Sie zusätzliche Kontextinformationen an, die an die Übersetzungs-Engine gesendet werden. Diese Option kann mehrfach verwendet werden, um mehrere Kontextzeichenfolgen bereitzustellen. Die Kontextinformationen helfen der Übersetzungs-Engine, den Hintergrund zu verstehen und genauere Übersetzungen zu erzeugen.

- **--xlate-glossary**=_glossary_

    Geben Sie eine Glossar-ID an, die für die Übersetzung verwendet werden soll. Diese Option ist nur verfügbar, wenn die DeepL-Engine verwendet wird. Die Glossar-ID sollte aus Ihrem DeepL-Konto stammen und sorgt für eine konsistente Übersetzung bestimmter Begriffe.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Setzen Sie diesen Wert auf 1, wenn Sie jeweils nur eine Zeile übersetzen möchten. Diese Option hat Vorrang vor der Option `--xlate-maxlen`.

- **--xlate-stripe**

    Sehen Sie das Übersetzungsergebnis in Echtzeit in der STDERR-Ausgabe.

    Verwenden Sie das [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)-Modul, um den übereinstimmenden Teil im Zebra-Streifen-Stil anzuzeigen. Dies ist nützlich, wenn die übereinstimmenden Teile direkt aneinander anschließen.

- **--xlate-mask**

    Die Farbpalette wird entsprechend der Hintergrundfarbe des Terminals umgeschaltet. Wenn Sie dies explizit angeben möchten, können Sie **--xlate-stripe-light** oder **--xlate-stripe-dark** verwenden.

- **--match-all**

    Führen Sie die Maskierungsfunktion aus und zeigen Sie den konvertierten Text unverändert ohne Wiederherstellung an.

- **--lineify-cm**
- **--lineify-colon**

    Im Fall der `cm`- und `colon`-Formate wird die Ausgabe zeilenweise aufgeteilt und formatiert. Daher kann das erwartete Ergebnis nicht erzielt werden, wenn nur ein Teil einer Zeile übersetzt wird. Diese Filter beheben Ausgaben, die durch die Übersetzung eines Teils einer Zeile beschädigt wurden, indem sie eine normale zeilenweise Ausgabe erzeugen.

    In der aktuellen Implementierung werden mehrere übersetzte Teile einer Zeile als unabhängige Zeilen ausgegeben.

# CACHE OPTIONS

Setzen Sie den gesamten Text der Datei als Zielbereich.

Das **xlate**-Modul kann zwischengespeicherten Übersetzungstext für jede Datei speichern und vor der Ausführung lesen, um den Overhead der Serveranfrage zu vermeiden. Mit der Standard-Cache-Strategie `auto` werden Cache-Daten nur dann gepflegt, wenn die Cache-Datei für die Zieldatei existiert.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Verwenden Sie **--xlate-cache=clear**, um das Cache-Management zu starten oder alle vorhandenen Cache-Daten zu bereinigen. Nach der Ausführung mit dieser Option wird eine neue Cache-Datei erstellt, falls keine existiert, und anschließend automatisch gepflegt.

    - `create`

        Pflegen Sie die Cache-Datei, wenn sie existiert.

    - `always`, `yes`, `1`

        Leere Cache-Datei erstellen und beenden.

    - `clear`

        Cache auf jeden Fall pflegen, solange das Ziel eine normale Datei ist.

    - `never`, `no`, `0`

        Löschen Sie zuerst die Cache-Daten.

    - `accumulate`

        Verwenden Sie niemals eine Cache-Datei, auch wenn sie existiert.
- **--xlate-update**

    Standardmäßig werden ungenutzte Daten aus der Cache-Datei entfernt. Wenn Sie diese nicht entfernen und in der Datei behalten möchten, verwenden Sie `accumulate`.

# COMMAND LINE INTERFACE

Diese Option erzwingt die Aktualisierung der Cache-Datei, auch wenn dies nicht notwendig ist.

Sie können dieses Modul einfach über die Befehlszeile mit dem in der Distribution enthaltenen `xlate`-Befehl verwenden. Siehe die `xlate`-Manpage für die Verwendung.

Der `xlate`-Befehl arbeitet mit der Docker-Umgebung zusammen, sodass Sie ihn auch dann verwenden können, wenn Sie nichts installiert haben, solange Docker verfügbar ist. Verwenden Sie die Option `-D` oder `-C`.

Da auch Makefiles für verschiedene Dokumentstile bereitgestellt werden, ist die Übersetzung in andere Sprachen ohne spezielle Angabe möglich. Verwenden Sie die Option `-M`.

Sie können auch die Docker- und `make`-Optionen kombinieren, sodass Sie `make` in einer Docker-Umgebung ausführen können.

Das Ausführen wie `xlate -C` startet eine Shell mit dem aktuell eingebundenen Arbeits-Git-Repository.

# EMACS

Laden Sie die `xlate.el` Datei, die im Repository enthalten ist, um den `xlate` Befehl aus dem Emacs-Editor zu verwenden. `xlate-region` Funktion übersetzt den angegebenen Bereich. Die Standardsprache ist `EN-US` und Sie können die Sprache mit einem Präfix-Argument angeben.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Setzen Sie Ihren Authentifizierungsschlüssel für den DeepL-Dienst.

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

    Docker-Container-Image.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-Bibliothek und CLI-Befehl.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-Bibliothek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI-Befehlszeilenschnittstelle

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Siehe das **greple** Handbuch für Details zum Zieltextmuster. Verwenden Sie die Optionen **--inside**, **--outside**, **--include**, **--exclude**, um den Suchbereich einzuschränken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Sie können das `-Mupdate` Modul verwenden, um Dateien anhand des Ergebnisses des **greple** Befehls zu ändern.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Verwenden Sie **sdif**, um das Konfliktmarker-Format nebeneinander mit der **-V** Option anzuzeigen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Das Greple **stripe** Modul wird mit der **--xlate-stripe** Option verwendet.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-Modul zum Übersetzen und Ersetzen nur der notwendigen Teile mit der DeepL-API (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Erstellung von Dokumenten in 15 Sprachen mit dem DeepL-API-Modul (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische Übersetzungs-Docker-Umgebung mit DeepL-API (auf Japanisch)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
