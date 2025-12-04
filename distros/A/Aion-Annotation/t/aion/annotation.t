use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Annotation - обрабатывает аннотации в модулях perl
# 
# # VERSION
# 
# 0.0.2-prealpha
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
#>> #@param Int $a
#>> #@param Int[] $r
#>> sub xyz {}
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Annotation;

Aion::Annotation->new->scan;

open my $f, '<', 'var/cache/modules.mtime.ini' or die $!; my @modules_mtime = <$f>; chop for @modules_mtime; close $f;
open my $f, '<', 'etc/annotation/remarks.ini' or die $!; my @remarks = <$f>; chop for @remarks; close $f;
open my $f, '<', 'etc/annotation/todo.ann' or die $!; my @todo = <$f>; chop for @todo; close $f;
open my $f, '<', 'etc/annotation/deprecated.ann' or die $!; my @deprecated = <$f>; chop for @deprecated; close $f;
open my $f, '<', 'etc/annotation/param.ann' or die $!; my @param = <$f>; chop for @param; close $f;

local ($::_g0 = do {0+@modules_mtime}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0+@modules_mtime  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {$modules_mtime[0]}, qr{^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$}, '$modules_mtime[0] # ~> ^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$'; undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@remarks}, $::_e0 = do {['For::Test#,4=The package for testing', 'For::Test#abc,9=Is property\n  readonly']}); ::is_deeply $::_g0, $::_e0, '\@remarks         # --> [\'For::Test#,4=The package for testing\', \'For::Test#abc,9=Is property\n  readonly\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@todo}, $::_e0 = do {['For::Test#abc,6=add1', 'For::Test#xyz,11=add2']}); ::is_deeply $::_g0, $::_e0, '\@todo            # --> [\'For::Test#abc,6=add1\', \'For::Test#xyz,11=add2\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@deprecated}, $::_e0 = do {['For::Test#,3=for_test', 'For::Test#abc,5=']}); ::is_deeply $::_g0, $::_e0, '\@deprecated      # --> [\'For::Test#,3=for_test\', \'For::Test#abc,5=\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {\@param}, $::_e0 = do {['For::Test#xyz,12=Int $a', 'For::Test#xyz,13=Int[] $r']}); ::is_deeply $::_g0, $::_e0, '\@param           # --> [\'For::Test#xyz,12=Int $a\', \'For::Test#xyz,13=Int[] $r\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
