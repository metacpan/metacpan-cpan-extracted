#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);

my $contract = contract {
    refute shift, "test 1";
    refute shift, "test 2";
    die shift if @_;
};

my $bad = $contract->apply( 0, "forgot a semicolon" );

# note explain $bad;

ok $bad->is_done, "Execution finished";
ok !$bad->has_died, "Has never died"
    or diag $bad->last_error;
ok !$bad->result(1), "Nothing returned for passing test";
is $bad->result(2), "forgot a semicolon", "Reason retained for failing test";
is $bad->count, 2, "2 tests run";

my $ugly = $contract->apply( 0, 0, "forgot a semicolon" );
ok $ugly->is_done, "Execution finished";
ok $ugly->has_died, "Has died";
like $ugly->last_error, qr/forgot a semicolon/, "Error retained";

my $file = quotemeta __FILE__;
my $line = __LINE__ + 2;
eval {
    $ugly->result(10);
};
like $@, qr/never.*performed.*$file line $line/
    , "Carped error for nonexistent test";

done_testing;
