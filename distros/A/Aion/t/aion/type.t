use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Type - класс валидаторов
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Type;

my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
local ($::_g0 = do {12   ~~ $Int}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '12   ~~ $Int # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {12.1 ~~ $Int}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '12.1 ~~ $Int # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
local ($::_g0 = do {$Char->include("a")}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '$Char->include("a")	 # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Char->exclude("ab")}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '$Char->exclude("ab") # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $IntOrChar = $Int | $Char;
local ($::_g0 = do {77   ~~ $IntOrChar}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '77   ~~ $IntOrChar # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"a"  ~~ $IntOrChar}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '"a"  ~~ $IntOrChar # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"ab" ~~ $IntOrChar}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"ab" ~~ $IntOrChar # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $Digit = $Int & $Char;
local ($::_g0 = do {7  ~~ $Digit}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '7  ~~ $Digit # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {77 ~~ $Digit}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '77 ~~ $Digit # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {"a" ~~ ~$Int;}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '"a" ~~ ~$Int; # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5   ~~ ~$Int;}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5   ~~ ~$Int; # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { $Int->validate("a", "..Eval..") }; $@}, qr{..Eval.. must have the type Int. The it is 'a'}, 'eval { $Int->validate("a", "..Eval..") }; $@	# ~> ..Eval.. must have the type Int. The it is \'a\''; undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Порождает валидаторы. Используется в `Aion::Types::subtype`.
# 
# # METHODS
# 
# ## new (%ARGUMENTS)
# 
# Конструктор.
# 
# ### ARGUMENTS
# 
# * name (Str) — Название типа.
# * args (ArrayRef) — Список аргументов типа.
# * init (CodeRef) — Инициализатор типа.
# * test (CodeRef) — Чекер.
# * a_test (CodeRef) — Чекер значений для типов с необязательными аргументами.
# * coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) — Массив пар: тип и переход.
# 
# ## stringify
# 
# Строковое преобразование объекта (имя с аргументами):
# 
::done_testing; }; subtest 'stringify' => sub { 
my $Char = Aion::Type->new(name => "Char");

local ($::_g0 = do {$Char->stringify}, $::_e0 = "Char"); ::ok $::_g0 eq $::_e0, '$Char->stringify # => Char' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $Int = Aion::Type->new(
	name => "Int",
	args => [3, 5],
);

local ($::_g0 = do {$Int->stringify}, $::_e0 = "Int[3, 5]"); ::ok $::_g0 eq $::_e0, '$Int->stringify  #=> Int[3, 5]' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Операции так же преобразуются в строку:
# 

local ($::_g0 = do {($Int & $Char)->stringify}, $::_e0 = "( Int[3, 5] & Char )"); ::ok $::_g0 eq $::_e0, '($Int & $Char)->stringify   # => ( Int[3, 5] & Char )' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {($Int | $Char)->stringify}, $::_e0 = "( Int[3, 5] | Char )"); ::ok $::_g0 eq $::_e0, '($Int | $Char)->stringify   # => ( Int[3, 5] | Char )' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {(~$Int)->stringify}, $::_e0 = "~Int[3, 5]"); ::ok $::_g0 eq $::_e0, '(~$Int)->stringify		  # => ~Int[3, 5]' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Операции — это объекты `Aion::Type` со специальными именами:
# 

local ($::_g0 = do {Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify}, $::_e0 = "~( Int[3, 5] | Char )"); ::ok $::_g0 eq $::_e0, 'Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify}, $::_e0 = "( Int[3, 5] | Char )"); ::ok $::_g0 eq $::_e0, 'Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify}, $::_e0 = "( Int[3, 5] & Char )"); ::ok $::_g0 eq $::_e0, 'Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## test
# 
# Тестирует, что `$_` принадлежит классу.
# 
::done_testing; }; subtest 'test' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local $_ = 5;
local ($::_g0 = do {$PositiveInt->test}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->test  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local $_ = -6;
local ($::_g0 = do {$PositiveInt->test}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->test  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## init
# 
# Инициализатор валидатора.
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

local ($::_g0 = do {3 ~~ $Range}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ $Range  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {4 ~~ $Range}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '4 ~~ $Range  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5 ~~ $Range}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5 ~~ $Range  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {2 ~~ $Range}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2 ~~ $Range  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {6 ~~ $Range}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '6 ~~ $Range  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# 
# ## include ($element)
# 
# Проверяет, принадлежит ли аргумент классу.
# 
::done_testing; }; subtest 'include ($element)' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local ($::_g0 = do {$PositiveInt->include(5)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->include(5) # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$PositiveInt->include(-6)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->include(-6) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## exclude ($element)
# 
# Проверяет, что аргумент не принадлежит классу.
# 
::done_testing; }; subtest 'exclude ($element)' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local ($::_g0 = do {$PositiveInt->exclude(5)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->exclude(5)  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$PositiveInt->exclude(-6)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->exclude(-6) # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## coerce ($value)
# 
# Привести `$value` к типу, если приведение из типа и функции находится в `$self->{coerce}`.
# 
::done_testing; }; subtest 'coerce ($value)' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });

push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];

local ($::_g0 = do {$Int->coerce(5.5)}, $::_e0 = "6"); ::ok $::_g0 eq $::_e0, '$Int->coerce(5.5)	# => 6' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int->coerce(undef)}, $::_e0 = "0"); ::ok $::_g0 eq $::_e0, '$Int->coerce(undef)  # => 0' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int->coerce("abc")}, $::_e0 = "abc"); ::ok $::_g0 eq $::_e0, '$Int->coerce("abc")  # => abc' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## detail ($element, $feature)
# 
# Формирует сообщение ошибки.
# 
::done_testing; }; subtest 'detail ($element, $feature)' => sub { 
my $Int = Aion::Type->new(name => "Int");

local ($::_g0 = do {$Int->detail(-5, "Feature car")}, $::_e0 = "Feature car must have the type Int. The it is -5!"); ::ok $::_g0 eq $::_e0, '$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $Num = Aion::Type->new(name => "Num", message => sub {
	"Error: $_ is'nt $Aion::Type::SELF->{N}!"
});

local ($::_g0 = do {$Num->detail("x", "car")}, $::_e0 = "Error: x is'nt car!"); ::ok $::_g0 eq $::_e0, '$Num->detail("x", "car") # => Error: x is\'nt car!' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# `$Aion::Type::SELF->{N}` equivalent to `N` in context of `Aion::Types`.
# 
# ## validate ($element, $feature)
# 
# Проверяет `$element` и выбрасывает сообщение `detail`, если элемент не принадлежит классу.
# 
::done_testing; }; subtest 'validate ($element, $feature)' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

eval {
	$PositiveInt->validate(-1, "Neg")
};
::like scalar do {$@}, qr{Neg must have the type PositiveInt. The it is -1}, '$@ # ~> Neg must have the type PositiveInt. The it is -1'; undef $::_g0; undef $::_e0;

# 
# ## val_to_str ($val)
# 
# Переводит `$val` в строку.
# 
::done_testing; }; subtest 'val_to_str ($val)' => sub { 
local ($::_g0 = do {Aion::Type->new->val_to_str([1,2,{x=>6}])}, $::_e0 = "[1, 2, {x => 6}]"); ::ok $::_g0 eq $::_e0, 'Aion::Type->new->val_to_str([1,2,{x=>6}]) # => [1, 2, {x => 6}]' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## instanceof ($type)
# 
# Определяет, что тип является подтипом другого `$type`.
# 
::done_testing; }; subtest 'instanceof ($type)' => sub { 
my $int = Aion::Type->new(name => "Int");
my $positiveInt = Aion::Type->new(name => "PositiveInt", as => $int);

local ($::_g0 = do {$positiveInt->instanceof($int)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$positiveInt->instanceof($int)          # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$positiveInt->instanceof($positiveInt)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$positiveInt->instanceof($positiveInt)  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$positiveInt->instanceof('Int')}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$positiveInt->instanceof(\'Int\')         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$positiveInt->instanceof('PositiveInt')}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$positiveInt->instanceof(\'PositiveInt\') # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$int->instanceof('PositiveInt')}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$int->instanceof(\'PositiveInt\')         # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$int->instanceof('Int')}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$int->instanceof(\'Int\')                 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## make ($pkg)
# 
# Создаёт подпрограмму без аргументов, которая возвращает тип.
# 
::done_testing; }; subtest 'make ($pkg)' => sub { 
BEGIN {
	Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
}

local ($::_g0 = do {"IX" ~~ Rim}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '"IX" ~~ Rim	 # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Свойство `init` не может использоваться с `make`.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@}, qr{init_where won't work in Rim}, 'eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won\'t work in Rim'; undef $::_g0; undef $::_e0;

# 
# Если подпрограмма не может быть создана, то выбрасывается исключение.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim")->make }; $@}, qr{syntax error}, 'eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error'; undef $::_g0; undef $::_e0;

# 
# ## make_arg ($pkg)
# 
# Создает подпрограмму с аргументами, которая возвращает тип.
# 
::done_testing; }; subtest 'make_arg ($pkg)' => sub { 
BEGIN {
	Aion::Type->new(name=>"Len", test => sub {
		$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
	})->make_arg(__PACKAGE__);
}

local ($::_g0 = do {"IX" ~~ Len[2,2]}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '"IX" ~~ Len[2,2]	# => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Если подпрограмма не может быть создана, то выбрасывается исключение.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim")->make_arg }; $@}, qr{syntax error}, 'eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error'; undef $::_g0; undef $::_e0;

# 
# ## make_maybe_arg ($pkg)
# 
# Создает подпрограмму с аргументами, которая возвращает тип.
# 
::done_testing; }; subtest 'make_maybe_arg ($pkg)' => sub { 
BEGIN {
	Aion::Type->new(
		name => "Enum123",
		test => sub { $_ ~~ [1,2,3] },
		a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
	)->make_maybe_arg(__PACKAGE__);
}

local ($::_g0 = do {3 ~~ Enum123}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ Enum123			# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {3 ~~ Enum123[4,5,6]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ Enum123[4,5,6]	 # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5 ~~ Enum123[4,5,6]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5 ~~ Enum123[4,5,6]	 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Если подпрограмма не может быть создана, то выбрасывается исключение.
# 

::like scalar do {eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@}, qr{syntax error}, 'eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error'; undef $::_g0; undef $::_e0;

# 
# ## equal ($type)
# 
# Типы равны, если они имеют одинаковое имя, одинаковое количество аргументов, родительский элемент и аргументы равны.
# 
::done_testing; }; subtest 'equal ($type)' => sub { 
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
my $AnotherInt = Aion::Type->new(name => "Int");
my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
my $Str = Aion::Type->new(name => "Str");

local ($::_g0 = do {$Int->equal($Int)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->equal($Int)                        # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int->equal($AnotherInt)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->equal($AnotherInt)                 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$IntWithArgs->equal($AnotherIntWithArgs)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$IntWithArgs->equal($AnotherIntWithArgs) # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$PositiveInt->equal($PositiveInt)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->equal($PositiveInt)        # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$Int->equal($Str)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->equal($Str)                          # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int->equal($IntWithArgs)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->equal($IntWithArgs)                  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$IntWithArgs->equal($IntWithDifferentArgs)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$IntWithArgs->equal($IntWithDifferentArgs) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$PositiveInt->equal($Int)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->equal($Int)                  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$Int->equal("not a type")}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->equal("not a type") # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
local ($::_g0 = do {$PositiveInt->equal($PositiveInt2)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->equal($PositiveInt2) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$Int->equal($PositiveInt)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->equal($PositiveInt) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$PositiveInt->equal($Int)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->equal($Int) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
local ($::_g0 = do {$PositiveIntWithArgs->equal($PositiveIntWithArgs2)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveIntWithArgs->equal($PositiveIntWithArgs2) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## nonequal ($type)
# 
# Обратная операция к `equal`.
# 
::done_testing; }; subtest 'nonequal ($type)' => sub { 
my $Int = Aion::Type->new(name => "Int");
my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);

local ($::_g0 = do {$Int->nonequal($PositiveInt)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int->nonequal($PositiveInt) # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int ne $PositiveInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int ne $PositiveInt         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## args ()
# 
# Список аргументов.
# 
# ## name ()
# 
# Имя типа.
# 
# ## as ()
# 
# Родительский тип.
# 
# ## message (;&message)
# 
# Акцессор сообщения. Использует `&message` для генерации сообщения об ошибке.
# 
# ## title (;$title)
# 
# Акцессор заголовка (используется для создания схемы **swagger**).
# 
# ## description (;$description)
# 
# Акцессор описания (используется для создания схемы **swagger**).
# 
# # OPERATORS
# 
# ## &{}
# 
# Делает объект вызываемым.
# 
::done_testing; }; subtest '&{}' => sub { 
my $PositiveInt = Aion::Type->new(
	name => "PositiveInt",
	test => sub { /^\d+$/ },
);

local $_ = 10;
local ($::_g0 = do {$PositiveInt->()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->()	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$_ = -1;
local ($::_g0 = do {$PositiveInt->()}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$PositiveInt->()	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ""
# 
# Стрингифицирует объект.
# 
::done_testing; }; subtest '""' => sub { 
local ($::_g0 = do {Aion::Type->new(name => "Int") . ""}, $::_e0 = "Int"); ::ok $::_g0 eq $::_e0, 'Aion::Type->new(name => "Int") . ""   # => Int' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);

local ($::_g0 = do {"$Enum"}, $::_e0 = "Enum['A', 'B', 'C']"); ::ok $::_g0 eq $::_e0, '"$Enum" # => Enum[\'A\', \'B\', \'C\']' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## $a | $b
# 
# Создает новый тип как объединение `$a` и `$b`.
# 
::done_testing; }; subtest '$a | $b' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $IntOrChar = $Int | $Char;

local ($::_g0 = do {77   ~~ $IntOrChar}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '77   ~~ $IntOrChar # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"a"  ~~ $IntOrChar}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"a"  ~~ $IntOrChar # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"ab" ~~ $IntOrChar}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"ab" ~~ $IntOrChar # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## $a & $b
# 
# Создает новый тип как пересечение `$a` и `$b`.
# 
::done_testing; }; subtest '$a & $b' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });

my $Digit = $Int & $Char;

local ($::_g0 = do {7  ~~ $Digit}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '7  ~~ $Digit # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {77 ~~ $Digit}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '77 ~~ $Digit # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"a" ~~ $Digit}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"a" ~~ $Digit # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ~ $a
# 
# Создает новый тип как исключение из `$a`.
# 
::done_testing; }; subtest '~ $a' => sub { 
my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });

local ($::_g0 = do {"a" ~~ ~$Int;}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"a" ~~ ~$Int; # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5   ~~ ~$Int;}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5   ~~ ~$Int; # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## $a eq $b, $a == $b
# 
# `$a` равно `$b`.
# 
::done_testing; }; subtest '$a eq $b, $a == $b' => sub { 
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

local ($::_g0 = do {$Int1 eq $Int2}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int1 eq $Int2 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int1 == $Int2}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int1 == $Int2 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## $a ne $b, $a != $b
# 
# `$a` не равно `$b`.
# 
::done_testing; }; subtest '$a ne $b, $a != $b' => sub { 
my $Int1 = Aion::Type->new(name => "Int");
my $Int2 = Aion::Type->new(name => "Int");

local ($::_g0 = do {$Int1 ne $Int2}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int1 ne $Int2 # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$Int1 != $Int2}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$Int1 != $Int2 # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {123 ne $Int2}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '123 ne $Int2 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
