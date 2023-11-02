# NAME

Aion::Format::Json - Perl extension for formatting JSON

# SYNOPSIS

```perl
use Aion::Format::Json;

to_json {a => 10}    # => {\n   "a": 10\n}\n
from_json '[1, "5"]' # --> [1, "5"]
```

# DESCRIPTION

`Aion::Format::Json` based on `JSON::XS`. And includethe following settings:

* allow_nonref - coding and decoding scalars.
* indent - enable multiline with indent on begin lines.
* space_after - `\n` after json.
* canonical - sorting keys in hashes.

# SUBROUTINES

## to_json (;$data)

Translate data to json format.

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

Parse string in json format to perl structure.

```perl
from_json '{"a": 10}' # --> {a => 10}

[map from_json, "{}", "2"]  # --> [{}, 2]
```

# AUTHOR

Yaroslav O. Kosmina [darviarush@mail.ru](darviarush@mail.ru)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Format::Json module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
