!ru:en
# NAME

Aion::Meta::Util - вспомогательные функции для создания мета-данных

# SYNOPSIS

```perl
package My::Meta::Class {
	use Aion::Meta::Util;
	
	create_accessors qw/age/;
	create_getters qw/name/;
}

my $class = bless {name => 'car'}, 'My::Meta::Class';

$class->age(20);
$class->age  # => 20

$class->name  # => car
eval { $class->name('auto') }; $@ # ~> name is ro
```

# DESCRIPTION

В мета-классах поддерживающих создание фич и сигнатур функций (т.е. внутреннюю кухню Aion) требуется своя небольшая реализация, которую и предоставляет данный модуль.

# SUBROUTINES

## create_getters (@getter_names)

Создаёт геттеры.

## create_accessors (@accessor_names)

Создаёт геттер-сеттеры.

## subref_is_reachable ($subref)

Проверяет, имеет ли подпрограмма тело.

```perl
use Aion::Meta::Util;

subref_is_reachable(\&nouname)             # -> ""
subref_is_reachable(UNIVERSAL->can('isa')) # -> ""
subref_is_reachable(sub {})                # -> 1
subref_is_reachable(\&CORE::exit)          # -> 1
```

## val_to_str ($val)

Переводит `$val` в строку.

```perl
Aion::Meta::Util::val_to_str([1,2,{x=>6}])   # => [1, 2, {x => 6}]

Aion::Meta::Util::val_to_str(qr/^[A-Z]/)   # => qr/^[A-Z]/u
Aion::Meta::Util::val_to_str(qr/^[A-Z]/i)   # => qr/^[A-Z]/ui
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Meta::Util module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
