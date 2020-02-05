#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Pure;

# Object.
my $cgi = CGI::Pure->new;
$cgi->param('par1', 'val1', 'val2');
$cgi->param('par2', 'val3');
$cgi->append_param('par2', 'val4');

foreach my $param_key ($cgi->param) {
        print "Param '$param_key': ".join(' ', $cgi->param($param_key))."\n";
}

# Output:
# Param 'par2': val3 val4
# Param 'par1': val1 val2