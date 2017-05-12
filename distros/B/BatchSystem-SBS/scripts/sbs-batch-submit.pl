#!/usr/bin/env perl
use strict;

use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();

use Getopt::Long;
my(@command, $chainCommands, $queue, $title, $onfinished);
if (!GetOptions(
		"command=s"=>\@command,
		"chain"=>\$chainCommands,
		"onfinished=s"=>\$onfinished,
		"queue=s"=>\$queue,
		"title=s"=>\$title,
	       )
   ){
  die;
}
die "must pass a --queue=queue_name argument" unless $queue;
die "must pass at least one --command=executabe argument" unless @command;
my @ids;
foreach(@command){
  my $id;
  if ($chainCommands && @ids){
    $id=$sbs->job_submit(command=>$_, queue=>$queue, title=>$title, on_finished=>$ids[-1]);
    print {*BatchSystem::SBS::STDLOG} info=> "chaining [$ids[-1]](on_finished)->[$id]";
  }else{
    $id=$sbs->job_submit(command=>$_, queue=>$queue, title=>$title, on_finished=>$onfinished);
  }
  push @ids, $id;
}
$sbs->scheduler->scheduling_update();
print {*BatchSystem::SBS::STDLOG} info=> "submited job(s) [@ids]\n";
print "$_\n" foreach (@ids);
