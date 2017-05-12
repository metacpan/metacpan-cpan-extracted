#!/usr/bin/perl 

use strict;
use warnings;

use CGI ':standard';

BEGIN { $SIG{INT} = 'IGNORE'; }

$SIG{INT} = 'IGNORE';

print header(-charset => 'utf-8');
