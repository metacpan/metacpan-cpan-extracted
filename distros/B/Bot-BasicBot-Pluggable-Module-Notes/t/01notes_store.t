#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DatabaseRow;

use Test::Bot::BasicBot::Pluggable;

my $TESTDB = 't/brane.db';
my @stores = qw/SQLite DBIC/;

foreach my $store_name (@stores) {
    unlink $TESTDB;

    my $store_class = "Bot::BasicBot::Pluggable::Module::Notes::Store::${store_name}";
    ## IMPLEMENT SKIP HERE?
    use_ok( $store_class );

    my $store = $store_class->new( "t/brane.db" );
    isa_ok( $store, $store_class);

    my $dbh = $store->dbh;
    $Test::DatabaseRow::dbh = $dbh;

## test direct store, no tags.
    ok($store->store(
           timestamp => '2010-01-01 23:23:23',
           name => 'directstore',
           channel => '#stored',
           notes => 'stored directly',
       ), 'Stored bare entry in DB');
    
    row_ok( table => "notes",
            where => [ channel => '#stored', notes => 'stored directly', name => 'directstore' ],
            label => "Finds directly stored data'" );

## test direct store, tags.
    if ($store_name eq 'DBIC') {
        ok($store->store(
               timestamp => '2010-01-01 23:23:23',
               name => 'directstore2',
               channel => '#stored2',
               notes => 'stored directly',
               tags => [qw<test boobies>],
           ), 'Stored bare entry in DB');
        
        row_ok( table => "notes",
                where => [ channel => '#stored2', notes => 'stored directly', name => 'directstore2' ],
                label => "Finds directly stored data'" );
        
        row_ok( table => 'tags',
                where => [ tag => 'test' ],
                label => "test tag in tags table, store = $store_name"
            );
        row_ok( table => 'tags',
                where => [ tag => 'boobies' ],
                label => 'boobies tag in tags table'
            );
    }

## get_notes, simple
    my $notes = $store->get_notes(name => 'directstore');
    is(@$notes, 1, 'Found the one stored note for this user');
    
    my $notes_multi_col = $store->get_notes(channel => '#stored', name => 'directstore');
    is(@$notes, 1, 'Found the one stored note for this user and channel');
    
    my $no_notes = $store->get_notes(name => 'nosuchuser');
    ok(!@$no_notes, 'No notes returned for non-existant user');
    
## get_notes, paging+rows
# add second+third row:

    $store->store(
        timestamp => '2010-01-02 22:22:22',
        name => 'directstore',
        channel => '#stored',
        notes => 'A second note in #stored',
        );
    $store->store(
        timestamp => '2010-01-02 22:22:22',
        name => 'directstore',
        channel => '#stored',
        notes => 'A third note in #stored',
        );

    row_ok( table => "notes",
            where => [ channel => '#stored', name => 'directstore' ],
            results => 3,
            label => "Returns 3 rows of directstore data" );

    my $notes_paged = $store->get_notes(rows => 1, page => 1);
    is(@$notes_paged, 1, 'Returned one note when pages at one row per page');

}

done_testing;

END {
    unlink $TESTDB;
}

