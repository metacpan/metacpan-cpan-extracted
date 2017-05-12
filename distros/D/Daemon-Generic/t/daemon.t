#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More qw(no_plan);
use File::Temp qw(tempdir);
use File::Slurp;
use FindBin;
use Time::HiRes;
use Eval::LineNumbers qw(eval_line_numbers);

my $finished;

END { ok($finished, "finished"); }

my $tmp = tempdir();
# $tmp = "/tmp/foo";

my $base = "$^X $tmp/daemon.pl -c $tmp/config";

write_file("$tmp/logger", <<END_LOGGER);
#!$^X

open \$out, ">>", \$ENV{LOGGER_OUTPUT}
	or die "open >\$ENV{LOGGER_OUTPUT}: \$!";
select(\$out);
\$| = 1;
print \$out "START LOG \@ARGV\n";
while (<STDIN>) {
	print \$out \$_;
}

END_LOGGER
chmod(0755, "$tmp/logger") or die;

$ENV{LOGGER_OUTPUT} = "$tmp/log";
$ENV{PATH} = "$tmp:$ENV{PATH}";

# diag read_file("$tmp/config");

my $daemon_header = eval_line_numbers(<<'END_HEADER'); #{

	use strict;
	use warnings;
	use FindBin;
	use File::Slurp;
	use Time::HiRes qw(sleep);

END_HEADER
#}

my $daemon_body = eval_line_numbers(<<'END_BODY'); #{

	my $pid_file;
	my $counter_file; 
	my $counter = 0;

	alarm(240);  # just in case

	newdaemon();

	my %c;

	sub gd_postconfig
	{
		my ($self, %config) = @_;

		%c = %config;
	}

	sub gd_run_body {
		if ($c{DIE}) {
			die $c{DIE};
		}
		write_file($c{COUNTER}, "$counter\n");
		$counter++;
		sleep($sleeptime) if $sleeptime;
	}

	my $rc = 0;

	sub gd_preconfig {
		my ($self) = @_;
		my %config;
		open my $fd, "<", $self->{configfile} or die "open $self->{configfile}: $!";
		while (<$fd>) {
			chomp;
			next if /^$/;
			next if /^#/;
			next unless /^(.+?)=(.*)/;
			$config{$1} = $2;
		}
		$self->{gd_foreground} = $config{foreground};
		$rc++;
		if ($config{RELOAD}) {
			write_file($config{RELOAD}, "$rc\n");
		}
		if ($config{PATH}) {
			$ENV{PATH} = $config{PATH};
		}
		return %config;
	}

END_BODY
#}

setup_test(eval_line_numbers(<<'END_WHILE1'));

	use Daemon::Generic::While1;
	our @ISA = qw(Daemon::Generic::While1);
	my $sleeptime = 0.1;

END_WHILE1

do_test('while1');

setup_test(eval_line_numbers(<<'END_EVENT'), 'sub gd_interval { 0.1 }' );

	use Daemon::Generic::Event;
	our @ISA = qw(Daemon::Generic::Event);
	my $sleeptime = 0;

END_EVENT

do_test('event');

setup_test(eval_line_numbers(<<'END_ANYEVENT'), 'sub gd_interval { 0.1 }' );

	use Event;
	use Daemon::Generic::AnyEvent;
	our @ISA = qw(Daemon::Generic::AnyEvent);
	my $sleeptime = 0;

END_ANYEVENT

do_test('anyevent');

$finished = 1;

sub set_alarm
{
	my ($pkg, $file, $line) = caller(1);
	$SIG{ALRM} = sub {
		die "timeout at $file line $line\n";
	};
	alarm(10);
}

sub expect (&) {
	set_alarm();
	my $r;
	do { sleep(0.05); $r = $_[0]->() }
	while (! $r);
	alarm(0);
	return $r;
}

sub run {
	set_alarm();
	my $r = `$base @_`;
	alarm(0);
	return $r;
}

sub setup_test
{
	my ($head_frag, $body_frag) = @_;

	unlink "$tmp/$_" for qw(pid counter counter1 log);

	write_file("$tmp/daemon.pl", "use lib '$FindBin::Bin/../lib';\n", $daemon_header, $head_frag, $daemon_body, $body_frag || '');

	config_deamon();
}

sub config_deamon {
	write_file("$tmp/config", <<END_CONFIG);
pidfile=$tmp/pid
COUNTER=$tmp/counter
RELOAD_COUNTER=$tmp/reload
foreground=0
PATH=$tmp:$ENV{PATH}
END_CONFIG
}

sub do_test 
{
	my ($name) = @_;


	like(run('start'), qr/Starting/, "start message - $name");

	expect { -s "$tmp/pid" };
	my $pid = read_file("$tmp/pid");
	chomp($pid);
	like($pid, qr/^\d+$/, "pid");

	expect { -s "$tmp/counter" };
	my $counter1 = read_file("$tmp/pid");
	chomp($counter1);
	like($counter1, qr/^\d+$/, "counter1 - $name");

	expect { -e "$tmp/log" };
	like(read_file("$tmp/log"), qr/START LOG/, "logged output");

	expect { my @l = read_file("$tmp/log"); @l > 1 };
	like(read_file("$tmp/log"), qr/Sucessfully daemonized/, "daemonized");

	append_file("$tmp/config", "COUNTER=$tmp/counter2");

	like(run('reload'), qr/reconfiguration/, "reconfig message");

	expect { -s "$tmp/counter2" };
	my $counter2 = read_file("$tmp/pid");
	chomp($counter2);
	like($counter2, qr/^\d+$/, "counter2");

	ok(kill(0,$pid), "process $pid is alive - $name");

	my $check = run('check');
	like($check, qr/Configuration looks okay/, "config ok - $name");
	like($check, qr/running - pid \d+/, "running");

	like(run('stop'), qr/Killing/, "kill message");

	ok(!kill(0,$pid), "process is dead - $name");

	my $check2 = run('check');
	like($check2, qr/Configuration looks okay/, "config ok");
	like($check2, qr/No \S+ running/, "not running");

	like(run('restart'), qr/Starting/, "restart message - start - $name");
	like(run('restart'), qr/Killing/, "restart message - kill");
	like(run('restart'), qr/Starting/, "restart message - start - $name");
	like(run('check'), qr/running - pid/, "check");
	like(run('stop'), qr/Killing/, "stop message");
	unlike(run('check'), qr/running - pid/, "check - $name");
}

