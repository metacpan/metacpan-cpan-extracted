use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # # NAME
# 
# Aion::Type - class of validators
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Type;

my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
::is scalar do {12   ~~ $Int}, "1", '12   ~~ $Int # => 1';
::is scalar do {12.1 ~~ $Int}, scalar do{""}, '12.1 ~~ $Int # -> ""';

my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
::is scalar do {$Char->include("a")}, "1", '$Char->include("a")	 # => 1';
::is scalar do {$Char->exclude("ab")}, "1", '$Char->exclude("ab") # => 1';

my $IntOrChar = $Int | $Char;
::is scalar do {77   ~~ $IntOrChar}, "1", '77   ~~ $IntOrChar # => 1';
::is scalar do {"a"  ~~ $IntOrChar}, "1", '"a"  ~~ $IntOrChar # => 1';
::is scalar do {"ab" ~~ $IntOrChar}, scalar do{""}, '"ab" ~~ $IntOrChar # -> ""';

my $Digit = $Int & $Char;
::is scalar do {7  ~~ $Digit}, "1", '7  ~~ $Digit # => 1';
::is scalar do {77 ~~ $Digit}, scalar do{""}, '77 ~~ $Digit # -> ""';

::is scalar do {"a" ~~ ~$Int;}, "1", '"a" ~~ ~$Int; # => 1';
::is scalar do {5   ~~ ~$Int;}, scalar do{""}, '5   ~~ ~$Int; # -> ""';

::like scalar do {eval { $Int->validate("a", "..Eval..") }; $@}, qr{..Eval.. must have the type Int. The it is 'a'}, 'eval { $Int->validate("a", "..Eval..") }; $@	# ~> ..Eval.. must have the type Int. The it is \'a\'';

# 
# # DESCRIPTION
# 
# This is construct for make any validators.
# 
# It using in `Aion::Types::subtype`.
# 
# # METHODS
# 
# ## new (%ARGUMENTS)
# 
# Constructor.
# 
# ### ARGUMENTS
# 
# * name (Str) — Name of type.
# * args (ArrayRef) — List of type arguments.
# * init (CodeRef) — Initializer for type.
# * test (CodeRef) — Values cheker.
# * a_test (CodeRef) — Values cheker for types with optional arguments.
# * coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) — Array of pairs: type and via.
# 
# ## stringify
# 
# Stringify of object (name with arguments):
# 
::done_testing; }; subtest 'stringify' => sub { 
my $Char = Aion::Type->new(name => "Char");

::is scalar do {$Char->stringify}, "Char", '$Char->stringify # => Char';

my $Int = Aion::Type->new(
	name => "Int",
	args => [3, 5],
);

::is scalar do {$Int->stringify}, "Int[3, 5]", '$Int->stringify  #=> Int[3, 5]';

# 
# Stringify operations:
# 

::is scalar do {($Int & $Char)->stringify}, "( Int[3, 5] & Char )", '($Int & $Char)->stringify   # => ( Int[3, 5] & Char )';
::is scalar do {($Int | $Char)->stringify}, "( Int[3, 5] | Char )", '($Int | $Char)->stringify   # => ( Int[3, 5] | Char )';
::is scalar do {(~$Int)->stringify}, "~Int[3, 5]", '(~$Int)->stringify		  # => ~Int[3, 5]';

# 
# The operations is objects of `Aion::Type` with special names:
# 

::is scalar do {Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify}, "~( Int[3, 5] | Char )", 'Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )';
::is scalar do {Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify}, "( Int[3, 5] | Char )", 'Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )';
::is scalar do {Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify}, "( Int[3, 5] & Char )", 'Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )';

# 
# ## test
# 
# Testing the `$_` belongs to the class.
# 
::done_testing; }; subtest 'test' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local $_ = 5;
::is scalar do {$PositiveInt->test}, scalar do{1}, '$PositiveInt->test  # -> 1';
local $_ = -6;
::is scalar do {$PositiveInt->test}, scalar do{""}, '$PositiveInt->test  # -> ""';

# 
# ## init
# 
# Initial the validator.
# 
::done_testing; }; subtest 'init' => sub { 
my $Range = Aion::Type->new(
	name => "Range",
	args => [3, 5],
	init => sub {
		@{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
	},
	test => sub { $Aion::Type::SELF->{min} <= $_ && $_ <= $Aion::Type::SELF->{max} },
);

$Range->init;

::is scalar do {3 ~~ $Range}, scalar do{1}, '3 ~~ $Range  # -> 1';
::is scalar do {4 ~~ $Range}, scalar do{1}, '4 ~~ $Range  # -> 1';
::is scalar do {5 ~~ $Range}, scalar do{1}, '5 ~~ $Range  # -> 1';

::is scalar do {2 ~~ $Range}, scalar do{""}, '2 ~~ $Range  # -> ""';
::is scalar do {6 ~~ $Range}, scalar do{""}, '6 ~~ $Range  # -> ""';

# 
# 
# ## include ($element)
# 
# checks whether the argument belongs to the class.
# 
::done_testing; }; subtest 'include ($element)' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

::is scalar do {$PositiveInt->include(5)}, scalar do{1}, '$PositiveInt->include(5) # -> 1';
::is scalar do {$PositiveInt->include(-6)}, scalar do{""}, '$PositiveInt->include(-6) # -> ""';

# 
# ## exclude ($element)
# 
# Checks that the argument does not belong to the class.
# 
::done_testing; }; subtest 'exclude ($element)' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

::is scalar do {$PositiveInt->exclude(5)}, scalar do{""}, '$PositiveInt->exclude(5)  # -> ""';
::is scalar do {$PositiveInt->exclude(-6)}, scalar do{1}, '$PositiveInt->exclude(-6) # -> 1';

# 
# ## coerce ($value)
# 
# Coerce `$value` to the type, if coerce from type and function is in `$self->{coerce}`.
# 
::done_testing; }; subtest 'coerce ($value)' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });

push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];

::is scalar do {$Int->coerce(5.5)}, "6", '$Int->coerce(5.5)	# => 6';
::is scalar do {$Int->coerce(undef)}, "0", '$Int->coerce(undef)  # => 0';
::is scalar do {$Int->coerce("abc")}, "abc", '$Int->coerce("abc")  # => abc';

# 
# ## detail ($element, $feature)
# 
# Return message belongs to error.
# 
::done_testing; }; subtest 'detail ($element, $feature)' => sub { 
my $Int = Aion::Type->new(name => "Int");

::is scalar do {$Int->detail(-5, "Feature car")}, "Feature car must have the type Int. The it is -5!", '$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!';

my $Num = Aion::Type->new(name => "Num", message => sub {
	"Error: $_ is'nt $Aion::Type::SELF->{N}!"
});

::is scalar do {$Num->detail("x", "car")}, "Error: x is'nt car!", '$Num->detail("x", "car")  # => Error: x is\'nt car!';

# 
# `$Aion::Type::SELF->{N}` equivalent to `N` in context of `Aion::Types`.
# 
# ## validate ($element, $feature)
# 
# It tested `$element` and throw `detail` if element is exclude from class.
# 
::done_testing; }; subtest 'validate ($element, $feature)' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

eval {
	$PositiveInt->validate(-1, "Neg")
};
::like scalar do {$@}, qr{Neg must have the type PositiveInt. The it is -1}, '$@   # ~> Neg must have the type PositiveInt. The it is -1';

# 
# ## val_to_str ($val)
# 
# Переводит `$val` в строку.
# 
::done_testing; }; subtest 'val_to_str ($val)' => sub { 
::is scalar do {Aion::Type->new->val_to_str([1,2,{x=>6}])}, "[1, 2, {x => 6}]", 'Aion::Type->new->val_to_str([1,2,{x=>6}])   # => [1, 2, {x => 6}]';

# 
# ## instanceof ($type)
# 
# Determines that the type is a subtype of a different $type.
# 
::done_testing; }; subtest 'instanceof ($type)' => sub { 
my $int = Aion::Type->new(name => "Int");
my $positiveInt = Aion::Type->new(name => "PositiveInt", as => $int);

::is scalar do {$positiveInt->instanceof($int)}, scalar do{1}, '$positiveInt->instanceof($int)		  # -> 1';
::is scalar do {$positiveInt->instanceof($positiveInt)}, scalar do{1}, '$positiveInt->instanceof($positiveInt)  # -> 1';
::is scalar do {$positiveInt->instanceof('Int')}, scalar do{1}, '$positiveInt->instanceof(\'Int\')		 # -> 1';
::is scalar do {$positiveInt->instanceof('PositiveInt')}, scalar do{1}, '$positiveInt->instanceof(\'PositiveInt\') # -> 1';
::is scalar do {$int->instanceof('PositiveInt')}, scalar do{""}, '$int->instanceof(\'PositiveInt\')		 # -> ""';
::is scalar do {$int->instanceof('Int')}, scalar do{1}, '$int->instanceof(\'Int\')				 # -> 1';

# 
# ## make ($pkg)
# 
# It make subroutine without arguments, who return type.
# 
::done_testing; }; subtest 'make ($pkg)' => sub { 
BEGIN {
	Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
}

::is scalar do {"IX" ~~ Rim}, "1", '"IX" ~~ Rim	 # => 1';

# 
# Property `init` won't use with `make`.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@}, qr{init_where won't work in Rim}, 'eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won\'t work in Rim';

# 
# If subroutine make'nt, then died.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim")->make }; $@}, qr{syntax error}, 'eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error';

# 
# ## make_arg ($pkg)
# 
# It make subroutine with arguments, who return type.
# 
::done_testing; }; subtest 'make_arg ($pkg)' => sub { 
BEGIN {
	Aion::Type->new(name=>"Len", test => sub {
		$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
	})->make_arg(__PACKAGE__);
}

::is scalar do {"IX" ~~ Len[2,2]}, "1", '"IX" ~~ Len[2,2]	# => 1';

# 
# If subroutine make'nt, then died.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim")->make_arg }; $@}, qr{syntax error}, 'eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error';

# 
# ## make_maybe_arg ($pkg)
# 
# It make subroutine with or without arguments, who return type.
# 
::done_testing; }; subtest 'make_maybe_arg ($pkg)' => sub { 
BEGIN {
	Aion::Type->new(
		name => "Enum123",
		test => sub { $_ ~~ [1,2,3] },
		a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
	)->make_maybe_arg(__PACKAGE__);
}

::is scalar do {3 ~~ Enum123}, scalar do{1}, '3 ~~ Enum123			# -> 1';
::is scalar do {3 ~~ Enum123[4,5,6]}, scalar do{""}, '3 ~~ Enum123[4,5,6]	 # -> ""';
::is scalar do {5 ~~ Enum123[4,5,6]}, scalar do{1}, '5 ~~ Enum123[4,5,6]	 # -> 1';

# 
# If subroutine make'nt, then died.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@}, qr{syntax error}, 'eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error';

# 
# ## equal ($type)
# 
# Types are equal when they have the same name, the same number of arguments, parent and arguments are equal.
# 
::done_testing; }; subtest 'equal ($type)' => sub { 
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
my $AnotherInt = Aion::Type->new(name => "Int");
my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
my $Str = Aion::Type->new(name => "Str");

::is scalar do {$Int->equal($Int)}, scalar do{1}, '$Int->equal($Int)                     # -> 1';
::is scalar do {$Int->equal($AnotherInt)}, scalar do{1}, '$Int->equal($AnotherInt)              # -> 1';
::is scalar do {$IntWithArgs->equal($AnotherIntWithArgs)}, scalar do{1}, '$IntWithArgs->equal($AnotherIntWithArgs) # -> 1';
::is scalar do {$PositiveInt->equal($PositiveInt)}, scalar do{1}, '$PositiveInt->equal($PositiveInt)     # -> 1';

::is scalar do {$Int->equal($Str)}, scalar do{""}, '$Int->equal($Str)                     # -> ""';
::is scalar do {$Int->equal($IntWithArgs)}, scalar do{""}, '$Int->equal($IntWithArgs)             # -> ""';
::is scalar do {$IntWithArgs->equal($IntWithDifferentArgs)}, scalar do{""}, '$IntWithArgs->equal($IntWithDifferentArgs) # -> ""';
::is scalar do {$PositiveInt->equal($Int)}, scalar do{""}, '$PositiveInt->equal($Int)             # -> ""';

::is scalar do {$Int->equal("not a type")}, scalar do{""}, '$Int->equal("not a type")             # -> ""';

my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
::is scalar do {$PositiveInt->equal($PositiveInt2)}, scalar do{""}, '$PositiveInt->equal($PositiveInt2)    # -> ""';

::is scalar do {$Int->equal($PositiveInt)}, scalar do{""}, '$Int->equal($PositiveInt)             # -> ""';
::is scalar do {$PositiveInt->equal($Int)}, scalar do{""}, '$PositiveInt->equal($Int)             # -> ""';

my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
::is scalar do {$PositiveIntWithArgs->equal($PositiveIntWithArgs2)}, scalar do{""}, '$PositiveIntWithArgs->equal($PositiveIntWithArgs2) # -> ""';

# 
# ## nonequal ($type)
# 
# Inverse of equal.
# 
::done_testing; }; subtest 'nonequal ($type)' => sub { 
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);

::is scalar do {$Int->nonequal($PositiveInt)}, scalar do{1}, '$Int->nonequal($PositiveInt) # -> 1';
::is scalar do {$Int ne $PositiveInt}, scalar do{1}, '$Int ne $PositiveInt         # -> 1';

# 
# ## args ()
# 
# The list of arguments.
# 
# ## name ()
# 
# The name of type.
# 
# ## as ()
# 
# The parent type.
# 
# ## message (;&message)
# 
# Getter/setter for message. Message use for generate error message.
# 
# ## title (;$title)
# 
# Getter/setter for title (using for swagger).
# 
# ## description (;$description)
# 
# Getter/setter for description (using for swagger).
# 
# # OPERATORS
# 
# ## &{}
# 
# It make the object is callable.
# 
::done_testing; }; subtest '&{}' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local $_ = 10;
::is scalar do {$PositiveInt->()}, scalar do{1}, '$PositiveInt->()	# -> 1';

$_ = -1;
::is scalar do {$PositiveInt->()}, scalar do{""}, '$PositiveInt->()	# -> ""';

# 
# ## ""
# 
# Stringify object.
# 
::done_testing; }; subtest '""' => sub { 
::is scalar do {Aion::Type->new(name => "Int") . ""}, "Int", 'Aion::Type->new(name => "Int") . ""   # => Int';

my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);

::is scalar do {"$Enum"}, "Enum['A', 'B', 'C']", '"$Enum" # => Enum[\'A\', \'B\', \'C\']';

# 
# ## $a | $b
# 
# It make new type as union of `$a` and `$b`.
# 
::done_testing; }; subtest '$a | $b' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $IntOrChar = $Int | $Char;

::is scalar do {77   ~~ $IntOrChar}, scalar do{1}, '77   ~~ $IntOrChar # -> 1';
::is scalar do {"a"  ~~ $IntOrChar}, scalar do{1}, '"a"  ~~ $IntOrChar # -> 1';
::is scalar do {"ab" ~~ $IntOrChar}, scalar do{""}, '"ab" ~~ $IntOrChar # -> ""';

# 
# ## $a & $b
# 
# It make new type as intersection of `$a` and `$b`.
# 
::done_testing; }; subtest '$a & $b' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $Digit = $Int & $Char;

::is scalar do {7  ~~ $Digit}, scalar do{1}, '7  ~~ $Digit # -> 1';
::is scalar do {77 ~~ $Digit}, scalar do{""}, '77 ~~ $Digit # -> ""';
::is scalar do {"a" ~~ $Digit}, scalar do{""}, '"a" ~~ $Digit # -> ""';

# 
# ## ~ $a
# 
# It make exclude type from `$a`.
# 
::done_testing; }; subtest '~ $a' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

::is scalar do {"a" ~~ ~$Int;}, scalar do{1}, '"a" ~~ ~$Int; # -> 1';
::is scalar do {5   ~~ ~$Int;}, scalar do{""}, '5   ~~ ~$Int; # -> ""';

# 
# ## $a eq $b
# 
# `$a` equal `$b`.
# 
::done_testing; }; subtest '$a eq $b' => sub { 
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

::is scalar do {$Int1 eq $Int2}, scalar do{1}, '$Int1 eq $Int2 # -> 1';

# 
# ## $a ne $b
# 
# `$a` not equal `$b`.
# 
::done_testing; }; subtest '$a ne $b' => sub { 
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

::is scalar do {$Int1 ne $Int2}, scalar do{""}, '$Int1 ne $Int2 # -> ""';
::is scalar do {123 ne $Int2}, scalar do{1}, '123 ne $Int2 # -> 1';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
