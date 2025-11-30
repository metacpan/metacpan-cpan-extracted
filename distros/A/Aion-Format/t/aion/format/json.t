use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Format::Json - расширение Perl для форматирования JSON
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format::Json;

local ($::_g0 = do {to_json {a => 10}}, $::_e0 = "{\n   \"a\": 10\n}\n"); ::ok $::_g0 eq $::_e0, 'to_json {a => 10}    # => {\n   "a": 10\n}\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {from_json '[1, "5"]'}, $::_e0 = do {[1, "5"]}); ::is_deeply $::_g0, $::_e0, 'from_json \'[1, "5"]\' # --> [1, "5"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Format::Json` использует в качестве основы `JSON::XS`. И включает следующие настройки:
# 
# * allow_nonref — скаляры кодирования и декодирования.
# * indent – включить многострочный текст с отступом в начале строки.
# * space_after — `\n` после json.
# * canonical — сортировка ключей в хешах.
# 
# # SUBROUTINES
# 
# ## to_json (;$data)
# 
# Переводит данные в формат json.
# 
::done_testing; }; subtest 'to_json (;$data)' => sub { 
my $data = {
    a => 10,
};

my $result = '{
   "a": 10
}
';

local ($::_g0 = do {to_json $data}, $::_e0 = do {$result}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'to_json $data # -> $result' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local $_ = $data;
local ($::_g0 = do {to_json}, $::_e0 = do {$result}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'to_json # -> $result' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from_json (;$string)
# 
# Разбирает строку в формате JSON в структуру Perl.
# 
::done_testing; }; subtest 'from_json (;$string)' => sub { 
local ($::_g0 = do {from_json '{"a": 10}'}, $::_e0 = do {{a => 10}}); ::is_deeply $::_g0, $::_e0, 'from_json \'{"a": 10}\' # --> {a => 10}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[map from_json, "{}", "2"]}, $::_e0 = do {[{}, 2]}); ::is_deeply $::_g0, $::_e0, '[map from_json, "{}", "2"]  # --> [{}, 2]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# The Aion::Format::Json module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
