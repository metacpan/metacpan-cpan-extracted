#! /usr/bin/perl

use strict;
use warnings;
use lib qw(../lib ./userLib);
use CGI::MiniFramework;

my $f = CGI::MiniFramework->new(
    PREFIX       => 'App',
    DEFAULT      => 'Index',
    DEFAULT_MODE => 'index',
);

print $f->run();

