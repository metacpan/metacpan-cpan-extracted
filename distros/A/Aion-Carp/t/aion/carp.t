use common::sense; use open qw/:std :utf8/; use Test::More 0.98; use Carp::Always::Color; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-carp/aion/carp/'; `rm -fr $s` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; $s = join "", <$__f__>; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Carp - added stacktrace to exceptions
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
    die(...) called at t/aion/carp.t line 14
    main::A() called at t/aion/carp.t line 15
    main::B() called at t/aion/carp.t line 16
    eval {...} called at t/aion/carp.t line 16
    main::C() called at t/aion/carp.t line 17
    main::D() called at t/aion/carp.t line 19
    eval {...} called at t/aion/carp.t line 19
";
$expected =~ s/^ {4}/\t/gm;

::is scalar do {substr($@, 0, length $expected)}, "$expected", 'substr($@, 0, length $expected) # => $expected';


my $exception = {message => "hi!"};
eval { die $exception };
::is scalar do {$@}, scalar do{$exception}, '$@  # -> $exception';
::is scalar do {$@->{message}}, "hi!", '$@->{message}  # => hi!';
::like scalar do {$@->{STACKTRACE}}, qr!^die\(\.\.\.\) called at!, '$@->{STACKTRACE}  # ~> ^die\(\.\.\.\) called at';

$exception = {message => "hi!", STACKTRACE => 123};
eval { die $exception };
::is scalar do {$exception->{STACKTRACE}}, scalar do{123}, '$exception->{STACKTRACE} # -> 123';

$exception = [];
eval { die $exception };
::is_deeply scalar do {$@}, scalar do {[]}, '$@ # --> []';

# 
# # DESCRIPTION
# 
# This module replace `$SIG{__DIE__}` to function, who added to exception stacktrace.
# 
# If exeption is string, then stacktrace added to message. And if exeption is hash (`{}`), or object on base hash (`bless {}, "..."`), then added to it key `STACKTRACE` with stacktrace.
# 
# Where use propagation, stacktrace do'nt added.
# 
# # SUBROUTINES
# 
# ## handler ($message)
# 
# It added to `$message` stacktrace.
# 
done_testing; }; subtest 'handler ($message)' => sub { 
::like scalar do {eval { Aion::Carp::handler("hi!") }; $@}, qr!^hi\!\n\tdie!, 'eval { Aion::Carp::handler("hi!") }; $@  # ~> ^hi!\n\tdie';

# 
# ## import
# 
# Replace `$SIG{__DIE__}` to `handler`.
# 
done_testing; }; subtest 'import' => sub { 
$SIG{__DIE__} = undef;
::is_deeply scalar do {$SIG{__DIE__}}, scalar do {undef}, '$SIG{__DIE__} # --> undef';

Aion::Carp->import;

::is scalar do {$SIG{__DIE__}}, scalar do{\&Aion::Carp::handler}, '$SIG{__DIE__} # -> \&Aion::Carp::handler';

# 
# # INSTALL
# 
# Add to **cpanfile** in your project:
# 

# on 'test' => sub {
# 	requires 'Aion::Carp',
# 		git => 'https://github.com/darviarush/perl-aion-carp.git',
# 		ref => 'master',
# 	;
# };

# 
# And run command:
# 

# $ sudo cpm install -gvv

# 
# # SEE ALSO
# 
# * `Carp::Always`
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
	done_testing;
};

done_testing;
