use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Meta::Feature - метаописатель фичи
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Meta::Feature;

our $feature = Aion::Meta::Feature->new("My::Package", "my_feature" => (is => 'rw'));

::is scalar do {$feature->stringify}, "has my_feature => (is => 'rw') of My::Package", '$feature->stringify  # => has my_feature => (is => \'rw\') of My::Package';

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
::is scalar do {$::feature->pkg}, scalar do{"My::Package"}, '$::feature->pkg # -> "My::Package"';

# 
# ## name
# Имя фичи.
# 
::done_testing; }; subtest 'name' => sub { 
::is scalar do {$::feature->name}, scalar do{"my_feature"}, '$::feature->name # -> "my_feature"';

# 
# ## opt
# Хеш опций фичи.
# 
::done_testing; }; subtest 'opt' => sub { 
::is_deeply scalar do {$::feature->opt}, scalar do {{is => 'rw'}}, '$::feature->opt # --> {is => \'rw\'}';

# 
# ## has
# Массив опций фичи в виде пар ключ-значение.
# 
::done_testing; }; subtest 'has' => sub { 
::is_deeply scalar do {$::feature->has}, scalar do {['is', 'rw']}, '$::feature->has # --> [\'is\', \'rw\']';

# 
# ## construct
# Объект конструктора фичи.
# 
::done_testing; }; subtest 'construct' => sub { 
::is scalar do {ref $::feature->construct}, 'Aion::Meta::FeatureConstruct', 'ref $::feature->construct # \> Aion::Meta::FeatureConstruct';

# 
# ## order ()
# Порядковый номер фичи в классе.
# 
::done_testing; }; subtest 'order ()' => sub { 
::is scalar do {$::feature->order}, scalar do{0}, '$::feature->order # -> 0';

# 
# ## required (;$bool)
# Флаг обязательности фичи в конструкторе (`new`).
# 
::done_testing; }; subtest 'required (;$bool)' => sub { 
$::feature->required(1);
::is scalar do {$::feature->required}, scalar do{1}, '$::feature->required # -> 1';

# 
# ## excessive (;$bool)
# Флаг избыточности фичи в конструкторе (`new`). Если она там есть должно выбрасываться исключение.
# 
::done_testing; }; subtest 'excessive (;$bool)' => sub { 
$::feature->excessive(1);
::is scalar do {$::feature->excessive}, scalar do{1}, '$::feature->excessive # -> 1';

# 
# ## isa (;Object[Aion::Type])
# Ограничение типа для значения фичи.
# 
::done_testing; }; subtest 'isa (;Object[Aion::Type])' => sub { 
use Aion::Type;

my $Int = Aion::Type->new(name => 'Int');

$::feature->isa($Int);
::is scalar do {$::feature->isa}, scalar do{$Int}, '$::feature->isa # -> $Int';

# 
# ## lazy (;$bool)
# Флаг ленивой инициализации.
# 
::done_testing; }; subtest 'lazy (;$bool)' => sub { 
$::feature->lazy(1);
::is scalar do {$::feature->lazy}, scalar do{1}, '$::feature->lazy # -> 1';

# 
# ## builder (;$sub)
# Билдер значения фичи или `undef`.
# 
::done_testing; }; subtest 'builder (;$sub)' => sub { 
my $builder = sub {};
$::feature->builder($builder);
::is scalar do {$::feature->builder}, scalar do{$builder}, '$::feature->builder # -> $builder';

# 
# ## default (;$value)
# Значение по умолчанию для фичи.
# 
::done_testing; }; subtest 'default (;$value)' => sub { 
$::feature->default(42);
::is scalar do {$::feature->default}, scalar do{42}, '$::feature->default # -> 42';

# 
# ## trigger (;$sub)
# Обработчик события изменения значения фичи или `undef`.
# 
::done_testing; }; subtest 'trigger (;$sub)' => sub { 
my $trigger = sub {};
$::feature->trigger($trigger);
::is scalar do {$::feature->trigger}, scalar do{$trigger}, '$::feature->trigger # -> $trigger';

# 
# ## release (;$sub)
# Обработчик события чтения значения из фичи или `undef`.
# 
::done_testing; }; subtest 'release (;$sub)' => sub { 
my $release = sub {};
$::feature->release($release);
::is scalar do {$::feature->release}, scalar do{$release}, '$::feature->release # -> $release';

# 
# ## cleaner (;$sub)
# Обработчик события удаления фичи из объекта или `undef`.
# 
::done_testing; }; subtest 'cleaner (;$sub)' => sub { 
my $cleaner = sub {};
$::feature->cleaner($cleaner);
::is scalar do {$::feature->cleaner}, scalar do{$cleaner}, '$::feature->cleaner # -> $cleaner';

# 
# ## make_reader (;$bool)
# Флаг создания метода-ридера.
# 
::done_testing; }; subtest 'make_reader (;$bool)' => sub { 
$::feature->make_reader(1);
::is scalar do {$::feature->make_reader}, scalar do{1}, '$::feature->make_reader # -> 1';

# 
# ## make_writer (;$bool)
# Флаг создания метода-райтера.
# 
::done_testing; }; subtest 'make_writer (;$bool)' => sub { 
$::feature->make_writer(1);
::is scalar do {$::feature->make_writer}, scalar do{1}, '$::feature->make_writer # -> 1';

# 
# ## make_predicate (;$bool)
# Флаг создания метода-предиката.
# 
::done_testing; }; subtest 'make_predicate (;$bool)' => sub { 
$::feature->make_predicate(1);
::is scalar do {$::feature->make_predicate}, scalar do{1}, '$::feature->make_predicate # -> 1';

# 
# ## make_clearer (;$bool)
# Флаг создания метода-очистителя.
# 
::done_testing; }; subtest 'make_clearer (;$bool)' => sub { 
$::feature->make_clearer(1);
::is scalar do {$::feature->make_clearer}, scalar do{1}, '$::feature->make_clearer # -> 1';

# 
# ## new ($pkg, $name, @has)
# Конструктор фичи.
# 
::done_testing; }; subtest 'new ($pkg, $name, @has)' => sub { 
my $feature = Aion::Meta::Feature->new('My::Class', 'attr', is => 'ro', default => 1);
::is scalar do {$feature->pkg}, scalar do{"My::Class"}, '$feature->pkg # -> "My::Class"';
::is scalar do {$feature->name}, scalar do{"attr"}, '$feature->name # -> "attr"';
::is_deeply scalar do {$feature->opt}, scalar do {{is => 'ro', default => 1}}, '$feature->opt # --> {is => \'ro\', default => 1}';

# 
# ## stringify ()
# Строковое представление фичи.
# 
::done_testing; }; subtest 'stringify ()' => sub { 
::is scalar do {$::feature->stringify}, scalar do{"has my_feature => (is => 'rw') of My::Package"}, '$::feature->stringify # -> "has my_feature => (is => \'rw\') of My::Package"';

# 
# ## mk_property ()
# Создаёт акцессор, геттер, сеттер, предикат и очиститель свойства.
# 
::done_testing; }; subtest 'mk_property ()' => sub { 
package My::Package { use Aion }

$::feature->mk_property;

::is scalar do {!!My::Package->can('my_feature')}, scalar do{1}, '!!My::Package->can(\'my_feature\') # -> 1';

# 
# ## meta ()
# Возвращает код в виде текста для доступа к метаинформации фичи.
# 
::done_testing; }; subtest 'meta ()' => sub { 
::is scalar do {$::feature->meta}, '$Aion::META{\'My::Package\'}{feature}{my_feature}', '$::feature->meta # \> $Aion::META{\'My::Package\'}{feature}{my_feature}';

# 
# ## stash ($key; $val)
# Доступ к хранилищу свойств для вызывающего пакета.
# 
::done_testing; }; subtest 'stash ($key; $val)' => sub { 
$::feature->stash('my_key', 'my_value');
::is scalar do {$::feature->stash('my_key')}, scalar do{'my_value'}, '$::feature->stash(\'my_key\') # -> \'my_value\'';

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
