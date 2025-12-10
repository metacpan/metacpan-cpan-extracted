use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Meta::Feature - метаописатель фичи
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Meta::Feature;

our $feature = Aion::Meta::Feature->new("My::Package", "my_feature" => (is => 'rw'));

local ($::_g0 = do {$feature->stringify}, $::_e0 = "has my_feature => (is => 'rw') of My::Package"); ::ok $::_g0 eq $::_e0, '$feature->stringify  # => has my_feature => (is => \'rw\') of My::Package' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Описывает фичу, которая добавляется в класс функцией `has`.
# 
# # METHODS
# 
# ## pkg
# Пакет, к которому относится фича.
# 
::done_testing; }; subtest 'pkg' => sub { 
local ($::_g0 = do {$::feature->pkg}, $::_e0 = do {"My::Package"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->pkg # -> "My::Package"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## name
# Имя фичи.
# 
::done_testing; }; subtest 'name' => sub { 
local ($::_g0 = do {$::feature->name}, $::_e0 = do {"my_feature"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->name # -> "my_feature"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## opt
# Хеш опций фичи.
# 
::done_testing; }; subtest 'opt' => sub { 
local ($::_g0 = do {$::feature->opt}, $::_e0 = do {{is => 'rw'}}); ::is_deeply $::_g0, $::_e0, '$::feature->opt # --> {is => \'rw\'}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## has
# Массив опций фичи в виде пар ключ-значение.
# 
::done_testing; }; subtest 'has' => sub { 
local ($::_g0 = do {$::feature->has}, $::_e0 = do {['is', 'rw']}); ::is_deeply $::_g0, $::_e0, '$::feature->has # --> [\'is\', \'rw\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## construct
# Объект конструктора фичи.
# 
::done_testing; }; subtest 'construct' => sub { 
local ($::_g0 = do {ref $::feature->construct}, $::_e0 = 'Aion::Meta::FeatureConstruct'); ::ok $::_g0 eq $::_e0, 'ref $::feature->construct # \> Aion::Meta::FeatureConstruct' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## order ()
# Порядковый номер фичи в классе.
# 
::done_testing; }; subtest 'order ()' => sub { 
local ($::_g0 = do {$::feature->order}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->order # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## required (;$bool)
# Флаг обязательности фичи в конструкторе (`new`).
# 
::done_testing; }; subtest 'required (;$bool)' => sub { 
$::feature->required(1);
local ($::_g0 = do {$::feature->required}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->required # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## excessive (;$bool)
# Флаг избыточности фичи в конструкторе (`new`). Если она там есть должно выбрасываться исключение.
# 
::done_testing; }; subtest 'excessive (;$bool)' => sub { 
$::feature->excessive(1);
local ($::_g0 = do {$::feature->excessive}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->excessive # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## isa (;Object[Aion::Type])
# Ограничение типа для значения фичи.
# 
::done_testing; }; subtest 'isa (;Object[Aion::Type])' => sub { 
use Aion::Type;

my $Int = Aion::Type->new(name => 'Int');

$::feature->isa($Int);
local ($::_g0 = do {$::feature->isa}, $::_e0 = do {$Int}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->isa # -> $Int' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## lazy (;$bool)
# Флаг ленивой инициализации.
# 
::done_testing; }; subtest 'lazy (;$bool)' => sub { 
$::feature->lazy(1);
local ($::_g0 = do {$::feature->lazy}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->lazy # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## builder (;$sub)
# Билдер значения фичи или `undef`.
# 
::done_testing; }; subtest 'builder (;$sub)' => sub { 
my $builder = sub {};
$::feature->builder($builder);
local ($::_g0 = do {$::feature->builder}, $::_e0 = do {$builder}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->builder # -> $builder' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## default (;$value)
# Значение по умолчанию для фичи.
# 
::done_testing; }; subtest 'default (;$value)' => sub { 
$::feature->default(42);
local ($::_g0 = do {$::feature->default}, $::_e0 = do {42}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->default # -> 42' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## trigger (;$sub)
# Обработчик события изменения значения фичи или `undef`.
# 
::done_testing; }; subtest 'trigger (;$sub)' => sub { 
my $trigger = sub {};
$::feature->trigger($trigger);
local ($::_g0 = do {$::feature->trigger}, $::_e0 = do {$trigger}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->trigger # -> $trigger' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## release (;$sub)
# Обработчик события чтения значения из фичи или `undef`.
# 
::done_testing; }; subtest 'release (;$sub)' => sub { 
my $release = sub {};
$::feature->release($release);
local ($::_g0 = do {$::feature->release}, $::_e0 = do {$release}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->release # -> $release' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## cleaner (;$sub)
# Обработчик события удаления фичи из объекта или `undef`.
# 
::done_testing; }; subtest 'cleaner (;$sub)' => sub { 
my $cleaner = sub {};
$::feature->cleaner($cleaner);
local ($::_g0 = do {$::feature->cleaner}, $::_e0 = do {$cleaner}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->cleaner # -> $cleaner' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## make_reader (;$bool)
# Флаг создания метода-ридера.
# 
::done_testing; }; subtest 'make_reader (;$bool)' => sub { 
$::feature->make_reader(1);
local ($::_g0 = do {$::feature->make_reader}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->make_reader # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## make_writer (;$bool)
# Флаг создания метода-райтера.
# 
::done_testing; }; subtest 'make_writer (;$bool)' => sub { 
$::feature->make_writer(1);
local ($::_g0 = do {$::feature->make_writer}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->make_writer # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## make_predicate (;$bool)
# Флаг создания метода-предиката.
# 
::done_testing; }; subtest 'make_predicate (;$bool)' => sub { 
$::feature->make_predicate(1);
local ($::_g0 = do {$::feature->make_predicate}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->make_predicate # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## make_clearer (;$bool)
# Флаг создания метода-очистителя.
# 
::done_testing; }; subtest 'make_clearer (;$bool)' => sub { 
$::feature->make_clearer(1);
local ($::_g0 = do {$::feature->make_clearer}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->make_clearer # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## new ($pkg, $name, @has)
# Конструктор фичи.
# 
::done_testing; }; subtest 'new ($pkg, $name, @has)' => sub { 
my $feature = Aion::Meta::Feature->new('My::Class', 'attr', is => 'ro', default => 1);
local ($::_g0 = do {$feature->pkg}, $::_e0 = do {"My::Class"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$feature->pkg # -> "My::Class"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$feature->name}, $::_e0 = do {"attr"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$feature->name # -> "attr"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$feature->opt}, $::_e0 = do {{is => 'ro', default => 1}}); ::is_deeply $::_g0, $::_e0, '$feature->opt # --> {is => \'ro\', default => 1}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## stringify ()
# Строковое представление фичи.
# 
::done_testing; }; subtest 'stringify ()' => sub { 
local ($::_g0 = do {$::feature->stringify}, $::_e0 = do {"has my_feature => (is => 'rw') of My::Package"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->stringify # -> "has my_feature => (is => \'rw\') of My::Package"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## mk_property ()
# Создаёт акцессор, геттер, сеттер, предикат и очиститель свойства.
# 
::done_testing; }; subtest 'mk_property ()' => sub { 
package My::Package { use Aion }

$::feature->mk_property;

local ($::_g0 = do {!!My::Package->can('my_feature')}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '!!My::Package->can(\'my_feature\') # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## meta ()
# Возвращает код в виде текста для доступа к метаинформации фичи.
# 
::done_testing; }; subtest 'meta ()' => sub { 
local ($::_g0 = do {$::feature->meta}, $::_e0 = '$Aion::META{\'My::Package\'}{feature}{my_feature}'); ::ok $::_g0 eq $::_e0, '$::feature->meta # \> $Aion::META{\'My::Package\'}{feature}{my_feature}' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## stash ($key; $val)
# Доступ к хранилищу свойств для вызывающего пакета.
# 
::done_testing; }; subtest 'stash ($key; $val)' => sub { 
$::feature->stash('my_key', 'my_value');
local ($::_g0 = do {$::feature->stash('my_key')}, $::_e0 = do {'my_value'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::feature->stash(\'my_key\') # -> \'my_value\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# The Aion::Meta::Feature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
