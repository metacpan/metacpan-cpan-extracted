#!/usr/bin/perl
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Errno qw(ENOENT);
use File::Temp qw/ :mktemp tempdir /;
use Test::More;
use Time::HiRes qw(usleep);

use lib 't/lib';
use forker;

#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Data::RecordStore::Silo;

my $is_root = `whoami` =~ /root/;

# -----------------------------------------------------
#               init
# -----------------------------------------------------

test_init();
test_use();
test_async();
done_testing;

exit( 0 );

sub failnice {
    my( $subr, $errm, $msg ) = @_;
    eval {
        $subr->();
        fail( $msg );
    };
    like( $@, qr/$errm/, "$msg error" );
    undef $@;
}

sub test_init {
    my $dir = tempdir( CLEANUP => 1 );
    my $size = 2 ** 10;
    my $silo = Data::RecordStore::Silo->open_silo( $dir, 'LZ*', $size );
    ok( $silo, "Got a silo" );
    my $new_silo = Data::RecordStore::Silo->open_silo( $dir, 'LZ*', $size );
    ok( $new_silo, "able to renit already inited silo with same params" );

    failnice( sub { Data::RecordStore::Silo->open_silo( $dir, 'LZ*' ) },
              "no record size given to open silo",
              "was able to reinit silo withthout specifying record size" );
    failnice( sub { Data::RecordStore::Silo->open_silo( $dir, undef, 100 ) },
              "must supply template to open silo",
              "was able to reinit silo withthout specifying template" );

    failnice( sub { Data::RecordStore::Silo->open_silo() },
              "must supply directory to open silo",
              "was able to reinit silo withthout specifying dir" );

    $dir = tempdir( CLEANUP => 1 );

    failnice( sub { Data::RecordStore::Silo->open_silo( $dir, 'LLL', 800 ) },
              'do not match',
              'template size and given size do not match' );
    
    
    $silo = Data::RecordStore::Silo->open_silo( $dir, 'LLL' );
    is( $silo->template, 'LLL', 'given template matches' );

    $silo = Data::RecordStore::Silo->reopen_silo( $dir );
    is( $silo->template, 'LLL', 'given template matches for reopened silo' );
    
    is( $silo->max_file_size, 2_000_000_000, "silo is default max size" );
    is( $silo->record_size, 12, "silo has 32 bytes per record" );
    is( $silo->records_per_subsilo, 166_666_666, "166,666,666 records per file" );

    if( ! $is_root ) {
        $dir = tempdir( CLEANUP => 1 );
        chmod 0444, $dir;
        my $cantdir = "$dir/cant";
        failnice( sub { Data::RecordStore::Silo->open_silo( $cantdir, 'LL' ) },
                  "Permission denied",
                  'was able to init a silo in an unwritable directory' );
     }
    $Data::RecordStore::Silo::DEFAULT_MAX_FILE_SIZE = 2_000_000_000;
} #test_init

sub test_use {
    my $dir = tempdir( CLEANUP => 1 );
    my $size = 2 ** 10;
    my $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size, $size * 10, );
    is( $silo->size, 0, 'nothing in the silo, no size' );
    is( $silo->entry_count, 0, 'nothing in the silo, no entries' );
    is_deeply( [$silo->subsilos], [0], 'one subsilo upon creation' );

    is( $silo->pop, undef, "nothing to pop" );
    is( $silo->peek, undef, "nothing to peek" );

    is( $silo->size, 0, 'nothing in the silo, no size still' );
    is( $silo->entry_count, 0, 'nothing in the silo, no entries still' );
    is_deeply( [$silo->subsilos], [0], 'one subsilo upon creation still' );
    
    $silo->ensure_entry_count( 1 );
    is( $silo->size, $size, 'silo now with one record. correct size' );
    is( $silo->entry_count, 1, 'silo now with one record. correct count' );
    failnice( sub { $silo->get_record(0) },
              'index 0 out of bounds',
              "got a record zero" );
    failnice( sub { $silo->get_record(2) },
              'index 2 out of bound',
              "got a record two" );
    is_deeply( $silo->get_record( 1 ), [''], 'empty record' );
    is_deeply( $silo->peek, [''], "empty peek" );

    $silo->pop;
    is( $silo->size, 0, 'nothing in the silo, no size after pop' );
    is( $silo->entry_count, 0, 'nothing in the silo, no entries after pop' );
    is_deeply( [$silo->subsilos], [0], 'one subsilo upon creation after pop' );
    $silo->ensure_entry_count( 1 );

    
    is( $silo->next_id, 2, "next id" );

    is( $silo->size, 2*$size, 'silo now with two. correct size' );
    is( $silo->entry_count, 2, 'silo now with two. correct count' );

    $silo->ensure_entry_count( 12 );
    is( $silo->size, 12*$size, 'silo now with 12. correct size' );
    is( $silo->entry_count, 12, 'silo now with 12. correct count' );
    is_deeply( [$silo->subsilos], [0,1], 'one subsilo upon creation' );

    is_deeply( $silo->pop, [''], 'empty popped record' );
    is( $silo->size, 11*$size, 'silo now with 11. correct size after pop one' );
    is( $silo->entry_count, 11, 'silo now with 11. correct count after pop one' );
    is_deeply( [$silo->subsilos], [0, 1], 'same subsilos after pop one' );
    
    is_deeply( $silo->pop, [''], 'empty popped record' );
    is( $silo->size, 10*$size, 'silo back to 10. correct size ' );
    is( $silo->entry_count, 10, 'silo back to 10. correct count' );
    is_deeply( [$silo->subsilos], [0], 'one less subsilo after pop two' );

    $silo->ensure_entry_count( 40 );
    is( $silo->size, 40*$size, 'silo to 40. correct size ' );
    is( $silo->entry_count, 40, 'silo to 40. correct count' );
    is_deeply( [$silo->subsilos], [0,1,2,3], 'four subsilos after 40 entries' );

    $silo->ensure_entry_count( 30 );
    is( $silo->size, 40*$size, 'silo still 40. correct size ' );
    is( $silo->entry_count, 40, 'silo still 40. correct count' );
    is_deeply( [$silo->subsilos], [0,1,2,3], 'four subsilos still 40 entries' );

    ok( $silo->put_record( 10, ["BLBLBLBLBLBL"] ), "put a record" );
    is( $silo->size, 40*$size, 'silo still 40. correct size after put' );
    is( $silo->entry_count, 40, 'silo still 40. correct count after put' );
    is_deeply( [$silo->subsilos], [0,1,2,3], 'four subsilos still 40 entries after put' );

    is_deeply( $silo->get_record( 10 ), [ "BLBLBLBLBLBL" ], "record was created" );
    is_deeply( $silo->get_record( 9 ), [''], "empty 9" );
    is_deeply( $silo->get_record( 11 ), [''], "empty 11" );

    is( $silo->push( "UUUUUUUU" ), 41, "pushed with id 41" );
    is( $silo->size, 41*$size, 'silo pushed to 41. correct size after put' );
    is( $silo->entry_count, 41, 'silo pushed to 41. correct count' );
    is_deeply( [$silo->subsilos], [0,1,2,3,4], 'five subsilos for 41 entries' );
    
    is_deeply( $silo->peek, [ 'UUUUUUUU' ], 'last pushed record' );
    is_deeply( $silo->pop, [ 'UUUUUUUU' ], 'last pushed record' );

    is( $silo->size, 40*$size, 'silo still 40. correct size after pop' );
    is( $silo->entry_count, 40, 'silo still 40. correct count after pop' );
    is_deeply( [$silo->subsilos], [0,1,2,3], 'four subsilos still 40 entries after pop' );

    eval {
        $silo->put_record( 41, "WRONG" );
        fail( 'was able to put record beyond end of bounds' );
    };
    like( $@, qr/out of bounds/, 'error message for put past entries' );
    
    eval {
        $silo->put_record( 0, "WRONG" );
        fail( 'was able to put record with index of 0' );
    };
    like( $@, qr/out of bounds/, 'error message for zero index' );
    
    eval {
        $silo->put_record( -1, "WRONG" );
        fail( 'was able to put record with index < 0' );
    };
    like( $@, qr/out of bounds/, 'error message for wrong index' );

    eval {
        $silo->put_record( 5, "WRONG".('x'x$size) );
        fail( 'was able to put record too big' );
    };
    like( $@, qr/too large/, 'error message for too big data' );

    unless( $is_root ) {
        $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size, $size * 10 );
        chmod 0000, "$dir";
        eval {
            $silo->subsilos;
            fail( "Was able to access subsilos despite dark directory" );
        };
        like( $@, qr/can't open/, 'error msg for dark dir' );
        chmod 0777, "$dir";
        is_deeply( [$silo->subsilos], [ 0, 1,2,3], "still four subsilos after reopen" );

        chmod 0444, "$dir/3";
        eval {
            $silo->peek;
        };
        like( $@, qr/Unable to open|Permission denied/, 'error msg for readonly file' );

        chmod 0777, "$dir/3";

        $silo->put_record(40,'LAST');
        is_deeply( $silo->peek, ['LAST'], 'last is last' );
        
        $silo->put_record(1,'FIRST');
        is_deeply( $silo->get_record(1), ['FIRST'], 'first is first' );

        $silo->put_record(1,'FIR');
        is_deeply( $silo->get_record(1), ['FIR'], 'fir is first' );
        
        $silo->put_record(1,'FIRST');
        is_deeply( $silo->get_record(1), ['FIRST'], 'first is again first' );
        
        $silo->put_record(1,'');
        is_deeply( $silo->get_record(1), [''], 'empty is first' );
        
        $silo->put_record(1,'F');
        is_deeply( $silo->get_record(1), ['F'], 'f is first' );

        
        $silo->empty_silo;
        is_deeply( [$silo->peek], [undef], 'nothing to peek at after empty silo' );
        is_deeply( [$silo->subsilos], [ 0], "empty only has first subsilo " );

        open my $fh, '>', "$dir/3";
        print $fh '';
        close $fh;
        eval {
            $silo->ensure_entry_count( 40 );
            fail( 'able to ensure count with wacky extra subsilo hanging out' );
        };
        open $fh, '>', "$dir/2";
        print $fh '';
        close $fh;
        eval {
            $silo->ensure_entry_count( 40 );
            fail( 'able to ensure count with wacky extra subsilos hanging out' );
        };

        $silo->empty_silo;
        chmod 0444, "$dir/0";
        eval {
            $silo->ensure_entry_count( 3 );
            fail( 'able to ensure count with unwriteable fi9rst' );
        };
        
    }

    $silo->unlink_silo;

    eval {
        is_deeply( [$silo->subsilos], [], "no subsilos after unlink silo" );
        fail( 'was able to call subsilos on this destroyed silo' );
    };


    $dir = tempdir( CLEANUP => 1 );
    $size = 2 ** 10;
    $silo = Data::RecordStore::Silo->open_silo( $dir, 'LIZ*', $size, $size * 10 );
    my $id = $silo->next_id;
    is_deeply( $silo->get_record(1), [0,0,''], 'starting with nothing' );
    $silo->put_record( $id, [12,8,"FOOFOO"] );
    is_deeply( $silo->get_record(1), [12,8,'FOOFOO'], 'starting with 12, FOOFOO' );
    $silo->put_record( $id, [42], 'L' );
    is_deeply( $silo->get_record(1), [42,8,'FOOFOO'], 'starting with FOOFOO but adjusted 12 --> 42 ' );
    is_deeply( $silo->get_record(1,'L'), [42], 'just the 42 ' );

    $silo->put_record( $id, [333], 'I', 4 );
    is_deeply( $silo->get_record(1), [42,333,'FOOFOO'], 'starting with FOOFOO but adjusted 8 --> 333 ' );
    is_deeply( $silo->get_record(1, 'L', 0 ), [42], 'picking out 333 ' );
    is_deeply( $silo->get_record(1, 'I', 4 ), [333], 'picking out  333 ' );

    $dir = tempdir( CLEANUP => 1 );
    $size = 2 ** 10;
    $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size );
    $id = $silo->push( "BARFY" );
    is_deeply( $silo->get_record($id), ['BARFY'], 'got record after single item on' );
    $silo->put_record( $id, "BARFYYY", "Z*" );
    is_deeply( $silo->get_record($id), ['BARFYYY'], 'got record after single item on with put record' );
    $silo->put_record( $id, ["BARFYYYZ"], "Z*" );
    is_deeply( $silo->get_record($id), ['BARFYYYZ'], 'got record after array item plus template on with put record' );

    is_deeply( $silo->get_record($id,"Z*"), [''], 'star template doesnt work with get_record. must use size ' );
    is_deeply( $silo->get_record($id,4), ['BARF'], 'use size rather than template for get_record ' );

    $dir = tempdir( CLEANUP => 1 );
    $silo = Data::RecordStore::Silo->open_silo( $dir, 'LIL' );
    $silo->push( [234,4,6654] );
    is_deeply( $silo->get_record( 1, 'LI' ), [234,4], 'get front part' );
    is_deeply( $silo->get_record( 1, 'I', 4 ), [4], 'get second' );

    
    $Data::RecordStore::Silo::DEFAULT_MAX_FILE_SIZE = 2_000_000_000;

    # test copy numbers
    $dir = tempdir( CLEANUP => 1 );
    $silo = Data::RecordStore::Silo->open_silo( $dir, 'LL' );
    $silo->push( [ 3, 56 ] );
    $id = $silo->next_id;
    $silo->copy_record( 1, 2 );
    is_deeply( $silo->get_record(2), [3,56], 'copied numbers' );
    
    
    # test copy
    $dir = tempdir( CLEANUP => 1 );
    $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', 2 ** 12 );
    $silo->push( "SOMETHING EXCELLENT" );
    failnice( sub { $silo->copy_record( 1, 0 ) },
              'out of bounds',
              'copy to zero dest' );
    failnice( sub { $silo->copy_record( 0, 1 ) },
              'out of bounds',
              'copy from zero source' );
    failnice( sub { $silo->copy_record( 3, 1 ) },
              'out of bounds',
              'copy from too big source' );
    failnice( sub { $silo->copy_record( 1, 3 ) },
              'out of bounds',
              'copy to too big dest' );
    $id = $silo->next_id;
    is_deeply( $silo->get_record(2), [''], 'nothing for new next id' );
    $silo->copy_record( 1, 2 );
    is_deeply( $silo->get_record(2), ['SOMETHING EXCELLENT'], 'copy worked for new id' );
    is_deeply( $silo->get_record(1), ['SOMETHING EXCELLENT'], 'original still there' );
} #test_use

sub test_async {
    
    my $dir = tempdir( CLEANUP => 1 );
    my $forker = forker->new( $dir );
    my $size = 2 ** 10;
    my $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size );
    
    $forker->init();

    my $A = fork;    
    unless( $A ) {
        $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size );
        $forker->expect( '1' );
        usleep( 5000 );
        my $id = $silo->next_id;
        $forker->put( "ID A $id" );
        exit;
    }

    my $B = fork;    
    unless( $B ) {
        $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size );
        $forker->spush( '1' );
        $forker->expect( "ID A 1" );
        my $id = $silo->push( "SOUPS" );
        $forker->put( "ID B 2" );
        exit;
    }

    my $C = fork;    
    unless( $C ) {
        $silo = Data::RecordStore::Silo->open_silo( $dir, 'Z*', $size );
        $forker->spush( '1' );
        $forker->spush( "ID A 1" );
        $forker->expect( "ID B 2" );
        my $val = $silo->get_record( 2 );
        $forker->put( "VAL $val->[0]" );
        exit;
    }
    $forker->put( '1' );
    
    waitpid $A, 0;
    waitpid $B, 0;
    waitpid $C, 0;

    is_deeply( $forker->get, [ '1', 'ID A 1' , 'ID B 2', 'VAL SOUPS' ], "correct order for things" );

    
} #test_async
