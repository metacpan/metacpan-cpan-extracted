#!/usr/bin/perl
# 01-add-feeds.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More;
BEGIN { 
    plan skip_all => "Set TEST_LIVE environment variable to run live tests." 
        unless $ENV{TEST_LIVE};
    plan tests => 10;
    use_ok('Catalyst::Model::XML::Feed'); 
}

my $model = Catalyst::Model::XML::Feed->new;
ok($model, 'created model');

eval {
    $model->register('delicious', 'http://feeds.delicious.com/v2/rss/');
};
ok(!$@, 'no error registering delicious feed');
is(scalar $model->get_all_feeds, 1, 'one feed added');

my @jrock_feeds;
eval {
    @jrock_feeds = $model->register('http://blog.jrock.us/');
};
ok(!$@, 'no error registering jrock.us feeds');
ok(scalar $model->get_all_feeds > 1, 'added some more feeds');

eval {
    $model->refresh;
};
ok(!$@, 'no problems refreshing feeds');

eval {
    $model->refresh('NotAFeed122333444455555');
};
ok($@, 'problem refreshing fake feed');

my $delicious = $model->get('delicious');
isa_ok($delicious, 'XML::Feed', 'delicious is a feed');
like($delicious->title, qr/del[.]?icio[.]?us/, 'delicious is del.icio.us');
