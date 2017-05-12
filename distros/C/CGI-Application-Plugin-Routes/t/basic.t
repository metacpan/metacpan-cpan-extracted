#! /usr/bin/perl -w
use Test::More 'no_plan';
use strict;
use lib 't/';
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1; 
$ENV{PATH_INFO} = '/view/mark/76/mark@stosberg.com';

my $out = TestApp->new->run;
like($out,qr/done$/,'expected output'); 







