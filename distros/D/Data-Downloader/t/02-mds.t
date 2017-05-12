#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;
use t::lib::functions;

Log::Log4perl->get_logger("")->level("DEBUG");

sub _find_files {
    my @where = @_;
    return map { -d $_ ? _find_files(glob "$_/*") : -e $_ ? $_ : () } @where;
}

my $test_dir = scratch_dir();
# diag "storing tree in $test_dir";

# Metadata server
my $mds = Data::Downloader::Repository->new(
    name              => "mds",
    storage_root      => "$test_dir/store",
    cache_strategy    => "LRU",
    cache_max_size    => 1024,
    file_url_template => "http://example.com/data/<md5>/<filename>",
    disks             => [ map +{ root => "disk$_/"}, (1..100) ],
    metadata_transformations => [ 
                  { input           => "archivesets",
                    output          => "one_archiveset",
                    function_name   => "split",
                    order_key       => "1", },
                  { input           => "one_archiveset",
                    output          => "archiveset",
                    function_name   => "match",
                    function_params => "10003|70003",
                    order_key       => "2", },
                  ],
    feeds => {
        name          => "georss",
        feed_template => 'https://example.com/'
        . 'service/georss?esdt=<esdt>&startdate=<startdate:%Y-%m-%d>'
        . '&as=<archiveset>&count=<count>&email=<email>'
        . '&password=<password>&met=0',
        feed_parameters => [
            { name => "email",    default_value => "" },
            { name => "password", default_value => "" },
        ],
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
    linktrees => [
        {
            root           => "$test_dir/linktree_default",
            condition      => undef,
            path_template  => "<archiveset>/<esdt>/<starttime:%Y/%m/%d>",
        },
        {
            root           => "$test_dir/linktree_OMT03",
            condition      => q/{ esdt => "OMTO3" }/,
            path_template  => "<archiveset>/<esdt>/<starttime:%Y>",
        },
        {
            root           => "$test_dir/by_orbit",
            condition      => q/{ orbit => 18000 }/,
            path_template  => "<orbit>"
        }
    ],
);

ok($mds->save, "Saved repository");

is($mds->name, "mds", "set repository name");
is($mds->feeds->[0]->name, "georss", "set feed name");
ok($mds->feeds->[0]->repository, "repository for feed was set")
    or diag "You may need to run t/01-clean-db.t";

ok(my $db = $mds->init_db, "Initialize DB") or BAIL_OUT $mds->error;

# create invalid objects
{
    my $feed = Data::Downloader::Feed->new( feed_template => "xxx" );
    ok(!$feed->save, 
       "Can't save because name was null (db error may be above)");
    like($feed->error, qr/may not be null/i, "got an error message");
}

SKIP: {
    skip "Unset DATA_DOWNLOADER_BULK_DOWNLOAD to run integrity check", 1 
    if ($ENV{DATA_DOWNLOADER_BULK_DOWNLOAD});
    my $md_source = Data::Downloader::MetadataSource->new( feed => 9999,
                               name => "invalid" );
    ok(!$md_source->save,
       "referential integrity check (db error may be above)");
}

my @from_file;
my @fake;
@from_file = (from_file  => "$Bin/sample_rss/omisips.xml");
@fake = ( fake => 1 );

$mds->feeds->[0]->refresh(
    startdate  => "2004-04-15",
    archiveset => "10003",
    count      => 5,
    esdt       => "OMTO3",
    @from_file,
);

$mds->download_all(@fake);

$_->rebuild for ($mds->linktrees);

for my $file (
    @{ Data::Downloader::File::Manager->get_files(
            [ orbit => '18000' ],
            with_objects => ['file_metadata'] )
    }
  ) {
    $file->download unless($file->on_disk);
    ok(-e "$test_dir/by_orbit/18000/".$file->filename, 
       "found downloaded file: ".$file->filename);
}

#
# dado tests
#

# dado files orbit=18000 makelinks
# rebuild the symlinks for all files with orbit=18000
for (@{ Data::Downloader::File::Manager->get_files(
           [ orbit => '18000' ],
           with_objects => ['file_metadata']) }) {
    # diag "updating links for file ".$_->filename;
    $_->makelinks;
}

# dado files on_disk=1 makelinks
# Make symlinks for all files
$_->makelinks for @{ Data::Downloader::File::Manager->get_files([on_disk => 1]) };

# Get an omi file fiven an md5 + filename (without using an rss feed)
# dado downloadfile repository=omi,\
#   md5=a46cee6a6d8df570b0ca977b9e8c3097,\
#   filename=OMI-Aura_L2-OMTO3_2007m0220t0052-o13831_v002-2007m0220t221310.he5
#
my $file = Data::Downloader::File->new(
    md5        => "a46cee6a6d8df570b0ca977b9e8c3097",
    filename   => "OMI-Aura_L2-OMTO3_2007m0220t0052-o13831_v002-2007m0220t221310.he5",
    repository => Data::Downloader::Repository->new( name => "mds" )->load->id,
);
my $got = $file->download(@fake);
ok($got, "downloaded ".$file->filename);
ok(ref($got) eq 'Data::Downloader::File', "download() returned an object");

for my $linktree (@{ Data::Downloader::Linktree::Manager->get_linktrees }) {
    # diag "rebuilding link tree in ".$linktree->root;
    $linktree->rebuild;
    next unless -d $linktree->root; # no files matched the criteria
    my @found = _find_files($linktree->root);
    ok @found > 1, "Found some files in ".$linktree->root;

}

my $filename = $file->storage_path;
ok(-e $filename,     "$filename is on disk");
$file->remove;
ok(!-e $filename,    "Removed $filename"   );
ok(!$file->on_disk,  "file is not on disk" );
ok(!$file->disk,     "file has no disk"    );
ok(!$file->disk_obj, "file has no disk_obj");
$file->download(fake => 1);
my $new_path = $file->storage_path;
ok(-e $new_path,     "$new_path is on disk");

ok(test_cleanup($test_dir, $db), "Test clean up");

1;

