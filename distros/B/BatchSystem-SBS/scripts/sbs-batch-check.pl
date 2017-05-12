#!/usr/bin/env perl
use strict;
use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();

$sbs->scheduler->resources_check();
$sbs->scheduler->resources_removenull();
