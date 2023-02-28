# NAME

App::Greple::tee - модуль для заміни знайденого тексту на результат зовнішньої команди

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Модуль **-Mtee** у Greple надсилає частину тексту, що відповідає заданій команді фільтрації, і замінює її на результат команди. Ідея походить від команди з назвою **teip**. Це схоже на пересилання частини даних до зовнішньої команди фільтрації.

Команда фільтрації слідує за оголошенням модуля (`-Mtee`) і завершується двома тире (`--`). Наприклад, наступна команда викликає команду `tr` з аргументами `a-z A-Z` для знайденого слова у даних.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Наведена вище команда перетворює всі знайдені слова з малих літер у великі. Насправді цей приклад не дуже корисний, оскільки **greple** може зробити те саме ефективніше за допомогою опції **--cm**.

За замовчуванням команда виконується як окремий процес, і всі знайдені дані надсилаються до нього упереміш. Якщо знайдений текст не закінчується новим рядком, його буде додано до початку і видалено після закінчення. Дані зіставляються рядок за рядком, тому кількість рядків вхідних і вихідних даних має бути однаковою.

Використовуючи опцію **--discrete**, викликається окрема команда для кожної деталі, що збігається. Ви можете побачити різницю за допомогою наступних команд.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

При використанні опції **--discrete** рядки вхідних і вихідних даних не обов'язково повинні бути однаковими.

# OPTIONS

- **--discrete**

    Викликати нову команду окремо для кожної знайденої частини.

# WHY DO NOT USE TEIP

Перш за все, якщо ви можете зробити це за допомогою команди **teip**, використовуйте її. Вона є чудовим інструментом і працює набагато швидше, ніж **greple**.

Оскільки **greple** призначено для обробки файлів документів, вона має багато можливостей, які підходять для неї, наприклад, елементи керування областями збігів. Можливо, варто скористатися перевагами **greple**, щоб скористатися цими можливостями.

Крім того, **teip** не може обробляти декілька рядків даних як єдине ціле, тоді як **greple** може виконувати окремі команди над фрагментом даних, що складається з декількох рядків.

# EXAMPLE

Наступна команда знайде текстові блоки у документі стилю [perlpod(1)](http://man.he.net/man1/perlpod), включеному до файлу модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Ви можете перекласти їх за допомогою сервісу DeepL, виконавши наведену вище команду, узгоджену з модулем **-Mtee**, який викликає команду **deepl** таким чином:

    greple -Mtee deepl text --to JA - -- --discrete ...

Оскільки **deepl** краще працює з однорядковим введенням, ви можете змінити частину команди таким чином:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Однак для цієї мети ефективніше використовувати спеціальний модуль [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl). Насправді, підказка щодо реалізації модуля **tee** прийшла з модуля **xlate**.

# EXAMPLE 2

Наступна команда знайде у документі LICENSE частину з відступами.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Ви можете переформатувати цю частину за допомогою модуля **tee** з командою **ansifold**:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate).

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
