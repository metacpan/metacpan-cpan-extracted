!ru:en
# NAME

Aion::Meta::RequiresFeature - требование фичи для интерфейсов

# SYNOPSIS

```perl
use Aion::Types qw(Str);
use Aion::Meta::RequiresFeature;
use Aion::Meta::Feature;

my $req = Aion::Meta::RequiresFeature->new(
	'My::Package', 'name', is => 'rw', isa => Str);

my $feature = Aion::Meta::Feature->new(
	'Other::Package',
	'name', is => 'rw', isa => Str,
	default => 'default_value');

$req->compare($feature);

$req->stringify  # => req name => (is => 'rw', isa => Str) of My::Package
```

# DESCRIPTION

С помощью `req` создаёт требование к фиче которая будет описана в модуле к которому будет подключена роль или который унаследует абстрактный класс.

Проверяться будут только указанные аспекты в фиче.

# SUBROUTINES

## new ($cls, $pkg, $name, @has)

Конструктор.

## pkg ()

Возвращает имя пакета в котором описано требование к фиче.

## name ()

Возвращает имя фичи.

## has ()

Возвращает массив с аспектами фичи.

## opt ()

Возвращает хеш аспектов фичи.

## stringify ()

Строковое представление фичи.

## compare ($feature)

Сравнивает с фичей, но только указанные аспекты.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Meta::RequiresFeature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
