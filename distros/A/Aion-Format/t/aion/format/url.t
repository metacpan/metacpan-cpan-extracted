use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Format::Url - утилиты для кодирования и декодирования URL-адресов
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format::Url;

local ($::_g0 = do {to_url_params {a => 1, b => [[1,2],3,{x=>10}]}}, $::_e0 = "a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10"); ::ok $::_g0 eq $::_e0, 'to_url_params {a => 1, b => [[1,2],3,{x=>10}]} # => a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {normalize_url "?x", "http://load.er/fix/mix?y=6"}, $::_e0 = "http://load.er/fix/mix?x"); ::ok $::_g0 eq $::_e0, 'normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Утилиты для кодирования и декодирования URL-адресов.
# 
# # SUBROUTINES
# 
# ## to_url_param (;$scalar)
# 
# Экранирует `$scalar` для части поиска URL.
# 
::done_testing; }; subtest 'to_url_param (;$scalar)' => sub { 
local ($::_g0 = do {to_url_param "a b"}, $::_e0 = "a+b"); ::ok $::_g0 eq $::_e0, 'to_url_param "a b" # => a+b' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {[map to_url_param, "a b", "🦁"]}, $::_e0 = do {[qw/a+b %F0%9F%A6%81/]}); ::is_deeply $::_g0, $::_e0, '[map to_url_param, "a b", "🦁"] # --> [qw/a+b %F0%9F%A6%81/]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## to_url_params (;$hash_ref)
# 
# Генерирует поисковую часть URL-адреса.
# 
::done_testing; }; subtest 'to_url_params (;$hash_ref)' => sub { 
local $_ = {a => 1, b => [[1,2],3,{x=>10}]};
local ($::_g0 = do {to_url_params}, $::_e0 = "a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10"); ::ok $::_g0 eq $::_e0, 'to_url_params  # => a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# 1. Ключи со значениями `undef` отбрасываются.
# 1. Значение `1` используется для ключа без значения.
# 1. Ключи преобразуются в алфавитном порядке.
# 

local ($::_g0 = do {to_url_params {k => "", n => undef, f => 1}}, $::_e0 = "f&k="); ::ok $::_g0 eq $::_e0, 'to_url_params {k => "", n => undef, f => 1}  # => f&k=' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from_url_params (;$scalar)
# 
# Парсит поисковую часть URL-адреса.
# 
::done_testing; }; subtest 'from_url_params (;$scalar)' => sub { 
local $_ = 'a&b[][]&b[][1]=2&b[1]=3&b[2][x]=10';
local ($::_g0 = do {from_url_params}, $::_e0 = do {{a => 1, b => [[1,2],3,{x=>10}]}}); ::is_deeply $::_g0, $::_e0, 'from_url_params  # --> {a => 1, b => [[1,2],3,{x=>10}]}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from_url_param (;$scalar)
# 
# Используется для парсинга ключей и значений в параметре URL.
# 
# Обратный к `to_url_param`.
# 
::done_testing; }; subtest 'from_url_param (;$scalar)' => sub { 
local $_ = to_url_param '↬';
local ($::_g0 = do {from_url_param}, $::_e0 = "↬"); ::ok $::_g0 eq $::_e0, 'from_url_param  # => ↬' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## parse_url ($url, $onpage, $dir)
# 
# Парсит и нормализует URL.
# 
# * `$url` — URL-адрес или его часть для парсинга.
# * `$onpage` — URL-адрес страницы с `$url`. Если `$url` не завершен, то он дополняется отсюда. Необязательный. По умолчанию использует конфигурацию `$onpage = 'off://off'`.
# * `$dir` (bool): 1 — нормализовать URL-путь с "/" на конце, если это каталог. 0 — без «/».
# 
::done_testing; }; subtest 'parse_url ($url, $onpage, $dir)' => sub { 
my $res = {
    proto  => "off",
    dom    => "off",
    domain => "off",
    link   => "off://off",
    orig   => "",
    onpage => "off://off",
};

local ($::_g0 = do {parse_url ""}, $::_e0 = do {$res}); ::is_deeply $::_g0, $::_e0, 'parse_url "" # --> $res' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$res = {
    proto  => "https",
    dom    => "main.com",
    domain => "www.main.com",
    path   => "/page",
    dir    => "/page/",
    link   => "https://main.com/page",
    orig   => "/page",
    onpage => "https://www.main.com/pager/mix",
};

local ($::_g0 = do {parse_url "/page", "https://www.main.com/pager/mix"}, $::_e0 = do {$res}); ::is_deeply $::_g0, $::_e0, 'parse_url "/page", "https://www.main.com/pager/mix"   # --> $res' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$res = {
    proto  => "https",
    user   => "user",
    pass   => "pass",
    dom    => "x.test",
    domain => "www.x.test",
    path   => "/path",
    dir    => "/path/",
    query  => "x=10&y=20",
    hash   => "hash",
    link   => 'https://user:pass@x.test/path?x=10&y=20#hash',
    orig   => 'https://user:pass@www.x.test/path?x=10&y=20#hash',
    onpage => "off://off",
};
local ($::_g0 = do {parse_url 'https://user:pass@www.x.test/path?x=10&y=20#hash'}, $::_e0 = do {$res}); ::is_deeply $::_g0, $::_e0, 'parse_url \'https://user:pass@www.x.test/path?x=10&y=20#hash\'  # --> $res' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## normalize_url ($url, $onpage, $dir)
# 
# Нормализует URL.
# 
# Использует `parse_url` и возвращает ссылку.
# 
::done_testing; }; subtest 'normalize_url ($url, $onpage, $dir)' => sub { 
local ($::_g0 = do {normalize_url ""}, $::_e0 = "off://off"); ::ok $::_g0 eq $::_e0, 'normalize_url ""   # => off://off' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "www.fix.com"}, $::_e0 = "off://off/www.fix.com"); ::ok $::_g0 eq $::_e0, 'normalize_url "www.fix.com"  # => off://off/www.fix.com' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url ":"}, $::_e0 = "off://off/:"); ::ok $::_g0 eq $::_e0, 'normalize_url ":"  # => off://off/:' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url '@'}, $::_e0 = "off://off/@"); ::ok $::_g0 eq $::_e0, 'normalize_url \'@\'  # => off://off/@' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "/"}, $::_e0 = "off://off"); ::ok $::_g0 eq $::_e0, 'normalize_url "/"  # => off://off' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "//"}, $::_e0 = "off://"); ::ok $::_g0 eq $::_e0, 'normalize_url "//" # => off://' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "?"}, $::_e0 = "off://off"); ::ok $::_g0 eq $::_e0, 'normalize_url "?"  # => off://off' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "#"}, $::_e0 = "off://off"); ::ok $::_g0 eq $::_e0, 'normalize_url "#"  # => off://off' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {normalize_url "/dir/file", "http://www.load.er/fix/mix"}, $::_e0 = "http://load.er/dir/file"); ::ok $::_g0 eq $::_e0, 'normalize_url "/dir/file", "http://www.load.er/fix/mix"  # => http://load.er/dir/file' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "dir/file", "http://www.load.er/fix/mix"}, $::_e0 = "http://load.er/fix/mix/dir/file"); ::ok $::_g0 eq $::_e0, 'normalize_url "dir/file", "http://www.load.er/fix/mix"  # => http://load.er/fix/mix/dir/file' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {normalize_url "?x", "http://load.er/fix/mix?y=6"}, $::_e0 = "http://load.er/fix/mix?x"); ::ok $::_g0 eq $::_e0, 'normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SEE ALSO
# 
# * [Badger::URL](https://metacpan.org/pod/Badger::URL).
# * [Mojo::URL](https://metacpan.org/pod/Mojo::URL).
# * [Plack::Request](https://metacpan.org/pod/Plack::Request).
# * [URI](https://metacpan.org/pod/URI).
# * [URI::URL](https://metacpan.org/pod/URI::URL).
# * [URL::Encode](https://metacpan.org/pod/URL::Encode).
# * [URL::XS](https://metacpan.org/pod/URL::XS).
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
# The Aion::Format::Url module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
