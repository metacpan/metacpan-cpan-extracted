#!/usr/bin/perl
#this file here just to shut up 'make test' errors 
use strict;
use Test;
use lib '../blib/lib';
use CGI::Widget::Series;

BEGIN { plan tests => 1 }

my $series = CGI::Widget::Series->new(-length=>1,-render=>sub{return 1});
ok($series);
1;
