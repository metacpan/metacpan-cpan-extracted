#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;


main();
exit(0);


#   delete_all

sub main {
    
    my $res = get_random_dt_range('2013-07-20 10:00:00', '2013-07-20 10:59:59');
    ok($res =~ m/^2013-07-20 10/, "got $res");

    $res = get_random_dt_range('2013-07-20 10:00:00', '2013-07-20 15:59:59');
    ok($res =~ m/^2013-07-20 1[0-5]/, "got $res");

    $res = get_random_dt_range('2013-07-20 10', '2013-07-20 11');
    ok($res =~ m/^2013-07-20 10/, "got $res");

    $res = get_random_dt_range('2013-07-20', '2013-07-21');
    ok($res =~ m/^2013-07-20/, "got $res");

    $res = get_random_dt_range('2013', '2014');
    ok($res =~ m/^2013-/, "got $res");

    done_testing();
}


sub get_random_dt_range {
    Data::HandyGen::mysql::_get_random_dt_range(@_);
}

