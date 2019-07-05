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
# $Id: 05-collector-client.t 121 2019-07-01 19:51:50Z abalama $
#
#########################################################################
use Test::More;
use App::MBUtiny::Collector::Client;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d '.git';

my $client = new App::MBUtiny::Collector::Client(
        url     => "http://test:test\@localhost/mbutiny", # Base URL
        timeout => 5, # default: 180
        verbose => 1, # Show req/res data
    );

plan skip_all => sprintf("Can't initialize the client: %s", $client->error)
    unless $client->status;
my $out = $client->check;
#note(explain($out));
plan skip_all => sprintf("Server not running or not configured: %s", $client->error)
    unless $client->status;
#note(explain($client));

# Start testing
plan tests => 6;

# Test data
my %info = (
    type => 1,
    name => "test",
    file => "test-fake-file.tar.gz",
    size => 123,
    md5  => "3a5fb8a1e0564eed5a6f5c4389ec5fa0",
    sha1 => "22d12324fa2256e275761b55d5c063b8d9fc3b95",
    status => 1,
    error => "",
    comment => "Test external fixup"
);
my $status = 1;

# Add file
{
    ok($client->add(%info), "Add test file") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
}

# Get file list
{
    my @list = $client->list(name => $info{name});
    ok($client->status, "Get file list") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
    ok(@list, "List is correct");
    #note(explain([@list]));
}

# Get info
{
    my %srv_info = $client->get(name => $info{name}, file => $info{file});
    ok($client->status, "Get file info") or do {
        diag($client->error);
        note($client->transaction);
        note($client->trace);
        $status = 0;
    };
    ok(%srv_info && $srv_info{file} eq $info{file}, "Info is correct");
    #note(explain(\%srv_info));
}

# Delete file
{
    ok($client->del(%info), "Delete test file") or do {
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
