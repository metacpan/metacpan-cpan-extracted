#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CrawlerCommons::RobotRulesParser' ) || print "Bail out!\n";
}

diag( "Testing CrawlerCommons::RobotRulesParser $CrawlerCommons::RobotRulesParser::VERSION, Perl $], $^X" );
