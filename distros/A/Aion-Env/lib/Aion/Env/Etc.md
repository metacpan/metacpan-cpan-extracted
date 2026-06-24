!ru:en
# NAME

Aion::Env::Etc - создаёт константу связанную с ключом из конфигурационных файлов

# SYNOPSIS

Файл etc/include.yml:
```text
includes:
  - etc/test.yml

test:
  abc: -12
```

Файл etc/test.yml:
```text
test:
  abc: 100

when@dev:
  test:
    val: 10
```

```perl
BEGIN { $ENV{APP_ENV} = 'dev' }

sub Int { sub { /^-?\d+$/ } }

use Aion::Env::Etc TEST_ABC => (isa => Int);
use Aion::Env::Etc VAL => (isa => Int, key => 'test.val');

TEST_ABC # -> -12
VAL # -> 10
```

# DESCRIPTION

Парсит конфигурационный файл. Путь к нему задан энвиронмент-переменной `AION_ENV_ETC_PATH`.

В нём может быть ключ `includes` c включением других конфигурационных файлов, а у тех – других.
Для простоты `includes` срабатывают от текущего каталога, который должен соответствовать корню проекта (таково соглашение).

Ключи вида `when@ID` будут перекрывать своими ключами ключи конфигурационного файла, если `ID` из них соответствует `APP_ENV`.

Хеши в ключах, при совпадении ключей в разных файлах, объединяются рекурсивно. Однако если в одном из ключей не хеш, то будет выброшено исключение.

# SUBROUTINES

## import ($name, %kw)

Создаёт константу в пакете из которого был вызван.

Допустимые опции:

* `isa` – подпрограмма-тестер или объект `Aion::Type` для проверки типа.
* `default` – значение по умолчанию.
* `key` – ключ из конфигурационных файлов. По умолчанию к нему преобразуется имя константы (переводится в нижний регистр и подчёрки заменяются на точки).

## parse ($path)

Считывает и парсит конфигурационный файл в формате `yaml`. `${ID}` заменяются на значения из `%ENV`, а если там нет, то из файла `.env`. Парсит файлы в `include` рекурсивно.

## merge_hashes ($file, $path, $x, $y)

Обединяет два хеша рекурсивно. Если в совпадающих ключах не хеши, то выбрасывает ошибку с `$file` и `$path`, где `$file` – подключающийся файл, а `$path` – путь из ключей через точку.

## val ($s)

Добавляет бэкслеши. Используется для эскейпинга энвиронментов.

```perl
my $escape_string = "\\\"\\'\\\\\\t\\r\\n";
Aion::Env::Etc::val("\"'\\\t\r\n") # -> $escape_string
```

## by_key ($hash, $path)

Получить значение по ключу из хеша.

```perl
my ($val, $key_exists) = Aion::Env::Etc::by_key({x => {y => {z => 3}}}, "x.y.z");

$val # -> 3
$key_exists # -> 1

($val, $key_exists) = Aion::Env::Etc::by_key({x => {y => {t => 10}}}, "x.y.z");

$val # -> undef
$key_exists # -> 0
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Env::Etc module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
