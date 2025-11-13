!ru:en
# NAME

Aion::Meta::Feature - метаописатель фичи

# SYNOPSIS

```perl
use Aion::Meta::Feature;

our $feature = Aion::Meta::Feature->new("My::Package", "my_feature" => (is => 'rw'));

$feature->stringify  # => has my_feature => (is => 'rw') of My::Package
```

# DESCRIPTION

Описывает фичу, которая добавляется в класс функцией `has`.

# METHODS

## pkg
Пакет, к которому относится фича.

```perl
$::feature->pkg # -> "My::Package"
```

## name
Имя фичи.

```perl
$::feature->name # -> "my_feature"
```

## opt
Хеш опций фичи.

```perl
$::feature->opt # --> {is => 'rw'}
```

## has
Массив опций фичи в виде пар ключ-значение.

```perl
$::feature->has # --> ['is', 'rw']
```

## construct
Объект конструктора фичи.

```perl
ref $::feature->construct # \> Aion::Meta::FeatureConstruct
```

## order ()
Порядковый номер фичи в классе.

```perl
$::feature->order # -> 0
```

## required (;$bool)
Флаг обязательности фичи в конструкторе (`new`).

```perl
$::feature->required(1);
$::feature->required # -> 1
```

## excessive (;$bool)
Флаг избыточности фичи в конструкторе (`new`). Если она там есть должно выбрасываться исключение.

```perl
$::feature->excessive(1);
$::feature->excessive # -> 1
```

## isa (;Object[Aion::Type])
Ограничение типа для значения фичи.

```perl
use Aion::Type;

my $Int = Aion::Type->new(name => 'Int');

$::feature->isa($Int);
$::feature->isa # -> $Int
```

## lazy (;$bool)
Флаг ленивой инициализации.

```perl
$::feature->lazy(1);
$::feature->lazy # -> 1
```

## builder (;$sub)
Билдер значения фичи или `undef`.

```perl
my $builder = sub {};
$::feature->builder($builder);
$::feature->builder # -> $builder
```

## default (;$value)
Значение по умолчанию для фичи.

```perl
$::feature->default(42);
$::feature->default # -> 42
```

## trigger (;$sub)
Обработчик события изменения значения фичи или `undef`.

```perl
my $trigger = sub {};
$::feature->trigger($trigger);
$::feature->trigger # -> $trigger
```

## release (;$sub)
Обработчик события чтения значения из фичи или `undef`.

```perl
my $release = sub {};
$::feature->release($release);
$::feature->release # -> $release
```

## cleaner (;$sub)
Обработчик события удаления фичи из объекта или `undef`.

```perl
my $cleaner = sub {};
$::feature->cleaner($cleaner);
$::feature->cleaner # -> $cleaner
```

## make_reader (;$bool)
Флаг создания метода-ридера.

```perl
$::feature->make_reader(1);
$::feature->make_reader # -> 1
```

## make_writer (;$bool)
Флаг создания метода-райтера.

```perl
$::feature->make_writer(1);
$::feature->make_writer # -> 1
```

## make_predicate (;$bool)
Флаг создания метода-предиката.

```perl
$::feature->make_predicate(1);
$::feature->make_predicate # -> 1
```

## make_clearer (;$bool)
Флаг создания метода-очистителя.

```perl
$::feature->make_clearer(1);
$::feature->make_clearer # -> 1
```

## new ($pkg, $name, @has)
Конструктор фичи.

```perl
my $feature = Aion::Meta::Feature->new('My::Class', 'attr', is => 'ro', default => 1);
$feature->pkg # -> "My::Class"
$feature->name # -> "attr"
$feature->opt # --> {is => 'ro', default => 1}
```

## stringify ()
Строковое представление фичи.

```perl
$::feature->stringify # -> "has my_feature => (is => 'rw') of My::Package"
```

## mk_property ()
Создаёт акцессор, геттер, сеттер, предикат и очиститель свойства.

```perl
package My::Package { use Aion }

$::feature->mk_property;

!!My::Package->can('my_feature') # -> 1
```

## meta ()
Возвращает код в виде текста для доступа к метаинформации фичи.

```perl
$::feature->meta # \> $Aion::META{'My::Package'}{feature}{my_feature}
```

## stash ($key; $val)
Доступ к хранилищу свойств для вызывающего пакета.

```perl
$::feature->stash('my_key', 'my_value');
$::feature->stash('my_key') # -> 'my_value'
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Meta::Feature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
