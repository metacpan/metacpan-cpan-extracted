#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestHelpers 'output_like';

output_like(<<EOF,
    use Carp::Always::Color::HTML;
    warn "foo";
EOF
    qr+<span style=\"color:#880\">foo</span> at -e line 2\b+,
    "simple warns work");

output_like(<<EOF,
    use Carp::Always::Color::HTML;
    sub foo {
        warn "foo";
    }
    foo();
EOF
    qr+<span style=\"color:#880\">foo</span> at -e line 3\.?\n\tmain::foo\(\) called at -e line 5\n+,
    "warns with a stacktrace work");

output_like(<<EOF,
    use Carp::Always::Color::HTML;
    die "foo";
EOF
    qr+<span style=\"color:#800\">foo</span> at -e line 2\b+,
    "simple dies work");

output_like(<<EOF,
    use Carp::Always::Color::HTML;
    sub foo {
        die "foo";
    }
    foo();
EOF
    qr+<span style=\"color:#800\">foo</span> at -e line 3\.?\n\tmain::foo\(\) called at -e line 5\n+,
    "dies with a stacktrace work");

done_testing;
