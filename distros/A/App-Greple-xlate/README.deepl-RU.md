# NAME

App::Greple::xlate - модуль поддержки перевода для greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.30

# DESCRIPTION

Модуль **Greple** **xlate** находит нужные текстовые блоки и заменяет их переведенным текстом. В настоящее время в качестве внутреннего движка реализованы модули DeepL (`deepl.pm`) и ChatGPT (`gpt3.pm`). Также включена экспериментальная поддержка gpt-4.

Если вы хотите перевести обычные текстовые блоки в документе, написанном в стиле Perl's pod, используйте команду **greple** с модулем `xlate::deepl` и `perl` следующим образом:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

В этой команде шаблонная строка `^(\w.*\n)+` означает последовательные строки, начинающиеся с буквенно-цифрового символа. В этой команде выделяется область, подлежащая переводу. Опция **--all** используется для создания всего текста.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Затем добавьте опцию `--xlate` для перевода выделенной области. После этого программа найдет нужные участки и заменит их выводом команды **--deepl**.

По умолчанию оригинальный и транслированный текст печатается в формате "маркер конфликта", совместимом с [git(1)](http://man.he.net/man1/git). Используя формат `ifdef`, можно легко получить нужную часть командой [unifdef(1)](http://man.he.net/man1/unifdef). Выходной формат может быть задан опцией **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Если требуется перевести весь текст, используйте опцию **--match-all**. Это сокращение для указания шаблона `(?s).+`, который соответствует всему тексту.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Запустите процесс перевода для каждой совпавшей области.

    Без этой опции **greple** ведет себя как обычная команда поиска. Таким образом, вы можете проверить, какая часть файла будет подвергнута переводу, прежде чем вызывать фактическую работу.

    Результат команды выводится в стандартный аут, поэтому при необходимости перенаправьте его в файл или воспользуйтесь модулем [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Опция **--xlate** вызывает опцию **--xlate-color** с опцией **--color=never**.

    С опцией **--xlate-fold** преобразованный текст сворачивается на указанную ширину. Ширина по умолчанию равна 70 и может быть задана опцией **--xlate-fold-width**. Для обкатки зарезервировано четыре колонки, поэтому в каждой строке может содержаться не более 74 символов.

- **--xlate-engine**=_engine_

    Определяет используемый движок перевода. Если вы указываете модуль движка напрямую, например `-Mxlate::deepl`, то этот параметр использовать не нужно.

- **--xlate-labor**
- **--xlabor**

    Вместо того чтобы вызывать механизм перевода, вы должны работать на него. После подготовки текста для перевода он копируется в буфер обмена. Вы должны вставить их в форму, скопировать результат в буфер обмена и нажать кнопку return.

- **--xlate-to** (Default: `EN-US`)

    Укажите целевой язык. Вы можете получить доступные языки с помощью команды `deepl languages` при использовании движка **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Укажите формат вывода оригинального и переведенного текста.

    - **conflict**, **cm**

        Оригинальный и преобразованный текст печатаются в формате [git(1)](http://man.he.net/man1/git) маркеров конфликтов.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Вы можете восстановить исходный файл следующей командой [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Оригинальный и преобразованный текст печатаются в формате [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Вы можете восстановить только японский текст командой **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Оригинальный и преобразованный текст печатаются разделенными одной пустой строкой.

    - **xtxt**

        Если формат `xtxt` (переведенный текст) или неизвестен, печатается только переведенный текст.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Укажите максимальную длину текста, передаваемого в API за один раз. По умолчанию установлено значение, как для бесплатного сервиса DeepL: 128К для API (**--xlate**) и 5000 для интерфейса буфера обмена (**--xlate-labor**). Вы можете изменить эти значения, если используете услугу Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Результат перевода можно увидеть в реальном времени в выводе STDERR.

- **--match-all**

    Установите весь текст файла в качестве целевой области.

# CACHE OPTIONS

Модуль **xlate** может хранить кэшированный текст перевода для каждого файла и считывать его перед выполнением, чтобы исключить накладные расходы на запрос к серверу. При стратегии кэширования по умолчанию `auto`, он сохраняет данные кэша только тогда, когда файл кэша существует для целевого файла.

- --cache-clear

    Опция **--cache-clear** может быть использована для инициирования управления кэшем или для обновления всех существующих данных кэша. После выполнения этой опции будет создан новый файл кэша, если он не существует, а затем автоматически сохранен.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Сохранять файл кэша, если он существует.

    - `create`

        Создать пустой файл кэша и выйти.

    - `always`, `yes`, `1`

        Сохранять кэш в любом случае, пока целевой файл является обычным файлом.

    - `clear`

        Сначала очистите данные кэша.

    - `never`, `no`, `0`

        Никогда не использовать файл кэша, даже если он существует.

    - `accumulate`

        По умолчанию неиспользуемые данные удаляются из файла кэша. Если вы не хотите удалять их и сохранять в файле, используйте `accumulate`.

# COMMAND LINE INTERFACE

Вы можете легко использовать этот модуль из командной строки с помощью команды `xlate`, включенной в репозиторий. Информацию об использовании смотрите в справке `xlate`.

# EMACS

Загрузите файл `xlate.el`, включенный в репозиторий, чтобы использовать команду `xlate` из редактора Emacs. Функция `xlate-region` переводит заданный регион. Язык по умолчанию - `EN-US`, и вы можете указать язык, вызывая ее с помощью аргумента prefix.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Задайте ключ аутентификации для сервиса DeepL.

- OPENAI\_API\_KEY

    Ключ аутентификации OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Необходимо установить инструменты командной строки для DeepL и ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Библиотека Python и команда CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Библиотека OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Интерфейс командной строки OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Подробную информацию о шаблоне целевого текста см. в руководстве **greple**. Используйте опции **--inside**, **--outside**, **--include**, **--exclude** для ограничения области совпадения.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Вы можете использовать модуль `-Mupdate` для модификации файлов по результатам команды **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Используйте **sdif**, чтобы показать формат маркера конфликта бок о бок с опцией **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Модуль Greple для перевода и замены только необходимых частей с помощью DeepL API (на японском языке)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Генерация документов на 15 языках с помощью модуля DeepL API (на японском языке)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Автоматический перевод Docker-окружения с помощью DeepL API (на японском языке)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
