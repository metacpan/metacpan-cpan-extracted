#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;

my @ok_samples = (
    q{The package will be delivered at 3:15 PM, March 15, 2007, on the dot.},
    q{the author was born sometime on July 15, 1979},
);

my @not_ok_samples = (
    q{there are no dates in this text},
);

use Date::Extract::Surprise qw( extract_datetimes );

my $des = Date::Extract::Surprise->new();

my $num = 0;
for my $text ( @ok_samples ) {

    my @dates;

    @dates = $des->extract( $text );
    ok @dates, "sample $num, object method";

    @dates = Date::Extract::Surprise->extract( $text );
    ok @dates, "sample $num, class method";

    @dates = extract_datetimes( $text );
    ok @dates, "sample $num, function";

    $num++;
}

done_testing();
