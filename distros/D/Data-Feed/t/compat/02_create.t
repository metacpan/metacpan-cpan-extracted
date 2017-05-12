# $Id$

use strict;
use Test::More tests => 73;
use Data::Feed;
use DateTime;

for my $format (qw( Atom RSS )) {
    my $feed_class = "Data::Feed::$format";
    Any::Moose::load_class $feed_class;

    my $feed = $feed_class->new();

    isa_ok($feed, $feed_class);
    like($feed->format, qr/^$format/, "[$format] Format is correct");

    $feed->title('My Feed');
    is($feed->title, 'My Feed', "[$format] Feed title is correct");

    $feed->link('http://www.example.com/');
    is($feed->link, 'http://www.example.com/', "[$format] Feed link is correct");
    $feed->description('Wow!');
    is($feed->description, 'Wow!', "[$format] Feed description is correct");
    is($feed->tagline, 'Wow!', "[$format] Tagline works as alias");

    $feed->tagline('Again');
    is($feed->tagline, 'Again', "[$format] Setting via tagline works");

    $feed->language('en_US');
    is($feed->language, 'en_US', "[$format] Feed language is correct");

    $feed->author('Ben');
    is($feed->author, 'Ben', "[$format] feed author is correct");

    $feed->copyright('Copyright 2005 Me');
    is($feed->copyright, 'Copyright 2005 Me', "[$format] Feed copyright is correct");

    $feed->icon('/favicon.ico');
    is($feed->icon, '/favicon.ico', "[$format] Feed icon is correct");

    $feed->base('http://foo.com');
    is($feed->base, 'http://foo.com', "[$format] Feed base is correct");

    my $now = DateTime->now;
    $feed->modified($now);
    isa_ok($feed->modified, 'DateTime', "[$format] Modified returns a DateTime");
    is($feed->modified->iso8601, $now->iso8601, "[$format] Feed modified is correct");

    $feed->generator('Movable Type');
    is($feed->generator, 'Movable Type', "[$format] Feed generator is correct");

    ok($feed->as_xml, 'as_xml returns something');

    my $entry_class = "${feed_class}::Entry";
    Any::Moose::load_class $entry_class;

    my $entry = $entry_class->new();
    isa_ok($entry, $entry_class);
    $entry->title('Foo Bar');
    is($entry->title, 'Foo Bar', "[$format] Entry title is correct");
    $entry->link('http://www.example.com/foo/bar.html');
    is($entry->link, 'http://www.example.com/foo/bar.html', "[$format] Entry link is correct");
    $entry->summary('This is a summary.');
    isa_ok($entry->summary, 'Data::Feed::Web::Content');
    is($entry->summary->body, 'This is a summary.', "[$format] Entry summary is correct");
    $entry->content('This is the content.');
    isa_ok($entry->content, 'Data::Feed::Web::Content');
    is($entry->content->type, 'text/html', "[$format] Entry content type is correct");
    is($entry->content->body, 'This is the content.', "[$format] Entry content body is correct");

    $entry->content(Data::Feed::Web::Content->new({
            body => 'This is the content (again).',
            type => 'text/plain',
    }));
    isa_ok($entry->content, 'Data::Feed::Web::Content');
    is($entry->content->body, 'This is the content (again).', 'setting with Data::Feed::Content works');
    $entry->category('Television');
    is($entry->category, 'Television', "[$format] Entry category is correct");
    $entry->author('Foo Baz');
    is($entry->author, 'Foo Baz', "[$format] Entry author is correct");
    $entry->id('foo:bar-15132');
    is($entry->id, 'foo:bar-15132', "[$format] Entry id is correct");
    my $dt = DateTime->now;
    $entry->issued($dt);
    isa_ok($entry->issued, 'DateTime');
    is($entry->issued->iso8601, $dt->iso8601, "[$format] Entry issued is correct");
    $entry->modified($dt);
    isa_ok($entry->modified, 'DateTime');
    is($entry->modified->iso8601, $dt->iso8601, "[$format] Entry modified is correct");

    $feed->add_entry($entry);
    my @e = $feed->entries;
    is(scalar @e, 1, 'One post in the feed');
    is($e[0]->title, 'Foo Bar', 'Correct post');
    is($e[0]->content->body, 'This is the content (again).', 'content is still correct');

    if ($format eq 'Atom') {
        like $feed->as_xml, qr/This is the content/;
    }
}
