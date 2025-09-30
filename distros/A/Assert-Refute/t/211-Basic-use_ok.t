#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);

my $report = refute_and_report {
    package T;
    my $self = shift;

    $self->use_ok( "Assert::Refute");
    $self->use_ok( "Assert::Refute", 0.01 );
    $self->use_ok( "Assert::Refute", "no_such_method" );
    $self->ok(1, "Lived until here");
};

is $report->get_sign, "t2N1d", "use as expected";

note "REPORT\n",$report->get_tap,"/REPORT";

done_testing;
