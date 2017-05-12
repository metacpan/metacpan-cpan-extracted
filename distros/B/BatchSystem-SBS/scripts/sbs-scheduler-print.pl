#!/usr/bin/env perl
use strict;

use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();

use Getopt::Long;
if (!GetOptions(
		
	       )
   ){
  die;
}
print $sbs->scheduler
