use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Annotation::Reader - считывает аннотации, комментарии и времена обновления модулей
# 
# # VERSION
# 
# 0.1.0
# 
# # SYNOPSIS
# 
# Файл etc/annotation/todo.ann:
#@> etc/annotation/todo.ann
#>> For::Test#abc,5=add1
#>> For::Test#xyz,11=add2
#@< EOF
# 
# Файл etc/annotation/remarks.ini:
#@> etc/annotation/remarks.ini
#>> For::Test#,4=The package for testing
#>> For::Test#abc,9=Is property\n  readonly
#@< EOF
# 
# Файл var/cache/modules.mtime.ini:
#@> var/cache/modules.mtime.ini
#>> For::Test=2025-01-02 03:04:05
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Annotation::Reader;
use Time::Local qw/timelocal/;

my $reader = Aion::Annotation::Reader->new('todo');

my @ann; push @ann, $_ while <$reader>;

my $ann = [
	{pkg => 'For::Test', name => 'abc', line => '5',  annotation => 'add1'},
	{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'},
];

local ($::_g0 = do {\@ann}, $::_e0 = do {$ann}); ::is_deeply $::_g0, $::_e0, '\@ann # --> $ann' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $reader_remarks = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_REMARKS);

my $remarks = [
	{pkg => 'For::Test', name => '',    line => '4', remark => 'The package for testing'},
	{pkg => 'For::Test', name => 'abc', line => '9', remark => "Is property\n  readonly"},
];

local ($::_g0 = do {\@{$reader_remarks}}, $::_e0 = do {$remarks}); ::is_deeply $::_g0, $::_e0, '\@{$reader_remarks} # --> $remarks' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $reader_mtime = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_MTIME);

# Время хранится как unixtime, поэтому ожидаемое значение не зависит от часового пояса
my $mtime = [{pkg => 'For::Test', mtime => timelocal(5, 4, 3, 2, 0, 2025)}];

local ($::_g0 = do {\@{$reader_mtime}}, $::_e0 = do {$mtime}); ::is_deeply $::_g0, $::_e0, '\@{$reader_mtime} # --> $mtime' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Annotation::Reader` читает файлы, которые создаёт [Aion::Annotation](https://metacpan.org/pod/Aion::Annotation), и отдаёт их содержимое построчно в виде хешей.
# 
# Доступны три вида данных:
# 
# 1. Аннотации из файлов **имя.ann** (имя передаётся в конструктор).
# 2. Комментарии из **remarks.ini**.
# 3. Времена обновления модулей из **modules.mtime.ini**.
# 
# Читатель спроектирован как итератор поверх файла: конструктор открывает файл, а метод `next` возвращает очередной распознанный элемент. Объект перегружает ряд операций, чтобы читателя можно было использовать как файл или функцию прямо в выражениях.
# 
# Распознанные строки представляются хешами:
# 
# 1. Аннотация (файл **etc/annotation/*.ann**) – ключи `pkg`, `name`, `line`, `annotation`.
# 2. Комментарий (файл **etc/annotation/remarks.ini**) – ключи `pkg`, `name`, `line`, `remark`.
# 3. Время (файл **var/cache/modules.mtime.ini**) – ключи `pkg`, `mtime`.
# 
# Каталоги настраиваются переменными окружения `AION_ANNOTATION_INI` (по умолчанию `etc/annotation`) и `AION_ANNOTATION_CACHE` (по умолчанию `var/cache`).
# 
# # OVERLOAD
# 
# `Aion::Annotation::Reader` перегружает операции:
# 
# ## <>
# 
# Вызов читателя.
# 
::done_testing; }; subtest '<>' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');

my @ann; push @ann, $_ while <$reader>;
local ($::_g0 = do {0+@ann}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0+@ann  # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## @{}
# 
# Список всех элементов.
# 
::done_testing; }; subtest '@{}' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');

my $ann = [
	{pkg => 'For::Test', name => 'abc', line => '5',  annotation => 'add1'},
	{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'},
];

local ($::_g0 = do {\@{$reader}}, $::_e0 = do {$ann}); ::is_deeply $::_g0, $::_e0, '\@{$reader} # --> $ann' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## &{}
# 
# Вызов как функции.
# 
# Каждое обращение возвращает следующий элемент или `undef` в конце:
# 
::done_testing; }; subtest '&{}' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');

local ($::_g0 = do {&$reader}, $::_e0 = do {{pkg => 'For::Test', name => 'abc', line => '5', annotation => 'add1'}}); ::is_deeply $::_g0, $::_e0, '&$reader # --> {pkg => \'For::Test\', name => \'abc\', line => \'5\', annotation => \'add1\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {&$reader}, $::_e0 = do {{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'}}); ::is_deeply $::_g0, $::_e0, '&$reader # --> {pkg => \'For::Test\', name => \'xyz\', line => \'11\', annotation => \'add2\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {&$reader}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '&$reader # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## *{}
# 
# Файловый дескриптор.
# 
::done_testing; }; subtest '*{}' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');
my $fh = *$reader;
::like scalar do {readline $fh}, qr{^For::Test#abc,5=add1$}, 'readline $fh  # ~> ^For::Test#abc,5=add1$'; undef $::_g0; undef $::_e0;

# 
# ## -X
# 
# Файловые операции.
# 
# Операции вида `-e`, `-s`, `-f` выполняются над файлом читателя. Результат операции кешируется:
# 
::done_testing; }; subtest '-X' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {-e $reader}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-e $reader # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-s $reader}, $::_e0 = do {43}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-s $reader # -> 43' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-f $reader}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-f $reader # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ""
# 
# Строковое представление.
# 
::done_testing; }; subtest '""' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {"$reader"}, $::_e0 = "Aion::Annotation::Reader<ann,etc/annotation/todo.ann>"); ::ok $::_g0 eq $::_e0, '"$reader" # => Aion::Annotation::Reader<ann,etc/annotation/todo.ann>' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # CONSTANTS
# 
# ## READ_REMARKS
# 
# Специальное имя, при котором читается файл комментариев:
# 
::done_testing; }; subtest 'READ_REMARKS' => sub { 
local ($::_g0 = do {Aion::Annotation::Reader::READ_REMARKS}, $::_e0 = do {"-remarks"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Aion::Annotation::Reader::READ_REMARKS  # -> "-remarks"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## READ_MTIME
# 
# Специальное имя, при котором читается файл времён обновления:
# 
::done_testing; }; subtest 'READ_MTIME' => sub { 
local ($::_g0 = do {Aion::Annotation::Reader::READ_MTIME}, $::_e0 = do {"-mtime"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Aion::Annotation::Reader::READ_MTIME  # -> "-mtime"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MODULES_MTIME_FILE
# 
# Имя файла времён обновления:
# 
::done_testing; }; subtest 'MODULES_MTIME_FILE' => sub { 
local ($::_g0 = do {Aion::Annotation::Reader::MODULES_MTIME_FILE}, $::_e0 = do {"modules.mtime.ini"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Aion::Annotation::Reader::MODULES_MTIME_FILE  # -> "modules.mtime.ini"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## REMARKS_FILE
# 
# Имя файла комментариев:
# 
::done_testing; }; subtest 'REMARKS_FILE' => sub { 
local ($::_g0 = do {Aion::Annotation::Reader::REMARKS_FILE}, $::_e0 = do {"remarks.ini"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Aion::Annotation::Reader::REMARKS_FILE  # -> "remarks.ini"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## LINE_REGEX
# 
# Регулярное выражение строки аннотации или комментария:
# 
::done_testing; }; subtest 'LINE_REGEX' => sub { 
my $line = 'For::Test#abc,5=add1';
my ($pkg, $name, $lineno, $text) = $line =~ Aion::Annotation::Reader::LINE_REGEX;
local ($::_g0 = do {"$pkg|$name|$lineno|$text"}, $::_e0 = do {"For::Test|abc|5|add1"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"$pkg|$name|$lineno|$text"  # -> "For::Test|abc|5|add1"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MTIME_REGEX
# 
# Регулярное выражение строки времени обновления:
# 
::done_testing; }; subtest 'MTIME_REGEX' => sub { 
my $line = 'For::Test=2025-01-02 03:04:05';
$line =~ Aion::Annotation::Reader::MTIME_REGEX;
local ($::_g0 = do {"$+{module}|$+{year}-$+{mon}-$+{mday} $+{hour}:$+{min}:$+{sec}"}, $::_e0 = do {"For::Test|2025-01-02 03:04:05"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"$+{module}|$+{year}-$+{mon}-$+{mday} $+{hour}:$+{min}:$+{sec}"  # -> "For::Test|2025-01-02 03:04:05"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SUBROUTINES
# 
# ## new ($cls, $ann)
# 
# Конструктор. В `$ann` передаётся имя аннотации (тогда читается `etc/annotation/$ann.ann`), либо константы `READ_REMARKS` или `READ_MTIME`. Файл открывается сразу в конструкторе:
# 
::done_testing; }; subtest 'new ($cls, $ann)' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {ref $reader}, $::_e0 = do {"Aion::Annotation::Reader"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $reader       # -> "Aion::Annotation::Reader"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$reader->{type}}, $::_e0 = do {"ann"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$reader->{type}   # -> "ann"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$reader->path}, $::_e0 = do {"etc/annotation/todo.ann"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$reader->path     # -> "etc/annotation/todo.ann"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Вызов допустим и у экземпляра:
# 

my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {$reader->new('todo')->path}, $::_e0 = do {"etc/annotation/todo.ann"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$reader->new(\'todo\')->path  # -> "etc/annotation/todo.ann"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Если файла нет – бросается исключение:
# 

eval { Aion::Annotation::Reader->new('no_such_annotation') };
::like scalar do {$@}, qr{^etc/annotation/no_such_annotation\.ann:}, '$@ # ~> ^etc/annotation/no_such_annotation\.ann:'; undef $::_g0; undef $::_e0;

# 
# ## path ()
# 
# Путь к открытому файлу:
# 
::done_testing; }; subtest 'path ()' => sub { 
my $reader = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_REMARKS);
local ($::_g0 = do {$reader->path}, $::_e0 = do {"etc/annotation/remarks.ini"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$reader->path  # -> "etc/annotation/remarks.ini"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## next ()
# 
# Возвращает следующий распознанный элемент. В скалярном контексте – один элемент или `undef`, в списочном – все оставшиеся элементы:
# 
::done_testing; }; subtest 'next ()' => sub { 
my $reader = Aion::Annotation::Reader->new('todo');

local ($::_g0 = do {scalar $reader->next}, $::_e0 = do {{pkg => 'For::Test', name => 'abc', line => '5', annotation => 'add1'}}); ::is_deeply $::_g0, $::_e0, 'scalar $reader->next # --> {pkg => \'For::Test\', name => \'abc\', line => \'5\', annotation => \'add1\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar $reader->next}, $::_e0 = do {{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'}}); ::is_deeply $::_g0, $::_e0, 'scalar $reader->next # --> {pkg => \'For::Test\', name => \'xyz\', line => \'11\', annotation => \'add2\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar $reader->next}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar $reader->next # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## DESTROY ()
# 
# Закрывает файл при уничтожении объекта. Обычно вызывается автоматически:
# 
::done_testing; }; subtest 'DESTROY ()' => sub { 
my $f;
{
	my $reader = Aion::Annotation::Reader->new('todo');
	$f = $reader->{f};
local ($::_g0 = do {defined fileno $f}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	defined fileno $f # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
} # $reader->DESTROY closes the file

local ($::_g0 = do {fileno $f}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'fileno $f  # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## detect_annotation ($self, $line)
# 
# Распознаёт строку аннотации. Возвращает хеш с ключами `pkg`, `name`, `line`, `annotation`:
# 
::done_testing; }; subtest 'detect_annotation ($self, $line)' => sub { 
my $test = {
	pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'
};

my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {Aion::Annotation::Reader::detect_annotation($reader, "For::Test#xyz,11=add2\n")}, $::_e0 = do {$test}); ::is_deeply $::_g0, $::_e0, 'Aion::Annotation::Reader::detect_annotation($reader, "For::Test#xyz,11=add2\n") # --> $test' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## detect_remark ($self, $line)
# 
# Распознаёт строку комментария. Экранированные последовательности `\n` превращаются в переводы строк, а `\<символ>` – в сам символ:
# 
::done_testing; }; subtest 'detect_remark ($self, $line)' => sub { 
my $test = {
	pkg => 'For::Test', name => 'abc', line => '9', remark => "Is property\n  readonly"
};

my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {Aion::Annotation::Reader::detect_remark($reader, "For::Test#abc,9=Is property\\n  readonly\n")}, $::_e0 = do {$test}); ::is_deeply $::_g0, $::_e0, 'Aion::Annotation::Reader::detect_remark($reader, "For::Test#abc,9=Is property\\n  readonly\n") # --> $test' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## detect_mtime ($self, $line)
# 
# Распознаёт строку времени обновления. Поле `mtime` — это unixtime (в локальном часовом поясе):
# 
::done_testing; }; subtest 'detect_mtime ($self, $line)' => sub { 
use Time::Local qw/timelocal/;

my $test = {
	pkg => 'For::Test', mtime => timelocal(5, 4, 3, 2, 0, 2025)
};

my $reader = Aion::Annotation::Reader->new('todo');
local ($::_g0 = do {Aion::Annotation::Reader::detect_mtime($reader, "For::Test=2025-01-02 03:04:05\n")}, $::_e0 = do {$test}); ::is_deeply $::_g0, $::_e0, 'Aion::Annotation::Reader::detect_mtime($reader, "For::Test=2025-01-02 03:04:05\n") # --> $test' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # CORRUPT LINES
# 
# Если строка не соответствует формату, выдаётся предупреждение (`warn`), а элемент всё равно возвращается – с неопределёнными полями. Это позволяет не прерывать чтение на повреждённом файле:
# 
::done_testing; }; subtest 'CORRUPT LINES' => sub { 
use Aion::Annotation::Reader;

my @warn;
local $SIG{__WARN__} = sub { push @warn, @_ };

my $reader = Aion::Annotation::Reader->new('todo');

local ($::_g0 = do {Aion::Annotation::Reader::detect_annotation($reader, "corrupt line\n")}, $::_e0 = do {{pkg => undef, name => undef, line => undef, annotation => undef}}); ::is_deeply $::_g0, $::_e0, 'Aion::Annotation::Reader::detect_annotation($reader, "corrupt line\n") # --> {pkg => undef, name => undef, line => undef, annotation => undef}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Aion::Annotation::Reader::detect_remark($reader, "corrupt line\n")}, $::_e0 = do {{pkg => undef, name => undef, line => undef, remark => ''}}); ::is_deeply $::_g0, $::_e0, 'Aion::Annotation::Reader::detect_remark($reader, "corrupt line\n") # --> {pkg => undef, name => undef, line => undef, remark => \'\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Aion::Annotation::Reader::detect_mtime($reader, "corrupt line\n")}, $::_e0 = do {{pkg => undef, mtime => undef}}); ::is_deeply $::_g0, $::_e0, 'Aion::Annotation::Reader::detect_mtime($reader, "corrupt line\n") # --> {pkg => undef, mtime => undef}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {0+@warn}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0+@warn  # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {$warn[0]}, qr{^etc/annotation/todo\.ann corrupt on line}, '$warn[0] # ~> ^etc/annotation/todo\.ann corrupt on line'; undef $::_g0; undef $::_e0;

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
# The Aion::Annotation::Reader module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
