use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Pleroma - контейнер эонов
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Pleroma;

my $pleroma = Aion::Pleroma->new;

local ($::_g0 = do {$pleroma->get('user')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$pleroma->get(\'user\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
eval {$pleroma->resolve('user')}; local ($::_g0 = $@, $::_e0 = 'user is\'nt eon!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$pleroma->resolve(\'user\') # @-> user is\'nt eon!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Реализует паттерн контейнера зависимостей.
# 
# Эон создаётся при запросе из контейнера через метод `get` или `resolve`, либо через аспект `eon` как ленивый `default`. Ленивость можно отменить через аспект `lazy`.
# 
# Контейнер находится в переменной `$Aion::pleroma` и его можно заменить с помощью `local`.
# 
# Конфигурацию для создания эонов получает из конфига `PLEROMA` и файла аннотаций (создаётся пакетом `Aion::Annotation`). Файл аннотаций можно заменить через конфиг `INI`.
# 
# # FEATURES
# 
# ## ini
# 
# Файл с аннотациями.
# 
::done_testing; }; subtest 'ini' => sub { 
local ($::_g0 = do {Aion::Pleroma->new->ini}, $::_e0 = "etc/annotation/eon.ann"); ::ok $::_g0 eq $::_e0, 'Aion::Pleroma->new->ini # => etc/annotation/eon.ann' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## pleroma
# 
# Конфигурация: ключ => 'класс#метод_класса'.
# 
# Файл lib/Ex/Eon/AnimalEon.pm:
#@> lib/Ex/Eon/AnimalEon.pm
#>> package Ex::Eon::AnimalEon;
#>> #@eon
#>> 
#>> use common::sense;
#>> 
#>> use Aion;
#>>  
#>> has role => (is => 'ro');
#>> 
#>> #@eon ex.cat
#>> sub cat { __PACKAGE__->new(role => 'cat') }
#>> 
#>> #@eon ex.dog
#>> sub dog { __PACKAGE__->new(role => 'dog') }
#>> 
#>> 1;
#@< EOF
# 
# Файл etc/annotation/eon.ann:
#@> etc/annotation/eon.ann
#>> Ex::Eon::AnimalEon#,2=
#>> Ex::Eon::AnimalEon#cat,10=ex.cat
#>> Ex::Eon::AnimalEon#dog,13=ex.dog
#@< EOF
# 
::done_testing; }; subtest 'pleroma' => sub { 
local ($::_g0 = do {Aion::Pleroma->new->pleroma}, $::_e0 = do {{"Ex::Eon::AnimalEon" => "Ex::Eon::AnimalEon#new", "ex.dog" => "Ex::Eon::AnimalEon#dog", "ex.cat" => "Ex::Eon::AnimalEon#cat"}}); ::is_deeply $::_g0, $::_e0, 'Aion::Pleroma->new->pleroma # --> {"Ex::Eon::AnimalEon" => "Ex::Eon::AnimalEon#new", "ex.dog" => "Ex::Eon::AnimalEon#dog", "ex.cat" => "Ex::Eon::AnimalEon#cat"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## eon
# 
# Совокупность порождённых эонов.
# 
::done_testing; }; subtest 'eon' => sub { 
my $pleroma = Aion::Pleroma->new;

local ($::_g0 = do {$pleroma->eon}, $::_e0 = do {{}}); ::is_deeply $::_g0, $::_e0, '$pleroma->eon # --> {}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
my $cat = $pleroma->resolve('ex.cat');
local ($::_g0 = do {$pleroma->eon}, $::_e0 = do {{ "ex.cat" => $cat }}); ::is_deeply $::_g0, $::_e0, '$pleroma->eon # --> { "ex.cat" => $cat }' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SUBROUTINES
# 
# ## get ($key)
# 
# Получить эон из контейнера.
# 
::done_testing; }; subtest 'get ($key)' => sub { 
my $pleroma = Aion::Pleroma->new;
local ($::_g0 = do {$pleroma->get('')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$pleroma->get(\'\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$pleroma->get('ex.dog')->role}, $::_e0 = "dog"); ::ok $::_g0 eq $::_e0, '$pleroma->get(\'ex.dog\')->role # => dog' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## resolve ($key)
# 
# Получить эон из контейнера или исключение, если его там нет.
# 
::done_testing; }; subtest 'resolve ($key)' => sub { 
my $pleroma = Aion::Pleroma->new;
eval {$pleroma->resolve('e.ibex')}; local ($::_g0 = $@, $::_e0 = "e.ibex is'nt eon!"); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$pleroma->resolve(\'e.ibex\') # @=> e.ibex is\'nt eon!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$pleroma->resolve('ex.dog')->role}, $::_e0 = "dog"); ::ok $::_g0 eq $::_e0, '$pleroma->resolve(\'ex.dog\')->role # => dog' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
