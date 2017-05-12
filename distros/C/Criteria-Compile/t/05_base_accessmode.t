#!/bin/perl


use strict;
use warnings;

use Test::More tests => 8;
use Carp;



use constant CC_CLASS => 'Criteria::Compile';
use_ok(CC_CLASS());


#create test data

our %test_data;
BEGIN {
    %test_data = (
        name => 'name',
        ten => 10,
        hundred => 100
    );
}

my %test_crit = ();
foreach (keys(%test_data)) {
    $test_crit{"${_}_is"} = $test_data{$_};
}


#create test criteria

my $ocrit = CC_CLASS()->new(%test_crit);
ok( $ocrit, 'create test object criteria');
my $hcrit = CC_CLASS()->new(%test_crit);
ok( $hcrit, 'create test hash criteria');


#test object access mode

ok( ($ocrit->access_mode(CC_CLASS()->ACC_OBJECT())
    and $ocrit->exec(bless({}, 'TestPackage'))),
    'match using object access mode' );
ok( !$ocrit->exec(bless({ n => 1 }, 'TestPackage')),
    'negative match using object access mode' );


#test hash access mode

ok( ($hcrit->access_mode(CC_CLASS()->ACC_HASH())
    and $hcrit->exec(\%test_data)),
    'match using hash access mode' );
ok( !$hcrit->exec({}),
    'negative match using hash access mode' );


#test for leaks

ok( $ocrit->exec(bless({}, 'TestPackage')),
    'leak test, object criteria still matches' );





done_testing();




package TestPackage;

BEGIN {
    no strict 'refs';
    foreach (keys %main::test_data) {
        *{"TestPackage\::$_"} = eval("sub { \$_[0]->{n} ? 'x' : \$::test_data{$_} }");
    }
}

