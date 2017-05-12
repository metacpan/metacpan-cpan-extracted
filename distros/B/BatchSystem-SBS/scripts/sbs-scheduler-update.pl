#!/usr/bin/env perl
use strict;
use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();

$sbs->scheduler->scheduling_update();
