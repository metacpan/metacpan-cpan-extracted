!ru:en
# NAME

Aion::Types - библиотека стандартных валидаторов и служит для создания новых валидаторов

# SYNOPSIS

```perl
use Aion::Types;

BEGIN {
	subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
		message { "Speak is'nt included kitty!" };
}

"Kitty!" ~~ SpeakOfKitty # -> 1
"abc"    ~~ SpeakOfKitty # -> ""

SpeakOfKitty->validate("abc", "This") # @-> Speak is'nt included kitty!


BEGIN {
	subtype IntOrArrayRef => as (Int | ArrayRef);
}

[] ~~ IntOrArrayRef  # -> 1
35 ~~ IntOrArrayRef  # -> 1
"" ~~ IntOrArrayRef  # -> ""


coerce IntOrArrayRef, from Num, via { int($_ + .5) };

IntOrArrayRef->coerce(5.5) # => 6
```

# DESCRIPTION

Этот модуль экспортирует подпрограммы:

* `subtype`, `as`, `init_where`, `where`, `awhere`, `message` — для создания валидаторов.
* `SELF`, `ARGS`, `A`, `B`, `C`, `D`, `M`, `N` — для использования в валидаторах типа и его аргументов.
* `coerce`, `from`, `via` — для создания конвертора значений из одного класса в другой.

Иерархия валидаторов:

```text
Any
	Control
		Union[A, B...]
		Intersection[A, B...]
		Exclude[A, B...]
		Option[A]
		Wantarray[A, S]
	Item
		Bool
		BoolLike
		Enum[A...]
		Maybe[A]
		Undef
		Defined
			Value
				Version
				Str
					Uni
					Bin
					NonEmptyStr
					StartsWith
					EndsWith
					Email
					Tel
					Url
					Path
					Html
					StrDate
					StrDateTime
					StrMatch[qr/.../]
					ClassName[A]
					RoleName[A]
					Rat
					Num
						PositiveNum
						Int
							PositiveInt
							Nat
			Ref
				Tied`[A]
				LValueRef
				FormatRef
				CodeRef`[name, proto]
					ReachableCodeRef`[name, proto]
					UnreachableCodeRef`[name, proto]
				RegexpRef
				ScalarRefRef`[A]
					RefRef`[A]
					ScalarRef`[A]
				GlobRef
					FileHandle
				ArrayRef`[A]
				HashRef`[H]
				Object`[O]
					Me
				Map[K, V]
				Tuple[A...]
				CycleTuple[A...]
				Dict[k => A, ...]
				RegexpLike
				CodeLike
				ArrayLike`[A]
					Lim[A, B?]
				HashLike`[A]
					HasProp[p...]
					LimKeys[A, B?]
			Like
				HasMethods[m...]
				Overload`[m...]
				InstanceOf[A...]
				ConsumerOf[A...]
				StrLike
					Len[A, B?]
				NumLike
					Float
					Double
					Range[from, to]
					Bytes[A, B?]
					PositiveBytes[A, B?]
```

# SUBROUTINES

## subtype ($name, @paraphernalia)

Создаёт новый тип.

```perl
BEGIN {
	subtype One => where { $_ == 1 } message { "Actual 1 only!" };
}

1 ~~ One	 # -> 1
0 ~~ One	 # -> ""
eval { One->validate(0) }; $@ # ~> Actual 1 only!
```

`where` и `message` — это синтаксический сахар, а `subtype` можно использовать без них.

```perl
BEGIN {
	subtype Many => (where => sub { $_ > 1 });
}

2 ~~ Many  # -> 1

eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@ # ~> subtype Many unused keys left: where1

eval { subtype 'Many' }; $@ # ~> subtype Many: main::Many exists!
```

## as ($super_type)

Используется с `subtype` для расширения создаваемого типа `$super_type`.

## init_where ($code)

Инициализирует тип с новыми аргументами. Используется с `subtype`.

```perl
BEGIN {
	subtype 'LessThen[A]',
		init_where { Num->validate(A, "Argument LessThen[A]") }
		where { $_ < A };
}

eval { LessThen["string"] }; $@  # ~> Argument LessThen\[A\]

5 ~~ LessThen[5]  # -> ""
```

## where ($code)

Использует `$code` как тест. Значение для теста передаётся в `$_`.

```perl
BEGIN {
	subtype 'Two',
		where { $_ == 2 };
}

2 ~~ Two # -> 1
3 ~~ Two # -> ""
```

Используется с `subtype`. Необходимо, если у типа есть аргументы.

```perl
subtype 'Ex[A]' # @-> subtype Ex[A]: needs a where
```

## awhere ($code)

Используется с `subtype`.

Если тип может быть с аргументами и без, то используется для проверки набора с аргументами, а `where` — без.

```perl
BEGIN {
	subtype 'GreatThen`[A]',
		where { $_ > 0 }
		awhere { $_ > A }
	;
}

0 ~~ GreatThen # -> ""
1 ~~ GreatThen # -> 1

3 ~~ GreatThen[3] # -> ""
4 ~~ GreatThen[3] # -> 1
```

Необходимо, если аргументы необязательны.

```perl
subtype 'Ex`[A]', where {} # @-> subtype Ex`[A]: needs a awhere
subtype 'Ex', awhere {} # @-> subtype Ex: awhere is excess

BEGIN {
	subtype 'MyEnum`[A...]',
		as Str,
		awhere { $_ ~~ scalar ARGS }
	;
}

"ab" ~~ MyEnum[qw/ab cd/] # -> 1
```

## SELF

Текущий тип. `SELF` используется в `init_where`, `where` и `awhere`.

## ARGS

Аргументы текущего типа. В скалярном контексте возвращает ссылку на массив, а в контексте массива возвращает список. Используется в `init_where`, `where` и `awhere`.

## A, B, C, D

Первый, второй, третий и пятый аргумент типа.

```perl
BEGIN {
	subtype "Seria[A,B,C,D]", where { A < B && B < $_ && $_ < C && C < D };
}

2.5 ~~ Seria[1,2,3,4] # -> 1
```

Используется в `init_where`, `where` и `awhere`.

## M, N

`M` и `N` сокращение для `SELF->{M}` и `SELF->{N}`.

```perl
BEGIN {
	subtype "BeginAndEnd[A, B]",
		init_where {
			N = qr/^${\ quotemeta A}/;
			M = qr/${\ quotemeta B}$/;
		}
		where { $_ =~ N && $_ =~ M };
}

"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"]; # -> 1
"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];  # -> ""

"" . BeginAndEnd["Hi,", "!"] # => BeginAndEnd['Hi,', '!']
```

## message ($code)

Используется с `subtype` для вывода сообщения об ошибке, если значение исключает тип. В `$code` используется: `SELF` - текущий тип, `ARGS`, `A`, `B`, `C`, `D` - аргументы типа (если есть) и проверочное значение в `$_`. Его можно преобразовать в строку с помощью `SELF->val_to_str($_)`.

## coerce ($type, from => $from, via => $via)

Добавляет новое приведение (`$via`) к `$type` из `$from` типа.

```perl
BEGIN {subtype Four => where {4 eq $_}}

"4a" ~~ Four # -> ""

Four->coerce("4a") # -> "4a"

coerce Four, from Str, via { 0+$_ };

Four->coerce("4a")	# -> 4

coerce Four, from ArrayRef, via { scalar @$_ };

Four->coerce([1,2,3])           # -> 3
Four->coerce([1,2,3]) ~~ Four   # -> ""
Four->coerce([1,2,3,4]) ~~ Four # -> 1
```

`coerce` выбрасывает исключения:

```perl
eval {coerce Int, via1 => 1}; $@  # ~> coerce Int unused keys left: via1
eval {coerce "x"}; $@  # ~> coerce x not Aion::Type!
eval {coerce Int}; $@  # ~> coerce Int: from is'nt Aion::Type!
eval {coerce Int, from "x"}; $@  # ~> coerce Int: from is'nt Aion::Type!
eval {coerce Int, from Num}; $@  # ~> coerce Int: via is not subroutine!
eval {coerce Int, (from=>Num, via=>"x")}; $@  # ~> coerce Int: via is not subroutine!
```

Стандартные приведения:

```perl
# Str from Undef — empty string
Str->coerce(undef) # -> ""

# Int from Num — rounded integer
Int->coerce(2.5)  # -> 3
Int->coerce(-2.5) # -> -3

# Bool from Any — 1 or ""
Bool->coerce([]) # -> 1
Bool->coerce(0)  # -> ""
```

## from ($type)

Синтаксический сахар для `coerce`.

## via ($code)

Синтаксический сахар для `coerce`.

# ATTRIBUTES

## :Isa (@signature)

Проверяет сигнатуру подпрограммы: аргументы и результаты.

```perl
sub minint($$) : Isa(Int => Int => Int) {
	my ($x, $y) = @_;
	$x < $y? $x : $y
}

minint 6, 5; # -> 5
eval {minint 5.5, 2}; $@ # ~> Arguments of method `minint` must have the type Tuple\[Int, Int\]\.

sub half($) : Isa(Int => Int) {
	my ($x) = @_;
	$x / 2
}

half 4; # -> 2
eval {half 5}; $@ # ~> Return of method `half` must have the type Int. The it is 2.5
```

# TYPES

## Any

Тип верхнего уровня в иерархии. Сопоставляет всё.

## Control

Тип верхнего уровня в конструкторах иерархии создает новые типы из любых типов.

## Union[A, B...]

Союз нескольких типов. Аналогичен оператору `$type1 | $type2`.

```perl
33  ~~ Union[Int, Ref] # -> 1
[]  ~~ Union[Int, Ref]	# -> 1
"a" ~~ Union[Int, Ref]	# -> ""
```

## Intersection[A, B...]

Пересечение нескольких типов. Аналогичен оператору `$type1 & $type2`.

```perl
15 ~~ Intersection[Int, StrMatch[/5/]] # -> 1
```

## Exclude[A, B...]

Исключение нескольких типов. Аналогичен оператору `~ $type`.

```perl
-5  ~~ Exclude[PositiveInt] # -> 1
"a" ~~ Exclude[PositiveInt] # -> 1
5   ~~ Exclude[PositiveInt] # -> ""
5.5 ~~ Exclude[PositiveInt] # -> 1
```

Если `Exclude` имеет много аргументов, то это аналог `~ ($type1 | $type2 ...)`.

```perl
-5  ~~ Exclude[PositiveInt, Enum[-2]] # -> 1
-2  ~~ Exclude[PositiveInt, Enum[-2]] # -> ""
0   ~~ Exclude[PositiveInt, Enum[-2]] # -> ""
```

## Option[A]

Дополнительные ключи в `Dict`.

```perl
{a=>55} ~~ Dict[a=>Int, b => Option[Int]]          # -> 1
{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]   # -> 1
{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]] # -> ""
```

## Wantarray[A, S]

Если подпрограмма возвращает разные значения в контексте массива и скаляра, то используется тип `Wantarray` с типом `A` для контекста массива и типом `S` для скалярного контекста.

```perl
sub arr : Isa(PositiveInt => Wantarray[ArrayRef[PositiveInt], PositiveInt]) {
	my ($n) = @_;
	wantarray? 1 .. $n: $n
}

my @a = arr(3);
my $s = arr(3);

\@a # --> [1,2,3]
$s  # -> 3
```

## Item

Тип верхнего уровня в иерархии скалярных типов.

## Bool

`1` is true. `0`, `""` or `undef` is false.

```perl
1 ~~ Bool  # -> 1
0 ~~ Bool  # -> 1
undef ~~ Bool # -> 1
"" ~~ Bool # -> 1

2 ~~ Bool  # -> ""
[] ~~ Bool # -> ""
```

## Enum[A...]

Перечисление.

```perl
3 ~~ Enum[1,2,3]   # -> 1
"cat" ~~ Enum["cat", "dog"] # -> 1
4 ~~ Enum[1,2,3]   # -> ""
```

## Maybe[A]

`undef` или тип в `[]`.

```perl
undef ~~ Maybe[Int] # -> 1
4 ~~ Maybe[Int]     # -> 1
"" ~~ Maybe[Int]    # -> ""
```

## Undef

Только `undef`.

```perl
undef ~~ Undef # -> 1
0 ~~ Undef     # -> ""
```

## Defined

Всё за исключением `undef`.

```perl
\0 ~~ Defined    # -> 1
undef ~~ Defined # -> ""
```

## Value

Определённые значения без ссылок.

```perl
3 ~~ Value  # -> 1
\3 ~~ Value    # -> ""
undef ~~ Value # -> ""
```

## Len[A, B?]

Определяет значение длины от `A` до `B` или от 0 до `A`, если `B` отсутствует.

```perl
"1234" ~~ Len[3]   # -> ""
"123" ~~ Len[3]    # -> 1
"12" ~~ Len[3]     # -> 1
"" ~~ Len[1, 2]    # -> ""
"1" ~~ Len[1, 2]   # -> 1
"12" ~~ Len[1, 2]  # -> 1
"123" ~~ Len[1, 2] # -> ""
```

## Version

Perl версии.

```perl
1.1.0 ~~ Version   # -> 1
v1.1.0 ~~ Version  # -> 1
v1.1 ~~ Version    # -> 1
v1 ~~ Version      # -> 1
1.1 ~~ Version     # -> ""
"1.1.0" ~~ Version # -> ""
```

## Str

Строки, включая числа.

```perl
1.1 ~~ Str   # -> 1
"" ~~ Str    # -> 1
1.1.0 ~~ Str # -> ""
```

## Uni

Строки Unicode с флагом utf8 или если декодирование в utf8 происходит без ошибок.

```perl
"↭" ~~ Uni # -> 1
123 ~~ Uni # -> ""
do {no utf8; "↭" ~~ Uni} # -> 1
```

## Bin

Бинарные строки без флага utf8 и октетов с номерами меньше 128.

```perl
123 ~~ Bin # -> 1
"z" ~~ Bin # -> 1
"↭" ~~ Bin # -> ""
do {no utf8; "↭" ~~ Bin }   # -> ""
```

## StartsWith\[S]

Строка начинается с `S`.

```perl
"Hi, world!" ~~ StartsWith["Hi,"] # -> 1
"Hi world!" ~~ StartsWith["Hi,"] # -> ""
```

## EndsWith\[S]

Строка заканчивается на `S`.

```perl
"Hi, world!" ~~ EndsWith["world!"] # -> 1
"Hi, world" ~~ EndsWith["world!"]  # -> ""
```

## NonEmptyStr

Строка с одним или несколькими символами, не являющимися пробелами.

```perl
" " ~~ NonEmptyStr              # -> ""
" S " ~~ NonEmptyStr            # -> 1
" S " ~~ (NonEmptyStr & Len[2]) # -> ""
```

## Email

Строки с `@`.

```perl
'@' ~~ Email     # -> 1
'a@a.a' ~~ Email # -> 1
'a.a' ~~ Email   # -> ""
```

## Tel

Формат телефонов — знак плюс и семь или больше цифр.

```perl
"+1234567" ~~ Tel # -> 1
"+1234568" ~~ Tel # -> 1
"+ 1234567" ~~ Tel # -> ""
"+1234567 " ~~ Tel # -> ""
```

## Url

URL-адреса веб-сайтов — это строка с префиксом http:// или https://.

```perl
"http://" ~~ Url # -> 1
"http:/" ~~ Url  # -> ""
```

## Path

Пути начинаются с косой черты.

```perl
"/" ~~ Path  # -> 1
"/a/b" ~~ Path  # -> 1
"a/b" ~~ Path   # -> ""
```

## Html

HTML начинается с `<!doctype html` или `<html`.

```perl
"<HTML" ~~ Html   # -> 1
" <html" ~~ Html     # -> 1
" <!doctype html>" ~~ Html # -> 1
" <html1>" ~~ Html   # -> ""
```

## StrDate

Дата в формате `yyyy-mm-dd`.

```perl
"2001-01-12" ~~ StrDate # -> 1
"01-01-01" ~~ StrDate   # -> ""
```

## StrDateTime

Дата и время в формате `yyyy-mm-dd HH:MM:SS`.

```perl
"2012-12-01 00:00:00" ~~ StrDateTime  # -> 1
"2012-12-01 00:00:00 " ~~ StrDateTime # -> ""
```

## StrMatch[qr/.../]

Сопоставляет строку с регулярным выражением.

```perl
' abc ' ~~ StrMatch[qr/abc/]  # -> 1
' abbc ' ~~ StrMatch[qr/abc/] # -> ""
```

## ClassName

Имя класса — это пакет с методом `new`.

```perl
'Aion::Type' ~~ ClassName  # -> 1
'Aion::Types' ~~ ClassName # -> ""
```

## RoleName

Имя роли — это пакет без метода `new`, с `@ISA` или с одним любым методом.

```perl
package ExRole1 {
	sub any_method {}
}

package ExRole2 {
	our @ISA = qw/ExRole1/;
}


'ExRole1' ~~ RoleName    # -> 1
'ExRole2' ~~ RoleName    # -> 1
'Aion::Type' ~~ RoleName # -> ""
'Nouname::Empty::Package' ~~ RoleName # -> ""
```

## Rat

Рациональные числа.

```perl
"6/7" ~~ Rat  # -> 1
"-6/7" ~~ Rat # -> 1
6 ~~ Rat      # -> 1
"inf" ~~ Rat  # -> 1
"+Inf" ~~ Rat # -> 1
"NaN" ~~ Rat  # -> 1
"-nan" ~~ Rat # -> 1
6.5 ~~ Rat    # -> 1
"6.5 " ~~ Rat # -> ''
```

## Num

Числа.

```perl
-6.5 ~~ Num   # -> 1
6.5e-7 ~~ Num # -> 1
"6.5 " ~~ Num # -> ""
```

## PositiveNum

Положительные числа.

```perl
0 ~~ PositiveNum    # -> 1
0.1 ~~ PositiveNum  # -> 1
-0.1 ~~ PositiveNum # -> ""
-0 ~~ PositiveNum   # -> 1
```

## Float

Машинное число с плавающей запятой составляет 4 байта.

```perl
-4.8 ~~ Float             # -> 1
-3.402823466E+38 ~~ Float # -> 1
+3.402823466E+38 ~~ Float # -> 1
-3.402823467E+38 ~~ Float # -> ""
```

## Double

Машинное число с плавающей запятой составляет 8 байт.

```perl
use Scalar::Util qw//;

                      -4.8 ~~ Double # -> 1
'-1.7976931348623157e+308' ~~ Double # -> 1
'+1.7976931348623157e+308' ~~ Double # -> 1
'-1.7976931348623159e+308' ~~ Double # -> ""
```

## Range[from, to]

Числа между `from` и `to`.

```perl
1 ~~ Range[1, 3]   # -> 1
2.5 ~~ Range[1, 3] # -> 1
3 ~~ Range[1, 3]   # -> 1
3.1 ~~ Range[1, 3] # -> ""
0.9 ~~ Range[1, 3] # -> ""
```

## Int

Целые числа.

```perl
123 ~~ Int	# -> 1
-12 ~~ Int	# -> 1
5.5 ~~ Int	# -> ""
```

## Bytes[N]

Рассчитывает максимальное и минимальное числа, которые поместятся в `N` байт и проверяет ограничение между ними.

```perl
-129 ~~ Bytes[1] # -> ""
-128 ~~ Bytes[1] # -> 1
127 ~~ Bytes[1]  # -> 1
128 ~~ Bytes[1]  # -> ""

# 2 bits power of (8 bits * 8 bytes - 1)
my $N = 1 << (8*8-1);
(-$N-1) ~~ Bytes[8] # -> ""
(-$N) ~~ Bytes[8]   # -> 1
($N-1) ~~ Bytes[8]  # -> 1
$N ~~ Bytes[8]      # -> ""

require Math::BigInt;

my $N17 = 1 << (8*Math::BigInt->new(17) - 1);

((-$N17-1) . "") ~~ Bytes[17] # -> ""
(-$N17 . "") ~~ Bytes[17]     # -> 1
(($N17-1) . "") ~~ Bytes[17]  # -> 1
($N17 . "") ~~ Bytes[17]      # -> ""
```

## PositiveInt

Положительные целые числа.

```perl
+0 ~~ PositiveInt # -> 1
-0 ~~ PositiveInt # -> 1
55 ~~ PositiveInt # -> 1
-1 ~~ PositiveInt # -> ""
```

## PositiveBytes[N]

Рассчитывает максимальное число, которое поместится в `N` байт (полагая, что в байтах нет отрицательного бита) и проверяет ограничение от 0 до этого числа.

```perl
-1 ~~ PositiveBytes[1]  # -> ""
0 ~~ PositiveBytes[1]   # -> 1
255 ~~ PositiveBytes[1] # -> 1
256 ~~ PositiveBytes[1] # -> ""

-1 ~~ PositiveBytes[8]   # -> ""
1.01 ~~ PositiveBytes[8] # -> ""
0 ~~ PositiveBytes[8]    # -> 1

my $N8 = 2 ** (8*Math::BigInt->new(8)) - 1;

$N8 . "" ~~ PositiveBytes[8]     # -> 1
($N8+1) . "" ~~ PositiveBytes[8] # -> ""

-1 ~~ PositiveBytes[17] # -> ""
0 ~~ PositiveBytes[17]  # -> 1
```

## Nat

Целые числа 1+.

```perl
0 ~~ Nat	# -> ""
1 ~~ Nat	# -> 1
```

## Ref

Ссылка.

```perl
\1 ~~ Ref # -> 1
[] ~~ Ref # -> 1
1 ~~ Ref  # -> ""
```

## Tied`[A]

Ссылка на связанную переменную.

```perl
package TiedHash { sub TIEHASH { bless {@_}, shift } }
package TiedArray { sub TIEARRAY { bless {@_}, shift } }
package TiedScalar { sub TIESCALAR { bless {@_}, shift } }

tie my %a, "TiedHash";
tie my @a, "TiedArray";
tie my $a, "TiedScalar";
my %b; my @b; my $b;

\%a ~~ Tied # -> 1
\@a ~~ Tied # -> 1
\$a ~~ Tied # -> 1

\%b ~~ Tied  # -> ""
\@b ~~ Tied  # -> ""
\$b ~~ Tied  # -> ""
\\$b ~~ Tied # -> ""

ref tied %a     # => TiedHash
ref tied %{\%a} # => TiedHash

\%a ~~ Tied["TiedHash"]   # -> 1
\@a ~~ Tied["TiedArray"]  # -> 1
\$a ~~ Tied["TiedScalar"] # -> 1

\%a ~~ Tied["TiedArray"]   # -> ""
\@a ~~ Tied["TiedScalar"]  # -> ""
\$a ~~ Tied["TiedHash"]    # -> ""
\\$a ~~ Tied["TiedScalar"] # -> ""
```

## LValueRef

Функция позволяет присваивание.

```perl
ref \substr("abc", 1, 2) # => LVALUE
ref \vec(42, 1, 2) # => LVALUE

\substr("abc", 1, 2) ~~ LValueRef # -> 1
\vec(42, 1, 2) ~~ LValueRef # -> 1
```

Но с `:lvalue` не работает.

```perl
sub abc: lvalue { $_ }

abc() = 12;
$_ # => 12
ref \abc()  # => SCALAR
\abc() ~~ LValueRef	# -> ""


package As {
	sub x : lvalue {
		shift->{x};
	}
}

my $x = bless {}, "As";
$x->x = 10;

$x->x # => 10
$x	# --> bless {x=>10}, "As"

ref \$x->x			 # => SCALAR
\$x->x ~~ LValueRef # -> ""
```

And on the end:

```perl
\1 ~~ LValueRef	# -> ""

my $x = "abc";
substr($x, 1, 1) = 10;

$x # => a10c

LValueRef->include( \substr($x, 1, 1) )	# => 1
```

## FormatRef

Формат.

```perl
format EXAMPLE_FMT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1
\1 ~~ FormatRef				# -> ""
```

## CodeRef`[name, proto]

Подпрограмма.

```perl
sub {} ~~ CodeRef	# -> 1
\1 ~~ CodeRef		# -> ""

sub code_ex ($;$) { ... }

\&code_ex ~~ CodeRef['main::code_ex']         # -> 1
\&code_ex ~~ CodeRef['code_ex']               # -> ""
\&code_ex ~~ CodeRef[qr/_/]                   # -> 1
\&code_ex ~~ CodeRef[undef, '$;$']            # -> 1
\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/] # -> 1
\&code_ex ~~ CodeRef[undef, '@']              # -> ""
\&code_ex ~~ CodeRef['main::code_ex', '$;$']  # -> 1
```


## ReachableCodeRef`[name, proto]

Подпрограмма с телом.

```perl
sub code_forward ($;$);

\&code_ex ~~ ReachableCodeRef['main::code_ex']        # -> 1
\&code_ex ~~ ReachableCodeRef['code_ex']              # -> ""
\&code_ex ~~ ReachableCodeRef[qr/_/]                  # -> 1
\&code_ex ~~ ReachableCodeRef[undef, '$;$']           # -> 1
\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]         # -> 1
\&code_ex ~~ ReachableCodeRef[undef, '@']             # -> ""
\&code_ex ~~ ReachableCodeRef['main::code_ex', '$;$'] # -> 1

\&code_forward ~~ ReachableCodeRef # -> ""
```

## UnreachableCodeRef`[name, proto]

Подпрограмма без тела.

```perl
\&nouname ~~ UnreachableCodeRef # -> 1
\&code_ex ~~ UnreachableCodeRef # -> ""
\&code_forward ~~ UnreachableCodeRef['main::code_forward', '$;$'] # -> 1
```

## Isa[A...]

Ссылка на подпрограмму с соответствующей сигнатурой.

```perl
sub sig_ex :Isa(Int => Str) {}

\&sig_ex ~~ Isa[Int => Str]        # -> 1
\&sig_ex ~~ Isa[Int => Str => Num] # -> ""
\&sig_ex ~~ Isa[Int => Num]        # -> ""
```

Подпрограммы без тела не оборачиваются в обработчик сигнатуры, а сигнатура запоминается для валидации соответствия впоследствии объявленной подпрограммы с телом. Поэтому функция не имеет сигнатуры.

```perl
sub unreachable_sig_ex :Isa(Int => Str);

\&unreachable_sig_ex ~~ Isa[Int => Str] # -> ""
```

## RegexpRef

Регулярное выражение.

```perl
qr// ~~ RegexpRef # -> 1
\1 ~~ RegexpRef   # -> ""
```

## ScalarRefRef`[A]

Ссылка на скаляр или ссылка на ссылку.

```perl
\12    ~~ ScalarRefRef                    # -> 1
\12    ~~ ScalarRefRef                    # -> 1
\-1.2  ~~ ScalarRefRef[Num]               # -> 1
\\-1.2 ~~ ScalarRefRef[ScalarRefRef[Num]] # -> 1
```

## ScalarRef`[A]

Ссылка на скаляр.

```perl
\12   ~~ ScalarRef      # -> 1
\\12  ~~ ScalarRef      # -> ""
\-1.2 ~~ ScalarRef[Num] # -> 1
```

## RefRef`[A]

Ссылка на ссылку.

```perl
\12    ~~ RefRef                 # -> ""
\\12   ~~ RefRef                 # -> 1
\-1.2  ~~ RefRef[Num]            # -> ""
\\-1.2 ~~ RefRef[ScalarRef[Num]] # -> 1
```

## GlobRef

Ссылка на глоб.

```perl
\*A::a ~~ GlobRef # -> 1
*A::a ~~ GlobRef  # -> ""
```

## FileHandle

Файловый описатель.

```perl
\*A::a ~~ FileHandle         # -> ""
\*STDIN ~~ FileHandle        # -> 1

open my $fh, "<", "/dev/null";
$fh ~~ FileHandle	         # -> 1
close $fh;

opendir my $dh, ".";
$dh ~~ FileHandle	         # -> 1
closedir $dh;

use constant { PF_UNIX => 1, SOCK_STREAM => 1 };

socket my $sock, PF_UNIX, SOCK_STREAM, 0;
$sock ~~ FileHandle	         # -> 1
close $sock;
```

## ArrayRef`[A]

Ссылки на массивы.

```perl
[] ~~ ArrayRef	# -> 1
{} ~~ ArrayRef	# -> ""
[] ~~ ArrayRef[Num]	# -> 1
{} ~~ ArrayRef[Num]	# -> ''
[1, 1.1] ~~ ArrayRef[Num]	# -> 1
[1, undef] ~~ ArrayRef[Num]	# -> ""
```

## Lim[A, B?]

Ограничивает массивы от `A` до `B` элементов или от 0 до `A`, если `B` отсутствует.

```perl
[] ~~ Lim[5]     # -> 1
[1..5] ~~ Lim[5] # -> 1
[1..6] ~~ Lim[5] # -> ""

[1..5] ~~ Lim[1,5] # -> 1
[1..6] ~~ Lim[1,5] # -> ""

[1] ~~ Lim[1,5] # -> 1
[] ~~ Lim[1,5]  # -> ""
```

## HashRef`[H]

Ссылки на хеши.

```perl
{} ~~ HashRef # -> 1
\1 ~~ HashRef # -> ""

[]  ~~ HashRef[Int]           # -> ""
{x=>1, y=>2}  ~~ HashRef[Int] # -> 1
{x=>1, y=>""} ~~ HashRef[Int] # -> ""
```

## Object`[O]

Благословлённые ссылки.

```perl
bless(\(my $val=10), "A1") ~~ Object # -> 1
\(my $val=10) ~~ Object              # -> ""

bless(\(my $val=10), "A1") ~~ Object["A1"] # -> 1
bless(\(my $val=10), "A1") ~~ Object["B1"] # -> ""
```

## Me

Благословенные ссылки на объекты текущего пакета.

```perl
package A1 {
 use Aion;
 bless({}, __PACKAGE__) ~~ Me  # -> 1
 bless({}, "A2") ~~ Me         # -> ""
}
```

## Map[K, V]

Как `HashRef`, но с типом для ключей.

```perl
{} ~~ Map[Int, Int]               # -> 1
{5 => 3} ~~ Map[Int, Int]         # -> 1
+{5.5 => 3} ~~ Map[Int, Int]      # -> ""
{5 => 3.3} ~~ Map[Int, Int]       # -> ""
{5 => 3, 6 => 7} ~~ Map[Int, Int] # -> 1
```

## Tuple[A...]

Тьюпл.

```perl
["a", 12] ~~ Tuple[Str, Int]    # -> 1
["a", 12, 1] ~~ Tuple[Str, Int] # -> ""
["a", 12.1] ~~ Tuple[Str, Int]  # -> ""
```

## CycleTuple[A...]

Тьюпл повторённый один или несколько раз.

```perl
["a", -5] ~~ CycleTuple[Str, Int] # -> 1
["a", -5, "x"] ~~ CycleTuple[Str, Int] # -> ""
["a", -5, "x", -6] ~~ CycleTuple[Str, Int] # -> 1
["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int] # -> ""
```

## Dict[k => A, ...]

Словарь.

```perl
{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str] # -> 1

{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str] # -> ""
{a => -1.6} ~~ Dict[a => Num, b => Str] # -> ""

{a => -1.6} ~~ Dict[a => Num, b => Option[Str]] # -> 1
```

## HasProp[p...]

Хэш имеет перечисленные свойства. Кроме них он может иметь и другие.

```perl
[0, 1] ~~ HasProp[qw/0 1/] # -> ""

{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/] # -> 1
{a => 1, b => 2} ~~ HasProp[qw/a b/] # -> 1
{a => 1, c => 3} ~~ HasProp[qw/a b/] # -> ""

bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/] # -> 1
```

## Like

Объект или строка.

```perl
"" ~~ Like # -> 1
1 ~~ Like  # -> 1
bless({}, "A") ~~ Like # -> 1
bless([], "A") ~~ Like # -> 1
bless(\(my $str = ""), "A") ~~ Like # -> 1
\1 ~~ Like  # -> ""
```

## HasMethods[m...]

Объект или класс имеет перечисленные методы. Кроме них может иметь и другие.

```perl
package HasMethodsExample {
	sub x1 {}
	sub x2 {}
}

"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]			# -> 1
bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1
bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]	# -> 1
"HasMethodsExample" ~~ HasMethods[qw/x3/]				# -> ""
"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]			# -> ""
"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]			# -> ""
```

## Overload`[op...]

Объект или класс с перегруженными операторами.

```perl
package OverloadExample {
	use overload '""' => sub { "abc" };
}

"OverloadExample" ~~ Overload            # -> 1
bless({}, "OverloadExample") ~~ Overload # -> 1
"A" ~~ Overload                          # -> ""
bless({}, "A") ~~ Overload               # -> ""
```

И у него есть операторы указанные операторы.

```perl
"OverloadExample" ~~ Overload['""'] # -> 1
"OverloadExample" ~~ Overload['|']  # -> ""
```

## InstanceOf[A...]

Класс или объект наследует классы из списка.

```perl
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


"Tiger" ~~ InstanceOf['Animal', 'Cat'] # -> 1
"Tiger" ~~ InstanceOf['Tiger']         # -> 1
"Tiger" ~~ InstanceOf['Cat', 'Dog']    # -> ""
```

## ConsumerOf[A...]

Класс или объект имеет указанные роли.

```perl
package NoneExample {}
package RoleExample { sub DOES { $_[1] ~~ [qw/Role1 Role2/] } }

'RoleExample' ~~ ConsumerOf[qw/Role1/] # -> 1
'RoleExample' ~~ ConsumerOf[qw/Role2 Role1/] # -> 1
bless({}, 'RoleExample') ~~ ConsumerOf[qw/Role3 Role2 Role1/] # -> ""

'NoneExample' ~~ ConsumerOf[qw/Role1/] # -> ""
```

## BoolLike

Проверяет 1, 0, "", undef или объект с перегруженным оператором `bool` или `0+` как `JSON::PP::Boolean`. Во втором случае вызывает оператор  `0+` и проверяет результат как `Bool`.

`BoolLike` вызывает оператор `0+` и проверяет результат.

```perl
package BoolLikeExample {
	use overload '0+' => sub { ${$_[0]} };
}

bless(\(my $x = 1 ), 'BoolLikeExample') ~~ BoolLike # -> 1
bless(\(my $x = 11), 'BoolLikeExample') ~~ BoolLike # -> ""

1 ~~ BoolLike     # -> 1
0 ~~ BoolLike     # -> 1
"" ~~ BoolLike    # -> 1
undef ~~ BoolLike # -> 1

package BoolLike2Example {
	use overload 'bool' => sub { ${$_[0]} };
}

bless(\(my $x = 1 ), 'BoolLike2Example') ~~ BoolLike # -> 1
bless(\(my $x = 11), 'BoolLike2Example') ~~ BoolLike # -> 1
```

## StrLike

Строка или объект с перегруженным оператором `""`.

```perl
"" ~~ StrLike # -> 1

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

bless({}, "StrLikeExample") ~~ StrLike # -> 1

{} ~~ StrLike # -> ""
```

## RegexpLike

Регулярное выражение или объект с перегруженным оператором `qr`.

```perl
ref(qr//)  # => Regexp
Scalar::Util::reftype(qr//) # => REGEXP

my $regex = bless qr//, "A";
Scalar::Util::reftype($regex) # => REGEXP

$regex ~~ RegexpLike # -> 1
qr// ~~ RegexpLike   # -> 1
"" ~~ RegexpLike     # -> ""

package RegexpLikeExample {
 use overload 'qr' => sub { qr/abc/ };
}

"RegexpLikeExample" ~~ RegexpLike # -> ""
bless({}, "RegexpLikeExample") ~~ RegexpLike # -> 1
```

## CodeLike

Подпрограмма или объект с перегруженным оператором `&{}`.

```perl
sub {} ~~ CodeLike     # -> 1
\&CodeLike ~~ CodeLike # -> 1
{} ~~ CodeLike         # -> ""
```

## ArrayLike`[A]

Массивы или объекты с перегруженным оператором или `@{}`.

```perl
{} ~~ ArrayLike      # -> ""
{} ~~ ArrayLike[Int] # -> ""

[] ~~ ArrayLike # -> 1

package ArrayLikeExample {
	use overload '@{}' => sub {
		shift->{array} //= []
	};
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
$x->{array} # --> [undef, 12]

$x ~~ ArrayLike # -> 1

$x ~~ ArrayLike[Int] # -> ""

$x->[0] = 13;
$x ~~ ArrayLike[Int] # -> 1
```

## HashLike`[A]

Хэши или объекты с перегруженным оператором `%{}`.

```perl
{} ~~ HashLike  # -> 1
[] ~~ HashLike  # -> ""
[] ~~ HashLike[Int] # -> ""

package HashLikeExample {
	use overload '%{}' => sub {
		shift->[0] //= {}
	};
}

my $x = bless [], 'HashLikeExample';
$x->{key} = 12.3;
$x->[0]  # --> {key => 12.3}

$x ~~ HashLike      # -> 1
$x ~~ HashLike[Int] # -> ""
$x ~~ HashLike[Num] # -> 1
```

# Coerces

## Join\[R] as Str

Сктроковый тип с преобразованием массивов в строку через разделитель.

```perl
Join([' '])->coerce([qw/a b c/]) # => a b c

package JoinExample { use Aion;
	has s => (isa => Join[', '], coerce => 1);
}

JoinExample->new(s => [qw/a b c/])->s # => a, b, c

JoinExample->new(s => 'string')->s # => string
```

## Split\[S] as ArrayRef

```perl
Split([' '])->coerce('a b c') # --> [qw/a b c/]

package SplitExample { use Aion;
	has s => (isa => Split[qr/\s*,\s*/], coerce => 1);
}

SplitExample->new(s => 'a, b, c')->s # --> [qw/a b c/]
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Types module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
