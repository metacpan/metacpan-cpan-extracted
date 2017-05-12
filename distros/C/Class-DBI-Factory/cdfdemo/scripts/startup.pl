#!/usr/bin/perl

use strict;
use warnings;

use lib '[% demo_root %]/lib';
use Apache ();
use Apache::Request ();
use Apache::Cookie ();
use Apache::Constants qw(:response);
use Apache::Util ();
use Apache::Status ();

use DBI; 
DBI->install_driver('SQLite');
use Class::DBI ();
$Class::DBI::Weaken_Is_Available = 0;	#disables unique-object stash for now

use Class::DBI::Factory ();
Class::DBI::Factory->add_status_menu;

use Template ();
use POSIX ();

1;
