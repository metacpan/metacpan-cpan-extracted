!ru:en
# NAME

Aion::Type - класс валидаторов

# SYNOPSIS

```perl
use Aion::Type;

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

eval { $Int->validate("a", "..Eval..") }; $@	# ~> ..Eval.. must have the type Int. The it is 'a'
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
Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )
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
	init => sub {
		@{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
	},
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

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });

push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];

$Int->coerce(5.5)	# => 6
$Int->coerce(undef)  # => 0
$Int->coerce("abc")  # => abc
```

## detail ($element, $feature)

Формирует сообщение ошибки.

```perl
my $Int = Aion::Type->new(name => "Int");

$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!

my $Num = Aion::Type->new(name => "Num", message => sub {
	"Error: $_ is'nt $Aion::Type::SELF->{N}!"
});

$Num->detail("x", "car") # => Error: x is'nt car!
```

`$Aion::Type::SELF->{N}` equivalent to `N` in context of `Aion::Types`.

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

Определяет, что тип является подтипом другого `$type`.

```perl
my $int = Aion::Type->new(name => "Int");
my $positiveInt = Aion::Type->new(name => "PositiveInt", as => $int);

$positiveInt->instanceof($int)          # -> 1
$positiveInt->instanceof($positiveInt)  # -> 1
$positiveInt->instanceof('Int')         # -> 1
$positiveInt->instanceof('PositiveInt') # -> 1
$int->instanceof('PositiveInt')         # -> ""
$int->instanceof('Int')                 # -> 1
```

## make ($pkg)

Создаёт подпрограмму без аргументов, которая возвращает тип.

```perl
BEGIN {
	Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
}

"IX" ~~ Rim	 # => 1
```

Свойство `init` не может использоваться с `make`.

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
	})->make_arg(__PACKAGE__);
}

"IX" ~~ Len[2,2]	# => 1
```

Если подпрограмма не может быть создана, то выбрасывается исключение.

```perl
eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error
```

## make_maybe_arg ($pkg)

Создает подпрограмму с аргументами, которая возвращает тип.

```perl
BEGIN {
	Aion::Type->new(
		name => "Enum123",
		test => sub { $_ ~~ [1,2,3] },
		a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
	)->make_maybe_arg(__PACKAGE__);
}

3 ~~ Enum123			# -> 1
3 ~~ Enum123[4,5,6]	 # -> ""
5 ~~ Enum123[4,5,6]	 # -> 1
```

Если подпрограмма не может быть создана, то выбрасывается исключение.

```perl
eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error
```

## equal ($type)

Типы равны, если они имеют одинаковое имя, одинаковое количество аргументов, родительский элемент и аргументы равны.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
my $AnotherInt = Aion::Type->new(name => "Int");
my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
my $Str = Aion::Type->new(name => "Str");

$Int->equal($Int)                        # -> 1
$Int->equal($AnotherInt)                 # -> 1
$IntWithArgs->equal($AnotherIntWithArgs) # -> 1
$PositiveInt->equal($PositiveInt)        # -> 1

$Int->equal($Str)                          # -> ""
$Int->equal($IntWithArgs)                  # -> ""
$IntWithArgs->equal($IntWithDifferentArgs) # -> ""
$PositiveInt->equal($Int)                  # -> ""

$Int->equal("not a type") # -> ""

my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
$PositiveInt->equal($PositiveInt2) # -> ""

$Int->equal($PositiveInt) # -> ""
$PositiveInt->equal($Int) # -> ""

my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
$PositiveIntWithArgs->equal($PositiveIntWithArgs2) # -> ""
```

## nonequal ($type)

Обратная операция к `equal`.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);

$Int->nonequal($PositiveInt) # -> 1
$Int ne $PositiveInt         # -> 1
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

# OPERATORS

## &{}

Делает объект вызываемым.

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

## $a | $b

Создает новый тип как объединение `$a` и `$b`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $IntOrChar = $Int | $Char;

77   ~~ $IntOrChar # -> 1
"a"  ~~ $IntOrChar # -> 1
"ab" ~~ $IntOrChar # -> ""
```

## $a & $b

Создает новый тип как пересечение `$a` и `$b`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $Digit = $Int & $Char;

7  ~~ $Digit # -> 1
77 ~~ $Digit # -> ""
"a" ~~ $Digit # -> ""
```

## ~ $a

Создает новый тип как исключение из `$a`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

"a" ~~ ~$Int; # -> 1
5   ~~ ~$Int; # -> ""
```

## $a eq $b, $a == $b

`$a` равно `$b`.

```perl
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

$Int1 eq $Int2 # -> 1
$Int1 == $Int2 # -> 1
```

## $a ne $b, $a != $b

`$a` не равно `$b`.

```perl
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

$Int1 ne $Int2 # -> ""
$Int1 != $Int2 # -> ""
123 ne $Int2 # -> 1
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
