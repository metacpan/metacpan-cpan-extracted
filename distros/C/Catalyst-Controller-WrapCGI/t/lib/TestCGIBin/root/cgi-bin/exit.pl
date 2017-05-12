#!/usr/bin/perl

use strict;
use warnings;

use CGI ':standard';

print header(-charset => 'utf-8');
print "hello " . param('name');
exit(param('exit') || 0);
