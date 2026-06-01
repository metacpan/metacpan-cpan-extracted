use strict;
use warnings;

use Test::More 0.88;

BEGIN { use_ok('DateTime::Format::Duration') };

my $strf = DateTime::Format::Duration->new(
    normalise => 0,
    pattern => '%F %r',
);

isa_ok($strf, 'DateTime::Format::Duration');

done_testing;
