#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }


use Beekeeper::Client;
use Time::HiRes qw( time sleep );
use Getopt::Long;

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
  -s, --size  N    size in KB of requests, default is 0
  -n, --n     N    alias for --count
  -b, --benchmark  run a set of predefined benchmarks
  -h, --help       display this help and exit

To create a burst of 5000 notifications:

  flood --type N --count 5000

To create a constant load of 100 requests per second:

  flood --type S --rate 100

Run a predefined set of benchmarks

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
    my @async_calls;
    my $code;

    if ($type =~ m/^N(otification)?/i) {
        $type = 'notifications';
        $code = sub {
            $client->send_notification(
                method => 'myapp.test.flood', 
                params => $payload,
            );
        };
    }
    elsif ($type =~ m/^S(ync)?/i) {
        $type = 'sync calls';
        $code = sub {
            $client->call_remote(
                method => 'myapp.test.echo', 
                params => $payload,
            );
        };
    }
    elsif ($type =~ m/^A(sync)?/i) {
        $type = 'async calls';
        $code = sub {
            push @async_calls, $client->call_remote_async(
                method => 'myapp.test.echo', 
                params => $payload,
            );
        };
    }
    elsif ($type =~ m/^F(ire)?/i) {
        $type = 'fire & forget';
        $code = sub {
            $client->fire_remote(
                method => 'myapp.test.echo', 
                params => $payload,
            );
        };
    }
    else {
        die "type must be one of (N)otification, (S)ync, (A)sync or (F)ire and forget\n";
    }

    my $rate = $args{'rate'} ? (1 / $args{'rate'}) : 0;
    my $max_count = $args{'count'} || ($rate ? -1 : 1000);

    my $quit;

    if ($rate) {
        print "Press ctrl-C to stop\n";
        $SIG{'INT'} = sub { $quit = 1; print "\b\b"; };
    }

    local $| = 1;
    printf( "%s %-15s of %3s Kb  ", $max_count, $type, $size ) if (!$rate);

    my $count = 0;
    my $start = time();
    my $next = $start;
    my $sleept = 0;
    my $sleep;

    while (1) {

        &$code();

        $count++;

        last if ($quit || $count == $max_count);

        if ($rate) {
            $next += $rate;
            $sleep = $next - time();
            if ($sleep > 0) {
                $sleept += $sleep;
                sleep($sleep);
            }
        }
    }

    if ($type eq 'async call') {
        $client->wait_async_calls;
        @async_calls = ();
    }

    my $ellapsed = time() - $start - $sleept;
    my $took = sprintf("%.3f", $ellapsed);
    my $tps = sprintf("%.0f", $count / $ellapsed);
    my $avg = sprintf("%.2f", $ellapsed / $count * 1000);

    printf( "%s %-15s of %3s Kb  ", $count, $type, $size ) if ($rate);
    printf( "in %6s sec  %6s /sec %6s ms each\n", $took, $tps, $avg );
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
