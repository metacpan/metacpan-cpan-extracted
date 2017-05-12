#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestHelpers 'output_like';

output_like(<<EOF,
    use Carp::Always::Color;
    warn "foo";
EOF
    qr/\e\[33mfoo\e\[m at -e line 2\b/,
    "detection works for terminal output");

output_like(<<EOF,
    my \$stderr;
    BEGIN {
        close(STDERR);
        open(STDERR, '>', \\\$stderr);
    }
    use Carp::Always::Color;
    warn "foo";
    print \$stderr;
EOF
    qr+foo at -e line 7\b+,
    "detection works for terminal output");

done_testing;
