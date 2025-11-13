# NAME

Aion::Type - class of validators

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

This is construct for make any validators.

It using in `Aion::Types::subtype`.

# METHODS

## new (%ARGUMENTS)

Constructor.

### ARGUMENTS

* name (Str) — Name of type.
* args (ArrayRef) — List of type arguments.
* init (CodeRef) — Initializer for type.
* test (CodeRef) — Values cheker.
* a_test (CodeRef) — Values cheker for types with optional arguments.
* coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) — Array of pairs: type and via.

## stringify

Stringify of object (name with arguments):

```perl
my $Char = Aion::Type->new(name => "Char");

$Char->stringify # => Char

my $Int = Aion::Type->new(
	name => "Int",
	args => [3, 5],
);

$Int->stringify  #=> Int[3, 5]
```

Stringify operations:

```perl
($Int & $Char)->stringify   # => ( Int[3, 5] & Char )
($Int | $Char)->stringify   # => ( Int[3, 5] | Char )
(~$Int)->stringify		  # => ~Int[3, 5]
```

The operations is objects of `Aion::Type` with special names:

```perl
Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )
Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )
Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )
```

## test

Testing the `$_` belongs to the class.

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

Initial the validator.

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

checks whether the argument belongs to the class.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

$PositiveInt->include(5) # -> 1
$PositiveInt->include(-6) # -> ""
```

## exclude ($element)

Checks that the argument does not belong to the class.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

$PositiveInt->exclude(5)  # -> ""
$PositiveInt->exclude(-6) # -> 1
```

## coerce ($value)

Coerce `$value` to the type, if coerce from type and function is in `$self->{coerce}`.

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

Return message belongs to error.

```perl
my $Int = Aion::Type->new(name => "Int");

$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!

my $Num = Aion::Type->new(name => "Num", message => sub {
	"Error: $_ is'nt $Aion::Type::SELF->{N}!"
});

$Num->detail("x", "car")  # => Error: x is'nt car!
```

`$Aion::Type::SELF->{N}` equivalent to `N` in context of `Aion::Types`.

## validate ($element, $feature)

It tested `$element` and throw `detail` if element is exclude from class.

```perl
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

eval {
	$PositiveInt->validate(-1, "Neg")
};
$@   # ~> Neg must have the type PositiveInt. The it is -1
```

## val_to_str ($val)

Переводит `$val` в строку.

```perl
Aion::Type->new->val_to_str([1,2,{x=>6}])   # => [1, 2, {x => 6}]
```

## instanceof ($type)

Determines that the type is a subtype of a different $type.

```perl
my $int = Aion::Type->new(name => "Int");
my $positiveInt = Aion::Type->new(name => "PositiveInt", as => $int);

$positiveInt->instanceof($int)		  # -> 1
$positiveInt->instanceof($positiveInt)  # -> 1
$positiveInt->instanceof('Int')		 # -> 1
$positiveInt->instanceof('PositiveInt') # -> 1
$int->instanceof('PositiveInt')		 # -> ""
$int->instanceof('Int')				 # -> 1
```

## make ($pkg)

It make subroutine without arguments, who return type.

```perl
BEGIN {
	Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
}

"IX" ~~ Rim	 # => 1
```

Property `init` won't use with `make`.

```perl
eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won't work in Rim
```

If subroutine make'nt, then died.

```perl
eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error
```

## make_arg ($pkg)

It make subroutine with arguments, who return type.

```perl
BEGIN {
	Aion::Type->new(name=>"Len", test => sub {
		$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
	})->make_arg(__PACKAGE__);
}

"IX" ~~ Len[2,2]	# => 1
```

If subroutine make'nt, then died.

```perl
eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error
```

## make_maybe_arg ($pkg)

It make subroutine with or without arguments, who return type.

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

If subroutine make'nt, then died.

```perl
eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error
```

## equal ($type)

Types are equal when they have the same name, the same number of arguments, parent and arguments are equal.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
my $AnotherInt = Aion::Type->new(name => "Int");
my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
my $Str = Aion::Type->new(name => "Str");

$Int->equal($Int)                     # -> 1
$Int->equal($AnotherInt)              # -> 1
$IntWithArgs->equal($AnotherIntWithArgs) # -> 1
$PositiveInt->equal($PositiveInt)     # -> 1

$Int->equal($Str)                     # -> ""
$Int->equal($IntWithArgs)             # -> ""
$IntWithArgs->equal($IntWithDifferentArgs) # -> ""
$PositiveInt->equal($Int)             # -> ""

$Int->equal("not a type")             # -> ""

my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
$PositiveInt->equal($PositiveInt2)    # -> ""

$Int->equal($PositiveInt)             # -> ""
$PositiveInt->equal($Int)             # -> ""

my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
$PositiveIntWithArgs->equal($PositiveIntWithArgs2) # -> ""
```

## nonequal ($type)

Inverse of equal.

```perl
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);

$Int->nonequal($PositiveInt) # -> 1
$Int ne $PositiveInt         # -> 1
```

## args ()

The list of arguments.

## name ()

The name of type.

## as ()

The parent type.

## message (;&message)

Getter/setter for message. Message use for generate error message.

## title (;$title)

Getter/setter for title (using for swagger).

## description (;$description)

Getter/setter for description (using for swagger).

# OPERATORS

## &{}

It make the object is callable.

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

Stringify object.

```perl
Aion::Type->new(name => "Int") . ""   # => Int

my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);

"$Enum" # => Enum['A', 'B', 'C']
```

## $a | $b

It make new type as union of `$a` and `$b`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $IntOrChar = $Int | $Char;

77   ~~ $IntOrChar # -> 1
"a"  ~~ $IntOrChar # -> 1
"ab" ~~ $IntOrChar # -> ""
```

## $a & $b

It make new type as intersection of `$a` and `$b`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $Digit = $Int & $Char;

7  ~~ $Digit # -> 1
77 ~~ $Digit # -> ""
"a" ~~ $Digit # -> ""
```

## ~ $a

It make exclude type from `$a`.

```perl
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

"a" ~~ ~$Int; # -> 1
5   ~~ ~$Int; # -> ""
```

## $a eq $b

`$a` equal `$b`.

```perl
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

$Int1 eq $Int2 # -> 1
```

## $a ne $b

`$a` not equal `$b`.

```perl
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

$Int1 ne $Int2 # -> ""
123 ne $Int2 # -> 1
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
