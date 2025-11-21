use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Meta::Util - вспомогательные функции для создания мета-данных
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package My::Meta::Class {
	use Aion::Meta::Util;
	
	create_accessors qw/age/;
	create_getters qw/name/;
}

my $class = bless {name => 'car'}, 'My::Meta::Class';

$class->age(20);
::is scalar do {$class->age}, "20", '$class->age  # => 20';

::is scalar do {$class->name}, "car", '$class->name  # => car';
::like scalar do {eval { $class->name('auto') }; $@}, qr{name is ro}, 'eval { $class->name(\'auto\') }; $@ # ~> name is ro';

# 
# # DESCRIPTION
# 
# В мета-классах поддерживающих создание фич и сигнатур функций (т.е. внутреннюю кухню Aion) требуется своя небольшая реализация, которую и предоставляет данный модуль.
# 
# # SUBROUTINES
# 
# ## create_getters (@getter_names)
# 
# Создаёт геттеры.
# 
# ## create_accessors (@accessor_names)
# 
# Создаёт геттер-сеттеры.
# 
# ## subref_is_reachable ($subref)
# 
# Проверяет, имеет ли подпрограмма тело.
# 
::done_testing; }; subtest 'subref_is_reachable ($subref)' => sub { 
use Aion::Meta::Util;

::is scalar do {subref_is_reachable(\&nouname)}, scalar do{""}, 'subref_is_reachable(\&nouname)             # -> ""';
::is scalar do {subref_is_reachable(UNIVERSAL->can('isa'))}, scalar do{""}, 'subref_is_reachable(UNIVERSAL->can(\'isa\')) # -> ""';
::is scalar do {subref_is_reachable(sub {})}, scalar do{1}, 'subref_is_reachable(sub {})                # -> 1';
::is scalar do {subref_is_reachable(\&CORE::exit)}, scalar do{1}, 'subref_is_reachable(\&CORE::exit)          # -> 1';

# 
# ## val_to_str ($val)
# 
# Переводит `$val` в строку.
# 
::done_testing; }; subtest 'val_to_str ($val)' => sub { 
::is scalar do {Aion::Meta::Util::val_to_str([1,2,{x=>6}])}, "[1, 2, {x => 6}]", 'Aion::Meta::Util::val_to_str([1,2,{x=>6}])   # => [1, 2, {x => 6}]';

::is scalar do {Aion::Meta::Util::val_to_str(qr/^[A-Z]/)}, "qr/^[A-Z]/u", 'Aion::Meta::Util::val_to_str(qr/^[A-Z]/)   # => qr/^[A-Z]/u';
::is scalar do {Aion::Meta::Util::val_to_str(qr/^[A-Z]/i)}, "qr/^[A-Z]/ui", 'Aion::Meta::Util::val_to_str(qr/^[A-Z]/i)   # => qr/^[A-Z]/ui';

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
# The Aion::Meta::Util module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
