#!/usr/bin/env perl

use Data::Downloader -init_logging => "DEBUG";
use strict;

# Get images stored by md5, symlinked by date and tag
my $images = Data::Downloader::Repository->new(
    name           => "images",
    storage_root   => "/usr/local/datastore/data",
    cache_strategy => "Keep",
    feeds          => [
        {
            name => "flickr",
            feed_template => 'http://api.flickr.com/services/feeds/photos_public.gne?tags=<tags>&lang=en-us&format=rss_200',
            file_source => {
                url_xpath      => 'media:content/@url',
                filename_xpath => 'media:content/@url',
                filename_regex => '/([^/]*)$',
            },
            metadata_sources => [
                { name => 'date_taken', xpath => 'dc:date.Taken' },
                { name => 'tags',       xpath => 'media:category' },
            ],
        },
    ],
    metadata_transformations => [
        {
            input         => "tags",
            output        => "tag",
            function_name => "split",
        },
    ],
    linktrees => [
        {
            root          => "/usr/local/datastore/by_tag",
            condition     => undef,
            path_template => "<tag>"
        },
        {
            root          => "/usr/local/datastore/by_date",
            condition     => undef,
            path_template => "<date_taken:%Y/%m/%d>"
        },
    ],
);

$images->load(speculative => 1) or $images->save;

for my $feed ($images->feeds) {
    $feed->refresh(tags => "apples");
}

$images->download_all;

1;

