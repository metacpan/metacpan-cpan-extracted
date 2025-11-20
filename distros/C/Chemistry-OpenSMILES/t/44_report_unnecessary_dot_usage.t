#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C'          => 0,
    'C(.C)'      => 1,
    'C(C.C)'     => 1,
    'C(=C.C)'    => 1,
    'C(C.C.C)'   => 1,
    'C(.C.C.C)'  => 1,
    'C(.C)C(.C)' => 2,
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    my $parser   = Chemistry::OpenSMILES::Parser->new;
    my( $graph ) = $parser->parse( $_, { report_unnecessary_dot_usage => 1 } );
    is $warnings, $cases{$_}, $_;
}
