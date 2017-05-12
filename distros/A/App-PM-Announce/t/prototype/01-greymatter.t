#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use App::PM::Announce;
my $app = App::PM::Announce->new;
my $feed = App::PM::Announce::Feed::greymatter->new(
    app => $app,
    username => 'alice8378',
    password => 'test8378',
    uri => 'http://72.14.179.195/cgi-bin/greymatter/gm.cgi',
);
my $key = int rand $$;
$feed->announce(
    title => "Event title ($key)",
    description => "Event description ($key)",
);

ok(1);

__END__
use WWW::Mechanize;
use HTTP::Request::Common qw/POST/;

my $agent = WWW::Mechanize->new;

#$agent->request(
#    POST "http://sf.pm.org/cgi-bin/greymatter/gm.cgi", {

$agent->request(
    POST "http://72.14.179.195/cgi-bin/greymatter/gm.cgi", {
        authorname => 'alice8378',
        authorpassword => 'test8378',
        newentrysubject => 'Hello, World (' . int( rand $$ ) . ')',
        newentrymaintext => 'Lorem ipsum (' . int( rand $$ ) . ')',
        newentrymoretext => '',
        newentryallowkarma => 'no',
        newentryallowcomments => 'no',
        newentrystayattop => 'no',
        thomas => 'Add This Entry',
    },
);

$agent->get("http://72.14.179.195/cgi-bin/greymatter/gm.cgi?authorname=alice8378&authorpassword=test8378&thomas=rebuildupdate&rebuilding=everything&rebuildfrom=1&connectednumber=");

ok(1);

# s*p*g***t
