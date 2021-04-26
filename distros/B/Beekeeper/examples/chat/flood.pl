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
  -r, --rate    N  sustain a rate of N requests per second
  -s, --size    N  size in KB of requests, default is 0
  -h, --help       display this help and exit

To create a 100 clients sending in total 1000 messages per second to each other:

  flood -c 100 -r 1000

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

print "$num_bots clients connected, sending $msg_sec messages per second (press any key to stop)\n";
$| = 1; # autoflush progress dots

while (1) {

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

    my $wait = 1 - (time() - $start_on);
    if ($wait < 0) {
        my $ovl = int(abs($wait * 100)); 
        print "Cannot handle $msg_sec messages per second ($ovl\% overload)\n";
        next;
    }

    my $cv = AnyEvent->condvar;
    my $tmr = AnyEvent->timer( after => 1, cb => $cv);
    $cv->recv;

    print '.';

    my $key = ReadKey(-1);
    if ($key) {
        print "\n";
        last;
    }
}

1;
