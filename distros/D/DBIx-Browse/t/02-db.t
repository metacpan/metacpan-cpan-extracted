#!/usr/bin/perl

use Test::More tests => 17;

use CGI;
use DBI;
use DBIx::Browse;
use DBIx::Browse::CGI;

use diagnostics;
use strict;

SKIP: {
    skip("database tests (see README file on how to allow them)", 17)
	unless ( $ENV{DBIX_BROWSE_MAKE_TEST} && $ENV{DBI_DSN} );

    my ( $dbh, $dbix_single, $dbix, $dbix_cgi, $sth, $row,
	 $pk, $id);

    ok( $dbh = DBI->connect() , 'Connecting to DSN');

    ok( $dbix_single = DBIx::Browse->new({dbh => $dbh, table => 'class'}),
	"Creating single table object.");
    ok( $dbix = DBIx::Browse->new({
	   debug         => 1,
	   dbh           => $dbh,
	   table         => 'item',
	   proper_fields => [ qw( name  )],
	   linked_fields => [ qw( class )]
	   }),
       "Creating linked table object.");
#     eval { 
# 	my $dbh_bad = new DBIx::Browse({
# 	    dbh           => $dbh,
# 	    table         => 'item',
# 	    proper_fields => [ qw( name  )],
# 	    linked_fields => [ qw( class )],
# 	    linked_tables => [ qw( class class ) ]
# 	    });
# 	};
# 	ok(!$@, "Parameter check.");
    
    ok($dbh->do("INSERT INTO class(name) VALUES('test2')"),
       "Init tables.");

    ok($dbix->insert({
	name  => 'test2',
	class => 'test2'
	}),
       "Insert.");

    ok($sth = $dbix->prepare({
	where => ' class = ? '
	}),
       "Statement: prepare");

    ok($sth->execute('test2'),
       "           execute");

    ok($row = $sth->fetchrow_hashref(),
	"          fetch row");

    ok($pk = $dbix->pkey_name,
       "           pkey name");

    ok($id = $row->{$pk},
       "           row id");
    $sth->finish;

    ok($dbix->update(
		     {class => 'test3'},
		     "id = ".$dbh->quote($id)
		     ),
       "Update.");

    ok($dbix->delete($id),
       "Delete");

    ok($dbix_cgi = DBIx::Browse::CGI->new({
	debug         => 1,
	dbh           => $dbh,
	table         => 'item',
	proper_fields => [ qw( name  )],
	linked_fields => [ qw( class )],
	no_print      => 1
	}),
       "CGI: create object");

    ok($dbix_cgi->insert({
	name  => 'test4',
	class => 'test2'
	}),
       "     insert");

    ok(my $lf = $dbix_cgi->list_form,
       "     list form");

    ok(my $ef = $dbix_cgi->edit_form(0),
       "     edit form");

    ok(my $bf = $dbix_cgi->browse,
       "     browse");


    $dbh->disconnect;
}


