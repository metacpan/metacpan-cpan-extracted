use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Types - библиотека стандартных валидаторов и служит для создания новых валидаторов
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types;

BEGIN {
	subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
		message { "Speak is'nt included kitty!" };
}

local ($::_g0 = do {"Kitty!" ~~ SpeakOfKitty}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Kitty!" ~~ SpeakOfKitty # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"abc"    ~~ SpeakOfKitty}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"abc"    ~~ SpeakOfKitty # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

eval {SpeakOfKitty->validate("abc", "This")}; local ($::_g0 = $@, $::_e0 = 'Speak is\'nt included kitty!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'SpeakOfKitty->validate("abc", "This") # @-> Speak is\'nt included kitty!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;


BEGIN {
	subtype IntOrArrayRef => as (Int | ArrayRef);
}

local ($::_g0 = do {[] ~~ IntOrArrayRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ IntOrArrayRef  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {35 ~~ IntOrArrayRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '35 ~~ IntOrArrayRef  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ IntOrArrayRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ IntOrArrayRef  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;


coerce IntOrArrayRef, from Num, via { int($_ + .5) };

local ($::_g0 = do {IntOrArrayRef->coerce(5.5)}, $::_e0 = "6"); ::ok $::_g0 eq $::_e0, 'IntOrArrayRef->coerce(5.5) # => 6' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Этот модуль экспортирует подпрограммы:
# 
# * `subtype`, `as`, `init_where`, `where`, `awhere`, `message` — для создания валидаторов.
# * `SELF`, `ARGS`, `A`, `B`, `C`, `D`, `M`, `N` — для использования в валидаторах типа и его аргументов.
# * `coerce`, `from`, `via` — для создания конвертора значений из одного класса в другой.
# 
# Иерархия валидаторов:
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
# 		BoolLike
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
# 				CodeRef`[name, proto]
# 					ReachableCodeRef`[name, proto]
# 					UnreachableCodeRef`[name, proto]
# 				RegexpRef
# 				ScalarRefRef`[A]
# 					RefRef`[A]
# 					ScalarRef`[A]
# 				GlobRef
# 					FileHandle
# 				ArrayRef`[A]
# 				HashRef`[H]
# 				Object`[O]
# 					Me
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
# # SUBROUTINES
# 
# ## subtype ($name, @paraphernalia)
# 
# Создаёт новый тип.
# 
::done_testing; }; subtest 'subtype ($name, @paraphernalia)' => sub { 
BEGIN {
	subtype One => where { $_ == 1 } message { "Actual 1 only!" };
}

local ($::_g0 = do {1 ~~ One}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ One	 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ One}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ One	 # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {eval { One->validate(0) }; $@}, qr{Actual 1 only\!}, 'eval { One->validate(0) }; $@ # ~> Actual 1 only!'; undef $::_g0; undef $::_e0;

# 
# `where` и `message` — это синтаксический сахар, а `subtype` можно использовать без них.
# 

BEGIN {
	subtype Many => (where => sub { $_ > 1 });
}

local ($::_g0 = do {2 ~~ Many}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2 ~~ Many  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

::like scalar do {eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@}, qr{subtype Many unused keys left: where1}, 'eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@ # ~> subtype Many unused keys left: where1'; undef $::_g0; undef $::_e0;

::like scalar do {eval { subtype 'Many' }; $@}, qr{subtype Many: main::Many exists\!}, 'eval { subtype \'Many\' }; $@ # ~> subtype Many: main::Many exists!'; undef $::_g0; undef $::_e0;

# 
# ## as ($super_type)
# 
# Используется с `subtype` для расширения создаваемого типа `$super_type`.
# 
# ## init_where ($code)
# 
# Инициализирует тип с новыми аргументами. Используется с `subtype`.
# 
::done_testing; }; subtest 'init_where ($code)' => sub { 
BEGIN {
	subtype 'LessThen[A]',
		init_where { Num->validate(A, "Argument LessThen[A]") }
		where { $_ < A };
}

::like scalar do {eval { LessThen["string"] }; $@}, qr{Argument LessThen\[A\]}, 'eval { LessThen["string"] }; $@  # ~> Argument LessThen\[A\]'; undef $::_g0; undef $::_e0;

local ($::_g0 = do {5 ~~ LessThen[5]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5 ~~ LessThen[5]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## where ($code)
# 
# Использует `$code` как тест. Значение для теста передаётся в `$_`.
# 
::done_testing; }; subtest 'where ($code)' => sub { 
BEGIN {
	subtype 'Two',
		where { $_ == 2 };
}

local ($::_g0 = do {2 ~~ Two}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2 ~~ Two # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {3 ~~ Two}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ Two # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Используется с `subtype`. Необходимо, если у типа есть аргументы.
# 

eval {subtype 'Ex[A]'}; local ($::_g0 = $@, $::_e0 = 'subtype Ex[A]: needs a where'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'subtype \'Ex[A]\' # @-> subtype Ex[A]: needs a where' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# ## awhere ($code)
# 
# Используется с `subtype`.
# 
# Если тип может быть с аргументами и без, то используется для проверки набора с аргументами, а `where` — без.
# 
::done_testing; }; subtest 'awhere ($code)' => sub { 
BEGIN {
	subtype 'GreatThen`[A]',
		where { $_ > 0 }
		awhere { $_ > A }
	;
}

local ($::_g0 = do {0 ~~ GreatThen}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ GreatThen # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1 ~~ GreatThen}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ GreatThen # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {3 ~~ GreatThen[3]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ GreatThen[3] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {4 ~~ GreatThen[3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '4 ~~ GreatThen[3] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Необходимо, если аргументы необязательны.
# 

eval {subtype 'Ex`[A]', where {}}; local ($::_g0 = $@, $::_e0 = 'subtype Ex`[A]: needs a awhere'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'subtype \'Ex`[A]\', where {} # @-> subtype Ex`[A]: needs a awhere' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {subtype 'Ex', awhere {}}; local ($::_g0 = $@, $::_e0 = 'subtype Ex: awhere is excess'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'subtype \'Ex\', awhere {} # @-> subtype Ex: awhere is excess' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

BEGIN {
	subtype 'MyEnum`[A...]',
		as Str,
		awhere { $_ ~~ scalar ARGS }
	;
}

local ($::_g0 = do {"ab" ~~ MyEnum[qw/ab cd/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"ab" ~~ MyEnum[qw/ab cd/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## SELF
# 
# Текущий тип. `SELF` используется в `init_where`, `where` и `awhere`.
# 
# ## ARGS
# 
# Аргументы текущего типа. В скалярном контексте возвращает ссылку на массив, а в контексте массива возвращает список. Используется в `init_where`, `where` и `awhere`.
# 
# ## A, B, C, D
# 
# Первый, второй, третий и пятый аргумент типа.
# 
::done_testing; }; subtest 'A, B, C, D' => sub { 
BEGIN {
	subtype "Seria[A,B,C,D]", where { A < B && B < $_ && $_ < C && C < D };
}

local ($::_g0 = do {2.5 ~~ Seria[1,2,3,4]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2.5 ~~ Seria[1,2,3,4] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Используется в `init_where`, `where` и `awhere`.
# 
# ## M, N
# 
# `M` и `N` сокращение для `SELF->{M}` и `SELF->{N}`.
# 
::done_testing; }; subtest 'M, N' => sub { 
BEGIN {
	subtype "BeginAndEnd[A, B]",
		init_where {
			N = qr/^${\ quotemeta A}/;
			M = qr/${\ quotemeta B}$/;
		}
		where { $_ =~ N && $_ =~ M };
}

local ($::_g0 = do {"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"];}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"]; # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {"" . BeginAndEnd["Hi,", "!"]}, $::_e0 = "BeginAndEnd['Hi,', '!']"); ::ok $::_g0 eq $::_e0, '"" . BeginAndEnd["Hi,", "!"] # => BeginAndEnd[\'Hi,\', \'!\']' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## message ($code)
# 
# Используется с `subtype` для вывода сообщения об ошибке, если значение исключает тип. В `$code` используется: `SELF` - текущий тип, `ARGS`, `A`, `B`, `C`, `D` - аргументы типа (если есть) и проверочное значение в `$_`. Его можно преобразовать в строку с помощью `SELF->val_to_str($_)`.
# 
# ## coerce ($type, from => $from, via => $via)
# 
# Добавляет новое приведение (`$via`) к `$type` из `$from` типа.
# 
::done_testing; }; subtest 'coerce ($type, from => $from, via => $via)' => sub { 
BEGIN {subtype Four => where {4 eq $_}}

local ($::_g0 = do {"4a" ~~ Four}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"4a" ~~ Four # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {Four->coerce("4a")}, $::_e0 = do {"4a"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Four->coerce("4a") # -> "4a"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

coerce Four, from Str, via { 0+$_ };

local ($::_g0 = do {Four->coerce("4a")}, $::_e0 = do {4}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Four->coerce("4a")	# -> 4' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

coerce Four, from ArrayRef, via { scalar @$_ };

local ($::_g0 = do {Four->coerce([1,2,3])}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Four->coerce([1,2,3])           # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Four->coerce([1,2,3]) ~~ Four}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Four->coerce([1,2,3]) ~~ Four   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Four->coerce([1,2,3,4]) ~~ Four}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Four->coerce([1,2,3,4]) ~~ Four # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# `coerce` выбрасывает исключения:
# 

::like scalar do {eval {coerce Int, via1 => 1}; $@}, qr{coerce Int unused keys left: via1}, 'eval {coerce Int, via1 => 1}; $@  # ~> coerce Int unused keys left: via1'; undef $::_g0; undef $::_e0;
::like scalar do {eval {coerce "x"}; $@}, qr{coerce x not Aion::Type\!}, 'eval {coerce "x"}; $@  # ~> coerce x not Aion::Type!'; undef $::_g0; undef $::_e0;
::like scalar do {eval {coerce Int}; $@}, qr{coerce Int: from is'nt Aion::Type\!}, 'eval {coerce Int}; $@  # ~> coerce Int: from is\'nt Aion::Type!'; undef $::_g0; undef $::_e0;
::like scalar do {eval {coerce Int, from "x"}; $@}, qr{coerce Int: from is'nt Aion::Type\!}, 'eval {coerce Int, from "x"}; $@  # ~> coerce Int: from is\'nt Aion::Type!'; undef $::_g0; undef $::_e0;
::like scalar do {eval {coerce Int, from Num}; $@}, qr{coerce Int: via is not subroutine\!}, 'eval {coerce Int, from Num}; $@  # ~> coerce Int: via is not subroutine!'; undef $::_g0; undef $::_e0;
::like scalar do {eval {coerce Int, (from=>Num, via=>"x")}; $@}, qr{coerce Int: via is not subroutine\!}, 'eval {coerce Int, (from=>Num, via=>"x")}; $@  # ~> coerce Int: via is not subroutine!'; undef $::_g0; undef $::_e0;

# 
# Стандартные приведения:
# 

# Str from Undef — empty string
local ($::_g0 = do {Str->coerce(undef)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Str->coerce(undef) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Int from Num — rounded integer
local ($::_g0 = do {Int->coerce(2.5)}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Int->coerce(2.5)  # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Int->coerce(-2.5)}, $::_e0 = do {-3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Int->coerce(-2.5) # -> -3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Bool from Any — 1 or ""
local ($::_g0 = do {Bool->coerce([])}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Bool->coerce([]) # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Bool->coerce(0)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Bool->coerce(0)  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from ($type)
# 
# Синтаксический сахар для `coerce`.
# 
# ## via ($code)
# 
# Синтаксический сахар для `coerce`.
# 
# # ATTRIBUTES
# 
# ## :Isa (@signature)
# 
# Проверяет сигнатуру подпрограммы: аргументы и результаты.
# 
::done_testing; }; subtest ':Isa (@signature)' => sub { 
sub minint($$) : Isa(Int => Int => Int) {
	my ($x, $y) = @_;
	$x < $y? $x : $y
}

local ($::_g0 = do {minint 6, 5;}, $::_e0 = do {5}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'minint 6, 5; # -> 5' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {eval {minint 5.5, 2}; $@}, qr{Arguments of method `minint` must have the type Tuple\[Int, Int\]\.}, 'eval {minint 5.5, 2}; $@ # ~> Arguments of method `minint` must have the type Tuple\[Int, Int\]\.'; undef $::_g0; undef $::_e0;

sub half($) : Isa(Int => Int) {
	my ($x) = @_;
	$x / 2
}

local ($::_g0 = do {half 4;}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'half 4; # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {eval {half 5}; $@}, qr{Return of method `half` must have the type Int. The it is 2.5}, 'eval {half 5}; $@ # ~> Return of method `half` must have the type Int. The it is 2.5'; undef $::_g0; undef $::_e0;

# 
# # TYPES
# 
# ## Any
# 
# Тип верхнего уровня в иерархии. Сопоставляет всё.
# 
# ## Control
# 
# Тип верхнего уровня в конструкторах иерархии создает новые типы из любых типов.
# 
# ## Union[A, B...]
# 
# Союз нескольких типов. Аналогичен оператору `$type1 | $type2`.
# 
::done_testing; }; subtest 'Union[A, B...]' => sub { 
local ($::_g0 = do {33  ~~ Union[Int, Ref]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '33  ~~ Union[Int, Ref] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[]  ~~ Union[Int, Ref]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[]  ~~ Union[Int, Ref]	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"a" ~~ Union[Int, Ref]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"a" ~~ Union[Int, Ref]	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Intersection[A, B...]
# 
# Пересечение нескольких типов. Аналогичен оператору `$type1 & $type2`.
# 
::done_testing; }; subtest 'Intersection[A, B...]' => sub { 
local ($::_g0 = do {15 ~~ Intersection[Int, StrMatch[/5/]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '15 ~~ Intersection[Int, StrMatch[/5/]] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Exclude[A, B...]
# 
# Исключение нескольких типов. Аналогичен оператору `~ $type`.
# 
::done_testing; }; subtest 'Exclude[A, B...]' => sub { 
local ($::_g0 = do {-5  ~~ Exclude[PositiveInt]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-5  ~~ Exclude[PositiveInt] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"a" ~~ Exclude[PositiveInt]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"a" ~~ Exclude[PositiveInt] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5   ~~ Exclude[PositiveInt]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5   ~~ Exclude[PositiveInt] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5.5 ~~ Exclude[PositiveInt]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5.5 ~~ Exclude[PositiveInt] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Если `Exclude` имеет много аргументов, то это аналог `~ ($type1 | $type2 ...)`.
# 

local ($::_g0 = do {-5  ~~ Exclude[PositiveInt, Enum[-2]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-5  ~~ Exclude[PositiveInt, Enum[-2]] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-2  ~~ Exclude[PositiveInt, Enum[-2]]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-2  ~~ Exclude[PositiveInt, Enum[-2]] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0   ~~ Exclude[PositiveInt, Enum[-2]]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0   ~~ Exclude[PositiveInt, Enum[-2]] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Option[A]
# 
# Дополнительные ключи в `Dict`.
# 
::done_testing; }; subtest 'Option[A]' => sub { 
local ($::_g0 = do {{a=>55} ~~ Dict[a=>Int, b => Option[Int]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a=>55} ~~ Dict[a=>Int, b => Option[Int]]          # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Wantarray[A, S]
# 
# Если подпрограмма возвращает разные значения в контексте массива и скаляра, то используется тип `Wantarray` с типом `A` для контекста массива и типом `S` для скалярного контекста.
# 
::done_testing; }; subtest 'Wantarray[A, S]' => sub { 
sub arr : Isa(PositiveInt => Wantarray[ArrayRef[PositiveInt], PositiveInt]) {
	my ($n) = @_;
	wantarray? 1 .. $n: $n
}

my @a = arr(3);
my $s = arr(3);

local ($::_g0 = do {\@a}, $::_e0 = do {[1,2,3]}); ::is_deeply $::_g0, $::_e0, '\@a # --> [1,2,3]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$s}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$s  # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Item
# 
# Тип верхнего уровня в иерархии скалярных типов.
# 
# ## Bool
# 
# `1` is true. `0`, `""` or `undef` is false.
# 
::done_testing; }; subtest 'Bool' => sub { 
local ($::_g0 = do {1 ~~ Bool}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ Bool  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ Bool}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ Bool  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {undef ~~ Bool}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'undef ~~ Bool # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ Bool}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ Bool # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {2 ~~ Bool}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2 ~~ Bool  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[] ~~ Bool}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ Bool # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Enum[A...]
# 
# Перечисление.
# 
::done_testing; }; subtest 'Enum[A...]' => sub { 
local ($::_g0 = do {3 ~~ Enum[1,2,3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ Enum[1,2,3]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"cat" ~~ Enum["cat", "dog"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"cat" ~~ Enum["cat", "dog"] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {4 ~~ Enum[1,2,3]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '4 ~~ Enum[1,2,3]   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Maybe[A]
# 
# `undef` или тип в `[]`.
# 
::done_testing; }; subtest 'Maybe[A]' => sub { 
local ($::_g0 = do {undef ~~ Maybe[Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'undef ~~ Maybe[Int] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {4 ~~ Maybe[Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '4 ~~ Maybe[Int]     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ Maybe[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ Maybe[Int]    # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Undef
# 
# Только `undef`.
# 
::done_testing; }; subtest 'Undef' => sub { 
local ($::_g0 = do {undef ~~ Undef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'undef ~~ Undef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ Undef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ Undef     # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Defined
# 
# Всё за исключением `undef`.
# 
::done_testing; }; subtest 'Defined' => sub { 
local ($::_g0 = do {\0 ~~ Defined}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\0 ~~ Defined    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {undef ~~ Defined}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'undef ~~ Defined # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Value
# 
# Определённые значения без ссылок.
# 
::done_testing; }; subtest 'Value' => sub { 
local ($::_g0 = do {3 ~~ Value}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ Value  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\3 ~~ Value}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\3 ~~ Value    # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {undef ~~ Value}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'undef ~~ Value # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Len[A, B?]
# 
# Определяет значение длины от `A` до `B` или от 0 до `A`, если `B` отсутствует.
# 
::done_testing; }; subtest 'Len[A, B?]' => sub { 
local ($::_g0 = do {"1234" ~~ Len[3]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"1234" ~~ Len[3]   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"123" ~~ Len[3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"123" ~~ Len[3]    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"12" ~~ Len[3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"12" ~~ Len[3]     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ Len[1, 2]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ Len[1, 2]    # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"1" ~~ Len[1, 2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"1" ~~ Len[1, 2]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"12" ~~ Len[1, 2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"12" ~~ Len[1, 2]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"123" ~~ Len[1, 2]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"123" ~~ Len[1, 2] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Version
# 
# Perl версии.
# 
::done_testing; }; subtest 'Version' => sub { 
local ($::_g0 = do {1.1.0 ~~ Version}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1.1.0 ~~ Version   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {v1.1.0 ~~ Version}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'v1.1.0 ~~ Version  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {v1.1 ~~ Version}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'v1.1 ~~ Version    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {v1 ~~ Version}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'v1 ~~ Version      # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1.1 ~~ Version}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1.1 ~~ Version     # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"1.1.0" ~~ Version}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"1.1.0" ~~ Version # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Str
# 
# Строки, включая числа.
# 
::done_testing; }; subtest 'Str' => sub { 
local ($::_g0 = do {1.1 ~~ Str}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1.1 ~~ Str   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ Str}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ Str    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1.1.0 ~~ Str}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1.1.0 ~~ Str # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Uni
# 
# Строки Unicode с флагом utf8 или если декодирование в utf8 происходит без ошибок.
# 
::done_testing; }; subtest 'Uni' => sub { 
local ($::_g0 = do {"↭" ~~ Uni}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"↭" ~~ Uni # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {123 ~~ Uni}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '123 ~~ Uni # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {do {no utf8; "↭" ~~ Uni}}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'do {no utf8; "↭" ~~ Uni} # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Bin
# 
# Бинарные строки без флага utf8 и октетов с номерами меньше 128.
# 
::done_testing; }; subtest 'Bin' => sub { 
local ($::_g0 = do {123 ~~ Bin}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '123 ~~ Bin # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"z" ~~ Bin}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"z" ~~ Bin # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"↭" ~~ Bin}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"↭" ~~ Bin # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {do {no utf8; "↭" ~~ Bin }}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'do {no utf8; "↭" ~~ Bin }   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## StartsWith\[S]
# 
# Строка начинается с `S`.
# 
::done_testing; }; subtest 'StartsWith\[S]' => sub { 
local ($::_g0 = do {"Hi, world!" ~~ StartsWith["Hi,"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Hi, world!" ~~ StartsWith["Hi,"] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"Hi world!" ~~ StartsWith["Hi,"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Hi world!" ~~ StartsWith["Hi,"] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## EndsWith\[S]
# 
# Строка заканчивается на `S`.
# 
::done_testing; }; subtest 'EndsWith\[S]' => sub { 
local ($::_g0 = do {"Hi, world!" ~~ EndsWith["world!"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Hi, world!" ~~ EndsWith["world!"] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"Hi, world" ~~ EndsWith["world!"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Hi, world" ~~ EndsWith["world!"]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## NonEmptyStr
# 
# Строка с одним или несколькими символами, не являющимися пробелами.
# 
::done_testing; }; subtest 'NonEmptyStr' => sub { 
local ($::_g0 = do {" " ~~ NonEmptyStr}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '" " ~~ NonEmptyStr              # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {" S " ~~ NonEmptyStr}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '" S " ~~ NonEmptyStr            # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {" S " ~~ (NonEmptyStr & Len[2])}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '" S " ~~ (NonEmptyStr & Len[2]) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Email
# 
# Строки с `@`.
# 
::done_testing; }; subtest 'Email' => sub { 
local ($::_g0 = do {'@' ~~ Email}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'@\' ~~ Email     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'a@a.a' ~~ Email}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'a@a.a\' ~~ Email # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'a.a' ~~ Email}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'a.a\' ~~ Email   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Tel
# 
# Формат телефонов — знак плюс и семь или больше цифр.
# 
::done_testing; }; subtest 'Tel' => sub { 
local ($::_g0 = do {"+1234567" ~~ Tel}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"+1234567" ~~ Tel # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"+1234568" ~~ Tel}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"+1234568" ~~ Tel # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"+ 1234567" ~~ Tel}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"+ 1234567" ~~ Tel # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"+1234567 " ~~ Tel}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"+1234567 " ~~ Tel # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Url
# 
# URL-адреса веб-сайтов — это строка с префиксом http:// или https://.
# 
::done_testing; }; subtest 'Url' => sub { 
local ($::_g0 = do {"http://" ~~ Url}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"http://" ~~ Url # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"http:/" ~~ Url}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"http:/" ~~ Url  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Path
# 
# Пути начинаются с косой черты.
# 
::done_testing; }; subtest 'Path' => sub { 
local ($::_g0 = do {"/" ~~ Path}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"/" ~~ Path  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"/a/b" ~~ Path}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"/a/b" ~~ Path  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"a/b" ~~ Path}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"a/b" ~~ Path   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Html
# 
# HTML начинается с `<!doctype html` или `<html`.
# 
::done_testing; }; subtest 'Html' => sub { 
local ($::_g0 = do {"<HTML" ~~ Html}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"<HTML" ~~ Html   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {" <html" ~~ Html}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '" <html" ~~ Html     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {" <!doctype html>" ~~ Html}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '" <!doctype html>" ~~ Html # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {" <html1>" ~~ Html}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '" <html1>" ~~ Html   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## StrDate
# 
# Дата в формате `yyyy-mm-dd`.
# 
::done_testing; }; subtest 'StrDate' => sub { 
local ($::_g0 = do {"2001-01-12" ~~ StrDate}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"2001-01-12" ~~ StrDate # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"01-01-01" ~~ StrDate}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"01-01-01" ~~ StrDate   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## StrDateTime
# 
# Дата и время в формате `yyyy-mm-dd HH:MM:SS`.
# 
::done_testing; }; subtest 'StrDateTime' => sub { 
local ($::_g0 = do {"2012-12-01 00:00:00" ~~ StrDateTime}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"2012-12-01 00:00:00" ~~ StrDateTime  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"2012-12-01 00:00:00 " ~~ StrDateTime}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"2012-12-01 00:00:00 " ~~ StrDateTime # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## StrMatch[qr/.../]
# 
# Сопоставляет строку с регулярным выражением.
# 
::done_testing; }; subtest 'StrMatch[qr/.../]' => sub { 
local ($::_g0 = do {' abc ' ~~ StrMatch[qr/abc/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\' abc \' ~~ StrMatch[qr/abc/]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {' abbc ' ~~ StrMatch[qr/abc/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\' abbc \' ~~ StrMatch[qr/abc/] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ClassName
# 
# Имя класса — это пакет с методом `new`.
# 
::done_testing; }; subtest 'ClassName' => sub { 
local ($::_g0 = do {'Aion::Type' ~~ ClassName}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Aion::Type\' ~~ ClassName  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Aion::Types' ~~ ClassName}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Aion::Types\' ~~ ClassName # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## RoleName
# 
# Имя роли — это пакет без метода `new`, с `@ISA` или с одним любым методом.
# 
::done_testing; }; subtest 'RoleName' => sub { 
package ExRole1 {
	sub any_method {}
}

package ExRole2 {
	our @ISA = qw/ExRole1/;
}


local ($::_g0 = do {'ExRole1' ~~ RoleName}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'ExRole1\' ~~ RoleName    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'ExRole2' ~~ RoleName}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'ExRole2\' ~~ RoleName    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Aion::Type' ~~ RoleName}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Aion::Type\' ~~ RoleName # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Nouname::Empty::Package' ~~ RoleName}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Nouname::Empty::Package\' ~~ RoleName # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Rat
# 
# Рациональные числа.
# 
::done_testing; }; subtest 'Rat' => sub { 
local ($::_g0 = do {"6/7" ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"6/7" ~~ Rat  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"-6/7" ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"-6/7" ~~ Rat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {6 ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '6 ~~ Rat      # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"inf" ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"inf" ~~ Rat  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"+Inf" ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"+Inf" ~~ Rat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"NaN" ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"NaN" ~~ Rat  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"-nan" ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"-nan" ~~ Rat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {6.5 ~~ Rat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '6.5 ~~ Rat    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"6.5 " ~~ Rat}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"6.5 " ~~ Rat # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Num
# 
# Числа.
# 
::done_testing; }; subtest 'Num' => sub { 
local ($::_g0 = do {-6.5 ~~ Num}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-6.5 ~~ Num   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {6.5e-7 ~~ Num}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '6.5e-7 ~~ Num # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"6.5 " ~~ Num}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"6.5 " ~~ Num # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveNum
# 
# Положительные числа.
# 
::done_testing; }; subtest 'PositiveNum' => sub { 
local ($::_g0 = do {0 ~~ PositiveNum}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ PositiveNum    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0.1 ~~ PositiveNum}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0.1 ~~ PositiveNum  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-0.1 ~~ PositiveNum}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-0.1 ~~ PositiveNum # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-0 ~~ PositiveNum}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-0 ~~ PositiveNum   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Float
# 
# Машинное число с плавающей запятой составляет 4 байта.
# 
::done_testing; }; subtest 'Float' => sub { 
local ($::_g0 = do {-4.8 ~~ Float}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-4.8 ~~ Float             # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-3.402823466E+38 ~~ Float}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-3.402823466E+38 ~~ Float # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {+3.402823466E+38 ~~ Float}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '+3.402823466E+38 ~~ Float # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-3.402823467E+38 ~~ Float}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-3.402823467E+38 ~~ Float # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Double
# 
# Машинное число с плавающей запятой составляет 8 байт.
# 
::done_testing; }; subtest 'Double' => sub { 
use Scalar::Util qw//;

local ($::_g0 = do {-4.8 ~~ Double}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '                      -4.8 ~~ Double # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'-1.7976931348623157e+308' ~~ Double}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'-1.7976931348623157e+308\' ~~ Double # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'+1.7976931348623157e+308' ~~ Double}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'+1.7976931348623157e+308\' ~~ Double # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'-1.7976931348623159e+308' ~~ Double}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'-1.7976931348623159e+308\' ~~ Double # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Range[from, to]
# 
# Числа между `from` и `to`.
# 
::done_testing; }; subtest 'Range[from, to]' => sub { 
local ($::_g0 = do {1 ~~ Range[1, 3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ Range[1, 3]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {2.5 ~~ Range[1, 3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2.5 ~~ Range[1, 3] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {3 ~~ Range[1, 3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3 ~~ Range[1, 3]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {3.1 ~~ Range[1, 3]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '3.1 ~~ Range[1, 3] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0.9 ~~ Range[1, 3]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0.9 ~~ Range[1, 3] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Int
# 
# Целые числа.
# 
::done_testing; }; subtest 'Int' => sub { 
local ($::_g0 = do {123 ~~ Int}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '123 ~~ Int	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-12 ~~ Int}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-12 ~~ Int	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {5.5 ~~ Int}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5.5 ~~ Int	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Bytes[N]
# 
# Рассчитывает максимальное и минимальное числа, которые поместятся в `N` байт и проверяет ограничение между ними.
# 
::done_testing; }; subtest 'Bytes[N]' => sub { 
local ($::_g0 = do {-129 ~~ Bytes[1]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-129 ~~ Bytes[1] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-128 ~~ Bytes[1]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-128 ~~ Bytes[1] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {127 ~~ Bytes[1]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '127 ~~ Bytes[1]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {128 ~~ Bytes[1]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '128 ~~ Bytes[1]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 2 bits power of (8 bits * 8 bytes - 1)
my $N = 1 << (8*8-1);
local ($::_g0 = do {(-$N-1) ~~ Bytes[8]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '(-$N-1) ~~ Bytes[8] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {(-$N) ~~ Bytes[8]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '(-$N) ~~ Bytes[8]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {($N-1) ~~ Bytes[8]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '($N-1) ~~ Bytes[8]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$N ~~ Bytes[8]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$N ~~ Bytes[8]      # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

require Math::BigInt;

my $N17 = 1 << (8*Math::BigInt->new(17) - 1);

local ($::_g0 = do {((-$N17-1) . "") ~~ Bytes[17]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '((-$N17-1) . "") ~~ Bytes[17] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {(-$N17 . "") ~~ Bytes[17]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '(-$N17 . "") ~~ Bytes[17]     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {(($N17-1) . "") ~~ Bytes[17]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '(($N17-1) . "") ~~ Bytes[17]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {($N17 . "") ~~ Bytes[17]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '($N17 . "") ~~ Bytes[17]      # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveInt
# 
# Положительные целые числа.
# 
::done_testing; }; subtest 'PositiveInt' => sub { 
local ($::_g0 = do {+0 ~~ PositiveInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '+0 ~~ PositiveInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-0 ~~ PositiveInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-0 ~~ PositiveInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {55 ~~ PositiveInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '55 ~~ PositiveInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-1 ~~ PositiveInt}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ PositiveInt # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveBytes[N]
# 
# Рассчитывает максимальное число, которое поместится в `N` байт (полагая, что в байтах нет отрицательного бита) и проверяет ограничение от 0 до этого числа.
# 
::done_testing; }; subtest 'PositiveBytes[N]' => sub { 
local ($::_g0 = do {-1 ~~ PositiveBytes[1]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ PositiveBytes[1]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ PositiveBytes[1]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ PositiveBytes[1]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {255 ~~ PositiveBytes[1]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '255 ~~ PositiveBytes[1] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {256 ~~ PositiveBytes[1]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '256 ~~ PositiveBytes[1] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {-1 ~~ PositiveBytes[8]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ PositiveBytes[8]   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1.01 ~~ PositiveBytes[8]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1.01 ~~ PositiveBytes[8] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ PositiveBytes[8]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ PositiveBytes[8]    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $N8 = 2 ** (8*Math::BigInt->new(8)) - 1;

local ($::_g0 = do {$N8 . "" ~~ PositiveBytes[8]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$N8 . "" ~~ PositiveBytes[8]     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {($N8+1) . "" ~~ PositiveBytes[8]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '($N8+1) . "" ~~ PositiveBytes[8] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {-1 ~~ PositiveBytes[17]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ PositiveBytes[17] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ PositiveBytes[17]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ PositiveBytes[17]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Nat
# 
# Целые числа 1+.
# 
::done_testing; }; subtest 'Nat' => sub { 
local ($::_g0 = do {0 ~~ Nat}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ Nat	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1 ~~ Nat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ Nat	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Ref
# 
# Ссылка.
# 
::done_testing; }; subtest 'Ref' => sub { 
local ($::_g0 = do {\1 ~~ Ref}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ Ref # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[] ~~ Ref}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ Ref # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1 ~~ Ref}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ Ref  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Tied`[A]
# 
# Ссылка на связанную переменную.
# 
::done_testing; }; subtest 'Tied`[A]' => sub { 
package TiedHash { sub TIEHASH { bless {@_}, shift } }
package TiedArray { sub TIEARRAY { bless {@_}, shift } }
package TiedScalar { sub TIESCALAR { bless {@_}, shift } }

tie my %a, "TiedHash";
tie my @a, "TiedArray";
tie my $a, "TiedScalar";
my %b; my @b; my $b;

local ($::_g0 = do {\%a ~~ Tied}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%a ~~ Tied # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@a ~~ Tied}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\@a ~~ Tied # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\$a ~~ Tied}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\$a ~~ Tied # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {\%b ~~ Tied}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%b ~~ Tied  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@b ~~ Tied}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\@b ~~ Tied  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\$b ~~ Tied}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\$b ~~ Tied  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\\$b ~~ Tied}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\\$b ~~ Tied # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {ref tied %a}, $::_e0 = "TiedHash"); ::ok $::_g0 eq $::_e0, 'ref tied %a     # => TiedHash' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ref tied %{\%a}}, $::_e0 = "TiedHash"); ::ok $::_g0 eq $::_e0, 'ref tied %{\%a} # => TiedHash' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {\%a ~~ Tied["TiedHash"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%a ~~ Tied["TiedHash"]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@a ~~ Tied["TiedArray"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\@a ~~ Tied["TiedArray"]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\$a ~~ Tied["TiedScalar"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\$a ~~ Tied["TiedScalar"] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {\%a ~~ Tied["TiedArray"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%a ~~ Tied["TiedArray"]   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@a ~~ Tied["TiedScalar"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\@a ~~ Tied["TiedScalar"]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\$a ~~ Tied["TiedHash"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\$a ~~ Tied["TiedHash"]    # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\\$a ~~ Tied["TiedScalar"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\\$a ~~ Tied["TiedScalar"] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## LValueRef
# 
# Функция позволяет присваивание.
# 
::done_testing; }; subtest 'LValueRef' => sub { 
local ($::_g0 = do {ref \substr("abc", 1, 2)}, $::_e0 = "LVALUE"); ::ok $::_g0 eq $::_e0, 'ref \substr("abc", 1, 2) # => LVALUE' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ref \vec(42, 1, 2)}, $::_e0 = "LVALUE"); ::ok $::_g0 eq $::_e0, 'ref \vec(42, 1, 2) # => LVALUE' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {\substr("abc", 1, 2) ~~ LValueRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\substr("abc", 1, 2) ~~ LValueRef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\vec(42, 1, 2) ~~ LValueRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\vec(42, 1, 2) ~~ LValueRef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Но с `:lvalue` не работает.
# 

sub abc: lvalue { $_ }

abc() = 12;
local ($::_g0 = do {$_}, $::_e0 = "12"); ::ok $::_g0 eq $::_e0, '$_ # => 12' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ref \abc()}, $::_e0 = "SCALAR"); ::ok $::_g0 eq $::_e0, 'ref \abc()  # => SCALAR' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\abc() ~~ LValueRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\abc() ~~ LValueRef	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;


package As {
	sub x : lvalue {
		shift->{x};
	}
}

my $x = bless {}, "As";
$x->x = 10;

local ($::_g0 = do {$x->x}, $::_e0 = "10"); ::ok $::_g0 eq $::_e0, '$x->x # => 10' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$x}, $::_e0 = do {bless {x=>10}, "As"}); ::is_deeply $::_g0, $::_e0, '$x	# --> bless {x=>10}, "As"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {ref \$x->x}, $::_e0 = "SCALAR"); ::ok $::_g0 eq $::_e0, 'ref \$x->x			 # => SCALAR' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\$x->x ~~ LValueRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\$x->x ~~ LValueRef # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# And on the end:
# 

local ($::_g0 = do {\1 ~~ LValueRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ LValueRef	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $x = "abc";
substr($x, 1, 1) = 10;

local ($::_g0 = do {$x}, $::_e0 = "a10c"); ::ok $::_g0 eq $::_e0, '$x # => a10c' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {LValueRef->include( \substr($x, 1, 1) )}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, 'LValueRef->include( \substr($x, 1, 1) )	# => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## FormatRef
# 
# Формат.
# 
::done_testing; }; subtest 'FormatRef' => sub { 
format EXAMPLE_FMT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

local ($::_g0 = do {*EXAMPLE_FMT{FORMAT} ~~ FormatRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\1 ~~ FormatRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ FormatRef				# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## CodeRef`[name, proto]
# 
# Подпрограмма.
# 
::done_testing; }; subtest 'CodeRef`[name, proto]' => sub { 
local ($::_g0 = do {sub {} ~~ CodeRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sub {} ~~ CodeRef	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\1 ~~ CodeRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ CodeRef		# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

sub code_ex ($;$) { ... }

local ($::_g0 = do {\&code_ex ~~ CodeRef['main::code_ex']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[\'main::code_ex\']         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef['code_ex']}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[\'code_ex\']               # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef[qr/_/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[qr/_/]                   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef[undef, '$;$']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[undef, \'$;$\']            # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef[undef, '@']}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[undef, \'@\']              # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef['main::code_ex', '$;$']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[\'main::code_ex\', \'$;$\']  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# 
# ## ReachableCodeRef`[name, proto]
# 
# Подпрограмма с телом.
# 
::done_testing; }; subtest 'ReachableCodeRef`[name, proto]' => sub { 
sub code_forward ($;$);

local ($::_g0 = do {\&code_ex ~~ ReachableCodeRef['main::code_ex']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ ReachableCodeRef[\'main::code_ex\']        # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ ReachableCodeRef['code_ex']}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ ReachableCodeRef[\'code_ex\']              # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ ReachableCodeRef[qr/_/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ ReachableCodeRef[qr/_/]                  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ ReachableCodeRef[undef, '$;$']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ ReachableCodeRef[undef, \'$;$\']           # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ ReachableCodeRef[undef, '@']}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ ReachableCodeRef[undef, \'@\']             # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ ReachableCodeRef['main::code_ex', '$;$']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ ReachableCodeRef[\'main::code_ex\', \'$;$\'] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {\&code_forward ~~ ReachableCodeRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_forward ~~ ReachableCodeRef # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## UnreachableCodeRef`[name, proto]
# 
# Подпрограмма без тела.
# 
::done_testing; }; subtest 'UnreachableCodeRef`[name, proto]' => sub { 
local ($::_g0 = do {\&nouname ~~ UnreachableCodeRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&nouname ~~ UnreachableCodeRef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_ex ~~ UnreachableCodeRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_ex ~~ UnreachableCodeRef # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&code_forward ~~ UnreachableCodeRef['main::code_forward', '$;$']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&code_forward ~~ UnreachableCodeRef[\'main::code_forward\', \'$;$\'] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Isa[A...]
# 
# Ссылка на подпрограмму с соответствующей сигнатурой.
# 
::done_testing; }; subtest 'Isa[A...]' => sub { 
sub sig_ex :Isa(Int => Str) {}

local ($::_g0 = do {\&sig_ex ~~ Isa[Int => Str]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&sig_ex ~~ Isa[Int => Str]        # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&sig_ex ~~ Isa[Int => Str => Num]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&sig_ex ~~ Isa[Int => Str => Num] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&sig_ex ~~ Isa[Int => Num]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&sig_ex ~~ Isa[Int => Num]        # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Подпрограммы без тела не оборачиваются в обработчик сигнатуры, а сигнатура запоминается для валидации соответствия впоследствии объявленной подпрограммы с телом. Поэтому функция не имеет сигнатуры.
# 

sub unreachable_sig_ex :Isa(Int => Str);

local ($::_g0 = do {\&unreachable_sig_ex ~~ Isa[Int => Str]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&unreachable_sig_ex ~~ Isa[Int => Str] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## RegexpRef
# 
# Регулярное выражение.
# 
::done_testing; }; subtest 'RegexpRef' => sub { 
local ($::_g0 = do {qr// ~~ RegexpRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'qr// ~~ RegexpRef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\1 ~~ RegexpRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ RegexpRef   # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ScalarRefRef`[A]
# 
# Ссылка на скаляр или ссылка на ссылку.
# 
::done_testing; }; subtest 'ScalarRefRef`[A]' => sub { 
local ($::_g0 = do {\12    ~~ ScalarRefRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\12    ~~ ScalarRefRef                    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\12    ~~ ScalarRefRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\12    ~~ ScalarRefRef                    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\-1.2  ~~ ScalarRefRef[Num]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\-1.2  ~~ ScalarRefRef[Num]               # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\\-1.2 ~~ ScalarRefRef[ScalarRefRef[Num]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\\-1.2 ~~ ScalarRefRef[ScalarRefRef[Num]] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ScalarRef`[A]
# 
# Ссылка на скаляр.
# 
::done_testing; }; subtest 'ScalarRef`[A]' => sub { 
local ($::_g0 = do {\12   ~~ ScalarRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\12   ~~ ScalarRef      # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\\12  ~~ ScalarRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\\12  ~~ ScalarRef      # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\-1.2 ~~ ScalarRef[Num]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\-1.2 ~~ ScalarRef[Num] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## RefRef`[A]
# 
# Ссылка на ссылку.
# 
::done_testing; }; subtest 'RefRef`[A]' => sub { 
local ($::_g0 = do {\12    ~~ RefRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\12    ~~ RefRef                 # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\\12   ~~ RefRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\\12   ~~ RefRef                 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\-1.2  ~~ RefRef[Num]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\-1.2  ~~ RefRef[Num]            # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\\-1.2 ~~ RefRef[ScalarRef[Num]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\\-1.2 ~~ RefRef[ScalarRef[Num]] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## GlobRef
# 
# Ссылка на глоб.
# 
::done_testing; }; subtest 'GlobRef' => sub { 
local ($::_g0 = do {\*A::a ~~ GlobRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\*A::a ~~ GlobRef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {*A::a ~~ GlobRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '*A::a ~~ GlobRef  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## FileHandle
# 
# Файловый описатель.
# 
::done_testing; }; subtest 'FileHandle' => sub { 
local ($::_g0 = do {\*A::a ~~ FileHandle}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\*A::a ~~ FileHandle         # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\*STDIN ~~ FileHandle}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\*STDIN ~~ FileHandle        # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

open my $fh, "<", "/dev/null";
local ($::_g0 = do {$fh ~~ FileHandle}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$fh ~~ FileHandle	         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
close $fh;

opendir my $dh, ".";
local ($::_g0 = do {$dh ~~ FileHandle}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$dh ~~ FileHandle	         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
closedir $dh;

use constant { PF_UNIX => 1, SOCK_STREAM => 1 };

socket my $sock, PF_UNIX, SOCK_STREAM, 0;
local ($::_g0 = do {$sock ~~ FileHandle}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sock ~~ FileHandle	         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
close $sock;

# 
# ## ArrayRef`[A]
# 
# Ссылки на массивы.
# 
::done_testing; }; subtest 'ArrayRef`[A]' => sub { 
local ($::_g0 = do {[] ~~ ArrayRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ ArrayRef	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{} ~~ ArrayRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ ArrayRef	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[] ~~ ArrayRef[Num]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ ArrayRef[Num]	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{} ~~ ArrayRef[Num]}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ ArrayRef[Num]	# -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[1, 1.1] ~~ ArrayRef[Num]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1, 1.1] ~~ ArrayRef[Num]	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[1, undef] ~~ ArrayRef[Num]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1, undef] ~~ ArrayRef[Num]	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Lim[A, B?]
# 
# Ограничивает массивы от `A` до `B` элементов или от 0 до `A`, если `B` отсутствует.
# 
::done_testing; }; subtest 'Lim[A, B?]' => sub { 
local ($::_g0 = do {[] ~~ Lim[5]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ Lim[5]     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[1..5] ~~ Lim[5]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1..5] ~~ Lim[5] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[1..6] ~~ Lim[5]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1..6] ~~ Lim[5] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[1..5] ~~ Lim[1,5]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1..5] ~~ Lim[1,5] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[1..6] ~~ Lim[1,5]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1..6] ~~ Lim[1,5] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[1] ~~ Lim[1,5]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[1] ~~ Lim[1,5] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[] ~~ Lim[1,5]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ Lim[1,5]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## HashRef`[H]
# 
# Ссылки на хеши.
# 
::done_testing; }; subtest 'HashRef`[H]' => sub { 
local ($::_g0 = do {{} ~~ HashRef}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ HashRef # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\1 ~~ HashRef}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ HashRef # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[]  ~~ HashRef[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[]  ~~ HashRef[Int]           # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{x=>1, y=>2}  ~~ HashRef[Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{x=>1, y=>2}  ~~ HashRef[Int] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{x=>1, y=>""} ~~ HashRef[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{x=>1, y=>""} ~~ HashRef[Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Object`[O]
# 
# Благословлённые ссылки.
# 
::done_testing; }; subtest 'Object`[O]' => sub { 
local ($::_g0 = do {bless(\(my $val=10), "A1") ~~ Object}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $val=10), "A1") ~~ Object # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\(my $val=10) ~~ Object}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\(my $val=10) ~~ Object              # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {bless(\(my $val=10), "A1") ~~ Object["A1"]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $val=10), "A1") ~~ Object["A1"] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless(\(my $val=10), "A1") ~~ Object["B1"]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $val=10), "A1") ~~ Object["B1"] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Me
# 
# Благословенные ссылки на объекты текущего пакета.
# 
::done_testing; }; subtest 'Me' => sub { 
package A1 {
 use Aion;
local ($::_g0 = do {bless({}, __PACKAGE__) ~~ Me}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, ' bless({}, __PACKAGE__) ~~ Me  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "A2") ~~ Me}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, ' bless({}, "A2") ~~ Me         # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

# 
# ## Map[K, V]
# 
# Как `HashRef`, но с типом для ключей.
# 
::done_testing; }; subtest 'Map[K, V]' => sub { 
local ($::_g0 = do {{} ~~ Map[Int, Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ Map[Int, Int]               # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{5 => 3} ~~ Map[Int, Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{5 => 3} ~~ Map[Int, Int]         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {+{5.5 => 3} ~~ Map[Int, Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '+{5.5 => 3} ~~ Map[Int, Int]      # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{5 => 3.3} ~~ Map[Int, Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{5 => 3.3} ~~ Map[Int, Int]       # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{5 => 3, 6 => 7} ~~ Map[Int, Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{5 => 3, 6 => 7} ~~ Map[Int, Int] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Tuple[A...]
# 
# Тьюпл.
# 
::done_testing; }; subtest 'Tuple[A...]' => sub { 
local ($::_g0 = do {["a", 12] ~~ Tuple[Str, Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", 12] ~~ Tuple[Str, Int]    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {["a", 12, 1] ~~ Tuple[Str, Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", 12, 1] ~~ Tuple[Str, Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {["a", 12.1] ~~ Tuple[Str, Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", 12.1] ~~ Tuple[Str, Int]  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## CycleTuple[A...]
# 
# Тьюпл повторённый один или несколько раз.
# 
::done_testing; }; subtest 'CycleTuple[A...]' => sub { 
local ($::_g0 = do {["a", -5] ~~ CycleTuple[Str, Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", -5] ~~ CycleTuple[Str, Int] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {["a", -5, "x"] ~~ CycleTuple[Str, Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", -5, "x"] ~~ CycleTuple[Str, Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {["a", -5, "x", -6] ~~ CycleTuple[Str, Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", -5, "x", -6] ~~ CycleTuple[Str, Int] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Dict[k => A, ...]
# 
# Словарь.
# 
::done_testing; }; subtest 'Dict[k => A, ...]' => sub { 
local ($::_g0 = do {{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{a => -1.6} ~~ Dict[a => Num, b => Str]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => -1.6} ~~ Dict[a => Num, b => Str] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => -1.6} ~~ Dict[a => Num, b => Option[Str]] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## HasProp[p...]
# 
# Хэш имеет перечисленные свойства. Кроме них он может иметь и другие.
# 
::done_testing; }; subtest 'HasProp[p...]' => sub { 
local ($::_g0 = do {[0, 1] ~~ HasProp[qw/0 1/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[0, 1] ~~ HasProp[qw/0 1/] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{a => 1, b => 2} ~~ HasProp[qw/a b/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => 1, b => 2} ~~ HasProp[qw/a b/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{a => 1, c => 3} ~~ HasProp[qw/a b/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{a => 1, c => 3} ~~ HasProp[qw/a b/] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Like
# 
# Объект или строка.
# 
::done_testing; }; subtest 'Like' => sub { 
local ($::_g0 = do {"" ~~ Like}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ Like # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1 ~~ Like}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ Like  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "A") ~~ Like}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "A") ~~ Like # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless([], "A") ~~ Like}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless([], "A") ~~ Like # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless(\(my $str = ""), "A") ~~ Like}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $str = ""), "A") ~~ Like # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\1 ~~ Like}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\1 ~~ Like  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## HasMethods[m...]
# 
# Объект или класс имеет перечисленные методы. Кроме них может иметь и другие.
# 
::done_testing; }; subtest 'HasMethods[m...]' => sub { 
package HasMethodsExample {
	sub x1 {}
	sub x2 {}
}

local ($::_g0 = do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]			# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"HasMethodsExample" ~~ HasMethods[qw/x3/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"HasMethodsExample" ~~ HasMethods[qw/x3/]				# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]			# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]			# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Overload`[op...]
# 
# Объект или класс с перегруженными операторами.
# 
::done_testing; }; subtest 'Overload`[op...]' => sub { 
package OverloadExample {
	use overload '""' => sub { "abc" };
}

local ($::_g0 = do {"OverloadExample" ~~ Overload}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"OverloadExample" ~~ Overload            # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "OverloadExample") ~~ Overload}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "OverloadExample") ~~ Overload # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"A" ~~ Overload}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"A" ~~ Overload                          # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "A") ~~ Overload}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "A") ~~ Overload               # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# И у него есть операторы указанные операторы.
# 

local ($::_g0 = do {"OverloadExample" ~~ Overload['""']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"OverloadExample" ~~ Overload[\'""\'] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"OverloadExample" ~~ Overload['|']}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"OverloadExample" ~~ Overload[\'|\']  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## InstanceOf[A...]
# 
# Класс или объект наследует классы из списка.
# 
::done_testing; }; subtest 'InstanceOf[A...]' => sub { 
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


local ($::_g0 = do {"Tiger" ~~ InstanceOf['Animal', 'Cat']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Tiger" ~~ InstanceOf[\'Animal\', \'Cat\'] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"Tiger" ~~ InstanceOf['Tiger']}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Tiger" ~~ InstanceOf[\'Tiger\']         # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"Tiger" ~~ InstanceOf['Cat', 'Dog']}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"Tiger" ~~ InstanceOf[\'Cat\', \'Dog\']    # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ConsumerOf[A...]
# 
# Класс или объект имеет указанные роли.
# 
::done_testing; }; subtest 'ConsumerOf[A...]' => sub { 
package NoneExample {}
package RoleExample { sub DOES { $_[1] ~~ [qw/Role1 Role2/] } }

local ($::_g0 = do {'RoleExample' ~~ ConsumerOf[qw/Role1/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'RoleExample\' ~~ ConsumerOf[qw/Role1/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'RoleExample' ~~ ConsumerOf[qw/Role2 Role1/]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'RoleExample\' ~~ ConsumerOf[qw/Role2 Role1/] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, 'RoleExample') ~~ ConsumerOf[qw/Role3 Role2 Role1/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, \'RoleExample\') ~~ ConsumerOf[qw/Role3 Role2 Role1/] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {'NoneExample' ~~ ConsumerOf[qw/Role1/]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'NoneExample\' ~~ ConsumerOf[qw/Role1/] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## BoolLike
# 
# Проверяет 1, 0, "", undef или объект с перегруженным оператором `bool` или `0+` как `JSON::PP::Boolean`. Во втором случае вызывает оператор  `0+` и проверяет результат как `Bool`.
# 
# `BoolLike` вызывает оператор `0+` и проверяет результат.
# 
::done_testing; }; subtest 'BoolLike' => sub { 
package BoolLikeExample {
	use overload '0+' => sub { ${$_[0]} };
}

local ($::_g0 = do {bless(\(my $x = 1 ), 'BoolLikeExample') ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $x = 1 ), \'BoolLikeExample\') ~~ BoolLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless(\(my $x = 11), 'BoolLikeExample') ~~ BoolLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $x = 11), \'BoolLikeExample\') ~~ BoolLike # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {1 ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ BoolLike     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ BoolLike     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ BoolLike    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {undef ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'undef ~~ BoolLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package BoolLike2Example {
	use overload 'bool' => sub { ${$_[0]} };
}

local ($::_g0 = do {bless(\(my $x = 1 ), 'BoolLike2Example') ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $x = 1 ), \'BoolLike2Example\') ~~ BoolLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless(\(my $x = 11), 'BoolLike2Example') ~~ BoolLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless(\(my $x = 11), \'BoolLike2Example\') ~~ BoolLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## StrLike
# 
# Строка или объект с перегруженным оператором `""`.
# 
::done_testing; }; subtest 'StrLike' => sub { 
local ($::_g0 = do {"" ~~ StrLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ StrLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

local ($::_g0 = do {bless({}, "StrLikeExample") ~~ StrLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "StrLikeExample") ~~ StrLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {{} ~~ StrLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ StrLike # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## RegexpLike
# 
# Регулярное выражение или объект с перегруженным оператором `qr`.
# 
::done_testing; }; subtest 'RegexpLike' => sub { 
local ($::_g0 = do {ref(qr//)}, $::_e0 = "Regexp"); ::ok $::_g0 eq $::_e0, 'ref(qr//)  # => Regexp' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Scalar::Util::reftype(qr//)}, $::_e0 = "REGEXP"); ::ok $::_g0 eq $::_e0, 'Scalar::Util::reftype(qr//) # => REGEXP' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $regex = bless qr//, "A";
local ($::_g0 = do {Scalar::Util::reftype($regex)}, $::_e0 = "REGEXP"); ::ok $::_g0 eq $::_e0, 'Scalar::Util::reftype($regex) # => REGEXP' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$regex ~~ RegexpLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$regex ~~ RegexpLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {qr// ~~ RegexpLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'qr// ~~ RegexpLike   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"" ~~ RegexpLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"" ~~ RegexpLike     # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package RegexpLikeExample {
 use overload 'qr' => sub { qr/abc/ };
}

local ($::_g0 = do {"RegexpLikeExample" ~~ RegexpLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"RegexpLikeExample" ~~ RegexpLike # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {bless({}, "RegexpLikeExample") ~~ RegexpLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'bless({}, "RegexpLikeExample") ~~ RegexpLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## CodeLike
# 
# Подпрограмма или объект с перегруженным оператором `&{}`.
# 
::done_testing; }; subtest 'CodeLike' => sub { 
local ($::_g0 = do {sub {} ~~ CodeLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sub {} ~~ CodeLike     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\&CodeLike ~~ CodeLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\&CodeLike ~~ CodeLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{} ~~ CodeLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ CodeLike         # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ArrayLike`[A]
# 
# Массивы или объекты с перегруженным оператором или `@{}`.
# 
::done_testing; }; subtest 'ArrayLike`[A]' => sub { 
local ($::_g0 = do {{} ~~ ArrayLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ ArrayLike      # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {{} ~~ ArrayLike[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ ArrayLike[Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[] ~~ ArrayLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ ArrayLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package ArrayLikeExample {
	use overload '@{}' => sub {
		shift->{array} //= []
	};
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
local ($::_g0 = do {$x->{array}}, $::_e0 = do {[undef, 12]}); ::is_deeply $::_g0, $::_e0, '$x->{array} # --> [undef, 12]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$x ~~ ArrayLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$x ~~ ArrayLike # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$x ~~ ArrayLike[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$x ~~ ArrayLike[Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$x->[0] = 13;
local ($::_g0 = do {$x ~~ ArrayLike[Int]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$x ~~ ArrayLike[Int] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## HashLike`[A]
# 
# Хэши или объекты с перегруженным оператором `%{}`.
# 
::done_testing; }; subtest 'HashLike`[A]' => sub { 
local ($::_g0 = do {{} ~~ HashLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '{} ~~ HashLike  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[] ~~ HashLike}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ HashLike  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[] ~~ HashLike[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '[] ~~ HashLike[Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package HashLikeExample {
	use overload '%{}' => sub {
		shift->[0] //= {}
	};
}

my $x = bless [], 'HashLikeExample';
$x->{key} = 12.3;
local ($::_g0 = do {$x->[0]}, $::_e0 = do {{key => 12.3}}); ::is_deeply $::_g0, $::_e0, '$x->[0]  # --> {key => 12.3}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$x ~~ HashLike}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$x ~~ HashLike      # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$x ~~ HashLike[Int]}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$x ~~ HashLike[Int] # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$x ~~ HashLike[Num]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$x ~~ HashLike[Num] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # Coerces
# 
# ## Join\[R] as Str
# 
# Сктроковый тип с преобразованием массивов в строку через разделитель.
# 
::done_testing; }; subtest 'Join\[R] as Str' => sub { 
local ($::_g0 = do {Join([' '])->coerce([qw/a b c/])}, $::_e0 = "a b c"); ::ok $::_g0 eq $::_e0, 'Join([\' \'])->coerce([qw/a b c/]) # => a b c' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package JoinExample { use Aion;
	has s => (isa => Join[', '], coerce => 1);
}

local ($::_g0 = do {JoinExample->new(s => [qw/a b c/])->s}, $::_e0 = "a, b, c"); ::ok $::_g0 eq $::_e0, 'JoinExample->new(s => [qw/a b c/])->s # => a, b, c' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {JoinExample->new(s => 'string')->s}, $::_e0 = "string"); ::ok $::_g0 eq $::_e0, 'JoinExample->new(s => \'string\')->s # => string' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Split\[S] as ArrayRef
# 
::done_testing; }; subtest 'Split\[S] as ArrayRef' => sub { 
local ($::_g0 = do {Split([' '])->coerce('a b c')}, $::_e0 = do {[qw/a b c/]}); ::is_deeply $::_g0, $::_e0, 'Split([\' \'])->coerce(\'a b c\') # --> [qw/a b c/]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package SplitExample { use Aion;
	has s => (isa => Split[qr/\s*,\s*/], coerce => 1);
}

local ($::_g0 = do {SplitExample->new(s => 'a, b, c')->s}, $::_e0 = do {[qw/a b c/]}); ::is_deeply $::_g0, $::_e0, 'SplitExample->new(s => \'a, b, c\')->s # --> [qw/a b c/]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

	::done_testing;
};

::done_testing;
