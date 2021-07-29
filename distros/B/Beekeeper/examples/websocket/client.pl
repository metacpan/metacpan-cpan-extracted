#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }


use MyApp::Service::Calculator;

my $calc = MyApp::Service::Calculator->new;

print "> ";

while (my $line = <STDIN>) {
    chomp $line;

    last if $line eq 'quit';

    my $result = eval { $calc->eval_expr($line) };

    print $@ ? "ERR: $@" : "= $result\n";

    print "> ";
}

1;
