#!/bin/perl


use strict;
use warnings;

use Test::More tests => 15;
use Carp;
use Criteria::DateTime ( );
use DateTime ( );
use DateTime::Duration ( );



use constant DTC_CLASS => 'Criteria::DateTime';
use constant DATETIME_CLASS => 'DateTime';
use constant DURATION_CLASS => 'DateTime::Duration';
use_ok(DTC_CLASS());


ok( DTC_CLASS()->new()->exec({}),
    'datetime criteria instance compilable');


#create test criteria

our %test_data;
BEGIN {
    %test_data = (
        tomorrow => DATETIME_CLASS()->now()->add(days => 1),
        nextweek => DATETIME_CLASS()->now()->add(days => 7),
        yesterday => DATETIME_CLASS()->now()->add(days => -1),
        lastweek => DATETIME_CLASS()->now()->add(days => -7),
        today => DATETIME_CLASS()->now(),
        oneday => DURATION_CLASS()->new(days => 1),
        twodays => DURATION_CLASS()->new(days => 2)
    );
}


my %criteria = (
    today_before => $test_data{nextweek},
    tomorrow_after => $test_data{today},
    tomorrow_sooner_than => $test_data{twodays},
    nextweek_later_than => $test_data{oneday},
    twodays_longer_than => $test_data{oneday},
    oneday_shorter_than => $test_data{twodays},
    lastweek_older_than => $test_data{oneday},
    nextweek_newer_than => $test_data{oneday}
);


#create test object

my $criteria;
my $test_obj = bless({%test_data}, 'TestPackage');


#basic criteria test

$criteria = DTC_CLASS()->new();
ok( $criteria->exec({}),
    'datetime criteria checking works, no grammar');

#basic grammar test via new

$criteria = DTC_CLASS()->new(%criteria);
ok( $criteria->exec($test_obj), 
    'datetime grammar works via ->new' );

#basic grammar test via add_criteria

$criteria = DTC_CLASS()->new();
$criteria->add_criteria(%criteria);
ok( $criteria->exec($test_obj), 
    'datetime grammar works via ->add_crtieria' );

#basic grammar test via direct compile

$criteria = DTC_CLASS()->new();
$criteria->compile({%criteria});
ok( $criteria->exec($test_obj), 
    'datetime grammar works via ->compile' );
ok( $criteria->compile() && $criteria->exec({}),
    'datetime compile method criteria non-persistent' );

#basic grammar test, individual

$criteria = DTC_CLASS()->new();
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


