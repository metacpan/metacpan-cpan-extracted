[![Actions Status](https://github.com/darviarush/perl-aion-enum/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion-enum/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Aion-Enum.svg)](https://metacpan.org/release/Aion-Enum) [![Coverage](https://raw.githubusercontent.com/darviarush/perl-aion-enum/master/doc/badges/total.svg)](https://fast2-matrix.cpantesters.org/?dist=Aion-Enum+0.0.3)
# NAME

Aion::Enum - перечисления в стиле ООП, когда каждое перечсление является объектом

# VERSION

0.0.3

# SYNOPSIS

Файл lib/StatusEnum.pm:
```perl
package StatusEnum;

use Aion::Enum;

# Active status
case active => 1, 'Active';

# Passive status
case passive => 2, 'Passive';

1;
```

```perl
use StatusEnum;

&StatusEnum::active->does('Aion::Enum') # => 1

StatusEnum->active->name   # => active
StatusEnum->passive->value # => 2
StatusEnum->active->alias  # => Active status
StatusEnum->passive->stash # => Passive

[ StatusEnum->cases   ] # --> [StatusEnum->active, StatusEnum->passive]
[ StatusEnum->names   ] # --> [qw/active passive/]
[ StatusEnum->values  ] # --> [qw/1 2/]
[ StatusEnum->aliases ] # --> ['Active status', 'Passive status']
[ StatusEnum->stashes ] # --> [qw/Active Passive/]
```

# DESCRIPTION

`Aion::Enum` позволяет создавать перечисления-объекты. Данные перечисления могут содержать дополнительные методы и свойства. В них можно добавлять роли (с помощью `with`) или использовать их самих как роли.

Важной особенностью является сохранение порядка перечисления.

`Aion::Enum` подобен перечислениям из php8, но имеет дополнительные свойства `alias` и `stash`.

# SUBROUTINES

## case ($name, [$value, [$stash]])

Создаёт перечисление: его константу.

```perl
package OrderEnum {
    use Aion::Enum;

    case 'first';
    case second => 2;
    case other  => 3, {data => 123};
}

&OrderEnum::first->name  # => first
&OrderEnum::first->value # -> undef
&OrderEnum::first->stash # -> undef

&OrderEnum::second->name  # => second
&OrderEnum::second->value # -> 2
&OrderEnum::second->stash # -> undef

&OrderEnum::other->name  # => other
&OrderEnum::other->value # -> 3
&OrderEnum::other->stash # --> {data => 123}
```

## issa ($nameisa, [$valueisa], [$stashisa], [$aliasisa])

Указывает тип (isa) значений и дополнений.

Её название – отсылка к богине Иссе из повести «Под лунами Марса» Берроуза.

```perl
eval {
package StringEnum;
    use Aion::Enum;

    issa Str => Int => Undef => Undef;

    case active => "Active";
};
$@ # ~> active value must have the type Int. The it is 'Active'

eval {
package StringEnum;
    use Aion::Enum;

    issa Str => Str => Int;

    case active => "Active", "Passive";
};
$@ # ~> active stash must have the type Int. The it is 'Passive'
```

Файл lib/StringEnum.pm:
```perl
package StringEnum;
use Aion::Enum;

issa Str => Undef => Undef => StrMatch[qr/^[A-Z]/];

# pushkin
case active => ;

1;
```

```perl
require StringEnum # @-> active alias must have the type StrMatch[qr/^[A-Z]/]. The it is 'pushkin'!
```

# CLASS METHODS

## cases ($cls)

Список перечислений.

```perl
[ OrderEnum->cases ] # --> [OrderEnum->first, OrderEnum->second, OrderEnum->other]
```

## names ($cls)

Имена перечислений.

```perl
[ OrderEnum->names ] # --> [qw/first second other/]
```

## values ($cls)

Значения перечислений.

```perl
[ OrderEnum->values ] # --> [undef, 2, 3]
```

## stashes ($cls)

Дополнения перечислений.

```perl
[ OrderEnum->stashes ] # --> [undef, undef, {data => 123}]
```

## aliases ($cls)

Псевдонимы перечислений.

Файл lib/AuthorEnum.pm:
```perl
package AuthorEnum;

use Aion::Enum;

# Pushkin Aleksandr Sergeevich
case pushkin =>;

# Yacheykin Uriy
case yacheykin =>;

case nouname =>;

1;
```

```perl
require AuthorEnum;
[ AuthorEnum->aliases ] # --> ['Pushkin Aleksandr Sergeevich', 'Yacheykin Uriy', undef]
```

## fromName ($cls, $name)

Получить case по имени c исключением.

```perl
OrderEnum->fromName('first') # -> OrderEnum->first
eval { OrderEnum->fromName('not_exists') }; $@ # ~> Did not case with name `not_exists`!
```

## tryFromName ($cls, $name)

Получить case по имени.

```perl
OrderEnum->tryFromName('first')      # -> OrderEnum->first
OrderEnum->tryFromName('not_exists') # -> undef
```

## fromValue ($cls, $value)

Получить case по значению c исключением.

```perl
OrderEnum->fromValue(undef) # -> OrderEnum->first
eval { OrderEnum->fromValue('not-exists') }; $@ # ~> Did not case with value `not-exists`!
```

## tryFromValue ($cls, $value)

Получить case по значению.

```perl
OrderEnum->tryFromValue(undef)        # -> OrderEnum->first
OrderEnum->tryFromValue('not-exists') # -> undef
```

## fromStash ($cls, $stash)

Получить case по дополнению c исключением.

```perl
OrderEnum->fromStash(undef) # -> OrderEnum->first
eval { OrderEnum->fromStash('not-exists') }; $@ # ~> Did not case with stash `not-exists`!
```

## tryFromStash ($cls, $value)

Получить case по дополнению.

```perl
OrderEnum->tryFromStash({data => 123}) # -> OrderEnum->other
OrderEnum->tryFromStash('not-exists')  # -> undef
```

## fromAlias ($cls, $alias)

Получить case по псевдониму c исключением.

```perl
AuthorEnum->fromAlias('Yacheykin Uriy') # -> AuthorEnum->yacheykin
eval { AuthorEnum->fromAlias('not-exists') }; $@ # ~> Did not case with alias `not-exists`!
```

## tryFromAlias ($cls, $alias)

Получить case по псевдониму.

```perl
AuthorEnum->tryFromAlias('Yacheykin Uriy') # -> AuthorEnum->yacheykin
AuthorEnum->tryFromAlias('not-exists')     # -> undef
```

# FEATURES

## name

Свойство только для чтения.

```perl
package NameEnum {
    use Aion::Enum;

    case piter =>;
}

NameEnum->piter->name # => piter
```

## value

Свойство только для чтения.

```perl
package ValueEnum {
    use Aion::Enum;

    case piter => 'Pan';
}

ValueEnum->piter->value # => Pan
```

## stash

Свойство только для чтения.

```perl
package StashEnum {
    use Aion::Enum;

    case piter => 'Pan', 123;
}

StashEnum->piter->stash # => 123
```

## alias

Свойство только для чтения.

Алиасы работают только если пакет находится в модуле, так как считывают комментарий перед кейсом за счёт рефлексии.

Файл lib/AliasEnum.pm:
```perl
package AliasEnum;

use Aion::Enum;

# Piter Pan
case piter => ;

1;
```

```perl
require AliasEnum;
AliasEnum->piter->alias # => Piter Pan
```

# SEE ALSO

1. [enum](https://metacpan.org/pod/enum).
2. [Class::Enum](https://metacpan.org/pod/Class::Enum).

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Enum module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
