# NAME

App::Greple::xlate - модуль підтримки перекладу для greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

Модулі **Greple** **xlate** знаходять текстові блоки і замінюють їх перекладеним текстом. Наразі в якості бекенд-рушія реалізовано модулі DeepL (`deepl.pm`) та ChatGPT (`gpt3.pm`).

Якщо ви хочете перекласти звичайні текстові блоки, написані у стилі [pod](https://metacpan.org/pod/pod), використовуйте команду **greple** з модулем `xlate::deepl` та `perl` таким чином:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Шаблон `^(\w.*\n)+` означає послідовні рядки, що починаються з буквено-цифрової літери. Ця команда показує область, яку потрібно перекласти. Параметр **--all** використовується для перекладу всього тексту.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Потім додайте опцію `--xlate` для перекладу виділеної області. Вона знайде і замінить їх на виведені командою **deepl**.

За замовчуванням оригінальний і перекладений текст виводиться у форматі "конфліктний маркер", сумісному з [git(1)](http://man.he.net/man1/git). Використовуючи формат `ifdef`, ви можете легко отримати потрібну частину за допомогою команди [unifdef(1)](http://man.he.net/man1/unifdef). Формат виводу можна вказати за допомогою опції **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Якщо ви хочете перекласти весь текст, використовуйте опцію **--match-all**. Це швидкий спосіб вказати шаблон `(?s).+`, який збігається з усім текстом.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Виклик процесу перекладу для кожної знайденої області.

    Без цього параметра **greple** поводиться як звичайна команда пошуку. Таким чином, ви можете перевірити, яку частину файлу буде перекладено, перш ніж викликати процес перекладу.

    Результат команди буде виведено у стандартний вивід, тому за потреби переспрямуйте його на файл або скористайтеся модулем [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Опція **--xlate** викликає опцію **--xlate-color** з опцією **--color=never**.

    За допомогою опції **--xlate-fold** перетворений текст буде згорнуто за вказаною шириною. За замовчуванням ширина складає 70 і може бути встановлена за допомогою параметра **--xlate-fold-width**. Чотири стовпчики зарезервовано для обкатки, тому кожен рядок може містити не більше 74 символів.

- **--xlate-engine**=_engine_

    Вказує рушій перекладу, який буде використано. Якщо ви вказуєте модуль рушія безпосередньо, наприклад, `-Mxlate::deepl`, вам не потрібно використовувати цей параметр.

- **--xlate-labor**
- **--xlabor**

    Замість того, щоб викликати рушій перекладу, ви маєте працювати з ним. Після підготовки тексту для перекладу він копіюється в буфер обміну. Ви маєте вставити його у форму, скопіювати результат у буфер обміну і натиснути клавішу return.

- **--xlate-to** (Default: `EN-US`)

    Вкажіть цільову мову. Доступні мови можна отримати за допомогою команди `deepl languages` у разі використання рушія **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Вкажіть формат виведення оригінального та перекладеного тексту.

    - **conflict**, **cm**

        Вивести оригінальний і перекладений текст у форматі конфліктних маркерів [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Відновити вихідний файл можна наступною командою [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Вивести оригінальний та перекладений текст у форматі [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        За допомогою команди **unifdef** можна отримати лише японський текст:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Вивести текст оригіналу та перекладу, розділені одним порожнім рядком.

    - **xtxt**

        Якщо формат `xtxt` (перекладений текст) або невідомий, друкується лише перекладений текст.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Вкажіть максимальну довжину тексту, що надсилається до API за один раз. За замовчуванням встановлено значення, як для безкоштовного сервісу DeepL: 128K для API (**--xlate**) і 5000 для інтерфейсу буфера обміну (**--xlate-labor**). Ви можете змінити ці значення, якщо ви використовуєте Pro сервіс.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Результат перекладу у реальному часі можна побачити у виводі STDERR.

- **--match-all**

    Встановити весь текст файлу як цільову область.

# CACHE OPTIONS

Модуль **xlate** може зберігати кешований текст перекладу для кожного файлу і зчитувати його перед виконанням, щоб усунути накладні витрати на запити до сервера. За замовчуванням стратегія кешування `auto` зберігає кешовані дані лише тоді, коли для цільового файлу існує файл кешу.

- --cache-clear

    Параметр **--cache-clear** може бути використано для ініціювання керування кешем або для оновлення усіх наявних даних кешу. Після виконання цього параметра буде створено новий файл кешу, якщо його не існує, а потім автоматично підтримуватиметься.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Обслуговувати файл кешу, якщо він існує.

    - `create`

        Створити порожній файл кешу і вийти.

    - `always`, `yes`, `1`

        Зберігати кеш у будь-якому випадку, якщо цільовий файл є нормальним.

    - `clear`

        Спочатку очистити дані кешу.

    - `never`, `no`, `0`

        Ніколи не використовувати файл кешу, навіть якщо він існує.

    - `accumulate`

        За замовчуванням, невикористані дані буде видалено з файлу кешу. Якщо ви не хочете видаляти їх і зберігати у файлі, скористайтеся командою `accumulate`.

# COMMAND LINE INTERFACE

Ви можете легко використовувати цей модуль з командного рядка за допомогою команди `xlate`, що входить до складу репозиторію. Див. довідкову інформацію щодо використання `xlate`.

# EMACS

Для використання команди `xlate` з редактора Emacs завантажте файл `xlate.el`, що входить до складу репозиторію. Функція `xlate-region` перекладає заданий регіон. За замовчуванням використовується мова `EN-US`, але ви можете вказати мову виклику за допомогою аргументу префікса.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Встановіть свій ключ автентифікації для сервісу DeepL.

- OPENAI\_API\_KEY

    Ключ автентифікації OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Вам потрібно встановити інструменти командного рядка для DeepL і ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Бібліотека Python і команда CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Бібліотека OpenAI на мові Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Інтерфейс командного рядка OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Детальніше про шаблон цільового тексту див. у посібнику **greple**. Використовуйте опції **--inside**, **--outside**, **--include**, **--exclude** для обмеження області пошуку.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Ви можете скористатися модулем `-Mupdate` для модифікації файлів за результатами виконання команди **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Використовуйте **sdif** для відображення формату конфліктних маркерів поряд з опцією **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
