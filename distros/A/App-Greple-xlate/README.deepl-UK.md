# NAME

App::Greple::xlate - модуль підтримки перекладу для greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.30

# DESCRIPTION

Модулі **Greple** **xlate** знаходять потрібні текстові блоки і замінюють їх перекладеним текстом. Наразі реалізовано модулі DeepL (`deepl.pm`) та ChatGPT (`gpt3.pm`) як внутрішній рушій. Також включено експериментальну підтримку gpt-4.

Якщо ви хочете перекласти звичайні текстові блоки в документі, написаному в стилі Perl, використовуйте команду **greple** з модулем `xlate::deepl` і `perl` таким чином:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

У цій команді рядок-шаблон `^(\w.*\n)+` означає послідовні рядки, що починаються з буквено-цифрової літери. Ця команда показує область, що перекладається, виділеною. Опція **--all** використовується для перекладу всього тексту.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Потім додайте опцію `--xlate`, щоб перекласти виділену область. Після цього програма знайде потрібні фрагменти і замінить їх на виведені командою **deepl**.

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

    Замість того, щоб викликати рушій перекладу, ви повинні працювати для нього. Після підготовки текстів для перекладу вони копіюються в буфер обміну. Від вас вимагається вставити його у форму, скопіювати результат у буфер обміну і натиснути клавішу return.

- **--xlate-to** (Default: `EN-US`)

    Вкажіть цільову мову. Доступні мови можна отримати за допомогою команди `deepl languages` у разі використання рушія **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Вкажіть формат виведення оригінального та перекладеного тексту.

    - **conflict**, **cm**

        Вихідний і перетворений текст виводиться у форматі [git(1)](http://man.he.net/man1/git) з маркерами конфліктів.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Відновити вихідний файл можна наступною командою [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Вихідний та перетворений текст виводиться у форматі [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        За допомогою команди **unifdef** можна отримати лише японський текст:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Вихідний та перетворений текст виводиться через один порожній рядок.

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

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

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

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Модуль Greple для перекладу та заміни лише необхідних частин за допомогою API DeepL (японською мовою)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Генерація документів 15 мовами за допомогою модуля DeepL API (японською мовою)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Автоматичний переклад середовища Docker за допомогою API DeepL (японською мовою)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
