use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Meta::RequiresAnyFunction - определяет любую функцию, которая должна быть в модуле
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Meta::RequiresAnyFunction;

my $any_function = Aion::Meta::RequiresAnyFunction->new(
	pkg => 'My::Package', name => 'my_function'
);

::is scalar do {$any_function->stringify}, "my_function of My::Package", '$any_function->stringify # => my_function of My::Package';

# 
# # DESCRIPTION
# 
# Создаётся в `requires fn1, fn2...` и при инициализации класса проверяется, что такая функция в нём была объявлена через `sub` или `has`.
# 
# # SUBROUTINES
# 
# ## new (%args)
# 
# Конструктор.
# 
# ## compare ($other)
# 
# Проверяет, что `$other` является функцией.
# 
::done_testing; }; subtest 'compare ($other)' => sub { 
my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package', name => 'my_function');
::like scalar do {eval { $any_function->compare(undef) }; $@}, qr{Requires my_function of My::Package}, 'eval { $any_function->compare(undef) }; $@  # ~> Requires my_function of My::Package';

# 
# ## pkg ()
# 
# Возвращает имя пакета, в котором объявлена функция.
# 
::done_testing; }; subtest 'pkg ()' => sub { 
my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package');
::is scalar do {$any_function->pkg}, "My::Package", '$any_function->pkg  # => My::Package';

# 
# ## name ()
# 
# Возвращает имя функции.
# 
::done_testing; }; subtest 'name ()' => sub { 
my $any_function = Aion::Meta::RequiresAnyFunction->new(name => 'my_function');
::is scalar do {$any_function->name}, "my_function", '$any_function->name  # => my_function';

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
# The Aion::Meta::RequiresAnyFunction module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
