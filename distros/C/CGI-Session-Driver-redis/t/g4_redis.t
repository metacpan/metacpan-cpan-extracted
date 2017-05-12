#!/usr/bin/perl

use strict;
use diagnostics;
use Test::More;
use IO::Socket::INET;
use FindBin qw($Bin);
use Redis;
use lib "$Bin/../lib";

my $server = '127.0.0.1:6379';

my $sock = IO::Socket::INET->new( PeerAddr => $server,
                                  Timeout  => 2, );
if ( !$sock )
{
    plan( skip_all => "No redis server running upon localhost\n" );
    exit 0;
}

eval "require Redis_";
unless ($@)
{
    plan( skip_all => "Redis is NOT available" );
    exit 0;
}

use CGI::Session::Test::Default;
my $redis = Redis->new( server => $server, debug => 0 );

my $TEST_KEY = '__cgi_session_driver_redis';
$redis->set( $TEST_KEY, 1 );
unless ( defined $redis->get($TEST_KEY) )
{
    plan( skip_all => "redis server is NOT available" );
    exit 0;
}

my $t = CGI::Session::Test::Default->new( dsn  => "dr:redis",
                                          args => { Redis => $redis } );

plan tests => $t->number_of_tests;
$t->run();
