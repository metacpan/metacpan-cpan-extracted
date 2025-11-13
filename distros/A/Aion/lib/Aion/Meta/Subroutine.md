!ru:en
# NAME

Aion::Meta::Subroutine - описывает функцию с сигнатурой

# SYNOPSIS

```perl
use Aion::Types qw(Int);
use Aion::Meta::Subroutine;

my $subroutine = Aion::Meta::Subroutine->new(
	pkg => 'My::Package',
	subname => 'my_subroutine',
	signature => [Int, Int],
	referent => undef,
);

$subroutine->stringify  # => my_subroutine(Int => Int) of My::Package
```

# DESCRIPTION

Служит для объявления требуемой функции в интерфейсах и обстрактных классах.
При этом `referent ~~ Undef`.

А так же создаёт функцию-обёртку проверяющую сигнатуру.

# SUBROUTINES

## new (%args)

Конструктор.

## wrap_sub ()

Создаёт функцию-обёртку проверяющую сигнатуру.

## compare ($subroutine)

Сверяет свою (ожидаемую) сигнатуру с объявленной у функции в модуле и выбрасывает исключение, если сигнатуры не совпадают.

## stringify ()

Строковое описание функции.

## pkg ()

Возвращает имя пакета, в котором объявлена функция.

## subname ()

Возвращает имя функции.

## signature ()

Возвращает сигнатуру функции.

## referent ()

Возвращает ссылку на оригинальную функцию.

## wrapsub ()

Возвращает функцию-обёртку проверяющую сигнатуру.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Meta::Subroutine module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
