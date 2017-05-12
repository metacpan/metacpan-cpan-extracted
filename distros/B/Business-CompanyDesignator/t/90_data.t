#!perl
#
# For release, check that share/company_designator.yml data file is latest
#

use strict;
use warnings;
use Test::More;
use Test::Files;
use File::Spec;
use File::HomeDir;
use FindBin qw($Bin);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $datafile = "$Bin/../share/company_designator.yml";
my $upstream = "$Bin/../share/company_designator_upstream.yml";

compare_ok($datafile, $upstream, 'datafile content in sync with upstream');

done_testing;

