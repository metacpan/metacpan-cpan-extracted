#!/usr/bin/env perl
use strict;

use Test::More tests => 9;
use File::Basename;
use File::Temp qw(tempdir);

use_ok('BatchSystem::SBS' );

my $fconfig=dirname($0)."/sbsconfig-2.xml";

my $sbs=BatchSystem::SBS->new();
ok($sbs, "BatchSystem::SBS object created");
$sbs->readConfig(file=>$fconfig);

ok(defined $sbs->scheduler(), "scheduler defined");

my $tmpdir=tempdir(UNLINK=>!$ENV{NOPUTZ4TEST}, CLEANUP=>!$ENV{NOPUTZ4TEST});
ok($sbs->workingDir($tmpdir), "setting temp workingdir [$tmpdir]");
my $jli_fname="$tmpdir/joblist.dump";
ok($sbs->scheduler->joblist_index($jli_fname), "setting scheduler joblist index to $jli_fname");

my $rsi_fname="$tmpdir/resources.dump";
ok($sbs->scheduler->resourcesStatus_index($rsi_fname), "setting scheduler resources index to $rsi_fname");
$sbs->scheduler->resourcesStatus_init();

my $qsi_fname="$tmpdir/queuesstatus.dump";
ok($sbs->scheduler->queuesStatus_index($qsi_fname), "setting scheduler queuesStatus index to $rsi_fname");
$sbs->scheduler->queuesStatus_init();

my $n=10;
for (1..$n){
  $sbs->job_submit(queue=>'single', command=>"hostname");
}

is($sbs->scheduler->joblist_size, $n, "$n job in the list");

is($sbs->job_info(id=>1)->{status}, 'PENDING', "job 1 is PENDING");

my @readids=$sbs->scheduler->scheduling_next_reserve();

foreach (@readids){
  $sbs->scheduler->job_execute(id=>$_);
}

