#!/usr/bin/perl

# ABSTRACT: generates data for testing (recursive, since uses some of modules to test; best to eyeball data)

use Modern::Perl;
use File::Temp ();
use App::JobLog::Config qw(log DIRECTORY);
use App::JobLog::Time qw(tz);
use App::JobLog::Log::Line;
use App::JobLog::Log;
use DateTime;
use IO::All -utf8;
use String::Random qw(random_string);

use constant MAX_LENGTH => 24 * 60 * 60 / 4;    # quarter of a day

my ( $length, $destination ) = @ARGV;

# create a working directory
my $dir = File::Temp->newdir();
$ENV{ DIRECTORY() } = $dir;
my $log = App::JobLog::Log->new;

my $time = DateTime->new(
    year      => 2011,
    month     => 1,
    day       => 1,
    hour      => 1,
    minute    => 0,
    second    => 0,
    time_zone => tz,
);

# create log lines
my ( @lines, %counts );
my $was_done  = 1;
my $ts        = '';
my $last_good = 1;
for ( my $i = 0 ; 1 ; $i++ ) {
    given (rand) {
        when ( $_ < .01 ) {

            # random blank line
            my $ll = App::JobLog::Log::Line->new( text => '' );
            push @lines, $ll;
        }
        when ( $_ < .02 ) {

            # random comment
            my $ll = App::JobLog::Log::Line->new( comment => random_text() );
            push @lines, $ll;
        }
        default {
            my $clone = $time->clone;
            $clone->add( seconds => int rand MAX_LENGTH );
            if ( $last_good && $was_done && rand() < 3 / 7 ) {
                $clone->add( days => int rand 3 );
            }
            my $ts2 = $clone->strftime('%Y/%m/%d');
            my $is_done = !$was_done && rand() > .8;
            $was_done ||=
              $time->hour == 23 && $time->minute == 59 && $time->second == 59;
            if ( $ts ne $ts2 ) {
                $i++;
                $counts{$ts2}++ unless $was_done;
            }
            $counts{$ts2}++ unless $is_done;
            $last_good = $counts{$ts2} > 1 || !$is_done;
            my $ll = App::JobLog::Log::Line->new(
                time => $clone,
                $is_done
                ? ( done => 1 )
                : ( tags => [], description => random_text() )
            );
            push @lines, $ll;
            $time     = $clone;
            $ts       = $ts2;
            $was_done = $is_done;
        }
    }
    last if $i >= $length && $last_good;
}

# create log
for my $line (@lines) {
    if ( $line->is_beginning ) {
        my $count = $counts{ $line->time->strftime('%Y/%m/%d') };
        push @{ $line->tags }, $count;
    }
    $log->append_event($line);
}
$log->close;
io(log) > io($destination);

# random quasi-words
sub random_text {
    my @words;
    for ( 1 .. int rand 12 ) {
        my $patt = '.' x ( 1 + int rand 12 );
        push @words, random_string($patt);
    }
    my $text = join( ' ', @words );
    $text =~ s/\\/\\\\/g;
    $text =~ s/;/rand() > .5 ? '\\;' : ';'/eg;
    return $text;
}
