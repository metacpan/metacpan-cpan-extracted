[![Actions Status](https://github.com/darviarush/perl-aion/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Aion.svg)](https://metacpan.org/release/Aion) [![Coverage](https://raw.githubusercontent.com/darviarush/perl-aion/master/doc/badges/total.svg)](https://fast2-matrix.cpantesters.org/?dist=Aion+1.4)
# NAME

Aion - постмодернистская объектная система для Perl 5, такая как «Mouse», «Moose», «Moo», «Mo» и «M», но с улучшениями

# VERSION

1.4

# SYNOPSIS

```perl
package Calc {

	use Aion;

	has a => (is => 'ro+', isa => Num);
	has b => (is => 'ro+', isa => Num);
	has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

	sub result : Isa(Me => Num) {
		my ($self) = @_;
		eval "${\ $self->a} ${\ $self->op} ${\ $self->b}";
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

$s->keysify	 # => key1, key2
$s->valsify	 # => a, b
```

## exactly ($package)

Проверяет, что `$package` — это суперкласс для данного или сам этот класс.

Реализацию метода `isa` Aion не меняет и она находит как суперклассы, так и роли (так как и те и другие добавляются в `@ISA` пакета).

```perl
package Ex::X { use Aion; }
package Ex::A { use Aion; extends q/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

Ex::C->exactly("Ex::A") # -> 1
Ex::C->exactly("Ex::B") # -> 1
Ex::C->exactly("Ex::X") # -> 1
Ex::C->exactly("Ex::X1") # -> ""
Ex::A->exactly("Ex::X") # -> 1
Ex::A->exactly("Ex::A") # -> 1
Ex::X->exactly("Ex::X") # -> 1
```

## does ($package)

Проверяет, что `$package` — это роль, которая используется в классе или другой роли.

```perl
package Role::X { use Aion -role; }
package Role::A { use Aion -role; with qw/Role::X/; }
package Role::B { use Aion -role; }
package Ex::Z { use Aion; with qw/Role::A Role::B/; }

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
		my ($lvalue, $feature) = @_;

		return unless $lvalue;

		$feature->construct->add_attr(":lvalue");
	};

	has moon => (is => "rw", lvalue => 1);
}

my $earth = Example::Earth->new;

$earth->moon = "Mars";

$earth->moon # => Mars
```

Аспект вызывается каждый раз, когда он указан в `has`.

Создатель аспекта имеет параметры:

* `$value` — значение аспекта.
* `$feature` — метаобъект описывающий фичу (`Aion::Meta::Feature`).
* `$aspect_name` — наименование аспекта.

```perl
package Example::Mars {
	use Aion;

	aspect lvalue => sub {
		my ($value, $feature, $aspect_name) = @_;

		$value # -> 1
		$aspect_name # => lvalue

		$feature->construct->add_attr(":lvalue");
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

		$class   # => World
		$extends # => Hello
	}
}

package Hello { use Aion;
	extends q/World/;

	$World::extended_by_this # -> 1
}

Hello->isa("World")	 # -> 1
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

NewExample->new(f => 5) # @-> y required!
NewExample->new(f => 5, y => 10) # @-> f is'nt feature!
NewExample->new(f => 5, p => 6, y => 10) # @-> f, p is'nt features!
NewExample->new(z => 10, y => 10) # @-> z excessive!

my $ex = NewExample->new(y => 8);

$ex->x # @-> Get feature x must have the type Num. The it is undef!

$ex = NewExample->new(x => 10.1, y => 8);

$ex->x # -> 10.1
```

# SUBROUTINES IN ROLES

## requires (@subroutine_names)

Проверяет, что в классах, использующих эту роль, есть указанные подпрограммы или фичи.

```perl
package Role::Alpha { use Aion -role;

	requires qw/abc/;
}

package Omega1 { use Aion; with Role::Alpha; }

eval { Omega1->new }; $@ # ~> Requires abc of Role::Alpha

package Omega { use Aion;
	with Role::Alpha;

	sub abc { "abc" }
}

Omega->new->abc  # => abc
```

## req ($name => @aspects)

Проверяет, что в классах, использующих эту роль, есть указанные фичи с указанными аспектами.

```perl
package Role::Beta { use Aion -role;

	req x => (is => 'rw', isa => Num);
}

package Omega2 { use Aion; with Role::Beta; }

eval { Omega2->new }; $@ # ~> Requires req x => \(is => 'rw', isa => Num\) of Role::Beta

package Omega3 { use Aion;
	with Role::Beta;

	has x => (is => 'rw', isa => Num, default => 12);
}

Omega3->new->x  # -> 12
```

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
* `?` – создать предикат.
* `!` – создать clearer.

```perl
package ExIs { use Aion;
	has rw => (is => 'rw?!');
	has ro => (is => 'ro+');
	has wo => (is => 'wo-?');
}

ExIs->new # @-> ro required!
ExIs->new(ro => 10, wo => -10) # @-> wo excessive!

ExIs->new(ro => 10)->has_rw # -> ""
ExIs->new(ro => 10, rw => 20)->has_rw # -> 1
ExIs->new(ro => 10, rw => 20)->clear_rw->has_rw # -> ""

ExIs->new(ro => 10)->ro  # -> 10

ExIs->new(ro => 10)->wo(30)->has_wo # -> 1
ExIs->new(ro => 10)->wo # @-> Feature wo cannot be get!
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

ExIsa->new(x => 'str') # @-> Set feature x must have the type Int. The it is 'str'!
ExIsa->new->x # @-> Get feature x must have the type Int. The it is undef!
ExIsa->new(x => 10)->x			  # -> 10
```

Список валидаторов см. в [Aion::Types](https://metacpan.org/pod/Aion::Types).

## coerce => (1|0)

Включает преобразования типов.

```perl
package ExCoerce { use Aion;
	has x => (is => 'ro', isa => Int, coerce => 1);
}

ExCoerce->new(x => 10.4)->x  # -> 10
ExCoerce->new(x => 10.5)->x  # -> 11
```

## default => $value

Значение по умолчанию устанавливается в конструкторе, если параметр с именем фичи отсутствует.

```perl
package ExDefault { use Aion;
	has x => (is => 'ro', default => 10);
}

ExDefault->new->x  # -> 10
ExDefault->new(x => 20)->x  # -> 20
```

Если `$value` является подпрограммой, то подпрограмма считается конструктором значения фичи. Используется ленивое вычисление, если нет атрибута `lazy`.

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

## lazy => (1|0)

Аспект `lazy` включает или отключает ленивое вычисление значения по умолчанию (`default`).

По умолчанию он включен только если значение по умолчанию является подпрограммой.

```perl
package ExLazy0 { use Aion;
	has x => (is => 'ro?', lazy => 0, default => sub { 5 });
}

my $ex0 = ExLazy0->new;
$ex0->has_x # -> 1
$ex0->x     # -> 5

package ExLazy1 { use Aion;
	has x => (is => 'ro?', lazy => 1, default => 6);
}

my $ex1 = ExLazy1->new;
$ex1->has_x # -> ""
$ex1->x     # -> 6
```

## eon => (1|2|$key)

С помощью аспекта `eon` реализуется паттерн **Dependency Injection**.

Он связывает свойство с сервисом из контейнера `$Aion::pleroma`.

Значением аспекта может быть ключ сервиса, 1 или 2.

* Если 1 – тогда ключём будет пакет в `isa => Object['Packet']`.
* Если 2 – тогда ключём будет "пакет#свойство".

Файл lib/CounterEon.pm:
```perl
package CounterEon;
#@eon ex.counter
use Aion;

has accomulator => (isa => Object['AccomulatorEon'], eon => 1);

1;
```

Файл lib/AccomulatorEon.pm:
```perl
package AccomulatorEon;
#@eon
use Aion;

has power => (isa => Object['PowerEon'], eon => 2);

1;
```

Файл lib/PowerEon.pm:
```perl
package PowerEon;
use Aion;

has counter => (eon => 'ex.counter');
	
#@eon
sub power { shift->new }

1;
```

```perl
{
	use Aion::Pleroma;
	local $Aion::pleroma = Aion::Pleroma->new(ini => undef, pleroma => {
		'ex.counter' => 'CounterEon#new',
		AccomulatorEon => 'AccomulatorEon#new',
		'PowerEon#power' => 'PowerEon#power',
	});
	
	my $counter = $Aion::pleroma->get('ex.counter');

	$counter->accomulator->power->counter # -> $counter
}
```

См. [Aion::Pleroma](https://metacpan.org/pod/Aion::Pleroma).

## trigger => $sub

`$sub` вызывается после установки свойства в конструкторе (`new`) или через сеттер.

Этимология `trigger` – впустить.

```perl
package ExTrigger { use Aion;
	has x => (trigger => sub {
		my ($self, $old_value) = @_;
		$self->y($old_value + $self->x);
	});

	has y => ();
}

my $ex = ExTrigger->new(x => 10);
$ex->y	  # -> 10
$ex->x(20);
$ex->y	  # -> 30
```

## release => $sub

`$sub` вызывается перед возвратом свойства из объекта через геттер.

Этимология `release` – выпустить.

```perl
package ExRelease { use Aion;
	has x => (release => sub {
		my ($self, $value) = @_;
		$_[1] = $value + 1;
	});
}

my $ex = ExRelease->new(x => 10);
$ex->x	  # -> 11
```

## init_arg => $name

Меняет имя свойства в конструкторе.

```perl
package ExInitArg { use Aion;
	has x => (is => 'ro+', init_arg => 'init_x');

	ExInitArg->new(init_x => 10)->x # -> 10
}
```

## accessor => $name

Меняет имя акцессора.

```perl
package ExAccessor { use Aion;
	has x => (is => 'rw', accessor => '_x');

	ExAccessor->new->_x(10)->_x # -> 10
}
```

## writer => $name

Создаёт сеттер с именем `$name` для свойства.

```perl
package ExWriter { use Aion;
	has x => (is => 'ro', writer => '_set_x');

	ExWriter->new->_set_x(10)->x # -> 10
}
```

## reader => $name

Создаёт геттер с именем `$name` для свойства.

```perl
package ExReader { use Aion;
	has x => (is => 'wo', reader => '_get_x');

	ExReader->new(x => 10)->_get_x # -> 10
}
```

## predicate => $name

Создаёт предикат с именем `$name` для свойства. Создать предикат со стандартным именем можно так же через  `is => '?'`.

```perl
package ExPredicate { use Aion;
	has x => (predicate => '_has_x');
	
	my $ex = ExPredicate->new;
	$ex->_has_x        # -> ""
	$ex->x(10)->_has_x # -> 1
}
```

## clearer => $name

Создаёт очиститель с именем `$name` для свойства. Создать очиститель со стандартным именем можно так же через  `is => '!'`.

```perl
package ExClearer { use Aion;
	has x => (is => '?', clearer => 'clear_x_');
}

my $ex = ExClearer->new;
$ex->has_x	  # -> ""
$ex->clear_x_;
$ex->has_x	  # -> ""
$ex->x(10);
$ex->has_x	  # -> 1
$ex->clear_x_;
$ex->has_x	  # -> ""
```

## cleaner => $sub

`$sub` вызывается при вызове декструктора или `$object->clear_feature`, но только если свойство имеется (см. `$object->has_feature`).

Данный аспект принудительно создаёт предикат и clearer.

```perl
package ExCleaner { use Aion;

	our $x;

	has x => (is => '!', cleaner => sub {
		my ($self) = @_;
		$x = $self->x
	});
}

$ExCleaner::x		  # -> undef
ExCleaner->new(x => 10);
$ExCleaner::x		  # -> 10

my $ex = ExCleaner->new(x => 12);

$ExCleaner::x	  # -> 10
$ex->clear_x;
$ExCleaner::x	  # -> 12

undef $ex;

$ExCleaner::x	  # -> 12
```

# ATTRIBUTES

`Aion` добавляет в пакет универсальные атрибуты.

## :Isa (@signature)

Атрибут `Isa` проверяет сигнатуру функции.

```perl
package MaybeCat { use Aion;

	sub is_cat : Isa(Me => Str => Bool) {
		my ($self, $anim) = @_;
		$anim =~ /(cat)/
	}
}

my $anim = MaybeCat->new;
$anim->is_cat('cat')	# -> 1
$anim->is_cat('dog')	# -> ""

MaybeCat->is_cat("cat") # @-> Arguments of method `is_cat` must have the type Tuple[Me, Str].
my @items = $anim->is_cat("cat") # @-> Returns of method `is_cat` must have the type Tuple[Bool].
```

Атрибут Isa позволяет объявить требуемые функции:

```perl
package Anim { use Aion -role;

	sub is_cat : Isa(Me => Bool);
}

package Cat { use Aion; with qw/Anim/;

	sub is_cat : Isa(Me => Bool) { 1 }
}

package Dog { use Aion; with qw/Anim/;

	sub is_cat : Isa(Me => Bool) { 0 }
}

package Mouse { use Aion; with qw/Anim/;
	
	sub is_cat : Isa(Me => Int) { 0 }
}

Cat->new->is_cat # -> 1
Dog->new->is_cat # -> 0
Mouse->new # @-> Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
