#!perl

use strict;
use warnings;

use Test::More tests => 1;

use_ok 'Dancer::Plugin::Memcached';

diag '';

unless ($ENV{D_P_M_SERVER})
{
    diag 'To complete all tests, have a spare memcached server and set ';
    diag 'the environment variable D_P_M_SERVER to its IP address and port.';
}
else
{
    diag 'Testing against memcached at '.$ENV{D_P_M_SERVER};
}
