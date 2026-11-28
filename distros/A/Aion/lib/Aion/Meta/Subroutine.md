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

Но вторая сигнатура может иметь суженные типы.

```perl
use Aion::Types;
use Aion::Meta::Subroutine;

my $x1 = Aion::Meta::Subroutine->new(pkg => 'ExCompare', subname => 'x1', signature => [Num() => Any]);
my $x2 = Aion::Meta::Subroutine->new(pkg => 'ExCompare', subname => 'x2', signature => [Int() => Str]);

Int <= Num # -> 1
Str <= Any # -> 1

$x1->compare($x2);
$x2->compare($x1); # @-> Signature mismatch: x2(Int => Str) of ExCompare <=> x1(Num => Any) of ExCompare

my $x3 = Aion::Meta::Subroutine->new(pkg => 'ExCompare', subname => 'x3', signature => [Str() => Any]);

Str <= Num # -> ""

$x1->compare($x3); # @-> Signature mismatch: x1(Num => Any) of ExCompare <=> x3(Str => Any) of ExCompare
```

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
