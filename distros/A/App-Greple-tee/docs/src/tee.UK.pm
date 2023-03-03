=encoding utf-8

=head1 NAME

App::Greple::tee - модуль для заміни знайденого тексту на результат зовнішньої команди

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Модуль B<-Mtee> у Greple надсилає частину тексту, що відповідає заданій команді фільтрації, і замінює її на результат команди. Ідея походить від команди з назвою B<teip>. Це схоже на пересилання частини даних до зовнішньої команди фільтрації.

Команда фільтрації слідує за оголошенням модуля (C<-Mtee>) і завершується двома тире (C<-->). Наприклад, наступна команда викликає команду C<tr> з аргументами C<a-z A-Z> для знайденого слова у даних.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Наведена вище команда перетворює всі знайдені слова з малих літер у великі. Насправді цей приклад не дуже корисний, оскільки B<greple> може зробити те саме ефективніше за допомогою опції B<--cm>.

За замовчуванням команда виконується як окремий процес, і всі знайдені дані надсилаються до нього упереміш. Якщо знайдений текст не закінчується новим рядком, його буде додано до початку і видалено після закінчення. Дані зіставляються рядок за рядком, тому кількість рядків вхідних і вихідних даних має бути однаковою.

Використовуючи опцію B<--discrete>, викликається окрема команда для кожної деталі, що збігається. Ви можете побачити різницю за допомогою наступних команд.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

При використанні опції B<--discrete> рядки вхідних і вихідних даних не обов'язково повинні бути однаковими.

=head1 OPTIONS

=over 7

=item B<--discrete>

Викликати нову команду окремо для кожної знайденої частини.

=back

=head1 WHY DO NOT USE TEIP

Перш за все, якщо ви можете зробити це за допомогою команди B<teip>, використовуйте її. Вона є чудовим інструментом і працює набагато швидше, ніж B<greple>.

Оскільки B<greple> призначено для обробки файлів документів, вона має багато можливостей, які підходять для неї, наприклад, елементи керування областями збігів. Можливо, варто скористатися перевагами B<greple>, щоб скористатися цими можливостями.

Крім того, B<teip> не може обробляти декілька рядків даних як єдине ціле, тоді як B<greple> може виконувати окремі команди над фрагментом даних, що складається з декількох рядків.

=head1 EXAMPLE

Наступна команда знайде текстові блоки у документі стилю L<perlpod(1)>, включеному до файлу модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Ви можете перекласти їх за допомогою сервісу DeepL, виконавши наведену вище команду, узгоджену з модулем B<-Mtee>, який викликає команду B<deepl> таким чином:

    greple -Mtee deepl text --to JA - -- --discrete ...

Оскільки B<deepl> краще працює з однорядковим введенням, ви можете змінити частину команди таким чином:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Однак для цієї мети ефективніше використовувати спеціальний модуль L<App::Greple::xlate::deepl>. Насправді, підказка щодо реалізації модуля B<tee> прийшла з модуля B<xlate>.

=head1 EXAMPLE 2

Наступна команда знайде у документі LICENSE частину з відступами.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Ви можете переформатувати цю частину за допомогою модуля B<tee> з командою B<ansifold>:

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

L<App::Greple::xlate>.

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
