use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
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

::is scalar do {"Kitty!" ~~ SpeakOfKitty}, scalar do{1}, '"Kitty!" ~~ SpeakOfKitty # -> 1';
::is scalar do {"abc"    ~~ SpeakOfKitty}, scalar do{""}, '"abc"    ~~ SpeakOfKitty # -> ""';

eval {SpeakOfKitty->validate("abc", "This")}; ok defined($@), 'SpeakOfKitty->validate("abc", "This") # @-> Speak is\'nt included kitty!'; ::cmp_ok $@, '=~', '^' . quotemeta 'Speak is\'nt included kitty!', 'SpeakOfKitty->validate("abc", "This") # @-> Speak is\'nt included kitty!';


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

::is scalar do {1 ~~ One}, scalar do{1}, '1 ~~ One	 # -> 1';
::is scalar do {0 ~~ One}, scalar do{""}, '0 ~~ One	 # -> ""';
::like scalar do {eval { One->validate(0) }; $@}, qr{Actual 1 only\!}, 'eval { One->validate(0) }; $@ # ~> Actual 1 only!';

# 
# `where` и `message` — это синтаксический сахар, а `subtype` можно использовать без них.
# 

BEGIN {
	subtype Many => (where => sub { $_ > 1 });
}

::is scalar do {2 ~~ Many}, scalar do{1}, '2 ~~ Many  # -> 1';

::like scalar do {eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@}, qr{subtype Many unused keys left: where1}, 'eval { subtype Many => (where1 => sub { $_ > 1 }) }; $@ # ~> subtype Many unused keys left: where1';

::like scalar do {eval { subtype 'Many' }; $@}, qr{subtype Many: main::Many exists\!}, 'eval { subtype \'Many\' }; $@ # ~> subtype Many: main::Many exists!';

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

::like scalar do {eval { LessThen["string"] }; $@}, qr{Argument LessThen\[A\]}, 'eval { LessThen["string"] }; $@  # ~> Argument LessThen\[A\]';

::is scalar do {5 ~~ LessThen[5]}, scalar do{""}, '5 ~~ LessThen[5]  # -> ""';

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

::is scalar do {2 ~~ Two}, scalar do{1}, '2 ~~ Two # -> 1';
::is scalar do {3 ~~ Two}, scalar do{""}, '3 ~~ Two # -> ""';

# 
# Используется с `subtype`. Необходимо, если у типа есть аргументы.
# 

eval {subtype 'Ex[A]'}; ok defined($@), 'subtype \'Ex[A]\' # @-> subtype Ex[A]: needs a where'; ::cmp_ok $@, '=~', '^' . quotemeta 'subtype Ex[A]: needs a where', 'subtype \'Ex[A]\' # @-> subtype Ex[A]: needs a where';

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

::is scalar do {0 ~~ GreatThen}, scalar do{""}, '0 ~~ GreatThen # -> ""';
::is scalar do {1 ~~ GreatThen}, scalar do{1}, '1 ~~ GreatThen # -> 1';

::is scalar do {3 ~~ GreatThen[3]}, scalar do{""}, '3 ~~ GreatThen[3] # -> ""';
::is scalar do {4 ~~ GreatThen[3]}, scalar do{1}, '4 ~~ GreatThen[3] # -> 1';

# 
# Необходимо, если аргументы необязательны.
# 

eval {subtype 'Ex`[A]', where {}}; ok defined($@), 'subtype \'Ex`[A]\', where {} # @-> subtype Ex`[A]: needs a awhere'; ::cmp_ok $@, '=~', '^' . quotemeta 'subtype Ex`[A]: needs a awhere', 'subtype \'Ex`[A]\', where {} # @-> subtype Ex`[A]: needs a awhere';
eval {subtype 'Ex', awhere {}}; ok defined($@), 'subtype \'Ex\', awhere {} # @-> subtype Ex: awhere is excess'; ::cmp_ok $@, '=~', '^' . quotemeta 'subtype Ex: awhere is excess', 'subtype \'Ex\', awhere {} # @-> subtype Ex: awhere is excess';

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

::is scalar do {2.5 ~~ Seria[1,2,3,4]}, scalar do{1}, '2.5 ~~ Seria[1,2,3,4] # -> 1';

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

::is scalar do {"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"];}, scalar do{1}, '"Hi, my dear!" ~~ BeginAndEnd["Hi,", "!"]; # -> 1';
::is scalar do {"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];}, scalar do{""}, '"Hi my dear!" ~~ BeginAndEnd["Hi,", "!"];  # -> ""';

::is scalar do {"" . BeginAndEnd["Hi,", "!"]}, "BeginAndEnd['Hi,', '!']", '"" . BeginAndEnd["Hi,", "!"] # => BeginAndEnd[\'Hi,\', \'!\']';

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

::is scalar do {"4a" ~~ Four}, scalar do{""}, '"4a" ~~ Four # -> ""';

::is scalar do {Four->coerce("4a")}, scalar do{"4a"}, 'Four->coerce("4a") # -> "4a"';

coerce Four, from Str, via { 0+$_ };

::is scalar do {Four->coerce("4a")}, scalar do{4}, 'Four->coerce("4a")	# -> 4';

coerce Four, from ArrayRef, via { scalar @$_ };

::is scalar do {Four->coerce([1,2,3])}, scalar do{3}, 'Four->coerce([1,2,3])           # -> 3';
::is scalar do {Four->coerce([1,2,3]) ~~ Four}, scalar do{""}, 'Four->coerce([1,2,3]) ~~ Four   # -> ""';
::is scalar do {Four->coerce([1,2,3,4]) ~~ Four}, scalar do{1}, 'Four->coerce([1,2,3,4]) ~~ Four # -> 1';

# 
# `coerce` выбрасывает исключения:
# 

::like scalar do {eval {coerce Int, via1 => 1}; $@}, qr{coerce Int unused keys left: via1}, 'eval {coerce Int, via1 => 1}; $@  # ~> coerce Int unused keys left: via1';
::like scalar do {eval {coerce "x"}; $@}, qr{coerce x not Aion::Type\!}, 'eval {coerce "x"}; $@  # ~> coerce x not Aion::Type!';
::like scalar do {eval {coerce Int}; $@}, qr{coerce Int: from is'nt Aion::Type\!}, 'eval {coerce Int}; $@  # ~> coerce Int: from is\'nt Aion::Type!';
::like scalar do {eval {coerce Int, from "x"}; $@}, qr{coerce Int: from is'nt Aion::Type\!}, 'eval {coerce Int, from "x"}; $@  # ~> coerce Int: from is\'nt Aion::Type!';
::like scalar do {eval {coerce Int, from Num}; $@}, qr{coerce Int: via is not subroutine\!}, 'eval {coerce Int, from Num}; $@  # ~> coerce Int: via is not subroutine!';
::like scalar do {eval {coerce Int, (from=>Num, via=>"x")}; $@}, qr{coerce Int: via is not subroutine\!}, 'eval {coerce Int, (from=>Num, via=>"x")}; $@  # ~> coerce Int: via is not subroutine!';

# 
# Стандартные приведения:
# 

# Str from Undef — empty string
::is scalar do {Str->coerce(undef)}, scalar do{""}, 'Str->coerce(undef) # -> ""';

# Int from Num — rounded integer
::is scalar do {Int->coerce(2.5)}, scalar do{3}, 'Int->coerce(2.5)  # -> 3';
::is scalar do {Int->coerce(-2.5)}, scalar do{-3}, 'Int->coerce(-2.5) # -> -3';

# Bool from Any — 1 or ""
::is scalar do {Bool->coerce([])}, scalar do{1}, 'Bool->coerce([]) # -> 1';
::is scalar do {Bool->coerce(0)}, scalar do{""}, 'Bool->coerce(0)  # -> ""';

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

::is scalar do {minint 6, 5;}, scalar do{5}, 'minint 6, 5; # -> 5';
::like scalar do {eval {minint 5.5, 2}; $@}, qr{Arguments of method `minint` must have the type Tuple\[Int, Int\]\.}, 'eval {minint 5.5, 2}; $@ # ~> Arguments of method `minint` must have the type Tuple\[Int, Int\]\.';

sub half($) : Isa(Int => Int) {
	my ($x) = @_;
	$x / 2
}

::is scalar do {half 4;}, scalar do{2}, 'half 4; # -> 2';
::like scalar do {eval {half 5}; $@}, qr{Return of method `half` must have the type Int. The it is 2.5}, 'eval {half 5}; $@ # ~> Return of method `half` must have the type Int. The it is 2.5';

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
::is scalar do {33  ~~ Union[Int, Ref]}, scalar do{1}, '33  ~~ Union[Int, Ref] # -> 1';
::is scalar do {[]  ~~ Union[Int, Ref]}, scalar do{1}, '[]  ~~ Union[Int, Ref]	# -> 1';
::is scalar do {"a" ~~ Union[Int, Ref]}, scalar do{""}, '"a" ~~ Union[Int, Ref]	# -> ""';

# 
# ## Intersection[A, B...]
# 
# Пересечение нескольких типов. Аналогичен оператору `$type1 & $type2`.
# 
::done_testing; }; subtest 'Intersection[A, B...]' => sub { 
::is scalar do {15 ~~ Intersection[Int, StrMatch[/5/]]}, scalar do{1}, '15 ~~ Intersection[Int, StrMatch[/5/]] # -> 1';

# 
# ## Exclude[A, B...]
# 
# Исключение нескольких типов. Аналогичен оператору `~ $type`.
# 
::done_testing; }; subtest 'Exclude[A, B...]' => sub { 
::is scalar do {-5  ~~ Exclude[PositiveInt]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt] # -> 1';
::is scalar do {"a" ~~ Exclude[PositiveInt]}, scalar do{1}, '"a" ~~ Exclude[PositiveInt] # -> 1';
::is scalar do {5   ~~ Exclude[PositiveInt]}, scalar do{""}, '5   ~~ Exclude[PositiveInt] # -> ""';
::is scalar do {5.5 ~~ Exclude[PositiveInt]}, scalar do{1}, '5.5 ~~ Exclude[PositiveInt] # -> 1';

# 
# Если `Exclude` имеет много аргументов, то это аналог `~ ($type1 | $type2 ...)`.
# 

::is scalar do {-5  ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{1}, '-5  ~~ Exclude[PositiveInt, Enum[-2]] # -> 1';
::is scalar do {-2  ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{""}, '-2  ~~ Exclude[PositiveInt, Enum[-2]] # -> ""';
::is scalar do {0   ~~ Exclude[PositiveInt, Enum[-2]]}, scalar do{""}, '0   ~~ Exclude[PositiveInt, Enum[-2]] # -> ""';

# 
# ## Option[A]
# 
# Дополнительные ключи в `Dict`.
# 
::done_testing; }; subtest 'Option[A]' => sub { 
::is scalar do {{a=>55} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{1}, '{a=>55} ~~ Dict[a=>Int, b => Option[Int]]          # -> 1';
::is scalar do {{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{1}, '{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]]   # -> 1';
::is scalar do {{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]]}, scalar do{""}, '{a=>55, b=>31.5} ~~ Dict[a=>Int, b => Option[Int]] # -> ""';

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

::is_deeply scalar do {\@a}, scalar do {[1,2,3]}, '\@a # --> [1,2,3]';
::is scalar do {$s}, scalar do{3}, '$s  # -> 3';

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
::is scalar do {1 ~~ Bool}, scalar do{1}, '1 ~~ Bool  # -> 1';
::is scalar do {0 ~~ Bool}, scalar do{1}, '0 ~~ Bool  # -> 1';
::is scalar do {undef ~~ Bool}, scalar do{1}, 'undef ~~ Bool # -> 1';
::is scalar do {"" ~~ Bool}, scalar do{1}, '"" ~~ Bool # -> 1';

::is scalar do {2 ~~ Bool}, scalar do{""}, '2 ~~ Bool  # -> ""';
::is scalar do {[] ~~ Bool}, scalar do{""}, '[] ~~ Bool # -> ""';

# 
# ## Enum[A...]
# 
# Перечисление.
# 
::done_testing; }; subtest 'Enum[A...]' => sub { 
::is scalar do {3 ~~ Enum[1,2,3]}, scalar do{1}, '3 ~~ Enum[1,2,3]   # -> 1';
::is scalar do {"cat" ~~ Enum["cat", "dog"]}, scalar do{1}, '"cat" ~~ Enum["cat", "dog"] # -> 1';
::is scalar do {4 ~~ Enum[1,2,3]}, scalar do{""}, '4 ~~ Enum[1,2,3]   # -> ""';

# 
# ## Maybe[A]
# 
# `undef` или тип в `[]`.
# 
::done_testing; }; subtest 'Maybe[A]' => sub { 
::is scalar do {undef ~~ Maybe[Int]}, scalar do{1}, 'undef ~~ Maybe[Int] # -> 1';
::is scalar do {4 ~~ Maybe[Int]}, scalar do{1}, '4 ~~ Maybe[Int]     # -> 1';
::is scalar do {"" ~~ Maybe[Int]}, scalar do{""}, '"" ~~ Maybe[Int]    # -> ""';

# 
# ## Undef
# 
# Только `undef`.
# 
::done_testing; }; subtest 'Undef' => sub { 
::is scalar do {undef ~~ Undef}, scalar do{1}, 'undef ~~ Undef # -> 1';
::is scalar do {0 ~~ Undef}, scalar do{""}, '0 ~~ Undef     # -> ""';

# 
# ## Defined
# 
# Всё за исключением `undef`.
# 
::done_testing; }; subtest 'Defined' => sub { 
::is scalar do {\0 ~~ Defined}, scalar do{1}, '\0 ~~ Defined    # -> 1';
::is scalar do {undef ~~ Defined}, scalar do{""}, 'undef ~~ Defined # -> ""';

# 
# ## Value
# 
# Определённые значения без ссылок.
# 
::done_testing; }; subtest 'Value' => sub { 
::is scalar do {3 ~~ Value}, scalar do{1}, '3 ~~ Value  # -> 1';
::is scalar do {\3 ~~ Value}, scalar do{""}, '\3 ~~ Value    # -> ""';
::is scalar do {undef ~~ Value}, scalar do{""}, 'undef ~~ Value # -> ""';

# 
# ## Len[A, B?]
# 
# Определяет значение длины от `A` до `B` или от 0 до `A`, если `B` отсутствует.
# 
::done_testing; }; subtest 'Len[A, B?]' => sub { 
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
# Perl версии.
# 
::done_testing; }; subtest 'Version' => sub { 
::is scalar do {1.1.0 ~~ Version}, scalar do{1}, '1.1.0 ~~ Version   # -> 1';
::is scalar do {v1.1.0 ~~ Version}, scalar do{1}, 'v1.1.0 ~~ Version  # -> 1';
::is scalar do {v1.1 ~~ Version}, scalar do{1}, 'v1.1 ~~ Version    # -> 1';
::is scalar do {v1 ~~ Version}, scalar do{1}, 'v1 ~~ Version      # -> 1';
::is scalar do {1.1 ~~ Version}, scalar do{""}, '1.1 ~~ Version     # -> ""';
::is scalar do {"1.1.0" ~~ Version}, scalar do{""}, '"1.1.0" ~~ Version # -> ""';

# 
# ## Str
# 
# Строки, включая числа.
# 
::done_testing; }; subtest 'Str' => sub { 
::is scalar do {1.1 ~~ Str}, scalar do{1}, '1.1 ~~ Str   # -> 1';
::is scalar do {"" ~~ Str}, scalar do{1}, '"" ~~ Str    # -> 1';
::is scalar do {1.1.0 ~~ Str}, scalar do{""}, '1.1.0 ~~ Str # -> ""';

# 
# ## Uni
# 
# Строки Unicode с флагом utf8 или если декодирование в utf8 происходит без ошибок.
# 
::done_testing; }; subtest 'Uni' => sub { 
::is scalar do {"↭" ~~ Uni}, scalar do{1}, '"↭" ~~ Uni # -> 1';
::is scalar do {123 ~~ Uni}, scalar do{""}, '123 ~~ Uni # -> ""';
::is scalar do {do {no utf8; "↭" ~~ Uni}}, scalar do{1}, 'do {no utf8; "↭" ~~ Uni} # -> 1';

# 
# ## Bin
# 
# Бинарные строки без флага utf8 и октетов с номерами меньше 128.
# 
::done_testing; }; subtest 'Bin' => sub { 
::is scalar do {123 ~~ Bin}, scalar do{1}, '123 ~~ Bin # -> 1';
::is scalar do {"z" ~~ Bin}, scalar do{1}, '"z" ~~ Bin # -> 1';
::is scalar do {"↭" ~~ Bin}, scalar do{""}, '"↭" ~~ Bin # -> ""';
::is scalar do {do {no utf8; "↭" ~~ Bin }}, scalar do{""}, 'do {no utf8; "↭" ~~ Bin }   # -> ""';

# 
# ## StartsWith\[S]
# 
# Строка начинается с `S`.
# 
::done_testing; }; subtest 'StartsWith\[S]' => sub { 
::is scalar do {"Hi, world!" ~~ StartsWith["Hi,"]}, scalar do{1}, '"Hi, world!" ~~ StartsWith["Hi,"] # -> 1';
::is scalar do {"Hi world!" ~~ StartsWith["Hi,"]}, scalar do{""}, '"Hi world!" ~~ StartsWith["Hi,"] # -> ""';

# 
# ## EndsWith\[S]
# 
# Строка заканчивается на `S`.
# 
::done_testing; }; subtest 'EndsWith\[S]' => sub { 
::is scalar do {"Hi, world!" ~~ EndsWith["world!"]}, scalar do{1}, '"Hi, world!" ~~ EndsWith["world!"] # -> 1';
::is scalar do {"Hi, world" ~~ EndsWith["world!"]}, scalar do{""}, '"Hi, world" ~~ EndsWith["world!"]  # -> ""';

# 
# ## NonEmptyStr
# 
# Строка с одним или несколькими символами, не являющимися пробелами.
# 
::done_testing; }; subtest 'NonEmptyStr' => sub { 
::is scalar do {" " ~~ NonEmptyStr}, scalar do{""}, '" " ~~ NonEmptyStr              # -> ""';
::is scalar do {" S " ~~ NonEmptyStr}, scalar do{1}, '" S " ~~ NonEmptyStr            # -> 1';
::is scalar do {" S " ~~ (NonEmptyStr & Len[2])}, scalar do{""}, '" S " ~~ (NonEmptyStr & Len[2]) # -> ""';

# 
# ## Email
# 
# Строки с `@`.
# 
::done_testing; }; subtest 'Email' => sub { 
::is scalar do {'@' ~~ Email}, scalar do{1}, '\'@\' ~~ Email     # -> 1';
::is scalar do {'a@a.a' ~~ Email}, scalar do{1}, '\'a@a.a\' ~~ Email # -> 1';
::is scalar do {'a.a' ~~ Email}, scalar do{""}, '\'a.a\' ~~ Email   # -> ""';

# 
# ## Tel
# 
# Формат телефонов — знак плюс и семь или больше цифр.
# 
::done_testing; }; subtest 'Tel' => sub { 
::is scalar do {"+1234567" ~~ Tel}, scalar do{1}, '"+1234567" ~~ Tel # -> 1';
::is scalar do {"+1234568" ~~ Tel}, scalar do{1}, '"+1234568" ~~ Tel # -> 1';
::is scalar do {"+ 1234567" ~~ Tel}, scalar do{""}, '"+ 1234567" ~~ Tel # -> ""';
::is scalar do {"+1234567 " ~~ Tel}, scalar do{""}, '"+1234567 " ~~ Tel # -> ""';

# 
# ## Url
# 
# URL-адреса веб-сайтов — это строка с префиксом http:// или https://.
# 
::done_testing; }; subtest 'Url' => sub { 
::is scalar do {"http://" ~~ Url}, scalar do{1}, '"http://" ~~ Url # -> 1';
::is scalar do {"http:/" ~~ Url}, scalar do{""}, '"http:/" ~~ Url  # -> ""';

# 
# ## Path
# 
# Пути начинаются с косой черты.
# 
::done_testing; }; subtest 'Path' => sub { 
::is scalar do {"/" ~~ Path}, scalar do{1}, '"/" ~~ Path  # -> 1';
::is scalar do {"/a/b" ~~ Path}, scalar do{1}, '"/a/b" ~~ Path  # -> 1';
::is scalar do {"a/b" ~~ Path}, scalar do{""}, '"a/b" ~~ Path   # -> ""';

# 
# ## Html
# 
# HTML начинается с `<!doctype html` или `<html`.
# 
::done_testing; }; subtest 'Html' => sub { 
::is scalar do {"<HTML" ~~ Html}, scalar do{1}, '"<HTML" ~~ Html   # -> 1';
::is scalar do {" <html" ~~ Html}, scalar do{1}, '" <html" ~~ Html     # -> 1';
::is scalar do {" <!doctype html>" ~~ Html}, scalar do{1}, '" <!doctype html>" ~~ Html # -> 1';
::is scalar do {" <html1>" ~~ Html}, scalar do{""}, '" <html1>" ~~ Html   # -> ""';

# 
# ## StrDate
# 
# Дата в формате `yyyy-mm-dd`.
# 
::done_testing; }; subtest 'StrDate' => sub { 
::is scalar do {"2001-01-12" ~~ StrDate}, scalar do{1}, '"2001-01-12" ~~ StrDate # -> 1';
::is scalar do {"01-01-01" ~~ StrDate}, scalar do{""}, '"01-01-01" ~~ StrDate   # -> ""';

# 
# ## StrDateTime
# 
# Дата и время в формате `yyyy-mm-dd HH:MM:SS`.
# 
::done_testing; }; subtest 'StrDateTime' => sub { 
::is scalar do {"2012-12-01 00:00:00" ~~ StrDateTime}, scalar do{1}, '"2012-12-01 00:00:00" ~~ StrDateTime  # -> 1';
::is scalar do {"2012-12-01 00:00:00 " ~~ StrDateTime}, scalar do{""}, '"2012-12-01 00:00:00 " ~~ StrDateTime # -> ""';

# 
# ## StrMatch[qr/.../]
# 
# Сопоставляет строку с регулярным выражением.
# 
::done_testing; }; subtest 'StrMatch[qr/.../]' => sub { 
::is scalar do {' abc ' ~~ StrMatch[qr/abc/]}, scalar do{1}, '\' abc \' ~~ StrMatch[qr/abc/]  # -> 1';
::is scalar do {' abbc ' ~~ StrMatch[qr/abc/]}, scalar do{""}, '\' abbc \' ~~ StrMatch[qr/abc/] # -> ""';

# 
# ## ClassName
# 
# Имя класса — это пакет с методом `new`.
# 
::done_testing; }; subtest 'ClassName' => sub { 
::is scalar do {'Aion::Type' ~~ ClassName}, scalar do{1}, '\'Aion::Type\' ~~ ClassName  # -> 1';
::is scalar do {'Aion::Types' ~~ ClassName}, scalar do{""}, '\'Aion::Types\' ~~ ClassName # -> ""';

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


::is scalar do {'ExRole1' ~~ RoleName}, scalar do{1}, '\'ExRole1\' ~~ RoleName    # -> 1';
::is scalar do {'ExRole2' ~~ RoleName}, scalar do{1}, '\'ExRole2\' ~~ RoleName    # -> 1';
::is scalar do {'Aion::Type' ~~ RoleName}, scalar do{""}, '\'Aion::Type\' ~~ RoleName # -> ""';
::is scalar do {'Nouname::Empty::Package' ~~ RoleName}, scalar do{""}, '\'Nouname::Empty::Package\' ~~ RoleName # -> ""';

# 
# ## Rat
# 
# Рациональные числа.
# 
::done_testing; }; subtest 'Rat' => sub { 
::is scalar do {"6/7" ~~ Rat}, scalar do{1}, '"6/7" ~~ Rat  # -> 1';
::is scalar do {"-6/7" ~~ Rat}, scalar do{1}, '"-6/7" ~~ Rat # -> 1';
::is scalar do {6 ~~ Rat}, scalar do{1}, '6 ~~ Rat      # -> 1';
::is scalar do {"inf" ~~ Rat}, scalar do{1}, '"inf" ~~ Rat  # -> 1';
::is scalar do {"+Inf" ~~ Rat}, scalar do{1}, '"+Inf" ~~ Rat # -> 1';
::is scalar do {"NaN" ~~ Rat}, scalar do{1}, '"NaN" ~~ Rat  # -> 1';
::is scalar do {"-nan" ~~ Rat}, scalar do{1}, '"-nan" ~~ Rat # -> 1';
::is scalar do {6.5 ~~ Rat}, scalar do{1}, '6.5 ~~ Rat    # -> 1';
::is scalar do {"6.5 " ~~ Rat}, scalar do{''}, '"6.5 " ~~ Rat # -> \'\'';

# 
# ## Num
# 
# Числа.
# 
::done_testing; }; subtest 'Num' => sub { 
::is scalar do {-6.5 ~~ Num}, scalar do{1}, '-6.5 ~~ Num   # -> 1';
::is scalar do {6.5e-7 ~~ Num}, scalar do{1}, '6.5e-7 ~~ Num # -> 1';
::is scalar do {"6.5 " ~~ Num}, scalar do{""}, '"6.5 " ~~ Num # -> ""';

# 
# ## PositiveNum
# 
# Положительные числа.
# 
::done_testing; }; subtest 'PositiveNum' => sub { 
::is scalar do {0 ~~ PositiveNum}, scalar do{1}, '0 ~~ PositiveNum    # -> 1';
::is scalar do {0.1 ~~ PositiveNum}, scalar do{1}, '0.1 ~~ PositiveNum  # -> 1';
::is scalar do {-0.1 ~~ PositiveNum}, scalar do{""}, '-0.1 ~~ PositiveNum # -> ""';
::is scalar do {-0 ~~ PositiveNum}, scalar do{1}, '-0 ~~ PositiveNum   # -> 1';

# 
# ## Float
# 
# Машинное число с плавающей запятой составляет 4 байта.
# 
::done_testing; }; subtest 'Float' => sub { 
::is scalar do {-4.8 ~~ Float}, scalar do{1}, '-4.8 ~~ Float             # -> 1';
::is scalar do {-3.402823466E+38 ~~ Float}, scalar do{1}, '-3.402823466E+38 ~~ Float # -> 1';
::is scalar do {+3.402823466E+38 ~~ Float}, scalar do{1}, '+3.402823466E+38 ~~ Float # -> 1';
::is scalar do {-3.402823467E+38 ~~ Float}, scalar do{""}, '-3.402823467E+38 ~~ Float # -> ""';

# 
# ## Double
# 
# Машинное число с плавающей запятой составляет 8 байт.
# 
::done_testing; }; subtest 'Double' => sub { 
use Scalar::Util qw//;

::is scalar do {-4.8 ~~ Double}, scalar do{1}, '                      -4.8 ~~ Double # -> 1';
::is scalar do {'-1.7976931348623157e+308' ~~ Double}, scalar do{1}, '\'-1.7976931348623157e+308\' ~~ Double # -> 1';
::is scalar do {'+1.7976931348623157e+308' ~~ Double}, scalar do{1}, '\'+1.7976931348623157e+308\' ~~ Double # -> 1';
::is scalar do {'-1.7976931348623159e+308' ~~ Double}, scalar do{""}, '\'-1.7976931348623159e+308\' ~~ Double # -> ""';

# 
# ## Range[from, to]
# 
# Числа между `from` и `to`.
# 
::done_testing; }; subtest 'Range[from, to]' => sub { 
::is scalar do {1 ~~ Range[1, 3]}, scalar do{1}, '1 ~~ Range[1, 3]   # -> 1';
::is scalar do {2.5 ~~ Range[1, 3]}, scalar do{1}, '2.5 ~~ Range[1, 3] # -> 1';
::is scalar do {3 ~~ Range[1, 3]}, scalar do{1}, '3 ~~ Range[1, 3]   # -> 1';
::is scalar do {3.1 ~~ Range[1, 3]}, scalar do{""}, '3.1 ~~ Range[1, 3] # -> ""';
::is scalar do {0.9 ~~ Range[1, 3]}, scalar do{""}, '0.9 ~~ Range[1, 3] # -> ""';

# 
# ## Int
# 
# Целые числа.
# 
::done_testing; }; subtest 'Int' => sub { 
::is scalar do {123 ~~ Int}, scalar do{1}, '123 ~~ Int	# -> 1';
::is scalar do {-12 ~~ Int}, scalar do{1}, '-12 ~~ Int	# -> 1';
::is scalar do {5.5 ~~ Int}, scalar do{""}, '5.5 ~~ Int	# -> ""';

# 
# ## Bytes[N]
# 
# Рассчитывает максимальное и минимальное числа, которые поместятся в `N` байт и проверяет ограничение между ними.
# 
::done_testing; }; subtest 'Bytes[N]' => sub { 
::is scalar do {-129 ~~ Bytes[1]}, scalar do{""}, '-129 ~~ Bytes[1] # -> ""';
::is scalar do {-128 ~~ Bytes[1]}, scalar do{1}, '-128 ~~ Bytes[1] # -> 1';
::is scalar do {127 ~~ Bytes[1]}, scalar do{1}, '127 ~~ Bytes[1]  # -> 1';
::is scalar do {128 ~~ Bytes[1]}, scalar do{""}, '128 ~~ Bytes[1]  # -> ""';

# 2 bits power of (8 bits * 8 bytes - 1)
my $N = 1 << (8*8-1);
::is scalar do {(-$N-1) ~~ Bytes[8]}, scalar do{""}, '(-$N-1) ~~ Bytes[8] # -> ""';
::is scalar do {(-$N) ~~ Bytes[8]}, scalar do{1}, '(-$N) ~~ Bytes[8]   # -> 1';
::is scalar do {($N-1) ~~ Bytes[8]}, scalar do{1}, '($N-1) ~~ Bytes[8]  # -> 1';
::is scalar do {$N ~~ Bytes[8]}, scalar do{""}, '$N ~~ Bytes[8]      # -> ""';

require Math::BigInt;

my $N17 = 1 << (8*Math::BigInt->new(17) - 1);

::is scalar do {((-$N17-1) . "") ~~ Bytes[17]}, scalar do{""}, '((-$N17-1) . "") ~~ Bytes[17] # -> ""';
::is scalar do {(-$N17 . "") ~~ Bytes[17]}, scalar do{1}, '(-$N17 . "") ~~ Bytes[17]     # -> 1';
::is scalar do {(($N17-1) . "") ~~ Bytes[17]}, scalar do{1}, '(($N17-1) . "") ~~ Bytes[17]  # -> 1';
::is scalar do {($N17 . "") ~~ Bytes[17]}, scalar do{""}, '($N17 . "") ~~ Bytes[17]      # -> ""';

# 
# ## PositiveInt
# 
# Положительные целые числа.
# 
::done_testing; }; subtest 'PositiveInt' => sub { 
::is scalar do {+0 ~~ PositiveInt}, scalar do{1}, '+0 ~~ PositiveInt # -> 1';
::is scalar do {-0 ~~ PositiveInt}, scalar do{1}, '-0 ~~ PositiveInt # -> 1';
::is scalar do {55 ~~ PositiveInt}, scalar do{1}, '55 ~~ PositiveInt # -> 1';
::is scalar do {-1 ~~ PositiveInt}, scalar do{""}, '-1 ~~ PositiveInt # -> ""';

# 
# ## PositiveBytes[N]
# 
# Рассчитывает максимальное число, которое поместится в `N` байт (полагая, что в байтах нет отрицательного бита) и проверяет ограничение от 0 до этого числа.
# 
::done_testing; }; subtest 'PositiveBytes[N]' => sub { 
::is scalar do {-1 ~~ PositiveBytes[1]}, scalar do{""}, '-1 ~~ PositiveBytes[1]  # -> ""';
::is scalar do {0 ~~ PositiveBytes[1]}, scalar do{1}, '0 ~~ PositiveBytes[1]   # -> 1';
::is scalar do {255 ~~ PositiveBytes[1]}, scalar do{1}, '255 ~~ PositiveBytes[1] # -> 1';
::is scalar do {256 ~~ PositiveBytes[1]}, scalar do{""}, '256 ~~ PositiveBytes[1] # -> ""';

::is scalar do {-1 ~~ PositiveBytes[8]}, scalar do{""}, '-1 ~~ PositiveBytes[8]   # -> ""';
::is scalar do {1.01 ~~ PositiveBytes[8]}, scalar do{""}, '1.01 ~~ PositiveBytes[8] # -> ""';
::is scalar do {0 ~~ PositiveBytes[8]}, scalar do{1}, '0 ~~ PositiveBytes[8]    # -> 1';

my $N8 = 2 ** (8*Math::BigInt->new(8)) - 1;

::is scalar do {$N8 . "" ~~ PositiveBytes[8]}, scalar do{1}, '$N8 . "" ~~ PositiveBytes[8]     # -> 1';
::is scalar do {($N8+1) . "" ~~ PositiveBytes[8]}, scalar do{""}, '($N8+1) . "" ~~ PositiveBytes[8] # -> ""';

::is scalar do {-1 ~~ PositiveBytes[17]}, scalar do{""}, '-1 ~~ PositiveBytes[17] # -> ""';
::is scalar do {0 ~~ PositiveBytes[17]}, scalar do{1}, '0 ~~ PositiveBytes[17]  # -> 1';

# 
# ## Nat
# 
# Целые числа 1+.
# 
::done_testing; }; subtest 'Nat' => sub { 
::is scalar do {0 ~~ Nat}, scalar do{""}, '0 ~~ Nat	# -> ""';
::is scalar do {1 ~~ Nat}, scalar do{1}, '1 ~~ Nat	# -> 1';

# 
# ## Ref
# 
# Ссылка.
# 
::done_testing; }; subtest 'Ref' => sub { 
::is scalar do {\1 ~~ Ref}, scalar do{1}, '\1 ~~ Ref # -> 1';
::is scalar do {[] ~~ Ref}, scalar do{1}, '[] ~~ Ref # -> 1';
::is scalar do {1 ~~ Ref}, scalar do{""}, '1 ~~ Ref  # -> ""';

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

::is scalar do {\%a ~~ Tied}, scalar do{1}, '\%a ~~ Tied # -> 1';
::is scalar do {\@a ~~ Tied}, scalar do{1}, '\@a ~~ Tied # -> 1';
::is scalar do {\$a ~~ Tied}, scalar do{1}, '\$a ~~ Tied # -> 1';

::is scalar do {\%b ~~ Tied}, scalar do{""}, '\%b ~~ Tied  # -> ""';
::is scalar do {\@b ~~ Tied}, scalar do{""}, '\@b ~~ Tied  # -> ""';
::is scalar do {\$b ~~ Tied}, scalar do{""}, '\$b ~~ Tied  # -> ""';
::is scalar do {\\$b ~~ Tied}, scalar do{""}, '\\$b ~~ Tied # -> ""';

::is scalar do {ref tied %a}, "TiedHash", 'ref tied %a     # => TiedHash';
::is scalar do {ref tied %{\%a}}, "TiedHash", 'ref tied %{\%a} # => TiedHash';

::is scalar do {\%a ~~ Tied["TiedHash"]}, scalar do{1}, '\%a ~~ Tied["TiedHash"]   # -> 1';
::is scalar do {\@a ~~ Tied["TiedArray"]}, scalar do{1}, '\@a ~~ Tied["TiedArray"]  # -> 1';
::is scalar do {\$a ~~ Tied["TiedScalar"]}, scalar do{1}, '\$a ~~ Tied["TiedScalar"] # -> 1';

::is scalar do {\%a ~~ Tied["TiedArray"]}, scalar do{""}, '\%a ~~ Tied["TiedArray"]   # -> ""';
::is scalar do {\@a ~~ Tied["TiedScalar"]}, scalar do{""}, '\@a ~~ Tied["TiedScalar"]  # -> ""';
::is scalar do {\$a ~~ Tied["TiedHash"]}, scalar do{""}, '\$a ~~ Tied["TiedHash"]    # -> ""';
::is scalar do {\\$a ~~ Tied["TiedScalar"]}, scalar do{""}, '\\$a ~~ Tied["TiedScalar"] # -> ""';

# 
# ## LValueRef
# 
# Функция позволяет присваивание.
# 
::done_testing; }; subtest 'LValueRef' => sub { 
::is scalar do {ref \substr("abc", 1, 2)}, "LVALUE", 'ref \substr("abc", 1, 2) # => LVALUE';
::is scalar do {ref \vec(42, 1, 2)}, "LVALUE", 'ref \vec(42, 1, 2) # => LVALUE';

::is scalar do {\substr("abc", 1, 2) ~~ LValueRef}, scalar do{1}, '\substr("abc", 1, 2) ~~ LValueRef # -> 1';
::is scalar do {\vec(42, 1, 2) ~~ LValueRef}, scalar do{1}, '\vec(42, 1, 2) ~~ LValueRef # -> 1';

# 
# Но с `:lvalue` не работает.
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
::is_deeply scalar do {$x}, scalar do {bless {x=>10}, "As"}, '$x	# --> bless {x=>10}, "As"';

::is scalar do {ref \$x->x}, "SCALAR", 'ref \$x->x			 # => SCALAR';
::is scalar do {\$x->x ~~ LValueRef}, scalar do{""}, '\$x->x ~~ LValueRef # -> ""';

# 
# And on the end:
# 

::is scalar do {\1 ~~ LValueRef}, scalar do{""}, '\1 ~~ LValueRef	# -> ""';

my $x = "abc";
substr($x, 1, 1) = 10;

::is scalar do {$x}, "a10c", '$x # => a10c';

::is scalar do {LValueRef->include( \substr($x, 1, 1) )}, "1", 'LValueRef->include( \substr($x, 1, 1) )	# => 1';

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

::is scalar do {*EXAMPLE_FMT{FORMAT} ~~ FormatRef}, scalar do{1}, '*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1';
::is scalar do {\1 ~~ FormatRef}, scalar do{""}, '\1 ~~ FormatRef				# -> ""';

# 
# ## CodeRef`[name, proto]
# 
# Подпрограмма.
# 
::done_testing; }; subtest 'CodeRef`[name, proto]' => sub { 
::is scalar do {sub {} ~~ CodeRef}, scalar do{1}, 'sub {} ~~ CodeRef	# -> 1';
::is scalar do {\1 ~~ CodeRef}, scalar do{""}, '\1 ~~ CodeRef		# -> ""';

sub code_ex ($;$) { ... }

::is scalar do {\&code_ex ~~ CodeRef['main::code_ex']}, scalar do{1}, '\&code_ex ~~ CodeRef[\'main::code_ex\']         # -> 1';
::is scalar do {\&code_ex ~~ CodeRef['code_ex']}, scalar do{""}, '\&code_ex ~~ CodeRef[\'code_ex\']               # -> ""';
::is scalar do {\&code_ex ~~ CodeRef[qr/_/]}, scalar do{1}, '\&code_ex ~~ CodeRef[qr/_/]                   # -> 1';
::is scalar do {\&code_ex ~~ CodeRef[undef, '$;$']}, scalar do{1}, '\&code_ex ~~ CodeRef[undef, \'$;$\']            # -> 1';
::is scalar do {\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]}, scalar do{1}, '\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/] # -> 1';
::is scalar do {\&code_ex ~~ CodeRef[undef, '@']}, scalar do{""}, '\&code_ex ~~ CodeRef[undef, \'@\']              # -> ""';
::is scalar do {\&code_ex ~~ CodeRef['main::code_ex', '$;$']}, scalar do{1}, '\&code_ex ~~ CodeRef[\'main::code_ex\', \'$;$\']  # -> 1';

# 
# 
# ## ReachableCodeRef`[name, proto]
# 
# Подпрограмма с телом.
# 
::done_testing; }; subtest 'ReachableCodeRef`[name, proto]' => sub { 
sub code_forward ($;$);

::is scalar do {\&code_ex ~~ ReachableCodeRef['main::code_ex']}, scalar do{1}, '\&code_ex ~~ ReachableCodeRef[\'main::code_ex\']        # -> 1';
::is scalar do {\&code_ex ~~ ReachableCodeRef['code_ex']}, scalar do{""}, '\&code_ex ~~ ReachableCodeRef[\'code_ex\']              # -> ""';
::is scalar do {\&code_ex ~~ ReachableCodeRef[qr/_/]}, scalar do{1}, '\&code_ex ~~ ReachableCodeRef[qr/_/]                  # -> 1';
::is scalar do {\&code_ex ~~ ReachableCodeRef[undef, '$;$']}, scalar do{1}, '\&code_ex ~~ ReachableCodeRef[undef, \'$;$\']           # -> 1';
::is scalar do {\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]}, scalar do{1}, '\&code_ex ~~ CodeRef[undef, qr/^(\$;\$|\@)$/]         # -> 1';
::is scalar do {\&code_ex ~~ ReachableCodeRef[undef, '@']}, scalar do{""}, '\&code_ex ~~ ReachableCodeRef[undef, \'@\']             # -> ""';
::is scalar do {\&code_ex ~~ ReachableCodeRef['main::code_ex', '$;$']}, scalar do{1}, '\&code_ex ~~ ReachableCodeRef[\'main::code_ex\', \'$;$\'] # -> 1';

::is scalar do {\&code_forward ~~ ReachableCodeRef}, scalar do{""}, '\&code_forward ~~ ReachableCodeRef # -> ""';

# 
# ## UnreachableCodeRef`[name, proto]
# 
# Подпрограмма без тела.
# 
::done_testing; }; subtest 'UnreachableCodeRef`[name, proto]' => sub { 
::is scalar do {\&nouname ~~ UnreachableCodeRef}, scalar do{1}, '\&nouname ~~ UnreachableCodeRef # -> 1';
::is scalar do {\&code_ex ~~ UnreachableCodeRef}, scalar do{""}, '\&code_ex ~~ UnreachableCodeRef # -> ""';
::is scalar do {\&code_forward ~~ UnreachableCodeRef['main::code_forward', '$;$']}, scalar do{1}, '\&code_forward ~~ UnreachableCodeRef[\'main::code_forward\', \'$;$\'] # -> 1';

# 
# ## Isa[A...]
# 
# Ссылка на подпрограмму с соответствующей сигнатурой.
# 
::done_testing; }; subtest 'Isa[A...]' => sub { 
sub sig_ex :Isa(Int => Str) {}

::is scalar do {\&sig_ex ~~ Isa[Int => Str]}, scalar do{1}, '\&sig_ex ~~ Isa[Int => Str]        # -> 1';
::is scalar do {\&sig_ex ~~ Isa[Int => Str => Num]}, scalar do{""}, '\&sig_ex ~~ Isa[Int => Str => Num] # -> ""';
::is scalar do {\&sig_ex ~~ Isa[Int => Num]}, scalar do{""}, '\&sig_ex ~~ Isa[Int => Num]        # -> ""';

# 
# Подпрограммы без тела не оборачиваются в обработчик сигнатуры, а сигнатура запоминается для валидации соответствия впоследствии объявленной подпрограммы с телом. Поэтому функция не имеет сигнатуры.
# 

sub unreachable_sig_ex :Isa(Int => Str);

::is scalar do {\&unreachable_sig_ex ~~ Isa[Int => Str]}, scalar do{""}, '\&unreachable_sig_ex ~~ Isa[Int => Str] # -> ""';

# 
# ## RegexpRef
# 
# Регулярное выражение.
# 
::done_testing; }; subtest 'RegexpRef' => sub { 
::is scalar do {qr// ~~ RegexpRef}, scalar do{1}, 'qr// ~~ RegexpRef # -> 1';
::is scalar do {\1 ~~ RegexpRef}, scalar do{""}, '\1 ~~ RegexpRef   # -> ""';

# 
# ## ScalarRefRef`[A]
# 
# Ссылка на скаляр или ссылка на ссылку.
# 
::done_testing; }; subtest 'ScalarRefRef`[A]' => sub { 
::is scalar do {\12    ~~ ScalarRefRef}, scalar do{1}, '\12    ~~ ScalarRefRef                    # -> 1';
::is scalar do {\12    ~~ ScalarRefRef}, scalar do{1}, '\12    ~~ ScalarRefRef                    # -> 1';
::is scalar do {\-1.2  ~~ ScalarRefRef[Num]}, scalar do{1}, '\-1.2  ~~ ScalarRefRef[Num]               # -> 1';
::is scalar do {\\-1.2 ~~ ScalarRefRef[ScalarRefRef[Num]]}, scalar do{1}, '\\-1.2 ~~ ScalarRefRef[ScalarRefRef[Num]] # -> 1';

# 
# ## ScalarRef`[A]
# 
# Ссылка на скаляр.
# 
::done_testing; }; subtest 'ScalarRef`[A]' => sub { 
::is scalar do {\12   ~~ ScalarRef}, scalar do{1}, '\12   ~~ ScalarRef      # -> 1';
::is scalar do {\\12  ~~ ScalarRef}, scalar do{""}, '\\12  ~~ ScalarRef      # -> ""';
::is scalar do {\-1.2 ~~ ScalarRef[Num]}, scalar do{1}, '\-1.2 ~~ ScalarRef[Num] # -> 1';

# 
# ## RefRef`[A]
# 
# Ссылка на ссылку.
# 
::done_testing; }; subtest 'RefRef`[A]' => sub { 
::is scalar do {\12    ~~ RefRef}, scalar do{""}, '\12    ~~ RefRef                 # -> ""';
::is scalar do {\\12   ~~ RefRef}, scalar do{1}, '\\12   ~~ RefRef                 # -> 1';
::is scalar do {\-1.2  ~~ RefRef[Num]}, scalar do{""}, '\-1.2  ~~ RefRef[Num]            # -> ""';
::is scalar do {\\-1.2 ~~ RefRef[ScalarRef[Num]]}, scalar do{1}, '\\-1.2 ~~ RefRef[ScalarRef[Num]] # -> 1';

# 
# ## GlobRef
# 
# Ссылка на глоб.
# 
::done_testing; }; subtest 'GlobRef' => sub { 
::is scalar do {\*A::a ~~ GlobRef}, scalar do{1}, '\*A::a ~~ GlobRef # -> 1';
::is scalar do {*A::a ~~ GlobRef}, scalar do{""}, '*A::a ~~ GlobRef  # -> ""';

# 
# ## FileHandle
# 
# Файловый описатель.
# 
::done_testing; }; subtest 'FileHandle' => sub { 
::is scalar do {\*A::a ~~ FileHandle}, scalar do{""}, '\*A::a ~~ FileHandle         # -> ""';
::is scalar do {\*STDIN ~~ FileHandle}, scalar do{1}, '\*STDIN ~~ FileHandle        # -> 1';

open my $fh, "<", "/dev/null";
::is scalar do {$fh ~~ FileHandle}, scalar do{1}, '$fh ~~ FileHandle	         # -> 1';
close $fh;

opendir my $dh, ".";
::is scalar do {$dh ~~ FileHandle}, scalar do{1}, '$dh ~~ FileHandle	         # -> 1';
closedir $dh;

use constant { PF_UNIX => 1, SOCK_STREAM => 1 };

socket my $sock, PF_UNIX, SOCK_STREAM, 0;
::is scalar do {$sock ~~ FileHandle}, scalar do{1}, '$sock ~~ FileHandle	         # -> 1';
close $sock;

# 
# ## ArrayRef`[A]
# 
# Ссылки на массивы.
# 
::done_testing; }; subtest 'ArrayRef`[A]' => sub { 
::is scalar do {[] ~~ ArrayRef}, scalar do{1}, '[] ~~ ArrayRef	# -> 1';
::is scalar do {{} ~~ ArrayRef}, scalar do{""}, '{} ~~ ArrayRef	# -> ""';
::is scalar do {[] ~~ ArrayRef[Num]}, scalar do{1}, '[] ~~ ArrayRef[Num]	# -> 1';
::is scalar do {{} ~~ ArrayRef[Num]}, scalar do{''}, '{} ~~ ArrayRef[Num]	# -> \'\'';
::is scalar do {[1, 1.1] ~~ ArrayRef[Num]}, scalar do{1}, '[1, 1.1] ~~ ArrayRef[Num]	# -> 1';
::is scalar do {[1, undef] ~~ ArrayRef[Num]}, scalar do{""}, '[1, undef] ~~ ArrayRef[Num]	# -> ""';

# 
# ## Lim[A, B?]
# 
# Ограничивает массивы от `A` до `B` элементов или от 0 до `A`, если `B` отсутствует.
# 
::done_testing; }; subtest 'Lim[A, B?]' => sub { 
::is scalar do {[] ~~ Lim[5]}, scalar do{1}, '[] ~~ Lim[5]     # -> 1';
::is scalar do {[1..5] ~~ Lim[5]}, scalar do{1}, '[1..5] ~~ Lim[5] # -> 1';
::is scalar do {[1..6] ~~ Lim[5]}, scalar do{""}, '[1..6] ~~ Lim[5] # -> ""';

::is scalar do {[1..5] ~~ Lim[1,5]}, scalar do{1}, '[1..5] ~~ Lim[1,5] # -> 1';
::is scalar do {[1..6] ~~ Lim[1,5]}, scalar do{""}, '[1..6] ~~ Lim[1,5] # -> ""';

::is scalar do {[1] ~~ Lim[1,5]}, scalar do{1}, '[1] ~~ Lim[1,5] # -> 1';
::is scalar do {[] ~~ Lim[1,5]}, scalar do{""}, '[] ~~ Lim[1,5]  # -> ""';

# 
# ## HashRef`[H]
# 
# Ссылки на хеши.
# 
::done_testing; }; subtest 'HashRef`[H]' => sub { 
::is scalar do {{} ~~ HashRef}, scalar do{1}, '{} ~~ HashRef # -> 1';
::is scalar do {\1 ~~ HashRef}, scalar do{""}, '\1 ~~ HashRef # -> ""';

::is scalar do {[]  ~~ HashRef[Int]}, scalar do{""}, '[]  ~~ HashRef[Int]           # -> ""';
::is scalar do {{x=>1, y=>2}  ~~ HashRef[Int]}, scalar do{1}, '{x=>1, y=>2}  ~~ HashRef[Int] # -> 1';
::is scalar do {{x=>1, y=>""} ~~ HashRef[Int]}, scalar do{""}, '{x=>1, y=>""} ~~ HashRef[Int] # -> ""';

# 
# ## Object`[O]
# 
# Благословлённые ссылки.
# 
::done_testing; }; subtest 'Object`[O]' => sub { 
::is scalar do {bless(\(my $val=10), "A1") ~~ Object}, scalar do{1}, 'bless(\(my $val=10), "A1") ~~ Object # -> 1';
::is scalar do {\(my $val=10) ~~ Object}, scalar do{""}, '\(my $val=10) ~~ Object              # -> ""';

::is scalar do {bless(\(my $val=10), "A1") ~~ Object["A1"]}, scalar do{1}, 'bless(\(my $val=10), "A1") ~~ Object["A1"] # -> 1';
::is scalar do {bless(\(my $val=10), "A1") ~~ Object["B1"]}, scalar do{""}, 'bless(\(my $val=10), "A1") ~~ Object["B1"] # -> ""';

# 
# ## Me
# 
# Благословенные ссылки на объекты текущего пакета.
# 
::done_testing; }; subtest 'Me' => sub { 
package A1 {
 use Aion;
::is scalar do {bless({}, __PACKAGE__) ~~ Me}, scalar do{1}, ' bless({}, __PACKAGE__) ~~ Me  # -> 1';
::is scalar do {bless({}, "A2") ~~ Me}, scalar do{""}, ' bless({}, "A2") ~~ Me         # -> ""';
}

# 
# ## Map[K, V]
# 
# Как `HashRef`, но с типом для ключей.
# 
::done_testing; }; subtest 'Map[K, V]' => sub { 
::is scalar do {{} ~~ Map[Int, Int]}, scalar do{1}, '{} ~~ Map[Int, Int]               # -> 1';
::is scalar do {{5 => 3} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3} ~~ Map[Int, Int]         # -> 1';
::is scalar do {+{5.5 => 3} ~~ Map[Int, Int]}, scalar do{""}, '+{5.5 => 3} ~~ Map[Int, Int]      # -> ""';
::is scalar do {{5 => 3.3} ~~ Map[Int, Int]}, scalar do{""}, '{5 => 3.3} ~~ Map[Int, Int]       # -> ""';
::is scalar do {{5 => 3, 6 => 7} ~~ Map[Int, Int]}, scalar do{1}, '{5 => 3, 6 => 7} ~~ Map[Int, Int] # -> 1';

# 
# ## Tuple[A...]
# 
# Тьюпл.
# 
::done_testing; }; subtest 'Tuple[A...]' => sub { 
::is scalar do {["a", 12] ~~ Tuple[Str, Int]}, scalar do{1}, '["a", 12] ~~ Tuple[Str, Int]    # -> 1';
::is scalar do {["a", 12, 1] ~~ Tuple[Str, Int]}, scalar do{""}, '["a", 12, 1] ~~ Tuple[Str, Int] # -> ""';
::is scalar do {["a", 12.1] ~~ Tuple[Str, Int]}, scalar do{""}, '["a", 12.1] ~~ Tuple[Str, Int]  # -> ""';

# 
# ## CycleTuple[A...]
# 
# Тьюпл повторённый один или несколько раз.
# 
::done_testing; }; subtest 'CycleTuple[A...]' => sub { 
::is scalar do {["a", -5] ~~ CycleTuple[Str, Int]}, scalar do{1}, '["a", -5] ~~ CycleTuple[Str, Int] # -> 1';
::is scalar do {["a", -5, "x"] ~~ CycleTuple[Str, Int]}, scalar do{""}, '["a", -5, "x"] ~~ CycleTuple[Str, Int] # -> ""';
::is scalar do {["a", -5, "x", -6] ~~ CycleTuple[Str, Int]}, scalar do{1}, '["a", -5, "x", -6] ~~ CycleTuple[Str, Int] # -> 1';
::is scalar do {["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]}, scalar do{""}, '["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int] # -> ""';

# 
# ## Dict[k => A, ...]
# 
# Словарь.
# 
::done_testing; }; subtest 'Dict[k => A, ...]' => sub { 
::is scalar do {{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]}, scalar do{1}, '{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str] # -> 1';

::is scalar do {{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]}, scalar do{""}, '{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str] # -> ""';
::is scalar do {{a => -1.6} ~~ Dict[a => Num, b => Str]}, scalar do{""}, '{a => -1.6} ~~ Dict[a => Num, b => Str] # -> ""';

::is scalar do {{a => -1.6} ~~ Dict[a => Num, b => Option[Str]]}, scalar do{1}, '{a => -1.6} ~~ Dict[a => Num, b => Option[Str]] # -> 1';

# 
# ## HasProp[p...]
# 
# Хэш имеет перечисленные свойства. Кроме них он может иметь и другие.
# 
::done_testing; }; subtest 'HasProp[p...]' => sub { 
::is scalar do {[0, 1] ~~ HasProp[qw/0 1/]}, scalar do{""}, '[0, 1] ~~ HasProp[qw/0 1/] # -> ""';

::is scalar do {{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/] # -> 1';
::is scalar do {{a => 1, b => 2} ~~ HasProp[qw/a b/]}, scalar do{1}, '{a => 1, b => 2} ~~ HasProp[qw/a b/] # -> 1';
::is scalar do {{a => 1, c => 3} ~~ HasProp[qw/a b/]}, scalar do{""}, '{a => 1, c => 3} ~~ HasProp[qw/a b/] # -> ""';

::is scalar do {bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/]}, scalar do{1}, 'bless({a => 1, b => 3}, "A") ~~ HasProp[qw/a b/] # -> 1';

# 
# ## Like
# 
# Объект или строка.
# 
::done_testing; }; subtest 'Like' => sub { 
::is scalar do {"" ~~ Like}, scalar do{1}, '"" ~~ Like # -> 1';
::is scalar do {1 ~~ Like}, scalar do{1}, '1 ~~ Like  # -> 1';
::is scalar do {bless({}, "A") ~~ Like}, scalar do{1}, 'bless({}, "A") ~~ Like # -> 1';
::is scalar do {bless([], "A") ~~ Like}, scalar do{1}, 'bless([], "A") ~~ Like # -> 1';
::is scalar do {bless(\(my $str = ""), "A") ~~ Like}, scalar do{1}, 'bless(\(my $str = ""), "A") ~~ Like # -> 1';
::is scalar do {\1 ~~ Like}, scalar do{""}, '\1 ~~ Like  # -> ""';

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

::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]			# -> 1';
::is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1';
::is scalar do {bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]}, scalar do{1}, 'bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]	# -> 1';
::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x3/]				# -> ""';
::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]			# -> ""';
::is scalar do {"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]}, scalar do{""}, '"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]			# -> ""';

# 
# ## Overload`[op...]
# 
# Объект или класс с перегруженными операторами.
# 
::done_testing; }; subtest 'Overload`[op...]' => sub { 
package OverloadExample {
	use overload '""' => sub { "abc" };
}

::is scalar do {"OverloadExample" ~~ Overload}, scalar do{1}, '"OverloadExample" ~~ Overload            # -> 1';
::is scalar do {bless({}, "OverloadExample") ~~ Overload}, scalar do{1}, 'bless({}, "OverloadExample") ~~ Overload # -> 1';
::is scalar do {"A" ~~ Overload}, scalar do{""}, '"A" ~~ Overload                          # -> ""';
::is scalar do {bless({}, "A") ~~ Overload}, scalar do{""}, 'bless({}, "A") ~~ Overload               # -> ""';

# 
# И у него есть операторы указанные операторы.
# 

::is scalar do {"OverloadExample" ~~ Overload['""']}, scalar do{1}, '"OverloadExample" ~~ Overload[\'""\'] # -> 1';
::is scalar do {"OverloadExample" ~~ Overload['|']}, scalar do{""}, '"OverloadExample" ~~ Overload[\'|\']  # -> ""';

# 
# ## InstanceOf[A...]
# 
# Класс или объект наследует классы из списка.
# 
::done_testing; }; subtest 'InstanceOf[A...]' => sub { 
package Animal {}
package Cat { our @ISA = qw/Animal/ }
package Tiger { our @ISA = qw/Cat/ }


::is scalar do {"Tiger" ~~ InstanceOf['Animal', 'Cat']}, scalar do{1}, '"Tiger" ~~ InstanceOf[\'Animal\', \'Cat\'] # -> 1';
::is scalar do {"Tiger" ~~ InstanceOf['Tiger']}, scalar do{1}, '"Tiger" ~~ InstanceOf[\'Tiger\']         # -> 1';
::is scalar do {"Tiger" ~~ InstanceOf['Cat', 'Dog']}, scalar do{""}, '"Tiger" ~~ InstanceOf[\'Cat\', \'Dog\']    # -> ""';

# 
# ## ConsumerOf[A...]
# 
# Класс или объект имеет указанные роли.
# 
::done_testing; }; subtest 'ConsumerOf[A...]' => sub { 
package NoneExample {}
package RoleExample { sub DOES { $_[1] ~~ [qw/Role1 Role2/] } }

::is scalar do {'RoleExample' ~~ ConsumerOf[qw/Role1/]}, scalar do{1}, '\'RoleExample\' ~~ ConsumerOf[qw/Role1/] # -> 1';
::is scalar do {'RoleExample' ~~ ConsumerOf[qw/Role2 Role1/]}, scalar do{1}, '\'RoleExample\' ~~ ConsumerOf[qw/Role2 Role1/] # -> 1';
::is scalar do {bless({}, 'RoleExample') ~~ ConsumerOf[qw/Role3 Role2 Role1/]}, scalar do{""}, 'bless({}, \'RoleExample\') ~~ ConsumerOf[qw/Role3 Role2 Role1/] # -> ""';

::is scalar do {'NoneExample' ~~ ConsumerOf[qw/Role1/]}, scalar do{""}, '\'NoneExample\' ~~ ConsumerOf[qw/Role1/] # -> ""';

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

::is scalar do {bless(\(my $x = 1 ), 'BoolLikeExample') ~~ BoolLike}, scalar do{1}, 'bless(\(my $x = 1 ), \'BoolLikeExample\') ~~ BoolLike # -> 1';
::is scalar do {bless(\(my $x = 11), 'BoolLikeExample') ~~ BoolLike}, scalar do{""}, 'bless(\(my $x = 11), \'BoolLikeExample\') ~~ BoolLike # -> ""';

::is scalar do {1 ~~ BoolLike}, scalar do{1}, '1 ~~ BoolLike     # -> 1';
::is scalar do {0 ~~ BoolLike}, scalar do{1}, '0 ~~ BoolLike     # -> 1';
::is scalar do {"" ~~ BoolLike}, scalar do{1}, '"" ~~ BoolLike    # -> 1';
::is scalar do {undef ~~ BoolLike}, scalar do{1}, 'undef ~~ BoolLike # -> 1';

package BoolLike2Example {
	use overload 'bool' => sub { ${$_[0]} };
}

::is scalar do {bless(\(my $x = 1 ), 'BoolLike2Example') ~~ BoolLike}, scalar do{1}, 'bless(\(my $x = 1 ), \'BoolLike2Example\') ~~ BoolLike # -> 1';
::is scalar do {bless(\(my $x = 11), 'BoolLike2Example') ~~ BoolLike}, scalar do{1}, 'bless(\(my $x = 11), \'BoolLike2Example\') ~~ BoolLike # -> 1';

# 
# ## StrLike
# 
# Строка или объект с перегруженным оператором `""`.
# 
::done_testing; }; subtest 'StrLike' => sub { 
::is scalar do {"" ~~ StrLike}, scalar do{1}, '"" ~~ StrLike # -> 1';

package StrLikeExample {
	use overload '""' => sub { "abc" };
}

::is scalar do {bless({}, "StrLikeExample") ~~ StrLike}, scalar do{1}, 'bless({}, "StrLikeExample") ~~ StrLike # -> 1';

::is scalar do {{} ~~ StrLike}, scalar do{""}, '{} ~~ StrLike # -> ""';

# 
# ## RegexpLike
# 
# Регулярное выражение или объект с перегруженным оператором `qr`.
# 
::done_testing; }; subtest 'RegexpLike' => sub { 
::is scalar do {ref(qr//)}, "Regexp", 'ref(qr//)  # => Regexp';
::is scalar do {Scalar::Util::reftype(qr//)}, "REGEXP", 'Scalar::Util::reftype(qr//) # => REGEXP';

my $regex = bless qr//, "A";
::is scalar do {Scalar::Util::reftype($regex)}, "REGEXP", 'Scalar::Util::reftype($regex) # => REGEXP';

::is scalar do {$regex ~~ RegexpLike}, scalar do{1}, '$regex ~~ RegexpLike # -> 1';
::is scalar do {qr// ~~ RegexpLike}, scalar do{1}, 'qr// ~~ RegexpLike   # -> 1';
::is scalar do {"" ~~ RegexpLike}, scalar do{""}, '"" ~~ RegexpLike     # -> ""';

package RegexpLikeExample {
 use overload 'qr' => sub { qr/abc/ };
}

::is scalar do {"RegexpLikeExample" ~~ RegexpLike}, scalar do{""}, '"RegexpLikeExample" ~~ RegexpLike # -> ""';
::is scalar do {bless({}, "RegexpLikeExample") ~~ RegexpLike}, scalar do{1}, 'bless({}, "RegexpLikeExample") ~~ RegexpLike # -> 1';

# 
# ## CodeLike
# 
# Подпрограмма или объект с перегруженным оператором `&{}`.
# 
::done_testing; }; subtest 'CodeLike' => sub { 
::is scalar do {sub {} ~~ CodeLike}, scalar do{1}, 'sub {} ~~ CodeLike     # -> 1';
::is scalar do {\&CodeLike ~~ CodeLike}, scalar do{1}, '\&CodeLike ~~ CodeLike # -> 1';
::is scalar do {{} ~~ CodeLike}, scalar do{""}, '{} ~~ CodeLike         # -> ""';

# 
# ## ArrayLike`[A]
# 
# Массивы или объекты с перегруженным оператором или `@{}`.
# 
::done_testing; }; subtest 'ArrayLike`[A]' => sub { 
::is scalar do {{} ~~ ArrayLike}, scalar do{""}, '{} ~~ ArrayLike      # -> ""';
::is scalar do {{} ~~ ArrayLike[Int]}, scalar do{""}, '{} ~~ ArrayLike[Int] # -> ""';

::is scalar do {[] ~~ ArrayLike}, scalar do{1}, '[] ~~ ArrayLike # -> 1';

package ArrayLikeExample {
	use overload '@{}' => sub {
		shift->{array} //= []
	};
}

my $x = bless {}, 'ArrayLikeExample';
$x->[1] = 12;
::is_deeply scalar do {$x->{array}}, scalar do {[undef, 12]}, '$x->{array} # --> [undef, 12]';

::is scalar do {$x ~~ ArrayLike}, scalar do{1}, '$x ~~ ArrayLike # -> 1';

::is scalar do {$x ~~ ArrayLike[Int]}, scalar do{""}, '$x ~~ ArrayLike[Int] # -> ""';

$x->[0] = 13;
::is scalar do {$x ~~ ArrayLike[Int]}, scalar do{1}, '$x ~~ ArrayLike[Int] # -> 1';

# 
# ## HashLike`[A]
# 
# Хэши или объекты с перегруженным оператором `%{}`.
# 
::done_testing; }; subtest 'HashLike`[A]' => sub { 
::is scalar do {{} ~~ HashLike}, scalar do{1}, '{} ~~ HashLike  # -> 1';
::is scalar do {[] ~~ HashLike}, scalar do{""}, '[] ~~ HashLike  # -> ""';
::is scalar do {[] ~~ HashLike[Int]}, scalar do{""}, '[] ~~ HashLike[Int] # -> ""';

package HashLikeExample {
	use overload '%{}' => sub {
		shift->[0] //= {}
	};
}

my $x = bless [], 'HashLikeExample';
$x->{key} = 12.3;
::is_deeply scalar do {$x->[0]}, scalar do {{key => 12.3}}, '$x->[0]  # --> {key => 12.3}';

::is scalar do {$x ~~ HashLike}, scalar do{1}, '$x ~~ HashLike      # -> 1';
::is scalar do {$x ~~ HashLike[Int]}, scalar do{""}, '$x ~~ HashLike[Int] # -> ""';
::is scalar do {$x ~~ HashLike[Num]}, scalar do{1}, '$x ~~ HashLike[Num] # -> 1';

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
