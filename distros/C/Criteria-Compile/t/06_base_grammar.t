#!/bin/perl


use strict;
use warnings;

use Test::More tests => 12;
use Carp;



use constant CC_CLASS => 'Criteria::Compile';
use_ok(CC_CLASS());



#create test criteria

our %test_data;
BEGIN {
    %test_data = (
        key_map => { 1000..1049 },
        name => 'name',
        number => rand(10)**rand(5),
        ten => 10,
        hundred => 100
    );
    my @keys = keys(%{$test_data{key_map}});
    $test_data{key} = $keys[rand(scalar(@keys)-1)];
}


my %criteria = (
    name_is => $test_data{name},
    number_like => qr/^[\d\.]+$/,
    ten_greater_than => 9,
    hundred_less_than => 200,
    key_in => [keys(%{$test_data{key_map}})],
    key_matches => $test_data{key_map}
);


#create test object

my $criteria;
my $test_obj = bless({%test_data}, 'TestPackage');


#basic criteria test

$criteria = CC_CLASS()->new();
ok( $criteria->exec({}),
    'base criteria checking works, no grammar');

#basic grammar test via new

$criteria = CC_CLASS()->new(%criteria);
ok( $criteria->exec($test_obj), 
    'base grammar works via ->new' );

#basic grammar test via add_criteria

$criteria = CC_CLASS()->new();
$criteria->add_criteria(%criteria);
ok( $criteria->exec($test_obj), 
    'base grammar works via ->add_crtieria' );

#basic grammar test via direct compile

$criteria = CC_CLASS()->new();
$criteria->compile({%criteria});
ok( $criteria->exec($test_obj), 
    'base grammar works via ->compile' );
ok( $criteria->compile() && $criteria->exec({}),
    'compile method criteria non-persistent' );

#basic grammar test, individual

$criteria = CC_CLASS()->new();
foreach (keys %criteria) {
    ok( ($criteria->compile({$_, $criteria{$_}})
        and $criteria->exec($test_obj)),
        sprintf('individual grammar check for "%s"', 
            ($_ =~ /^[^_]+_(.*)/)));

}



#test compelted
done_testing();





package TestPackage;

BEGIN {
    no strict 'refs';
    foreach (keys %main::test_data) {
        *{"TestPackage\::$_"} = eval("sub { \$::test_data{$_} }");
    }
}


