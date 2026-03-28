#!/usr/bin/perl

use strict;
use warnings;
use App::Prove;
use Test::More tests=>4;

my $sbackup = {};
sub steal_stderr {
    my ($sref) = @_;
    if (!defined($$sbackup{stderr})) {
        open($$sbackup{stderr}, '>&STDERR');
        close(STDERR);
    }
    $$sref = undef;
    open(STDERR, '>', $sref);
}
sub return_stderr {
    if (defined($$sbackup{stderr})) {
        close(STDERR);
        open(STDERR, '>&', $$sbackup{stderr});
        delete($$sbackup{stderr});
    }
}

subtest 'stderr, all data'=>sub {
	plan tests=>16;
	my $prove=App::Prove->new();
	$prove->process_args('-PMetrics=stderr,prefix,PRE,sep, SEP ,subdepth,-1,label,1,rollup,0',glob('t/tests/simple-*.tt'));
	my $serr; steal_stderr(\$serr);
	$prove->run();
	return_stderr();
	my %seen=map {$_=>1} map {s/\s+/ /gr} grep {/^METRIC:/} split(/\n/,$serr);
	foreach my $expect (
		['simple-0-1',     1,'PRE SEP t/tests/simple-0-1.tt SEP okA'],
		['simple-1-1-1',   1,'PRE SEP t/tests/simple-1-1.tt SEP Level1 SEP okA'],
		['simple-1-1-0',   1,'PRE SEP t/tests/simple-1-1.tt SEP Level1'],
		['simple-2-1-2',   1,'PRE SEP t/tests/simple-2-1.tt SEP Level1 SEP Level2 SEP okA'],
		['simple-2-1-1',   1,'PRE SEP t/tests/simple-2-1.tt SEP Level1 SEP Level2'],
		['simple-2-1-0',   1,'PRE SEP t/tests/simple-2-1.tt SEP Level1'],
		['simple-0-0',     0,'PRE SEP t/tests/simple-0-0.tt SEP failA'],
		['simple-1-0-1',   0,'PRE SEP t/tests/simple-1-0.tt SEP Level1 SEP failA'],
		['simple-1-0-0',   0,'PRE SEP t/tests/simple-1-0.tt SEP Level1'],
		['simple-2-0-2',   0,'PRE SEP t/tests/simple-2-0.tt SEP Level1 SEP Level2 SEP failA'],
		['simple-2-0-1',   0,'PRE SEP t/tests/simple-2-0.tt SEP Level1 SEP Level2'],
		['simple-2-0-0',   0,'PRE SEP t/tests/simple-2-0.tt SEP Level1'],
		['simple-1-0-n-0', 0,'PRE SEP t/tests/simple-1-0-n.tt SEP Level1'],
		['simple-1-0-ul-1',0,'PRE SEP t/tests/simple-1-0-ul.tt SEP Level1 SEP '],
		['simple-1-0-ul-0',0,'PRE SEP t/tests/simple-1-0-ul.tt SEP Level1'],
	) {
		ok($seen{"METRIC: $$expect[1] $$expect[2]"},$$expect[0]);
	}
	#
	is(scalar(keys %seen),15,'Pigeonhole');
};

subtest 'stderr, all data, no label'=>sub {
	plan tests=>17;
	my $prove=App::Prove->new();
	$prove->process_args('-PMetrics=stderr,prefix,PRE,sep, SEP ,subdepth,-1,label,0,rollup,0',glob('t/tests/simple-*.tt'));
	my $serr; steal_stderr(\$serr);
	$prove->run();
	return_stderr();
	my %seen=map {$_=>1} map {s/\s+/ /gr} grep {/^METRIC:/} split(/\n/,$serr);
	foreach my $expect (
		['simple-0-1',     1,'PRE SEP t/tests/simple-0-1.tt'],
		['simple-1-1-1',   1,'PRE SEP t/tests/simple-1-1.tt SEP Level1'],
		['simple-1-1-0',   1,'PRE SEP t/tests/simple-1-1.tt'],
		['simple-2-1-2',   1,'PRE SEP t/tests/simple-2-1.tt SEP Level1 SEP Level2'],
		['simple-2-1-1',   1,'PRE SEP t/tests/simple-2-1.tt SEP Level1'],
		['simple-2-1-0',   1,'PRE SEP t/tests/simple-2-1.tt'],
		['simple-0-0',     0,'PRE SEP t/tests/simple-0-0.tt'],
		['simple-1-0-1',   0,'PRE SEP t/tests/simple-1-0.tt SEP Level1'],
		['simple-1-0-0',   0,'PRE SEP t/tests/simple-1-0.tt'],
		['simple-2-0-2',   0,'PRE SEP t/tests/simple-2-0.tt SEP Level1 SEP Level2'],
		['simple-2-0-1',   0,'PRE SEP t/tests/simple-2-0.tt SEP Level1'],
		['simple-2-0-0',   0,'PRE SEP t/tests/simple-2-0.tt'],
		['simple-1-0-n-1', 0,'PRE SEP t/tests/simple-1-0-n.tt SEP Level1'],
		['simple-1-0-n-0', 0,'PRE SEP t/tests/simple-1-0-n.tt'],
		['simple-1-0-ul-1',0,'PRE SEP t/tests/simple-1-0-ul.tt SEP Level1'],
		['simple-1-0-ul-0',0,'PRE SEP t/tests/simple-1-0-ul.tt'],
	) {
		ok($seen{"METRIC: $$expect[1] $$expect[2]"},$$expect[0]);
	}
	#
	is(scalar(keys %seen),16,'Pigeonhole');
};

subtest 'stderr, subdepth'=>sub {
	plan tests=>11;
	my ($prove,$serr);
	my @expect=(
		[0,0,'PRE SEP t/tests/mixed-2.tt'],
		[1,0,'PRE SEP t/tests/mixed-2.tt'],
		[2,0,'PRE SEP t/tests/mixed-2.tt'],
		[1,0,'PRE SEP t/tests/mixed-2.tt SEP Level1'],
		[2,0,'PRE SEP t/tests/mixed-2.tt SEP Level1'],
		[2,1,'PRE SEP t/tests/mixed-2.tt SEP Level1 SEP Level2A'],
		[2,0,'PRE SEP t/tests/mixed-2.tt SEP Level1 SEP Level2B'],
	);
	foreach my $level (0..2) {
		my $prove=App::Prove->new();
		$prove->process_args('-PMetrics=stderr,prefix,PRE,sep, SEP ,subdepth,'.$level.',label,0,rollup,0','t/tests/mixed-2.tt');
		my $serr=''; steal_stderr(\$serr);
		$prove->run();
		return_stderr();
		foreach my $expect (grep {$$_[0]<=$level} @expect) { like($serr,qr{METRIC:\s*$$expect[1]\s*\Q$$expect[2]\E},$$expect[2]) }
	}
};

my %metrics;
subtest 'module'=>sub {
	plan tests=>1;
	%metrics=();
	my %expect=(
		"t/tests/mixed-2.tt\tLevel1\tLevel2A" => 1,
		"t/tests/mixed-2.tt\tLevel1\tLevel2B" => 0,
		"t/tests/mixed-2.tt\tLevel1" => 0,
		"t/tests/mixed-2.tt" => 0
	);
	package MetricsTestModule {
		sub configureHarness { return (prefix=>'',sep=>"\t",subdepth=>-1,label=>0,rollup=>0) }
		sub save { my (%h)=@_; while(my ($k,$v)=each %h) { $metrics{$k}=$v } }
	};
	$INC{'MetricsTestModule.pm'}=1;
	my $prove=App::Prove->new();
	$prove->process_args('-PMetrics=module,MetricsTestModule','t/tests/mixed-2.tt');
	my $serr=''; steal_stderr(\$serr);
	$prove->run();
	return_stderr();
	is_deeply(\%metrics,\%expect,'collected metrics');
};

