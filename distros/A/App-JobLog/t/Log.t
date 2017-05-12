#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use autodie;

use File::Path qw(remove_tree);
use File::Temp ();
use App::JobLog::Config qw(log DIRECTORY);
use App::JobLog::Log::Line;
use App::JobLog::Log;
use App::JobLog::Time qw(tz);
use Capture::Tiny qw(capture);
use DateTime;
use File::Spec;
use IO::All -utf8;
use FileHandle;

use Test::More;
use Test::Fatal;

# create a working directory
my $dir = File::Temp->newdir();
$ENV{ DIRECTORY() } = $dir;

# use a constant time zone so as to avoid crafting data to fit various datelight savings time adjustments
$App::JobLog::Config::tz =
  DateTime::TimeZone->new( name => 'America/New_York' );

subtest 'empty log' => sub {
    my $log = App::JobLog::Log->new;
    my $date =
      DateTime->new( year => 2011, month => 1, day => 1, time_zone => tz );
    my $end = $date->clone->add( days => 1 )->subtract( seconds => 1 );
    is(
        exception {
            my $events = $log->find_events( $date, $end );
            ok( @$events == 0, 'no events in empty log' );
        },
        undef,
        'no error thrown with empty log',
    );
    is(
        exception {
            $log->append_event( time => $date, description => 'test event' );
            $log->close;
            my $events = $log->find_events( $date, $end );
            ok( @$events == 1, 'added event appears in empty log' );
        },
        undef,
        'added event to empty log'
    );
    $log = App::JobLog::Log->new;
    my $events = $log->find_events( $date, $end );
    ok( @$events == 1, 'event preserved after closing log' );
};

subtest 'log validation' => sub {

    # copy log data over
    my $file = File::Spec->catfile( 't', 'data', 'invalid.log' );
    my $io = io $file;
    $io > io log;
    my $log = App::JobLog::Log->new;
    my ( $stdout, $stderr ) = capture {
        $log->validate;
    };
    note $stderr;
    my $text = io(log)->slurp;
    ok( index( $text, <<END) > -1, 'found misplaced "DONE"' );
# ERROR; task end without corresponding beginning
# 2011  1  1  4 14 15:DONE
END
    ok( index( $text, <<END) > -1, 'found malformed line' );
# ERROR; malformed line
# 2011  1  1 12 47 25:malformed line
END
    ok( index( $text, <<END) > -1, 'found events out of order' );
# ERROR; dates out of order
# 2011  1  1 13 43  4::out of order
END
};

for my $size (qw(tiny small normal big)) {

    # copy log data over
    my $file = File::Spec->catfile( 't', 'data', "$size.log" );
    my $io = io $file;
    $io > io log;

    # determine which dates are present in the log
    # obtain tags and description for first and last events
    my ( @dates, %dates, $first, $last );
    while ( my $line = $io->getline ) {
        chomp $line;
        if ( $line =~ /^(\d{4})\s++(\d++)\s++(\d++)/ ) {
            my $ll = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_beginning ) {
                $first = $ll unless $first;
                $last = $ll;
            }
            my $ts = sprintf '%d/%02d/%02d', $1, $2, $3;
            unless ( $dates{$ts} ) {
                my $date = DateTime->new(
                    year      => $1,
                    month     => $2,
                    day       => $3,
                    time_zone => tz
                );
                $dates{$ts} = 1;
                push @dates, $date;
            }
        }
    }

    subtest "$size log" => sub {
        my $log = App::JobLog::Log->new;
        my ($e) = $log->first_event;
        my $ts1 = join ' ', @{ $first->tags };
        my $ts2 = join ' ', @{ $e->tags };
        is( $ts1, $ts2, "found tags of first event correctly for $size log" );
        ($e) = $log->last_event;
        $ts1 = join ' ', @{ $last->tags };
        $ts2 = join ' ', @{ $e->tags };
        is( $ts1, $ts2, "found tags of last event correctly for $size log" );
        ok( !( $last->is_beginning ^ $e->is_open ),
            "correctly determined whether last event in log is ongoing" );

        for (
            my $d = $dates[0]->clone ;
            DateTime->compare( $d, $dates[$#dates] ) <= 0 ;
            $d = $d->add( days => 1 )
          )
        {
            my $ts  = $d->strftime('%Y/%m/%d');
            my $end = $d->clone;
            $end->add( days => 1 )->subtract( seconds => 1 );
            my $events = $log->find_events( $d, $end );
            if ( $dates{$ts} ) {
                ok( @$events, "found events for $ts" );
                my $e = $events->[-1];
                if ($e) {
                    my $tags = $e->tags;
                    ok( ref $tags eq 'ARRAY', "obtained tags for $ts" );
                    if ($tags) {
                        ok( @$tags > 0, "tags found for events on $ts" );
                        is(
                            $tags->[0],
                            scalar @$events,
                            "correct number of events for $ts"
                        );
                    }
                }
                else {
                    fail("event is undefined for $ts");
                }
            }
            else {
                ok( @$events == 0, 'day absent from log contains no events' );
            }
        }
    };
}

subtest 'iterating over events in reverse' => sub {

    # copy log data over
    my $file = File::Spec->catfile( 't', 'data', 'tiny.log' );
    my $io = io $file;
    $io > io log;

    # count events
    my $fh     = FileHandle->new($file);
    my @events = <$fh>;
    @events = map { /^\d/ && $_ !~ /DONE/ ? $_ : () } @events;
    my $log   = App::JobLog::Log->new;
    my $count = 0;
    my $i     = $log->reverse_iterator;
    my @reversed_events;
    while ( my $e = $i->() ) { push @reversed_events, $e }
    ok( @events == @reversed_events, 'found all events' );

    # see if the log returns the same events in either order
    @events = reverse @{ $log->all_events };
    for ( $i = 0 ; $i < @events && $i < @reversed_events ; $i++ ) {
        my ( $e1, $e2 ) = ( $events[$i], $reversed_events[$i] );
        ok( $e1->cmp($e2) == 0, "same time for event $i" );
    }

    # see if we can iterate from an event midway in the log
    for my $index ( 0 .. $#events ) {
        $count = 0;
        $i     = $log->reverse_iterator( $events[$index] );
        while ( $i->() ) { $count++ }
        ok( $count == @events - $index,
            "found correct number of events iterating from event $index" );
    }
};

subtest 'finding notes' => sub {

    # copy log data over
    my $file = File::Spec->catfile( 't', 'data', 'notes.log' );
    my $io = io $file;
    $io > io log;

    my $log = App::JobLog::Log->new;
    my $start =
      DateTime->new( year => 2012, month => 3, day => 1, time_zone => tz );
    my $end = $start->clone->add( days => 2 )->subtract( seconds => 1 );
    my $notes = $log->find_notes( $start, $end );
    ok( @$notes == 3, 'found all notes at end of log' );
    $start = $start->subtract( days => 1 );
    $end = $start->clone->add( days => 1 )->subtract( seconds => 1 );
    $notes = $log->find_notes( $start, $end );
    ok( @$notes == 7, 'found all notes at top of log' );
    $start = $start->add( days => 1 );
    $end = $start->clone->add( days => 1 )->subtract( seconds => 1 );
    $notes = $log->find_notes( $start, $end );
    ok( @$notes == 1, 'found all notes in middle of log' );
};

done_testing();

remove_tree $dir;
