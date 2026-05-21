#!perl

use v5.26.0;

use strict;
use warnings;

use Test2::V1;

use ok 'Data::Printer::Filter::EscapeNonPrintable';

foreach my $mod ( qw< Data::Printer::Filter::EscapeNonPrintable > ) {
    my $mod_ver = '$' . $mod . '::VERSION';

    T2->diag(
        sprintf "Testing $mod %s, Perl %s, %s",
        $mod_ver, $], $^X,
    );
}

T2->done_testing;
