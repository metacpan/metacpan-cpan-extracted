#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader -init_logging => "FATAL";
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;
use t::lib::functions;


my $test_dir = scratch_dir();
# diag "storing tree in $test_dir";

my $LIVE_TESTS
    = ($ENV{DATA_DOWNLOADER_LIVE_TESTS} || $ENV{DD_LIVE_TESTS}) ? 1 : 0;

my $flickr = Data::Downloader::Repository->new(
    name              => "flickr",
    storage_root      => "$test_dir/store",
    cache_strategy    => "LRU",
    cache_max_size    => ($LIVE_TESTS ? 20*1024*1024 : 1024*20),
    file_url_template => 
       "http://farm4.static.flickr.com/<url1>/<url2>_<size>.<format>",
    metadata_transformations => [
				 { input           => "tags",
				   output          => "one_tag",
				   function_name   => "split",
				   order_key       => 1 },
				 { input           => "one_tag", 
				   output          => "tag",
				   function_name   => "match", 
				   function_params => "a", 
				   order_key       => 2 },
				 ],
    linktrees => [
		  { root          => "$test_dir/linktree_by_tag",
		    condition     => undef,
		    path_template => "<tag>" },
		  { root          => "$test_dir/linktree_default",
		    condition     => undef,
		    path_template => "<date_taken:%Y/%m/%d>" },
		  ],
    feeds => {
        name             => "flickr_rss",
        feed_template    => 'http://api.flickr.com/services/feeds/'
	    . 'photos_public.gne?tags=<tags>&lang=en-us&format=rss_200',
        file_source      => {
            url_xpath      => 'media:content/@url',
            filename_xpath => 'media:content/@url',
            filename_regex => '/([^/]*)$',
            # no md5_xpath
        },
        metadata_sources => [
            { name => 'date_taken', xpath => 'dc:date.Taken'  },
            { name => 'tags',       xpath => 'media:category' },
        ],
    }
);

ok($flickr->save, "Saved repository") or BAIL_OUT $flickr->error;

ok(my $db = $flickr->init_db, "Initialize DB") or BAIL_OUT $flickr->error;

Data::Downloader::MetadataPivot->rebuild_pivot_view;

diag "getting live feed" if ($LIVE_TESTS);
$flickr->feeds->[0]->refresh(
    tags => 'apples',
    ($LIVE_TESTS ?  () : (from_file => "$Bin/sample_rss/flickr_apples.xml")),
);

my @fake;
unless ($LIVE_TESTS) {
    @fake = (fake => 1);
    # diag "set DATA_DOWNLOADER_LIVE_TESTS=1 to connect to live servers";
}

$flickr->download_all(@fake);

for my $file ($flickr->files) {
    $file->load; # TODO, shouldn't be necessary?
    if ($file->on_disk) {
        for my $symlink ($file->symlinks) {
            ok(-e $symlink->linkname, 
	       "made link to file ".$file->filename." at ".$symlink->linkname);
        }
    } else {
        my @links = $file->symlinks;
        ok(@links==0, "no symlinks for file not on disk : ".$file->filename);
    }
    ok($file->check, "checked file ".$file->filename);
}

ok(test_cleanup($test_dir, $db), "Test clean up");

1;


