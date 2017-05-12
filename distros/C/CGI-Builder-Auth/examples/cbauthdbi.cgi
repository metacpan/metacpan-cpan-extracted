#!/usr/bin/perl -w
require './CBAuthDBI.pm';
my $app = CGI::Builder::Auth::Example::CBAuthDBI->new();
$app->process();
