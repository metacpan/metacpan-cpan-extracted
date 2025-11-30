!ru:en
# NAME

Aion::Format::Json - расширение Perl для форматирования JSON

# SYNOPSIS

```perl
use Aion::Format::Json;

to_json {a => 10}    # => {\n   "a": 10\n}\n
from_json '[1, "5"]' # --> [1, "5"]
```

# DESCRIPTION

`Aion::Format::Json` использует в качестве основы `JSON::XS`. И включает следующие настройки:

* allow_nonref — скаляры кодирования и декодирования.
* indent – включить многострочный текст с отступом в начале строки.
* space_after — `\n` после json.
* canonical — сортировка ключей в хешах.

# SUBROUTINES

## to_json (;$data)

Переводит данные в формат json.

```perl
my $data = {
    a => 10,
};

my $result = '{
   "a": 10
}
';

to_json $data # -> $result

local $_ = $data;
to_json # -> $result
```

## from_json (;$string)

Разбирает строку в формате JSON в структуру Perl.

```perl
from_json '{"a": 10}' # --> {a => 10}

[map from_json, "{}", "2"]  # --> [{}, 2]
```

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Format::Json module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
