# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

$|=1;

use Test::More tests => 2;

use_ok('CGI::Carp::Fatals');

$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';

my $output = `$^X t/crash.cgi`;

ok($output =~ /Environment/i,"INFO_VARIABLES worked");

delete $ENV{GATEWAY_INTERFACE};

