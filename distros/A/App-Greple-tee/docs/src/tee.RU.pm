=encoding utf-8

=head1 NAME

App::Greple::tee - модуль для замены совпадающего текста на результат внешней команды

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Модуль Greple's B<-Mtee> посылает совпавшие части текста заданной команде фильтра и заменяет их результатом команды. Идея взята из команды B<teip>. Это подобно обходу частичных данных внешней командой фильтрации.

Команда фильтрации следует за объявлением модуля (C<-Mtee>) и заканчивается двумя тире (C<-->). Например, следующая команда вызывает команду C<tr> с аргументами C<a-z A-Z> для найденного слова в данных.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Приведенная выше команда преобразует все совпадающие слова из нижнего регистра в верхний. На самом деле этот пример не так полезен, потому что B<greple> может сделать то же самое более эффективно с помощью опции B<--cm>.

По умолчанию команда выполняется как один процесс, и все совпавшие данные передаются ему вперемешку. Если совпадающий текст не заканчивается новой строкой, она добавляется до и удаляется после. Данные сопоставляются построчно, поэтому количество строк входных и выходных данных должно быть одинаковым.

При использовании опции B<--discrete> для каждой сопоставленной детали вызывается отдельная команда. Разницу можно определить по следующим командам.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Строки входных и выходных данных не должны быть одинаковыми при использовании опции B<--discrete>.

=head1 VERSION

Version 0.9901

=head1 OPTIONS

=over 7

=item B<--discrete>

Вызвать новую команду индивидуально для каждой сопоставленной детали.

=item B<--fillup>

Объедините последовательность непустых строк в одну строку перед передачей их команде фильтра. Символы новой строки между широкими символами удаляются, а другие символы новой строки заменяются пробелами.

=item B<--blockmatch>

Обычно внешней команде передается область, соответствующая заданному шаблону поиска. При указании этой опции будет обрабатываться не совпадающая область, а весь блок, содержащий ее.

Например, чтобы отправить внешней команде строки, содержащие шаблон C<foo>, необходимо указать шаблон, соответствующий всей строке:

    greple -Mtee cat -n -- '^.*foo.*\n'

Но с помощью опции B<--blockmatch> это можно сделать следующим образом:

    greple -Mtee cat -n -- foo

С опцией B<--blockmatch> этот модуль ведет себя подобно опции B<-g> в L<teip(1)>.

=back

=head1 WHY DO NOT USE TEIP

Прежде всего, всегда, когда вы можете сделать это с помощью команды B<teip>, используйте ее. Это отличный инструмент и намного быстрее, чем B<greple>.

Поскольку B<greple> предназначен для обработки файлов документов, он имеет много функций, которые подходят для этого, например, управление областью соответствия. Возможно, стоит использовать B<greple>, чтобы воспользоваться этими возможностями.

Кроме того, B<teip> не может обрабатывать несколько строк данных как единое целое, в то время как B<greple> может выполнять отдельные команды на куске данных, состоящем из нескольких строк.

=head1 EXAMPLE

Следующая команда найдет текстовые блоки внутри документа стиля L<perlpod(1)>, включенного в файл модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Вы можете перевести их с помощью сервиса DeepL, выполнив приведенную выше команду, соединенную с модулем B<-Mtee>, который вызывает команду B<deepl> следующим образом:

    greple -Mtee deepl text --to JA - -- --fillup ...

Однако для этой цели более эффективен специализированный модуль L<App::Greple::xlate::deepl>. Фактически, подсказка для реализации модуля B<tee> пришла из модуля B<xlate>.

=head1 EXAMPLE 2

Следующая команда обнаружит в документе LICENSE часть с отступами.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Вы можете переформатировать эту часть, используя модуль B<tee> с командой B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Использование опции C<--discrete> отнимает много времени. Поэтому вы можете использовать опцию C<--separate '\r'> вместе с C<ansifold>, которая создает одну строку, используя символ CR вместо NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Затем преобразуйте символ CR в NL с помощью команды L<tr(1)> или другой.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Рассмотрим ситуацию, когда вы хотите искать строки в строках, не относящихся к заголовкам. Например, вы можете захотеть найти изображения из команды C<docker image ls>, но оставить строку заголовка. Это можно сделать с помощью следующей команды.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Опция C<-Mline -L 2:> извлекает предпоследние строки и отправляет их команде C<grep perl>. Опция C<--discrete> необходима, но она вызывается только один раз, поэтому недостатка в производительности нет.

В данном случае команда C<teip -l 2- -- grep> выдает ошибку, так как количество строк на выходе меньше, чем на входе. Однако результат вполне удовлетворительный :)

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

Опция C<--fillup> может работать некорректно для корейского текста.

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
