#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }


use MyApp::Service::Flood;
use Time::HiRes 'time';
use Term::ReadKey;
use Getopt::Long;

ReadMode "cbreak";
END { ReadMode "restore" }

my ($opt_count, $opt_number, $opt_rate, $opt_type, $opt_size, $opt_bench, $opt_help);
my $no_args = (@ARGV == 0) ? 1 : 0;

GetOptions(
    "type=s"    => \$opt_type,     # --type
    "count=i"   => \$opt_count,    # --count
    "n=i"       => \$opt_number,   # --n
    "rate=i"    => \$opt_rate,     # --rate
    "size=i"    => \$opt_size,     # --size
    "benchmark" => \$opt_bench,    # --benchmark
    "help"      => \$opt_help,     # --help    
) or exit;

my $Help = "
Usage: flood [OPTIONS]
Flood with requests a test worker pool.

  -t, --type str   type of requests to be made (N, S, A or F)
  -c, --count N    how many requests to be made
  -r, --rate  N    sustain a rate of N requests per second
  -s, --size  N    size in KiB of requests, default is 0
  -n, --n     N    alias for --count
  -b, --benchmark  run a set of predefined benchmarks
  -h, --help       display this help and exit

Create a burst of 5000 notifications:

  flood --type N --count 5000

Create a constant load of 100 requests per second:

  flood --type S --rate 100

Run a predefined set of benchmarks:

  flood --benchmark

";

if ($opt_help || $no_args) {
    print $Help;
    exit;
}

my $client = Beekeeper::Client->instance;

if ($opt_bench) {
    # Predefined benchmarks
    print "\n";
    run_benchmarks();
}
else {
    # Flood / benchmark
    time_this(
        type  => $opt_type,
        count => $opt_count || $opt_number,
        rate  => $opt_rate,
        size  => $opt_size,
    );
}


sub time_this {

    my %args = (
        count => undef,
        rate  => undef,
        size  => undef,
        type  => undef,
        @_
    );

    my $size = $args{'size'} || 0;
    my $payload = { data => 'X' x ($size * 1024) };

    my $type = $args{'type'} || 'N';
    my $code;

    if ($type =~ m/^N(otification)?/i) {
        $type = 'notifications';
        $code = sub {
            # Measure send time
            MyApp::Service::Flood->notify( $payload );
        };
    }
    elsif ($type =~ m/^S(ync)?/i) {
        $type = 'sync calls';
        $code = sub {
            # Measure response time
            MyApp::Service::Flood->echo( $payload );
        };
    }
    elsif ($type =~ m/^A(sync)?/i) {
        $type = 'async calls';
        $code = sub {
            # Measure response time
            MyApp::Service::Flood->async_echo( $payload, sub {} );
        };
    }
    elsif ($type =~ m/^F(ire)?/i) {
        $type = 'fire & forget';
        $code = sub {
            # Measure send time only
            MyApp::Service::Flood->fire_echo( $payload );
        };
    }
    else {
        die "type must be one of (N)otification, (S)ync, (A)sync or (F)ire and forget\n";
    }

    my $count = $args{'count'};
    my $rate  = $args{'rate'};
    my $batch = $rate || $count || 1000;
    my $total = 0;

    local $| = 1;

    BENCH: {

        printf( "%s %-15s of %3s Kb  ", $batch, $type, $size );

        my $start = time();

        for (1..$batch) {
            &$code();
        }

        $total += $batch;

        if ($type eq 'async calls') {

            # Run the event loop in order to receive responses
            my $cv = AnyEvent->condvar;
            AnyEvent::postpone { $cv->send };
            $cv->recv;
        }

        my $took = time() - $start;
        my $clk = sprintf("%.3f", $took);
        my $cps = sprintf("%.0f", $batch / $took);
        my $avg = sprintf("%.2f", $took / $batch * 1000);

        if ($rate) {

            printf( "in %6s sec  %6s /sec %6s ms each", $clk, $cps, $avg );

            if ($took <= 1) {

                my $sleep = 1 - $took;
                my $cv = AnyEvent->condvar;
                AnyEvent->now_update;
                my $tmr = AnyEvent->timer( after => $sleep, cb => $cv);
                $cv->recv;
            }
            else {
                my $ovl = int(abs(($took - 1) * 100)); 
                print "   $ovl\% overload";
            }

            print "\n";

            last if $count && $total >= $count;

            my $key = ReadKey(-1);
            last if $key;

            redo BENCH;
        }
        else {

            printf( "in %6s sec  %6s /sec %6s ms each\n", $clk, $cps, $avg );
        }
    }

    if ($type eq 'async calls' && !$rate) {
        # Ensure that all responses are received before running the next benchmark
        $client->wait_async_calls;
    }
}

sub run_benchmarks {

    my $count = $opt_count || $opt_number || 1000;

    my @sizes = ( 0, 1, 5, 10 );

    # Notifications
    foreach (@sizes) {
        time_this( type => 'N', count => $count, size => $_ );
        sleep 1;
    }

    print "\n";

    # Sync calls
    foreach (@sizes) {
        time_this( type => 'S', count => $count, size => $_ );
        sleep 1;
    }

    print "\n";

    # Async calls
    foreach (@sizes) {
        time_this( type => 'A', count => $count, size => $_ );
        sleep 1;
    }

    print "\n";

    # Fire calls
    foreach (@sizes) {
        time_this( type => 'F', count => $count, size => $_ );
        sleep 1;
    }

    print "\n";
}
