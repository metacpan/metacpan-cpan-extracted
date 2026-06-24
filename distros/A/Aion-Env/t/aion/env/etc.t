use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Env::Etc - создаёт константу связанную с ключом из конфигурационных файлов
# 
# # SYNOPSIS
# 
# Файл etc/include.yml:
#@> etc/include.yml
#>> includes:
#>>   - etc/test.yml
#>> 
#>> test:
#>>   abc: -12
#@< EOF
# 
# Файл etc/test.yml:
#@> etc/test.yml
#>> test:
#>>   abc: 100
#>> 
#>> when@dev:
#>>   test:
#>>     val: 10
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
BEGIN { $ENV{APP_ENV} = 'dev' }

sub Int { sub { /^-?\d+$/ } }

use Aion::Env::Etc TEST_ABC => (isa => Int);
use Aion::Env::Etc VAL => (isa => Int, key => 'test.val');

local ($::_g0 = do {TEST_ABC}, $::_e0 = do {-12}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'TEST_ABC # -> -12' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {VAL}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'VAL # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Парсит конфигурационный файл. Путь к нему задан энвиронмент-переменной `AION_ENV_ETC_PATH`.
# 
# В нём может быть ключ `includes` c включением других конфигурационных файлов, а у тех – других.
# Для простоты `includes` срабатывают от текущего каталога, который должен соответствовать корню проекта (таково соглашение).
# 
# Ключи вида `when@ID` будут перекрывать своими ключами ключи конфигурационного файла, если `ID` из них соответствует `APP_ENV`.
# 
# Хеши в ключах, при совпадении ключей в разных файлах, объединяются рекурсивно. Однако если в одном из ключей не хеш, то будет выброшено исключение.
# 
# # SUBROUTINES
# 
# ## import ($name, %kw)
# 
# Создаёт константу в пакете из которого был вызван.
# 
# Допустимые опции:
# 
# * `isa` – подпрограмма-тестер или объект `Aion::Type` для проверки типа.
# * `default` – значение по умолчанию.
# * `key` – ключ из конфигурационных файлов. По умолчанию к нему преобразуется имя константы (переводится в нижний регистр и подчёрки заменяются на точки).
# 
# ## parse ($path)
# 
# Считывает и парсит конфигурационный файл в формате `yaml`. `${ID}` заменяются на значения из `%ENV`, а если там нет, то из файла `.env`. Парсит файлы в `include` рекурсивно.
# 
# ## merge_hashes ($file, $path, $x, $y)
# 
# Обединяет два хеша рекурсивно. Если в совпадающих ключах не хеши, то выбрасывает ошибку с `$file` и `$path`, где `$file` – подключающийся файл, а `$path` – путь из ключей через точку.
# 
# ## val ($s)
# 
# Добавляет бэкслеши. Используется для эскейпинга энвиронментов.
# 
::done_testing; }; subtest 'val ($s)' => sub { 
my $escape_string = "\\\"\\'\\\\\\t\\r\\n";
local ($::_g0 = do {Aion::Env::Etc::val("\"'\\\t\r\n")}, $::_e0 = do {$escape_string}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Aion::Env::Etc::val("\"\'\\\t\r\n") # -> $escape_string' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## by_key ($hash, $path)
# 
# Получить значение по ключу из хеша.
# 
::done_testing; }; subtest 'by_key ($hash, $path)' => sub { 
my ($val, $key_exists) = Aion::Env::Etc::by_key({x => {y => {z => 3}}}, "x.y.z");

local ($::_g0 = do {$val}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$val # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$key_exists}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$key_exists # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

($val, $key_exists) = Aion::Env::Etc::by_key({x => {y => {t => 10}}}, "x.y.z");

local ($::_g0 = do {$val}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$val # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$key_exists}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$key_exists # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **Perl5**
# 
# # COPYRIGHT
# 
# The Aion::Env::Etc module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
