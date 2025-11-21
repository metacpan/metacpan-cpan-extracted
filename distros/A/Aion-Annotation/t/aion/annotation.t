use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Annotation - обрабатывает аннотации в модулях perl
# 
# # VERSION
# 
# 0.0.0-prealpha
# 
# # SYNOPSIS
# 
# Файл lib/For/Test.pm:
#@> lib/For/Test.pm
#>> package For::Test;
#>> # The package for testing
#>> #@deprecated for_test
#>> 
#>> #@deprecated
#>> #@todo add1
#>> # Is property
#>> #   readonly
#>> has abc => (is => 'ro');
#>> 
#>> #@todo add2
#>> sub xyz {}
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Annotation;

Aion::Annotation->new->scan;

open my $f, '<', 'etc/annotation/modules.mtime.ini' or die $!; my @modules_mtime = <$f>; chop for @modules_mtime; close $f;
open my $f, '<', 'etc/annotation/remarks.ini' or die $!; my @remarks = <$f>; chop for @remarks; close $f;
open my $f, '<', 'etc/annotation/todo.ann' or die $!; my @todo = <$f>; chop for @todo; close $f;
open my $f, '<', 'etc/annotation/deprecated.ann' or die $!; my @deprecated = <$f>; chop for @deprecated; close $f;

::is scalar do {0+@modules_mtime}, scalar do{1}, '0+@modules_mtime  # -> 1';
::like scalar do {$modules_mtime[0]}, qr{^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$}, '$modules_mtime[0] # ~> ^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$';
::is_deeply scalar do {\@remarks}, scalar do {['For::Test#=The package for testing', 'For::Test#abc=Is property\n  readonly']}, '\@remarks         # --> [\'For::Test#=The package for testing\', \'For::Test#abc=Is property\n  readonly\']';
::is_deeply scalar do {\@todo}, scalar do {['For::Test#abc=add1', 'For::Test#xyz=add2']}, '\@todo            # --> [\'For::Test#abc=add1\', \'For::Test#xyz=add2\']';
::is_deeply scalar do {\@deprecated}, scalar do {['For::Test#=for_test', 'For::Test#abc=']}, '\@deprecated      # --> [\'For::Test#=for_test\', \'For::Test#abc=\']';

# 
# # DESCRIPTION
# 
# `Aion::Annotation` сканирует модули perl в каталоге **lib** и распечатывает их в соответстующие файлы в каталоге **etc/annotation**.
# 
# Сменить **lib** можно через конфиг `LIB`, а **etc/annotation** через конфиг `INI`.
# 
# 1. В **modules.mtime.ini** хранятся времена последнего обновления модулей.
# 2. В **remarks.ini** сохраняются комментарии к подпрограммам, свойствам и пакетам.
# 3. В файлах **имя.ann** сохраняются аннотации по своим именам.
# 
# # SUBROUTINES/METHODS
# 
# ## scan ()
# 
# Сканирует кодовую базу задаваемую конфигом `LIB` (перечень каталогов, по умолчанию `["lib"]`). И достаёт все аннотации и комментарии и распечатывает их в соответстующие файлы в каталоге `INI` (по умолчанию "etc/annotation").
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
# The Aion::Annotation module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
