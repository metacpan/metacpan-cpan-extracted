#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };

# Load BEFORE T::M to avoid detecting it
use Assert::Refute qw(:core), {};

use Test::More;
use Scalar::Util qw(refaddr);

my @trace;
my $report = try_refute {
    push @trace, current_contract;
    push @trace, "alive";
};

is refaddr $trace[0], refaddr $report, "current_contract is same as report";
is $trace[1], "alive", "current_contract lives";

my $permitted = eval {
    current_contract;
    "Should not be";
};
like $@, qr/[Nn]ot currently testing anything/, "Thou shall not pass";
is $permitted, undef, "Unreachable";

done_testing;
