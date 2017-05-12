use strict;
use Test::More ( tests => 21 );

BEGIN {
    use_ok("Data::Feed");
    use_ok("Data::Feed::Atom");
}
use DateTime;

my $now = DateTime->now();

my $feed = Data::Feed::Atom->new();
$feed->title("foo");
$feed->description("Atom 1.0 feed");
$feed->link("http://example.org/");
$feed->id("tag:cpan.org;xml-feed-atom");
$feed->icon('/favicon.ico');
$feed->base('http://yo.com/');
$feed->updated($now);

my $entry = Data::Feed::Atom::Entry->new();
$entry->title("1st Entry");
$entry->link("http://example.org/");
$entry->category("blah");
$entry->content("<p>Hello world.</p>");
$entry->id("tag:cpan.org;xml-feed-atom-entry");
$entry->updated($now);

$feed->add_entry($entry);

my $xml = $feed->as_xml;
TODO: {
    todo_skip("fix me", 1);
    like $xml, qr!<feed xmlns="http://www.w3.org/2005/Atom"!;
}
like $xml, qr!<content .*type="xhtml">!;
like $xml, qr!<div xmlns="http://www.w3.org/1999/xhtml">!;

# roundtrip
$feed = Data::Feed->parse(\$xml);
is $feed->format, 'Atom';
is $feed->title, "foo";
is $feed->description, "Atom 1.0 feed";
is $feed->link, "http://example.org/";
is $feed->id, "tag:cpan.org;xml-feed-atom";
is "".$feed->updated, "".$now;
is $feed->icon, '/favicon.ico';
is $feed->base, 'http://yo.com/';

my @entries = $feed->entries;
is @entries, 1;
$entry = $entries[0];

is $entry->title, '1st Entry';
is $entry->link, 'http://example.org/';
is $entry->category, 'blah';
is $entry->content->type, 'text/html';
like $entry->content->body, qr!\s*<p>Hello world.</p>\s*!s;

is $entry->id, "tag:cpan.org;xml-feed-atom-entry";
is "".$entry->updated, "".$now;


