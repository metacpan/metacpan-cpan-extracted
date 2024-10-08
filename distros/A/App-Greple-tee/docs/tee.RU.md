# NAME

App::Greple::tee - модуль для замены совпадающего текста на результат внешней команды

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.01

# DESCRIPTION

Модуль Greple's **-Mtee** посылает совпавшие части текста заданной команде фильтра и заменяет их результатом команды. Идея взята из команды **teip**. Это подобно обходу частичных данных внешней командой фильтрации.

Команда фильтрации следует за объявлением модуля (`-Mtee`) и заканчивается двумя тире (`--`). Например, следующая команда вызывает команду `tr` с аргументами `a-z A-Z` для найденного слова в данных.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Приведенная выше команда преобразует все совпадающие слова из нижнего регистра в верхний. На самом деле этот пример не так полезен, потому что **greple** может сделать то же самое более эффективно с помощью опции **--cm**.

По умолчанию команда выполняется как один процесс, и все совпадающие данные отправляются в него вперемешку. Если совпадающий текст не заканчивается новой строкой, то она добавляется перед отправкой и удаляется после получения. Входные и выходные данные сопоставляются построчно, поэтому количество строк ввода и вывода должно быть одинаковым.

При использовании опции **--discrete** для каждой совпадающей области текста вызывается отдельная команда. Разницу можно определить по следующим командам.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Строки входных и выходных данных не должны быть одинаковыми при использовании опции **--discrete**.

# OPTIONS

- **--discrete**

    Вызвать новую команду индивидуально для каждой сопоставленной детали.

- **--bulkmode**

    При использовании опции <--discrete> каждая команда выполняется по требованию. Опция
    <--bulkmode> option causes all conversions to be performed at once.

- **--crmode**

    Эта опция заменяет все символы новой строки в середине каждого блока на символы возврата каретки. Возврат каретки, содержащийся в результате выполнения команды, возвращается обратно к символу новой строки. Таким образом, блоки, состоящие из нескольких строк, можно обрабатывать партиями без использования опции **--discrete**.

- **--fillup**

    Объединить последовательность непустых строк в одну строку перед передачей ее команде фильтрации. Символы новой строки между символами большой ширины удаляются, а остальные символы новой строки заменяются пробелами.

- **--squeeze**

    Объединяет два или более последовательных символов новой строки в один.

- **-Mline** **--offload** _command_

    Опция **--offload** в [teip(1)](http://man.he.net/man1/teip) реализована в другом модуле **-Mline**.

        greple -Mtee cat -n -- -Mline --offload 'seq 10 20'

    Вы также можете использовать модуль **line** для обработки только четных строк следующим образом.

        greple -Mtee cat -n -- -Mline 2::2

# LEGACIES

Опция **--blocks** больше не нужна, поскольку в модуле **greple** реализована опция **--stretch** (**-S**). Вы можете просто выполнить следующее.

    greple -Mtee cat -n -- --all -SE foo

Не рекомендуется использовать опцию **--blocks**, поскольку в будущем она может быть устаревшей.

- **--blocks**

    Обычно внешней команде передается область, соответствующая заданному шаблону поиска. При указании этой опции будет обрабатываться не совпадающая область, а весь блок, содержащий ее.

    Например, чтобы отправить внешней команде строки, содержащие шаблон `foo`, необходимо указать шаблон, соответствующий всей строке:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Но с опцией **--blocks** это можно сделать следующим образом:

        greple -Mtee cat -n -- foo --blocks

    С опцией **--blocks** этот модуль ведет себя более похоже на модуль [teip(1)](http://man.he.net/man1/teip) с опцией **-g**. В остальном поведение аналогично [teip(1)](http://man.he.net/man1/teip) с опцией **-o**.

    Не используйте **--blocks** с опцией **--all**, так как блок будет представлять собой все данные.

# WHY DO NOT USE TEIP

Прежде всего, всегда, когда вы можете сделать это с помощью команды **teip**, используйте ее. Это отличный инструмент и намного быстрее, чем **greple**.

Поскольку **greple** предназначен для обработки файлов документов, он имеет много функций, которые подходят для этого, например, управление областью соответствия. Возможно, стоит использовать **greple**, чтобы воспользоваться этими возможностями.

Кроме того, **teip** не может обрабатывать несколько строк данных как единое целое, в то время как **greple** может выполнять отдельные команды на куске данных, состоящем из нескольких строк.

# EXAMPLE

Следующая команда найдет текстовые блоки внутри документа стиля [perlpod(1)](http://man.he.net/man1/perlpod), включенного в файл модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

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

Опция --discrete запускает несколько процессов, поэтому процесс будет выполняться дольше. Поэтому можно использовать опцию `--separate '\r'` с `ansifold`, которая выдает одну строку, используя символ CR вместо NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Затем преобразуйте символ CR в NL с помощью команды [tr(1)](http://man.he.net/man1/tr) или другой.

    ... | tr '\r' '\n'

# EXAMPLE 3

Рассмотрим ситуацию, когда требуется выполнить поиск строк в строках, не являющихся заголовками. Например, нужно найти имена образов Docker из команды `docker image ls`, но оставить строку заголовка. Это можно сделать с помощью следующей команды.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Опция `-Mline -L 2:` извлекает предпоследние строки и отправляет их в команду `grep perl`. Опция --discrete необходима, поскольку количество строк ввода и вывода меняется, но поскольку команда выполняется только один раз, то недостатка в производительности нет.

Если попытаться сделать то же самое с помощью команды **teip**, то `teip -l 2- -- grep` выдаст ошибку, поскольку количество выходных строк меньше количества входных. Однако с полученным результатом проблем нет.

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

Опция `--fillup` удаляет пробелы между символами хангыля при конкатенации корейского текста.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
