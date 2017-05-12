#!/usr/bin/perl

use Class::Easy;

use Test::More qw(no_plan);

eval "
	\$aaa = 'bbb';
";

debug $@;

ok $@ =~ /Global symbol/, "strict is turned on by Class::Easy";

use Class::Easy::Log::Tie;

my $str;
my $err = tie *STDERR => 'Class::Easy::Log::Tie', \$str;

warn $@;

# Global symbol "$aaa" requires explicit package name
ok $str =~ /Global symbol/, $str;

logger ('default')->appender (*STDERR);

debug "debug test"; # string # 28

ok $str =~ /\[$$\] \[main\(\d+\)\] \[default\] debug test/m, $str;

print $str;

undef $err;
untie *STDERR;

ok $str; #, "warnings is turned on by Class::Easy; warning is: $err";

# ok ! $^W, "warnings is not turned on globally";

1;