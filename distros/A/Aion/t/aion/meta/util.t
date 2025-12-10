use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
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
local ($::_g0 = do {$class->age}, $::_e0 = "20"); ::ok $::_g0 eq $::_e0, '$class->age  # => 20' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$class->name}, $::_e0 = "car"); ::ok $::_g0 eq $::_e0, '$class->name  # => car' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {eval { $class->name('auto') }; $@}, qr{name is ro}, 'eval { $class->name(\'auto\') }; $@ # ~> name is ro'; undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {subref_is_reachable(\&nouname)}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'subref_is_reachable(\&nouname)             # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {subref_is_reachable(UNIVERSAL->can('isa'))}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'subref_is_reachable(UNIVERSAL->can(\'isa\')) # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {subref_is_reachable(sub {})}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'subref_is_reachable(sub {})                # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {subref_is_reachable(\&CORE::exit)}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'subref_is_reachable(\&CORE::exit)          # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## val_to_str ($val)
# 
# Переводит `$val` в строку.
# 
::done_testing; }; subtest 'val_to_str ($val)' => sub { 
local ($::_g0 = do {Aion::Meta::Util::val_to_str([1,2,{x=>6}])}, $::_e0 = "[1, 2, {x => 6}]"); ::ok $::_g0 eq $::_e0, 'Aion::Meta::Util::val_to_str([1,2,{x=>6}])   # => [1, 2, {x => 6}]' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {Aion::Meta::Util::val_to_str(qr/^[A-Z]/)}, $::_e0 = "qr/^[A-Z]/u"); ::ok $::_g0 eq $::_e0, 'Aion::Meta::Util::val_to_str(qr/^[A-Z]/)   # => qr/^[A-Z]/u' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Aion::Meta::Util::val_to_str(qr/^[A-Z]/i)}, $::_e0 = "qr/^[A-Z]/ui"); ::ok $::_g0 eq $::_e0, 'Aion::Meta::Util::val_to_str(qr/^[A-Z]/i)   # => qr/^[A-Z]/ui' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
