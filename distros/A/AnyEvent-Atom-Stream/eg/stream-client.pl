#!/usr/bin/perl
use strict;
use AnyEvent::Atom::Stream;

my $url = "http://updates.sixapart.com/atom-stream.xml";
my $cv  = AnyEvent->condvar;

# API is compatible to XML::Atom::Stream
binmode STDOUT, ":utf8";

my $client = AnyEvent::Atom::Stream->new(
    callback  => sub {
        my $feed = shift;
        for my $entry ($feed->entries) {
            print $entry->title .
                ($feed->author ? " (by " . $feed->author->name . ")" : '') . "\n",
                    "  ", $entry->link->href, "\n";
            print "  (body: ", length($entry->content->body), " bytes)\n";
        }
    },
    timeout   => 30,
    on_disconnect => $cv,
);

my $guard = $client->connect($url);

$cv->recv;
