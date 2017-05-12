#!/usr/bin/perl -w
#package AAA_01
#the line above does not have to interest you
use Test::More no_plan;
use strict;

BEGIN {
	$| = 1;
	chdir 't' if -d 't';
	unshift @INC, '../bin';
	unshift @INC, '../lib';
	use_ok 'Applications::BackupAndRestore';
}

Gtk2->init;
isa_ok my $fqf = new Applications::BackupAndRestore, "Applications::BackupAndRestore";
$fqf->show;
Gtk2->main_iteration while Gtk2->events_pending;

__END__
