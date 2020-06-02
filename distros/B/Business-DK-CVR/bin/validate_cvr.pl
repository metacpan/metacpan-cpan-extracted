#!/usr/bin/perl

# $Id$

use strict;
use warnings;
use vars qw($VERSION);
use Getopt::Long;
use Business::DK::CVR qw(validate);

$VERSION = '0.01';

my $verbose = 0;
my $result = GetOptions( 'verbose' => \$verbose );

if ( not $ARGV[0] ) {
    die "usage: validate_cvr.pl [-v] <10 digit CVR number>\n";
}

my $cvr = $ARGV[0];

if ( validate($cvr) ) {
    print "$cvr is valid\n";
} else {
    print "$cvr is not valid\n";
}

exit 0;
