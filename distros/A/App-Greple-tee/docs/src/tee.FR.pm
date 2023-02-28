=encoding utf-8

=head1 NAME

App::Greple::tee - module permettant de remplacer le texte correspondant par le résultat de la commande externe

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Le module B<-Mtee> de Greple envoie les parties de texte correspondantes à la commande de filtrage donnée, et les remplace par le résultat de la commande. L'idée est dérivée de la commande appelée B<teip>. C'est comme si on contournait des données partielles vers la commande de filtrage externe.

La commande de filtrage suit la déclaration du module (C<-Mtee>) et se termine par deux tirets (C<-->). Par exemple, la commande suivante appelle la commande C<tr> avec les arguments C<a-z A-Z> pour le mot correspondant dans les données.

    greple -Mtee tr a-z A-Z -- '\w+' ...

La commande ci-dessus convertit tous les mots correspondants des minuscules aux majuscules. En fait, cet exemple n'est pas très utile car B<greple> peut faire la même chose plus efficacement avec l'option B<--cm>.

Par défaut, la commande est exécutée comme un seul processus, et toutes les données correspondantes lui sont envoyées mélangées. Si le texte correspondant ne se termine pas par une nouvelle ligne, il est ajouté avant et supprimé après. Les données sont mappées ligne par ligne, le nombre de lignes de données d'entrée et de sortie doit donc être identique.

En utilisant l'option B<--discrete>, une commande individuelle est appelée pour chaque pièce appariée. Vous pouvez faire la différence avec les commandes suivantes.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Il n'est pas nécessaire que les lignes de données d'entrée et de sortie soient identiques lorsque l'option B<--discrete> est utilisée.

=head1 OPTIONS

=over 7

=item B<--discrete>

Lancez une nouvelle commande individuellement pour chaque pièce correspondante.

=back

=head1 WHY DO NOT USE TEIP

Tout d'abord, chaque fois que vous pouvez le faire avec la commande B<teip>, utilisez-la. C'est un excellent outil et beaucoup plus rapide que B<greple>.

Comme B<greple> est conçu pour traiter des fichiers de documents, il possède de nombreuses fonctionnalités qui lui sont appropriées, comme les contrôles de la zone de correspondance. Il peut être intéressant d'utiliser B<greple> pour profiter de ces fonctionnalités.

Par ailleurs, B<teip> ne peut pas traiter plusieurs lignes de données comme une seule unité, alors que B<greple> peut exécuter des commandes individuelles sur un fragment de données composé de plusieurs lignes.

=head1 EXAMPLE

La commande suivante trouvera des blocs de texte dans le document de style L<perlpod(1)> inclus dans le fichier du module Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Vous pouvez les traduire par le service DeepL en exécutant la commande ci-dessus combinée avec le module B<-Mtee> qui appelle la commande B<deepl> comme ceci :

    greple -Mtee deepl text --to JA - -- --discrete ...

Comme B<deepl> fonctionne mieux pour la saisie sur une seule ligne, vous pouvez modifier la partie de la commande comme ceci :

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Le module dédié L<App::Greple::xlate::deepl> est plus efficace dans ce but, cependant. En fait, l'indice d'implémentation du module B<tee> vient du module B<xlate>.

=head1 EXAMPLE 2

La prochaine commande trouvera une partie indentée dans le document LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Vous pouvez reformater cette partie en utilisant le module B<tee> avec la commande B<ansifold> :

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
