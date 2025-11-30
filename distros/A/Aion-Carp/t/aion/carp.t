use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Carp - добавляет трассировку стека в исключения
# 
# # VERSION
# 
# 1.5
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Carp;

sub A { die "hi!" }
sub B { A() }
sub C { eval { B() }; die if $@ }
sub D { C() }

eval { D() };

my $expected = "hi!
    die(...) called at t/aion/carp.t line 15
    main::A() called at t/aion/carp.t line 16
    main::B() called at t/aion/carp.t line 17
    eval {...} called at t/aion/carp.t line 17
    main::C() called at t/aion/carp.t line 18
    main::D() called at t/aion/carp.t line 20
    eval {...} called at t/aion/carp.t line 20
";
$expected =~ s/^ {4}/\t/gm;

local ($::_g0 = do {substr($@, 0, length $expected)}, $::_e0 = "$expected"); ::ok $::_g0 eq $::_e0, 'substr($@, 0, length $expected) # => $expected' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;


my $exception = {message => "hi!"};
eval { die $exception };
local ($::_g0 = do {$@}, $::_e0 = do {$exception}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$@  # -> $exception' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$@->{message}}, $::_e0 = "hi!"); ::ok $::_g0 eq $::_e0, '$@->{message}  # => hi!' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {$@->{STACKTRACE}}, qr{^die\(\.\.\.\) called at}, '$@->{STACKTRACE}  # ~> ^die\(\.\.\.\) called at'; undef $::_g0; undef $::_e0;

$exception = {message => "hi!", STACKTRACE => 123};
eval { die $exception };
local ($::_g0 = do {$exception->{STACKTRACE}}, $::_e0 = do {123}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$exception->{STACKTRACE} # -> 123' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$exception = [];
eval { die $exception };
local ($::_g0 = do {$@}, $::_e0 = do {[]}); ::is_deeply $::_g0, $::_e0, '$@ # --> []' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Этот модуль заменяет `$SIG{__DIE__}` на функцию, добавляющую в исключения трассировку стека.
# 
# Если исключением является строка, к сообщению добавляется трассировка стека. А если исключением является хэш (`{}`) или объект на базе хеша (`bless {}, "..."`), то к нему добавляется ключ `STACKTRACE` со stacktrace.
# 
# При повторном выбрасывании исключения трассировка стека не добавляется, а остаётся прежней.
# 
# # SUBROUTINES
# 
# ## handler ($message)
# 
# Добавляет трассировку стека в `$message`.
# 
::done_testing; }; subtest 'handler ($message)' => sub { 
::like scalar do {eval { Aion::Carp::handler("hi!") }; $@}, qr{^hi\!\n\tdie}, 'eval { Aion::Carp::handler("hi!") }; $@  # ~> ^hi!\n\tdie'; undef $::_g0; undef $::_e0;

# 
# ## import
# 
# Заменяет `$SIG{__DIE__}` на `handler`.
# 
::done_testing; }; subtest 'import' => sub { 
$SIG{__DIE__} = undef;
local ($::_g0 = do {$SIG{__DIE__}}, $::_e0 = do {undef}); ::is_deeply $::_g0, $::_e0, '$SIG{__DIE__} # --> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

Aion::Carp->import;

local ($::_g0 = do {$SIG{__DIE__}}, $::_e0 = do {\&Aion::Carp::handler}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$SIG{__DIE__} # -> \&Aion::Carp::handler' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SEE ALSO
# 
# * `Carp::Always`
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
# The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
