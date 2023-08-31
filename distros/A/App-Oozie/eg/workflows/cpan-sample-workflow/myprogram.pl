#!/usr/bin/env perl

# You can do anything you want in this code and since the output is captured,
# it is also possible t define some variables to use for subsequent workflow
# actions

use strict;
use warnings;

use Carp qw( croak );
use Getopt::Long;

GetOptions(
    \my %OPT,
    qw(
        dryrun
        whatever=s
    )
) or croak 'Failed to parse command line arguments!';

if ( $OPT{dryrun} ) {
    warn "Alright, not doing anything apart from spamming the logs";
    exit;
}

printf "foo=%s\n", $OPT{whatever} || 'Hello';
