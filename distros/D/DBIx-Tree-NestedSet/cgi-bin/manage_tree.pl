#!/usr/bin/perl

use strict;
use DBIx::Tree::NestedSet();
#Change this to whatever subclass you've created to manage
#your tree.
use DBIx::Tree::NestedSet::Manage();


my $dbh=DBI->connect("dbi:mysql:database","user","pass",{RaiseError => 1, AutoCommit =>1}) or die("Couldn't connect to database");

my $tree=DBIx::Tree::NestedSet->new(dbh=>$dbh) or die("Couldn't create tree!");

my $manager=
  DBIx::Tree::NestedSet::Manage->new(
				     TMPL_PATH=>'/www/legalnet/mods/DBIx/Tree/NestedSet/Manage/',
				     PARAMS=>{
					      dbh=>$dbh,
					      tree=>$tree,
					      template_name=>'manage_tree.tmpl'
					     }
				    );

$manager->run();
