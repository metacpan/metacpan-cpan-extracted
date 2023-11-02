=encoding utf-8

=head1 NAME

App::Greple::tee - modul de înlocuire a textului cu rezultatul unei comenzi externe

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Modulul B<-Mtee> al lui Greple trimite partea de text potrivit la comanda de filtrare dată și le înlocuiește cu rezultatul comenzii. Ideea este derivată din comanda numită B<teip>. Este ca și cum ar ocoli datele parțiale către comanda de filtrare externă.

Comanda de filtrare urmează după declarația modulului (C<-Mtee>) și se termină prin două liniuțe (C<-->). De exemplu, următoarea comandă apelează comanda C<tr> comanda cu argumente C<a-z A-Z> pentru cuvântul potrivit din date.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Comanda de mai sus convertește toate cuvintele potrivite din minuscule în majuscule. De fapt, acest exemplu în sine nu este atât de util, deoarece B<greple> poate face același lucru mai eficient cu opțiunea B<--cm>.

În mod implicit, comanda este executată ca un singur proces, iar toate datele potrivite sunt trimise către acesta amestecate împreună. În cazul în care textul potrivit nu se termină cu newline, acesta este adăugat înainte și eliminat după. Datele sunt mapate linie cu linie, astfel încât numărul de linii de date de intrare și de ieșire trebuie să fie identic.

Utilizând opțiunea B<--discret>, se apelează o comandă individuală pentru fiecare piesă care se potrivește. Puteți face diferența prin următoarele comenzi.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Liniile de date de intrare și de ieșire nu trebuie să fie identice atunci când se utilizează opțiunea B<--discrete>.

=head1 VERSION

Version 0.9901

=head1 OPTIONS

=over 7

=item B<--discrete>

Invocarea unei noi comenzi individuale pentru fiecare piesă care se potrivește.

=item B<--fillup>

Combină o secvență de linii care nu sunt goale într-o singură linie înainte de a le transmite comenzii de filtrare. Caracterele newline dintre caracterele largi sunt șterse, iar alte caractere newline sunt înlocuite cu spații.

=item B<--blockmatch>

În mod normal, zona care corespunde modelului de căutare specificat este trimisă la comanda externă. În cazul în care se specifică această opțiune, nu zona care corespunde, ci întregul bloc care o conține va fi procesat.

De exemplu, pentru a trimite liniile care conțin modelul C<foo> la comanda externă, trebuie să specificați modelul care se potrivește cu întreaga linie:

    greple -Mtee cat -n -- '^.*foo.*\n'

Dar cu opțiunea B<<--blockmatch>, se poate face la fel de simplu, după cum urmează:

    greple -Mtee cat -n -- foo

Cu opțiunea B<--blockmatch>, acest modul se comportă mai mult ca opțiunea B<-g> a lui L<teip(1)>.

=back

=head1 WHY DO NOT USE TEIP

În primul rând, ori de câte ori puteți face acest lucru cu comanda B<teip>, utilizați-o. Este un instrument excelent și mult mai rapid decât B<greple>.

Deoarece B<greple> este concepută pentru a procesa fișiere document, are multe caracteristici care îi sunt adecvate, cum ar fi controalele zonei de potrivire. Ar putea merita să utilizați B<greple> pentru a profita de aceste caracteristici.

De asemenea, B<teip> nu poate trata mai multe linii de date ca o singură unitate, în timp ce B<greple> poate executa comenzi individuale pe un fragment de date format din mai multe linii.

=head1 EXAMPLE

Următoarea comandă va găsi blocuri de text în interiorul documentului de stil L<perlpod(1)> inclus în fișierul modul Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Puteți să le traduceți prin serviciul DeepL executând comanda de mai sus convinsă cu modulul B<-Mtee> care apelează comanda B<deepl> astfel:

    greple -Mtee deepl text --to JA - -- --fillup ...

Totuși, modulul dedicat L<App::Greple::xlate::deepl> este mai eficient în acest scop. De fapt, sugestia de implementare a modulului B<tee> a venit de la modulul B<xlate>.

=head1 EXAMPLE 2

Următoarea comandă va găsi o parte indentată în documentul LICENȚĂ.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Puteți reformata această parte utilizând modulul B<tee> cu comanda B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Utilizarea opțiunii C<--discrete> necesită mult timp. Deci, puteți utiliza opțiunea C<--separate '\r'> cu C<ansifold> care produce o singură linie folosind caracterul CR în loc de NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Apoi, convertiți caracterul CR în NL prin comanda L<tr(1)> sau alta.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Luați în considerare o situație în care doriți să căutați prin grep șiruri de caractere din liniile fără antet. De exemplu, este posibil să doriți să căutați imagini din comanda C<docker image ls>, dar să lăsați linia de antet. Puteți face acest lucru prin următoarea comandă.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Opțiunea C<-Mline -L 2:> recuperează penultima linie și o trimite la comanda C<grep perl>. Opțiunea C<--discrete> este necesară, dar aceasta este apelată o singură dată, deci nu există niciun dezavantaj de performanță.

În acest caz, C<teip -l 2- -- grep> produce o eroare deoarece numărul de linii de la ieșire este mai mic decât cel de la intrare. Cu toate acestea, rezultatul este destul de satisfăcător :)

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

Este posibil ca opțiunea C<--fillup> să nu funcționeze corect pentru textul coreean.

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
