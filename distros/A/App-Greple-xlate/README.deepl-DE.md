# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für Greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.31

# DESCRIPTION

**Greple** **xlate** Modul findet die gewünschten Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit sind die Module DeepL (`deepl.pm`) und ChatGPT (`gpt3.pm`) als Backend-Engine implementiert. Experimentelle Unterstützung für gpt-4 ist ebenfalls enthalten.

Wenn Sie normale Textblöcke in einem Dokument übersetzen wollen, das im Pod-Stil von Perl geschrieben ist, verwenden Sie den Befehl **greple** mit dem Modul `xlate::deepl` und `perl` wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

In diesem Befehl bedeutet die Zeichenkette `^(\w.*\n)+` aufeinanderfolgende Zeilen, die mit einem alphanumerischen Buchstaben beginnen. Dieser Befehl zeigt den zu übersetzenden Bereich hervorgehoben an. Die Option **--all** wird verwendet, um den gesamten Text zu erzeugen.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Fügen Sie dann die Option `--xlate` hinzu, um den ausgewählten Bereich zu übersetzen. Dann werden die gewünschten Abschnitte gefunden und durch die Ausgabe des Befehls **deepl** ersetzt.

Standardmäßig werden der ursprüngliche und der übersetzte Text im Format "conflict marker" gedruckt, das mit [git(1)](http://man.he.net/man1/git) kompatibel ist. Wenn Sie das `ifdef`-Format verwenden, können Sie den gewünschten Teil mit dem Befehl [unifdef(1)](http://man.he.net/man1/unifdef) leicht erhalten. Das Ausgabeformat kann mit der Option **--xlate-format** festgelegt werden.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Wenn Sie den gesamten Text übersetzen wollen, verwenden Sie die Option **--match-all**. Dies ist eine Abkürzung zur Angabe des Musters `(?s).+`, das auf den gesamten Text passt.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Rufen Sie den Übersetzungsprozess für jeden übereinstimmenden Bereich auf.

    Ohne diese Option verhält sich **greple** wie ein normaler Suchbefehl. Sie können also prüfen, welcher Teil der Datei Gegenstand der Übersetzung sein wird, bevor Sie die eigentliche Arbeit aufrufen.

    Das Ergebnis des Befehls wird im Standard-Output ausgegeben, also leiten Sie es bei Bedarf in eine Datei um oder verwenden Sie das Modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Die Option **--xlate** ruft die Option **--xlate-color** mit der Option **--color=never** auf.

    Mit der Option **--xlate-fold** wird der konvertierte Text um die angegebene Breite gefaltet. Die Standardbreite ist 70 und kann mit der Option **--xlate-fold-width** eingestellt werden. Vier Spalten sind für den Einlaufvorgang reserviert, so dass jede Zeile maximal 74 Zeichen enthalten kann.

- **--xlate-engine**=_engine_

    Gibt die zu verwendende Übersetzungs-Engine an. Wenn Sie das Engine-Modul direkt angeben, wie z.B. `-Mxlate::deepl`, brauchen Sie diese Option nicht zu verwenden.

- **--xlate-labor**
- **--xlabor**

    Anstatt die Übersetzungsmaschine aufzurufen, wird von Ihnen erwartet, dass Sie für sie arbeiten. Nachdem der zu übersetzende Text vorbereitet wurde, wird er in die Zwischenablage kopiert. Es wird erwartet, dass Sie sie in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und Return drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. Sie können die verfügbaren Sprachen mit dem Befehl `deepl languages` abrufen, wenn Sie die Engine **DeepL** verwenden.

- **--xlate-format**=_format_ (Default: `conflict`)

    Geben Sie das Ausgabeformat für den Originaltext und den übersetzten Text an.

    - **conflict**, **cm**

        Original und konvertierter Text werden im Format [git(1)](http://man.he.net/man1/git) conflict marker gedruckt.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Sie können die Originaldatei mit dem nächsten Befehl [sed(1)](http://man.he.net/man1/sed) wiederherstellen.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Original und konvertierter Text werden im [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` Format gedruckt.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Mit dem Befehl **unifdef** können Sie nur den japanischen Text wiederherstellen:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Original und konvertierter Text werden durch eine einzelne Leerzeile getrennt gedruckt.

    - **xtxt**

        Wenn das Format `xtxt` (übersetzter Text) oder unbekannt ist, wird nur der übersetzte Text gedruckt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Geben Sie die maximale Länge des Textes an, der auf einmal an die API gesendet werden soll. Der Standardwert ist wie beim kostenlosen DeepL account service: 128K für die API (**--xlate**) und 5000 für die Zwischenablage-Schnittstelle (**--xlate-labor**). Sie können diese Werte ändern, wenn Sie den Pro-Dienst verwenden.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Sehen Sie das Ergebnis der Übersetzung in Echtzeit in der STDERR-Ausgabe.

- **--match-all**

    Legen Sie den gesamten Text der Datei als Zielbereich fest.

# CACHE OPTIONS

Das Modul **xlate** kann den übersetzten Text für jede Datei im Cache speichern und vor der Ausführung lesen, um den Overhead durch Anfragen an den Server zu vermeiden. Bei der Standard-Cache-Strategie `auto` werden die Cache-Daten nur beibehalten, wenn die Cache-Datei für die Zieldatei existiert.

- --cache-clear

    Die Option **--cache-clear** kann verwendet werden, um die Cache-Verwaltung zu starten oder um alle vorhandenen Cache-Daten zu aktualisieren. Wenn diese Option ausgeführt wird, wird eine neue Cache-Datei erstellt, falls noch keine vorhanden ist, und anschließend automatisch beibehalten.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Behalten Sie die Cache-Datei bei, wenn sie vorhanden ist.

    - `create`

        Leere Cachedatei erstellen und beenden.

    - `always`, `yes`, `1`

        Cache trotzdem beibehalten, sofern das Ziel eine normale Datei ist.

    - `clear`

        Löschen Sie zuerst die Cache-Daten.

    - `never`, `no`, `0`

        Cache-Datei nie verwenden, auch wenn sie vorhanden ist.

    - `accumulate`

        In der Standardeinstellung werden nicht verwendete Daten aus der Cache-Datei entfernt. Wenn Sie sie nicht entfernen und in der Datei behalten wollen, verwenden Sie `accumulate`.

# COMMAND LINE INTERFACE

Sie können dieses Modul einfach von der Kommandozeile aus verwenden, indem Sie den in der Distribution enthaltenen Befehl `xlate` benutzen. Informationen zur Verwendung finden Sie in der `xlate`-Hilfe.

Der Befehl `xlate` arbeitet mit der Docker-Umgebung zusammen, d.h. selbst wenn Sie nichts installiert haben, können Sie ihn verwenden, solange Docker verfügbar ist. Verwenden Sie die Option `-D` oder `-C`.

Da Makefiles für verschiedene Dokumentstile zur Verfügung gestellt werden, ist auch die Übersetzung in andere Sprachen ohne besondere Angaben möglich. Verwenden Sie die Option `-M`.

Sie können auch die Optionen Docker und make kombinieren, so dass Sie make in einer Docker-Umgebung ausführen können.

Ein Aufruf wie `xlate -GC` startet eine Shell mit dem aktuellen Git-Repository.

Lesen Sie den japanischen Artikel im Abschnitt ["SEE ALSO"](#see-also) für weitere Einzelheiten.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
        -w # wrap line by # width
        -o # output format (default "xtxt", or "cm", "ifdef")
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
        -M   run make
        -n   dry-run
    Docker options
        -G   mount git top-level directory
        -B   run in non-interactive (batch) mode
        -R   mount read-only
        -E * specify environment variable to be inherited
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

Laden Sie die Datei `xlate.el` aus dem Repository, um den Befehl `xlate` im Emacs-Editor zu verwenden. Die Funktion `xlate-region` übersetzt die angegebene Region. Die Standardsprache ist `EN-US` und Sie können die Sprache mit dem Präfix-Argument angeben.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Legen Sie Ihren Authentifizierungsschlüssel für den Dienst DeepL fest.

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

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python-Bibliothek und CLI-Befehl.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python-Bibliothek

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI Kommandozeilen-Schnittstelle

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lesen Sie das Handbuch **greple** für Details über Zieltextmuster. Verwenden Sie die Optionen **--inside**, **--outside**, **--include**, **--exclude**, um den Suchbereich einzuschränken.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Sie können das Modul `-Mupdate` verwenden, um Dateien anhand des Ergebnisses des Befehls **greple** zu ändern.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Verwenden Sie **sdif**, um das Format der Konfliktmarkierung zusammen mit der Option **-V** anzuzeigen.

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

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
