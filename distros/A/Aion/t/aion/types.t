use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion!aion!types/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Types is a library of validators. And it makes new validators
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types;

BEGIN {
    subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
        message { "Speak is'nt included kitty!" };
}

::is scalar do {"Kitty!" ~~ SpeakOfKitty}, scalar do{1}, '"Kitty!" ~~ SpeakOfKitty # -> 1';
::is scalar do {"abc" ~~ SpeakOfKitty}, scalar do{""}, '"abc" ~~ SpeakOfKitty 	 # -> ""';

::like scalar do {eval { SpeakOfKitty->validate("abc", "This") }; "$@"}, qr!Speak is'nt included kitty\!!, 'eval { SpeakOfKitty->validate("abc", "This") }; "$@" # ~> Speak is\'nt included kitty!';


BEGIN {
	subtype IntOrArrayRef => as (Int | ArrayRef);
}

::is scalar do {[] ~~ IntOrArrayRef}, scalar do{1}, '[] ~~ IntOrArrayRef  # -> 1';
::is scalar do {35 ~~ IntOrArrayRef}, scalar do{1}, '35 ~~ IntOrArrayRef  # -> 1';
::is scalar do {"" ~~ IntOrArrayRef}, scalar do{""}, '"" ~~ IntOrArrayRef  # -> ""';


coerce IntOrArrayRef, from Num, via { int($_ + .5) };

::is scalar do {IntOrArrayRef->coerce(5.5)}, "6", 'IntOrArrayRef->coerce(5.5) # => 6';

# 
# # DESCRIPTION
# 
# This module export subroutines:
# 
# * `subtype`, `as`, `init_where`, `where`, `awhere`, `message` — for create validators.
# * `SELF`, `ARGS`, `A`, `B`, `C`, `D`, `M`, `N` — for use in validators has arguments.
# * `coerce`, `from`, `via` — for create coerce, using for translate values from one class to other class.
# 
# Hierarhy of validators:
# 

# Any
# 	Control
# 		Union[A, B...]
# 		Intersection[A, B...]
# 		Exclude[A, B...]
# 		Option[A]
# 		Wantarray[A, S]
# 	Item
# 		Bool
# 		Enum[A...]
# 		Maybe[A]
# 		Undef
# 		Defined
# 			Value
# 				Version
# 				Str
# 					Uni
# 					Bin
# 					NonEmptyStr
# 					StartsWith
# 					EndsWith
# 					Email
# 					Tel
# 					Url
# 					Path
# 					Html
# 					StrDate
# 					StrDateTime
# 					StrMatch[qr/.../]
# 					ClassName[A]
# 					RoleName[A]
# 					Rat
# 					Num
# 						PositiveNum
# 						Int
# 							PositiveInt
# 							Nat
# 			Ref
# 				Tied`[A]
# 				LValueRef
# 				FormatRef
# 				CodeRef
# 				RegexpRef
# 				ScalarRef`[A]
# 				RefRef`[A]
# 				GlobRef`[A]
# 				ArrayRef`[A]
# 				HashRef`[H]
# 				Object`[O]
# 				Map[K, V]
# 				Tuple[A...]
# 				CycleTuple[A...]
# 				Dict[k => A, ...]
# 				RegexpLike
# 				CodeLike
# 				ArrayLike`[A]
# 					Lim[A, B?]
# 				HashLike`[A]
# 					HasProp[p...]
# 					LimKeys[A, B?]
# 			Like
# 				HasMethods[m...]
# 				Overload`[m...]
# 				InstanceOf[A...]
# 				ConsumerOf[A...]
# 				StrLike
# 					Len[A, B?]
# 				NumLike
# 					Float
# 					Double
# 					Range[from, to]
# 					Bytes[A, B?]
# 					PositiveBytes[A, B?]
# 

# 
# # SUBROUTINES
# 
# ## subtype ($name, @paraphernalia)
# 
# Make new type.
# 
done_testing; }; subtest 'subtype ($name, @paraphernalia)' => sub { 
BEGIN {
	subtype One => where { $_ == 1 } message { "Actual 1 only!" };
}

::is scalar do {1 ~~ One}, scalar do{1}, '1 ~~ One 	# -> 1';
::is scalar do {0 ~~ One}, scalar do{""}, '0 ~~ One 	# -> ""';
::like scalar do {eval { One->validate(0) }; $@}, qr!Actual 1 only\!!, 'eval { One->validate(0) }; $@ # ~> Actual 1 only!';

# 
# `where` and `message` is syntax sugar, and `subtype` can be used without them.
# 

BEGIN {
	subtype Many => (where => sub { $_ > 1 });
}

::is scalar do {2 ~~ Many}, scalar do{1}, '2 ~~ Many  # -> 1';

::like scalar do {eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@}, qr!subtype Many unused keys left: where1!, 'eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@ # ~> subtype Many unused keys left: where1';

::like scalar do {eval { subtype 'Many' }; $@}, qr!subtype Many: main::Many exists\!!, 'eval { subtype \'Many\' }; $@ # ~> subtype Many: main::Many exists!';

# 
# ## as ($parenttype)
# 
# Use with `subtype` for extended create type of `$parenttype`.
# 
# ## init_where ($code)
# 
# Initialize type with new arguments. Use with `subtype`.
# 
done_testing; }; subtest 'init_where ($code)' => sub { 
BEGIN {
	subtype 'LessThen[A]',
		init_where { Num->validate(A, "Argument LessThen[A]") }
		where { $_ < A };
}

::like scalar do {eval { LessThen["string"] }; $@}, qr!Argument LessThen\[A\]!, 'eval { LessThen["string"] }; $@  # ~> Argument LessThen\[A\]';

::is scalar do {5 ~~ LessThen[5]}, scalar do{""}, '5 ~~ LessThen[5]  # -> ""';

# 
# ## where ($code)
# 
# Set in type `$code` as test. Value for test set in `$_`.
# 
done_testing; }; subtest 'where ($code)' => sub { 
BEGIN {
	subtype 'Two',
		where { $_ == 2 };
}

::is scalar do {2 ~~ Two}, scalar do{1}, '2 ~~ Two # -> 1';
::is scalar do {3 ~~ Two}, scalar do{""}, '3 ~~ Two # -> ""';

# 
# Use with `subtype`. Need if is the required arguments.
# 

::like scalar do {eval { subtype 'Ex[A]' }; $@}, qr!subtype Ex\[A\]: needs a where!, 'eval { subtype \'Ex[A]\' }; $@  # ~> subtype Ex\[A\]: needs a where';

# 
# ## awhere ($code)
# 
# Use with `subtype`. 
# 
# If type maybe with and without arguments, then use for set test with arguments, and `where` - without.
# 
done_testing; }; subtest 'awhere ($code)' => sub { 
BEGIN {
	subtype 'GreatThen`[A]',
		where { $_ > 0 }
		awhere { $_ > A }
	;
}

::is scalar do {0 ~~ GreatThen}, scalar do{""}, '0 ~~ GreatThen    # -> ""';
::is scalar do {1 ~~ GreatThen}, scalar do{1}, '1 ~~ GreatThen    # -> 1';

::is scalar do {3 ~~ GreatThen[3]}, scalar do{""}, '3 ~~ GreatThen[3] # -> ""';
::is scalar do {4 ~~ GreatThen[3]}, scalar do{1}, '4 ~~ GreatThen[3] # -> 1';

# 
# Need if arguments is optional.
# 

::like scalar do {eval { subtype 'Ex`[A]', where {} }; $@}, qr!subtype Ex`\[A\]: needs a awhere!, 'eval { subtype \'Ex`[A]\', where {} }; $@  # ~> subtype Ex`\[A\]: needs a awhere';
::like scalar do {eval { subtype 'Ex', awhere {} }; $@}, qr!subtype Ex: awhere is excess!, 'eval { subtype \'Ex\', awhere {} }; $@  # ~> subtype Ex: awhere is excess';

BEGIN {
	subtype 'MyEnum`[A...]',
		as Str,
		awhere { $_ ~~ scalar ARGS }
	;
}

::is scalar do {"ab" ~~ MyEnum[qw/ab cd/]}, scalar do{1}, '"ab" ~~ MyEnum[qw/ab cd/] # -> 1';

# 
# ## SELF
# 
# The current type. `SELF` use in `init_where`, `where` and `awhere`.
# 
# ## ARGS
# 
# Arguments of the current type. In scalar context returns array ref on the its. And in array context returns its. Use in `init_where`, `where` and `awhere`.
# 
# ## A, B, C, D
# 
# First, second, third and fifth argument of the type.
# 
done_testing; }; subtest 'A, B, C, D' => sub { 
BEGIN {
	subtype "Seria[A,B,C,D]", where { A < B < $_ < C < D };
}

::is scalar do {2.5 ~~ Seria[1,2,3,4]}, scalar do{1}, '2.5 ~~ Seria[1,2,3,4]   # -> 1';

# 
# Use in `init_where`, `where` and `awhere`.
# 
# ## M, N
# 
# `M` and `N` is the reduction for `SELF->{M}` and `SELF->{N}`.
# 
done_testing; }; subtest 'M, N' => sub { 
BEGIN {
	subtype "BeginAndEnd[A, B]",
		init_where {
			N = qr/^${\ quotemeta A}/;
			M = qr/${\ quotemeta B}$/;
		}
		where { $_ =~ N && $_ =~ M };
}

::is scalar do {"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"]}, scalar do{1}, '"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"]   # -> 1';
::is scalar do {"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"]}, scalar do{""}, '"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"]   # -> ""';

::is scalar do {BeginAndEnd["Hi,", "!"]}, "BeginAndEnd['Hi,', '!']", 'BeginAndEnd["Hi,", "!"]   # => BeginAndEnd[\'Hi,\', \'!\']';

# 
# 
# 
# ## message ($code)
# 
# Use with `subtype` for make the message on error, if the value excluded the type. In `$code` use subroutine: `SELF` - the current type, `ARGS`, `A`, `B`, `C`, `D` - arguments of type (if is), and the testing value in `$_`. It can be stringified using `SELF->val_to_str($_)`.
# 
# ## coerce ($type, from => $from, via => $via)
# 
# It add new coerce ($via) to `$type` from `$from`-type.
# 
done_testing; }; subtest 'coerce ($type, from => $from, via => $via)' => sub { 
BEGIN {subtype Four => where {4 eq $_}}

::is scalar do {"4a" ~~ Four}, scalar do{""}, '"4a" ~~ Four	# -> ""';

::is scalar do {Four->coerce("4a")}, scalar do{"4a"}, 'Four->coerce("4a")	# -> "4a"';

coerce Four, from Str, via { 0+$_ };

::is scalar do {Four->coerce("4a")}, scalar do{4}, 'Four->coerce("4a")	# -> 4';

coerce Four, from ArrayRef, via { scalar @$_ };

::is scalar do {Four->coerce([1,2,3])}, scalar do{3}, 'Four->coerce([1,2,3])	# -> 3';
::is scalar do {Four->coerce([1,2,3]) ~~ Four}, scalar do{""}, 'Four->coerce([1,2,3]) ~~ Four	# -> ""';
::is scalar do {Four->coerce([1,2,3,4]) ~~ Four}, scalar do{1}, 'Four->coerce([1,2,3,4]) ~~ Four	# -> 1';

# 
# `coerce` throws exeptions:
# 

::like scalar do {eval {coerce Int, via1 => 1}; $@}, qr!coerce Int unused keys left: via1!, 'eval {coerce Int, via1 => 1}; $@  # ~> coerce Int unused keys left: via1';
::like scalar do {eval {coerce "x"}; $@}, qr!coerce x not Aion::Type\!!, 'eval {coerce "x"}; $@  # ~> coerce x not Aion::Type!';
::like scalar do {eval {coerce Int}; $@}, qr!coerce Int: from is'nt Aion::Type\!!, 'eval {coerce Int}; $@  # ~> coerce Int: from is\'nt Aion::Type!';
::like scalar do {eval {coerce Int, from "x"}; $@}, qr!coerce Int: from is'nt Aion::Type\!!, 'eval {coerce Int, from "x"}; $@  # ~> coerce Int: from is\'nt Aion::Type!';
::like scalar do {eval {coerce Int, from Num}; $@}, qr!coerce Int: via is not subroutine\!!, 'eval {coerce Int, from Num}; $@  # ~> coerce Int: via is not subroutine!';
::like scalar do {eval {coerce Int, (from=>Num, via=>"x")}; $@}, qr!coerce Int: via is not subroutine\!!, 'eval {coerce Int, (from=>Num, via=>"x")}; $@  # ~> coerce Int: via is not subroutine!';

# 
# Standart coerces:
# 

# Str from Undef — empty string
::is scalar do {Str->coerce(undef)}, scalar do{""}, 'Str->coerce(undef) # -> ""';

# Int from Num — rounded integer
::is scalar do {Int->coerce(2.5)}, scalar do{3}, 'Int->coerce(2.5) # -> 3';
::is scalar do {Int->coerce(-2.5)}, scalar do{-3}, 'Int->coerce(-2.5) # -> -3';

# Bool from Any — 1 or ""
::is scalar do {Bool->coerce([])}, scalar do{1}, 'Bool->coerce([])	# -> 1';
::is scalar do {Bool->coerce(0)}, scalar do{""}, 'Bool->coerce(0)		# -> ""';

# 
# ## from ($type)
# 
# Syntax sugar for `coerce`.
# 
# ## via ($code)
# 
# Syntax sugar for `coerce`.
# 
# # ATTRIBUTES
# 
# ## Isa (@signature)
# 
# Check the subroutine signature: arguments and returns.
# 
done_testing; }; subtest 'Isa (@signature)' => sub { 
sub minint($$) : Isa(Int => Int => Int) {
	my ($x, $y) = @_;
	$x < $y? $x : $y
}

::is scalar do {minint 6, 5;}, scalar do{5}, 'minint 6, 5; # -> 5';
::like scalar do {eval {minint 5.5, 2}; $@}, qr!Arguments of method `minint` must have the type Tuple\[Int, Int\]\.!, 'eval {minint 5.5, 2}; $@ # ~> Arguments of method `minint` must have the type Tuple\[Int, Int\]\.';

# 
# Attribute `Isa` is subroutine `UNIVERSAL::Isa`.
# 

sub half($) {
	my ($x) = @_;
	$x / 2
}

UNIVERSAL::Isa(
	__PACKAGE__,
	*half,
	\&half,
	undef,
	[Int => Int],
);

::is scalar do {half 4;}, scalar do{2}, 'half 4; # -> 2';
::like scalar do {eval {half 5}; $@}, qr!Return of method `half` must have the type Int. The it is 2.5!, 'eval {half 5}; $@ # ~> Return of method `half` must have the type Int. The it is 2.5';

# 
# # TYPES
# 
# ## Any
# 
# Top-level type in the hierarchy. Match all.
# 
# ## Control
# 
# Top-level type in the hierarchy constructors new types from any types.
# 
# ## Union[A, B...]
# 
# Union many types. It analog operator `$type1 | $type2`.
# 
done_testing; }; subtest 'Union[A, B...]' => sub { 
::is scalar do {33  ~~ Union[Int, Ref]}, scalar do{1}, '33  ~~ Union[Int, Ref]    # -> 1';
::is scalar do {[]  ~~ Union[Int, Ref]}, scalar do{1}, '[]  ~~ Union[Int, Ref]    # -> 1';
::is scalar do {"a" ~~ Union[Int, Ref]}, scalar do{""}, '"a" ~~ Union[Int, Ref]    # -> ""';

# 
# ## Intersection[A, B...]
# 
# Intersection many types. It analog operator `$type1 & $type2`.
# 
done_testing; }; subtest 'Intersection[A, B...]' => sub { 
::is scalar do {15 ~~ Intersection[Int, StrMatch[/5/]]}, scalar do{1}, '15 ~~ Intersection[Int, StrMatch[/5/]]    # -> 1';

# 
# ## Exclude[A, B...]
# 
# Exclude many types. It analog operator `~ $type`.
# 
done_testing; }; subtest 'Exclude[A, B...]' => sub { 
::is scalar do {-5  ~~ Exclude[PositiveInt]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt]    # -> 1';
::is scalar do {"a" ~~ Exclude[PositiveInt]}, scalar do{1}, '"a" ~~ Exclude[PositiveInt]    # -> 1';
::is scalar do {5   ~~ Exclude[PositiveInt]}, scalar do{""}, '5   ~~ Exclude[PositiveInt]    # -> ""';
::is scalar do {5.5 ~~ Exclude[PositiveInt]}, scalar do{1}, '5.5 ~~ Exclude[PositiveInt]    # -> 1';

# 
# If `Exclude` has many arguments, then this analog `~ ($type1 | $type2 ...)`.
# 

::is scalar do {-5  ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt, Enum[-2]]    # -> 1';
::is scalar do {-2  ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{""}, '-2  ~~ Exclude[PositiveInt, Enum[-2]]    # -> ""';
::is scalar do {0   ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{""}, '0   ~~ Exclude[PositiveInt, Enum[-2]]    # -> ""';

# 
# ## Option[A]
# 
# The optional keys in the `Dict`.
# 
done_testing; }; subtest 'Option[A]' => sub { 
::is scalar do {{a=>55} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{1}, '{a=>55} ~~ Dict[a=>Int, b => Option[Int]] # -> 1';
::is scalar do {{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{1}, '{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]] # -> 1';
::is scalar do {{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{""}, '{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]] # -> ""';

# 
# ## Wantarray[A, S]
# 
# if the subroutine returns different values in the context of an array and a scalar, then using type `Wantarray` with type `A` for array context and type `S` for scalar context.
# 
done_testing; }; subtest 'Wantarray[A, S]' => sub { 
sub arr : Isa(PositiveInt => Wantarray[ArrayRef[PositiveInt], PositiveInt]) {
	my ($n) = @_;
	wantarray? 1 .. $n: $n
}

my @a = arr(3);
my $s = arr(3);

::is_deeply scalar do {\@a}, scalar do {[1,2,3]}, '\@a  # --> [1,2,3]';
::is scalar do {$s}, scalar do{3}, '$s	 # -> 3';

# 
# ## Item
# 
# Top-level type in the hierarchy scalar types.
# 
# ## Bool
# 
# `1` is true. `0`, `""` or `undef` is false.
# 
done_testing; }; subtest 'Bool' => sub { 
::is scalar do {1 ~~ Bool}, scalar do{1}, '1 ~~ Bool     # -> 1';
::is scalar do {0 ~~ Bool}, scalar do{1}, '0 ~~ Bool     # -> 1';
::is scalar do {undef ~~ Bool}, scalar do{1}, 'undef ~~ Bool # -> 1';
::is scalar do {"" ~~ Bool}, scalar do{1}, '"" ~~ Bool    # -> 1';

::is scalar do {2 ~~ Bool}, scalar do{""}, '2 ~~ Bool     # -> ""';
::is scalar do {[] ~~ Bool}, scalar do{""}, '[] ~~ Bool    # -> ""';

# 
# ## Enum[A...]
# 
# Enumerate values.
# 
done_testing; }; subtest 'Enum[A...]' => sub { 
::is scalar do {3 ~~ Enum[1,2,3]}, scalar do{1}, '3 ~~ Enum[1,2,3]        	# -> 1';
::is scalar do {"cat" ~~ Enum["cat", "dog"]}, scalar do{1}, '"cat" ~~ Enum["cat", "dog"] # -> 1';
::is scalar do {4 ~~ Enum[1,2,3]}, scalar do{""}, '4 ~~ Enum[1,2,3]        	# -> ""';

# 
# ## Maybe[A]
# 
# `undef` or type in `[]`.
# 
done_testing; }; subtest 'Maybe[A]' => sub { 
::is scalar do {undef ~~ Maybe[Int]}, scalar do{1}, 'undef ~~ Maybe[Int]    # -> 1';
::is scalar do {4 ~~ Maybe[Int]}, scalar do{1}, '4 ~~ Maybe[Int]        # -> 1';
::is scalar do {"" ~~ Maybe[Int]}, scalar do{""}, '"" ~~ Maybe[Int]       # -> ""';

# 
# ## Undef
# 
# `undef` only.
# 
done_testing; }; subtest 'Undef' => sub { 
::is scalar do {undef ~~ Undef}, scalar do{1}, 'undef ~~ Undef    # -> 1';
::is scalar do {0 ~~ Undef}, scalar do{""}, '0 ~~ Undef        # -> ""';

# 
# ## Defined
# 
# All exclude `undef`.
# 
done_testing; }; subtest 'Defined' => sub { 
::is scalar do {\0 ~~ Defined}, scalar do{1}, '\0 ~~ Defined       # -> 1';
::is scalar do {undef ~~ Defined}, scalar do{""}, 'undef ~~ Defined    # -> ""';

# 
# ## Value
# 
# Defined unreference values.
# 
done_testing; }; subtest 'Value' => sub { 
::is scalar do {3 ~~ Value}, scalar do{1}, '3 ~~ Value        # -> 1';
::is scalar do {\3 ~~ Value}, scalar do{""}, '\3 ~~ Value       # -> ""';
::is scalar do {undef ~~ Value}, scalar do{""}, 'undef ~~ Value    # -> ""';

# 
# ## Len[A, B?]
# 
# Defines the length value from `A` to `B`, or from 0 to `A` if `B` is'nt present.
# 
done_testing; }; subtest 'Len[A, B?]' => sub { 
::is scalar do {"1234" ~~ Len[3]}, scalar do{""}, '"1234" ~~ Len[3]   # -> ""';
::is scalar do {"123" ~~ Len[3]}, scalar do{1}, '"123" ~~ Len[3]    # -> 1';
::is scalar do {"12" ~~ Len[3]}, scalar do{1}, '"12" ~~ Len[3]     # -> 1';
::is scalar do {"" ~~ Len[1, 2]}, scalar do{""}, '"" ~~ Len[1, 2]    # -> ""';
::is scalar do {"1" ~~ Len[1, 2]}, scalar do{1}, '"1" ~~ Len[1, 2]   # -> 1';
::is scalar do {"12" ~~ Len[1, 2]}, scalar do{1}, '"12" ~~ Len[1, 2]  # -> 1';
::is scalar do {"123" ~~ Len[1, 2]}, scalar do{""}, '"123" ~~ Len[1, 2] # -> ""';

# 
# ## Version
# 
# Perl versions.
# 
done_testing; }; subtest 'Version' => sub { 
::is scalar do {1.1.0 ~~ Version}, scalar do{1}, '1.1.0 ~~ Version    # -> 1';
::is scalar do {v1.1.0 ~~ Version}, scalar do{1}, 'v1.1.0 ~~ Version   # -> 1';
::is scalar do {v1.1 ~~ Version}, scalar do{1}, 'v1.1 ~~ Version     # -> 1';
::is scalar do {v1 ~~ Version}, scalar do{1}, 'v1 ~~ Version       # -> 1';
::is scalar do {1.1 ~~ Version}, scalar do{""}, '1.1 ~~ Version      # -> ""';
::is scalar do {"1.1.0" ~~ Version}, scalar do{""}, '"1.1.0" ~~ Version  # -> ""';

# 
# ## Str
# 
# Strings, include numbers.
# 
done_testing; }; subtest 'Str' => sub { 
::is scalar do {1.1 ~~ Str}, scalar do{1}, '1.1 ~~ Str         # -> 1';
::is scalar do {"" ~~ Str}, scalar do{1}, '"" ~~ Str          # -> 1';
::is scalar do {1.1.0 ~~ Str}, scalar do{""}, '1.1.0 ~~ Str       # -> ""';

# 
# ## Uni
# 
# Unicode strings: with utf8-flag or decode to utf8 without error.
# 
done_testing; }; subtest 'Uni' => sub { 
::is scalar do {"↭" ~~ Uni}, scalar do{1}, '"↭" ~~ Uni    # -> 1';
::is scalar do {123 ~~ Uni}, scalar do{""}, '123 ~~ Uni    # -> ""';
::is scalar do {do {no utf8; "↭" ~~ Uni}}, scalar do{1}, 'do {no utf8; "↭" ~~ Uni}    # -> 1';

# 
# ## Bin
# 
# Binary strings: without utf8-flag and octets with numbers less then 128.
# 
done_testing; }; subtest 'Bin' => sub { 
::is scalar do {123 ~~ Bin}, scalar do{1}, '123 ~~ Bin    # -> 1';
::is scalar do {"z" ~~ Bin}, scalar do{1}, '"z" ~~ Bin    # -> 1';
::is scalar do {"↭" ~~ Bin}, scalar do{""}, '"↭" ~~ Bin    # -> ""';
::is scalar do {do {no utf8; "↭" ~~ Bin }}, scalar do{""}, 'do {no utf8; "↭" ~~ Bin }   # -> ""';

# 
# ## StartsWith\[S]
# 
# The string starts with `S`.
# 
done_testing; }; subtest 'StartsWith\[S]' => sub { 
::is scalar do {"Hi, world!" ~~ StartsWith["Hi,"]}, scalar do{1}, '"Hi, world!" ~~ StartsWith["Hi,"]	# -> 1';
::is scalar do {"Hi world!" ~~ StartsWith["Hi,"]}, scalar do{""}, '"Hi world!" ~~ StartsWith["Hi,"]	# -> ""';

# 
# ## EndsWith\[S]
# 
# The string ends with `S`.
# 
done_testing; }; subtest 'EndsWith\[S]' => sub { 
::is scalar do {"Hi, world!" ~~ EndsWith["world!"]}, scalar do{1}, '"Hi, world!" ~~ EndsWith["world!"]	# -> 1';
::is scalar do {"Hi, world" ~~ EndsWith["world!"]}, scalar do{""}, '"Hi, world" ~~ EndsWith["world!"]	# -> ""';

# 
# ## NonEmptyStr
# 
# String with one or many non-space characters.
# 
done_testing; }; subtest 'NonEmptyStr' => sub { 
::is scalar do {" " ~~ NonEmptyStr}, scalar do{""}, '" " ~~ NonEmptyStr        # -> ""';
::is scalar do {" S " ~~ NonEmptyStr}, scalar do{1}, '" S " ~~ NonEmptyStr      # -> 1';
::is scalar do {" S " ~~ (NonEmptyStr & Len[2])}, scalar do{""}, '" S " ~~ (NonEmptyStr & Len[2])   # -> ""';

# 
# ## Email
# 
# Strings with `@`.
# 
done_testing; }; subtest 'Email' => sub { 
::is scalar do {'@' ~~ Email}, scalar do{1}, '\'@\' ~~ Email      # -> 1';
::is scalar do {'a@a.a' ~~ Email}, scalar do{1}, '\'a@a.a\' ~~ Email  # -> 1';
::is scalar do {'a.a' ~~ Email}, scalar do{""}, '\'a.a\' ~~ Email    # -> ""';

# 
# ## Tel
# 
# Format phones is plus sign and seven or great digits.
# 
done_testing; }; subtest 'Tel' => sub { 
::is scalar do {"+1234567" ~~ Tel}, scalar do{1}, '"+1234567" ~~ Tel    # -> 1';
::is scalar do {"+1234568" ~~ Tel}, scalar do{1}, '"+1234568" ~~ Tel    # -> 1';
::is scalar do {"+ 1234567" ~~ Tel}, scalar do{""}, '"+ 1234567" ~~ Tel    # -> ""';
::is scalar do {"+1234567 " ~~ Tel}, scalar do{""}, '"+1234567 " ~~ Tel    # -> ""';

# 
# ## Url
# 
# Web urls is string with prefix http:// or https://.
# 
done_testing; }; subtest 'Url' => sub { 
::is scalar do {"http://" ~~ Url}, scalar do{1}, '"http://" ~~ Url    # -> 1';
::is scalar do {"http:/" ~~ Url}, scalar do{""}, '"http:/" ~~ Url    # -> ""';

# 
# ## Path
# 
# The paths starts with a slash.
# 
done_testing; }; subtest 'Path' => sub { 
::is scalar do {"/" ~~ Path}, scalar do{1}, '"/" ~~ Path     # -> 1';
::is scalar do {"/a/b" ~~ Path}, scalar do{1}, '"/a/b" ~~ Path  # -> 1';
::is scalar do {"a/b" ~~ Path}, scalar do{""}, '"a/b" ~~ Path   # -> ""';

# 
# ## Html
# 
# The html starts with a `<!doctype` or `<html`.
# 
done_testing; }; subtest 'Html' => sub { 
::is scalar do {"<HTML" ~~ Html}, scalar do{1}, '"<HTML" ~~ Html            # -> 1';
::is scalar do {" <html" ~~ Html}, scalar do{1}, '" <html" ~~ Html           # -> 1';
::is scalar do {" <!doctype html>" ~~ Html}, scalar do{1}, '" <!doctype html>" ~~ Html # -> 1';
::is scalar do {" <html1>" ~~ Html}, scalar do{""}, '" <html1>" ~~ Html         # -> ""';

# 
# ## StrDate
# 
# The date is format `yyyy-mm-dd`.
# 
done_testing; }; subtest 'StrDate' => sub { 
::is scalar do {"2001-01-12" ~~ StrDate}, scalar do{1}, '"2001-01-12" ~~ StrDate    # -> 1';
::is scalar do {"01-01-01" ~~ StrDate}, scalar do{""}, '"01-01-01" ~~ StrDate    # -> ""';

# 
# ## StrDateTime
# 
# The dateTime is format `yyyy-mm-dd HH:MM:SS`.
# 
done_testing; }; subtest 'StrDateTime' => sub { 
::is scalar do {"2012-12-01 00:00:00" ~~ StrDateTime}, scalar do{1}, '"2012-12-01 00:00:00" ~~ StrDateTime     # -> 1';
::is scalar do {"2012-12-01 00:00:00 " ~~ StrDateTime}, scalar do{""}, '"2012-12-01 00:00:00 " ~~ StrDateTime    # -> ""';

# 
# ## StrMatch[qr/.../]
# 
# Match value with regular expression.
# 
done_testing; }; subtest 'StrMatch[qr/.../]' => sub { 
::is scalar do {' abc ' ~~ StrMatch[qr/abc/]}, scalar do{1}, '\' abc \' ~~ StrMatch[qr/abc/]    # -> 1';
::is scalar do {' abbc ' ~~ StrMatch[qr/abc/]}, scalar do{""}, '\' abbc \' ~~ StrMatch[qr/abc/]   # -> ""';

# 
# ## ClassName
# 
# Classname is the package with method `new`.
# 
done_testing; }; subtest 'ClassName' => sub { 
::is scalar do {'Aion::Type' ~~ ClassName}, scalar do{1}, '\'Aion::Type\' ~~ ClassName     # -> 1';
::is scalar do {'Aion::Types' ~~ ClassName}, scalar do{""}, '\'Aion::Types\' ~~ ClassName    # -> ""';

# 
# ## RoleName
# 
# Rolename is the package with subroutine `requires`.
# 
done_testing; }; subtest 'RoleName' => sub { 
package ExRole {
	sub requires {}
}

::is scalar do {'ExRole' ~~ RoleName}, scalar do{1}, '\'ExRole\' ~~ RoleName    	# -> 1';
::is scalar do {'Aion::Type' ~~ RoleName}, scalar do{""}, '\'Aion::Type\' ~~ RoleName    # -> ""';

# 
# ## Rat
# 
# Rational numbers.
# 
done_testing; }; subtest 'Rat' => sub { 
::is scalar do {"6/7" ~~ Rat}, scalar do{1}, '"6/7" ~~ Rat     # -> 1';
::is scalar do {"-6/7" ~~ Rat}, scalar do{1}, '"-6/7" ~~ Rat    # -> 1';
::is scalar do {6 ~~ Rat}, scalar do{1}, '6 ~~ Rat         # -> 1';
::is scalar do {"inf" ~~ Rat}, scalar do{1}, '"inf" ~~ Rat     # -> 1';
::is scalar do {"+Inf" ~~ Rat}, scalar do{1}, '"+Inf" ~~ Rat    # -> 1';
::is scalar do {"NaN" ~~ Rat}, scalar do{1}, '"NaN" ~~ Rat     # -> 1';
::is scalar do {"-nan" ~~ Rat}, scalar do{1}, '"-nan" ~~ Rat    # -> 1';
::is scalar do {6.5 ~~ Rat}, scalar do{1}, '6.5 ~~ Rat       # -> 1';
::is scalar do {"6.5 " ~~ Rat}, scalar do{''}, '"6.5 " ~~ Rat    # -> \'\'';

# 
# ## Num
# 
# The numbers.
# 
done_testing; }; subtest 'Num' => sub { 
::is scalar do {-6.5 ~~ Num}, scalar do{1}, '-6.5 ~~ Num      # -> 1';
::is scalar do {6.5e-7 ~~ Num}, scalar do{1}, '6.5e-7 ~~ Num    # -> 1';
::is scalar do {"6.5 " ~~ Num}, scalar do{""}, '"6.5 " ~~ Num    # -> ""';

# 
# ## PositiveNum
# 
# The positive numbers.
# 
done_testing; }; subtest 'PositiveNum' => sub { 
::is scalar do {0 ~~ PositiveNum}, scalar do{1}, '0 ~~ PositiveNum     # -> 1';
::is scalar do {0.1 ~~ PositiveNum}, scalar do{1}, '0.1 ~~ PositiveNum   # -> 1';
::is scalar do {-0.1 ~~ PositiveNum}, scalar do{""}, '-0.1 ~~ PositiveNum  # -> ""';
::is scalar do {-0 ~~ PositiveNum}, scalar do{1}, '-0 ~~ PositiveNum    # -> 1';

# 
# ## Float
# 
# The machine float number is 4 bytes.
# 
done_testing; }; subtest 'Float' => sub { 
::is scalar do {-4.8 ~~ Float}, scalar do{1}, '-4.8 ~~ Float    				# -> 1';
::is scalar do {-3.402823466E+38 ~~ Float}, scalar do{1}, '-3.402823466E+38 ~~ Float    	# -> 1';
::is scalar do {+3.402823466E+38 ~~ Float}, scalar do{1}, '+3.402823466E+38 ~~ Float    	# -> 1';
::is scalar do {-3.402823467E+38 ~~ Float}, scalar do{""}, '-3.402823467E+38 ~~ Float       # -> ""';

# 
# ## Double
# 
# The machine float number is 8 bytes.
# 
done_testing; }; subtest 'Double' => sub { 
::is scalar do {-4.8 ~~ Double}, scalar do{1}, '-4.8 ~~ Double    					# -> 1';
::is scalar do {-1.7976931348623158e+308 ~~ Double}, scalar do{1}, '-1.7976931348623158e+308 ~~ Double  # -> 1';
::is scalar do {+1.7976931348623158e+308 ~~ Double}, scalar do{1}, '+1.7976931348623158e+308 ~~ Double  # -> 1';
::is scalar do {-1.7976931348623159e+308 ~~ Double}, scalar do{""}, '-1.7976931348623159e+308 ~~ Double # -> ""';

# 
# ## Range[from, to]
# 
# Numbers between `from` and `to`.
# 
done_testing; }; subtest 'Range[from, to]' => sub { 
::is scalar do {1 ~~ Range[1, 3]}, scalar do{1}, '1 ~~ Range[1, 3]    # -> 1';
::is scalar do {2.5 ~~ Range[1, 3]}, scalar do{1}, '2.5 ~~ Range[1, 3]  # -> 1';
::is scalar do {3 ~~ Range[1, 3]}, scalar do{1}, '3 ~~ Range[1, 3]    # -> 1';
::is scalar do {3.1 ~~ Range[1, 3]}, scalar do{""}, '3.1 ~~ Range[1, 3]  # -> ""';
::is scalar do {0.9 ~~ Range[1, 3]}, scalar do{""}, '0.9 ~~ Range[1, 3]  # -> ""';

# 
# ## Int
# 
# Integers.
# 
done_testing; }; subtest 'Int' => sub { 
::is scalar do {123 ~~ Int}, scalar do{1}, '123 ~~ Int    # -> 1';
::is scalar do {-12 ~~ Int}, scalar do{1}, '-12 ~~ Int    # -> 1';
::is scalar do {5.5 ~~ Int}, scalar do{""}, '5.5 ~~ Int    # -> ""';

# 
# ## Bytes[N]
# 
# `N` - the number of bytes for limit.
# 
done_testing; }; subtest 'Bytes[N]' => sub { 
::is scalar do {-129 ~~ Bytes[1]}, scalar do{""}, '-129 ~~ Bytes[1]    # -> ""';
::is scalar do {-128 ~~ Bytes[1]}, scalar do{1}, '-128 ~~ Bytes[1]    # -> 1';
::is scalar do {127 ~~ Bytes[1]}, scalar do{1}, '127 ~~ Bytes[1]     # -> 1';
::is scalar do {128 ~~ Bytes[1]}, scalar do{""}, '128 ~~ Bytes[1]     # -> ""';

# 2 bits power of (8 bits * 8 bytes - 1)
my $N = 1 << (8*8-1);
::is scalar do {(-$N-1) ~~ Bytes[8]}, scalar do{""}, '(-$N-1) ~~ Bytes[8]   # -> ""';
::is scalar do {(-$N) ~~ Bytes[8]}, scalar do{1}, '(-$N) ~~ Bytes[8]     # -> 1';
::is scalar do {($N-1) ~~ Bytes[8]}, scalar do{1}, '($N-1) ~~ Bytes[8]  	# -> 1';
::is scalar do {$N ~~ Bytes[8]}, scalar do{""}, '$N ~~ Bytes[8]      	# -> ""';

require Math::BigInt;

my $N17 = 1 << (8*Math::BigInt->new(17) - 1);

::is scalar do {((-$N17-1) . "") ~~ Bytes[17]}, scalar do{""}, '((-$N17-1) . "") ~~ Bytes[17]  # -> ""';
::is scalar do {(-$N17 . "") ~~ Bytes[17]}, scalar do{1}, '(-$N17 . "") ~~ Bytes[17]  # -> 1';
::is scalar do {(($N17-1) . "") ~~ Bytes[17]}, scalar do{1}, '(($N17-1) . "") ~~ Bytes[17]  # -> 1';
::is scalar do {($N17 . "") ~~ Bytes[17]}, scalar do{""}, '($N17 . "") ~~ Bytes[17]  # -> ""';

# 
# ## PositiveInt
# 
# Positive integers.
# 
done_testing; }; subtest 'PositiveInt' => sub { 
::is scalar do {+0 ~~ PositiveInt}, scalar do{1}, '+0 ~~ PositiveInt    # -> 1';
::is scalar do {-0 ~~ PositiveInt}, scalar do{1}, '-0 ~~ PositiveInt    # -> 1';
::is scalar do {55 ~~ PositiveInt}, scalar do{1}, '55 ~~ PositiveInt    # -> 1';
::is scalar do {-1 ~~ PositiveInt}, scalar do{""}, '-1 ~~ PositiveInt    # -> ""';

# 
# ## PositiveBytes[N]
# 
# `N` - the number of bytes for limit.
# 
done_testing; }; subtest 'PositiveBytes[N]' => sub { 
::is scalar do {-1 ~~ PositiveBytes[1]}, scalar do{""}, '-1 ~~ PositiveBytes[1]    # -> ""';
::is scalar do {0 ~~ PositiveBytes[1]}, scalar do{1}, '0 ~~ PositiveBytes[1]    # -> 1';
::is scalar do {255 ~~ PositiveBytes[1]}, scalar do{1}, '255 ~~ PositiveBytes[1]    # -> 1';
::is scalar do {256 ~~ PositiveBytes[1]}, scalar do{""}, '256 ~~ PositiveBytes[1]    # -> ""';

::is scalar do {-1 ~~ PositiveBytes[8]}, scalar do{""}, '-1 ~~ PositiveBytes[8] # -> ""';
::is scalar do {1.01 ~~ PositiveBytes[8]}, scalar do{""}, '1.01 ~~ PositiveBytes[8] # -> ""';
::is scalar do {0 ~~ PositiveBytes[8]}, scalar do{1}, '0 ~~ PositiveBytes[8] # -> 1';

my $N8 = 2 ** (8*Math::BigInt->new(8)) - 1;

::is scalar do {$N8 . "" ~~ PositiveBytes[8]}, scalar do{1}, '$N8 . "" ~~ PositiveBytes[8] # -> 1';
::is scalar do {($N8+1) . "" ~~ PositiveBytes[8]}, scalar do{""}, '($N8+1) . "" ~~ PositiveBytes[8] # -> ""';

::is scalar do {-1 ~~ PositiveBytes[17]}, scalar do{""}, '-1 ~~ PositiveBytes[17] # -> ""';
::is scalar do {0 ~~ PositiveBytes[17]}, scalar do{1}, '0 ~~ PositiveBytes[17] # -> 1';

# 
# ## Nat
# 
# Integers 1+.
# 
done_testing; }; subtest 'Nat' => sub { 
::is scalar do {0 ~~ Nat}, scalar do{""}, '0 ~~ Nat    # -> ""';
::is scalar do {1 ~~ Nat}, scalar do{1}, '1 ~~ Nat    # -> 1';

# 
# ## Ref
# 
# The value is reference.
# 
done_testing; }; subtest 'Ref' => sub { 
::is scalar do {\1 ~~ Ref}, scalar do{1}, '\1 ~~ Ref    # -> 1';
::is scalar do {1 ~~ Ref}, scalar do{""}, '1 ~~ Ref     # -> ""';

# 
# ## Tied`[A]
# 
# The reference on the tied variable.
# 
done_testing; }; subtest 'Tied`[A]' => sub { 
package TiedHash { sub TIEHASH { bless {@_}, shift } }
package TiedArray { sub TIEARRAY { bless {@_}, shift } }
package TiedScalar { sub TIESCALAR { bless {@_}, shift } }

tie my %a, "TiedHash";
tie my @a, "TiedArray";
tie my $a, "TiedScalar";
my %b; my @b; my $b;

::is scalar do {\%a ~~ Tied}, scalar do{1}, '\%a ~~ Tied    # -> 1';
::is scalar do {\@a ~~ Tied}, scalar do{1}, '\@a ~~ Tied    # -> 1';
::is scalar do {\$a ~~ Tied}, scalar do{1}, '\$a ~~ Tied    # -> 1';

::is scalar do {\%b ~~ Tied}, scalar do{""}, '\%b ~~ Tied    # -> ""';
::is scalar do {\@b ~~ Tied}, scalar do{""}, '\@b ~~ Tied    # -> ""';
::is scalar do {\$b ~~ Tied}, scalar do{""}, '\$b ~~ Tied    # -> ""';
::is scalar do {\\$b ~~ Tied}, scalar do{""}, '\\$b ~~ Tied    # -> ""';

::is scalar do {ref tied %a}, "TiedHash", 'ref tied %a  # => TiedHash';
::is scalar do {ref tied %{\%a}}, "TiedHash", 'ref tied %{\%a}  # => TiedHash';

::is scalar do {\%a ~~ Tied["TiedHash"]}, scalar do{1}, '\%a ~~ Tied["TiedHash"]     # -> 1';
::is scalar do {\@a ~~ Tied["TiedArray"]}, scalar do{1}, '\@a ~~ Tied["TiedArray"]    # -> 1';
::is scalar do {\$a ~~ Tied["TiedScalar"]}, scalar do{1}, '\$a ~~ Tied["TiedScalar"]   # -> 1';

::is scalar do {\%a ~~ Tied["TiedArray"]}, scalar do{""}, '\%a ~~ Tied["TiedArray"]    # -> ""';
::is scalar do {\@a ~~ Tied["TiedScalar"]}, scalar do{""}, '\@a ~~ Tied["TiedScalar"]   # -> ""';
::is scalar do {\$a ~~ Tied["TiedHash"]}, scalar do{""}, '\$a ~~ Tied["TiedHash"]     # -> ""';
::is scalar do {\\$a ~~ Tied["TiedScalar"]}, scalar do{""}, '\\$a ~~ Tied["TiedScalar"]     # -> ""';



# 
# ## LValueRef
# 
# The function allows assignment.
# 
done_testing; }; subtest 'LValueRef' => sub { 
::is scalar do {ref \substr("abc", 1, 2)}, "LVALUE", 'ref \substr("abc", 1, 2) # => LVALUE';
::is scalar do {ref \vec(42, 1, 2)}, "LVALUE", 'ref \vec(42, 1, 2) # => LVALUE';

::is scalar do {\substr("abc", 1, 2) ~~ LValueRef}, scalar do{1}, '\substr("abc", 1, 2) ~~ LValueRef # -> 1';
::is scalar do {\vec(42, 1, 2) ~~ LValueRef}, scalar do{1}, '\vec(42, 1, 2) ~~ LValueRef # -> 1';

# 
# But it with `: lvalue` do'nt working.
# 

sub abc: lvalue { $_ }

abc() = 12;
::is scalar do {$_}, "12", '$_ # => 12';
::is scalar do {ref \abc()}, "SCALAR", 'ref \abc()  # => SCALAR';
::is scalar do {\abc() ~~ LValueRef}, scalar do{""}, '\abc() ~~ LValueRef	# -> ""';


package As {
	sub x : lvalue {
		shift->{x};
	}
}

my $x = bless {}, "As";
$x->x = 10;

::is scalar do {$x->x}, "10", '$x->x # => 10';
::is_deeply scalar do {$x}, scalar do {bless {x=>10}, "As"}, '$x    # --> bless {x=>10}, "As"';

::is scalar do {ref \$x->x}, "SCALAR", 'ref \$x->x 			# => SCALAR';
::is scalar do {\$x->x ~~ LValueRef}, scalar do{""}, '\$x->x ~~ LValueRef # -> ""';

# 
# And on the end:
# 

::is scalar do {\1 ~~ LValueRef}, scalar do{""}, '\1 ~~ LValueRef	# -> ""';

my $x = "abc";
substr($x, 1, 1) = 10;

::is scalar do {$x}, "a10c", '$x # => a10c';

::is scalar do {LValueRef->include(\substr($x, 1, 1))}, "1", 'LValueRef->include(\substr($x, 1, 1))	# => 1';

# 
# ## FormatRef
# 
# The format.
# 
done_testing; }; subtest 'FormatRef' => sub { 
format EXAMPLE_FMT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

::is scalar do {*EXAMPLE_FMT{FORMAT} ~~ FormatRef}, scalar do{1}, '*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1';
::is scalar do {\1 ~~ FormatRef}, scalar do{""}, '\1 ~~ FormatRef    			# -> ""';

# 
# ## CodeRef
# 
# Subroutine.
# 
done_testing; }; subtest 'CodeRef' => sub { 
::is scalar do {sub {} ~~ CodeRef}, scalar do{1}, 'sub {} ~~ CodeRef    # -> 1';
::is scalar do {\1 ~~ CodeRef}, scalar do{""}, '\1 ~~ CodeRef        # -> ""';

# 
# ## RegexpRef
# 
# The regular expression.
# 
done_testing; }; subtest 'RegexpRef' => sub { 
::is scalar do {qr// ~~ RegexpRef}, scalar do{1}, 'qr// ~~ RegexpRef    # -> 1';
::is scalar do {\1 ~~ RegexpRef}, scalar do{""}, '\1 ~~ RegexpRef    	 # -> ""';

# 
# ## ScalarRef`[A]
# 
# The scalar.
# 
done_testing; }; subtest 'ScalarRef`[A]' => sub { 
::is scalar do {\12 ~~ ScalarRef}, scalar do{1}, '\12 ~~ ScalarRef     		# -> 1';
::is scalar do {\\12 ~~ ScalarRef}, scalar do{""}, '\\12 ~~ ScalarRef    		# -> ""';
::is scalar do {\-1.2 ~~ ScalarRef[Num]}, scalar do{1}, '\-1.2 ~~ ScalarRef[Num]     # -> 1';
::is scalar do {\\-1.2 ~~ ScalarRef[Num]}, scalar do{""}, '\\-1.2 ~~ ScalarRef[Num]     # -> ""';

# 
# ## RefRef`[A]
# 
# The ref as ref.
# 
done_testing; }; subtest 'RefRef`[A]' => sub { 
::is scalar do {\\1 ~~ RefRef}, scalar do{1}, '\\1 ~~ RefRef    # -> 1';
::is scalar do {\1 ~~ RefRef}, scalar do{""}, '\1 ~~ RefRef     # -> ""';
::is scalar do {\\1.3 ~~ RefRef[ScalarRef[Num]]}, scalar do{1}, '\\1.3 ~~ RefRef[ScalarRef[Num]]    # -> 1';
::is scalar do {\1.3 ~~ RefRef[ScalarRef[Num]]}, scalar do{""}, '\1.3 ~~ RefRef[ScalarRef[Num]]    # -> ""';

# 
# ## GlobRef
# 
# The global.
# 
done_testing; }; subtest 'GlobRef' => sub { 
::is scalar do {\*A::a ~~ GlobRef}, scalar do{1}, '\*A::a ~~ GlobRef    # -> 1';
::is scalar do {*A::a ~~ GlobRef}, scalar do{""}, '*A::a ~~ GlobRef     # -> ""';

# 
# ## ArrayRef`[A]
# 
# The arrays.
# 
done_testing; }; subtest 'ArrayRef`[A]' => sub { 
::is scalar do {[] ~~ ArrayRef}, scalar do{1}, '[] ~~ ArrayRef    # -> 1';
::is scalar do {{} ~~ ArrayRef}, scalar do{""}, '{} ~~ ArrayRef    # -> ""';
::is scalar do {[] ~~ ArrayRef[Num]}, scalar do{1}, '[] ~~ ArrayRef[Num]    # -> 1';
::is scalar do {{} ~~ ArrayRef[Num]}, scalar do{''}, '{} ~~ ArrayRef[Num]    # -> \'\'';
::is scalar do {[1, 1.1] ~~ ArrayRef[Num]}, scalar do{1}, '[1, 1.1] ~~ ArrayRef[Num]    # -> 1';
::is scalar do {[1, undef] ~~ ArrayRef[Num]}, scalar do{""}, '[1, undef] ~~ ArrayRef[Num]    # -> ""';

# 
# ## Lim[A, B?]
# 
# Limit arrays from `A` to `B`, or from 0 to `A`, if `B` is'nt present.
# 
done_testing; }; subtest 'Lim[A, B?]' => sub { 
::is scalar do {[] ~~ Lim[5]}, scalar do{1}, '[] ~~ Lim[5] # -> 1';
::is scalar do {[1..5] ~~ Lim[5]}, scalar do{1}, '[1..5] ~~ Lim[5] # -> 1';
::is scalar do {[1..6] ~~ Lim[5]}, scalar do{""}, '[1..6] ~~ Lim[5] # -> ""';

::is scalar do {[1..5] ~~ Lim[1,5]}, scalar do{1}, '[1..5] ~~ Lim[1,5] # -> 1';
::is scalar do {[1..6] ~~ Lim[1,5]}, scalar do{""}, '[1..6] ~~ Lim[1,5] # -> ""';

::is scalar do {[1] ~~ Lim[1,5]}, scalar do{1}, '[1] ~~ Lim[1,5] # -> 1';
::is scalar do {[] ~~ Lim[1,5]}, scalar do{""}, '[] ~~ Lim[1,5] # -> ""';

# 
# ## HashRef`[H]
# 
# The hashes.
# 
done_testing; }; subtest 'HashRef`[H]' => sub { 
::is scalar do {{} ~~ HashRef}, scalar do{1}, '{} ~~ HashRef    # -> 1';
::is scalar do {\1 ~~ HashRef}, scalar do{""}, '\1 ~~ HashRef    # -> ""';

::is scalar do {[]  ~~ HashRef[Int]}, scalar do{""}, '[]  ~~ HashRef[Int]    # -> ""';
::is scalar do {{x=>1, y=>2}  ~~ HashRef[Int]}, scalar do{1}, '{x=>1, y=>2}  ~~ HashRef[Int]    # -> 1';
::is scalar do {{x=>1, y=>""} ~~ HashRef[Int]}, scalar do{""}, '{x=>1, y=>""} ~~ HashRef[Int]    # -> ""';

# 
# ## Object`[O]
# 
# The blessed values.
# 
done_testing; }; subtest 'Object`[O]' => sub { 
::is scalar do {bless(\(my $val=10), "A1") ~~ Object}, scalar do{1}, 'bless(\(my $val=10), "A1") ~~ Object    # -> 1';
::is scalar do {\(my $val=10) ~~ Object}, scalar do{""}, '\(my $val=10) ~~ Object			    	# -> ""';

::is scalar do {bless(\(my $val=10), "A1") ~~ Object["A1"]}, scalar do{1}, 'bless(\(my $val=10), "A1") ~~ Object["A1"]   # -> 1';
::is scalar do {bless(\(my $val=10), "A1") ~~ Object["B1"]}, scalar do{""}, 'bless(\(my $val=10), "A1") ~~ Object["B1"]   # -> ""';

# 
# ## Map[K, V]
# 
# As `HashRef`, but has type for keys also.
# 
done_testing; }; subtest 'Map[K, V]' => sub { 
::is scalar do {{} ~~ Map[Int, Int]}, scalar do{1}, '{} ~~ Map[Int, Int]    		 # -> 1';
::is scalar do {{5 => 3} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3} ~~ Map[Int, Int]    # -> 1';
::is scalar do {+{5.5 => 3} ~~ Map[Int, Int]}, scalar do{""}, '+{5.5 => 3} ~~ Map[Int, Int] # -> ""';
::is scalar do {{5 => 3.3} ~~ Map[Int, Int]}, scalar do{""}, '{5 => 3.3} ~~ Map[Int, Int]  # -> ""';
::is scalar do {{5 => 3, 6 => 7} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3, 6 => 7} ~~ Map[Int, Int]  # -> 1';

# 
# ## Tuple[A...]
# 
# The tuple.
# 
done_testing; }; subtest 'Tuple[A...]' => sub { 
::is scalar do {["a", 12] ~~ Tuple[Str, Int]}, scalar do{1}, '["a", 12] ~~ Tuple[Str, Int]    # -> 1';
::is scalar do {["a", 12, 1] ~~ Tuple[Str, Int]}, scalar do{""}, '["a", 12, 1] ~~ Tuple[Str, Int]    # -> ""';
::is scalar do {["a", 12.1] ~~ Tuple[Str, Int]}, scalar do{""}, '["a", 12.1] ~~ Tuple[Str, Int]    # -> ""';

# 
# ## CycleTuple[A...]
# 
# The tuple one or more times.
# 
done_testing; }; subtest 'CycleTuple[A...]' => sub { 
::is scalar do {["a", -5] ~~ CycleTuple[Str, Int]}, scalar do{1}, '["a", -5] ~~ CycleTuple[Str, Int]    # -> 1';
::is scalar do {["a", -5, "x"] ~~ CycleTuple[Str, Int]}, scalar do{""}, '["a", -5, "x"] ~~ CycleTuple[Str, Int]    # -> ""';
::is scalar do {["a", -5, "x", -6] ~~ CycleTuple[Str, Int]}, scalar do{1}, '["a", -5, "x", -6] ~~ CycleTuple[Str, Int]    # -> 1';
::is scalar do {["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]}, scalar do{""}, '["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]    # -> ""';

# 
# ## Dict[k => A, ...]
# 
# The dictionary.
# 
done_testing; }; subtest 'Dict[k => A, ...]' => sub { 
::is scalar do {{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]}, scalar do{1}, '{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]    # -> 1';

::is scalar do {{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]}, scalar do{""}, '{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]    # -> ""';
::is scalar do {{a => -1.6} ~~ Dict[a => Num, b => Str]}, scalar do{""}, '{a => -1.6} ~~ Dict[a => Num, b => Str]    # -> ""';

::is scalar do {{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]}, scalar do{1}, '{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]    # -> 1';

# 
# ## HasProp[p...]
# 
# The hash has the properties.
# 
done_testing; }; subtest 'HasProp[p...]' => sub { 
::is scalar do {[0, 1] ~~ HasProp[qw/0 1/]}, scalar do{""}, '[0, 1] ~~ HasProp[qw/0 1/]	# -> ""';

::is scalar do {{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]    # -> 1';
::is scalar do {{a => 1, b => 2} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2} ~~ HasProp[qw/a b/]    # -> 1';
::is scalar do {{a => 1, c => 3} ~~ HasProp[qw/a b/]}, scalar do{""}, '{a => 1, c => 3} ~~ HasProp[qw/a b/]    # -> ""';

::is scalar do {bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]}, scalar do{1}, 'bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]    # -> 1';

# 
# ## Like
# 
# The object or string.
# 
done_testing; }; subtest 'Like' => sub { 
::is scalar do {"" ~~ Like}, scalar do{1}, '"" ~~ Like    	# -> 1';
::is scalar do {1 ~~ Like}, scalar do{1}, '1 ~~ Like    	# -> 1';
::is scalar do {bless({}, "A") ~~ Like}, scalar do{1}, 'bless({}, "A") ~~ Like    # -> 1';
::is scalar do {bless([], "A") ~~ Like}, scalar do{1}, 'bless([], "A") ~~ Like    # -> 1';
::is scalar do {bless(\(my $str = ""), "A") ~~ Like}, scalar do{1}, 'bless(\(my $str = ""), "A") ~~ Like    # -> 1';
::is scalar do {\1 ~~ Like}, scalar do{""}, '\1 ~~ Like    	# -> ""';

# 
# ## HasMethods[m...]
# 
# The object or the class has the methods.
# 
done_testing; }; subtest 'HasMethods[m...]' => sub { 
package HasMethodsExample {
	sub x1 {}
	sub x2 {}
}

::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]    		# -> 1';
::is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1';
::is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]    # -> 1';
::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x3/]    			# -> ""';
::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]    		# -> ""';
::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]    		# -> ""';

# 
# ## Overload`[op...]
# 
# The object or the class is overloaded.
# 
done_testing; }; subtest 'Overload`[op...]' => sub { 
package OverloadExample {
	use overload '""' => sub { "abc" };
}

::is scalar do {"OverloadExample" ~~ Overload}, scalar do{1}, '"OverloadExample" ~~ Overload    # -> 1';
::is scalar do {bless({}, "OverloadExample") ~~ Overload}, scalar do{1}, 'bless({}, "OverloadExample") ~~ Overload    # -> 1';
::is scalar do {"A" ~~ Overload}, scalar do{""}, '"A" ~~ Overload    				# -> ""';
::is scalar do {bless({}, "A") ~~ Overload}, scalar do{""}, 'bless({}, "A") ~~ Overload    	# -> ""';

# 
# And it has the operators if arguments are specified.
# 

::is scalar do {"OverloadExample" ~~ Overload['""']}, scalar do{1}, '"OverloadExample" ~~ Overload[\'""\']   # -> 1';
::is scalar do {"OverloadExample" ~~ Overload['|']}, scalar do{""}, '"OverloadExample" ~~ Overload[\'|\']    # -> ""';

# 
# ## InstanceOf[A...]
# 
# The class or the object inherits the list of classes.
# 
done_testing; }; subtest 'InstanceOf[A...]' => sub { 
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


::is scalar do {"Tiger" ~~ InstanceOf['Animal', 'Cat']}, scalar do{1}, '"Tiger" ~~ InstanceOf[\'Animal\', \'Cat\']  # -> 1';
::is scalar do {"Tiger" ~~ InstanceOf['Tiger']}, scalar do{1}, '"Tiger" ~~ InstanceOf[\'Tiger\']    		# -> 1';
::is scalar do {"Tiger" ~~ InstanceOf['Cat', 'Dog']}, scalar do{""}, '"Tiger" ~~ InstanceOf[\'Cat\', \'Dog\']    	# -> ""';

# 
# ## ConsumerOf[A...]
# 
# The class or the object has the roles.
# 
# The presence of the role is checked by the `does` method.
# 
done_testing; }; subtest 'ConsumerOf[A...]' => sub { 
package NoneExample {}
package RoleExample { sub does { $_[1] ~~ [qw/Role1 Role2/] } }

::is scalar do {'RoleExample' ~~ ConsumerOf[qw/Role1/]}, scalar do{1}, '\'RoleExample\' ~~ ConsumerOf[qw/Role1/] # -> 1';
::is scalar do {'RoleExample' ~~ ConsumerOf[qw/Role2 Role1/]}, scalar do{1}, '\'RoleExample\' ~~ ConsumerOf[qw/Role2 Role1/] # -> 1';
::is scalar do {bless({}, 'RoleExample') ~~ ConsumerOf[qw/Role3 Role2 Role1/]}, scalar do{""}, 'bless({}, \'RoleExample\') ~~ ConsumerOf[qw/Role3 Role2 Role1/] # -> ""';

::is scalar do {'NoneExample' ~~ ConsumerOf[qw/Role1/]}, scalar do{""}, '\'NoneExample\' ~~ ConsumerOf[qw/Role1/]	# -> ""';

# 
# ## StrLike
# 
# String or object with overloaded operator `""`.
# 
done_testing; }; subtest 'StrLike' => sub { 
::is scalar do {"" ~~ StrLike}, scalar do{1}, '"" ~~ StrLike    							# -> 1';

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

::is scalar do {bless({}, "StrLikeExample") ~~ StrLike}, scalar do{1}, 'bless({}, "StrLikeExample") ~~ StrLike    	# -> 1';

::is scalar do {{} ~~ StrLike}, scalar do{""}, '{} ~~ StrLike    							# -> ""';

# 
# ## RegexpLike
# 
# The regular expression or the object with overloaded operator `qr`.
# 
done_testing; }; subtest 'RegexpLike' => sub { 
::is scalar do {ref(qr//)}, "Regexp", 'ref(qr//)  # => Regexp';
::is scalar do {Scalar::Util::reftype(qr//)}, "REGEXP", 'Scalar::Util::reftype(qr//)  # => REGEXP';

my $regex = bless qr//, "A";
::is scalar do {Scalar::Util::reftype($regex)}, "REGEXP", 'Scalar::Util::reftype($regex) # => REGEXP';

::is scalar do {$regex ~~ RegexpLike}, scalar do{1}, '$regex ~~ RegexpLike    # -> 1';
::is scalar do {qr// ~~ RegexpLike}, scalar do{1}, 'qr// ~~ RegexpLike    	# -> 1';
::is scalar do {"" ~~ RegexpLike}, scalar do{""}, '"" ~~ RegexpLike    	# -> ""';

package RegexpLikeExample {
	use overload 'qr' => sub { qr/abc/ };
}

::is scalar do {"RegexpLikeExample" ~~ RegexpLike}, scalar do{""}, '"RegexpLikeExample" ~~ RegexpLike    # -> ""';
::is scalar do {bless({}, "RegexpLikeExample") ~~ RegexpLike}, scalar do{1}, 'bless({}, "RegexpLikeExample") ~~ RegexpLike    # -> 1';

# 
# ## CodeLike
# 
# The subroutines.
# 
done_testing; }; subtest 'CodeLike' => sub { 
::is scalar do {sub {} ~~ CodeLike}, scalar do{1}, 'sub {} ~~ CodeLike    	# -> 1';
::is scalar do {\&CodeLike ~~ CodeLike}, scalar do{1}, '\&CodeLike ~~ CodeLike  # -> 1';
::is scalar do {{} ~~ CodeLike}, scalar do{""}, '{} ~~ CodeLike  		# -> ""';

# 
# ## ArrayLike`[A]
# 
# The arrays or objects with  or overloaded operator `@{}`.
# 
done_testing; }; subtest 'ArrayLike`[A]' => sub { 
::is scalar do {{} ~~ ArrayLike}, scalar do{""}, '{} ~~ ArrayLike    		# -> ""';
::is scalar do {{} ~~ ArrayLike[Int]}, scalar do{""}, '{} ~~ ArrayLike[Int]    # -> ""';

::is scalar do {[] ~~ ArrayLike}, scalar do{1}, '[] ~~ ArrayLike    	# -> 1';

package ArrayLikeExample {
	use overload '@{}' => sub {
		shift->{array} //= []
	};
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
::is_deeply scalar do {$x->{array}}, scalar do {[undef, 12]}, '$x->{array}  # --> [undef, 12]';

::is scalar do {$x ~~ ArrayLike}, scalar do{1}, '$x ~~ ArrayLike    # -> 1';

::is scalar do {$x ~~ ArrayLike[Int]}, scalar do{""}, '$x ~~ ArrayLike[Int]    # -> ""';

$x->[0] = 13;
::is scalar do {$x ~~ ArrayLike[Int]}, scalar do{1}, '$x ~~ ArrayLike[Int]    # -> 1';

# 
# ## HashLike`[A]
# 
# The hashes or objects with overloaded operator `%{}`.
# 
done_testing; }; subtest 'HashLike`[A]' => sub { 
::is scalar do {{} ~~ HashLike}, scalar do{1}, '{} ~~ HashLike    	# -> 1';
::is scalar do {[] ~~ HashLike}, scalar do{""}, '[] ~~ HashLike    	# -> ""';
::is scalar do {[] ~~ HashLike[Int]}, scalar do{""}, '[] ~~ HashLike[Int] # -> ""';

package HashLikeExample {
	use overload '%{}' => sub {
		shift->[0] //= {}
	};
}

my $x = bless [], 'HashLikeExample';
$x->{key} = 12.3;
::is_deeply scalar do {$x->[0]}, scalar do {{key => 12.3}}, '$x->[0]  # --> {key => 12.3}';

::is scalar do {$x ~~ HashLike}, scalar do{1}, '$x ~~ HashLike    	   # -> 1';
::is scalar do {$x ~~ HashLike[Int]}, scalar do{""}, '$x ~~ HashLike[Int]    # -> ""';
::is scalar do {$x ~~ HashLike[Num]}, scalar do{1}, '$x ~~ HashLike[Num]    # -> 1';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Types module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
