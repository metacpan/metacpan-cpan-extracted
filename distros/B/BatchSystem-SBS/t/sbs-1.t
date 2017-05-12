#!/usr/bin/env  perl
use strict;

use Test::More tests => 13;
use File::Basename;
use File::Temp qw(tempdir);

use_ok('BatchSystem::SBS' );

my $fconfig=dirname($0)."/sbsconfig-1.xml";

my $sbs=BatchSystem::SBS->new();
ok($sbs, "BatchSystem::SBS object created");
$sbs->readConfig(file=>$fconfig);

ok(defined $sbs->scheduler(), "scheduler defined");

my $tmpdir=tempdir(UNLINK=>!$ENV{NOPUTZ4TEST}, CLEANUP=>!$ENV{NOPUTZ4TEST});
ok($sbs->workingDir($tmpdir), "setting temp workingdir [$tmpdir]");
my $jli_fname="$tmpdir/joblist.dump";
ok($sbs->scheduler->joblist_index($jli_fname), "setting scheduler job index to $jli_fname");

my $jobsdir=$sbs->jobs_dir();
ok($jobsdir, "set jobs_dir to [$jobsdir");

#adding one job
my $jid=$sbs->job_submit(queue=>'single', command=>"sleep 1");
my $dir=$sbs->jobs_dir()."/$jid";
ok(-d $dir, "job directory was created($dir)");

#checking dump file size
ok(-f $jli_fname, "scheduler job index file have been created");
my $sz=(stat $jli_fname)[7];
ok($sz>0, "scheduler job index file is not empty ($sz)");
is($sbs->scheduler->joblist_size, 1, "1 job in the list");

#add more jobs
$sbs->job_submit(queue=>'single', command=>"sleep 2");
$sbs->job_submit(queue=>'single', command=>"sleep 3");
is($sbs->scheduler->joblist_size, 3, "3 jobs in the list");

#remove one
ok($sbs->scheduler->job_remove(id=>1), "job [1] removed");
is($sbs->scheduler->joblist_size, 2, "2 jobs in the list");
#print STDERR $sbs->scheduler;
