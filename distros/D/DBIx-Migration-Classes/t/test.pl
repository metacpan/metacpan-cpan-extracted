#!/usr/bin/perl -w

use strict;
use lib '../lib';
use lib './lib';
use DBIx::Migration::Classes;

# create a migrator instance
my $migrator = 
	DBIx::Migration::Classes->new(
		namespaces => ['MyTestChanges'],
		dbname => 'migratetest',
	);

# migrate a database from current state to another
#$migrator->migrate("HEAD");
$migrator->_test();

