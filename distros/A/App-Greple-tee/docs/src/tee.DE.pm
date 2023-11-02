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

Version 0.9901

=head1 OPTIONS

=over 7

=item B<--discrete>

Rufen Sie den neuen Befehl einzeln für jedes übereinstimmende Teil auf.

=item B<--fillup>

Kombiniert eine Folge von nicht leeren Zeilen zu einer einzigen Zeile, bevor sie an den Filterbefehl übergeben wird. Zeilenumbrüche zwischen breiten Zeichen werden gelöscht, und andere Zeilenumbrüche werden durch Leerzeichen ersetzt.

=item B<--blockmatch>

Normalerweise wird der Bereich, der dem angegebenen Suchmuster entspricht, an den externen Befehl gesendet. Wenn diese Option angegeben wird, wird nicht der übereinstimmende Bereich, sondern der gesamte Block, der ihn enthält, verarbeitet.

Um zum Beispiel Zeilen mit dem Muster C<foo> an das externe Kommando zu senden, müssen Sie das Muster angeben, das auf die gesamte Zeile passt:

    greple -Mtee cat -n -- '^.*foo.*\n'

Mit der Option B<--blockmatch> kann dies jedoch ganz einfach wie folgt geschehen:

    greple -Mtee cat -n -- foo

Mit der Option B<--blockmatch> verhält sich dieses Modul eher wie die Option B<-g> von L<teip(1)>.

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

package App::Greple::tee;

our $VERSION = "0.9901";

use v5.14;
use warnings;
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use App::cdif::Command;
use Data::Dumper;

our $command;
our $blockmatch;
our $discrete;
our $fillup;

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv;
    }
}

use Unicode::EastAsianWidth;

sub fillup_paragraph {
    (my $s1, local $_, my $s2) = $_[0] =~ /\A(\s*)(.*?)(\s*)\z/s or die;
    s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//g;
    s/\s+/ /g;
    $s1 . $_ . $s2;
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if ($fillup) {
	$data =~ s/^.+(?:\n.+)*/fillup_paragraph(${^MATCH})/pmge;
    }
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    $exec->command($command)->setstdin($data)->update->data // '';
}

sub jammed_call {
    my @need_nl = grep { $_[$_] !~ /\n\z/ } keys @_;
    my @from = @_;
    $from[$_] .= "\n" for @need_nl;
    my @lines = map { int tr/\n/\n/ } @from;
    my $from = join '', @from;
    my $out = call $from;
    my @out = $out =~ /.*\n/g;
    if (@out < sum @lines) {
	die "Unexpected response from command:\n\n$out\n";
    }
    my @to = map { join '', splice @out, 0, $_ } @lines;
    $to[$_] =~ s/\n\z// for @need_nl;
    return @to;
}

my @jammed;

sub postgrep {
    my $grep = shift;
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback}->[0] ]
	      } $grep->result
	    ] ];
    }
    return if $discrete;
    @jammed = my @block = ();
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }
    @jammed = jammed_call @block if @block;
}

sub callback {
    if ($discrete) {
	call { @_ }->{match};
    }
    else {
	shift @jammed // die;
    }
}

1;

__DATA__

builtin --blockmatch $blockmatch
builtin --discrete!  $discrete
builtin --fillup!    $fillup

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
