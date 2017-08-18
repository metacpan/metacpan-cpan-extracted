#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 26;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
}


for my $t (parse DR::DateTime '2017-08-18 01:02:03.5+0300') {
    isa_ok $t => DR::DateTime::, 'instance created';

    is $t->nanosecond, 500_000_000, 'nanosecond';
    ok $t->truncate(to  => 'second'), 'truncate to second';
    is $t->nanosecond, 0, 'nanosecond after truncate';
    is $t->strftime('%F %T%z'), '2017-08-18 01:02:03+0300', 'strftime';


    is $t->second, 3, 'second'; 
    ok $t->truncate(to => 'minute'), 'truncate to minute';
    is $t->second, 0, 'second after truncate';
    is $t->strftime('%F %T%z'), '2017-08-18 01:02:00+0300', 'strftime';

    is $t->minute, 2, 'minute'; 
    ok $t->truncate(to => 'hour'), 'truncate to hour';
    is $t->minute, 0, 'minute after truncate';
    is $t->strftime('%F %T%z'), '2017-08-18 01:00:00+0300', 'strftime';
    
    is $t->hour, 1, 'hour'; 
    ok $t->truncate(to => 'day'), 'truncate to day';
    is $t->hour, 0, 'hour after truncate';
    is $t->strftime('%F %T%z'), '2017-08-18 00:00:00+0300', 'strftime';
    
    is $t->day, 18, 'day'; 
    ok $t->truncate(to => 'month'), 'truncate to month';
    is $t->day, 1, 'day after truncate';
    is $t->strftime('%F %T%z'), '2017-08-01 00:00:00+0300', 'strftime';
    
    is $t->month, 8, 'month'; 
    ok $t->truncate(to => 'year'), 'truncate to year';
    is $t->day, 1, 'month after truncate';
    is $t->strftime('%F %T%z'), '2017-01-01 00:00:00+0300', 'strftime';
}
