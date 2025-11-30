!ru:en
# NAME

Aion::Format::Url - утилиты для кодирования и декодирования URL-адресов

# SYNOPSIS

```perl
use Aion::Format::Url;

to_url_params {a => 1, b => [[1,2],3,{x=>10}]} # => a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10

normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x
```

# DESCRIPTION

Утилиты для кодирования и декодирования URL-адресов.

# SUBROUTINES

## to_url_param (;$scalar)

Экранирует `$scalar` для части поиска URL.

```perl
to_url_param "a b" # => a+b

[map to_url_param, "a b", "🦁"] # --> [qw/a+b %F0%9F%A6%81/]
```

## to_url_params (;$hash_ref)

Генерирует поисковую часть URL-адреса.

```perl
local $_ = {a => 1, b => [[1,2],3,{x=>10}]};
to_url_params  # => a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10
```

1. Ключи со значениями `undef` отбрасываются.
1. Значение `1` используется для ключа без значения.
1. Ключи преобразуются в алфавитном порядке.

```perl
to_url_params {k => "", n => undef, f => 1}  # => f&k=
```

## from_url_params (;$scalar)

Парсит поисковую часть URL-адреса.

```perl
local $_ = 'a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10';
from_url_params  # --> {a => 1, b => [[1,2],3,{x=>10}]}
```

## from_url_param (;$scalar)

Используется для парсинга ключей и значений в параметре URL.

Обратный к `to_url_param`.

```perl
local $_ = to_url_param '↬';
from_url_param  # => ↬
```

## parse_url ($url, $onpage, $dir)

Парсит и нормализует URL.

* `$url` — URL-адрес или его часть для парсинга.
* `$onpage` — URL-адрес страницы с `$url`. Если `$url` не завершен, то он дополняется отсюда. Необязательный. По умолчанию использует конфигурацию `$onpage = 'off://off'`.
* `$dir` (bool): 1 — нормализовать URL-путь с "/" на конце, если это каталог. 0 — без «/».

```perl
my $res = {
    proto  => "off",
    dom    => "off",
    domain => "off",
    link   => "off://off",
    orig   => "",
    onpage => "off://off",
};

parse_url "" # --> $res

$res = {
    proto  => "https",
    dom    => "main.com",
    domain => "www.main.com",
    path   => "/page",
    dir    => "/page/",
    link   => "https://main.com/page",
    orig   => "/page",
    onpage => "https://www.main.com/pager/mix",
};

parse_url "/page", "https://www.main.com/pager/mix"   # --> $res

$res = {
    proto  => "https",
    user   => "user",
    pass   => "pass",
    dom    => "x.test",
    domain => "www.x.test",
    path   => "/path",
    dir    => "/path/",
    query  => "x=10&y=20",
    hash   => "hash",
    link   => 'https://user:pass@x.test/path?x=10&y=20#hash',
    orig   => 'https://user:pass@www.x.test/path?x=10&y=20#hash',
    onpage => "off://off",
};
parse_url 'https://user:pass@www.x.test/path?x=10&y=20#hash'  # --> $res
```

## normalize_url ($url, $onpage, $dir)

Нормализует URL.

Использует `parse_url` и возвращает ссылку.

```perl
normalize_url ""   # => off://off
normalize_url "www.fix.com"  # => off://off/www.fix.com
normalize_url ":"  # => off://off/:
normalize_url '@'  # => off://off/@
normalize_url "/"  # => off://off
normalize_url "//" # => off://
normalize_url "?"  # => off://off
normalize_url "#"  # => off://off

normalize_url "/dir/file", "http://www.load.er/fix/mix"  # => http://load.er/dir/file
normalize_url "dir/file", "http://www.load.er/fix/mix"  # => http://load.er/fix/mix/dir/file
normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x
```

# SEE ALSO

* [Badger::URL](https://metacpan.org/pod/Badger::URL).
* [Mojo::URL](https://metacpan.org/pod/Mojo::URL).
* [Plack::Request](https://metacpan.org/pod/Plack::Request).
* [URI](https://metacpan.org/pod/URI).
* [URI::URL](https://metacpan.org/pod/URI::URL).
* [URL::Encode](https://metacpan.org/pod/URL::Encode).
* [URL::XS](https://metacpan.org/pod/URL::XS).

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Format::Url module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
