use strict;
use warnings;
use Find::Lib '../lib';
use AnyEvent::Superfeedr;
use Encode;

die "$0 <jid> <pass>" unless @ARGV >= 2;

binmode STDOUT, ":utf8";

my $end = AnyEvent->condvar;
my $sf = AnyEvent::Superfeedr->new(
    jid => shift,
    password => shift,
    on_notification => sub { 
        my $notification = shift;
        printf "Fetched '%s' %s [status=%s], next at %s\n",
            $notification->title,
            $notification->feed_uri,
            $notification->http_status,
            $notification->next_fetch;
    },
);
$sf->connect;
$end->recv;
