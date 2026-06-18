use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Env - создаёт константу связанную со значением из .env
# 
# # VERSION
# 
# 0.1
# 
# # SYNOPSIS
# 
# Файл .env:
#@> .env
#>> BIN_TEST=10
#>> OCT_TEST=${BIN_TEST}20
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
BEGIN {
	delete @ENV{qw/BIN_TEST OCT_TEST BB_TEST NN_TEST/};

	$ENV{UNI_TEST} = 30;
}

sub Int { sub { /^-?\d+$/ } }

use Aion::Env BIN_TEST => (isa => Int);
use Aion::Env OCT_TEST => (isa => Int);
use Aion::Env UNI_TEST => (isa => Int);
use Aion::Env BB_TEST => (isa => Int, default => 1);

local ($::_g0 = do {BIN_TEST;}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'BIN_TEST; # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {OCT_TEST;}, $::_e0 = do {1020}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'OCT_TEST; # -> 1020' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {UNI_TEST;}, $::_e0 = do {30}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'UNI_TEST; # -> 30' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {BB_TEST;}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'BB_TEST; # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {eval 'use Aion::Env NN_TEST => ()'; $@;}, $::_e0 = 'NN_TEST is\'nt defined!'); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, 'eval \'use Aion::Env NN_TEST => ()\'; $@; # ^-> NN_TEST is\'nt defined!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {eval 'use Aion::Env NN_TEST => (nouname => 1)'; $@;}, $::_e0 = 'Unknown keyword: nouname'); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, 'eval \'use Aion::Env NN_TEST => (nouname => 1)\'; $@; # ^-> Unknown keyword: nouname' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {eval 'use Aion::Env NN_TEST => (nouname1 => 1, nouname2 => 2)'; $@;}, $::_e0 = 'Unknown keywords: nouname1, nouname2'); ::ok $::_g0 =~ /^${\quotemeta $::_e0}/, 'eval \'use Aion::Env NN_TEST => (nouname1 => 1, nouname2 => 2)\'; $@; # ^-> Unknown keywords: nouname1, nouname2' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# В проектах используется конфигурационный файл `.env` для конфигурации проекта, в `Makefile`, для `docker` и `docker compose`. Данный модуль позволяет оформить переменные окружения в виде констант модулей `perl`. 
# 
# Константы инициализируются из `%ENV`, если там нет значения или оно `undef`, то из файла `.env`, а если и там его не будет – из опции `default`.
# 
# При парсинге файла, ошибка синтаксиса приведёт к исключению.
# 
# Тип переменной окружения можно проверять с помощью опции `isa`. Она принимает подпрограмму или объект с перегруженным оператором `${}`. В этом случае значение будет передано в `$_`. Если объект имеет метод `validate`, как у `Aion::Type`, то будет вызван он с параметрами: значением и именем переменной окружения.
# 
# Рекомендуется называть переменные окружения используя название модуля в котором она объявлена. Например, пакет `Aion::Type`, тогда имена переменных окружения в нём – `AION_TYPE_*`.
# 
# # SUBROUTINES
# 
# ## import ($cls, $name, %kw)
# 
# Создаёт константу с именем `$name` в пакете из которого вызван.
# Опционально можно передать в `%kw` `isa` и `default`.
# 
# ## parse ($file)
# 
# Парсит файл формата `.env` и возвращает хеш с переменными из него.
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
# The Aion::Env module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
