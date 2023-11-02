# NAME

App::Greple::tee - Modul zum Ersetzen von übereinstimmendem Text durch das Ergebnis eines externen Befehls

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple's **-Mtee** Modul sendet übereinstimmende Textteile an den angegebenen Filterbefehl, und ersetzt sie durch das Ergebnis des Befehls. Die Idee ist von dem Befehl **teip** abgeleitet. Es ist wie das Umgehen von Teildaten an den externen Filterbefehl.

Der Filterbefehl folgt auf die Moduldeklaration (`-Mtee`) und wird durch zwei Bindestriche (`--`) abgeschlossen. Zum Beispiel ruft der nächste Befehl den Befehl `tr` mit den Argumenten `a-z A-Z` für das passende Wort in den Daten auf.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Der obige Befehl wandelt alle übereinstimmenden Wörter von Kleinbuchstaben in Großbuchstaben um. Eigentlich ist dieses Beispiel nicht so nützlich, weil **greple** dasselbe mit der Option **--cm** effektiver machen kann.

Standardmäßig wird der Befehl als ein einziger Prozess ausgeführt, und alle übereinstimmenden Daten werden gemischt an ihn gesendet. Wenn der übereinstimmende Text nicht mit einem Zeilenumbruch endet, wird er davor eingefügt und danach entfernt. Die Daten werden zeilenweise zugeordnet, so dass die Anzahl der Zeilen der Eingabe- und Ausgabedaten identisch sein muss.

Mit der Option **--diskret** wird für jedes übereinstimmende Teil ein eigener Befehl aufgerufen. Sie können den Unterschied anhand der folgenden Befehle erkennen.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Die Zeilen der Ein- und Ausgabedaten müssen nicht identisch sein, wenn die Option **--diskret** verwendet wird.

# VERSION

Version 0.9901

# OPTIONS

- **--discrete**

    Rufen Sie den neuen Befehl einzeln für jedes übereinstimmende Teil auf.

- **--fillup**

    Kombiniert eine Folge von nicht leeren Zeilen zu einer einzigen Zeile, bevor sie an den Filterbefehl übergeben wird. Zeilenumbrüche zwischen breiten Zeichen werden gelöscht, und andere Zeilenumbrüche werden durch Leerzeichen ersetzt.

- **--blockmatch**

    Normalerweise wird der Bereich, der dem angegebenen Suchmuster entspricht, an den externen Befehl gesendet. Wenn diese Option angegeben wird, wird nicht der übereinstimmende Bereich, sondern der gesamte Block, der ihn enthält, verarbeitet.

    Um zum Beispiel Zeilen mit dem Muster `foo` an das externe Kommando zu senden, müssen Sie das Muster angeben, das auf die gesamte Zeile passt:

        greple -Mtee cat -n -- '^.*foo.*\n'

    Mit der Option **--blockmatch** kann dies jedoch ganz einfach wie folgt geschehen:

        greple -Mtee cat -n -- foo

    Mit der Option **--blockmatch** verhält sich dieses Modul eher wie die Option **-g** von [teip(1)](http://man.he.net/man1/teip).

# WHY DO NOT USE TEIP

Vor allem, wenn Sie den Befehl **teip** verwenden können, sollten Sie ihn einsetzen. Er ist ein hervorragendes Werkzeug und viel schneller als **greple**.

Da **greple** für die Verarbeitung von Dokumentdateien konzipiert ist, verfügt es über viele Funktionen, die dafür geeignet sind, wie z. B. die Steuerung des Abgleichbereichs. Es könnte sich lohnen, **greple** zu verwenden, um diese Funktionen zu nutzen.

Außerdem kann **teip** nicht mehrere Datenzeilen als eine Einheit verarbeiten, während **greple** einzelne Befehle auf einem aus mehreren Zeilen bestehenden Datenpaket ausführen kann.

# EXAMPLE

Der nächste Befehl findet Textblöcke innerhalb des [perlpod(1)](http://man.he.net/man1/perlpod) Stildokuments, das in der Perl-Moduldatei enthalten ist.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Sie können sie mit dem Dienst DeepL übersetzen, indem Sie den obigen Befehl zusammen mit dem Modul **-Mtee** ausführen, das den Befehl **deepl** wie folgt aufruft:

    greple -Mtee deepl text --to JA - -- --fillup ...

Das spezielle Modul [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) ist für diesen Zweck jedoch effektiver. Tatsächlich stammt der Implementierungshinweis des Moduls **tee** aus dem Modul **xlate**.

# EXAMPLE 2

Der nächste Befehl wird einen eingerückten Teil im LICENSE-Dokument finden.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Sie können diesen Teil umformatieren, indem Sie das Modul **tee** mit dem Befehl **ansifold** verwenden:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Die Verwendung der Option `--diskret` ist zeitaufwendig. Sie können daher die Option `--separate '\r'` mit `ansifold` verwenden, die eine einzelne Zeile mit CR-Zeichen anstelle von NL erzeugt.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Dann konvertieren Sie das CR-Zeichen mit dem Befehl [tr(1)](http://man.he.net/man1/tr) oder ähnlichem in NL.

    ... | tr '\r' '\n'

# EXAMPLE 3

Stellen Sie sich eine Situation vor, in der Sie nach Zeichenketten in Nicht-Kopfzeilen suchen wollen. Zum Beispiel könnten Sie nach Bildern aus dem Befehl `docker image ls` suchen, aber die Kopfzeile weglassen. Sie können dies mit folgendem Befehl tun.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Option `-Mline -L 2:` holt die vorletzte Zeile und sendet sie an den Befehl `grep perl`. Die Option `--discrete` ist erforderlich, aber sie wird nur einmal aufgerufen, so dass es keine Leistungseinbußen gibt.

In diesem Fall erzeugt `teip -l 2- -- grep` einen Fehler, weil die Anzahl der Zeilen in der Ausgabe geringer ist als die der Eingabe. Das Ergebnis ist jedoch recht zufriedenstellend :)

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# BUGS

Die Option `--fillup` funktioniert möglicherweise nicht korrekt für koreanischen Text.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
