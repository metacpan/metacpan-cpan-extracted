#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use AnyEvent;
use AnyEvent::JSONRPC;

my ($host, $port) = qw(127.0.0.1 4423);
GetOptions(
  "host=s" => \$host,
  "port=s" => \$port,
) or die "Can't parse options";

my $server = jsonrpc_server $host, $port;

$server->reg_cb(

    echo => sub {
        my ($cb, @params) = @_;

        $cb->result( @params );
    },

    date => sub {
        my ($cb) = @_;

        $cb->result( scalar localtime );
    },

    error => sub {
        my ($cb, $message) = @_;

        $cb->error( message => $message );
    },

);

AnyEvent->condvar->recv();


