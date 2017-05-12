#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure;

# Object.
my $query_string = 'par1=val1;par1=val2;par2=value';
my $cgi = CGI::Pure->new(
        'init' => $query_string,
);
foreach my $param_key ($cgi->param) {
        print "Param '$param_key': ".join(' ', $cgi->param($param_key))."\n";
}

# Output:
# Param 'par1': val1 val2
# Param 'par2': value