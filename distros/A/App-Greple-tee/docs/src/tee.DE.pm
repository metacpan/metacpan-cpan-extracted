=encoding utf-8

=head1 NAME

App::Greple::tee - Modul zum Ersetzen von übereinstimmendem Text durch das Ergebnis eines externen Befehls

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple's B<-Mtee> Modul sendet übereinstimmende Textteile an den angegebenen Filterbefehl, und ersetzt sie durch das Ergebnis des Befehls. Die Idee ist von dem Befehl B<teip> abgeleitet. Es ist wie das Umgehen von Teildaten an den externen Filterbefehl.

Der Filterbefehl folgt auf die Moduldeklaration (C<-Mtee>) und wird durch zwei Bindestriche (C<-->) abgeschlossen. Zum Beispiel ruft der nächste Befehl den Befehl C<tr> mit den Argumenten C<a-z A-Z> für das passende Wort in den Daten auf.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Der obige Befehl wandelt alle übereinstimmenden Wörter von Kleinbuchstaben in Großbuchstaben um. Eigentlich ist dieses Beispiel nicht so nützlich, weil B<greple> dasselbe mit der Option B<--cm> effektiver machen kann.

Standardmäßig wird der Befehl als ein einziger Prozess ausgeführt, und alle übereinstimmenden Daten werden gemischt an ihn gesendet. Wenn der übereinstimmende Text nicht mit einem Zeilenumbruch endet, wird er davor eingefügt und danach entfernt. Die Daten werden zeilenweise zugeordnet, so dass die Anzahl der Zeilen der Eingabe- und Ausgabedaten identisch sein muss.

Mit der Option B<--diskret> wird für jedes übereinstimmende Teil ein eigener Befehl aufgerufen. Sie können den Unterschied anhand der folgenden Befehle erkennen.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Die Zeilen der Ein- und Ausgabedaten müssen nicht identisch sein, wenn die Option B<--diskret> verwendet wird.

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

Rufen Sie den neuen Befehl einzeln für jedes übereinstimmende Teil auf.

=item B<--fillup>

Kombiniert eine Folge von nicht leeren Zeilen zu einer einzigen Zeile, bevor sie an den Filterbefehl übergeben wird. Zeilenumbrüche zwischen breiten Zeichen werden gelöscht, und andere Zeilenumbrüche werden durch Leerzeichen ersetzt.

=item B<--blocks>

Normalerweise wird der Bereich, der dem angegebenen Suchmuster entspricht, an den externen Befehl gesendet. Wenn diese Option angegeben wird, wird nicht der übereinstimmende Bereich, sondern der gesamte Block, der ihn enthält, verarbeitet.

Um zum Beispiel Zeilen mit dem Muster C<foo> an das externe Kommando zu senden, müssen Sie das Muster angeben, das auf die gesamte Zeile passt:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Aber mit der Option B<--blocks> kann es so einfach wie folgt gemacht werden:

    greple -Mtee cat -n -- foo --blocks

Mit der Option B<--blocks> verhält sich dieses Modul eher wie L<teip(1)> mit der Option B<-g>. Ansonsten ist das Verhalten ähnlich wie bei L<teip(1)> mit der Option B<-o>.

Verwenden Sie die Option B<--blocks> nicht mit der Option B<--all>, da der Block die gesamten Daten sein werden.

=item B<--squeeze>

Kombiniert zwei oder mehr aufeinanderfolgende Zeilenumbruchzeichen zu einem.

=back

=head1 WHY DO NOT USE TEIP

Vor allem, wenn Sie den Befehl B<teip> verwenden können, sollten Sie ihn einsetzen. Er ist ein hervorragendes Werkzeug und viel schneller als B<greple>.

Da B<greple> für die Verarbeitung von Dokumentdateien konzipiert ist, verfügt es über viele Funktionen, die dafür geeignet sind, wie z. B. die Steuerung des Abgleichbereichs. Es könnte sich lohnen, B<greple> zu verwenden, um diese Funktionen zu nutzen.

Außerdem kann B<teip> nicht mehrere Datenzeilen als eine Einheit verarbeiten, während B<greple> einzelne Befehle auf einem aus mehreren Zeilen bestehenden Datenpaket ausführen kann.

=head1 EXAMPLE

Der nächste Befehl findet Textblöcke innerhalb des L<perlpod(1)> Stildokuments, das in der Perl-Moduldatei enthalten ist.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Sie können sie mit dem Dienst DeepL übersetzen, indem Sie den obigen Befehl zusammen mit dem Modul B<-Mtee> ausführen, das den Befehl B<deepl> wie folgt aufruft:

    greple -Mtee deepl text --to JA - -- --fillup ...

Das spezielle Modul L<App::Greple::xlate::deepl> ist für diesen Zweck jedoch effektiver. Tatsächlich stammt der Implementierungshinweis des Moduls B<tee> aus dem Modul B<xlate>.

=head1 EXAMPLE 2

Der nächste Befehl wird einen eingerückten Teil im LICENSE-Dokument finden.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Sie können diesen Teil umformatieren, indem Sie das Modul B<tee> mit dem Befehl B<ansifold> verwenden:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Die Verwendung der Option C<--diskret> ist zeitaufwendig. Sie können daher die Option C<--separate '\r'> mit C<ansifold> verwenden, die eine einzelne Zeile mit CR-Zeichen anstelle von NL erzeugt.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Dann konvertieren Sie das CR-Zeichen mit dem Befehl L<tr(1)> oder ähnlichem in NL.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Stellen Sie sich eine Situation vor, in der Sie nach Zeichenketten in Nicht-Kopfzeilen suchen wollen. Zum Beispiel könnten Sie nach Bildern aus dem Befehl C<docker image ls> suchen, aber die Kopfzeile weglassen. Sie können dies mit folgendem Befehl tun.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Option C<-Mline -L 2:> holt die vorletzte Zeile und sendet sie an den Befehl C<grep perl>. Die Option C<--discrete> ist erforderlich, aber sie wird nur einmal aufgerufen, so dass es keine Leistungseinbußen gibt.

In diesem Fall erzeugt C<teip -l 2- -- grep> einen Fehler, weil die Anzahl der Zeilen in der Ausgabe geringer ist als die der Eingabe. Das Ergebnis ist jedoch recht zufriedenstellend :)

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

=head1 BUGS

Die Option C<--fillup> funktioniert möglicherweise nicht korrekt für koreanischen Text.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
