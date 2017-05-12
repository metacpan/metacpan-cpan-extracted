#!/usr/bin/env perl
use warnings;
use strict;
use Carp::Source;
use Test::More tests => 1;
use Test::Differences;
my $context = Carp::Source::get_context(__FILE__, __LINE__,
    lines  => 5,
    number => 0
);

# Some comments to
# avoid getting the expected
# context into the tested context
# which would make for recursive weirdness
my $expected = <<EOCONTEXT;
context for t/02_with_options.t line 7:

use warnings;
use strict;
use Carp::Source;
use Test::More tests => 1;
use Test::Differences;
\e[30;43mmy \$context = Carp::Source::get_context(__FILE__, __LINE__,\e[0m
    lines  => 5,
    number => 0
);

# Some comments to
===========================================================================
EOCONTEXT
eq_or_diff $context, $expected, 'context';
