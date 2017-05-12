#!/usr/bin/perl

BEGIN {
	use Class::Easy;
	if (try_to_use ('IO::Easy')) {
		unshift @INC, IO::Easy::Dir->current->dir_io('lib')->path;
	}

	use Test::More qw(no_plan);

	# use_ok 'Project::Easy::Helper';

}

use Data::Dumper;

use Class::Easy::Log;

my $str;
my $rstr = \$str;
$rstr = "$rstr";

my $l = {layout => '%m%n'};
Class::Easy::Log::_parse_layout ($l);
ok $l->{_layout_format} eq '%s%s';

# [$$] [$sub($line)] [DBG] $message\n
$l = {layout => '[%P] %% [%C::%M(%L)] [%c] %m%n-fsd'};
Class::Easy::Log::_parse_layout ($l);
ok $l->{_layout_format} eq '[%d] %% [%s::%s(%d)] [%s] %s%s-fsd', $l->{_layout_format};

# warn join ', ', @{$l->{_layout_fields}};
ok join (', ', @{$l->{_layout_fields}}) eq 'pid, package, method, line, category, message, newline';

ok logger()->{category} eq 'main', 'logger() has category of caller package';
ok logger('sql')->{category} eq 'sql', 'logger(category) has supplied category';

SKIP: {
	eval {require Log::Log4perl};

	skip "Log::Log4perl not installed", 2 if $@;

	ok logger('log4perl')->{category} eq 'main', 'logger(driver) has category of caller package';
	ok logger(log4perl => 'sql')->{category} eq 'sql', 'logger(driver, category) has supplied category';

};

my $logger = logger ('test');

# ok main->can ('log_test');

ok log_test ($rstr), 'logger created function in caller package';
ok ! defined $str, 'but no appenders plugged in';

ok $logger->appender (\$str), 'append logs to content of accumulator string';
ok log_test ($rstr);
ok $str =~ /\Q$rstr\E/, 'accumulator string contains log message';

ok $logger->appender (), 'cancel logging';
ok log_test ('aaa');
ok $str !~ /aaa/;

ok $logger->appender (\$str);
ok log_test ('bbb');
ok $str =~ /bbb/;

ok $logger->appender ();

my $str2;

my $err = catch_stderr (\$str2);

ok $logger->appender (*STDERR), 'write logs to the STDERR';
ok log_test ($rstr);
ok $str2 =~ /\Q$rstr\E/, 'STDERR contains log message';

ok $logger->appender (), 'cancel logging';
ok log_test ('aaa');
ok $str2 !~ /aaa/;

ok $logger->appender (*STDERR);
logger ('test');

ok logger (test => *STDERR), 'simplified syntax';

ok log_test ('bbb');
ok $str2 =~ /bbb/;

$str2 = '';

# timer test
my $t = timer_test ('xxx');

sleep (1);

my $interval = $t->end;

ok $interval > 0;

warn "your system have bad timer: 1s = ${interval}s"
	if $interval < 1;

ok $str2 =~ /xxx/;

ok $t = timer ('zzz'), 'default timer belongs to debug category';

sleep (1);

ok ! $t->end;

ok $logger->appender ();

release_stderr;

# TODO: test coderef

eval {critical 'msg'};

ok $@ =~ /msg/, $@;

# checking for debug

$str2 = '';

$err = catch_stderr (\$str2);

$logger = logger (default => *STDERR);

debug ("hello");

ok ($str2 =~ /hello/);

1;

