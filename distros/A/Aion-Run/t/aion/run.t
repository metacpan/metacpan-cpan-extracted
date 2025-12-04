use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Run - роль для консольных команд
# 
# # VERSION
# 
# 0.0.2
# 
# # SYNOPSIS
# 
# Файл lib/Scripts/MyScript.pm:
#@> lib/Scripts/MyScript.pm
#>> package Scripts::MyScript;
#>> 
#>> use common::sense;
#>> 
#>> use List::Util qw/reduce/;
#>> use Aion::Format qw/trappout/;
#>> 
#>> use Aion;
#>> 
#>> with qw/Aion::Run/;
#>> 
#>> # Operands for calculations
#>> has operands => (is => "ro+", isa => ArrayRef[Int], arg => "-a", init_arg => "operand");
#>> 
#>> # Operator for calculations
#>> has operator => (is => "ro+", isa => Enum[qw!+ - * /!], arg => 1);
#>> 
#>> #@run math/calc „Calculate”
#>> sub calculate_sum {
#>>     my ($self) = @_;
#>>     printf "Result: %g\n", reduce {
#>>         given($self->operator) {
#>>             $a+$b when /\+/;
#>>             $a-$b when /\-/;
#>>             $a*$b when /\*/;
#>>             $a/$b when /\//;
#>>         }
#>>     } @{$self->operands};
#>> }
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format qw/trappout/;

use lib "lib";
use Scripts::MyScript;

local ($::_g0 = do {trappout { Scripts::MyScript->new_from_args([qw/-a 1 -a 2 -a 3 +/])->calculate_sum }}, $::_e0 = "Result: 6\n"); ::ok $::_g0 eq $::_e0, 'trappout { Scripts::MyScript->new_from_args([qw/-a 1 -a 2 -a 3 +/])->calculate_sum } # => Result: 6\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {trappout { Scripts::MyScript->new_from_args([qw/--operand=4 * --operand=2/])->calculate_sum }}, $::_e0 = "Result: 8\n"); ::ok $::_g0 eq $::_e0, 'trappout { Scripts::MyScript->new_from_args([qw/--operand=4 * --operand=2/])->calculate_sum } # => Result: 8\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Роль `Aion::Run` реализует аспект `arg` для установки фич из параметров командной строки.
# 
# * `arg => "-X"` — именованный параметр. Можно использовать как шорткут **\-X**, так и название фичи с **\--**.
# * `arg => natural` — порядковый параметр. `1+`.
# * `arg => 0` — все неименованные параметры. Используется с `isa => ArrayRef`.
# 
# # METHODS
# 
# ## new_from_args ($pkg, $args)
# 
# Конструктор. Он создает объект сценария с параметрами командной строки.
# 
::done_testing; }; subtest 'new_from_args ($pkg, $args)' => sub { 
package ArgExample {
	use Aion;
	
	with qw/Aion::Run/;
	
	has args => (is => "ro+", isa => ArrayRef[Str], arg => 0);
	has arg => (is => "ro+", isa => ArrayRef[Str], arg => '-a');
	has arg1 => (is => "ro+", isa => Str, arg => 1);
	has arg2 => (is => "ro+", isa => Str, init_arg => '_arg2', arg => 2);
	has arg_1 => (is => "ro+", isa => Str, init_arg => '_arg_1', arg => -1);
	has arg_2 => (is => "ro+", isa => Str, arg => -2);
}

my $ex = ArgExample->new_from_args([qw/1  -a 5  2  --arg=6 -2 5 --_arg_1=4/]);

local ($::_g0 = do {$ex->arg1}, $::_e0 = "1"); ::ok $::_g0 eq $::_e0, '$ex->arg1 # => 1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->arg2}, $::_e0 = "2"); ::ok $::_g0 eq $::_e0, '$ex->arg2 # => 2' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->arg_1}, $::_e0 = "4"); ::ok $::_g0 eq $::_e0, '$ex->arg_1 # => 4' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->arg_2}, $::_e0 = "5"); ::ok $::_g0 eq $::_e0, '$ex->arg_2 # => 5' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->args}, $::_e0 = do {[1, 2]}); ::is_deeply $::_g0, $::_e0, '$ex->args # --> [1, 2]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->arg}, $::_e0 = do {[5, 6]}); ::is_deeply $::_g0, $::_e0, '$ex->arg # --> [5, 6]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SEE ALSO
# 
# * [Aion](https://metacpan.org/pod/Aion)
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
# The Aion::Run module is copyright (с) 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
