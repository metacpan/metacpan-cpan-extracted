use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
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

local ($::_g0 = do {$any_function->stringify}, $::_e0 = "my_function of My::Package"); ::ok $::_g0 eq $::_e0, '$any_function->stringify # => my_function of My::Package' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
::like scalar do {eval { $any_function->compare(undef) }; $@}, qr{Requires my_function of My::Package}, 'eval { $any_function->compare(undef) }; $@  # ~> Requires my_function of My::Package'; undef $::_g0; undef $::_e0;

# 
# ## pkg ()
# 
# Возвращает имя пакета, в котором объявлена функция.
# 
::done_testing; }; subtest 'pkg ()' => sub { 
my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package');
local ($::_g0 = do {$any_function->pkg}, $::_e0 = "My::Package"); ::ok $::_g0 eq $::_e0, '$any_function->pkg  # => My::Package' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## name ()
# 
# Возвращает имя функции.
# 
::done_testing; }; subtest 'name ()' => sub { 
my $any_function = Aion::Meta::RequiresAnyFunction->new(name => 'my_function');
local ($::_g0 = do {$any_function->name}, $::_e0 = "my_function"); ::ok $::_g0 eq $::_e0, '$any_function->name  # => my_function' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
