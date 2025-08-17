#!/usr/bin/env perl

use Test2::V0;

use Data::KSUID ':all';

is ksuid_to_string(Data::KSUID::MAX), Data::KSUID::MAX_STRING,
    'MAX and MAX_STRING match';

is ksuid_to_string(Data::KSUID::MIN), Data::KSUID::MIN_STRING,
    'MIN and MIN_STRING match';

done_testing;
