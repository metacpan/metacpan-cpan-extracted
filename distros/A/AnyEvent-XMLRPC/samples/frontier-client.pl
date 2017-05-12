#!/usr/bin/perl
use Frontier::Client;
use Data::Dumper;

$server = Frontier::Client->new( 'url' => 'http://localhost:9090/RPC2' );
my @args = qw(aaa bbb ccc);
$result = $server->call("echo", @args);

print Dumper $result;