#!/usr/bin/env perl

use Data::Downloader -init_logging => "TRACE";
use strict;

$|=1;
chomp (my $username = do { print "user : "; <STDIN>; });
chomp (my $pass = do { print "pass : "; <STDIN>; });

my $omi = Data::Downloader::Repository->new(
    name           => "omi",
    storage_root   => "/usr/local/datastore/data",
    cache_strategy => "Keep",
    feeds          => [
        {
            name => "acps",
            feed_template => 'https://acps1.omisips.eosdis.nasa.gov/acpsweb/restmd/service/rssfeed/<archiveset>/<esdt>',
            file_source => {
                url_xpath      => "default:link",
                md5_xpath      => "datacasting:md5",
                filename_xpath => "datacasting:filename",
            },
            metadata_sources => [
                { name => "archivesets", xpath => "datacasting:archivesets" },
                { name => "starttime",   xpath => "datacasting:starttime"   },
                { name => "endtime",     xpath => "datacasting:endtime"     },
                { name => "esdt",        xpath => "datacasting:esdt"        },
                { name => "orbit",       xpath => "datacasting:orbit"       },
            ]
        },
    ],
    metadata_transformations => [
        {
            input         => "archivesets",
            output        => "archiveset",
            function_name => "split",
            order_key     => "1",
        },
      ],
    linktrees => [
        {
            root           => "/usr/local/datastore/tree",
            condition      => undef,
            path_template  => "<archiveset>/<esdt>/<starttime:%Y/%m/%d>",
        },
    ]

);

$omi->load(speculative => 1) or $omi->save;

for my $feed ($omi->feeds) {
    $feed->refresh(archiveset => 10003, esdt => "OMTO3", user => $username, password => $pass);
}

$omi->download_all;

1;

