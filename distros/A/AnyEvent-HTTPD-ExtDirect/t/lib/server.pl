#!perl

use lib 't/lib';
use RPC::ExtDirect::Test::Foo;
use RPC::ExtDirect::Test::Bar;

use AnyEvent::HTTPD::ExtDirect;

my $httpd = AnyEvent::HTTPD::ExtDirect->new( port => 8080 );

$httpd->run();

