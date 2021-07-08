#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }

use MyApp::Bot;
use Time::HiRes 'time';
use Term::ReadKey;
use Getopt::Long;

ReadMode "cbreak";
END { ReadMode "restore" }

my ($opt_clients, $opt_rate, $opt_size, $opt_help);
my $no_args = (@ARGV == 0) ? 1 : 0;

GetOptions(
    "clients=i" => \$opt_clients,  # --clients
    "rate=i"    => \$opt_rate,     # --rate
    "size=i"    => \$opt_size,     # --size
    "help"      => \$opt_help,     # --help    
) or exit;

my $Help = "
Usage: flood [OPTIONS]
Create a lot of clients who flood with messages each other.

  -c, --clients N  number of client connections to use
  -r, --rate    N  sustain a rate of N requests per second among all clients
  -s, --size    N  size in KiB of requests, default is 0
  -h, --help       display this help and exit

To create a 100 clients sending in total 500 messages per second to each other:

  flood -c 100 -r 500

";

if ($opt_help || $no_args) {
    print $Help;
    exit;
}

my $num_bots = $opt_clients || 50;
my $msg_sec  = $opt_rate    || 100;
my $msg_size = $opt_size    || 0;

my @Bots;
my $DEBUG = 0;

foreach my $n (1..$num_bots) {

    my $username = sprintf("bot-%.3d", $n);

    push @Bots, MyApp::Bot->new(
        username   => $username,
        on_message => sub {
            my (%args) = @_;
            return unless $DEBUG;
            my $message = $args{'message'};
            my $from = $args{'from'} ? "$args{from}:" : ">";
            print "$from $message\n";
        },
    );
}

print "$num_bots clients are sending $msg_sec requests per second.\n";
print "Workers are handling $msg_sec calls per second.\n";
print "Routers are handling " . ($msg_sec * 2) . " messages per second.\n";
print "(press any key to stop)\n";
$| = 1; # autoflush progress dots

while (1) {

    print '.';

    my $start_on = time();

    for (1..$msg_sec) {

        my $bot_A = $Bots[rand($num_bots)];
        my $bot_B = $Bots[rand($num_bots)];

        my $msg = $msg_size ? 'X' x ($msg_size * 1024) : 'Hello ' . $bot_B->username;

        $bot_A->talk(
            to_user => $bot_B->username,
            message => $msg,
        );
    }

    my $cv = AnyEvent->condvar;
    AnyEvent::postpone { $cv->send };
    $cv->recv;

    my $key = ReadKey(-1);
    if ($key) {
        print "\n";
        last;
    }

    my $took = time() - $start_on;
    if ($took > 1) {
        my $ovl = int(abs(($took - 1) * 100)); 
        print "Cannot sustain $msg_sec msg/s ($ovl\% overload)\n";
        next;
    }

    my $wait = 1 - $took;
    $cv = AnyEvent->condvar;
    AnyEvent->now_update;
    my $tmr = AnyEvent->timer( after => $wait, cb => $cv);
    $cv->recv;
}

1;
