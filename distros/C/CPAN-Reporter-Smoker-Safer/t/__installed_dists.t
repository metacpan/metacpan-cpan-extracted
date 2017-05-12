#!perl

use strict;
use warnings;
use Test::More tests => 12;
use Test::Differences;
use CPAN::Reporter::Smoker::Safer;
$|=1;

local $CPAN::Reporter::Smoker::Safer::MIN_REPORTS  = 0;
local $CPAN::Reporter::Smoker::Safer::MIN_DAYS_OLD = 0;
local $CPAN::Reporter::Smoker::Safer::EXCLUDE_TESTED = 0;
my ($dists, $mask, $label);


$mask = '/CPAN/';
$label = "$mask -";
$dists = CPAN::Reporter::Smoker::Safer->__installed_dists( $mask, undef );
is( ref($dists), 'ARRAY', "$label got array ref" );
ok( scalar(@$dists), "$label got dists" );
ok( grep(m#/CPAN-\d#,@$dists), "$label got CPAN" );
ok( grep(m#/CPAN-Reporter-\d#,@$dists), "$label got CPAN-Reporter" );


$mask = '/CPAN::Reporter/';
$label = "$mask -";
$dists = CPAN::Reporter::Smoker::Safer->__installed_dists( $mask, undef );
is( ref($dists), 'ARRAY', "$label got array ref" );
ok( scalar(@$dists), "$label got dists" );
ok( ! grep(m#/CPAN-\d#,@$dists), "$label no CPAN" );
ok( grep(m#/CPAN-Reporter-\d#,@$dists), "$label got CPAN-Reporter" );


$mask = '/CPAN/';
$label = "$mask Filter=>Reporter -";
$dists = CPAN::Reporter::Smoker::Safer->__installed_dists( $mask, sub { $_[1]->pretty_id =~ /Reporter/ } );
is( ref($dists), 'ARRAY', "$label got array ref" );
ok( scalar(@$dists), "$label got dists" );
ok( ! grep(m#/CPAN-\d#,@$dists), "$label no CPAN" );
ok( grep(m#/CPAN-Reporter-\d#,@$dists), "$label got CPAN-Reporter" );


