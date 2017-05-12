#!/usr/bin/perl -w
use lib '/var/www/cgi-bin/Test';
use Test;
$t = Test->new() ;
$t->process() ;
