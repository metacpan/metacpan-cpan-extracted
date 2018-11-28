#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core), {};
use Assert::Refute::T::Hash;

my $report;

$report = try_refute {
    keys_are { foo => 42, bar => 137 }, [], undef, "No restriction";
    keys_are { foo => 42 }, [qw[foo]], undef, "Just happy case";
    keys_are { foo => 42 }, [qw[foo bar]], undef, "Required missing";
    keys_are { foo => 42, bar => 137 }, [qw[foo]], [], "Restricted";
    keys_are { foo => 42, bar => 137 }, [qw[foo]], [qw[bar]], "Restricted pass";
    keys_are { foo => 42, baz => 137 }, [qw[foo]], [qw[bar]], "Restricted typo";
};

contract_is $report, "t2NN1Nd", "Contract as expected";

note "REPORT\n".$report->get_tap."/REPORT";

done_testing;
