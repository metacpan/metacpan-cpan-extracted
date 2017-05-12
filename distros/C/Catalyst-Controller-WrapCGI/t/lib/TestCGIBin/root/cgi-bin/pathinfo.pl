#!/usr/bin/perl 

use strict;
use warnings;

use CGI ':standard';

print header(-charset => 'utf-8');
print $ENV{PATH_INFO};
