!ru:en
# NAME

Aion::Type - класс валидаторов

# SYNOPSIS

```perl
use Aion::Type;
use Aion::Types qw//;

my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
12   ~~ $Int # => 1
12.1 ~~ $Int # -> ""

my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
$Char->include("a")	 # => 1
$Char->exclude("ab") # => 1

my $IntOrChar = $Int | $Char;
77   ~~ $IntOrChar # => 1
"a"  ~~ $IntOrChar # => 1
"ab" ~~ $IntOrChar # -> ""

my $Digit = $Int & $Char;
7  ~~ $Digit # => 1
77 ~~ $Digit # -> ""

"a" ~~ ~$Int; # => 1
5   ~~ ~$Int; # -> ""

eval { $Int->validate("a", "..Eval..") }; $@ # ~> ..Eval.. must have the type Int. The it is 'a'
```

# DESCRIPTION

Порождает валидаторы. Используется в `Aion::Types::subtype`.

# METHODS

## new (%ARGUMENTS)

Конструктор.

### ARGUMENTS

* name (Str) — Название типа.
* args (ArrayRef) — Список аргументов типа.
* init (CodeRef) — Инициализатор типа.
* test (CodeRef) — Чекер.
* a_test (CodeRef) — Чекер значений для типов с необязательными аргументами.
* coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) — Массив пар: тип и переход.

## stringify

Строковое преобразование объекта (имя с аргументами):

```perl
my $Char = Aion::Type->new(name => "Char");

$Char->stringify # => Char

my $Int = Aion::Type->new(
	name => "Int",
	args => [3, 5],
);

$Int->stringify  #=> Int[3, 5]
```

Операции так же преобразуются в строку:

```perl
($Int & $Char)->stringify   # => ( Int[3, 5] & Char )
($Int | $Char)->stringify   # => ( Int[3, 5] | Char )
(~$Int)->stringify		  # => ~Int[3, 5]
```

Операции — это объекты `Aion::Type` со специальными именами:

```perl
Aion::Type->new(name => "Exclude", args => [$Char])->stringify   # => ~Char
Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )
Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )
```

## test

Тестирует, что `$_` принадлежит классу.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local $_ = 5;
$PositiveInt->test  # -> 1
local $_ = -6;
$PositiveInt->test  # -> ""
```

## init

Инициализатор валидатора.

```perl
my $Range = Aion::Type->new(
	name => "Range",
	args => [3, 5],
	init => [sub {
		@{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
	}],
	test => sub { $Aion::Type::SELF->{min} <= $_ && $_ <= $Aion::Type::SELF->{max} },
);

$Range->init;

3 ~~ $Range  # -> 1
4 ~~ $Range  # -> 1
5 ~~ $Range  # -> 1

2 ~~ $Range  # -> ""
6 ~~ $Range  # -> ""
```


## include ($element)

Проверяет, принадлежит ли аргумент классу.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

$PositiveInt->include(5) # -> 1
$PositiveInt->include(-6) # -> ""
```

## exclude ($element)

Проверяет, что аргумент не принадлежит классу.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

$PositiveInt->exclude(5)  # -> ""
$PositiveInt->exclude(-6) # -> 1
```

## coerce ($value)

Привести `$value` к типу, если приведение из типа и функции находится в `$self->{coerce}`.

Соответствует оператору `>>`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });

push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];

$Int->coerce(5.5)	 # => 6
$Int->coerce(undef)  # => 0
$Int->coerce("abc")  # => abc
```

## detail ($element, $feature)

Формирует сообщение ошибки.

```perl
my $Int = Aion::Type->new(name => "Int");

$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!

my $Num = Aion::Type->new(name => "Num", message => sub {
	"Error: $_ is'nt $Aion::Type::SELF->{property}!"
});

$Num->detail("x", "car") # => Error: x is'nt car!
```

## validate ($element, $feature)

Проверяет `$element` и выбрасывает сообщение `detail`, если элемент не принадлежит классу.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

eval {
	$PositiveInt->validate(-1, "Neg")
};
$@ # ~> Neg must have the type PositiveInt. The it is -1
```

## val_to_str ($val)

Переводит `$val` в строку.

```perl
Aion::Type->new->val_to_str([1,2,{x=>6}]) # => [1, 2, {x => 6}]
```

## instanceof ($type)

Определяет, что тип является подтипом другого `$type` по имени типа.

В `|` и `~` не заходит. Аргументы не проверяет.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);

$PositiveInt->instanceof('Int');          # -> 1
$PositiveInt->instanceof('PositiveInt');  # -> 1
$Int->instanceof('PositiveInt');          # -> ""

my $MyEnum = Aion::Type->new(name => "MyEnum", args => [3, 5, 'car']);
($MyEnum & $PositiveInt)->instanceof('Int'); # -> 1
```

## is_set_theoretic

Проверяет, что тип является множественно-теоритическим (т.е. – оператором `|`, `&` или `~`).

## simplify

Если выражение не имеет значений – вернёт `~Any`, иначе – выражение.

Упрощение выражения в этой функции возможно появится в будущем.

```perl
package Aion::Types;

my $type = (Enum[1,2] | Enum[2,3]) & Enum[2,3,4];

$type->simplify->stringify # => ( ( Enum[1, 2] | Enum[2, 3] ) & Enum[2, 3, 4] )

my $range = Range[-10,0] & Range[4,8];
$range->simplify->stringify # => ~Any
```

## Any

Константа для типа включающего все значения.

```perl
package Aion::Type;

42 ~~ Any   # -> 1
42 ~~ None  # -> ""

Any <= Any   # -> 1
None <= Any  # -> 1
Any <= None  # -> ""
```

## None

Константа для пустого типа, не включающего ничего.

## identical ($type)

Типы равны, если они имеют одинаковый прототип (`coerce`), одинаковое количество аргументов, родительский элемент, их аргументы и M и N равны.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
my $AnotherInt = Aion::Type->new(name => "Int", coerce => $Int->{coerce});
my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2], coerce => $IntWithArgs->{coerce});
my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
my $Str = Aion::Type->new(name => "Str");

$Int->identical($Int)                        # -> 1
$Int->identical($AnotherInt)                 # -> 1
$IntWithArgs->identical($AnotherIntWithArgs) # -> 1
$PositiveInt->identical($PositiveInt)        # -> 1

$Int->{coerce} == $Str->{coerce}               # -> ""
$Int->identical($Str)                          # -> ""
$Int->identical($IntWithArgs)                  # -> ""
$IntWithArgs->identical($IntWithDifferentArgs) # -> ""
$PositiveInt->identical($Int)                  # -> ""

$Int->identical("not a type") # -> ""

my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
$PositiveInt->identical($PositiveInt2) # -> ""

$Int->identical($PositiveInt) # -> ""
$PositiveInt->identical($Int) # -> ""

my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
$PositiveIntWithArgs->identical($PositiveIntWithArgs2) # -> ""
```

## distinct ($type)

Обратная операция к `identical`.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);

$Int->distinct($PositiveInt) # -> 1
$Int ne $PositiveInt         # -> 1
```

## disjoint ($other)

Тип не пересекается с другим типом.

## subset ($type)

Определяет, что он является подмножеством указанного типа.

## superset ($type)

Определяет, что он является надмножеством указанного типа.

## subproper ($other)

Тип является строгим подмножеством другого.

## superproper ($other)

Тип является строгим надмножеством другого.

## equals ($other)

Тип эквивалентен другому типу.

## differs ($other)

Тип не эквивалентен другому типу.

## disjoint ($other)

Тип не имеет пересечений с другим типом.

## intersects ($other)

Тип имеет пересечение или пересечения с другим типом.

## make ($pkg)

Создаёт подпрограмму без аргументов, которая возвращает тип.

```perl
BEGIN {
	Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
}

"IX" ~~ Rim	 # => 1
```

Если указан `init` то при каждом использовании подпрограммы будет создаваться тип и инициализироваться.

```perl
eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won't work in Rim
```

Если подпрограмма не может быть создана, то выбрасывается исключение.

```perl
eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error
```

## make_arg ($pkg)

Создает подпрограмму с аргументами, которая возвращает тип.

```perl
BEGIN {
	Aion::Type->new(name=>"Len", test => sub {
		$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
	})->make_arg(__PACKAGE__, 1);
}

"IX" ~~ Len[2,2] # => 1
```

Если подпрограмма не может быть создана, то выбрасывается исключение.

```perl
eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error
```

## make_maybe_arg ($pkg)

Создает подпрограмму с аргументами или без.

```perl
BEGIN {
	Aion::Type->new(
		name => "Enum123",
		test => sub { $_ ~~ [1,2,3] },
		a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
	)->make_maybe_arg(__PACKAGE__);
}

3 ~~ Enum123        # -> 1
3 ~~ Enum123[4,5,6] # -> ""
5 ~~ Enum123[4,5,6] # -> 1
```

Если подпрограмма не может быть создана, то выбрасывается исключение.

```perl
eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error
```

## args ()

Список аргументов.

## name ()

Имя типа.

## as ()

Родительский тип.

## message (;&message)

Акцессор сообщения. Использует `&message` для генерации сообщения об ошибке.

## title (;$title)

Акцессор заголовка (используется для создания схемы **swagger**).

## description (;$description)

Акцессор описания (используется для создания схемы **swagger**).

## example (;$example)

Акцессор примера (используется для создания схемы **swagger**).

## true ()

Всегда возвращает `1`. Нужна для указания теста для типа без `where`.

## clone ()

Клонировать тип.

```perl
my $type = Aion::Type->new(name => 'New');
my $type10 = $type->clone(args => [10]);
$type->stringify # => New
$type10->stringify # => New[10]
```

## is_primitive ()

Это - примитивный тип, то есть тот, в иерархии которого нет множественно-теоритических операторов.

```perl
Aion::Types::Int->is_primitive  # -> 1
Aion::Types::Like->is_primitive # -> ""
```

## is_union ()

Это объединение типов.

```perl
Aion::Types::Int->is_union # -> ""
(Aion::Types::Int | Aion::Types::Int)->is_union  # -> 1
```

## is_intersection ()

Это пересечение типов.

```perl
Aion::Types::Int->is_intersection # -> ""
(Aion::Types::Int & Aion::Types::Int)->is_intersection  # -> 1
```

## is_exclude ()

Это исключение типа.

```perl
Aion::Types::Any->is_exclude # -> ""
(~Aion::Types::Any)->is_exclude # -> 1
Aion::Types::None->is_exclude # -> 1
~Aion::Types::Any eq Aion::Types::None # -> 1
```

## is_enum ()

Это перечисление.

```perl
Aion::Types::Int->is_enum  # -> ""
Aion::Types::Enum([1])->is_enum  # -> 1
```

## is_range_type ()

Это интервальный тип.

```perl
Aion::Types::Int->is_range_type  # -> ""
Aion::Types::Len([10])->is_range_type  # -> 1
```

## range_lbound ()

Нижняя граница интервала.

```perl
Aion::Types::Int->range_lbound  # -> undef
Aion::Types::Len([10])->range_lbound  # -> 0
Aion::Types::Range([0, 10])->range_lbound  # -> '-Inf'
```

## is_range ()

Это интервал.

```perl
Aion::Types::Int->is_range  # -> ""
Aion::Types::Len([10])->is_range  # -> ""
Aion::Types::Range([1, 10])->is_range  # -> 1
```

## typed_sorted_args_key ()

Формирует ключ с отсортированными типизированными параметрами.

```perl
(Aion::Types::Int & Aion::Types::Num)->typed_sorted_args_key  # -> (Aion::Types::Num & Aion::Types::Int)->typed_sorted_args_key
```

## sorted_args_key ()

Формирует ключ с отсортированными нетипизированными параметрами.

```perl
Aion::Types::Enum([10, 20])->sorted_args_key # -> Aion::Types::Enum([20, 10])->sorted_args_key
```

## key ()

Уникальный ключ из прототипа типа и его параметров.

## keyfn ($fn)

Устанавливает/возвращает функцию построения ключа для типа как класса.

```perl
my $type = Aion::Type->new(name => 'New', args => [10, 20]);
$type->keyfn($type->can('sorted_args_key'));

my $type2 = Aion::Type->new(name => 'New', args => [20, 10], coerce => $type->{coerce});
$type->key # -> $type2->key
```

## asen ()

Возвращает цепочку предков.

```perl
[Aion::Types::Num->asen]  # --> [Aion::Types::Any, Aion::Types::Item, Aion::Types::Defined, Aion::Types::Value, Aion::Types::Str]
```

## ckey ()

Ключ для сравнения типов в <=> и cmp.

## compare ($other)

Сравнение для сортировки. Используется в операторах `<=>` и `cmp`.

## is_descendant ($other, $is_strict)

A потомок B. Сравнивается прототип, но если указан `$is_strict`, то использется оператор `eq`.

```perl
Aion::Types::Range([1, 10])->is_descendant(Aion::Types::Defined)  # -> 1
Aion::Types::Range([1, 10])->is_descendant(Aion::Types::Value)    # -> ""
```

## like ($other)

Сравнивает по прототипам.

```perl
Aion::Types::Range([1, 10])->like(Aion::Types::Range([100, 200]))  # -> 1
```

## joint ($other)

Типы пересекаются.

```perl
Aion::Types::Range([1, 10])->joint(Aion::Types::Range([100, 200]))  # -> ""
Aion::Types::Range([1, 10])->joint(Aion::Types::Range([10, 200]))  # -> 1
```

# OPERATORS

## &{}

Тестирует `$_`.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local $_ = 10;
$PositiveInt->()	# -> 1

$_ = -1;
$PositiveInt->()	# -> ""
```

## ""

Стрингифицирует объект.

```perl
Aion::Type->new(name => "Int") . ""   # => Int

my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);

"$Enum" # => Enum['A', 'B', 'C']
```

## |

Или. Создает новый тип как объединение двух.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $IntOrChar = $Int | $Char;

77   ~~ $IntOrChar # -> 1
"a"  ~~ $IntOrChar # -> 1
"ab" ~~ $IntOrChar # -> ""
```

## &

И. Создает новый тип как пересечение двух.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $Digit = $Int & $Char;

7  ~~ $Digit # -> 1
77 ~~ $Digit # -> ""
"a" ~~ $Digit # -> ""
```

## ~

Не. Создает новый тип как исключение данного.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

"a" ~~ ~$Int; # -> 1
5   ~~ ~$Int; # -> ""
```

## ~~

Тестирует значение.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

$Int ~~ 3    # -> 1
-6   ~~ $Int # -> 1
```

## >>

Приведение к типу.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
$Int->{coerce} = [[$Int => sub { $_ + 5 }]];

5 >> $Int # -> 10

$Int >> -4 # -> 1
```

## eq

Типы тождественны.

```perl
my $Int1 = Aion::Type->new(name => "Int1");
my $Int2 = Aion::Type->new(name => "Int2", coerce => $Int1->{coerce});

$Int1 eq $Int2; # -> 1

delete $Int1->{key};
$Int1->{M} = 2;

$Int1 eq $Int2; # -> ""

my $Enum1 = Aion::Type->new(name => "Enum", args => ['red', 'green']);
my $Enum2 = Aion::Type->new(name => "Enum", args => ['green', 'red'], coerce => $Enum1->{coerce});

$Enum1->keyfn(\&Aion::Type::sorted_args_key);

$Enum1 eq $Enum2 # -> 1
$Enum1->key eq $Enum2->key # -> 1
```

## ne

Типы различны.

## ==

Эквивалентность двух типов.

```perl
my $Enum1 = Aion::Type->new(name => "Enum", args => ['red', 'green']);
my $Enum2 = Aion::Type->new(name => "Enum", args => ['green'], coerce => $Enum1->{coerce});
my $Enum3 = Aion::Type->new(name => "Enum", args => ['red'], coerce => $Enum1->{coerce});

$Enum1 == ($Enum2 | $Enum3) # -> 1
$Enum1 eq ($Enum2 | $Enum3) # -> ""
```

## !=

Неэквивалентность двух типов. Операция противоположная эквивалентности.

## <

A строгое подмножество B.

```perl
my $Num = Aion::Type->new(name => "Num");
my $Int = Aion::Type->new(name => "Int", as => $Num);
my $Str = Aion::Type->new(name => "Str");

$Int < $Num # -> 1
$Int < ($Int | $Str) # -> 1
$Int < ($Num | $Str) # -> 1

$Num < $Int # -> ""
$Int < $Int # -> ""
($Num | $Str) < $Int # -> ""
```

## >

A строгое надмножество B.

## <=

A подмножество B.

## >=

A надмножество B.

## <=>

Сравнение двух типов. Используется при сортировке.

```perl
package Aion::Types;

Enum[1,2] <=> Enum[1,2,3]   # -> 1
Enum[1,2,3] <=> Enum[1,2]   # -> -1
Enum[1,2] <=> Enum[1,2]     # -> 0

Range[1,5] <=> Range[1,10]  # -> 1
Range[1,10] <=> Range[1,5]  # -> -1
Range[1,5] <=> Range[1,5]   # -> 0

Int <=> Num                  # -> 1
Num <=> Int                  # -> -1

Str <=> Int                  # -> -1
```

## cmp

Аналогично `<=>`.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
