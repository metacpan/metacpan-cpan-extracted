# $Id: 01-parse.t 1921 2006-02-28 02:50:52Z btrott $

use strict;
use Test::More tests => 81;
use Data::Feed;
use URI;

my %Feeds = (
    't/data/atom.xml' => 'Atom',
    't/data/rss10.xml' => 'RSS 1.0',
    't/data/rss20.xml' => 'RSS 2.0',
);

## First, test all of the various ways of calling parse.
my $feed;
my $file = 't/data/atom.xml';
$feed = Data::Feed->parse($file);
isa_ok($feed, 'Data::Feed::Atom');
is($feed->title, 'First Weblog');
open my $fh, $file or die "Can't open $file: $!";
$feed = Data::Feed->parse($fh);
isa_ok($feed, 'Data::Feed::Atom');
is($feed->title, 'First Weblog');
seek $fh, 0, 0;
my $xml = do { local $/; <$fh> };
$feed = Data::Feed->parse(\$xml);
isa_ok($feed, 'Data::Feed::Atom');
is($feed->title, 'First Weblog');
$feed = Data::Feed->parse(URI->new("file:$file"));
isa_ok($feed, 'Data::Feed::Atom');
is($feed->title, 'First Weblog');

## Then try calling all of the unified API methods.
for my $file (sort keys %Feeds) {
    my $feed = Data::Feed->parse($file) or die Data::Feed->errstr;
    my($subclass) = $Feeds{$file} =~ /^(\w+)/;
    isa_ok($feed, 'Data::Feed::' . $subclass);
    is($feed->format, $Feeds{$file});
    is($feed->language, 'en-us');
    is($feed->title, 'First Weblog');
    is($feed->link, 'http://localhost/weblog/');
    is($feed->tagline, 'This is a test weblog.');
    is($feed->description, 'This is a test weblog.');
    my $dt = $feed->modified;
    isa_ok($dt, 'DateTime');
    $dt->set_time_zone('UTC');
    is($dt->iso8601, '2004-05-30T07:39:57');
    is($feed->author, 'Melody');
    is($feed->icon, $Feeds{$file} eq 'Atom' ? '/favicon.ico' : undef);
    is($feed->base, $Feeds{$file} eq 'RSS 1.0' ? undef : 'http://hey.com/');

    my @entries = $feed->entries;
    is(scalar @entries, 2);
    my $entry = $entries[0];
    is($entry->title, 'Entry Two');
    is($entry->link, 'http://localhost/weblog/2004/05/entry_two.html');
    $dt = $entry->issued;
    isa_ok($dt, 'DateTime');
    $dt->set_time_zone('UTC');
    is($dt->iso8601, '2004-05-30T07:39:25');
    like($entry->content->body, qr/<p>Hello!<\/p>/);
    is($entry->summary->body, 'Hello!...');
    is(($entry->category)[0], 'Travel');
    is($entry->category, 'Travel');
    is($entry->author, 'Melody');
    ok($entry->id);
}

$feed = Data::Feed->parse('t/data/rss20-no-summary.xml')
    or die Data::Feed->errstr;
my $entry = ($feed->entries)[0];
ok(!$entry->summary->body);
like($entry->content->body, qr/<p>This is a test.<\/p>/);

$feed = Data::Feed->parse('t/data/rss10-invalid-date.xml')
    or die Data::Feed->errstr;
$entry = ($feed->entries)[0];
ok(!$entry->issued);   ## Should return undef, but not die.
ok(!$entry->modified); ## Same.
