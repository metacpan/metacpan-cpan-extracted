=encoding utf-8

=head1 NAME

App::Greple::tee - module om gematchte tekst te vervangen door het externe opdrachtresultaat

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple's B<-Mtee> module stuurt gematchte tekstdelen naar het gegeven filtercommando, en vervangt ze door het resultaat van het commando. Het idee is afgeleid van het commando B<teip>. Het is als het omzeilen van gedeeltelijke gegevens naar het externe filtercommando.

Het filtercommando volgt op de moduleverklaring (C<-Mtee>) en eindigt met twee streepjes (C<-->). Bijvoorbeeld, het volgende commando roept commando C<tr> op met C<a-z A-Z> argumenten voor het gezochte woord in de gegevens.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Bovenstaand commando zet alle overeenkomende woorden om van kleine letters naar hoofdletters. Eigenlijk is dit voorbeeld zelf niet zo nuttig omdat B<greple> hetzelfde effectiever kan doen met de optie B<--cm>.

Standaard wordt het commando uitgevoerd als een enkel proces, en alle gematchte gegevens worden erdoor gemengd. Als de gematchte tekst niet eindigt met een newline, wordt hij ervoor toegevoegd en erna verwijderd. De gegevens worden regel voor regel in kaart gebracht, dus het aantal regels invoer- en uitvoergegevens moet identiek zijn.

Met de optie B<--discreet> wordt voor elk gematcht onderdeel een afzonderlijk commando opgeroepen. U kunt het verschil zien aan de hand van de volgende commando's.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Bij gebruik van de optie B<--discreet> hoeven de regels invoer- en uitvoergegevens niet identiek te zijn.

=head1 OPTIONS

=over 7

=item B<--discrete>

Roep nieuw commando individueel op voor elk onderdeel.

=back

=head1 WHY DO NOT USE TEIP

Allereerst, wanneer u het kunt doen met het commando B<-teip>, gebruik het. Het is een uitstekend hulpmiddel en veel sneller dan B<greple>.

Omdat B<greple> is ontworpen om documentbestanden te verwerken, heeft het veel functies die daarvoor geschikt zijn, zoals controles van het matchgebied. Het kan de moeite waard zijn om B<greple> te gebruiken om van die functies te profiteren.

Ook kan B<teip> niet omgaan met meerdere regels gegevens als een enkele eenheid, terwijl B<greple> individuele opdrachten kan uitvoeren op een gegevensbrok die uit meerdere regels bestaat.

=head1 EXAMPLE

Het volgende commando vindt tekstblokken in L<perlpod(1)> stijldocument opgenomen in het Perl-modulebestand.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

U kunt ze vertalen door DeepL service door het bovenstaande commando uit te voeren in combinatie met B<-Mtee> module die het commando B<deepl> als volgt oproept:

    greple -Mtee deepl text --to JA - -- --discrete ...

Omdat B<deepl> beter werkt voor invoer op één regel, kunt u het commandogedeelte als volgt wijzigen:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

De speciale module L<App::Greple::xlate::deepl> is echter effectiever voor dit doel. In feite kwam de implementatiehint van de module B<tee> van de module B<xlate>.

=head1 EXAMPLE 2

Het volgende commando vindt een ingesprongen deel in het LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
U kunt dit deel opnieuw formatteren door de module B<tee> te gebruiken met het commando B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    
=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "0.03";

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

my @jammed;
my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } 0 .. $#{$argv})) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv;
    }
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    $exec->command($command)->setstdin($data)->update->data;
}

sub jammed_call {
    my @need_nl = grep { $_[$_] !~ /\n\z/ } 0 .. $#_;
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

sub postgrep {
    my $grep = shift;
    @jammed = my @block = ();
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback} ]
	      } $grep->result
	    ] ];
    }
    return if $discrete;
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

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
