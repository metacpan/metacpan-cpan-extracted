#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my %cases = (
    'C(CC'    => 't/04_errors.t: syntax error: missing closing parenthesis.',
    'CC)C'    => 't/04_errors.t: syntax error: unbalanced parentheses.',
    'CCC)'    => 't/04_errors.t: syntax error: unbalanced parentheses.',
    'C#=O'    => 't/04_errors.t: syntax error at position 3: \'O\'.',
    'C..O'    => 't/04_errors.t: syntax error at position 3: \'O\'.',
    'CCC1'    => 't/04_errors.t: unclosed ring bond(s) detected: 1.',
    'C2%12'   => 't/04_errors.t: unclosed ring bond(s) detected: 2, 12.',
    'C=1CC$1' => 't/04_errors.t: ring bond types for ring bond 1 do not match.',
    'C((C))O' => 't/04_errors.t: syntax error at position 3: \'C))O\'.',
    '(O)'     => 't/04_errors.t: syntax error at position 1: \'O)\'.',
    '(O)C'    => 't/04_errors.t: syntax error at position 1: \'O)C\'.',
    '.CC'     => 't/04_errors.t: syntax error at position 1: \'CC\'.',
    'CC.'     => 't/04_errors.t: syntax error at position 4.',
);

plan tests => scalar keys %cases;

for (sort keys %cases) {
    'intentionally polluting $1' =~ /(\S+)/;

    my $error;
    eval {
        my $parser = Chemistry::OpenSMILES::Parser->new;
        my @graphs = $parser->parse( $_ );
    };
    $error = $@ if $@;
    $error =~ s/\n$// if $error;
    is( $error, $cases{$_} );
}
