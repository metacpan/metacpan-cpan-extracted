# NAME

App::Greple::tee - модуль для замены совпадающего текста на результат внешней команды

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Модуль Greple's **-Mtee** посылает совпавшие части текста заданной команде фильтра и заменяет их результатом команды. Идея взята из команды **teip**. Это подобно обходу частичных данных внешней командой фильтрации.

Команда фильтрации следует за объявлением модуля (`-Mtee`) и заканчивается двумя тире (`--`). Например, следующая команда вызывает команду `tr` с аргументами `a-z A-Z` для найденного слова в данных.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Приведенная выше команда преобразует все совпадающие слова из нижнего регистра в верхний. На самом деле этот пример не так полезен, потому что **greple** может сделать то же самое более эффективно с помощью опции **--cm**.

По умолчанию команда выполняется как один процесс, и все совпавшие данные передаются ему вперемешку. Если совпадающий текст не заканчивается новой строкой, она добавляется до и удаляется после. Данные сопоставляются построчно, поэтому количество строк входных и выходных данных должно быть одинаковым.

При использовании опции **--discrete** для каждой сопоставленной детали вызывается отдельная команда. Разницу можно определить по следующим командам.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Строки входных и выходных данных не должны быть одинаковыми при использовании опции **--discrete**.

# VERSION

Version 0.9901

# OPTIONS

- **--discrete**

    Вызвать новую команду индивидуально для каждой сопоставленной детали.

- **--fillup**

    Объедините последовательность непустых строк в одну строку перед передачей их команде фильтра. Символы новой строки между широкими символами удаляются, а другие символы новой строки заменяются пробелами.

- **--blockmatch**

    Обычно внешней команде передается область, соответствующая заданному шаблону поиска. При указании этой опции будет обрабатываться не совпадающая область, а весь блок, содержащий ее.

    Например, чтобы отправить внешней команде строки, содержащие шаблон `foo`, необходимо указать шаблон, соответствующий всей строке:

        greple -Mtee cat -n -- '^.*foo.*\n'

    Но с помощью опции **--blockmatch** это можно сделать следующим образом:

        greple -Mtee cat -n -- foo

    С опцией **--blockmatch** этот модуль ведет себя подобно опции **-g** в [teip(1)](http://man.he.net/man1/teip).

# WHY DO NOT USE TEIP

Прежде всего, всегда, когда вы можете сделать это с помощью команды **teip**, используйте ее. Это отличный инструмент и намного быстрее, чем **greple**.

Поскольку **greple** предназначен для обработки файлов документов, он имеет много функций, которые подходят для этого, например, управление областью соответствия. Возможно, стоит использовать **greple**, чтобы воспользоваться этими возможностями.

Кроме того, **teip** не может обрабатывать несколько строк данных как единое целое, в то время как **greple** может выполнять отдельные команды на куске данных, состоящем из нескольких строк.

# EXAMPLE

Следующая команда найдет текстовые блоки внутри документа стиля [perlpod(1)](http://man.he.net/man1/perlpod), включенного в файл модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Вы можете перевести их с помощью сервиса DeepL, выполнив приведенную выше команду, соединенную с модулем **-Mtee**, который вызывает команду **deepl** следующим образом:

    greple -Mtee deepl text --to JA - -- --fillup ...

Однако для этой цели более эффективен специализированный модуль [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl). Фактически, подсказка для реализации модуля **tee** пришла из модуля **xlate**.

# EXAMPLE 2

Следующая команда обнаружит в документе LICENSE часть с отступами.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Вы можете переформатировать эту часть, используя модуль **tee** с командой **ansifold**:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Использование опции `--discrete` отнимает много времени. Поэтому вы можете использовать опцию `--separate '\r'` вместе с `ansifold`, которая создает одну строку, используя символ CR вместо NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Затем преобразуйте символ CR в NL с помощью команды [tr(1)](http://man.he.net/man1/tr) или другой.

    ... | tr '\r' '\n'

# EXAMPLE 3

Рассмотрим ситуацию, когда вы хотите искать строки в строках, не относящихся к заголовкам. Например, вы можете захотеть найти изображения из команды `docker image ls`, но оставить строку заголовка. Это можно сделать с помощью следующей команды.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Опция `-Mline -L 2:` извлекает предпоследние строки и отправляет их команде `grep perl`. Опция `--discrete` необходима, но она вызывается только один раз, поэтому недостатка в производительности нет.

В данном случае команда `teip -l 2- -- grep` выдает ошибку, так как количество строк на выходе меньше, чем на входе. Однако результат вполне удовлетворительный :)

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

Опция `--fillup` может работать некорректно для корейского текста.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
