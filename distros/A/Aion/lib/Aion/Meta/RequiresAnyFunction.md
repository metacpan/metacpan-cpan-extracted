!ru:en
# NAME

Aion::Meta::RequiresAnyFunction - определяет любую функцию, которая должна быть в модуле

# SYNOPSIS

```perl
use Aion::Meta::RequiresAnyFunction;

my $any_function = Aion::Meta::RequiresAnyFunction->new(
	pkg => 'My::Package', name => 'my_function'
);

$any_function->stringify # => my_function of My::Package
```

# DESCRIPTION

Создаётся в `requires fn1, fn2...` и при инициализации класса проверяется, что такая функция в нём была объявлена через `sub` или `has`.

# SUBROUTINES

## new (%args)

Конструктор.

## compare ($other)

Проверяет, что `$other` является функцией.

```perl
my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package', name => 'my_function');
eval { $any_function->compare(undef) }; $@  # ~> Requires my_function of My::Package
```

## pkg ()

Возвращает имя пакета, в котором объявлена функция.

```perl
my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package');
$any_function->pkg  # => My::Package
```

## name ()

Возвращает имя функции.

```perl
my $any_function = Aion::Meta::RequiresAnyFunction->new(name => 'my_function');
$any_function->name  # => my_function
```
# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Meta::RequiresAnyFunction module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
