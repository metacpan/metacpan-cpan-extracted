# NAME

Aion::Type::Lim - граница со смещением для интервалов

# SYNOPSIS

```perl
use Aion::Type::Lim;

Aion::Type::Lim->from(5) # => Closed[5]
Aion::Type::Lim->from(5)->inc # => Opened[5]
Aion::Type::Lim->from(5)->dec # => Opened[5]

my $five_min = Aion::Type::Lim->from(5)->dec;
my $five_max = Aion::Type::Lim->from(5)->inc;

$five_min == 5 # -> ""
$five_min < 5 # -> 1
$five_max > 5 # -> 1
```

# DESCRIPTION

Предназначен для создания открытых границ в `Range[from, to]`.

Переопределяет оператор сравнения `<=>` из которого выводятся остальные операторы сравнения: `<`, `>`, `<=`, `>=`, `==`, `!=`.

# SUBROUTINES

## from ($cls, $lim)

Конструктор.

## dec ()

Уменьшает сдвиг.

## inc ()

Увеличивает сдвиг.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Type::Lim module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
