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

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

Викликати нову команду окремо для кожної знайденої частини.

=item B<--fillup>

Об'єднайте послідовність непустих рядків в один рядок, перш ніж передавати їх команді фільтрації. Символи нового рядка між широкими символами видаляються, а інші символи нового рядка замінюються пробілами.

=item B<--blocks>

Зазвичай зовнішній команді надсилається область, що відповідає заданому шаблону пошуку. Якщо вказати цю опцію, то буде оброблено не область, а весь блок, що її містить.

Наприклад, щоб надіслати зовнішній команді рядки, що містять шаблон C<foo>, потрібно вказати шаблон, який збігається з усім рядком:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Але з опцією B<--blocks> це можна зробити так само просто:

    greple -Mtee cat -n -- foo --blocks

З опцією B<--blocks> цей модуль поводитиметься більш подібно до L<teip(1)> з опцією B<-g>. В іншому випадку поведінка подібна до поведінки L<teip(1)> з опцією B<-o>.

Не використовуйте B<--blocks> з опцією B<--all>, оскільки блоком будуть всі дані.

=item B<--squeeze>

Об'єднує два або більше символів нового рядка, що йдуть підряд, в один.

=back

=head1 WHY DO NOT USE TEIP

Перш за все, якщо ви можете зробити це за допомогою команди B<teip>, використовуйте її. Вона є чудовим інструментом і працює набагато швидше, ніж B<greple>.

Оскільки B<greple> призначено для обробки файлів документів, вона має багато можливостей, які підходять для неї, наприклад, елементи керування областями збігів. Можливо, варто скористатися перевагами B<greple>, щоб скористатися цими можливостями.

Крім того, B<teip> не може обробляти декілька рядків даних як єдине ціле, тоді як B<greple> може виконувати окремі команди над фрагментом даних, що складається з декількох рядків.

=head1 EXAMPLE

Наступна команда знайде текстові блоки у документі стилю L<perlpod(1)>, включеному до файлу модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Ви можете перекласти їх за допомогою сервісу DeepL, виконавши наведену вище команду, узгоджену з модулем B<-Mtee>, який викликає команду B<deepl> таким чином:

    greple -Mtee deepl text --to JA - -- --fillup ...

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

Використання опції C<--discrete> забирає багато часу. Тому ви можете використовувати опцію C<--separate '\r'> з C<ansifold>, яка створює один рядок з використанням символу CR замість NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Потім перетворіть CR символ на NL за допомогою команди L<tr(1)> або іншої.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Розглянемо ситуацію, у якій вам потрібно шукати рядки з рядків, що не є заголовками. Наприклад, ви можете шукати зображення з команди C<docker image ls>, але залишити заголовний рядок. Це можна зробити за допомогою наступної команди.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Параметр C<-Mline -L 2:> витягує передостанні рядки і надсилає їх команді C<grep perl>. Опція C<--discrete> є обов'язковою, але вона викликається лише один раз, тому на продуктивності це не позначається.

У цьому випадку C<teip -l 2- -- grep> видає помилку, оскільки кількість рядків на виході менша, ніж на вході. Проте, результат цілком задовільний :)

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>.

=head1 BUGS

Опція C<--fillup> може працювати некоректно для корейського тексту.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
