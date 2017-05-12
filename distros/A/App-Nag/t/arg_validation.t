#!/usr/bin/perl

use Modern::Perl;
use App::Nag;
use DateTime;
use DateTime::TimeZone;

use Test::More;
use Test::Fatal;

# this all could be cleaned up a bit

my (
    $opt,      $usage,   $name, $verbosity, $text,
    $synopsis, $seconds, $time, $true_seconds
);
local @ARGV;

subtest '1s delta' => sub {
    @ARGV = qw(1s this is the text);
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $verbosity == 1, 'right verbosity' );
    ok( $seconds == 1,   '1s' );
};

subtest '1h delta' => sub {
    @ARGV = qw(--slap 1h this is the text);
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $verbosity == 3,     'right verbosity --slap' );
    ok( $seconds == 60 * 60, '1h' );
};

subtest '1H delta' => sub {
    @ARGV = qw(--slap 1H this is the text);
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $verbosity == 3,     'right verbosity --slap' );
    ok( $seconds == 60 * 60, '1h' );
};

my $tz = DateTime::TimeZone->new( name => 'local' );

subtest '10am' => sub {
    $time         = '10am';
    $true_seconds = get_time( 10, 0, 'am' );
    @ARGV         = ( $time, qw(this is the text) );
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $seconds == $true_seconds, "time: $time" );
};

subtest '10AM' => sub {
    $time         = '10AM';
    $true_seconds = get_time( 10, 0, 'am' );
    @ARGV         = ( $time, qw(this is the text) );
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $seconds == $true_seconds, "time: $time" );
};

subtest '10A.M.' => sub {
    $time         = '10A.M.';
    $true_seconds = get_time( 10, 0, 'am' );
    @ARGV         = ( $time, qw(this is the text) );
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $seconds == $true_seconds, "time: $time" );
};

subtest 'plain 10' => sub {
    $time         = '10';
    $true_seconds = get_time( 10, 0 );
    @ARGV         = ( $time, qw(this is the text) );
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $seconds == $true_seconds, "time: $time" );
};

subtest '13:24' => sub {
    $time         = '13:24';
    $true_seconds = get_time( 13, 24 );
    @ARGV         = ( $time, qw(this is the text) );
    ( $opt, $usage, $name ) = App::Nag->validate_args;
    ( $verbosity, $text, $synopsis, $seconds ) =
      App::Nag->validate_time( $opt, $usage, @ARGV );
    ok( $seconds == $true_seconds, "time: $time" );
};

subtest 'exceptions' => sub {
    isnt(
        exception {
            $time = '13:24am';
            @ARGV = ( $time, qw(this is the text) );
            ( $opt, $usage, $name ) = App::Nag->validate_args;
            App::Nag->validate_time( $opt, $usage, @ARGV );
        },
        undef,
        "can't parse 13:24am"
    );
    isnt(
        exception {
            $time = '10G';
            @ARGV = ( $time, qw(this is the text) );
            ( $opt, $usage, $name ) = App::Nag->validate_args;
            App::Nag->validate_time( $opt, $usage, @ARGV );
        },
        undef,
        "can't parse 10G"
    );
    isnt(
        exception {
            $time = '11:60';
            @ARGV = ( $time, qw(this is the text) );
            ( $opt, $usage, $name ) = App::Nag->validate_args;
            App::Nag->validate_time( $opt, $usage, @ARGV );
        },
        undef,
        "can't parse 11:60"
    );
    isnt(
        exception {
            $time = '24pm';
            @ARGV = ( $time, qw(this is the text) );
            ( $opt, $usage, $name ) = App::Nag->validate_args;
            App::Nag->validate_time( $opt, $usage, @ARGV );
        },
        undef,
        "can't parse 24pm"
    );
};

done_testing();

# construct a test time
sub get_time {
    my ( $hours, $minutes, $suffix ) = @_;
    my $now = DateTime->now( time_zone => $tz );
    my $then = $now->clone->set(
        hour   => $hours,
        minute => $minutes,
        second => 0
    );
    if ( $hours < 13 ) {
        $then->add( hours => 12 ) while $then < $now;
        given ( $suffix || '' ) {
            when ('am') { $then->add( hours => 12 ) if $then->hour >= 12 }
            when ('pm') { $then->add( hours => 12 ) if $then->hour < 12 }
        }
    }
    else {
        $then->add( days => 1 ) if $then < $now;
    }
    return $then->epoch - $now->epoch;
}
