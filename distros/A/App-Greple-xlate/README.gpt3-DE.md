# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9904

# DESCRIPTION

Das **Greple** **xlate** Modul findet gewünschte Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit sind die DeepL (`deepl.pm`) und ChatGPT (`gpt3.pm`) Module als Backend-Engine implementiert. Experimentelle Unterstützung für gpt-4 und gpt-4o ist ebenfalls enthalten.

Wenn Sie normale Textblöcke in einem Dokument übersetzen möchten, das im Perl-Pod-Stil geschrieben ist, verwenden Sie den **greple**-Befehl mit dem `xlate::deepl`- und `perl`-Modul wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In diesem Befehl bedeutet das Musterzeichenfolgenmuster `^([\w\pP].*\n)+`, dass aufeinanderfolgende Zeilen mit alphanumerischen und Satzzeichenbuchstaben beginnen. Dieser Befehl zeigt den zu übersetzenden Bereich hervorgehoben an. Die Option **--all** wird verwendet, um den gesamten Text zu erzeugen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Fügen Sie dann die Option `--xlate` hinzu, um den ausgewählten Bereich zu übersetzen. Anschließend findet es die gewünschten Abschnitte und ersetzt sie durch die Ausgabe des **deepl**-Befehls.

Standardmäßig wird der Original- und übersetzte Text im "Konfliktmarker"-Format ausgegeben, das mit [git(1)](http://man.he.net/man1/git) kompatibel ist. Mit dem `ifdef`-Format können Sie den gewünschten Teil leicht mit dem **unifdef(1)** Befehl erhalten. Das Ausgabeformat kann mit der **--xlate-format** Option festgelegt werden.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Wenn Sie den gesamten Text übersetzen möchten, verwenden Sie die **--match-all** Option. Dies ist eine Abkürzung, um das Muster `(?s).+` anzugeben, das den gesamten Text abdeckt.

Konfliktmarker-Formatdaten können im Seit-an-Seit-Stil mit dem Befehl `sdif` und der Option `-V` angezeigt werden. Da ein Vergleich auf Zeichenfolgenbasis keinen Sinn macht, wird die Option `--no-cdif` empfohlen. Wenn Sie den Text nicht einfärben möchten, geben Sie `--no-textcolor` (oder `--no-tc`) an.

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Die Verarbeitung erfolgt in festgelegten Einheiten, aber im Fall einer Sequenz von mehreren Zeilen mit nicht-leerem Text werden sie zusammen in eine einzige Zeile umgewandelt. Diese Operation wird wie folgt durchgeführt:

- Entfernen Sie Leerzeichen am Anfang und Ende jeder Zeile.
- Wenn eine Zeile mit einem Vollbreiten-Satzzeichen endet, verknüpfen Sie sie mit der nächsten Zeile.
- Wenn eine Zeile mit einem Vollbreitenzeichen endet und die nächste Zeile mit einem Vollbreitenzeichen beginnt, werden die Zeilen zusammengefügt.
- Wenn entweder das Ende oder der Anfang einer Zeile kein Vollbreitenzeichen ist, werden sie durch Einfügen eines Leerzeichens zusammengefügt.

Cache-Daten werden basierend auf dem normalisierten Text verwaltet, sodass auch bei Änderungen, die die Normalisierungsergebnisse nicht beeinflussen, die zwischengespeicherten Übersetzungsdaten weiterhin wirksam sind.

Dieser Normalisierungsprozess wird nur für das erste (0.) und für gerade nummerierte Muster durchgeführt. Wenn also zwei Muster wie folgt angegeben sind, wird der Text, der dem ersten Muster entspricht, nach der Normalisierung verarbeitet, und es wird kein Normalisierungsprozess für den Text durchgeführt, der dem zweiten Muster entspricht.

    greple -Mxlate -E normalized -E not-normalized

Verwenden Sie daher das erste Muster für Text, der verarbeitet werden soll, indem mehrere Zeilen zu einer einzigen Zeile kombiniert werden, und verwenden Sie das zweite Muster für vorformatierten Text. Wenn es keinen Text gibt, der dem ersten Muster entspricht, verwenden Sie ein Muster, das nichts entspricht, wie z.B. `(?!)`.

# MASKING

Gelegentlich gibt es Teile von Text, die nicht übersetzt werden sollen. Zum Beispiel Tags in Markdown-Dateien. DeepL schlägt vor, dass in solchen Fällen der nicht zu übersetzende Teil in XML-Tags umgewandelt, übersetzt und dann nach Abschluss der Übersetzung wiederhergestellt wird. Um dies zu unterstützen, ist es möglich, die zu maskierenden Teile der Übersetzung anzugeben.

    --xlate-setopt maskfile=MASKPATTERN

Dies wird jede Zeile der Datei \`MASKPATTERN\` als regulären Ausdruck interpretieren, Zeichenfolgen übersetzen, die ihm entsprechen, und nach der Verarbeitung zurücksetzen. Zeilen, die mit `#` beginnen, werden ignoriert.

Komplexes Muster kann auf mehreren Zeilen mit einem umgekehrten Schrägstrich für einen Zeilenumbruch geschrieben werden.

Wie der Text durch Maskierung transformiert wird, kann durch die **--xlate-mask** Option gesehen werden.

Diese Schnittstelle ist experimentell und kann sich in Zukunft ändern.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Rufen Sie den Übersetzungsprozess für jeden übereinstimmenden Bereich auf.

    Ohne diese Option verhält sich **greple** wie ein normaler Suchbefehl. Sie können also überprüfen, welcher Teil der Datei vor dem Aufrufen der eigentlichen Arbeit übersetzt wird.

    Das Befehlsergebnis wird auf die Standardausgabe geschrieben, also leiten Sie es bei Bedarf um oder verwenden Sie das Modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Die Option **--xlate** ruft die Option **--xlate-color** mit der Option **--color=never** auf.

    Mit der Option **--xlate-fold** wird der konvertierte Text auf die angegebene Breite gefaltet. Die Standardbreite beträgt 70 und kann mit der Option **--xlate-fold-width** festgelegt werden. Vier Spalten sind für den Run-in-Betrieb reserviert, so dass jede Zeile maximal 74 Zeichen enthalten kann.

- **--xlate-engine**=_engine_

    Spezifiziert die zu verwendende Übersetzungs-Engine. Wenn Sie das Engine-Modul direkt angeben, z.B. `-Mxlate::deepl`, müssen Sie diese Option nicht verwenden.

    Zu diesem Zeitpunkt stehen folgende Engines zur Verfügung:

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        Die Schnittstelle von **gpt-4o** ist instabil und kann momentan nicht garantiert korrekt funktionieren.

- **--xlate-labor**
- **--xlabor**

    Anstatt die Übersetzungs-Engine aufzurufen, wird von Ihnen erwartet, dass Sie die Übersetzung durchführen. Nachdem der zu übersetzende Text vorbereitet wurde, wird er in die Zwischenablage kopiert. Sie sollen ihn dann in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und Enter drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. Sie können die verfügbaren Sprachen mit dem Befehl `deepl languages` abrufen, wenn Sie den **DeepL**-Motor verwenden.

- **--xlate-format**=_format_ (Default: `conflict`)

    Geben Sie das Ausgabeformat für den ursprünglichen und übersetzten Text an.

    Die folgenden Formate außer `xtxt` gehen davon aus, dass der zu übersetzende Teil eine Sammlung von Zeilen ist. Tatsächlich ist es möglich, nur einen Teil einer Zeile zu übersetzen, und die Angabe eines Formats außer `xtxt` wird keine sinnvollen Ergebnisse liefern.

    - **conflict**, **cm**

        Original und konvertierter Text werden im [git(1)](http://man.he.net/man1/git) Konfliktmarker-Format gedruckt.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Sie können die ursprüngliche Datei mit dem nächsten [sed(1)](http://man.he.net/man1/sed)-Befehl wiederherstellen.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        &lt;div class="original">

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Number of colon is 7 by default. If you specify colon sequence like `:::::`, it is used instead of 7 colons.

    - **ifdef**

        Original und konvertierter Text werden im [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` Format gedruckt.

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

        Original text:

    - **xtxt**

        Wenn das Format `xtxt` (übersetzter Text) oder unbekannt ist, wird nur der übersetzte Text gedruckt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Übersetzen Sie den folgenden Text Zeile für Zeile ins Deutsche.

- **--xlate-maxline**=_n_ (Default: 0)

    Legen Sie die maximale Anzahl von Textzeilen fest, die gleichzeitig an die API gesendet werden sollen.

    Setzen Sie diesen Wert auf 1, wenn Sie jeweils eine Zeile übersetzen möchten. Diese Option hat Vorrang vor der Option `--xlate-maxlen`.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Sehen Sie das Übersetzungsergebnis in Echtzeit in der STDERR-Ausgabe.

- **--xlate-stripe**

    Verwenden Sie das Modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe), um den übereinstimmenden Teil im Zebra-Streifenmuster anzuzeigen. Dies ist nützlich, wenn die übereinstimmenden Teile direkt aufeinander folgen.

    Die Farbpalette wird entsprechend der Hintergrundfarbe des Terminals umgeschaltet. Wenn Sie dies explizit angeben möchten, können Sie **--xlate-stripe-light** oder **--xlate-stripe-dark** verwenden.

- **--xlate-mask**

    Führen Sie die Maskierungsfunktion aus und zeigen Sie den konvertierten Text ohne Wiederherstellung an.

- **--match-all**

    Setzen Sie den gesamten Text der Datei als Zielbereich.

# CACHE OPTIONS

Das **xlate**-Modul kann den zwischengespeicherten Text der Übersetzung für jede Datei speichern und vor der Ausführung lesen, um den Overhead des Serveranfragen zu eliminieren. Mit der Standard-Cache-Strategie `auto` werden Cache-Daten nur dann beibehalten, wenn die Cache-Datei für die Zieldatei vorhanden ist.

Verwenden Sie **--xlate-cache=clear**, um das Cache-Management zu starten oder alle vorhandenen Cache-Daten zu löschen. Nach der Ausführung mit dieser Option wird eine neue Cache-Datei erstellt, wenn noch keine vorhanden ist, und danach automatisch gewartet.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Die Cache-Datei beibehalten, wenn sie vorhanden ist.

    - `create`

        Leere Cache-Datei erstellen und beenden.

    - `always`, `yes`, `1`

        Cache-Datei beibehalten, solange das Ziel eine normale Datei ist.

    - `clear`

        Löschen Sie zuerst die Cache-Daten.

    - `never`, `no`, `0`

        Verwenden Sie niemals die Cache-Datei, auch wenn sie vorhanden ist.

    - `accumulate`

        Standardmäßig werden nicht verwendete Daten aus der Cache-Datei entfernt. Wenn Sie sie nicht entfernen und in der Datei behalten möchten, verwenden Sie `accumulate`.
- **--xlate-update**

    Diese Option zwingt dazu, die Cache-Datei zu aktualisieren, auch wenn es nicht notwendig ist.

# COMMAND LINE INTERFACE

Sie können dieses Modul ganz einfach über die Befehlszeile verwenden, indem Sie den im Vertrieb enthaltenen Befehl `xlate` verwenden. Sehen Sie sich die `xlate` man-Seite für die Verwendung an.

Der Befehl `xlate` funktioniert in Verbindung mit der Docker-Umgebung, sodass Sie ihn verwenden können, solange Docker verfügbar ist, auch wenn Sie nichts installiert haben. Verwenden Sie die Option `-D` oder `-C`.

Da Makefiles für verschiedene Dokumentenstile bereitgestellt werden, ist eine Übersetzung in andere Sprachen ohne spezielle Angabe möglich. Verwenden Sie die Option `-M`.

Sie können auch die Docker- und Make-Optionen kombinieren, sodass Sie make in einer Docker-Umgebung ausführen können.

Wenn Sie beispielsweise `xlate -GC` ausführen, wird eine Shell mit dem aktuellen Arbeits-Git-Repository gestartet.

Lesen Sie den japanischen Artikel im Abschnitt "Siehe auch" für weitere Details.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -u   force update cache
        -s   silent mode
        -e # translation engine (*deepl, gpt3, gpt4, gpt4o)
        -p # pattern to determine translation area
        -x # file containing mask patterns
        -w # wrap line by # width
        -o # output format (*xtxt, cm, ifdef, space, space+, colon)
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   end of option
        N.B. default is marked as *

    Make options
        -M   run make
        -n   dry-run

    Docker options
        -D * run xlate on the container with the same parameters
        -C * execute following command on the container, or run shell
        -S * start the live container
        -A * attach to the live container
        N.B. -D/-C/-A terminates option handling

        -G   mount git top-level directory
        -H   mount home directory
        -V # specify mount directory
        -U   do not mount
        -R   mount read-only
        -L   do not remove and keep live container
        -K   kill and remove live container
        -E # specify environment variable to be inherited
        -I # docker image or version (default: tecolicom/xlate:version)

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

# EMACS

Laden Sie die Datei `xlate.el` aus dem Repository, um den Befehl `xlate` im Emacs-Editor zu verwenden. Die Funktion `xlate-region` übersetzt den angegebenen Bereich. Die Standardsprache ist `EN-US`, und Sie können die Sprache mit einem Präfixargument angeben.

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

Sie müssen die Befehlszeilentools für DeepL und ChatGPT installieren.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker-Container-Image.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-Bibliothek und CLI-Befehl.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-Bibliothek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI-Befehlszeilenschnittstelle

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Weitere Informationen zum Zieltextmuster finden Sie im Handbuch von **greple**. Verwenden Sie die Optionen **--inside**, **--outside**, **--include** und **--exclude**, um den Übereinstimmungsbereich einzuschränken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Sie können das Modul `-Mupdate` verwenden, um Dateien anhand des Ergebnisses des Befehls **greple** zu ändern.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Verwenden Sie **sdif**, um das Konfliktmarkerformat mit der Option **-V** nebeneinander anzuzeigen.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** Modul verwenden Sie die **--xlate-stripe** Option.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple-Modul zum Übersetzen und Ersetzen nur der notwendigen Teile mit der DeepL API (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generieren von Dokumenten in 15 Sprachen mit dem DeepL API-Modul (auf Japanisch)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatische Übersetzungsumgebung für Docker mit der DeepL API (auf Japanisch)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
