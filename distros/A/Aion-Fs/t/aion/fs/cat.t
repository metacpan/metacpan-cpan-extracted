use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Fs::Cat - файловый дескриптор с автозакрытием
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Fs qw/lay/;
use Aion::Fs::Cat;
use Symbol;

my $file = "lay.test.txt";

lay $file, "xyz";

my $f = Symbol::gensym;
open $f, "<", $file;

$f = Aion::Fs::Cat->new(f => $f, path => $file);

local ($::_g0 = do {-d $f}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-d $f # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-f $f}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-f $f # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

read $f, my $buf, 1;
local ($::_g0 = do {$buf}, $::_e0 = "x"); ::ok $::_g0 eq $::_e0, '$buf # => x' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {<$f>}, $::_e0 = "yz"); ::ok $::_g0 eq $::_e0, '<$f> # => yz' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$f->path;}, $::_e0 = "lay.test.txt"); ::ok $::_g0 eq $::_e0, '$f->path; # => lay.test.txt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

undef $f;

# 
# # DESCRIPTION
# 
# Содержит файловый дескриптор, который закрывается в деструкторе. А благодаря перегрузке операторов `*{}`, `-X` и `<>` работает со всеми файловыми операциями `perl`.
# 
# Используется в [Aion::Fs::ilay](https://metacpan.org/pod/Aion::Fs#icat-\(%3B%24path\)).
# 
# # SUBROUTINES
# 
# ## new (%args)
# 
# Конструктор.
# 
# ## path ()
# 
# Путь к файлу.
# 
# ## next ()
# 
# Следующая строка.
# 
# ## DESTROY ()
# 
# Деструктор. Закрывает файловый дескриптор.
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
# The Aion::Fs::Cat module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
