#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Test 1: Simple inheritance with inline packages
{
    package Test::SimpleBase;
    use Class;

    our $SIMPLE_COUNT;
    BEGIN { $SIMPLE_COUNT++ }
    sub simple_id { 111 }
}

{
    package Test::SimpleUser;
    use Class;
    extends 'Test::SimpleBase';
}

my $simple_user = Test::SimpleUser->new;
is($simple_user->simple_id, 111, 'simple inheritance works');
is($Test::SimpleBase::SIMPLE_COUNT, 1, 'base class compiled once');

# Test 2: Multi-level inheritance
{
    package Test::Level1;
    use Class;
    sub level1 { 'one' }
}

{
    package Test::Level2;
    use Class;
    extends 'Test::Level1';
    sub level2 { 'two' }
}

{
    package Test::Level3;
    use Class;
    extends 'Test::Level2';
}

my $level3 = Test::Level3->new;
is($level3->level1, 'one', 'multi-level inheritance level1 works');
is($level3->level2, 'two', 'multi-level inheritance level2 works');

done_testing;
