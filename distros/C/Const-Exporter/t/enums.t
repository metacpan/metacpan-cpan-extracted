#!perl

use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use lib 't/lib';
use Test::Const::Exporter::Enums;

subtest 'enums' => sub {

    is $c1, 8;
    is $c2, 4;
    is $c3, 20;

};

subtest 'auto increment' => sub {

    is a1, 0;
    is a2, (a1()+1);
    is a3, (a2()+1);

};

subtest 'auto increment custom start' => sub {

    is $d1, 10;
    is $d2, 12;
    is $d3, 13;

};

subtest 'custom increment' => sub {

    is $b1, 1;
    is $b2, 2;
    is $b3, 8, 'skipped symbol';

};


done_testing;
