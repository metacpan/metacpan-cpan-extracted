#!/usr/bin/env perl -w
use strict;
use Test;
use lib qw(lib);
BEGIN { plan tests => 1 }

use Schedule::Chronic; 
use Schedule::Chronic::Tab;
use Schedule::Chronic::Constraint::Loadavg;
use Schedule::Chronic::Constraint::DiskIO;
use Schedule::Chronic::Constraint::Inactivity;
use Schedule::Chronic::Constraint::Freq;
ok(1);
exit;

