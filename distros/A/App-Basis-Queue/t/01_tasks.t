#!/usr/bin/perl -w

=head1 NAME

01_basic.t

=head1 DESCRIPTION

perform basic tests on App::Basis::Queue
while the tests are setup into subtests, they are not independent of the
preceding tests as the data the preceding tests creates is used in
subsequent ones

=head1 AUTHOR

   kevin mulholland, moodfarm@cpan.org

=cut

use 5.10.0;
use feature 'state';
use strict;
use warnings;

use Test::More;
use POSIX qw(strftime);
use DBI;
use Try::Tiny;
use Time::HiRes qw(gettimeofday tv_interval );

BEGIN {
    if ( $ENV{AUTHOR_TESTING} ) {
        plan tests => 13;
    }
    else {
        plan tests => 1;
    }
    use_ok('App::Basis::Queue');
}

# create a name for the queue we will be testing with, it should not exist!
my $test_q = strftime( "%Y-%m-%d %H:%M:%S", localtime() ) . "_" . $$ . '_';
$test_q =~ s/[ :-]/_/g;
$test_q = 'tst';
my $qname       = '/basic_q';
my $queue_two   = "$qname/two";
my $queue_three = "$qname/three";

my ( $queue, $dbh );
my $add_items = 1000;

# get optional DSN info from the user environment
my $dsn
    = $ENV{SQ_DSN}
    ? $ENV{SQ_DSN}
    : "dbi:SQLite:/tmp/queue_simple-tasks.$test_q.sqlite3";
my $user   = $ENV{SQ_USER};
my $passwd = $ENV{SQ_PASSWD};

# ----------------------------------------------------------------------------

=item query_db

general purpose db query tool, returns all results as a arrayref of hashes
this function was created by kevin outside of home
copyright is retained with him
returns ref to data and a status msg

=cut

sub query_db {
    my ( $dbh, $query, $p ) = @_;
    our @params = $p ? @$p : ();
    my ( $result, $err, $sth );

    try {
        $sth = $dbh->prepare($query);
        my $rv = $sth->execute(@params);

        # so as to get an array of hashes
        $result = $sth->fetchall_arrayref( {} );
    }
    catch {};
    return $result, $err;
}

# ----------------------------------------------------------------------------
# process and pass queue item
sub pass_item {
    my ( $self, $qname, $record ) = @_;
    return 1;
}

# ----------------------------------------------------------------------------
# process and pass queue item after a small sleep
sub pass_delay_item {
    state $count ;

    $count = 1 + ( ( $count++ ) % 3 );    # delay 1, 2, 3 seconds
    my ( $self, $qname, $record ) = @_;
    sleep($count);
    return 1;
}

# ----------------------------------------------------------------------------
# process and fail queue item
sub fail_item {
    my ( $self, $qname, $record ) = @_;
    return 0;
}

# ----------------------------------------------------------------------------
# move an item onto another queue
sub move_q2 {
    my ( $self, $qname, $record ) = @_;
    $self->delete_record($record);
    $self->add( queue => $queue_two, data => $record->{data} );
    return 1;
}

# ----------------------------------------------------------------------------
# reset an item on the queue
sub reset_q2 {
    my ( $self, $qname, $record ) = @_;
    $self->reset_record($record);
    return 1;
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
        or die "Could not connect to DB $dsn";
    note "Testing against $dsn";

    if ( $dsn =~ /SQLite/i ) {
        $dbh->do("PRAGMA journal_mode = WAL");
        $dbh->do("PRAGMA synchronous = NORMAL");
    }

# -----------------------------------------------------------------------------
    subtest "check clean start\n" => sub {

       # remove all entries from the tables to make sure we are starting clean
        my $table_name = $test_q . "_queue";
        my ( $ret, $err ) = query_db( $dbh, "DROP $table_name;" );

        # check the table does not exist before we start
        ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" );

        ok( !$ret && !$err, "Table $table_name does not exist" );
    };

# -----------------------------------------------------------------------------
    subtest "create queue object\n" => sub {
        $queue = App::Basis::Queue->new(
            dbh    => $dbh,
            prefix => $test_q,
            debug  => 0
        );
        isa_ok( $queue, 'App::Basis::Queue' );

# new should have created the various database tables, lets check if this is the case
# we know that the tables will start with $test_q and the be 'queue_names' and 'queue_info'
        my $table_name = $test_q . "_queue";
        my ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" );
        ok( $ret, "Table $table_name exists" );

        my $queue_list = $queue->list_queues();
        ok( !scalar(@$queue_list), 'No queues listed' );
    };

# -----------------------------------------------------------------------------
    subtest "adding to queue\n" => sub {
        my ( $stats, $old_stats );

        # add 1 thing to the queue
        my $resp = $queue->add(
            queue => $qname,
            data  => { number => 17, desc => "test data" }
        );
        ok( $resp, "added 1 item to $qname" );

        my $count = 0;
        note "delay processing";
        foreach my $i ( 1 .. 10 ) {
            my $resp = $queue->add(
                queue => $qname,
                data  => { number => $i, desc => "test data", delay => 3 }
            );
            $count++ if ($resp);
        }
        ok( $count == 10, '10 items add to queue ' . $qname );

        my $queue_list = $queue->list_queues();
        ok( scalar(@$queue_list) == 1 && $queue_list->[0] eq $qname,
            "Single queue ($qname) listed" );

        # get queue_size, check 11 things on the queue
        my $size = $queue->queue_size( queue => $qname );
        ok( $size == 11, "found 11 items in $qname" );
        $stats = $queue->stats( queue => $qname );
        ok( $stats->{unprocessed} == 11, '11 unprocessed items' );
        ok( !$stats->{processed},        'no processed items' );
    };

# -----------------------------------------------------------------------------
    subtest "queue processing\n" => sub {
        my ( $stats, $old_stats );

        # process 1 thing
        $queue->process(
            queue    => $qname,
            count    => 1,
            callback => \&pass_item
        );

        # get queue_size, check now 10 things on the queue
        my $size = $queue->queue_size( queue => $qname );
        ok( $size == 10, "found 10 items in $qname" );

        # get stats, check 1 processed item
        $stats = $queue->stats( queue => $qname );
        ok( $stats->{processed} == 1, 'one processed item' );

        # process another thing and fail it
        $queue->process(
            queue    => $qname,
            count    => 1,
            callback => \&fail_item
        );

        # get stats check that there is one failed processing item
        $stats = $queue->stats( queue => $qname );
        ok( $stats->{failures} == 1,    "one failed item in $qname" );
        ok( $stats->{unprocessed} == 9, "9 left in $qname" );

        # add 10th thing to the queue
        $queue->add(
            queue => $qname,
            data  => { number => 11, desc => "test data" }
        );

        # get queue_size, check 10 unprocessed
        $size = $queue->queue_size( queue => $qname );
        ok( $size == 10, "another item added, so 10 items in the $qname" );

        # add 12th item to another queue
        $queue->add(
            queue => $queue_two,
            data  => { number => 12, data => "test data" }
        );
        $size = $queue->queue_size( queue => $queue_two );
        ok( $size == 1, "found 1 item in $queue_two" );

        # get its queue_size
        # check queue_size of main queue, should still be 10
        $size = $queue->queue_size( queue => $qname );
        ok( $size == 10, "still have 10 items in $qname" );

        # process 5 things
        $queue->process(
            queue    => $qname,
            count    => 5,
            callback => \&pass_item
        );

        # get queue_size, check 5 items
        $size = $queue->queue_size( queue => $qname );
        ok( $size == 5, "5 items remaining on $qname" );

        # process 3 things, sleep 3s for each
        $queue->process(
            queue    => $qname,
            count    => 3,
            callback => \&pass_delay_item
        );

        # get queue_size, check 2 items
        $size = $queue->queue_size( queue => $qname );
        ok( $size == 2, "2 items remaining on $qname" );

        # fail 2 remaining items
        $queue->process(
            queue    => $qname,
            count    => 5,
            callback => \&fail_item
        );
        $stats = $queue->stats( queue => $qname );
        ok( $stats->{unprocessed} == 0, "0 items left in $qname" );
        ok( $stats->{failures} == 3,    "3 failures in $qname" );
    };

# -----------------------------------------------------------------------------
    subtest "reset_failures\n" => sub {
        my ( $stats, $old_stats );

        $old_stats = $queue->stats( queue => $qname );
        $queue->reset_failures( queue => $qname );
        $stats = $queue->stats( queue => $qname );

        ok( $stats->{unprocessed} == 3,
            "3 items left in $qname after reset_failures" );
        ok( $stats->{processed} == $old_stats->{processed},
            "we still have $old_stats->{processed} items in $qname after reset_failures"
        );
        ok( !$stats->{failures},
            "no failures left in $qname after reset_failures" );
    };

# -----------------------------------------------------------------------------
    subtest "purge_tasks\n" => sub {
        my ( $stats, $old_stats );

        # fail earliest record
        $queue->process(
            queue    => $qname,
            count    => 1,
            callback => \&fail_item
        );
        $old_stats = $queue->stats( queue => $qname );
        $queue->purge_tasks( queue => $qname );
        $stats = $queue->stats( queue => $qname );

        ok( $stats->{unprocessed} == $old_stats->{unprocessed},
            "$old_stats->{unprocessed} items left to process in $qname after purge"
        );
        ok( !$stats->{processed},
            "no processed items in $qname after purge" );
        ok( !$stats->{failures}, "no failures left in $qname after purge" );
    };

# -----------------------------------------------------------------------------
    subtest "process_failures\n" => sub {
        my ( $stats, $old_stats );

        # fail the 2 records that are in $qname
        $queue->process(
            queue    => $qname,
            count    => 2,
            callback => \&fail_item
        );
        $old_stats = $queue->stats( queue => $qname );
        ok( $old_stats->{failures} == 2, "we have some failures on $qname" );
        $queue->process_failures(
            queue    => $qname,
            count    => 2,
            callback => \&move_q2
        );

        my $qstats  = $queue->stats( queue => $qname );
        my $q2stats = $queue->stats( queue => $queue_two );

        ok( $qstats->{total_records} < $old_stats->{total_records},
            "less records in $qname after move" );
        ok( !$qstats->{failures}, "no failures on $qname" );
        ok( $q2stats->{unprocessed} == 3,
            "3 unprocessed items on $queue_two"
        );
    };

    subtest "reset_records\n" => sub {
        my ( $stats, $old_stats );

        # fail all records in $queue_two
        $queue->process(
            queue    => $queue_two,
            count    => 3,
            callback => \&fail_item
        );
        $old_stats = $queue->stats( queue => $queue_two );
        ok( $old_stats->{failures} == 3,
            "we have our failures in $queue_two" );
        $queue->process_failures(
            queue    => $queue_two,
            count    => 3,
            callback => \&reset_q2
        );
        $stats = $queue->stats( queue => $queue_two );
        ok( !$stats->{failures} && $stats->{unprocessed} == 3,
            "we have reset our failures in $queue_two"
        );
    };

    subtest "another_queue" => sub {

        # make sure we have data in-sync
        note
            "test that 2 different queue instances can both add to the same queue";
        my $dbh2
            = DBI->connect( $dsn, $user, $passwd,
            { RaiseError => 0, PrintError => 0, AutoCommit => 1 } )
            or die "Could not connect to DB $dsn";
        my $another_q = App::Basis::Queue->new(
            dbh    => $dbh2,
            prefix => $test_q,
            debug  => 0
        );
        my $q3 = "$qname/three";

        # now queue and another_q both know the same queue queue_names
        # create a new queue via queue
        $queue->add(
            queue => $q3,
            data  => { number => 3, note => 'queue' }
        );

# at this point another_q does not know of the q3 queue, what happens if I add to it?
        my $status = $another_q->add(
            queue => $q3,
            data  => { number => 4, note => 'another_q' }
        );
        ok( $status, "added via another queue instance" );

        $queue->add(
            queue => $q3,
            data  => { number => 5, note => 'queue' }
        );
        my $stats = $another_q->stats( queue => $q3 );
        ok( $stats->{unprocessed} == 3, "second instance has valid stats" );
    };

# -----------------------------------------------------------------------------
    subtest "remove_queue\n" => sub {
        my $resp = $queue->remove_queue( queue => $queue_two );
        ok( $resp, "Removed $queue_two and its entries" );
    };

# -----------------------------------------------------------------------------
# subtest "add many items\n" => sub {
#     my $loop = $add_items ;
#     note "add $loop items" ;
#     my $start = [gettimeofday] ;
#     my $count ;
#     # eval {
#       $dbh->begin_work ; # start a transaction
#     foreach my $i ( 1 .. $loop ) {
#         my $resp = $queue->add(
#             queue => $qname,
#             data  => { number => $i, desc => "test data" }
#         ) ;
#         $count++ if ($resp) ;
#     }
#     # $dbh->commit ;
#     # } ;
#     # if( $@) {
#     #     say STDERR "Error: during adding many items" ;
#     # }
#     my $elapsed = tv_interval($start) ;
#     ok( $count == $loop, "added $loop items" ) ;
#     my $rate = $count / $elapsed ;
#     ok( $rate > 5, "Insert rate > 5 per second" ) ;
#     note sprintf( "thats %.2f per second (%d in %ds)",
#         $rate, $count, $elapsed ) ;
# } ;

# -----------------------------------------------------------------------------
    subtest "wildcards\n" => sub {
        $queue->add(
            queue => "/wild/1",
            data  => { number => 12, data => "test data" }
        );
        $queue->add(
            queue => "/wild/two",
            data  => { number => 12, data => "test data" }
        );
        my $size = $queue->queue_size( queue => "/wild/*" );
        ok( $size == 2, "two items in /wild/*" );

        # process 1 thing
        $queue->process(
            queue    => "/wild/*",
            count    => 1,
            callback => \&pass_item
        );
        $size = $queue->queue_size( queue => "/wild/*" );
        ok( $size == 1, "processed one item from /wild/*" );

        # process 1 thing
        $queue->process(
            queue    => "/wild/*",
            count    => 1,
            callback => \&pass_item
        );
        $size = $queue->queue_size( queue => "/wild/*" );
        ok( $size == 0, "nothing left in /wild/*" );
    };

# -----------------------------------------------------------------------------

    subtest "cleanup\n" => sub {

# we could unlink the table if using sqlite, but it may be a general purpose one
# and obviously we cannot unlink postgreSQL or mysql so lets not even bother

        $queue->remove_tables();

        # check we have removed the table
        my $table_name = $test_q . "_queue";
        my ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" );
        ok( !$ret && !$err, "Table $table_name has been removed" );
    };
}
else {
    # testing has been done in BEGIN, just loads the module
}
