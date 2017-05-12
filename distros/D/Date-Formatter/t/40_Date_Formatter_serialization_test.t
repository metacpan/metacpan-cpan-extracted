#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { 
    use_ok('Date::Formatter')
}

my $date = Date::Formatter->now();

can_ok($date, 'pack');
can_ok($date, 'unpack');

# test Serializable instance
my $pack_test = $date->pack();
my $unpacked_date = $date->unpack($pack_test);

isnt($date->stringValue(), $unpacked_date->stringValue());	
is(ref($unpacked_date), ref($date), '... these should be the same type');
is($unpacked_date->pack(), $pack_test, '... should be no loss of information');	
