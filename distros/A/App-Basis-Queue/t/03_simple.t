#!/usr/bin/perl -w

=head1 NAME

03_simple.t

=head1 DESCRIPTION

perform basic tests on App::Basis::Queue
while the tests are setup into subtests, they are not independent of the
preceding tests as the data the preceding tests creates is used in
subsequent ones

=head1 AUTHOR

   kevin mulholland, moodfarm@cpan.org

=cut

use 5.10.0 ;
use feature 'state' ;
use strict ;
use warnings ;

use Test::More ;
use POSIX qw(strftime) ;
use DBI ;
use Try::Tiny ;
use Time::HiRes qw(gettimeofday tv_interval ) ;

BEGIN {
    if ( $ENV{AUTHOR_TESTING} ) {
        plan tests => 7 ;
    } else {
        plan tests => 1 ;
    }
    use_ok('App::Basis::Queue') ;
}

# create a name for the queue we will be testing with, it should not exist!
my $test_q = strftime( "%Y-%m-%d %H:%M:%S", localtime() ) . "_" . $$ . '_' ;
$test_q =~ s/[ :-]/_/g ;
$test_q = 'tst' ;
my $qname       = '/basic_q' ;
my $queue_two   = "$qname/two" ;
my $queue_three = "$qname/three" ;

my ( $queue, $dbh ) ;
my $add_items = 1000 ;

# get optional DSN info from the user environment
my $dsn
    = $ENV{SQ_DSN}
    ? $ENV{SQ_DSN}
    : "dbi:SQLite:/tmp/queue_simple-tasks.$test_q.sqlite3" ;
my $user   = $ENV{SQ_USER} ;
my $passwd = $ENV{SQ_PASSWD} ;

# ----------------------------------------------------------------------------

=item query_db

general purpose db query tool, returns all results as a arrayref of hashes
this function was created by kevin outside of home
copyright is retained with him
returns ref to data and a status msg

=cut

sub query_db
{
    my ( $dbh, $query, $p ) = @_ ;
    our @params = $p ? @$p : () ;
    my ( $result, $err, $sth ) ;

    try {
        $sth = $dbh->prepare($query) ;
        my $rv = $sth->execute(@params) ;

        # so as to get an array of hashes
        $result = $sth->fetchall_arrayref( {} ) ;
    }
    catch {} ;
    return $result, $err ;
}

# ----------------------------------------------------------------------------
# Testing starts here
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# author testing can use sql, automated CPAN testing may not be able to
if ( $ENV{AUTHOR_TESTING} ) {

    # $add_items = ( $add_items / 10 ) if ( $dsn =~ /SQLite/i );

# set PrintError off otherwise it will tell us that tables do not exist, we know that!
    $dbh
        = DBI->connect( $dsn, $user, $passwd,
        { RaiseError => 1, PrintError => 0, AutoCommit => 1 } )
        or die "Could not connect to DB $dsn" ;
    note "Testing against $dsn" ;

    if ( $dsn =~ /SQLite/i ) {
        $dbh->do("PRAGMA journal_mode = WAL") ;
        $dbh->do("PRAGMA synchronous = NORMAL") ;
    }

# -----------------------------------------------------------------------------

    subtest "check clean start\n" => sub {

       # remove all entries from the tables to make sure we are starting clean
        my $table_name = $test_q . "_queue" ;
        my ( $ret, $err ) = query_db( $dbh, "DROP TABLE $table_name;" ) ;

        # check the table does not exist before we start
        ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" ) ;

        ok( !$ret && !$err, "Table $table_name does not exist" ) ;
    } ;

# -----------------------------------------------------------------------------

    subtest "create queue object\n" => sub {
        $queue = App::Basis::Queue->new(
            dbh    => $dbh,
            prefix => $test_q,
            debug  => $ENV{DEBUG}
        ) ;
        isa_ok( $queue, 'App::Basis::Queue' ) ;

        # ->new should have created the various database tables,
        # lets check if this is the case
        # we know that the tables will start with $test_q
        # and they are 'queue_names' and 'queue_info'
        my $table_name = $test_q . "_queue" ;
        my ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" ) ;
        ok( $ret, "Table $table_name exists" ) ;

        my $queue_list = $queue->list_queues() ;
        ok( !scalar(@$queue_list), 'No queues listed' ) ;
    } ;

# -----------------------------------------------------------------------------

    subtest "adding to queue\n" => sub {
        my ( $stats, $old_stats ) ;

        # add 1 thing to the queue
        my $resp = $queue->push(
            queue => $qname,
            data  => { item => 1, desc => "test data" }
        ) ;
        ok( $resp, "pudhed 1 item to $qname" ) ;

        my $count = 0 ;
        foreach my $i ( 2 .. 11 ) {
            my $resp = $queue->push(
                queue => $qname,
                data  => { item => $i, desc => "test data" }
            ) ;
            $count++ if ($resp) ;
        }
        ok( $count == 10, '10 items pushed to queue ' . $qname ) ;

        my $queue_list = $queue->list_queues() ;
        ok( scalar(@$queue_list) == 1 && $queue_list->[0] eq $qname,
            "Single queue ($qname) listed" ) ;

        # get queue size, check 11 things on the queue
        my $size = $queue->size( queue => $qname ) ;
        ok( $size == 11, "expecting 11 items in $qname - got $size" ) ;
    } ;

# -----------------------------------------------------------------------------

    subtest "queue popping\n" => sub {
        my ( $stats, $old_stats ) ;

        # fetch 1 thing
        my $record = $queue->pop( queue => $qname ) ;
        # note explain $record ;
        # check it is item 1
        ok( $record->{item} == 1, "got expected first record" ) ;

        # get queue size, check now 10 things on the queue
        my $size = $queue->size( queue => $qname ) ;
        ok( $size == 10, "found $size items in $qname, expected 10" ) ;

        # get the next 10 items and check that they are in expected order
        my $counter = 0 ;
        for ( my $i = 2; $i <= 11; $i++ ) {
            $record = $queue->pop( queue => $qname ) ;
            # check it is correct item
            $counter++ if ( $record && $record->{item} == $i ) ;
        }
        ok( $counter == 10, "expected 10 items in pushed order, got $counter" ) ;
    } ;

# -----------------------------------------------------------------------------

    subtest "wildcards\n" => sub {
        $queue->push(
            queue => "/wild/1",
            data  => { number => 1, data => "test data" }
        ) ;
        $queue->push(
            queue => "/wild/two",
            data  => { number => 2, data => "test data" }
        ) ;
        my $size = $queue->size( queue => "/wild/*" ) ;
        ok( $size == 2, "two items in /wild/*" ) ;

        # get first thing
        my $record = $queue->pop( queue => "/wild/*", ) ;
        # check record is the first
        ok( $record->{number} == 1, "got expected first record" ) ;

        $size = $queue->size( queue => "/wild/*" ) ;
        ok( $size == 1, "popped one item from /wild/*" ) ;

        # get next thing
        $record = $queue->pop( queue => "/wild/*", ) ;
        # check record is the first
        ok( $record->{number} == 2, "got expected second record" ) ;

        $size = $queue->size( queue => "/wild/*" ) ;
        ok( $size == 0, "nothing left in /wild/*" ) ;
    } ;

# -----------------------------------------------------------------------------

    subtest "cleanup\n" => sub {

# we could unlink the table if using sqlite, but it may be a general purpose one
# and obviously we cannot unlink postgreSQL or mysql so lets not even bother

        $queue->remove_tables() ;

        # check we have removed the table
        my $table_name = $test_q . "_queue" ;
        my ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" ) ;
        ok( !$ret && !$err, "Table $table_name has been removed" ) ;
    } ;
} else {
    # testing has been done in BEGIN, just loads the module
}
