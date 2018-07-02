#!perl

use strict;
use warnings;

# Load BEFORE T::M to avoid detecting it
use Assert::Refute qw(:core);

use Test::More;

my $spec = contract {
    current_contract->refute( 0, "fine" );
    current_contract->refute( 42, "not so fine" );
};

my $log = $spec->apply;

is $log->get_count, 2, "Count as expected";
ok !$log->is_passing, "Contract invalidated (as expected)";

my $permitted = eval {
    current_contract;
    "Should not be";
};
like $@, qr/[Nn]ot currently testing anything/, "Thou shall not pass";
is $permitted, undef, "Unreachable";

done_testing;
