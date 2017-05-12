#!/usr/bin/env perl
use strict;

use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();

use Getopt::Long;
my($isFinished);
if (!GetOptions(
		"isfinished"=>\$isFinished,
	       )
   ){
  die;
}

foreach (@ARGV){
  print STDERR "$_\tremoved\n" if $sbs->job_remove(id=>$_, isfinished=>$isFinished);
}
