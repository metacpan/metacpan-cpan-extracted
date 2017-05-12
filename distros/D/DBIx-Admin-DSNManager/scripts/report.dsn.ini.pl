#!/usr/bin/env perl

use strict;
use warnings;

use DBIx::Admin::DSNManager;

use File::Spec;

# --------------------------

my($manager) = DBIx::Admin::DSNManager -> new
(
	file_name => File::Spec -> catdir('t', 'dsn.ini'),
	verbose   => 1,
) || die $DBIx::Admin::DSNManager::errstr;

$manager -> report;

my($section) = 'SQLite.1';
my($config)  = $manager -> config;

print "Section: $section. dsn: $$config{$section}{dsn}. \n";
