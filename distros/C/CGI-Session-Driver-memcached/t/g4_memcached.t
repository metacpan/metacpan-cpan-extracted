#!/usr/bin/perl

use strict;
use diagnostics;
use Test::More;
use IO::Socket::INET;
use FindBin qw($Bin);
use lib "$Bin/../lib";

my $server = '127.0.0.1:11211';
my @servers = ();
if (exists $ENV{CGISESS_MEMCACHED_SERVERS}) {
    @servers = split ' ', $ENV{CGISESS_MEMCACHED_SERVERS};
}
else {
    @servers = ($server);
}

for my $s (@servers) {
    my $sock = IO::Socket::INET->new(
        PeerAddr => $s,
        Timeout => 2,
    );
    if (!$sock) {
        plan(skip_all => "No memcached instance running at $s\n");
        exit 0;
    }
}

my $client = '';
for (qw(Cache::Memcached Cache::Memcached::Fast)) {
    eval "require $_";
    unless ($@) {
        $client = $_;
    }
}
unless ($client) {
    plan(skip_all => "Cache::Memcached or Cache::Memcached::Fast is NOT available");
    exit 0;
}

use CGI::Session::Test::Default;
my $memcached = $client->new({
    servers => \@servers,
    debug   => 1,
});

my $TEST_KEY = '__cgi_session_driver_memcached';
$memcached->set($TEST_KEY, 1);
unless (defined $memcached->get($TEST_KEY)) {
    plan(skip_all=>"memcached server is NOT available");
    exit 0;
}

my $t = CGI::Session::Test::Default->new(
    dsn => "dr:memcached",
    args=> { Memcached => $memcached }
);

plan tests => $t->number_of_tests;
$t->run();
