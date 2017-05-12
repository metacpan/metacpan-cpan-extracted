#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

BEGIN { 
    use_ok('Date::Formatter')
}

{
    my $d;
    lives_ok {
        $d = Date::Formatter->new(
                hour         => 9,
                minutes      => 3,
                seconds      => 0,
                day_of_month => 4,
                month        => 12,
                year         => 1996
                );
    } '... created a date successfully';
    isa_ok($d, 'Date::Formatter');
    
    $d->createDateFormatter('(hh):(mm):(ss) (MM)/(DD)/(YYYY)');
    is($d->toString(), '9:03:00 12/4/1996', '... got the date we expected');
}

{
    my $d;
    lives_ok {
        $d = Date::Formatter->new(
                day_of_month => 16,
                month        => 2,
                year         => 2002
                );
    } '... created a date successfully';
    isa_ok($d, 'Date::Formatter');
    
    $d->createDateFormatter('(hh):(mm):(ss) (MM)/(DD)/(YYYY)');
    is($d->toString(), '12:00:00 2/16/2002', '... got the date we expected');
}

{
    my $d;
    lives_ok {
        $d = Date::Formatter->new(
                hour         => 11,
                minutes      => 58,
                seconds      => 23,
                );
    } '... created a date successfully';
    isa_ok($d, 'Date::Formatter');
    
    $d->createDateFormatter('(hh):(mm):(ss) (MM)/(DD)/(YYYY)');
    is($d->toString(), '11:58:23 1/1/2000', '... got the date we expected');
}

throws_ok {
    Date::Formatter->new(
                month => 0
                );
} qr/Insufficient Arguments \:/, '... got the error we expected';

throws_ok {
    Date::Formatter->new(
                month => 'Fail'
                );
} qr/Insufficient Arguments \:/, '... got the error we expected';

throws_ok {
    Date::Formatter->new(
                day_of_month => 0
                );
} qr/Insufficient Arguments \:/, '... got the error we expected';

