#!perl
use warnings;
use strict;

# SQLite database for testing
use FindBin qw($Bin);
my $db = "$Bin/test.db";
unlink($db);

##################################################

package Testing;
use base qw( Class::DBI );
use Class::DBI::PagedSearch;

__PACKAGE__->set_db( Main => "dbi:SQLite:$db", "", "");
__PACKAGE__->columns( All => qw( id text  ));

# set up the testing table
__PACKAGE__->db_Main->do("
  CREATE TABLE testing (
    id INT NOT NULL,
    text TEXT
  )
");

##################################################

package main;
use Data::Page;
use Test::More tests => 49;

for (1 .. 40) {
  ok( my $test = Testing->create({ text => 'aa', id => $_ }), "new test object" );
}

is( Testing->search(), 40, "got hundred entries" );

my $page = Data::Page->new();
$page->entries_per_page(10);
$page->current_page(3);
is( my @entries = Testing->search(text => 'aa', {pager => $page} ), 10, 'got ten etries' );
is( shift @entries, 21, 'got lower bound entry');
is( pop @entries, 30, 'got upper bound entry');
is( $page->total_entries, 40, "40 entries in the database" );

@entries = Testing->search_sql( 'SELECT id, text FROM testing WHERE text = ?', 'aa', {pager => $page} );
is( @entries, 10, 'got our ten etries' );
is( shift @entries, 21, 'got lower bound entry');
is( pop @entries, 30, 'got upper bound entry');
is( $page->total_entries, 40, "40 entries in the database" );

