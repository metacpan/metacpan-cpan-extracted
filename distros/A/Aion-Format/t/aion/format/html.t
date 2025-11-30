use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Format::Html - библиотека для форматирования HTML
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format::Html;

local ($::_g0 = do {from_html "<b>&excl;</b>"}, $::_e0 = "!"); ::ok $::_g0 eq $::_e0, 'from_html "<b>&excl;</b>" # => !' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {to_html "<a>"}, $::_e0 = "&lt;a&gt;"); ::ok $::_g0 eq $::_e0, 'to_html "<a>"             # => &lt;a&gt;' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPION
# 
# Библиотека для форматирования HTML-документов.
# 
# # SUBROUTINES
# 
# ## from_html ($html)
# 
# Преобразует HTML в текст.
# 
::done_testing; }; subtest 'from_html ($html)' => sub { 
local ($::_g0 = do {from_html "Basic is <b>superlanguage</b>!<br>"}, $::_e0 = "Basic is superlanguage!\n"); ::ok $::_g0 eq $::_e0, 'from_html "Basic is <b>superlanguage</b>!<br>"  # => Basic is superlanguage!\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## to_html ($html)
# 
# Экранирует символы HTML.
# 
# ## safe_html ($html)
# 
# Обрезает опасные и неизвестные теги HTML, а также неизвестные атрибуты из известных тегов.
# 
::done_testing; }; subtest 'safe_html ($html)' => sub { 
local ($::_g0 = do {safe_html "-<em>-</em><br>-"}, $::_e0 = "-<em>-</em><br>-"); ::ok $::_g0 eq $::_e0, 'safe_html "-<em>-</em><br>-" # => -<em>-</em><br>-' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {safe_html "-<em onclick='  '>-</em><br onmouseout=1>-"}, $::_e0 = "-<em>-</em><br>-"); ::ok $::_g0 eq $::_e0, 'safe_html "-<em onclick=\'  \'>-</em><br onmouseout=1>-" # => -<em>-</em><br>-' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {safe_html "-<xx24>-</xx24>"}, $::_e0 = "--"); ::ok $::_g0 eq $::_e0, 'safe_html "-<xx24>-</xx24>" # => --' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {safe_html "-< applet >-</ applet >"}, $::_e0 = "-< applet >-"); ::ok $::_g0 eq $::_e0, 'safe_html "-< applet >-</ applet >" # => -< applet >-' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## split_on_pages ($html, $symbols_on_page, $by)
# 
# Разбивает текст на страницы с учетом html-тегов.
# 
::done_testing; }; subtest 'split_on_pages ($html, $symbols_on_page, $by)' => sub { 
local ($::_g0 = do {[split_on_pages "Alice in wonderland. This is book", 17]}, $::_e0 = do {["Alice in wonderland. ", "This is book"]}); ::is_deeply $::_g0, $::_e0, '[split_on_pages "Alice in wonderland. This is book", 17]  # --> ["Alice in wonderland. ", "This is book"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# The Aion::Format::Html module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
