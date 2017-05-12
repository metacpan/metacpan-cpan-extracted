#!/usr/bin/perl -w

use strict;

sub conf {
    my $db_src = 'dbi:Pg:dbname=dnszone';
    my $db_user = 'dnszone';
    my $db_pass = 'sndenoz';
    return $db_src, $db_user, $db_pass;
}

1;
