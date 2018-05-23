#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use lib qw(
    t/lib lib
    blib/lib blib/t/lib 
);

$| = 1;

use Test::More;
use Test2::Tools::Exception qw(dies lives);

use Assert::Conditional qw(assert_does assert_doesnt);

plan tests => 14;

my $PRIVATE_RX = qr/botched assertion assert_private_method/;
my $PROTECTED_RX = qr/botched assertion assert_protected_method/;

my $ROLE = "Alien::Snatch";

{
    my($module, $obj, $method, $test_name, $e);
    $module = "Some::TestRapper";
    require_ok $module;
    $obj = $module->new;

    $test_name = "assert_doesnt";
    ok(lives { assert_doesnt($module, $ROLE) }, "$test_name lives")
        || diag "$test_name died: $@";

    $test_name = "assert_does";
    like($e = dies { assert_does($module, $ROLE) },
        qr/botched assertion assert_does\b/, 
        "$test_name dies"
    ) && note "found expected exception: $e";

    $method = "their_data";
    $test_name = "$module->$method";
    ok(lives { $obj->$method }, "$test_name lives") 
        || diag "$test_name died: $@";

    $method = "our_data";
    $test_name = "$module->$method";
    like($e = dies { $obj->$method }, $PROTECTED_RX, "$test_name dies") 
        && note "found expected exception: $e";

    $method = "my_data";
    $test_name = "$module->$method";
    like($e = dies { $obj->$method }, $PRIVATE_RX, "$test_name dies") 
        && note "found expected exception: $e";

} 


{
    my($module, $obj, $method, $test_name, $e);
    $module = "Other::ProbeRapper";
    require_ok $module;
    $obj = $module->new;

    $test_name = "assert_does";
    ok(lives { assert_does($module, $ROLE) }, "$test_name lives")
        || diag "$test_name died: $@";

    $test_name = "assert_doesnt";
    like($e = dies { assert_doesnt($module, $ROLE) },
        qr/botched assertion assert_doesnt\b/, 
        "$test_name dies"
    ) && note "found expected exception: $e";

    $method = "their_data";
    $test_name = "$module->$method";
    ok(lives { $obj->$method }, "$test_name lives") 
        || diag "died: $@";

    $method = "safe_data";
    $test_name = "$module->$method";
    ok(lives { $obj->$method }, "$test_name lives") 
        || diag "died: $@";

    $method = "roll_data";
    $test_name = "$module->$method";
    ok(lives { $obj->$method }, "$test_name lives") 
        || diag "died: $@";

    $method = "our_data";
    $test_name = "$module->$method";
    like($e = dies { $obj->$method }, $PROTECTED_RX, "$test_name dies") 
        && note "found expected exception: $e";

    $method = "my_data";
    $test_name = "$module->$method";
    like($e = dies { $obj->$method }, $PRIVATE_RX, "$test_name dies")
        && note "found expected exception: $e";

} 


done_testing;
