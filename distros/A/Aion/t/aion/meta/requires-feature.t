use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Meta::RequiresFeature - требование фичи для интерфейсов
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Types qw(Str);
use Aion::Meta::RequiresFeature;
use Aion::Meta::Feature;

my $req = Aion::Meta::RequiresFeature->new(
	'My::Package', 'name', is => 'rw', isa => Str);

my $feature = Aion::Meta::Feature->new(
	'Other::Package',
	'name', is => 'rw', isa => Str,
	default => 'default_value');

$req->compare($feature);

::is scalar do {$req->stringify}, "req name => (is => 'rw', isa => Str) of My::Package", '$req->stringify  # => req name => (is => \'rw\', isa => Str) of My::Package';

# 
# # DESCRIPTION
# 
# С помощью `req` создаёт требование к фиче которая будет описана в модуле к которому будет подключена роль или который унаследует абстрактный класс.
# 
# Проверяться будут только указанные аспекты в фиче.
# 
# # SUBROUTINES
# 
# ## new ($cls, $pkg, $name, @has)
# 
# Конструктор.
# 
# ## pkg ()
# 
# Возвращает имя пакета в котором описано требование к фиче.
# 
# ## name ()
# 
# Возвращает имя фичи.
# 
# ## has ()
# 
# Возвращает массив с аспектами фичи.
# 
# ## opt ()
# 
# Возвращает хеш аспектов фичи.
# 
# ## stringify ()
# 
# Строковое представление фичи.
# 
# ## compare ($feature)
# 
# Сравнивает с фичей, но только указанные аспекты.
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
# The Aion::Meta::RequiresFeature module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
