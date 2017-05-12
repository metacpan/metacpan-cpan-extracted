#!/usr/bin/env perl
use strict;

use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();


use Getopt::Long;
my($action);
if (!GetOptions(
		"action=s"=>\$action,
	       )
   ){
  die;
}
die "must pass a --action=ACTION argument" unless $action;

foreach (@ARGV){
  $sbs->job_action(id=>$_, action=>$action);
}
