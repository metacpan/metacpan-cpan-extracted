# NAME

App::Greple::xlate - модуль підтримки перекладу для greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

**Greple** Модуль **xlate** знаходить текстові блоки і замінює їх перекладеним текстом. В даний час в якості двигуна використовуються модулі DeepL (`deepl.pm`) та ChatGPT (`gpt3.pm`).

Якщо ви хочете перекласти звичайні текстові блоки, написані у стилі [pod](https://metacpan.org/pod/pod), використовуйте команду **greple** з модулем `xlate::deepl` та `perl` таким чином:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Шаблон `^(\w.*\n)+` означає послідовні рядки, що починаються з букви або цифри. Ця команда показує область, яку потрібно перекласти. Опція **--all** використовується для виведення всього тексту.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Потім додайте опцію `--xlate`, щоб перекласти вибрану область. Вона знайде та замінить їх виводом команди **deepl**.

За замовчуванням оригінальний та перекладений текст виводяться у форматі "конфліктного маркера", сумісного з [git(1)](http://man.he.net/man1/git). Використовуючи формат `ifdef`, ви можете легко отримати бажану частину за допомогою команди [unifdef(1)](http://man.he.net/man1/unifdef). Формат виводу можна вказати за допомогою опції **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Якщо ви хочете перекласти весь текст, використовуйте опцію **--match-all**. Це скорочення для вказання шаблону `(?s).+`, який відповідає всьому тексту.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Викликайте процес перекладу для кожної знайденої області.

    Без цієї опції **greple** працює як звичайна команда пошуку. Тому ви можете перевірити, яка частина файлу буде підлягати перекладу, перед викликом фактичної роботи.

    Результат команди виводиться на стандартний вивід, тому перенаправте його до файлу, якщо потрібно, або розгляньте використання модуля [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Опція **--xlate** викликає опцію **--xlate-color** з опцією **--color=never**.

    З опцією **--xlate-fold** перетворений текст складається за вказаною шириною. За замовчуванням ширина становить 70 і може бути встановлена за допомогою опції **--xlate-fold-width**. Чотири стовпці зарезервовані для роботи з рядками, тому кожен рядок може містити максимум 74 символи.

- **--xlate-engine**=_engine_

    Вказує двигун перекладу, який буде використовуватися. Якщо ви вказуєте модуль двигуна безпосередньо, наприклад `-Mxlate::deepl`, вам не потрібно використовувати цю опцію.

- **--xlate-labor**
- **--xlabor**

    Замість виклику двигуна перекладу, очікується, що ви будете працювати з текстом, який потрібно перекласти. Після підготовки тексту для перекладу, вони копіюються в буфер обміну. Очікується, що ви вставите їх у форму, скопіюєте результат в буфер обміну та натиснете Enter.

- **--xlate-to** (Default: `EN-US`)

    Вкажіть цільову мову. Ви можете отримати доступні мови за допомогою команди `deepl languages`, коли використовуєте двигун **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Вкажіть формат виведення для оригінального та перекладеного тексту.

    - **conflict**, **cm**

        Вивести оригінальний та перекладений текст у форматі конфліктних маркерів [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Ви можете відновити оригінальний файл за допомогою наступної команди [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Вивести оригінальний та перекладений текст у форматі [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Ви можете отримати лише японський текст за допомогою команди **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Вивести оригінальний та перекладений текст, розділені одним порожнім рядком.

    - **xtxt**

        Якщо формат - це `xtxt` (перекладений текст) або невідомий, виводиться лише перекладений текст.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Перекладіть наступний текст українською мовою, рядок за рядком.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Перекладіть наступний текст на українську мову.

- **--match-all**

    Переглядайте результат перекладу в режимі реального часу у виводі STDERR.

# CACHE OPTIONS

Встановіть весь текст файлу як цільову область.

- --cache-clear

    Модуль **xlate** може зберігати кешований текст перекладу для кожного файлу та читати його перед виконанням, щоб уникнути надмірного запиту до сервера. За замовчуванням стратегія кешу `auto` підтримує кешові дані тільки тоді, коли файл кешу існує для цільового файлу.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Опція **--cache-clear** може бути використана для ініціювання керування кешем або оновлення всіх існуючих даних кешу. Після виконання з цією опцією буде створено новий файл кешу, якщо він не існує, і потім автоматично підтримуватиметься.

    - `create`

        Підтримуйте файл кешу, якщо він існує.

    - `always`, `yes`, `1`

        Створіть порожній файл кешу та вийдіть.

    - `clear`

        Підтримуйте кеш незалежно від того, чи є цільовий файл звичайним файлом.

    - `never`, `no`, `0`

        Спочатку очистіть дані кешу.

    - `accumulate`

        Ніколи не використовуйте файл кешу, навіть якщо він існує.

# COMMAND LINE INTERFACE

За замовчуванням невикористані дані видаляються з файлу кешу. Якщо ви не хочете їх видаляти і зберігати в файлі, використовуйте `accumulate`.

# EMACS

Ви можете легко використовувати цей модуль з командного рядка, використовуючи команду `xlate`, яка входить до репозиторію. Для використання команди `xlate` з редактора Emacs завантажте файл `xlate.el`, який входить до репозиторію. Функція `xlate-region` перекладає задану область. Мова за замовчуванням - `EN-US`, і ви можете вказати мову, викликаючи її з аргументом префіксу.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Встановіть свій ключ аутентифікації для сервісу DeepL.

- OPENAI\_API\_KEY

    Ключ аутентифікації OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Вам потрібно встановити інструменти командного рядка для DeepL та ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Бібліотека DeepL для Python та командний рядок.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Бібліотека OpenAI для Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Інтерфейс командного рядка OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Докладніше про шаблон тексту цільового тексту див. у посібнику **greple**. Використовуйте опції **--inside**, **--outside**, **--include**, **--exclude**, щоб обмежити область відповідності.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Ви можете використовувати модуль `-Mupdate`, щоб змінювати файли за результатами команди **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Використовуйте **sdif**, щоб показати формат маркера конфлікту поруч з опцією **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
