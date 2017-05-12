#!/usr/bin/perl -w

require './CBAuth.pm';
my $app = CGI::Builder::Auth::Example::CBAuth->new();
$app->process();
