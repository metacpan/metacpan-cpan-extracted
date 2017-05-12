use strict;
use warnings;
use Find::Lib '../lib';
use AnyEvent::Superfeedr;
use Encode;

die "$0 <jid> <pass>" unless @ARGV >= 2;

binmode STDOUT, ":utf8";

my $end = AnyEvent->condvar;
my $sf = AnyEvent::Superfeedr->new(
    debug => $ENV{DEBUG},
    jid => shift,
    password => shift,
    # bogus for my tests
    #subscription => {
    #    interval => 5,
    #    sub_cb => sub { [ "firehoser.superfeedr.com" ] },
    #    unsub_cb => sub { [ "", undef, '""', "*" ] },
    #},
    on_notification => sub { 
        my $notification = shift;
        warn $notification->as_xml;
        printf "%s: %s\n", $notification->title, $notification->feed_uri;

        for my $entry ($notification->entries) {
            my $title = Encode::decode_utf8($entry->title); 
            $title =~ s/\s+/ /gs;

            my $l = length $title;
            my $max = 50;
            if ($l > $max) {
                substr $title, $max - 3, $l - $max + 3, '...';
            }
            printf "~ %-50s\n", $title;
        }
    },
);
$sf->connect;
$end->recv;
