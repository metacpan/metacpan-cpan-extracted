#!/usr/bin/env perl

=head1 NAME

02_pubsub.t

=head1 DESCRIPTION

perform pubsub tests on App::Basis::Queue
while the tests are setup into subtests, they are not independent of the
preceding tests as the data the preceding tests creates is used in
subsequent ones

=head1 AUTHOR

   kevin mulholland, moodfarm@cpan.org

=cut

use strict ;
use warnings ;
use feature 'state' ;

use Test::More ;
use POSIX qw(strftime) ;
use DBI ;
use Try::Tiny ;
use Time::HiRes qw(gettimeofday tv_interval ) ;

use App::Basis::Queue ;
use Data::Printer ;

BEGIN {
    if ( $ENV{AUTHOR_TESTING} ) {
        plan tests => 5 ;
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

# get optional DSN info from the user environment
my $db_loc = "/tmp/queue_simple-pubsub.$test_q.sqlite3" ;
my $dsn
    = $ENV{SQ_DSN}
    ? $ENV{SQ_DSN}
    : "dbi:SQLite:$db_loc" ;
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

# -----------------------------------------------------------------------------
sub _rand_pub
{
    my $c = int( rand(10) + 1 ) ;
    $dbh->begin_work ;
    for ( my $i = 0; $i < $c; $i++ ) {
        my $q = "/pub/" . int( rand(3) + 1 ) ;
        $queue->publish( queue => $q, data => { text => "item $i of $c" } ) ;
    }
    $dbh->commit ;
    return $c ;
}

# -----------------------------------------------------------------------------
my $persist_counter = 0 ;
sub _dump_data
{
    my $obj = shift ;
    my ( $queue, $data ) = @_ ;

    $persist_counter++ ;
    # note "Dump data for $queue $data->{data}->{text}" ;
}

# -----------------------------------------------------------------------------
my $dumped_counter = 0 ;

sub _dump_data2
{
    my $obj = shift ;
    my ( $queue, $data ) = @_ ;

    $dumped_counter++ ;
    # note "Dump data2 ($dumped_counter) for $queue $data->{data}->{text}" ;
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
    # diag "Testing against $dsn" ;

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
        # isa_ok( $queue, 'App::Basis::Queue' ) ;

# new should have created the various database tables, lets check if this is the case
# we know that the tables will start with $test_q and the be 'queue_names' and 'queue_info'
        my $table_name = $test_q . "_queue" ;
        my ( $ret, $err )
            = query_db( $dbh, "SELECT * from $table_name LIMIT 1;" ) ;
        ok( $ret, "Table $table_name exists" ) ;

        my $queue_list = $queue->list_queues() ;
        ok( !scalar(@$queue_list), 'No queues listed' ) ;
    } ;

# -----------------------------------------------------------------------------
# lets publish some persistent items
    subtest "publishing - with pauses" => sub {
        my $time   = time() ;
        my $totals = 0 ;

        sleep(1) ;
        $totals += _rand_pub() ;
        if ($queue->publish(
                queue   => '/pub/1',
                data    => { text => 'first persist on one' },
                persist => 1
            )
            ) {
            $totals++ ;
        }

        sleep(1) ;
        $totals += _rand_pub() ;
        if ($queue->publish(
                queue   => '/pub/1',
                data    => { text => 'second persist on one' },
                persist => 1
            )
            ) {
            $totals++ ;
        }

        sleep(1) ;
        $totals += _rand_pub() ;
        if ($queue->publish(
                queue   => '/pub/2',
                data    => { text => 'first persist on two' },
                persist => 1
            )
            ) {
            $totals++ ;
        }

        sleep(1) ;
        $totals += _rand_pub() ;
        if ($queue->publish(

                queue   => '/pub/3',
                data    => { text => 'first persist on three' },
                persist => 1
            )
            ) {
            $totals++ ;
        }

        sleep(1) ;
        $totals += _rand_pub() ;
        if ($queue->publish(
                queue   => '/pub/3',
                data    => { text => 'last persist on three' },
                persist => 1
            )
            ) {
            $totals++ ;
        }

        sleep(1) ;
        $totals += _rand_pub() ;
        if ($queue->publish(
                queue   => '/pub/1',
                data    => { text => 'last persist on one' },
                persist => 1
            )
            ) {
            $totals++ ;
        }

        # diag "subscribing, getting persistent things first" ;
        $queue->subscribe(
            queue    => '/pub/1',
            callback => \&_dump_data,
            persist  => 1
        ) ;
        $queue->subscribe(
            queue    => '/pub/2',
            callback => \&_dump_data,
            persist  => 1
        ) ;
        $queue->subscribe(
            queue    => '/pub/3',
            callback => \&_dump_data,
            persist  => 1
        ) ;
        # diag "check we have persistent events" ;
        $queue->listen(  events => 1 ) ;
        ok( $persist_counter == 3, "Got all persistent events" ) ;

        $queue->unsubscribe( queue => '/pub/1', ) ;
        $queue->unsubscribe( queue => '/pub/2', ) ;
        $queue->unsubscribe( queue => '/pub/3', ) ;

        # diag "getting $totals chatter items" ;

        $queue->subscribe(
            queue    => '/pub/*',
            callback => \&_dump_data2,
            after    => $time           # from back when this function started
        ) ;
        # diag 'listening for 2s' ;
        $queue->listen( datetime => time() + 2 ) ;
        ok( $totals == $dumped_counter, "picked up all chatter items" ) ;
    } ;

# -----------------------------------------------------------------------------

    subtest "cleanup\n" => sub {
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
