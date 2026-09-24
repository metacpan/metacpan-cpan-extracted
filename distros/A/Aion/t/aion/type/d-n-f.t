use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Type::DNF - приведение типа-выражения к ДНФ эквивалентными преобразованиями
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types qw/Range None/;

my $gap = Range[-10, 0] & Range[4, 8];
local ($::_g0 = do {$gap->_simplify eq None}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$gap->_simplify eq None   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Это роль, которую включает в себя `Aion::Type`. Содержит служебные методы для развёртки типа-выражения (комбинации `&`, `|`, `~`) в **ДНФ — дизъюнктивную нормальную форму**.
# 
# Этот модуль реализует алгоритм №1 из списка способов построения ДНФ:
# 
# 1. **Эквивалентные преобразования на основе законов булевой алгебры** ✅ (реализовано здесь).
# 2. Метод таблиц истинности (построение СДНФ).
# 3. Алгоритм Цейтина (введение «мусорных» переменных).
# 4. Алгоритмы на основе BDD (Binary Decision Diagrams).
# 
# Пояснение остальных вариантов (для контекста):
# 
# * **Метод таблиц истинности (СДНФ)** — перебирает все наборы значений переменных и собирает совершенную ДНФ по единицам функции. Экспоненциален по числу переменных и потому неприменим к «большим» типам.
# * **Алгоритм Цейтина** — вводит вспомогательные переменные и строит КНФ с линейным размером (в основном для SAT-решателей), а не ДНФ.
# * **BDD** — сворачивает дерево решений, разделяя одинаковые поддеревья.
# 
# Здесь же ДНФ получается чисто алгебраически: раскрытием скобок по закону дистрибутивности.
# 
# # ALGORITHM
# 
# Общая цепочка преобразований (см. метод `_simplify` в `Aion::Type`):
# 
# 	_unfolding -> _pushing -> _distribute
# 
# Каждый шаг — эквивалентное преобразование по законам булевой алгебры:
# 
# - **`_unfolding`** — раскрывает цепочку ограничивающих типов `A as B as C` в эквивалентное пересечение `A & B & C` «в лоб», не допуская совмещения с уже множественно-теоретическими операциями.
# - **`_pushing`** — «проталкивает» отрицания к термам по законам де Моргана и инверсии диапазонов/перечислений: `~(A | B) => ~A & ~B`, `~(A & B) => ~A | ~B`, `~~A => A`.
# - **`_distribute`** — применяет закон дистрибутивности и раскрывает пересечение объединений в объединение пересечений (ДНФ):
# 
# 	(A | B) & (C | D | E) & F  =>  (A & C & F) | (A & D & F) | (A & E & F) | (B & C & F) | (B & D & F) | (B & E & F)
# 
#   Пересечения/объединения затем сворачиваются вспомогательными функциями `_intersection` и `_union`, которые приводят термы (по диапазонам — `_intersection_ranges`/`_union_ranges`, по перечислениям — `_union_enums`/`_intersection_enums`).
# 
# Терм считается атомом: тип без множественно-теоретических операторов либо явно выделенные «куски» после `_unfolding` и `_pushing`.
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
# The Aion::Type::DNF module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
