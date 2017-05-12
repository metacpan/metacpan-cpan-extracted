#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test some special read forms, like quote and such.

=cut

use Test::More tests => 4;
use Test::Deep;

use Data::SExpression;

my $ds = Data::SExpression->new;

{
    no warnings 'once';
    cmp_deeply(
        scalar $ds->read("'(a b c)"),
        [\*::quote, [\*::a, \*::b, \*::c]],
        "Parsed quote correctly"
       );

    cmp_deeply(
        scalar $ds->read("`(a b c)"),
        [\*::quasiquote, [\*::a, \*::b, \*::c]],
        "Parsed quasiquote correctly"
       );

    cmp_deeply(
        scalar $ds->read(",(a b c)"),
        [\*::unquote, [\*::a, \*::b, \*::c]],
        "Parsed unquote correctly"
       );

    cmp_deeply(
        scalar $ds->read("'`(a ,b ,c)"),
        [\*::quote, [\*::quasiquote, [\*::a, [\*::unquote, \*::b], [\*::unquote, \*::c]]]],
        "Parsed quote, quasiquote, and unquote together"
       );
}
