#!perl

use Test::More qw/no_plan/;
use FindBin qw/$Bin/;
use t::lib::functions;
use Data::Downloader -init_logging => "FATAL";
use YAML::XS qw/Dump/;
use strict;
use warnings;

# Parse a feed referred to on datacasting.jpl.nasa.gov

my $test_dir = scratch_dir();

my $LIVE_TESTS
    = ($ENV{DATA_DOWNLOADER_LIVE_TESTS} || $ENV{DD_LIVE_TESTS}) ? 1 : 0;

my $spec = {
    name              => "airs",
    storage_root      => "$test_dir/store",
    cache_strategy    => "LRU",
    cache_max_size    =>  20*1024*1024,
    linktrees => [
		  { root          => "$test_dir/linktree_default",
		    condition     => undef,
		    path_template => "<starttime:%Y/%m/%d>" },
		  ],
    feeds => {
        name             => "airx2ret_nrt",
        feed_template    => 'http://example.com/feed.xml',
        file_source      => {
            url_xpath      => 'enclosure/@url',
            filename_xpath => 'title',
        },
        metadata_sources => [
            { name => 'starttime', xpath => 'datacasting:customElement[@name="validity_start_time"]/@value' },
            { name => 'endtime', xpath => 'datacasting:customElement[@name="validity_end_time"]/@value' },
        ],
    }
};

my $repo = Data::Downloader::Repository->new(%$spec);

ok($repo->save, "Saved repository") or BAIL_OUT $repo->error;

ok(my $db = $repo->init_db, "Initialize DB") or BAIL_OUT $repo->error;

Data::Downloader::MetadataPivot->rebuild_pivot_view;

diag "getting live feed" if ($LIVE_TESTS);
$repo->feeds->[0]->refresh(
    ($LIVE_TESTS ?  () : (from_file => "$Bin/sample_rss/gsics.xml")),
);

my @fake;
unless ($LIVE_TESTS) {
    @fake = (fake => 1);
    # diag "set DATA_DOWNLOADER_LIVE_TESTS=1 to connect to live servers";
}

$repo->download_all(@fake);

for my $file ($repo->files) {
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


