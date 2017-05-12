#!/usr/bin/perl

use lib './';
use TestApp;

$ENV{PATH_INFO} = $ARGV[0];

my $app = TestApp->new();
$app->run();
