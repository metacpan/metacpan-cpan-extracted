use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Meta::Subroutine - описывает функцию с сигнатурой
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types qw(Int);
use Aion::Meta::Subroutine;

my $subroutine = Aion::Meta::Subroutine->new(
	pkg => 'My::Package',
	subname => 'my_subroutine',
	signature => [Int, Int],
	referent => undef,
);

::is scalar do {$subroutine->stringify}, "my_subroutine(Int => Int) of My::Package", '$subroutine->stringify  # => my_subroutine(Int => Int) of My::Package';

# 
# # DESCRIPTION
# 
# Служит для объявления требуемой функции в интерфейсах и обстрактных классах.
# При этом `referent ~~ Undef`.
# 
# А так же создаёт функцию-обёртку проверяющую сигнатуру.
# 
# # SUBROUTINES
# 
# ## new (%args)
# 
# Конструктор.
# 
# ## wrap_sub ()
# 
# Создаёт функцию-обёртку проверяющую сигнатуру.
# 
# ## compare ($subroutine)
# 
# Сверяет свою (ожидаемую) сигнатуру с объявленной у функции в модуле и выбрасывает исключение, если сигнатуры не совпадают.
# 
# ## stringify ()
# 
# Строковое описание функции.
# 
# ## pkg ()
# 
# Возвращает имя пакета, в котором объявлена функция.
# 
# ## subname ()
# 
# Возвращает имя функции.
# 
# ## signature ()
# 
# Возвращает сигнатуру функции.
# 
# ## referent ()
# 
# Возвращает ссылку на оригинальную функцию.
# 
# ## wrapsub ()
# 
# Возвращает функцию-обёртку проверяющую сигнатуру.
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
# The Aion::Meta::Subroutine module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
