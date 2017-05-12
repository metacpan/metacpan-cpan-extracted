#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test reading multiple SExpressions from a string

=cut

use Test::More 'no_plan';
use Test::Deep;

use Data::SExpression;

my $text = "(foo) bar 3.4 (a (list))";
my $sexp;

my $ds = Data::SExpression->new;

($sexp, $text) = $ds->read($text);

{
    no warnings 'once';
    cmp_deeply($sexp, [\*foo], "Parsed a sexp off the start of a string");
}

like($text, qr/ ?bar 3.4 \(a \(list\)\)/, "Returned the rest of the string");


my @sexps;
while (1) {
    eval {
        ( $sexp, $text ) = $ds->read($text);
    };
    last if $@;
    push @sexps, $sexp;
}

{
    no warnings 'once';
    cmp_deeply(\@sexps,
               [\*::bar, 3.4, [\*::a, [\*::list]]],
               "Read a bunch of SExpressions");
}
