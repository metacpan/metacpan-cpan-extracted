[![Actions Status](https://github.com/darviarush/perl-aion/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Aion.svg)](https://metacpan.org/release/Aion) [![Coverage Status](https://img.shields.io/coveralls/darviarush/perl-aion/master.svg?style=flat)](https://coveralls.io/r/darviarush/perl-aion?branch=master)
# NAME

Aion - постмодернистская объектная система для Perl 5, такая как «Mouse», «Moose», «Moo», «Mo» и «M», но с улучшениями

# VERSION

0.4

# SYNOPSIS

```perl
package Calc {

    use Aion;

    has a => (is => 'ro+', isa => Num);
    has b => (is => 'ro+', isa => Num);
    has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

    sub result : Isa(Object => Num) {
        my ($self) = @_;
        eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
    }

}

Calc->new(a => 1.1, b => 2)->result   # => 3.1
```

# DESCRIPTION

Aion — ООП-фреймворк для создания классов с **фичами**, имеет **аспекты**, **роли** и так далее.

Свойства, объявленные через has, называются **фичами**.

А `is`, `isa`, `default` и так далее в `has` называются **аспектами**.

Помимо стандартных аспектов, роли могут добавлять свои собственные аспекты с помощью подпрограммы **aspect**.

Сигнатура методов может проверяться с помощью атрибута `:Isa(...)`.

# SUBROUTINES IN CLASSES AND ROLES

`use Aion` импортирует типы из модуля `Aion::Types` и следующие подпрограммы:

## has ($name, %aspects)

Создаёт метод для получения/установки функции (свойства) класса.

Файл lib/Animal.pm:
```perl
package Animal;
use Aion;

has type => (is => 'ro+', isa => Str);
has name => (is => 'rw-', isa => Str, default => 'murka');

1;
```

```perl
use lib "lib";
use Animal;

my $cat = Animal->new(type => 'cat');

$cat->type   # => cat
$cat->name   # => murka

$cat->name("murzik");
$cat->name   # => murzik
```

## with

Добавляет в модуль роли. Для каждой роли вызывается метод `import_with`.

Файл lib/Role/Keys/Stringify.pm:
```perl
package Role::Keys::Stringify;

use Aion -role;

sub keysify {
    my ($self) = @_;
    join ", ", sort keys %$self;
}

1;
```

Файл lib/Role/Values/Stringify.pm:
```perl
package Role::Values::Stringify;

use Aion -role;

sub valsify {
    my ($self) = @_;
    join ", ", map $self->{$_}, sort keys %$self;
}

1;
```

Файл lib/Class/All/Stringify.pm:
```perl
package Class::All::Stringify;

use Aion;

with q/Role::Keys::Stringify/;
with q/Role::Values::Stringify/;

has [qw/key1 key2/] => (is => 'rw', isa => Str);

1;
```

```perl
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

$s->keysify     # => key1, key2
$s->valsify     # => a, b
```

## isa ($package)

Проверяет, что `$package` — это суперкласс для данного или сам этот класс.

```perl
package Ex::X { use Aion; }
package Ex::A { use Aion; extends q/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

Ex::C->isa("Ex::A") # -> 1
Ex::C->isa("Ex::B") # -> 1
Ex::C->isa("Ex::X") # -> 1
Ex::C->isa("Ex::X1") # -> ""
Ex::A->isa("Ex::X") # -> 1
Ex::A->isa("Ex::A") # -> 1
Ex::X->isa("Ex::X") # -> 1
```

## does ($package)

Проверяет, что `$package` — это роль, которая используется в классе или другой роли.

```perl
package Role::X { use Aion -role; }
package Role::A { use Aion; with qw/Role::X/; }
package Role::B { use Aion; }
package Ex::Z { use Aion; with qw/Role::A Role::B/ }

Ex::Z->does("Role::A") # -> 1
Ex::Z->does("Role::B") # -> 1
Ex::Z->does("Role::X") # -> 1
Role::A->does("Role::X") # -> 1
Role::A->does("Role::X1") # -> ""
Ex::Z->does("Ex::Z") # -> ""
```

## aspect ($aspect => sub { ... })

Добавляет аспект к `has` в текущем классе и его классам-наследникам или текущей роли и применяющим её классам.

```perl
package Example::Earth {
    use Aion;

    aspect lvalue => sub {
        my ($cls, $name, $value, $construct, $feature) = @_;

        $construct->{attr} .= ":lvalue";
    };

    has moon => (is => "rw", lvalue => 1);
}

my $earth = Example::Earth->new;

$earth->moon = "Mars";

$earth->moon # => Mars
```

Аспект вызывается каждый раз, когда он указан в `has`.

Создатель аспекта имеет параметры:

* `$cls` — пакет с `has`.
* `$name` — имя фичи.
* `$value` — значение аспекта.
* `$construct` — хэш с фрагментами кода для присоединения к методу объекта.
* `$feature` — хеш описывающий фичу.

```perl
package Example::Mars {
    use Aion;

    aspect lvalue => sub {
        my ($cls, $name, $value, $construct, $feature) = @_;

        $construct->{attr} .= ":lvalue";

        $cls # => Example::Mars
        $name # => moon
        $value # -> 1
        [sort keys %$construct] # --> [qw/attr eval get name pkg ret set sub/]
        [sort keys %$feature] # --> [qw/construct has name opt order/]

        my $_construct = {
            pkg => $cls,
            name => $name,
			attr => ':lvalue',
			eval => 'package %(pkg)s {
	%(sub)s
}',
            sub => 'sub %(name)s%(attr)s {
		if(@_>1) {
			my ($self, $val) = @_;
			%(set)s%(ret)s
		} else {
			my ($self) = @_;
			%(get)s
		}
	}',
            get => '$self->{%(name)s}',
            set => '$self->{%(name)s} = $val',
            ret => '; $self',
        };

        $construct # --> $_construct

        my $_feature = {
            has => [is => "rw", lvalue => 1],
            opt => {
                is => "rw",
                lvalue => 1,
            },
            name => $name,
            construct => $_construct,
            order => 0,
        };

        $feature # --> $_feature
    };

    has moon => (is => "rw", lvalue => 1);
}
```

# SUBROUTINES IN CLASSES

## extends (@superclasses)

Расширяет класс другим классом/классами. Он вызывает из каждого наследуемого класса метод `import_extends`, если он в нём есть.

```perl
package World { use Aion;

    our $extended_by_this = 0;

    sub import_extends {
        my ($class, $extends) = @_;
        $extended_by_this ++;

        $class      # => World
        $extends    # => Hello
    }
}

package Hello { use Aion;
    extends q/World/;

    $World::extended_by_this # -> 1
}

Hello->isa("World")     # -> 1
```

## new (%param)

Конструктор.

* Устанавливает `%param` для фич.
* Проверяет, что параметры соответствуют фичам.
* Устанавливает значения по умолчанию.

```perl
package NewExample { use Aion;
    has x => (is => 'ro', isa => Num);
    has y => (is => 'ro+', isa => Num);
    has z => (is => 'ro-', isa => Num);
}

eval { NewExample->new(f => 5) }; $@            # ~> f is not feature!
eval { NewExample->new(n => 5, r => 6) }; $@    # ~> n, r is not features!
eval { NewExample->new }; $@                    # ~> Feature y is required!
eval { NewExample->new(z => 10) }; $@           # ~> Feature z cannot set in new!

my $ex = NewExample->new(y => 8);

eval { $ex->x }; $@  # ~> Get feature `x` must have the type Num. The it is undef

$ex = NewExample->new(x => 10.1, y => 8);

$ex->x # -> 10.1
```

# SUBROUTINES IN ROLES

## requires (@subroutine_names)

Проверяет, что в классах использующих эту роль есть указанные подпрограммы или фичи.

```perl
package Role::Alpha { use Aion -role;

    sub in {
        my ($self, $s) = @_;
        $s =~ /[${\ $self->abc }]/
    }

    requires qw/abc/;
}

eval { package Omega1 { use Aion; with Role::Alpha; } }; $@ # ~> abc requires!

package Omega { use Aion;
    with Role::Alpha;

    sub abc { "abc" }
}

Omega->new->in("a")  # -> 1
```

# METHODS

## has ($feature)

Проверяет, что свойство установлено.

Фичи имеющие `default => sub { ... }` выполняют `sub` при первом вызове геттера, то есть: являются отложенными.

`$object->has('фича')` позволяет проверить, что `default` ещё не вызывался.

```perl
package ExHas { use Aion;
    has x => (is => 'rw');
}

my $ex = ExHas->new;

$ex->has("x")   # -> ""

$ex->x(10);

$ex->has("x")   # -> 1
```

## clear (@features)

Удаляет ключи фич из объекта предварительно вызвав на них `clearer` (если есть).

```perl
package ExClearer { use Aion;
    has x => (is => 'rw');
    has y => (is => 'rw');
}

my $c = ExClearer->new(x => 10, y => 12);

$c->has("x")   # -> 1
$c->has("y")   # -> 1

$c->clear(qw/x y/);

$c->has("x")   # -> ""
$c->has("y")   # -> ""
```


# METHODS IN CLASSES

`use Aion` включает в модуль следующие методы:

## new (%parameters)

Конструктор.

# ASPECTS

`use Aion` включает в модуль следующие аспекты для использования в `has`:

## is => $permissions

* `ro` — создать только геттер.
* `wo` — создать только сеттер.
* `rw` — создать геттер и сеттер.

По умолчанию — `rw`.

Дополнительные разрешения:

* `+` — фича обязательна в параметрах конструктора. `+` не используется с `-`.
* `-` — фича не может быть установлена через конструктор. '-' не используется с `+`.
* `*` — не инкрементировать счётчик ссылок на значение (применить `weaken` к значению после установки его в фичу).

```perl
package ExIs { use Aion;
    has rw => (is => 'rw');
    has ro => (is => 'ro+');
    has wo => (is => 'wo-');
}

eval { ExIs->new }; $@ # ~> \* Feature ro is required!
eval { ExIs->new(ro => 10, wo => -10) }; $@ # ~> \* Feature wo cannot set in new!
ExIs->new(ro => 10);
ExIs->new(ro => 10, rw => 20);

ExIs->new(ro => 10)->ro  # -> 10

ExIs->new(ro => 10)->wo(30)->has("wo")  # -> 1
eval { ExIs->new(ro => 10)->wo }; $@ # ~> has: wo is wo- \(not get\)
ExIs->new(ro => 10)->rw(30)->rw  # -> 30
```

Функция с `*` не удерживает значение:

```perl
package Node { use Aion;
    has parent => (is => "rw*", isa => Maybe[Object["Node"]]);
}

my $root = Node->new;
my $node = Node->new(parent => $root);

$node->parent->parent   # -> undef
undef $root;
$node->parent   # -> undef

# And by setter:
$node->parent($root = Node->new);

$node->parent->parent   # -> undef
undef $root;
$node->parent   # -> undef
```

## isa => $type

Указывает тип, а точнее – валидатор, фичи.

```perl
package ExIsa { use Aion;
    has x => (is => 'ro', isa => Int);
}

eval { ExIsa->new(x => 'str') }; $@ # ~> \* Feature x must have the type Int. The it is 'str'
eval { ExIsa->new->x          }; $@ # ~> Get feature `x` must have the type Int. The it is undef
ExIsa->new(x => 10)->x              # -> 10
```

Список валидаторов см. в [Aion::Type](https://metacpan.org/pod/Aion::Type).

## default => $value

Значение по умолчанию устанавливается в конструкторе, если параметр с именем фичи отсутствует.

```perl
package ExDefault { use Aion;
    has x => (is => 'ro', default => 10);
}

ExDefault->new->x  # -> 10
ExDefault->new(x => 20)->x  # -> 20
```

Если `$value` является подпрограммой, то подпрограмма считается конструктором значения фичи. Используется ленивое вычисление.

```perl
my $count = 10;

package ExLazy { use Aion;
    has x => (default => sub {
        my ($self) = @_;
        ++$count
    });
}

my $ex = ExLazy->new;
$count   # -> 10
$ex->x   # -> 11
$count   # -> 11
$ex->x   # -> 11
$count   # -> 11
```

## trigger => $sub

`$sub` вызывается после установки свойства в конструкторе (`new`) или через сеттер.
Этимология – впустить.

```perl
package ExTrigger { use Aion;
    has x => (trigger => sub {
        my ($self, $old_value) = @_;
        $self->y($old_value + $self->x);
    });

    has y => ();
}

my $ex = ExTrigger->new(x => 10);
$ex->y      # -> 10
$ex->x(20);
$ex->y      # -> 30
```

## release => $sub

`$sub` вызывается перед возвратом свойства из объекта через геттер.
Этимология – выпустить.

```perl
package ExRelease { use Aion;
    has x => (release => sub {
        my ($self, $value) = @_;
        $_[1] = $value + 1;
    });
}

my $ex = ExRelease->new(x => 10);
$ex->x      # -> 11
```

## clearer => $sub

`$sub` вызывается при вызове декструктора или `$object->clear("feature")`, но только если свойство имеется (см. `$object->has("feature")`).

```perl
package ExClearer { use Aion;
	
	our $x;

    has x => (clearer => sub {
        my ($self) = @_;
        $x = $self->x
    });
}

$ExClearer::x      	# -> undef
ExClearer->new(x => 10);
$ExClearer::x      	# -> 10

my $ex = ExClearer->new(x => 12);

$ExClearer::x      # -> 10
$ex->clear('x');
$ExClearer::x      # -> 12

undef $ex;

$ExClearer::x      # -> 12
```

# ATTRIBUTES

`Aion` добавляет в пакет универсальные атрибуты.

## Isa (@signature)

Атрибут `Isa` проверяет сигнатуру функции.

**ВНИМАНИЕ**: использование атрибута «Isa» замедляет работу программы.

**СОВЕТ**: использования аспекта `isa` для объектов более чем достаточно, чтобы проверить правильность данных объекта.

```perl
package Anim { use Aion;

    sub is_cat : Isa(Object => Str => Bool) {
        my ($self, $anim) = @_;
        $anim =~ /(cat)/
    }
}

my $anim = Anim->new;

$anim->is_cat('cat')    # -> 1
$anim->is_cat('dog')    # -> ""


eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].
eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
