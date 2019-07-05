#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 06-storage-client.t 121 2019-07-01 19:51:50Z abalama $
#
#########################################################################
use Test::More;
use App::MBUtiny::Collector::DBI qw/COLLECTOR_DB_FILENAME/;
use App::MBUtiny::Storage::HTTP;
use Sys::Hostname;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d '.git';

my $client = new App::MBUtiny::Storage::HTTP::Client(
        url     => "http://test:test\@localhost/mbuserver", # Base URL
        timeout => 15, # default: 180
        verbose => 1, # Show req/res data
    );

plan skip_all => sprintf("Can't initialize the client: %s", $client->error)
    unless $client->status;
plan skip_all => sprintf("Server not running or not configured: %s", $client->error)
    unless $client->check;
#note(explain($client));

# Start testing
plan tests => 9;

my $host = "foo";
my $host_suffix = sprintf("%s/%s", hostname(), $host);
my $testfilename = COLLECTOR_DB_FILENAME;
my $size = -e $testfilename ? -s $testfilename : 0;
my $status = 1;

# Upload file
{
    ok($client->upload(file => $testfilename, name => $testfilename, path => $host_suffix), "Upload test file") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
}
#note($client->trace);

# Get file list (as string)
{
    my $list = $client->filelist(path => $host_suffix); #, host => $host
    ok($client->status, "Get file list (as string)") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
    note($list);
}

# Get file list (as array)
{
    my @list = $client->filelist(path => $host_suffix); #, host => $host
    ok($client->status, "Get file list (as array)") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
    note(explain(\@list));
}

# Get info
my $after_size = 0;
{
    my %info = $client->fileinfo(name => $testfilename, path => $host_suffix);
    ok($client->status, "Get file info") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
    $after_size = $info{size} || 0;
    ok($after_size, "Info is correct");
    is($after_size, $size, "File sizes are the same");
    note(explain(\%info));
}

# Download file
my $download_size = 0;
{
    ok($client->download(file => "downloaded.tmp", name => $testfilename, path => $host_suffix), "Download test file") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
    if (my $res = $client->res) {
        $download_size = $res->content_length || 0
    }
    is($after_size, $download_size, "File sizes are the same (uploaded=downloaded)");
    #note($client->trace);
    #note($client->transaction);
}

# Delete file
{
    ok($client->remove(name => $testfilename, path => $host_suffix), "Delete test file") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
}

# General info
unless ($status) {
    my $res = $client->res;
    note(explain({
        status => $client->status ? "OK" : "ERROR",
        error  => $client->error,
        code => $res ? $res->code : undef,
        line => $res ? $res->status_line : undef,
        message => $res ? $res->message : undef,
        transaction => $client->transaction,
    }));
}

1;

__END__
