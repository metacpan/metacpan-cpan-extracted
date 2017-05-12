#!/usr/bin/perl 

use strict;
use warnings;

use CGI ':standard';

print header(-charset => 'utf-8');
print do { local $/; <DATA> };

__DATA__
testing
