#!/usr/bin/perl

use Test::Most tests => 31;
use Test::NoWarnings;

use Time::Local;
use App::TimelogTxt::Event;

dies_ok { App::TimelogTxt::Event->new_from_line() } "new_from_line dies with no argument.";
dies_ok { App::TimelogTxt::Event->new_from_line( 'This is not an event' ) } "new_from_line dies with bad argument.";

my $REFERENCE_TIME = Time::Local::timelocal( 2, 0, 10, 5, 5, 113 );
{
    my $label = 'Canonical event, line';
    my $line = '2013-06-05 10:00:02 +proj1 do something';
    my $event = App::TimelogTxt::Event->new_from_line( $line );
    isa_ok( $event, 'App::TimelogTxt::Event' );
    is( $event->stamp, '2013-06-05', "$label: stamp correct" );
    is( $event->project, 'proj1', "$label: project correct" );
    is( $event->task, '+proj1 do something', "$label: task correct" );
    is( $event->epoch, $REFERENCE_TIME, "$label: epoch correct" );
    is( $event->to_string, $line, "$label: string correct" );
    ok( !$event->is_stop, "$label: is not a stop event" );
}

{
    my $label = 'Canonical event, time';
    my $event = App::TimelogTxt::Event->new( '+proj1 do something', $REFERENCE_TIME );
    isa_ok( $event, 'App::TimelogTxt::Event' );
    is( $event->stamp, '2013-06-05', "$label: stamp correct" );
    is( $event->project, 'proj1', "$label: project correct" );
    is( $event->task, '+proj1 do something', "$label: task correct" );
    is( $event->epoch, $REFERENCE_TIME, "$label: epoch correct" );
    is( $event->to_string, '2013-06-05 10:00:02 +proj1 do something', "$label: string correct" );
    ok( !$event->is_stop, "$label: is not a stop event" );
}

{
    my $label = 'stop event, line';
    my $line = '2013-06-05 10:00:02 stop';
    my $event = App::TimelogTxt::Event->new_from_line( $line );
    isa_ok( $event, 'App::TimelogTxt::Event' );
    is( $event->stamp, '2013-06-05', "$label: stamp correct" );
    is( $event->project, undef, "$label: project correct" );
    is( $event->task, 'stop', "$label: task correct" );
    is( $event->epoch, $REFERENCE_TIME, "$label: epoch correct" );
    is( $event->to_string, $line, "$label: string correct" );
    ok( $event->is_stop, "$label: is a stop event" );
}

{
    my $label = 'stop event, time';
    my $event = App::TimelogTxt::Event->new( 'stop', $REFERENCE_TIME );
    isa_ok( $event, 'App::TimelogTxt::Event' );
    is( $event->stamp, '2013-06-05', "$label: stamp correct" );
    is( $event->project, undef, "$label: project correct" );
    is( $event->task, 'stop', "$label: task correct" );
    is( $event->epoch, $REFERENCE_TIME, "$label: epoch correct" );
    is( $event->to_string, '2013-06-05 10:00:02 stop', "$label: string correct" );
    ok( $event->is_stop, "$label: is a stop event" );
}
