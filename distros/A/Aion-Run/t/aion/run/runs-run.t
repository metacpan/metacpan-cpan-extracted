use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Run::RunsRun - список скриптов с аннотацией `#@run`
# 
# # SYNOPSIS
# 
# Файл etc/annotation/run.ann:
#@> etc/annotation/run.ann
#>> Aion::Run::RunRun#run,3=run:run „Executes Perl code in the context of the current project”
#>> Aion::Run::RunsRun#list,5=run:runs „List of scripts”
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use common::sense;
use Aion::Format qw/trappout coloring/;
use Aion::Run::RunsRun;

my $len = 4;
my $len2 = 6;

my $list = coloring "#yellow%s#r\n", "run";
$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "run", "code", "„Executes Perl code in the context of the current project”";
$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "runs", "[mask]", "„List of scripts”";

local ($::_g0 = do {trappout { Aion::Run::RunsRun->new->list }}, $::_e0 = "$list"); ::ok $::_g0 eq $::_e0, 'trappout { Aion::Run::RunsRun->new->list } # => $list' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Печатает на стандартный вывод список сценариев из файла **etc/annotation/run.ann**.
# 
# Для этого загружает файлы, чтобы получить из них описание аргументов.
# 
# Поменять файл можно в конфиге `Aion::Run::Runner#INI`.
# 
# # FEATURES
# 
# ## mask
# 
# Маска для фильтра по скриптам.
# 
::done_testing; }; subtest 'mask' => sub { 
my $len = 4;
my $len2 = 6;

my $list = coloring "#yellow%s#r\n", "run";
$list .= coloring "  #green%-${len}s #{bold red}%-${len2}s #{bold black}%s#r\n", "runs", "[mask]", "„List of scripts”";

local ($::_g0 = do {trappout { Aion::Run::RunsRun->new(mask => 'runs')->list }}, $::_e0 = "$list"); ::ok $::_g0 eq $::_e0, 'trappout { Aion::Run::RunsRun->new(mask => \'runs\')->list } # => $list' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SUBROUTINES
# 
# ## list ()
# 
# Выводит список сценариев на `STDOUT`.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <darviarush@mail.ru>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Run::RunsRun module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
