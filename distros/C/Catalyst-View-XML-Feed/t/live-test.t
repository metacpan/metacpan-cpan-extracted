#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use XML::Feed;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN { use_ok 'TestApp'; }

# a live test against TestApp, the test application
use Catalyst::Test 'TestApp';

like(get('/'), qr/it works/i, 'main page has our text');


subtest 'custom_formats' => sub {
    for my $action (qw(
        string
        feed_obj_entries_arrayref_objs__rss
        feed_obj_array_entries_array_objs__rss
        feed_hash_entries_objs__rss feed_hash_entries_objs__atom
        feed_hash_entries_hashes__rss
        ))
    {
        test_action($action);
    }
};

subtest 'xml_feed' => sub {
    for my $action (qw(
        xml_feed__atom xml_feed__rss xml_feed__rss09
        xml_feed__rss1 xml_feed__rss2
        ))
    {
        test_action($action);
    }
};

subtest 'xml_rss' => sub {
    eval { require XML::RSS; };
    plan(skip_all => 'XML::RSS not installed') if $@;
    for my $action (qw(xml_rss))
    {
        test_action($action);
    }
};

subtest 'xml_atom_simplefeed' => sub {
    eval { require XML::Atom::SimpleFeed; };
    plan(skip_all => 'XML::Atom::SimpleFeed not installed') if $@;
    for my $action (qw(xml_atom_simplefeed))
    {
        test_action($action);
    }
};

subtest 'xml_atom_feed' => sub {
    eval { require XML::Atom::Feed; };
    plan(skip_all => 'XML::Atom::Feed not installed') if $@;
    for my $action (qw(xml_atom_feed))
    {
        test_action($action);
    }
};

sub test_action {
    my ($action) = @_;

    my $res = request('/' . $action);
    my $content = $res->content;

    cmp_ok($res->code, 'eq', 200, "/$action code is 200");

    my $ct = 'text/xml';
    if ($action =~ /rss/) {
        $ct = 'application/rss\+xml';
    } elsif ($action =~ /atom/) {
        $ct = 'application/atom\+xml';
    }
    like($res->header('Content-Type'), qr/$ct/, "/$action has correct Content-Type ($ct)");

    like($content, qr/my awesome site/i, "/$action has 'my awesome site'");
    like($content, qr/my first post/i, "/$action has 'my first post'");

    SKIP: {
        skip "No author or description expected for RSS 0.9", 2
            if $content =~ m!http://my.netscape.com/rdf/simple/0.9/!i;
        like($content, qr/it works/i, "/$action has 'it works'");
        like($content, qr/Mark A\. Stratman/i, "/$action has 'Mark A. Stratman'");
    }
}

done_testing;
