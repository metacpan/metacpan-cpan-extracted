#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Business::CPI::Util::Types qw/Money/;
use Test::More;
use Test::TypeTiny;

should_pass('1007.00',   Money);
should_pass('1007.32',   Money);
should_pass('1,007.32',  Money);
should_pass(1_007.32,    Money);
should_pass('-1,007.32', Money);
should_pass(-1_007.32,   Money);
should_fail('R$ 123',    Money);
should_fail('USD 123',   Money);
should_fail('R$ -123',   Money);
should_fail('USD -123',  Money);
should_fail('10z0',      Money);
should_fail('1007',      Money);

# TODO test other types

done_testing;
