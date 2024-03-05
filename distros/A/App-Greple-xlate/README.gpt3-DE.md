# NAME

App::Greple::xlate - Übersetzungsunterstützungsmodul für greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.31

# DESCRIPTION

Das **Greple** **xlate** Modul findet gewünschte Textblöcke und ersetzt sie durch den übersetzten Text. Derzeit sind die DeepL (`deepl.pm`) und ChatGPT (`gpt3.pm`) Module als Backend-Engine implementiert. Experimentelle Unterstützung für gpt-4 ist ebenfalls enthalten.

Wenn Sie normale Textblöcke in einem Dokument übersetzen möchten, das im Perl-Pod-Stil geschrieben ist, verwenden Sie den **greple**-Befehl mit dem `xlate::deepl`- und `perl`-Modul wie folgt:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

In diesem Befehl bedeutet das Musterzeichenfolge `^(\w.*\n)+` aufeinanderfolgende Zeilen, die mit einem alphanumerischen Buchstaben beginnen. Dieser Befehl zeigt den zu übersetzenden Bereich hervorgehoben an. Die Option **--all** wird verwendet, um den gesamten Text zu erzeugen.

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

- **--xlate-labor**
- **--xlabor**

    Anstatt die Übersetzungs-Engine aufzurufen, wird von Ihnen erwartet, dass Sie die Übersetzung durchführen. Nachdem der zu übersetzende Text vorbereitet wurde, wird er in die Zwischenablage kopiert. Sie sollen ihn dann in das Formular einfügen, das Ergebnis in die Zwischenablage kopieren und Enter drücken.

- **--xlate-to** (Default: `EN-US`)

    Geben Sie die Zielsprache an. Sie können die verfügbaren Sprachen mit dem Befehl `deepl languages` abrufen, wenn Sie den **DeepL**-Motor verwenden.

- **--xlate-format**=_format_ (Default: `conflict`)

    Geben Sie das Ausgabeformat für den ursprünglichen und übersetzten Text an.

    - **conflict**, **cm**

        Original und konvertierter Text werden im [git(1)](http://man.he.net/man1/git) Konfliktmarker-Format gedruckt.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Sie können die ursprüngliche Datei mit dem nächsten [sed(1)](http://man.he.net/man1/sed)-Befehl wiederherstellen.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

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

        Original und konvertierter Text werden durch eine einzelne Leerzeile getrennt gedruckt.

    - **xtxt**

        Wenn das Format `xtxt` (übersetzter Text) oder unbekannt ist, wird nur der übersetzte Text gedruckt.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Übersetzen Sie den folgenden Text Zeile für Zeile ins Deutsche.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Sehen Sie das Übersetzungsergebnis in Echtzeit in der STDERR-Ausgabe.

- **--match-all**

    Setzen Sie den gesamten Text der Datei als Zielbereich.

# CACHE OPTIONS

Das **xlate**-Modul kann den zwischengespeicherten Text der Übersetzung für jede Datei speichern und vor der Ausführung lesen, um den Overhead des Serveranfragen zu eliminieren. Mit der Standard-Cache-Strategie `auto` werden Cache-Daten nur dann beibehalten, wenn die Cache-Datei für die Zieldatei vorhanden ist.

- --cache-clear

    Die Option **--cache-clear** kann verwendet werden, um das Cache-Management zu initiieren oder alle vorhandenen Cache-Daten zu aktualisieren. Sobald sie mit dieser Option ausgeführt wird, wird eine neue Cache-Datei erstellt, wenn sie nicht vorhanden ist, und danach automatisch gewartet.

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

# COMMAND LINE INTERFACE

Sie können dieses Modul problemlos über die Befehlszeile verwenden, indem Sie den in der Distribution enthaltenen Befehl `xlate` verwenden. Sehen Sie sich die Hilfeinformationen von `xlate` für die Verwendung an.

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

Laden Sie die Datei `xlate.el` aus dem Repository, um den Befehl `xlate` im Emacs-Editor zu verwenden. Die Funktion `xlate-region` übersetzt den angegebenen Bereich. Die Standardsprache ist `EN-US`, und Sie können die Sprache mit einem Präfixargument angeben.

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

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

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

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
