# NAME

Aion::Types is a library of validators. And it makes new validators

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

This module export subroutines:

* `subtype`, `as`, `init_where`, `where`, `awhere`, `message` — for create validators.
* `SELF`, `ARGS`, `A`, `B`, `C`, `D`, `M`, `N` — for use in validators has arguments.
* `coerce`, `from`, `via` — for create coerce, using for translate values from one class to other class.

Hierarhy of validators:

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
				CodeRef
				RegexpRef
				ScalarRef`[A]
				RefRef`[A]
				GlobRef`[A]
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

Make new type.

```perl
BEGIN {
	subtype One => where { $_ == 1 } message { "Actual 1 only!" };
}

1 ~~ One	 # -> 1
0 ~~ One	 # -> ""
eval { One->validate(0) }; $@ # ~> Actual 1 only!
```

`where` and `message` is syntax sugar, and `subtype` can be used without them.

```perl
BEGIN {
	subtype Many => (where => sub { $_ > 1 });
}

2 ~~ Many  # -> 1

eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@ # ~> subtype Many unused keys left: where1

eval { subtype 'Many' }; $@ # ~> subtype Many: main::Many exists!
```

## as ($parenttype)

Use with `subtype` for extended create type of `$parenttype`.

## init_where ($code)

Initialize type with new arguments. Use with `subtype`.

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

Set in type `$code` as test. Value for test set in `$_`.

```perl
BEGIN {
	subtype 'Two',
		where { $_ == 2 };
}

2 ~~ Two # -> 1
3 ~~ Two # -> ""
```

Use with `subtype`. Need if is the required arguments.

```perl
eval { subtype 'Ex[A]' }; $@  # ~> subtype Ex\[A\]: needs a where
```

## awhere ($code)

Use with `subtype`.

If type maybe with and without arguments, then use for set test with arguments, and `where` - without.

```perl
BEGIN {
	subtype 'GreatThen`[A]',
		where { $_ > 0 }
		awhere { $_ > A }
	;
}

0 ~~ GreatThen	# -> ""
1 ~~ GreatThen	# -> 1

3 ~~ GreatThen[3] # -> ""
4 ~~ GreatThen[3] # -> 1
```

Need if arguments is optional.

```perl
eval { subtype 'Ex`[A]', where {} }; $@  # ~> subtype Ex`\[A\]: needs a awhere
eval { subtype 'Ex', awhere {} }; $@  # ~> subtype Ex: awhere is excess

BEGIN {
	subtype 'MyEnum`[A...]',
		as Str,
		awhere { $_ ~~ scalar ARGS }
	;
}

"ab" ~~ MyEnum[qw/ab cd/] # -> 1
```

## SELF

The current type. `SELF` use in `init_where`, `where` and `awhere`.

## ARGS

Arguments of the current type. In scalar context returns array ref on the its. And in array context returns its. Use in `init_where`, `where` and `awhere`.

## A, B, C, D

First, second, third and fifth argument of the type.

```perl
BEGIN {
	subtype "Seria[A,B,C,D]", where { A < B && B < $_ && $_ < C && C < D };
}

2.5 ~~ Seria[1,2,3,4]   # -> 1
```

Use in `init_where`, `where` and `awhere`.

## M, N

`M` and `N` is the reduction for `SELF->{M}` and `SELF->{N}`.

```perl
BEGIN {
	subtype "BeginAndEnd[A, B]",
		init_where {
			N = qr/^${\ quotemeta A}/;
			M = qr/${\ quotemeta B}$/;
		}
		where { $_ =~ N && $_ =~ M };
}

"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"];   # -> 1
"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];   # -> ""

"" . BeginAndEnd["Hi,", "!"]   # => BeginAndEnd['Hi,', '!']
```

## message ($code)

Use with `subtype` for make the message on error, if the value excluded the type. In `$code` use subroutine: `SELF` - the current type, `ARGS`, `A`, `B`, `C`, `D` - arguments of type (if is), and the testing value in `$_`. It can be stringified using `SELF->val_to_str($_)`.

## coerce ($type, from => $from, via => $via)

It add new coerce ($via) to `$type` from `$from`-type.

```perl
BEGIN {subtype Four => where {4 eq $_}}

"4a" ~~ Four	# -> ""

Four->coerce("4a")	# -> "4a"

coerce Four, from Str, via { 0+$_ };

Four->coerce("4a")	# -> 4

coerce Four, from ArrayRef, via { scalar @$_ };

Four->coerce([1,2,3])           # -> 3
Four->coerce([1,2,3]) ~~ Four   # -> ""
Four->coerce([1,2,3,4]) ~~ Four # -> 1
```

`coerce` throws exeptions:

```perl
eval {coerce Int, via1 => 1}; $@  # ~> coerce Int unused keys left: via1
eval {coerce "x"}; $@  # ~> coerce x not Aion::Type!
eval {coerce Int}; $@  # ~> coerce Int: from is'nt Aion::Type!
eval {coerce Int, from "x"}; $@  # ~> coerce Int: from is'nt Aion::Type!
eval {coerce Int, from Num}; $@  # ~> coerce Int: via is not subroutine!
eval {coerce Int, (from=>Num, via=>"x")}; $@  # ~> coerce Int: via is not subroutine!
```

Standart coerces:

```perl
# Str from Undef — empty string
Str->coerce(undef) # -> ""

# Int from Num — rounded integer
Int->coerce(2.5) # -> 3
Int->coerce(-2.5) # -> -3

# Bool from Any — 1 or ""
Bool->coerce([])	# -> 1
Bool->coerce(0)		# -> ""
```

## from ($type)

Syntax sugar for `coerce`.

## via ($code)

Syntax sugar for `coerce`.

# ATTRIBUTES

## :Isa (@signature)

Check the subroutine signature: arguments and returns.

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

Top-level type in the hierarchy. Match all.

## Control

Top-level type in the hierarchy constructors new types from any types.

## Union[A, B...]

Union many types. It analog operator `$type1 | $type2`.

```perl
33  ~~ Union[Int, Ref]	# -> 1
[]  ~~ Union[Int, Ref]	# -> 1
"a" ~~ Union[Int, Ref]	# -> ""
```

## Intersection[A, B...]

Intersection many types. It analog operator `$type1 & $type2`.

```perl
15 ~~ Intersection[Int, StrMatch[/5/]]	# -> 1
```

## Exclude[A, B...]

Exclude many types. It analog operator `~ $type`.

```perl
-5  ~~ Exclude[PositiveInt]	# -> 1
"a" ~~ Exclude[PositiveInt]	# -> 1
5   ~~ Exclude[PositiveInt]	# -> ""
5.5 ~~ Exclude[PositiveInt]	# -> 1
```

If `Exclude` has many arguments, then this analog `~ ($type1 | $type2 ...)`.

```perl
-5  ~~ Exclude[PositiveInt, Enum[-2]]	# -> 1
-2  ~~ Exclude[PositiveInt, Enum[-2]]	# -> ""
0   ~~ Exclude[PositiveInt, Enum[-2]]	# -> ""
```

## Option[A]

The optional keys in the `Dict`.

```perl
{a=>55} ~~ Dict[a=>Int, b => Option[Int]] # -> 1
{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]] # -> 1
{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]] # -> ""
```

## Wantarray[A, S]

if the subroutine returns different values in the context of an array and a scalar, then using type `Wantarray` with type `A` for array context and type `S` for scalar context.

```perl
sub arr : Isa(PositiveInt => Wantarray[ArrayRef[PositiveInt], PositiveInt]) {
	my ($n) = @_;
	wantarray? 1 .. $n: $n
}

my @a = arr(3);
my $s = arr(3);

\@a  # --> [1,2,3]
$s	 # -> 3
```

## Item

Top-level type in the hierarchy scalar types.

## Bool

`1` is true. `0`, `""` or `undef` is false.

```perl
1 ~~ Bool	 # -> 1
0 ~~ Bool	 # -> 1
undef ~~ Bool # -> 1
"" ~~ Bool	# -> 1

2 ~~ Bool	 # -> ""
[] ~~ Bool	# -> ""
```

## Enum[A...]

Enumerate values.

```perl
3 ~~ Enum[1,2,3]			# -> 1
"cat" ~~ Enum["cat", "dog"] # -> 1
4 ~~ Enum[1,2,3]			# -> ""
```

## Maybe[A]

`undef` or type in `[]`.

```perl
undef ~~ Maybe[Int]	# -> 1
4 ~~ Maybe[Int]		# -> 1
"" ~~ Maybe[Int]	   # -> ""
```

## Undef

`undef` only.

```perl
undef ~~ Undef	# -> 1
0 ~~ Undef		# -> ""
```

## Defined

All exclude `undef`.

```perl
\0 ~~ Defined	   # -> 1
undef ~~ Defined	# -> ""
```

## Value

Defined unreference values.

```perl
3 ~~ Value		# -> 1
\3 ~~ Value	   # -> ""
undef ~~ Value	# -> ""
```

## Len[A, B?]

Defines the length value from `A` to `B`, or from 0 to `A` if `B` is'nt present.

```perl
"1234" ~~ Len[3]   # -> ""
"123" ~~ Len[3]	# -> 1
"12" ~~ Len[3]	 # -> 1
"" ~~ Len[1, 2]	# -> ""
"1" ~~ Len[1, 2]   # -> 1
"12" ~~ Len[1, 2]  # -> 1
"123" ~~ Len[1, 2] # -> ""
```

## Version

Perl versions.

```perl
1.1.0 ~~ Version	# -> 1
v1.1.0 ~~ Version   # -> 1
v1.1 ~~ Version	 # -> 1
v1 ~~ Version	   # -> 1
1.1 ~~ Version	  # -> ""
"1.1.0" ~~ Version  # -> ""
```

## Str

Strings, include numbers.

```perl
1.1 ~~ Str		 # -> 1
"" ~~ Str		  # -> 1
1.1.0 ~~ Str	   # -> ""
```

## Uni

Unicode strings: with utf8-flag or decode to utf8 without error.

```perl
"↭" ~~ Uni	# -> 1
123 ~~ Uni	# -> ""
do {no utf8; "↭" ~~ Uni}	# -> 1
```

## Bin

Binary strings: without utf8-flag and octets with numbers less then 128.

```perl
123 ~~ Bin	# -> 1
"z" ~~ Bin	# -> 1
"↭" ~~ Bin	# -> ""
do {no utf8; "↭" ~~ Bin }   # -> ""
```

## StartsWith\[S]

The string starts with `S`.

```perl
"Hi, world!" ~~ StartsWith["Hi,"]	# -> 1
"Hi world!" ~~ StartsWith["Hi,"]	# -> ""
```

## EndsWith\[S]

The string ends with `S`.

```perl
"Hi, world!" ~~ EndsWith["world!"]	# -> 1
"Hi, world" ~~ EndsWith["world!"]	# -> ""
```

## NonEmptyStr

String with one or many non-space characters.

```perl
" " ~~ NonEmptyStr		# -> ""
" S " ~~ NonEmptyStr	  # -> 1
" S " ~~ (NonEmptyStr & Len[2])   # -> ""
```

## Email

Strings with `@`.

```perl
'@' ~~ Email	  # -> 1
'a@a.a' ~~ Email  # -> 1
'a.a' ~~ Email	# -> ""
```

## Tel

Format phones is plus sign and seven or great digits.

```perl
"+1234567" ~~ Tel	# -> 1
"+1234568" ~~ Tel	# -> 1
"+ 1234567" ~~ Tel	# -> ""
"+1234567 " ~~ Tel	# -> ""
```

## Url

Web urls is string with prefix http:// or https://.

```perl
"http://" ~~ Url	# -> 1
"http:/" ~~ Url	# -> ""
```

## Path

The paths starts with a slash.

```perl
"/" ~~ Path	 # -> 1
"/a/b" ~~ Path  # -> 1
"a/b" ~~ Path   # -> ""
```

## Html

The html starts with a `<!doctype` or `<html`.

```perl
"<HTML" ~~ Html			# -> 1
" <html" ~~ Html		   # -> 1
" <!doctype html>" ~~ Html # -> 1
" <html1>" ~~ Html		 # -> ""
```

## StrDate

The date is format `yyyy-mm-dd`.

```perl
"2001-01-12" ~~ StrDate	# -> 1
"01-01-01" ~~ StrDate	# -> ""
```

## StrDateTime

The dateTime is format `yyyy-mm-dd HH:MM:SS`.

```perl
"2012-12-01 00:00:00" ~~ StrDateTime	 # -> 1
"2012-12-01 00:00:00 " ~~ StrDateTime	# -> ""
```

## StrMatch[qr/.../]

Match value with regular expression.

```perl
' abc ' ~~ StrMatch[qr/abc/]	# -> 1
' abbc ' ~~ StrMatch[qr/abc/]   # -> ""
```

## ClassName

Classname is the package with method `new`.

```perl
'Aion::Type' ~~ ClassName  # -> 1
'Aion::Types' ~~ ClassName # -> ""
```

## RoleName

Rolename is the package without method `new`, and with `@ISA` or with one any method.

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

Rational numbers.

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

The numbers.

```perl
-6.5 ~~ Num   # -> 1
6.5e-7 ~~ Num # -> 1
"6.5 " ~~ Num # -> ""
```

## PositiveNum

The positive numbers.

```perl
0 ~~ PositiveNum    # -> 1
0.1 ~~ PositiveNum  # -> 1
-0.1 ~~ PositiveNum # -> ""
-0 ~~ PositiveNum   # -> 1
```

## Float

The machine float number is 4 bytes.

```perl
-4.8 ~~ Float             # -> 1
-3.402823466E+38 ~~ Float # -> 1
+3.402823466E+38 ~~ Float # -> 1
-3.402823467E+38 ~~ Float # -> ""
```

## Double

The machine float number is 8 bytes.

```perl
use Scalar::Util qw//;

                      -4.8 ~~ Double # -> 1
'-1.7976931348623157e+308' ~~ Double # -> 1
'+1.7976931348623157e+308' ~~ Double # -> 1
'-1.7976931348623159e+308' ~~ Double # -> ""
```

## Range[from, to]

Numbers between `from` and `to`.

```perl
1 ~~ Range[1, 3]   # -> 1
2.5 ~~ Range[1, 3] # -> 1
3 ~~ Range[1, 3]   # -> 1
3.1 ~~ Range[1, 3] # -> ""
0.9 ~~ Range[1, 3] # -> ""
```

## Int

Integers.

```perl
123 ~~ Int	# -> 1
-12 ~~ Int	# -> 1
5.5 ~~ Int	# -> ""
```

## Bytes[N]

`N` - the number of bytes for limit.

```perl
-129 ~~ Bytes[1]	# -> ""
-128 ~~ Bytes[1]	# -> 1
127 ~~ Bytes[1]	 # -> 1
128 ~~ Bytes[1]	 # -> ""

# 2 bits power of (8 bits * 8 bytes - 1)
my $N = 1 << (8*8-1);
(-$N-1) ~~ Bytes[8]   # -> ""
(-$N) ~~ Bytes[8]	 # -> 1
($N-1) ~~ Bytes[8]	  # -> 1
$N ~~ Bytes[8]		  # -> ""

require Math::BigInt;

my $N17 = 1 << (8*Math::BigInt->new(17) - 1);

((-$N17-1) . "") ~~ Bytes[17]  # -> ""
(-$N17 . "") ~~ Bytes[17]  # -> 1
(($N17-1) . "") ~~ Bytes[17]  # -> 1
($N17 . "") ~~ Bytes[17]  # -> ""
```

## PositiveInt

Positive integers.

```perl
+0 ~~ PositiveInt	# -> 1
-0 ~~ PositiveInt	# -> 1
55 ~~ PositiveInt	# -> 1
-1 ~~ PositiveInt	# -> ""
```

## PositiveBytes[N]

`N` - the number of bytes for limit.

```perl
-1 ~~ PositiveBytes[1]	# -> ""
0 ~~ PositiveBytes[1]	# -> 1
255 ~~ PositiveBytes[1]	# -> 1
256 ~~ PositiveBytes[1]	# -> ""

-1 ~~ PositiveBytes[8] # -> ""
1.01 ~~ PositiveBytes[8] # -> ""
0 ~~ PositiveBytes[8] # -> 1

my $N8 = 2 ** (8*Math::BigInt->new(8)) - 1;

$N8 . "" ~~ PositiveBytes[8] # -> 1
($N8+1) . "" ~~ PositiveBytes[8] # -> ""

-1 ~~ PositiveBytes[17] # -> ""
0 ~~ PositiveBytes[17] # -> 1
```

## Nat

Integers 1+.

```perl
0 ~~ Nat	# -> ""
1 ~~ Nat	# -> 1
```

## Ref

The value is reference.

```perl
\1 ~~ Ref	# -> 1
1 ~~ Ref	 # -> ""
```

## Tied`[A]

The reference on the tied variable.

```perl
package TiedHash { sub TIEHASH { bless {@_}, shift } }
package TiedArray { sub TIEARRAY { bless {@_}, shift } }
package TiedScalar { sub TIESCALAR { bless {@_}, shift } }

tie my %a, "TiedHash";
tie my @a, "TiedArray";
tie my $a, "TiedScalar";
my %b; my @b; my $b;

\%a ~~ Tied	# -> 1
\@a ~~ Tied	# -> 1
\$a ~~ Tied	# -> 1

\%b ~~ Tied	# -> ""
\@b ~~ Tied	# -> ""
\$b ~~ Tied	# -> ""
\\$b ~~ Tied	# -> ""

ref tied %a  # => TiedHash
ref tied %{\%a}  # => TiedHash

\%a ~~ Tied["TiedHash"]	 # -> 1
\@a ~~ Tied["TiedArray"]	# -> 1
\$a ~~ Tied["TiedScalar"]   # -> 1

\%a ~~ Tied["TiedArray"]	# -> ""
\@a ~~ Tied["TiedScalar"]   # -> ""
\$a ~~ Tied["TiedHash"]	 # -> ""
\\$a ~~ Tied["TiedScalar"]	 # -> ""


```

## LValueRef

The function allows assignment.

```perl
ref \substr("abc", 1, 2) # => LVALUE
ref \vec(42, 1, 2) # => LVALUE

\substr("abc", 1, 2) ~~ LValueRef # -> 1
\vec(42, 1, 2) ~~ LValueRef # -> 1
```

But it with `: lvalue` do'nt working.

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

LValueRef->include(\substr($x, 1, 1))	# => 1
```

## FormatRef

The format.

```perl
format EXAMPLE_FMT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1
\1 ~~ FormatRef				# -> ""
```

## CodeRef

Subroutine.

```perl
sub {} ~~ CodeRef	# -> 1
\1 ~~ CodeRef		# -> ""
```

## RegexpRef

The regular expression.

```perl
qr// ~~ RegexpRef	# -> 1
\1 ~~ RegexpRef		 # -> ""
```

## ScalarRef`[A]

The scalar.

```perl
\12 ~~ ScalarRef			 # -> 1
\\12 ~~ ScalarRef			# -> ""
\-1.2 ~~ ScalarRef[Num]	 # -> 1
\\-1.2 ~~ ScalarRef[Num]	 # -> ""
```

## RefRef`[A]

The ref as ref.

```perl
\\1 ~~ RefRef	# -> 1
\1 ~~ RefRef	 # -> ""
\\1.3 ~~ RefRef[ScalarRef[Num]]	# -> 1
\1.3 ~~ RefRef[ScalarRef[Num]]	# -> ""
```

## GlobRef

The global.

```perl
\*A::a ~~ GlobRef	# -> 1
*A::a ~~ GlobRef	 # -> ""
```

## ArrayRef`[A]

The arrays.

```perl
[] ~~ ArrayRef	# -> 1
{} ~~ ArrayRef	# -> ""
[] ~~ ArrayRef[Num]	# -> 1
{} ~~ ArrayRef[Num]	# -> ''
[1, 1.1] ~~ ArrayRef[Num]	# -> 1
[1, undef] ~~ ArrayRef[Num]	# -> ""
```

## Lim[A, B?]

Limit arrays from `A` to `B`, or from 0 to `A`, if `B` is'nt present.

```perl
[] ~~ Lim[5] # -> 1
[1..5] ~~ Lim[5] # -> 1
[1..6] ~~ Lim[5] # -> ""

[1..5] ~~ Lim[1,5] # -> 1
[1..6] ~~ Lim[1,5] # -> ""

[1] ~~ Lim[1,5] # -> 1
[] ~~ Lim[1,5] # -> ""
```

## HashRef`[H]

The hashes.

```perl
{} ~~ HashRef	# -> 1
\1 ~~ HashRef	# -> ""

[]  ~~ HashRef[Int]	# -> ""
{x=>1, y=>2}  ~~ HashRef[Int]	# -> 1
{x=>1, y=>""} ~~ HashRef[Int]	# -> ""
```

## Object`[O]

The blessed values.

```perl
bless(\(my $val=10), "A1") ~~ Object	# -> 1
\(my $val=10) ~~ Object					# -> ""

bless(\(my $val=10), "A1") ~~ Object["A1"]   # -> 1
bless(\(my $val=10), "A1") ~~ Object["B1"]   # -> ""
```

## Me

The blessed values self package.

```perl
package A1 {
	use Aion;
	bless({}, __PACKAGE__) ~~ Me  # -> 1
	bless({}, "A2") ~~ Me  # -> ""
}
```

## Map[K, V]

As `HashRef`, but has type for keys also.

```perl
{} ~~ Map[Int, Int]			 # -> 1
{5 => 3} ~~ Map[Int, Int]	# -> 1
+{5.5 => 3} ~~ Map[Int, Int] # -> ""
{5 => 3.3} ~~ Map[Int, Int]  # -> ""
{5 => 3, 6 => 7} ~~ Map[Int, Int]  # -> 1
```

## Tuple[A...]

The tuple.

```perl
["a", 12] ~~ Tuple[Str, Int]	# -> 1
["a", 12, 1] ~~ Tuple[Str, Int]	# -> ""
["a", 12.1] ~~ Tuple[Str, Int]	# -> ""
```

## CycleTuple[A...]

The tuple one or more times.

```perl
["a", -5] ~~ CycleTuple[Str, Int]	# -> 1
["a", -5, "x"] ~~ CycleTuple[Str, Int]	# -> ""
["a", -5, "x", -6] ~~ CycleTuple[Str, Int]	# -> 1
["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]	# -> ""
```

## Dict[k => A, ...]

The dictionary.

```perl
{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]	# -> 1

{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]	# -> ""
{a => -1.6} ~~ Dict[a => Num, b => Str]	# -> ""

{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]	# -> 1
```

## HasProp[p...]

The hash has the properties.

```perl
[0, 1] ~~ HasProp[qw/0 1/]	# -> ""

{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]	# -> 1
{a => 1, b => 2} ~~ HasProp[qw/a b/]	# -> 1
{a => 1, c => 3} ~~ HasProp[qw/a b/]	# -> ""

bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]	# -> 1
```

## Like

The object or string.

```perl
"" ~~ Like		# -> 1
1 ~~ Like		# -> 1
bless({}, "A") ~~ Like	# -> 1
bless([], "A") ~~ Like	# -> 1
bless(\(my $str = ""), "A") ~~ Like	# -> 1
\1 ~~ Like		# -> ""
```

## HasMethods[m...]

The object or the class has the methods.

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

The object or the class is overloaded.

```perl
package OverloadExample {
	use overload '""' => sub { "abc" };
}

"OverloadExample" ~~ Overload	# -> 1
bless({}, "OverloadExample") ~~ Overload	# -> 1
"A" ~~ Overload					# -> ""
bless({}, "A") ~~ Overload		# -> ""
```

And it has the operators if arguments are specified.

```perl
"OverloadExample" ~~ Overload['""']   # -> 1
"OverloadExample" ~~ Overload['|']	# -> ""
```

## InstanceOf[A...]

The class or the object inherits the list of classes.

```perl
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


"Tiger" ~~ InstanceOf['Animal', 'Cat']  # -> 1
"Tiger" ~~ InstanceOf['Tiger']			# -> 1
"Tiger" ~~ InstanceOf['Cat', 'Dog']		# -> ""
```

## ConsumerOf[A...]

The class or the object has the roles.

The presence of the role is checked by the `DOES` method.

```perl
package NoneExample {}
package RoleExample { sub DOES { $_[1] ~~ [qw/Role1 Role2/] } }

'RoleExample' ~~ ConsumerOf[qw/Role1/] # -> 1
'RoleExample' ~~ ConsumerOf[qw/Role2 Role1/] # -> 1
bless({}, 'RoleExample') ~~ ConsumerOf[qw/Role3 Role2 Role1/] # -> ""

'NoneExample' ~~ ConsumerOf[qw/Role1/]	# -> ""
```

## BoolLike

Check the 1, 0, "", undef or object with overloaded operator `0+` as `JSON::PP::Boolean`.

The operator `0+` evaluates, and result is checking.

```perl
package BoolLikeExample {
	use overload '0+' => sub { ${$_[0]} };
}

bless(\(my $x = 1 ), 'BoolLikeExample') ~~ BoolLike # -> 1
bless(\(my $x = 11), 'BoolLikeExample') ~~ BoolLike # -> ""

1 ~~ BoolLike	  # -> 1
0 ~~ BoolLike	  # -> 1
"" ~~ BoolLike	  # -> 1
undef ~~ BoolLike # -> 1
```

## StrLike

String or object with overloaded operator `""`.

```perl
"" ~~ StrLike								# -> 1

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

bless({}, "StrLikeExample") ~~ StrLike		# -> 1

{} ~~ StrLike								# -> ""
```

## RegexpLike

The regular expression or the object with overloaded operator `qr`.

```perl
ref(qr//)  # => Regexp
Scalar::Util::reftype(qr//)  # => REGEXP

my $regex = bless qr//, "A";
Scalar::Util::reftype($regex) # => REGEXP

$regex ~~ RegexpLike	# -> 1
qr// ~~ RegexpLike		# -> 1
"" ~~ RegexpLike		# -> ""

package RegexpLikeExample {
	use overload 'qr' => sub { qr/abc/ };
}

"RegexpLikeExample" ~~ RegexpLike	# -> ""
bless({}, "RegexpLikeExample") ~~ RegexpLike	# -> 1
```

## CodeLike

The subroutines.

```perl
sub {} ~~ CodeLike		# -> 1
\&CodeLike ~~ CodeLike  # -> 1
{} ~~ CodeLike		  # -> ""
```

## ArrayLike`[A]

The arrays or objects with  or overloaded operator `@{}`.

```perl
{} ~~ ArrayLike			# -> ""
{} ~~ ArrayLike[Int]	# -> ""

[] ~~ ArrayLike		# -> 1

package ArrayLikeExample {
	use overload '@{}' => sub {
		shift->{array} //= []
	};
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
$x->{array}  # --> [undef, 12]

$x ~~ ArrayLike	# -> 1

$x ~~ ArrayLike[Int]	# -> ""

$x->[0] = 13;
$x ~~ ArrayLike[Int]	# -> 1
```

## HashLike`[A]

The hashes or objects with overloaded operator `%{}`.

```perl
{} ~~ HashLike		# -> 1
[] ~~ HashLike		# -> ""
[] ~~ HashLike[Int] # -> ""

package HashLikeExample {
	use overload '%{}' => sub {
		shift->[0] //= {}
	};
}

my $x = bless [], 'HashLikeExample';
$x->{key} = 12.3;
$x->[0]  # --> {key => 12.3}

$x ~~ HashLike		   # -> 1
$x ~~ HashLike[Int]	# -> ""
$x ~~ HashLike[Num]	# -> 1
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Types module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
