#!/usr/bin/env perl

use strict;
use warnings;
use vars qw($VERSION);
use Getopt::Long;
use English qw(-no_match_vars);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Class::Business::DK::CPR;

$VERSION = '0.01';

my $verbose = 0;
my $result = GetOptions( 'verbose' => \$verbose );

if ( not $ARGV[0] ) {
    die "usage: validate_cpr.pl [-v] <10 digit CPR number>\n";
}

my $unvalidated_cpr = $ARGV[0];

my $rv = 0;
my $cpr;

eval { $cpr = Class::Business::DK::CPR->new($unvalidated_cpr); };

if ($EVAL_ERROR) {
    print "$unvalidated_cpr is not valid\n";

}
else {
    if ($verbose) {
        print $cpr->get_number
          . ' is valid for algorithms: '
          . $cpr->get_algorithm;
        print ', gender indicated is: '
          . ( $cpr->get_gender % 2 ? 'male' : 'female' );
        print "\n";
    }
    else {
        print $cpr->get_number . " is valid\n";
    }
}

exit 0;
