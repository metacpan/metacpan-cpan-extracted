!ru:en
# NAME

Aion::Format::Yaml - конвертер из/в yaml

# SYNOPSIS

```perl
use Aion::Format::Yaml qw/from_yaml to_yaml/;

to_yaml {foo => 'bar'} # -> "foo: bar\n"
from_yaml "a: b" # --> {a => "b"}
```

# DESCRIPTION

Конвертирует из/в yaml. Под капотом использует `YAML::Syck`, настроенную в соответствии с требованиями Aion.

# SUBROUTINES

## to_yaml ($struct)

В yaml.

```perl
to_yaml {foo => undef} # => foo: ~\n
to_yaml {foo => 'true'} # => foo: 'true'\n
```

## from_yaml ($string)

Из yaml.

Булевы значения:

```note
y|Y|yes|Yes|YES|n|N|no|No|NO|
true|True|TRUE|false|False|FALSE|
on|On|ON|off|Off|OFF
```

```perl
from_yaml "a: true" # --> {a => 1}
from_yaml "a: yes" # --> {a => 1}
from_yaml "a: y" # --> {a => 1}
from_yaml "a: ON" # --> {a => 1}
from_yaml "a: FALSE" # --> {a => ""}
from_yaml "a: No" # --> {a => ""}
from_yaml "a: N" # --> {a => ""}
from_yaml "a: off" # --> {a => ""}
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Format::Yaml module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
