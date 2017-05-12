#!/usr/bin/perl

use strict;
use warnings;

use lib '[% demo_root %]/lib';
use Apache2 ();
use Apache::Const;
use Apache::Request ();
use Apache::Cookie ();
use Apache::Util ();
use Apache::Status ();

use DBI; 
DBI->install_driver('SQLite');

use Class::DBI ();
use Class::DBI::Factory ();
$Class::DBI::Weaken_Is_Available = 0;	#disables unique-object stash for now

use Template ();
use POSIX ();

1;
